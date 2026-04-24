{ ... }: {
  flake.modules.darwin.user-marco = {
    users.users.marco.home = "/Users/marco";
    system.primaryUser = "marco";
    programs.zsh.enable = true;
  };
}
