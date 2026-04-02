{ config, ... }:
{
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  age.secrets.hermes-agent-auth = {
    file = ../../secrets/hermes-agent-auth.age;
    mode = "0400";
    owner = "hermes";
    group = "hermes";
  };

  age.secrets.hermes-agent-telegram = {
    file = ../../secrets/hermes-agent-telegram.age;
    mode = "0400";
    owner = "hermes";
    group = "hermes";
  };

  age.secrets.hermes-agent-z-ai = {
    file = ../../secrets/hermes-agent-z-ai.age;
    mode = "0400";
    owner = "hermes";
    group = "hermes";
  };

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    authFile = config.age.secrets.hermes-agent-auth.path;

    environmentFiles = [
      config.age.secrets.hermes-agent-z-ai.path
    ];

    mcpServers.github = {
      url = "https://api.githubcopilot.com/mcp/";
      auth = "oauth";
    };

    settings = {
      model = {
        default = "glm-5.1";
        provider = "zai";
      };
      providerBaseUrl = "https://open.bigmodel.cn/api/paas/v4";
      apiKeyEnvVar = "ZAI_API_KEY";
      toolsets = [ "all" ];
      terminal.backend = "local";

      delivery = {
        platform = "telegram";
        telegram = {
          botTokenFile = config.age.secrets.hermes-agent-telegram.path;
          allowedUsers = [ "zHeph2" ];
          parseMode = "Markdown";
        };
      };
    };
  };
}
