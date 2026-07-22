{ inputs, ... }:
{
  infra.modules.nixos.comfyui =
    { pkgs, ... }:
    {
      imports = [ inputs.comfyui-nix.nixosModules.default ];

      nix.settings = {
        substituters = [
          "https://comfyui.cachix.org"
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [
          "comfyui.cachix.org-1:33mf9VzoIjzVbp0zwj+fT51HG0y31ZTK3nzYZAX0rec="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };

      hardware.graphics = {
        enable = true;
        extraPackages = [ pkgs.rocmPackages.clr.icd ];
      };

      services.comfyui = {
        enable = true;
        gpuSupport = "rocm";
        enableManager = true;
        listenAddress = "127.0.0.1";
        port = 8188;
        openFirewall = false;
      };
    };
}
