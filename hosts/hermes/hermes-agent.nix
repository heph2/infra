{ config, ... }:
{
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  age.secrets.hermes-agent-env = {
    file = ../../secrets/hermes-agent-env.age;
    mode = "0400";
    owner = "hermes";
    group = "hermes";
  };

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    settings.model.default = "glm-5.1";
    settings.model.provider = "zai";
    environmentFiles = [
      config.age.secrets.hermes-agent-env.path
    ];

    #   mcpServers.github = {
    #     url = "https://api.githubcopilot.com/mcp/";
    #     auth = "oauth";
    #   };

    #   settings = {
    #     model = {
    #       default = "glm-5.1";
    #       provider = "zai";
    #     };
    #     toolsets = [ "all" ];
    #     terminal.backend = "local";
    #   };
  };
}
