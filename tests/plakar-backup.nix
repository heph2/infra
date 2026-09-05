{ config, lib }:
let
  service = config.systemd.services.plakarbackup-home-heph;
  timer = config.systemd.timers.plakarbackup-home-heph;
in
assert service.description == "Back up home-heph with Plakar";
assert service.serviceConfig.Type == "oneshot";
assert service.serviceConfig.User == "heph";
assert service.serviceConfig.Group == "users";
assert builtins.length service.serviceConfig.LoadCredential == 1;
assert timer.timerConfig.OnCalendar == "hourly";
assert timer.timerConfig.Persistent;
assert lib.hasInfix "sftp://root@sauron/bck/freya/plakar/home-heph" service.script;
assert lib.hasInfix "/home/heph" service.script;
assert lib.hasInfix "-ignore .cache" service.script;
assert !lib.hasInfix "/bck/freya/home-heph" service.script;
true
