# Hypothetical Clan 26.05 refactor

Status: **isolated, opt-in Tyr prototype**, not a production migration or an
installation/deployment approval. The root flake, its lock, `.justfile`, host
modules, encrypted secrets, Terraform state/resources, and Kubernetes manifests
are unchanged. No machine was contacted or deployed.

## What this experiment proves

`clan/flake.nix` pins Clan's **26.05 branch** at
[`88d23f9e80115919d2b661e670ef5a24e6eb1442`](https://git.clan.lol/clan/clan-core/src/commit/88d23f9e80115919d2b661e670ef5a24e6eb1442).
It imports the local repository as `infra`, follows its nixpkgs, flake-parts,
disko, and sops-nix inputs, and has its own lock. This tests Clan 26.05 with our
existing unstable nixpkgs, **not** with Clan's default NixOS 26.05 package set.

The existing `hosts/tyr/configuration.nix` is a **flake-parts declaration**.
It cannot be imported directly as a Clan NixOS machine module. The prototype
uses `evalFlakeModule` with `modules/dendritic/` to obtain that declaration's
`system`, `specialArgs`, and `modules`, then feeds them to `clan-core.lib.clan`.
There is no second hand-maintained Tyr service/module list.

Only Tyr is in the inventory. No Clan service instances, generated credentials,
new disk layouts, networking services, or backup replacements are configured.
Clan's optional recommended defaults are disabled. Its ZFS module also supplies
host ID and force-import defaults independently of that flag; the adapter
explicitly retains Tyr's existing values. Further hosts need their own default
and storage review, not just another inventory entry.

The inventory target is deliberately `root@tyr.invalid`, and Tyr requires an
explicit update. The core target is wired to that inventory value as well, so
both CLI and module consumers see the same address. `.invalid` is a reserved
non-production domain, **not a security boundary**: command-line overrides or
local resolver configuration can bypass this precaution. Do not run install,
update, vars generation, or secret-writing commands against this prototype.

## Safe commands

Run from the repository root, with Nix flakes enabled. Track new files with
`git add` before evaluating. Use Nix **2.31 or newer** for the relative-path lock
format; this prototype was validated with Nix 2.34.8 (the packaged Clan CLI uses
Nix 2.31.5).

```sh
nix eval ./clan#nixosConfigurations --apply builtins.attrNames --json
nix eval ./clan#lib.parity
nix flake check ./clan --no-build
nix build ./clan#checks.x86_64-linux.tyr-parity --no-link
nix eval ./clan#nixosConfigurations.tyr.config.system.build.toplevel.drvPath --raw
nix run ./clan#clan-cli -- machines list --flake "path:$PWD/clan"
```

Use the explicit `path:` argument for the CLI: at this pinned version, both
`--flake ./clan` and a Git URL with `?dir=clan` lose the subdirectory during CLI
prefetch/selection and evaluate the production root instead (`clanInternals`
missing). The explicit path invocation was tested and lists only `tyr`.

`tests/clan-prototype.nix` checks the exposed fleet, nixpkgs pin against the root
lock, NixOS assertions, disabled defaults, guarded target, and absence of vars
generators. It requires the **same complete system toplevel derivation** as the
legacy Tyr, rather than maintaining a partial list of service options. A mutation
check confirmed that dropping the host ID preservation makes this assertion
fail. Derivation equality is not proof of successful builds, deployed runtime
behavior, or remote reachability.

The nested lock contains a snapshot of the production input graph. After root
input updates, deliberately refresh/review that graph too; ordinary evaluation
does not synchronize it. The test rejects a stale nixpkgs pin. Initial lock
creation hit a Nix nested-lock rebasing issue for Obscura's relative `vericert`
input. The committed graph retains that input with parent
`[ "infra", "obscura" ]` and rebases its follows paths under `infra`; do not
replace it with a guessed dependency revision or update the production lock as
a workaround. Preserve the checked-in lock rather than deleting it to rebuild
from scratch.

## Proposed ownership model

Keep the existing host-local modules and shared dendritic/Home Manager registry.
Clan would become a fleet inventory and orchestration layer, not a reason to
rewrite every NixOS service as a Clan Service.

- **Inventory:** machine names, platform class, reviewed deployment addresses,
  and explicit role tags. Map `infra.nixos.hosts` to NixOS machines and
  `infra.darwin.hosts` to machines with `machineClass = "darwin"`.
- **Host configuration:** continue using `hosts/<name>/default.nix`, hardware
  files, overlays, and imported application modules. Preserve Home Manager users,
  `extraSpecialArgs`, disk IDs, data mounts, and `system.stateVersion`.
- **Cross-machine services:** introduce `inventory.instances` only where a Clan
  Service demonstrably replaces existing wiring. Start with a low-risk service,
  not cluster identity, mail, authentication, or all backups at once.
- **Secrets:** keep agenix and existing SOPS recipients/files at first. Consider
  Clan vars for a new, isolated credential later; migration of existing secrets
  needs recipient, boot identity, runtime path, permissions, and rotation review.
- **Provisioning:** Terraform continues to own cloud resources, DNS, backends,
  and state addresses. Clan/nixos-anywhere/disko may eventually own installation
  on a new disposable node, not recreation of existing cloud or storage assets.
- **Kubernetes:** `clusters/pumba/` stays Flux/Kubernetes configuration. Clan does
  not replace its controllers, application manifests, or cluster state.

## Fleet boundaries before expanding

The root declares nine NixOS machines and one Darwin machine; declarations and
README labels do not establish current reachability or operational status.

- **Tyr / Zima:** x86_64 server configurations; k3s server/agent identity and
  endpoints are coupled. Preserve databases, ingress, OIDC, and host-only files.
- **Hermes:** Hetzner mail server with both SOPS and agenix, custom Plakar mail
  backups, and runtime-generated networking. Keep Terraform state/resource
  identities and networking intact; do not replace nixos-infect in this PR.
- **Freya / Sauron:** desktop/NAS with ZFS/disko and valuable data. Preserve ZFS
  identities/import behavior, encrypted-root boot, existing pools, and custom
  Plakar/Borg/USB jobs. Clan backup services are not an equivalent replacement
  without restore evidence, credential, mount, user, and scheduling parity.
- **Timballo:** x86_64 laptop with existing LUKS/GRUB and Home Manager. Preserve
  disk UUIDs and user state versions; evaluate older option/package usage first.
- **Fenrir:** aarch64 Asahi; retain apple-silicon modules/overlays, kernel,
  firmware, and boot setup. A generic ARM installer is not a validated path.
- **Pixie / Ushi:** AVF and WSL respectively. These need runtime/image-specific
  provisioning; do not inherit physical-machine disk/boot defaults.
- **Aron:** aarch64 Darwin. Clan documents updates of an existing nix-darwin
  installation, not NixOS installation on macOS. Preserve Determinate Nix,
  Homebrew, the `marco` Home Manager user, and Darwin activation hooks.
- **Fafnir:** commented-out router draft; not an active flake output or a pilot.

## Incremental migration gates

1. **This PR:** review the isolated adapter and limitations. Keep existing
   production rebuild commands authoritative. The prototype can be removed
   without changing any production configuration.
2. **Disposable validation:** build Tyr's full closure, inspect the complete
   configuration/closure diff, validate CLI operations on a disposable machine,
   and confirm its actual status/reachability. Obtain explicit approval before
   changing the reserved target or performing a switch. Keep the previous system
   generation and legacy rebuild path as rollback.
3. **Add one host at a time:** evaluate and build representative x86_64,
   aarch64/Asahi, Darwin, WSL, and AVF configurations with their existing package
   pins. Review Clan's unconditional defaults, duplicate sops/disko module
   imports, special arguments, disk identities, and SSH/build-host behavior.
4. **Services/vars separately:** move one cross-machine service or credential
   with concrete parity checks and rollback. Require backup restore tests before
   retiring any current backup job. Audit existing inline/host-local credentials
   separately; do not copy their values into new inventory or documentation.
5. **Production integration:** only after those gates, connect Clan to the main
   flake-parts module layer and preserve existing output names/rebuild workflows.
   Remove the old output constructor only after every platform is covered.

## Validation recorded for this PR

- Clan inventory/CLI lists only Tyr; parity evaluates to `true`; the parity
  derivation builds; prototype `nix flake check --no-build` passes (Nix warns
  about Clan's expected nonstandard `clanInternals` output).
- Legacy and Clan Tyr toplevel derivations evaluate to the **same drvPath** after
  neutralizing the unconditional ZFS defaults. Full system builds, runtime parity,
  remote updates, and restore tests are **not** claimed. No deployment, disk
  formatting, key generation, or secret decryption was performed.
- Alfred's test suite passes: 9 tests, 12 assertions. Use
  `nix shell --inputs-from . nixpkgs#babashka --command bb test` if `bb` is absent.
- The production root's `nix flake check --no-build` fails on Freya's existing
  `hosts/freya/home.nix` read of `/home/heph/.emacs.d/init.el` in pure evaluation.
  This unchanged, host-local dependency must be addressed separately before
  treating the entire production fleet as reproducibly evaluated.

## References inspected

- [Clan 26.05 overview](https://clan.lol/docs/26.05)
- [Flake-parts integration](https://clan.lol/docs/26.05/guides/flake-parts)
- [Inventory model](https://clan.lol/docs/26.05/guides/inventory/intro-to-inventory)
- [Clan options](https://clan.lol/docs/26.05/reference/options/clan)
- [Vars model](https://clan.lol/docs/26.05/guides/vars/intro-to-vars)
- [macOS support](https://clan.lol/docs/26.05/guides/macos)
- [Physical-machine quick start](https://clan.lol/docs/26.05/getting-started/quick-start)

Versioned documentation examples sometimes link to `main` or use a `main`
archive. The prototype instead follows the pinned 26.05 implementation and
verifies its inventory/CLI behavior directly.
