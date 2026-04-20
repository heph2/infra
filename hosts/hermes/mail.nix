{ config, lib, pkgs, ... }: {
  age.secrets.cloudflare = {
    file = ../../secrets/acme-api-token-cloudflare.age;
    mode = "640";
  };
  age.secrets.mailgun-smtp = {
    file = ../../secrets/mailgun-smtp-user.age;
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
          "anime@mbauce.com"
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

  services.dovecot2 = {
    mailPlugins.globally.enable = [ "old_stats" ];
    extraConfig = ''
      service old-stats {
        unix_listener old-stats {
          user = dovecot-exporter
          group = dovecot-exporter
          mode = 0660
        }
        fifo_listener old-stats-mail {
          mode = 0660
          user = dovecot2
          group = dovecot2
        }
        fifo_listener old-stats-user {
          mode = 0660
          user = dovecot2
          group = dovecot2
        }
      }
      plugin {
        old_stats_refresh = 30 secs
        old_stats_track_cmds = yes
      }
    '';
  };

  services.postfix = {
    settings.main = {
      relayhost = [ "[smtp.eu.mailgun.org]:587" ];
      relay_domains = [ "mbauce.com" ];
      smtp_sasl_auth_enable = true;
      smtp_sasl_password_maps = "texthash:/etc/postfix/sasl_passwd";
      smtp_sasl_security_options = "noanonymous";
    };
  };

  systemd.services.mailgun-sasl-passwd = {
    description = "Generate Postfix SASL password file for Mailgun";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      echo '[smtp.eu.mailgun.org]:587 postmaster@mailgun.mbauce.com:'$(cat ${config.age.secrets.mailgun-smtp.path}) > /etc/postfix/sasl_passwd
      ${pkgs.postfix}/bin/postmap /etc/postfix/sasl_passwd
      chown root:postfix /etc/postfix/sasl_passwd
      chmod 640 /etc/postfix/sasl_passwd
    '';
  };

  systemd.services.postfix = {
    requires = [ "mailgun-sasl-passwd.service" ];
    after = [ "mailgun-sasl-passwd.service" ];
  };

  services.prometheus.exporters = {
    dovecot = {
      enable = true;
      # port = 9160;
      socketPath = "/var/run/dovecot2/old-stats";
    };
    postfix = {
      enable = true;
      # port = 9117;
    };
  };
}
