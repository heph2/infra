{ config, lib }:
let
  service = config.systemd.services.plakarbackup-home-heph;
  timer = config.systemd.timers.plakarbackup-home-heph;
  cloudService = config.systemd.services.plakarbackup-freya-system-gdrive;
  stagingDir = "/mnt/data/.plakar-staging";
in
assert service.description == "Back up home-heph with Plakar";
assert service.serviceConfig.Type == "oneshot";
assert service.serviceConfig.User == "heph";
assert service.serviceConfig.Group == "users";
assert service.unitConfig.RequiresMountsFor == [ "/home/heph" ];
assert builtins.length service.serviceConfig.LoadCredential == 1;
assert timer.timerConfig.OnCalendar == "hourly";
assert timer.timerConfig.Persistent;
assert !(builtins.hasAttr "plakarbackup-freya-system-gdrive" config.systemd.timers);
assert lib.hasInfix "-concurrency 1" cloudService.script;
assert (cloudService.environment.TMPDIR or null) == stagingDir;
assert lib.hasInfix "-ignore .plakar-staging" cloudService.script;
assert lib.elem "/mnt/data" cloudService.serviceConfig.RequiresMountsFor;
assert lib.hasInfix "install -d -m 0700 ${stagingDir}" cloudService.preStart;
assert lib.hasInfix "sftp://root@sauron/bck/freya/plakar/home-heph" service.script;
assert lib.hasInfix "-configdir /home/heph/.config/plakar" service.script;
assert lib.hasInfix "/home/heph" service.script;
assert lib.hasInfix "-ignore .cache" service.script;
assert !lib.hasInfix "/bck/freya/home-heph" service.script;
true
