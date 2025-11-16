let
  heph = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO5082w5a8Dljon2Qs9N3eGd5+Tg52zzawlZGeHw8D12";
  freya = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILCmIz2Selg5eJ77lvpJHgDJiRIOZbucMjDK5zrhTEWK";
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
}
