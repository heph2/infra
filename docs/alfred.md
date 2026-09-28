# Alfred

Alfred is the repository's small Babashka personal-operations CLI. It is
installed by the home-manager user-tools module and is also available as
`nix build .#alfred`.

## Daily tasks

```sh
alfred today
alfred today --expenses
alfred tasks upcoming
```

These commands read tasks through `vja --json`. Alfred does not create,
complete, edit, or defer tasks; use `vja` for changes. `--expenses` also reads
`LEDGER_FILE` (or accepts `--file`) and prints the current-month expense total.

## Finance

```sh
alfred money chart --months 6
alfred money summary --file ~/env/finance/2026.journal
```

The journal is still authoritative. Alfred uses hledger's CSV output rather
than scraping terminal reports.

## IP and machine inventory

Records live in `data/network.edn` and are intentionally versioned with the
repository:

```sh
alfred ip list
alfred ip list --network homelab-v6
alfred ip check
alfred host list
alfred host show zima
```

`ip check` reports malformed, duplicate, and out-of-network addresses. Alfred
does not update DHCP, DNS, routers, or Nix host configuration.

## Nix builds

```sh
alfred nix hosts
alfred nix plan zima
alfred nix build zima
alfred nix plan aron
alfred nix build aron
alfred nix hosts --flake /path/to/infra
```

Targets are discovered from the current directory's flake, or an explicit
`--flake PATH` / `ALFRED_FLAKE`. `plan` prints the existing `just` recipe and
`build` runs it from that directory. Alfred deliberately does not switch,
deploy remotely, reboot, or modify a host.

## Development

```sh
nix develop
bb test/alfred_test.clj
```
