{
  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    settings.model = {
      provider = "openai-codex";
      default = "gpt-6-luna";
    };
  };
}
