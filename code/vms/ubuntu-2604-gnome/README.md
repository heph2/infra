# Ubuntu 26.04 GNOME Intune VM

This is a small libvirt/QEMU setup for an interactive Ubuntu Desktop 26.04 LTS
VM. It is intended to run on **Freya**, the repository's x86_64 NixOS
workstation. It deliberately does not automate Microsoft Entra sign-in or
Intune enrollment.

**Support caveat:** Microsoft's current enrollment page lists physical, Azure
VM, or Hyper-V machines for Linux enrollment. It does not list KVM/libvirt.
Therefore this repository path is a practical lab/development VM, not a claim
that Microsoft supports Intune enrollment on a libvirt guest. If the tenant
requires a documented virtual platform, use an x86/64 Azure VM or Hyper-V
instead.

## Why this host and hypervisor

The repository already configures Freya with:

- x86_64 hardware;
- `virtualisation.libvirtd`;
- `virt-manager`;
- SPICE USB redirection; and
- `qemu-libvirtd`, `libvirtd`, and `kvm` access for the local user.

Aron is Apple Silicon. VMware Fusion and UTM can run ARM guests there, but
Microsoft's documented Linux enrollment requirement is Ubuntu Desktop 24.04 or
26.04 on an x86/64 CPU. QEMU x86 emulation on Apple Silicon would not be a good
Intune workstation and is intentionally rejected by `create.sh`.

## Requirements

- Ubuntu 26.04 has been released and its official `amd64` Desktop ISO is
  available.
- Freya has been booted with the current configuration and the current user can
  access `qemu:///system`.
- The system libvirt `default` network exists. The script starts it when
  needed.
- The Samsung T7 Touch is formatted as ext4 with label `INTUNE_VM` and mounted
  at `/mnt/intune-vm` by Freya's NixOS configuration.
- At least 4 virtual CPUs, 8 GiB RAM, and 80 GiB free disk are available. These
  are conservative starting values for GNOME plus Edge and the Intune app.
- The VM has outbound DNS and HTTPS access through libvirt's default NAT
  network.

## Prepare the Samsung T7

> **Destructive:** these commands erase every partition and all data on the
> Samsung T7 Touch with serial `S5KANJ0T106297M`. Verify the device identity
> before running them. They must never be used on a different disk.

```bash
T7=/dev/disk/by-id/usb-Samsung_PSSD_T7_Touch_S5KANJ0T106297M-0:0
lsblk -o NAME,TRAN,VENDOR,MODEL,SERIAL,SIZE,FSTYPE,MOUNTPOINTS "$T7"

printf 'label: gpt\n, , L\n' | sudo sfdisk --wipe always "$T7"
sudo udevadm settle
sudo mkfs.ext4 -F -L INTUNE_VM "${T7}-part1"
```

Deploy Freya so the new filesystem is mounted on demand:

```bash
cd /home/heph/code/infra
just deploy freya
ls -la /mnt/intune-vm
findmnt /mnt/intune-vm
```

`findmnt` must report an ext4 filesystem labelled `INTUNE_VM`. Do not unplug
this drive while the VM or its libvirt storage pool is active.

## Create the VM

Run this on Freya, from the repository checkout:

```bash
./code/vms/ubuntu-2604-gnome/create.sh
```

The script:

1. requires an `x86_64` host and `qemu:///system`;
2. verifies that `/mnt/intune-vm` is the writable ext4 filesystem labelled
   `INTUNE_VM`;
3. starts and autostarts libvirt's `default` NAT network;
4. creates and starts the `intune-t7` libvirt storage pool on the T7;
5. downloads the official Ubuntu Desktop ISO and `SHA256SUMS` into the local
   cache;
6. verifies the ISO against the official checksum list;
7. creates an 80 GiB qcow2 volume in the `intune-t7` pool; and
8. creates a UEFI VM with virtio disk/network, SPICE graphics, and 4 vCPUs/8 GiB
   RAM.

Open the new VM in **virt-manager** and complete the installation interactively.
During installation:

- select the default Ubuntu Desktop installation so GNOME is installed;
- enable disk encryption if the organization's policy requires it;
- create a normal user account; and
- use the default NAT network.

After installation, eject the installer ISO in virt-manager and reboot. The
VM's disk is a libvirt volume stored on the Samsung T7 at
`/mnt/intune-vm/images/ubuntu-2604-intune.qcow2`, not in the repository.

Resource defaults can be overridden without editing the script:

```bash
RAM_MB=12288 VCPUS=6 DISK_SIZE=120G ./code/vms/ubuntu-2604-gnome/create.sh
```

## Intune enrollment checklist

Microsoft's current Linux enrollment documentation requires:

- Ubuntu Desktop 24.04 or 26.04 LTS;
- a GNOME graphical desktop;
- an x86/64 CPU;
- Microsoft Edge 102.x or later; and
- the Microsoft Intune app for Linux.

That page lists physical, Azure VM, or Hyper-V machines. It does not list
libvirt/KVM, so treat the Freya path as unsupported by Microsoft unless the
organization confirms otherwise.

Inside the freshly installed VM:

1. Install all Ubuntu updates and reboot.
2. Install Microsoft Edge and the Microsoft Intune app with Microsoft's
   official Intune installer script (`Linux/Intune Installer` in
   `github.com/microsoft/shell-intune-samples`). It configures the
   packages.microsoft.com `prod` and Edge apt repositories — including the
   separate GPG keys Ubuntu 26.04 needs — and installs `microsoft-edge-stable`
   and `intune-portal`:

   ```bash
   curl -fsSL -o /tmp/intune-installer.sh \
     "https://raw.githubusercontent.com/microsoft/shell-intune-samples/master/Linux/Intune%20Installer/installer.sh"
   chmod +x /tmp/intune-installer.sh
   sudo bash /tmp/intune-installer.sh --verbose
   ```

   The script is idempotent and logs to `~/intune-installer.log`.

3. Reboot once so the `intune-portal` and `microsoft-identity-broker`
   services start from a clean boot. Do not commit the downloaded script,
   packages, or any enrollment data here.
4. Launch the Intune app, sign in with the work/school account, and complete
   the organization's compliance prompts.
5. Sign in to Edge with the same work account and verify access to the required
   work resources.
6. Reboot and confirm that the Intune app still reports the device as compliant.

Enrollment is interactive and tenant-specific. The VM should be treated as a
corporate-owned device, as required by Microsoft's Linux enrollment flow.

## VM lifecycle

```bash
virsh --connect qemu:///system pool-info intune-t7
virsh --connect qemu:///system list --all
virsh --connect qemu:///system start ubuntu-2604-intune
virsh --connect qemu:///system shutdown ubuntu-2604-intune
virt-manager
```

Take snapshots only for this same VM and coordinate rollback with the tenant's
policy. **Do not clone, copy, or distribute a disk after enrollment**: Intune
does not support cloned enrolled devices because enrollment and identity tokens
are replicated.

## Validation

The repository can validate the script without starting a VM:

```bash
bash -n code/vms/ubuntu-2604-gnome/create.sh
```

After creating the VM, validate the actual environment manually:

```bash
virsh --connect qemu:///system dominfo ubuntu-2604-intune
virsh --connect qemu:///system domblklist ubuntu-2604-intune
```

Then check in Ubuntu that GNOME is active, DNS/HTTPS work, the clock is synced,
Edge launches, and the Intune app reports compliance. If an interrupted
`virt-install` leaves a domain behind, inspect it with `virsh list --all` and
remove the incomplete domain/volume manually before retrying.

## References

- [Microsoft Intune supported platforms](https://learn.microsoft.com/en-us/intune/fundamentals/ref-supported-platforms)
- [Enroll a Linux device in Microsoft Intune](https://learn.microsoft.com/en-us/intune/user-help/enrollment/enroll-linux)
- [Microsoft Intune installer script](https://github.com/microsoft/shell-intune-samples/tree/master/Linux/Intune%20Installer)
- [Get the Microsoft Intune app for Linux](https://learn.microsoft.com/en-us/intune/user-help/company-portal/intune-app-linux)
- [Ubuntu 26.04 release schedule](https://documentation.ubuntu.com/release-notes/26.04/schedule/)
- [Ubuntu 26.04 releases](https://releases.ubuntu.com/resolute/)
