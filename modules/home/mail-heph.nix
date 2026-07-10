{
  infra.modules.homeManager.mail-heph =
    { config, pkgs, ... }:
    {
      age = {
        identityPaths = [ "/home/heph/.ssh/sekai_ed" ];
        secrets.imap-mbauce.file = ../../secrets/imap-mbauce-mail.age;
      };

      programs = {
        mbsync.enable = true;
        msmtp.enable = true;
        notmuch.hooks = {
          preNew = "mbsync --all";
          postNew = "afew -tnv";
        };
      };

      accounts.email.accounts.personal = {
        address = "me@mbauce.com";
        imap.host = "mail.mbauce.com";
        mbsync = {
          enable = true;
          create = "maildir";
        };
        msmtp.enable = true;
        notmuch.enable = true;
        primary = true;
        realName = "Marco Bauce";
        passwordCommand = "${pkgs.coreutils-full}/bin/cat ${config.age.secrets.imap-mbauce.path}";
        smtp.host = "mail.mbauce.com";
        userName = "me@mbauce.com";
      };

      home.file = {
        ".config/afew/config".text = ''
          [SpamFilter]
          [KillThreadsFilter]
          [ListMailsFilter]
          [SentMailsFilter]
          sent_tag = sent
          [ArchiveSentMailsFilter]

          [Filter.0]
          message = "Filter Personal Mails"
          query = 'folder:~/Maildir/personal/'
          tags = +personal

          [Filter.1]
          message = "delete all message from fitexpress"
          query = from:no_reply@fitexpress.it
          tags = +junk;-new

          [Filter.2]
          message = "Filter mailing lists"
          query = from:nexa@server-nexa.polito.it
          tags = +lists;-new

          [Filter.3]
          message = "Filter Work Mails"
          query = 'to:m.bauce@davinci.care'
          tags = +work

          [Filter.4]
          message = "Filter OVH Mails"
          query = 'folder:~/Maildir/ovh/'
          tags = +ovh

          [InboxFilter]
        '';
        ".config/aliases".text = ''
          root: shopping@mbauce.com
        '';
      };
    };
}
