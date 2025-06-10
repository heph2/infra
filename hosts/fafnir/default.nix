{ config, pkgs, ... }: {

  boot = {
    kernel = {
      sysctl = {
        "net.ipv4.conf.all.forwarding" = true;
        "net.ipv6.conf.all.forwarding" = true;
      };
    };
  };

  networking = {
    nat = enable;
    useDHCP = false;
    hostName = "fafnir";
    nameserver = [ "1.1.1.1" ];
    # Define VLANS
    vlans = {
      wan = {
        id = 10;
        interface = "enp1s0";
      };
      lan = {
        id = 20;
        interface = "enp2s0";
      };
      iot = {
        id = 90;
        interface = "enp2s0";
      };
    };
  };

  interfaces = {
    # Don't request DHCP on the physical interfaces
    enp1s0.useDHCP = false;
    enp2s0.useDHCP = false;
    enp3s0.useDHCP = false;

    # Handle the VLANs
    wan.useDHCP = false;
    lan = {
      ipv4.addresses = [{
        address = "10.1.1.1";
        prefixLength = 24;
      }];
    };
    iot = {
      ipv4.addresses = [{
        address = "10.1.90.1";
        prefixLength = 24;
      }];
    };
  };

  # setup pppoe session
  services.pppd = {
    enable = true;
    peers = {
      vodafone = {
        # Autostart the PPPoE session on boot
        autostart = true;
        enable = true;
        config = ''
          plugin rp-pppoe.so wan

          # pppd supports multiple ways of entering credentials,
          # this is just 1 way
          name "vodafonedsl"
          password "vodafonedsl"

          persist
          maxfail 0
          holdoff 5

          noipdefault
          defaultroute
        '';
      };
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    mg
    htop
    ppp
    ethtool
    tcpdump
    conntrack-tools
  ];
}
