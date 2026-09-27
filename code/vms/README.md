# Virtual machines

VM definitions live here rather than in the NixOS host registry. Guests that do
not run NixOS cannot be represented by the modules under `hosts/`.

## Current target

- [`ubuntu-2604-gnome/`](./ubuntu-2604-gnome/) — Ubuntu Desktop 26.04 LTS
  with GNOME for Microsoft Intune.

The repository-native lab host is **Freya**: it is `x86_64-linux`, already
enables libvirt, SPICE USB redirection, virt-manager, and the required user
groups, and mounts the dedicated Samsung T7 VM filesystem at `/mnt/intune-vm`.
Aron is an Apple Silicon (`aarch64-darwin`) Mac, so it is not the right
host for this VM: Microsoft's Linux enrollment requirements specify an x86/64
CPU.

Important: Microsoft's enrollment page explicitly lists physical, Azure VM, or
Hyper-V machines. The Freya/libvirt path is useful for testing and development,
but Microsoft support for Intune enrollment inside a KVM/libvirt guest is not
stated there. Use Azure or Hyper-V when the tenant requires a documented
supported VM platform.
