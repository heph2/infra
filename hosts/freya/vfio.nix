let

  platform = "amd";
  # RTX 3090
  gpuIDs = [
    "10de:2204" # Graphics
    "10de:1aef" # Audio
  ];
in { pkgs, lib, config, ... }: {
  options.vfio.enable = with lib;
    mkEnableOption "Configure the machine for VFIO";

  config = let cfg = config.vfio;
  in {
    boot = {
      kernelModules = [
        "kvm-${platform}"
        "vfio_pci"
        "vfio"
        "vfio_iommu_type1"
        "vfio_virqfd"

        "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
      ];

      kernelParams = [
        "${platform}_iommu=on"
        "${platform}_iommu=pt"
        "kvm.ignore_msrs=1"
        "pcie_acs_override=downstream,multifunction"
        #        "default_hugepagesz=1G"
        #        "hugepagesz=1G"
        #        "hugepages=16"
      ] ++ lib.optional cfg.enable
        # isolate the GPU
        ("vfio-pci.ids=" + lib.concatStringsSep "," gpuIDs);
    };
  };
}
