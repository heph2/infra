let
  heph = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO5082w5a8Dljon2Qs9N3eGd5+Tg52zzawlZGeHw8D12";
  freya = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILCmIz2Selg5eJ77lvpJHgDJiRIOZbucMjDK5zrhTEWK";
  zima = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKmSgm97MHi+1dwh79BpyePwiXAcD2R+ceUKbBn6pVRv";
  sauron = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKECQ6GB+aeG76Sx8Ht4JJH0JmRrMNsf/uoA42eDZFK0";
  users = [
    freya
    heph
  ];
in
{
  "wg-key-freya.age".publicKeys = [
    freya
    heph
  ];
  "imap-mbauce-mail.age".publicKeys = [
    heph
    freya
  ];
  "actual-oidc-client-secret.age".publicKeys = [
    heph
    freya
    zima
  ];
  "cloudflare_api_token.age".publicKeys = [
    heph
    freya
    zima
    sauron
  ];
  "paperless-oidc-client-secret.age".publicKeys = [
    heph
    freya
    zima
    sauron
  ];
}
