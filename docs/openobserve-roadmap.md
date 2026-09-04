# OpenObserve and telemetry roadmap

## Current status

Phase 1 is implemented and deployed to the Pumba cluster through Flux.

- OpenObserve v0.92.2 is private and reachable through port-forward.
- An OpenTelemetry Collector DaemonSet runs on `tyr` and `zima`.
- Kubernetes pod logs are tailed from `/var/log/pods`.
- CRI/containerd logs are auto-detected and parsed.
- File offsets are persisted under `/var/lib/otelcol`.
- Logs are enriched with namespace, pod, container, pod UID, and node fields.
- Batching, retry, queue, and memory-limit guardrails are enabled.
- OpenObserve ingestion was verified with a live smoke test.
- The collector uses sealed OpenObserve credentials; its ServiceAccount has no API RBAC and token automount is disabled.

The collector starts at the end of each file, so the rollout does not backfill historical node logs.

## Remaining implementation plan

### 1. Harden and observe Phase 1

- Create a dedicated OpenObserve ingest credential instead of using the admin credential for collector ingestion.
- Keep the credential sealed and rotate the current shared credential after cutover.
- Configure stream/index retention and storage limits appropriate for the single-node Garage-backed trial.
- Watch collector errors, OpenObserve health, ingestion volume, and node resource usage for 24–48 hours.
- Tune exclusions and batch/queue limits if ingestion is noisy or resource-heavy.

### 2. Provide private LAN dashboard access

Decision: use public-domain names with split DNS and public ACME certificates:

- OpenObserve: `https://openobserve.pumba.pochi.casa`
- Headlamp: `https://headlamp.pumba.pochi.casa`
- Local DNS: LAN router records for both names, pointing to Tyr (`192.168.0.104`).
- TLS: Caddy DNS-01 through Cloudflare, using the existing encrypted API-token wiring.
- Access control: Tyr Caddy permits these vhosts only from `192.168.0.0/24` and proxies to the existing Traefik NodePort.
- Kubernetes: Traefik `Ingress` resources route each hostname to its private `ClusterIP` Service.

The cluster already has Traefik exposed on the Pumba node addresses (`192.168.0.104` and `192.168.0.105`), so this does not require public DNS records or public dashboard exposure. With the current design, local DNS should point to `192.168.0.104`, where Tyr Caddy terminates TLS and forwards to Traefik; do not add `.105` until a second TLS edge or a VIP is configured. Retain port-forward as a fallback during Tyr maintenance.

Implementation status:

- [x] Add the two Traefik `Ingress` resources.
- [x] Add the Tyr Caddy configuration.
- [ ] Add the two local DNS records on the LAN router.
- [ ] Deploy the Tyr Caddy configuration.
- [ ] Confirm certificate issuance and dashboard access from a LAN client.

### 3. Add filtered host telemetry

- Add journald collection with explicit unit/facility filters and bounded retention.
- Add host CPU, memory, disk, filesystem, network, and selected systemd metrics.
- Keep the existing Prometheus/Grafana setup during the trial.
- Measure volume and resource impact before expanding collection.

### 4. Instrument Lorebound

- Enable the existing OpenTelemetry seam in `apps/backend/instrumentation.ts`.
- Export HTTP, workflow, query, and error traces over private OTLP HTTP.
- Add service/resource attributes and sampling before enabling production-level trace volume.
- Correlate traces with collected backend logs where practical.

### 5. Add selected infrastructure telemetry

Only after the preceding stages are stable, add useful low-volume metrics/logs for Traefik, CNPG/Postgres, Dragonfly, Garage, Flux, and OpenObserve itself.

## Constraints

- Keep dashboards private; do not add public DNS or public ingress.
- Keep credentials encrypted and out of Git history.
- Do not replace Prometheus/Grafana during the evaluation.
- Do not introduce Flux Operator.
- Preserve reusable `base` and `clusters/pumba` overlays.
- Preserve unrelated working-tree changes.

## Acceptance criteria

- A LAN hostname opens each dashboard without port-forwarding.
- DNS names resolve only on the intended internal network.
- OpenObserve ingestion uses a least-privilege credential.
- Retention and storage behavior are bounded and documented.
- Host telemetry is filtered, searchable, and does not destabilize K3s.
- Lorebound traces are opt-in, resource-bounded, and searchable alongside logs.
