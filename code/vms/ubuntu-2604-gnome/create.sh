#!/usr/bin/env bash
set -euo pipefail

# Create an Ubuntu Desktop VM for Microsoft Intune on an x86_64 libvirt host.
# The installer remains interactive: encryption, user creation, and Intune
# enrollment must not be automated or captured in this repository.

VM_NAME="${VM_NAME:-ubuntu-2604-intune}"
RAM_MB="${RAM_MB:-8192}"
VCPUS="${VCPUS:-4}"
DISK_SIZE="${DISK_SIZE:-80G}"
ISO_DIR="${ISO_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/ubuntu-2604-gnome}"
ISO_URL="https://releases.ubuntu.com/resolute/ubuntu-26.04-desktop-amd64.iso"
LIBVIRT_URI="qemu:///system"
VM_STORAGE_MOUNT="${VM_STORAGE_MOUNT:-/mnt/intune-vm}"
POOL="${POOL:-intune-t7}"
POOL_TARGET="${VM_STORAGE_MOUNT}/images"
DISK_NAME="${VM_NAME}.qcow2"
ISO_NAME="${ISO_URL##*/}"
ISO_PATH="${ISO_DIR}/${ISO_NAME}"
CHECKSUMS_PATH="${ISO_DIR}/SHA256SUMS"

need_command() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'missing required command: %s\n' "$1" >&2
    exit 1
  }
}

for command in awk curl findmnt grep sha256sum virsh virt-install; do
  need_command "$command"
done

case "$(uname -m)" in
  x86_64) ;;
  *)
    printf 'this VM targets an x86_64 host; detected %s\n' "$(uname -m)" >&2
    printf 'do not use the Apple Silicon Aron host for Intune enrollment.\n' >&2
    exit 1
    ;;
esac

# Accessing the directory triggers Freya's systemd automount.
if ! ls -d "${VM_STORAGE_MOUNT}/." >/dev/null 2>&1 \
  || ! findmnt --mountpoint "$VM_STORAGE_MOUNT" >/dev/null 2>&1; then
  printf 'the Samsung T7 VM filesystem is not mounted at %s.\n' "$VM_STORAGE_MOUNT" >&2
  printf 'format it and deploy Freya as documented before retrying.\n' >&2
  exit 1
fi

storage_label="$(findmnt --noheadings --types ext4 --output LABEL --target "$VM_STORAGE_MOUNT")"
storage_type="$(findmnt --noheadings --types ext4 --output FSTYPE --target "$VM_STORAGE_MOUNT")"
storage_options="$(findmnt --noheadings --types ext4 --output OPTIONS --target "$VM_STORAGE_MOUNT")"
if [[ "$storage_label" != "INTUNE_VM" || "$storage_type" != "ext4" ]]; then
  printf '%s must be the ext4 filesystem labelled INTUNE_VM; found label=%q type=%q\n' \
    "$VM_STORAGE_MOUNT" "$storage_label" "$storage_type" >&2
  exit 1
fi
case ",${storage_options}," in
  *,rw,*) ;;
  *)
    printf '%s is not mounted read-write.\n' "$VM_STORAGE_MOUNT" >&2
    exit 1
    ;;
esac

virsh --connect "$LIBVIRT_URI" uri >/dev/null
if ! virsh --connect "$LIBVIRT_URI" net-info default | grep -q 'Active:.*yes'; then
  virsh --connect "$LIBVIRT_URI" net-start default
fi
virsh --connect "$LIBVIRT_URI" net-autostart default >/dev/null

if ! virsh --connect "$LIBVIRT_URI" pool-info "$POOL" >/dev/null 2>&1; then
  virsh --connect "$LIBVIRT_URI" pool-define-as \
    "$POOL" dir --target "$POOL_TARGET" >/dev/null
  virsh --connect "$LIBVIRT_URI" pool-build "$POOL" >/dev/null
fi
if ! virsh --connect "$LIBVIRT_URI" pool-dumpxml "$POOL" \
  | grep -Fq "<path>${POOL_TARGET}</path>"; then
  printf 'libvirt pool %q exists but does not target %s\n' "$POOL" "$POOL_TARGET" >&2
  exit 1
fi
if ! virsh --connect "$LIBVIRT_URI" pool-info "$POOL" | grep -q 'State:.*running'; then
  virsh --connect "$LIBVIRT_URI" pool-start "$POOL"
fi
virsh --connect "$LIBVIRT_URI" pool-autostart "$POOL" >/dev/null

mkdir -p "$ISO_DIR"
if [[ ! -f "$ISO_PATH" ]]; then
  printf 'downloading %s\n' "$ISO_URL"
  curl --fail --location --continue-at - --output "$ISO_PATH" "$ISO_URL"
fi

printf 'downloading official checksum list\n'
curl --fail --location --output "$CHECKSUMS_PATH" \
  "${ISO_URL%/*}/SHA256SUMS"

checksum_line="$(awk -v name="$ISO_NAME" '$2 == name || $2 == "*" name { print; exit }' "$CHECKSUMS_PATH")"
if [[ -z "$checksum_line" ]]; then
  printf 'the ISO is not listed in the official checksum file: %s\n' "$ISO_NAME" >&2
  printf 'the release may not be published yet; inspect %s\n' "$CHECKSUMS_PATH" >&2
  exit 1
fi
printf '%s  %s\n' "${checksum_line%% *}" "$ISO_PATH" | sha256sum --check --status -
printf 'ISO checksum verified\n'

if virsh --connect "$LIBVIRT_URI" dominfo "$VM_NAME" >/dev/null 2>&1; then
  printf 'VM already exists: %s\n' "$VM_NAME" >&2
  printf 'use virt-manager or virsh instead of recreating it.\n' >&2
  exit 1
fi

if virsh --connect "$LIBVIRT_URI" vol-info "$DISK_NAME" --pool "$POOL" >/dev/null 2>&1; then
  printf 'disk volume already exists: %s\n' "$DISK_NAME" >&2
  exit 1
fi

volume_created=0
cleanup_volume() {
  if (( volume_created == 1 )) && ! virsh --connect "$LIBVIRT_URI" dominfo "$VM_NAME" >/dev/null 2>&1; then
    virsh --connect "$LIBVIRT_URI" vol-delete "$DISK_NAME" --pool "$POOL" >/dev/null 2>&1 || true
  fi
}
trap cleanup_volume EXIT

virsh --connect "$LIBVIRT_URI" vol-create-as \
  --pool "$POOL" \
  --name "$DISK_NAME" \
  --capacity "$DISK_SIZE" \
  --format qcow2
volume_created=1

virt-install \
  --connect "$LIBVIRT_URI" \
  --name "$VM_NAME" \
  --memory "$RAM_MB" \
  --vcpus "$VCPUS" \
  --cpu host-passthrough \
  --osinfo detect=on,name=ubuntu24.04 \
  --disk "vol=${POOL}/${DISK_NAME},bus=virtio" \
  --cdrom "$ISO_PATH" \
  --network "network=default,model=virtio" \
  --graphics "spice,listen=127.0.0.1" \
  --video virtio \
  --sound ich9 \
  --channel spicevmc \
  --boot uefi \
  --noautoconsole
trap - EXIT

cat <<EOF
VM created: ${VM_NAME}

Open it with virt-manager, complete the Ubuntu Desktop installation, then:
  1. Eject the installer ISO in virt-manager.
  2. Install updates and reboot.
  3. Install Microsoft Edge and the Microsoft Intune app from Microsoft's
     current Linux enrollment documentation.
  4. Enroll this VM interactively. Do not clone or copy its disk afterwards.
EOF
