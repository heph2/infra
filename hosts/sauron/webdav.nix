{ config, pkgs, ... }:

let
  mediaGroup = "media";
  musicDir = "/media/jelly/music";
  htpasswdFile = config.age.secrets.webdav_htpasswd.path;
in
{
  age.secrets.webdav_htpasswd = {
    file = ../../secrets/webdav_htpasswd.age;
    mode = "0400";
    owner = "webdav";
  };

  users.users.webdav = {
    isSystemUser = true;
    group = mediaGroup;
  };

  systemd.services.webdav = {
    description = "Read-only WebDAV music library";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.rclone}/bin/rclone serve webdav ${musicDir} --addr 127.0.0.1:8787 --read-only --htpasswd ${htpasswdFile} --no-modtime";
      Restart = "on-failure";
      User = "webdav";
      Group = mediaGroup;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ "/run" ];
    };
  };
}
