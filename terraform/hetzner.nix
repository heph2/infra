{ config, lib, ... }:
{
  terraform = {
    required_providers = {
      sops = {
        source = "carlpett/sops";
        version = "~> 0.5";
      };
      hcloud = {
        source = "hetznercloud/hcloud";
      };
    };
    backend.s3 = { };
  };

  data.sops_file.terraform_secrets = {
    source_file = "../../secrets/secrets.yaml";
  };

  provider.hcloud = {
    token = lib.tf.ref ''data.sops_file.terraform_secrets.data["terraform.hcloud.token"]'';
  };

  resource.hcloud_ssh_key.default = {
    name = "ssh-sekay";
    public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILCmIz2Selg5eJ77lvpJHgDJiRIOZbucMjDK5zrhTEWK heph@fenrir";
  };

  resource.hcloud_server.hermes = {
    name = "hermes";
    image = "debian-11";
    server_type = "cx11";
    user_data = lib.tf.file "./nixos-infect.sh";
    ssh_keys = [ (config.resource.hcloud_ssh_key.default "name") ];
    public_net = [
      {
        ipv4_enabled = true;
        ipv6_enabled = true;
      }
    ];
  };

  resource.hcloud_rdns.master = {
    server_id = config.resource.hcloud_server.hermes "id";
    ip_address = config.resource.hcloud_server.hermes "ipv4_address";
    dns_ptr = "mail.mbauce.com";
  };

  output.hermes_ip.value = config.resource.hcloud_server.hermes "ipv4_address";
}
