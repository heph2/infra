let
  heph =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO5082w5a8Dljon2Qs9N3eGd5+Tg52zzawlZGeHw8D12";
  freya =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILCmIz2Selg5eJ77lvpJHgDJiRIOZbucMjDK5zrhTEWK";
  zima =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKmSgm97MHi+1dwh79BpyePwiXAcD2R+ceUKbBn6pVRv";
  sauron =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKECQ6GB+aeG76Sx8Ht4JJH0JmRrMNsf/uoA42eDZFK0";
  sauronRsa =
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCyBxXlNlsu4Q7fnox5xHrSf6teUfls0hfKzupR7qP5DTK/5KbPMnHoDtrONGVxsim6ChfDnsrVn/1DvDsQT+lbGzJAQ9ykUcyxKRxRRxLAeoQpWnZU0UNAW4hkJeD1QmZxxyd+x/CL2TouL15SPJgKNmvjZ//dM9uGD4SJL4gXwOiCJIgv6Z+TwI2gJ45Okcx2btvkHrnoVAipGH9HJVwJZUkxEB6Qsiqf6bPWHMpUxY+W70A2mga3epWynlLf/ChpAvnNhD+mBaVtG+GOuVfq6K4sLES7k0Y4bAvfU5mf4mX+YSLDKbipyIQbPTpTz6io154EFBNws7UZ6KNy1g2BOaPecPQh/iSnAm5oc9I5SkW6V52IbMJ8RiIqboZQ1T2SIAw6p84gJFHzxJD7Iohv2OF2+3tO8jRsnlOt7Tkt56KEBx3f4Uxol9KaInokfGOKoa+7KeoiiYK1q68+ki2a2kGAZX8mhjGsZ07NkBnAMifVxQT9GRZHhjMuwDjZT1jmK36HUXrLGIpwAwCwePT/n/pA/4V42aC9LIJqzXeOux6KprWPw3S1jQPGXDlVxb+g/p6YgwWygWbIod+1mbNf273YkQQtcdTwDPFc3oBCXfy/snAm5z7/UnRpz9IHDkIglYpP30sgPqkd5cyL6Zle+kyq5qnWJxzHhrMcgTcEw== root@sauron";
  tyr =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINvI0NxnjLWyG+oxLInkBvaKWqV6BWeTPLH5YeaCDYLG";
  hermes =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJODYFqjgPr4z6UmG0k/jx7LJ/WcJaysVmc8FgQyuJSS";
  gengar =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPJNdqrQa4WFfk3BclCAPxLyYQZ9zddcQDqUW7myXQjx";
  users = [ freya heph ];
in {
  "wg-key-freya.age".publicKeys = [ freya heph ];
  "terraform-b2.age".publicKeys = [ freya heph ];
  "wg-key-fenrir.age".publicKeys = [ heph freya ];
  "plakar-routeros-passphrase.age".publicKeys = [ freya heph ];
  "plakar-bitwarden-session.age".publicKeys = [ freya heph ];
  "imap-mbauce-mail.age".publicKeys = [ heph freya ];
  "mailgun-smtp-user.age".publicKeys = [ hermes freya ];
  "actual-oidc-client-secret.age".publicKeys = [ heph freya zima ];
  "cloudflare_api_token.age".publicKeys = [ heph freya zima sauron tyr hermes ];
  "acme-api-token-cloudflare.age".publicKeys = [ hermes freya ];
  "paperless-oidc-client-secret.age".publicKeys = [ heph freya zima sauron ];
  "homebox-oidc-client-secret.age".publicKeys = [ heph freya zima sauron tyr ];
  "vikunja-oidc-client-secret.age".publicKeys = [ heph freya tyr ];
  "vja-api-token.age".publicKeys = [ heph freya ];
  "mem0-api-key.age".publicKeys = [ heph freya ];
  "wallet-mcp-token.age".publicKeys = [ heph freya ];
  "typesafe-api-key.age".publicKeys = [ heph freya ];
  "pocket-id-encryption-key.age".publicKeys = [ heph freya sauron ];
  "netdata_token.age".publicKeys = [ sauron zima tyr ];
  "webdav_htpasswd.age".publicKeys = [ sauron heph freya ];
  "ups-admin.age".publicKeys = [ sauron ];
  "grafana-oidc-client-secret.age".publicKeys = [ heph zima freya tyr sauron ];
  "shortcut-api-token.age".publicKeys = [ heph freya ];
  "github-token.age".publicKeys = [ heph freya ];
  "hermes-agent-env.age".publicKeys = [ heph freya hermes ];
  "hermes-agent-session-token.age".publicKeys = [ freya sauronRsa ];
  "hermes-agent-api-server.env.age".publicKeys = [ freya sauron ];
  "hermes-agent-dashboard-password.age".publicKeys = [ freya ];
  "vaultwarden-oidc-client-secret.age".publicKeys = [ heph freya tyr ];
  "miniflux-db.password.age".publicKeys = [ heph freya tyr ];
  "miniflux-oidc-client-secret.age".publicKeys = [ heph freya tyr ];
  "gengar-lorebound-env.age".publicKeys = [ heph freya gengar ];
}
