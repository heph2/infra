{ config, ... }:
{
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  age.secrets.hermes-agent-auth = {
    file = ../../secrets/hermes-agent-auth.age;
    mode = "0400";
    owner = "hermes";
    group = "hermes";
  };

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    authFile = config.age.secrets.hermes-agent-auth.path;

    mcpServers.github = {
      url = "https://api.githubcopilot.com/mcp/";
      auth = "oauth";
    };

    settings = {
      model = {
        default = "gpt-5.4";
        provider = "openai-codex";
      };
      toolsets = [ "all" ];
      terminal.backend = "local";
    };
  };
}
