{ config, lib }:
let
  command = builtins.readFile config.home-manager.backupCommand;
in
assert config.home-manager.backupCommand != null;
assert lib.hasInfix "HOME_MANAGER_BACKUP_EXT" command;
assert lib.hasInfix "while [ -e" command;
true
