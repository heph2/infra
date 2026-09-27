{ inputs, ... }:
{
  infra.modules.nixos.comfyui =
    { lib, pkgs, ... }:
    let
      comfyPkgs = import inputs.comfyui-nix.inputs.nixpkgs {
        system = pkgs.stdenv.hostPlatform.system;
        config = {
          allowUnfree = true;
          allowBrokenPredicate = pkg: (pkg.pname or "") == "open-clip-torch";
        };
      };
      versions = import "${inputs.comfyui-nix}/nix/versions.nix";
      basePythonOverrides = import "${inputs.comfyui-nix}/nix/python-overrides.nix" {
        pkgs = comfyPkgs;
        inherit versions;
        gpuSupport = "rocm";
      };
      comfyPackages = import "${inputs.comfyui-nix}/nix/packages.nix" {
        pkgs = comfyPkgs;
        inherit versions;
        lib = comfyPkgs.lib;
        gpuSupport = "rocm";
        pythonOverrides =
          final: prev:
          (basePythonOverrides final prev)
          // {
            terminado = prev.terminado.overridePythonAttrs (_: {
              doCheck = false;
              pythonImportsCheck = [ ];
            });
          };
      };
    in
    {
      imports = [ inputs.comfyui-nix.nixosModules.default ];

      nix.settings = {
        substituters = [
          "https://cache.nixos.org"
          "https://comfyui.cachix.org"
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShvY="
          "comfyui.cachix.org-1:33mf9VzoIjzVbp0zwj+fT51HG0y31ZTK3nzYZAX0rec="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };

      hardware.graphics = {
        enable = true;
        extraPackages = [ pkgs.rocmPackages.clr.icd ];
      };

      services.comfyui = {
        packageSet = lib.mkForce {
          default = comfyPackages.default;
          rocm = comfyPackages.default;
        };
        enable = true;
        gpuSupport = "rocm";
        enableManager = false;
        listenAddress = "127.0.0.1";
        port = 8188;
        openFirewall = false;
        extraArgs = [
          "--disable-xformers"
          "--use-pytorch-cross-attention"
        ];
      };
    };
}
