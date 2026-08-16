{
  config,
  lib,
  pkgs,
}:
let
  service = config.systemd.services.plakar-remarkable-backup;
in
assert service.serviceConfig.Type == "oneshot";
assert service.serviceConfig.User == "heph";
assert builtins.elem pkgs.openssh service.path;
assert builtins.length service.serviceConfig.LoadCredential == 1;
assert !lib.hasInfix "SSH_AUTH_SOCK" service.script;
assert lib.hasInfix "/home/heph/.ssh/plakar" service.script;
assert lib.hasInfix "remarkable://10.11.99.1" service.script;
assert lib.hasInfix ''ATTR{idVendor}=="04b3"'' config.services.udev.extraRules;
assert lib.hasInfix ''ATTR{idProduct}=="4010"'' config.services.udev.extraRules;
true
