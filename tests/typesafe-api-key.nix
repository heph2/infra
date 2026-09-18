{ config, lib }:
let
  home = config.home-manager.users.heph;
  secret = home.age.secrets.typesafe-api-key;
  recipients = import ../secrets/secrets.nix;
in
assert home.age.secrets ? typesafe-api-key;
assert builtins.baseNameOf secret.file == "typesafe-api-key.age";
assert builtins.pathExists secret.file;
assert secret.path == "${home.home.homeDirectory}/.config/typesafe/api-key";
assert secret.mode == "0400";
assert builtins.elem "${home.home.homeDirectory}/.ssh/sekai_ed" home.age.identityPaths;
assert recipients."typesafe-api-key.age".publicKeys == recipients."mem0-api-key.age".publicKeys;
assert !(home.home.sessionVariables ? TYPESAFE_API_KEY);
assert lib.hasInfix "if [[ -r ${secret.path} ]]; then" home.programs.zsh.initContent;
assert lib.hasInfix ''export TYPESAFE_API_KEY="$('' home.programs.zsh.initContent;
assert lib.hasInfix ''/bin/cat ${secret.path})"'' home.programs.zsh.initContent;
true
