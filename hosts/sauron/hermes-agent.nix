{ config, ... }:
{
  age.secrets.hermes-agent-session-token = {
    file = ../../secrets/hermes-agent-session-token.age;
    owner = "hermes";
    mode = "0400";
  };

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    backend = {
      mode = "serve";
      host = "192.168.0.106";
      port = 9119;
      waitFor = "interface";
      interfaceName = "enp10s0";
      sessionTokenFile = config.age.secrets.hermes-agent-session-token.path;
    };
    settings = {
      model = {
        provider = "openai-codex";
        default = "gpt-6-luna";
      };
      dashboard.basic_auth = {
        username = "hermes";
        password_hash = "scrypt$16384$8$1$jGydD+YpugEc7WeuZ0pSwA==$OASxzYduMq015kyvjk04Pq9h6XYT7xvi6nqVoZDvChw=";
      };
    };
  };

  networking.firewall.interfaces.enp10s0.allowedTCPPorts = [ 9119 ];
}
