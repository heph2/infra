{ config }:
let
  service = config.systemd.services.plakar-routeros-backup;
  timer = config.systemd.timers.plakar-routeros-backup;
in
assert service.serviceConfig.Type == "oneshot";
assert service.serviceConfig.User == "heph";
assert builtins.length service.serviceConfig.LoadCredential == 1;
assert
  config.services.plakar-routeros-backup.modes == [
    "export"
    "backup"
  ];
assert timer.timerConfig.OnCalendar == "weekly";
assert timer.timerConfig.Persistent;
true
