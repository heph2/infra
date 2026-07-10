{
  infra.modules.homeManager.heph = {
    home = {
      username = "heph";
      homeDirectory = "/home/heph";
      enableNixpkgsReleaseCheck = false;
    };
    programs.home-manager.enable = true;
  };
}
