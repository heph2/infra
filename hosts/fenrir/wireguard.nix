{ config, ... }:

{
  age.identityPaths = [ "/home/heph/.ssh/sekai_ed" ];

  age.secrets.wg-fenrir = {
    file = ../../secrets/wg-key-fenrir.age;
    mode = "0400";
  };

  networking.wireguard.interfaces.wg-road = {
    ips = [
      "10.253.90.11/32"
      "fdf9:7597:d29:90::11/128"
    ];
    privateKeyFile = config.age.secrets.wg-fenrir.path;

    peers = [
      {
        publicKey = "1OBrXcpODOJew77cY1iipMLSJvSwdoMNIAnzFxqFj0I=";
        allowedIPs = [
          "10.253.90.0/24"
          "192.168.0.0/24"
          "2a07:7e81:85f5::/64"
          "fdf9:7597:d29:90::/64"
        ];
        endpoint = "fenrir.pochi.casa:51820";
        persistentKeepalive = 25;
      }
    ];
  };
}
