# Sauron AirVPN port forwarding

AirVPN supports remote port forwarding, which is useful for BitTorrent peer connectivity. A forwarded port is allocated to the AirVPN account and reached through the VPN server; it is **not** a port to forward on the home router. See AirVPN's [port-forwarding FAQ](https://airvpn.org/faq/port_forwarding/) and [forwarded ports page](https://airvpn.org/ports/).

## Sauron prerequisites

Do not open a BitTorrent port on Sauron's physical/LAN interface or enable qBittorrent port forwarding until qBittorrent is isolated behind its VPN tunnel with a kill switch. A port open on the host without that isolation can expose the home connection instead of the VPN endpoint.

Before enabling the tunnel, you need:

1. An AirVPN WireGuard profile generated for Sauron. Keep the private key secret; do not commit or paste the profile into an issue or pull request.
2. A forwarded port reserved in AirVPN's client area. Use the same local port for qBittorrent, unless the AirVPN forwarding entry deliberately maps it to a different local port.
3. The profile installed as an encrypted host secret using this repository's agenix workflow. The decrypted profile must only be available at runtime.

The VPN-only design should keep qBittorrent behind the tunnel, including its incoming TCP and UDP peer port, and block its non-tunnel traffic if the VPN goes down. Keep the Web UI reachable only from the trusted LAN/service network; never expose it as the forwarded peer port. Sonarr, Radarr, Prowlarr, and Jellyfin should stay outside the VPN tunnel and retain access to qBittorrent and `/media/torrent`.

## Current status

Sauron currently runs qBittorrent directly on the host; no AirVPN tunnel or kill switch is configured. AirVPN supports port forwarding, but this repository change does not activate it: the account-specific WireGuard profile and reserved port are not present in the repository or host secrets. Do not treat the forwarded port as enabled until the VPN-isolated service is configured and an external reachability test confirms it through the AirVPN exit address.
