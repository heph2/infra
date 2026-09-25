{ config, pkgs, ... }:

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

    # Do not let the generated peer routes capture the public endpoint. It is
    # in the same /64 as the home LAN route below, so install the routes
    # explicitly and keep the endpoint on the physical interface.
    allowedIPsAsRoutes = false;
    postSetup = ''
      ${pkgs.iproute2}/bin/ip route replace 10.253.90.0/24 dev wg-road
      ${pkgs.iproute2}/bin/ip route replace 192.168.0.0/24 dev wg-road
      ${pkgs.iproute2}/bin/ip -6 route replace fdf9:7597:d29:90::/64 dev wg-road
      ${pkgs.iproute2}/bin/ip -6 route replace 2a07:7e81:85f5::/64 dev wg-road
      ${pkgs.iproute2}/bin/ip -6 route replace 2a07:7e81:85f5::/128 via fe80::d221:f9ff:fe33:d1b1 dev wlan0
    '';

    peers = [
      {
        publicKey = "1OBrXcpODOJew77cY1iipMLSJvSwdoMNIAnzFxqFj0I=";
        allowedIPs = [
          "10.253.90.0/24"
          "192.168.0.0/24"
          "2a07:7e81:85f5::/64"
          "fdf9:7597:d29:90::/64"
        ];
        # Use the documented stable AAAA directly so boot does not depend on
        # DNS being available when the peer unit starts.
        endpoint = "[2a07:7e81:85f5::]:51820";
        persistentKeepalive = 25;
      }
    ];
  };
}
