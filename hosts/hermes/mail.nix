{ config, lib, pkgs, ... }: {
  age.secrets.cloudflare = {
    file = ../../secrets/cloudflare_api_token.age;
    mode = "640";
  };
  mailserver = {
    stateVersion = 3;
    enable = true;
    borgbackup = {
      enable = true;
      repoLocation = "ssh://root@100.126.120.86//data/backup/hermes";
      cmdPreexec = ''export BORG_RSH="ssh -o StrictHostKeyChecking=no"'';
    };
    fqdn = "mail.mbauce.com";
    domains = [ "mbauce.com" ];
    loginAccounts = {
      "me@mbauce.com" = {
        hashedPasswordFile = "/var/lib/mail-accounts/me/pssw";
        aliases = [
          "ml@mbauce.com" # # For MailingLists
          "bill@mbauce.com" # # For stuff about billing and payments
          "notes@mbauce.com" # # For notes
          "shopping@mbauce.com" # # For shopping on e-commerce
          "infra@mbauce.com" # # For VPS/IT stuff
          "bank@mbauce.com" # # For banking stuff
          "ssn@mbauce.com" # # For medical stuff
          "book@mbauce.com" # # For book stuff
          "mela@mbauce.com" # # AppleID
          "social@mbauce.com" # # Social stuff
          "spoty@mbauce.com" # # Music Stuff
          "games@mbauce.com" # # Games Stuff
          "ff@mbauce.com" # # Firefox
          "fit@mbauce.com" # # Fitness and Diet
          "horse@mbauce.com" # # Horse
          "china@mbauce.com" # # China App and Stuff
          "sport@mbauce.com" # # Sport Stuff
          "pirate@mbauce.com" # # Pirating stuff
          "subs@mbauce.com" # # Subscriptions in general
          "discord@mbauce.com" # # Discord
          "kagi-2@mbauce.com"
          "lang@mbauce.com" # # Languages, Anki
        ];
        sieveScript = ''
          require ["fileinto", "mailbox"];

          #if address :is "from" "gitlab@mg.gitlab.com" {
          #    fileinto :create "GitLab";
          #    stop;
          #}
          if header :matches "list-id" "nexa@server-nexa.polito.it" {
              fileinto :create "Nexa";
              stop;
          }

          # This must be the last rule, it will check if list-id is set, and
          # file the message into the Lists folder for further investigation
          #elsif header :matches "list-id" "<?*>" {
          #    fileinto :create "Lists";
          #    stop;
          #}
        '';
      };
    };
    x509.useACMEHost = config.mailserver.fqdn;
    # certificateScheme = "acme";
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "catch@mrkeebs.eu";
    certs.${config.mailserver.fqdn} = {
      dnsProvider = "cloudflare";
      environmentFile = config.age.secrets.cloudflare.path;
      reloadServices = [ "dovecot2" "postfix" ];
    };
  };

  systemd.services."acme-mail.mbauce.com".serviceConfig.EnvironmentFile =
    [ config.age.secrets.cloudflare.path ];

  services.postfix = { };

  services.prometheus.exporters = {
    rspamd = {
      enable = true;
      port = 7980;
    };
    dovecot = {
      enable = true;
      port = 9160;
    };
    postfix = {
      enable = true;
      port = 9117;
    };
  };
}
