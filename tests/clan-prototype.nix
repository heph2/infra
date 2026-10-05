# Catch fleet expansion, input drift, changed system closures, or unsafe deployment defaults.
{ prototype, baseline }:
let
  lib = baseline.inputs.nixpkgs.lib;
  candidate = prototype.nixosConfigurations.tyr.config;
  current = baseline.nixosConfigurations.tyr.config;
  productionLock = builtins.fromJSON (builtins.readFile (baseline + "/flake.lock"));
  productionPin = productionLock.nodes.${productionLock.nodes.root.inputs.nixpkgs}.locked;
in
assert lib.assertMsg (
  builtins.attrNames prototype.nixosConfigurations == [ "tyr" ]
) "The isolated Clan flake must expose only Tyr";
assert lib.assertMsg (
  (prototype.darwinConfigurations or { }) == { }
) "The Tyr prototype must not expose Darwin machines";
assert lib.assertMsg (
  candidate.system.build.toplevel.drvPath == current.system.build.toplevel.drvPath
) "Clan must preserve Tyr's complete system derivation";
assert lib.assertMsg (
  prototype.inputs.nixpkgs.narHash == productionPin.narHash
) "The prototype nixpkgs pin must match the root lock, not a stale nested lock";
assert lib.assertMsg (
  !candidate.clan.core.enableRecommendedDefaults
) "Clan's optional defaults must remain disabled during the experiment";
assert lib.assertMsg (
  candidate.clan.core.networking.targetHost == "root@tyr.invalid"
) "The prototype must not point at a live deployment target";
assert lib.assertMsg candidate.clan.core.deployment.requireExplicitUpdate
  "Tyr must be excluded from implicit bulk updates";
assert lib.assertMsg (
  candidate.clan.core.vars.generators == { }
) "The prototype must not generate or rotate credentials";
assert lib.assertMsg (builtins.all (
  entry: entry.assertion
) candidate.assertions) "The Clan Tyr configuration has failed NixOS assertions";
true
