{ config, lib, pkgs, ... }:
{
    mailserver = {
        enable = true;
        fqdn = "mail.mbauce.com";
        domains = [ "mbauce.com" ];
        loginAccounts = {
            "test@mbauce.com" = {
                # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt' > /hashed/password/file/location
                hashedPasswordFile = "/var/lib/mail-accounts/test/pssw";
                aliases = [
                   "info@mbauce.com"
                ];
            };
            "me@mbauce.com" = {
                hashedPasswordFile = "/var/lib/mail-accounts/me/pssw";
                aliases = [
                    "ml@mbauce.com" ## For MailingLists
                    "bill@mbauce.com" ## For stuff about billing and payments
                    "notes@mbauce.com" ## For notes
                    "shopping@mbauce.com" ## For shopping on e-commerce
                    "infra@mbauce.com" ## For VPS/IT stuff
                    "bank@mbauce.com" ## For banking stuff
                    "ssn@mbauce.com" ## For medical stuff
                    "book@mbauce.com" ## For book stuff
                    "mela@mbauce.com" ## AppleID
                    "social@mbauce.com" ## Social stuff
                    "spoty@mbauce.com" ## Music Stuff
                    "games@mbauce.com" ## Games Stuff
                    "ff@mbauce.com" ## Firefox
                    "fit@mbauce.com" ## Fitness and Diet
                    "horse@mbauce.com" ## Horse
                    "china@mbauce.com" ## China App and Stuff
                    "sport@mbauce.com" ## Sport Stuff
                    "pirate@mbauce.com" ## Pirating stuff
                    "subs@mbauce.com" ## Subscriptions in general
                    "discord@mbauce.com" ## Discord
                    "lang@mbauce.com" ## Languages, Anki
                ];
                sieveScript = ''
                    require ["fileinto", "mailbox"];
 
                    #if address :is "from" "gitlab@mg.gitlab.com" {
                    #    fileinto :create "GitLab";
                    #    stop;
                    #}
                    if header :matches "list-id" "nexa@server-naxa.polito.it" {
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
        certificateScheme = 3;
    };
    security.acme = {
        acceptTerms = true;
        defaults.email = "catch@mrkeebs.eu";
    };

    services.postfix = {
      extraConfig = ''
        inet_protocols = ipv4
      '';
    };
}
