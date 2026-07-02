# K3s Internal Ingress Notes

These notes capture the working pattern used to expose k3s services internally with the same IPv6-facing entrypoint as services such as Sonarr, Radarr, and Jellyfin.

## Access Pattern

Public or internal DNS should point service hostnames at `sauron`'s IPv6 address:

```text
*.pochi.casa AAAA 2a07:7e81:85f5::beef
```

For an internal-only service, publish the hostname only in internal DNS. If the hostname is managed in Cloudflare, keep it DNS-only.

Traffic flow:

```text
client
  -> service.pochi.casa over IPv6
  -> sauron Caddy on 80/443
  -> k3s Traefik nodeport on tyr/zima
  -> Kubernetes Ingress host rule
  -> Kubernetes Service
```

## Cuppy

Cuppy is exposed as:

```text
https://cuppy.pochi.casa/
```

Current k3s details observed on 2026-07-01:

- Namespace: `cuppy`
- Service: `cuppy`, port `80`
- Ingress class: `traefik`
- Ingress host: `cuppy.pochi.casa`
- Traefik LoadBalancer addresses: `192.168.0.104`, `192.168.0.105`
- Traefik HTTP nodeport: `30298`
- Caddy upstreams: `192.168.0.104:30298 192.168.0.105:30298`

The Caddy vhost is configured in `hosts/sauron/caddy.nix`.

Required DNS record:

```text
cuppy.pochi.casa AAAA 2a07:7e81:85f5::beef
```

## Verification

Check the Kubernetes side:

```sh
kubectl -n cuppy get ingress,svc,pod -o wide
```

Check the route before DNS exists by forcing the IPv6 address:

```sh
curl -I --resolve 'cuppy.pochi.casa:443:[2a07:7e81:85f5::beef]' https://cuppy.pochi.casa/
```

A healthy Cuppy route returned `HTTP/2 200` through Caddy.

Check Caddy directly from `sauron`:

```sh
curl -I --resolve cuppy.pochi.casa:443:127.0.0.1 https://cuppy.pochi.casa/
systemctl is-active caddy
```

## Operational Gotchas

- The Cuppy ingress host was patched live from `cuppy.local` to `cuppy.pochi.casa`. Persist that change wherever the Cuppy manifests are stored, otherwise reapplying the original manifests may restore `cuppy.local`.
- Caddy can obtain certificates with the Cloudflare DNS plugin even before the AAAA record exists, but clients cannot resolve the service name until DNS is added.
- SSH commands to the nodes may need `ssh -F /dev/null -i ~/.ssh/sekai_ed ...` if the default SSH config has restrictive permissions.
- The kubeconfig context `pumba` was fixed by embedding certificate data and using `pumba.pochi.casa`; the k3s server on `tyr` includes `--tls-san pumba.pochi.casa`.
- During the Cuppy change, `nixos-rebuild switch` on `sauron` activated Caddy but reported unrelated failures for `netdata`, `suid-sgid-wrappers`, and `zfs-zed`. Caddy and the Cuppy route were healthy despite those failures.

## Disko Pinning

`sauron` and `freya` previously imported Disko with mutable `builtins.fetchTarball` references. The repository now pins Disko as a flake input and imports `inputs.disko.nixosModules.disko` from host configuration files. This avoids build failures when the upstream `master.tar.gz` hash changes.
