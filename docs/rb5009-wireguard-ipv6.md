# RB5009 WireGuard over IPv6

This runbook records the working road-warrior WireGuard setup on the RB5009. The public WireGuard transport is IPv6-only, while the tunnel carries IPv4 and IPv6 traffic to the home LAN and other VPN peers.

## Address plan

| Purpose | Value |
| --- | --- |
| Public endpoint | `fenrir.pochi.casa:51820` |
| Endpoint AAAA | `2a07:7e81:85f5::` |
| Endpoint A record | none |
| WireGuard interface | `wg-road` |
| Tunnel IPv4 network | `10.253.90.0/24` |
| RB5009 tunnel IPv4 | `10.253.90.1/24` |
| Allocated ULA | `fdf9:7597:d29::/48` |
| WireGuard ULA network | `fdf9:7597:d29:90::/64` |
| RB5009 tunnel IPv6 | `fdf9:7597:d29:90::1/64` |
| Home IPv4 LAN | `192.168.0.0/24` |
| Home IPv6 LAN | `2a07:7e81:85f5::/64` |
| Jellyfin host | `jelly.pochi.casa` / `2a07:7e81:85f5::beef` |

The endpoint deliberately has only an AAAA record. Clients therefore need working IPv6 before they can establish the tunnel.

## Router configuration

The RB5009 WireGuard public key is:

```text
1OBrXcpODOJew77cY1iipMLSJvSwdoMNIAnzFxqFj0I=
```

The relevant interface addressing is:

```routeros
/interface wireguard
add name=wg-road listen-port=51820 mtu=1420

/ip address
add address=10.253.90.1/24 interface=wg-road comment="WireGuard IPv4"

/ipv6 address
add address=fdf9:7597:d29:90::1/64 interface=wg-road advertise=no \
    comment="Wireguard ULA"
```

Do not copy or commit the WireGuard private key.

## iPhone peer

The iPhone 15 Pro uses:

```text
Public key: UezFQKsPPeRPRd2WY+uuyqzGom6oFFPdJQBmnVLpqjo=
IPv4:      10.253.90.10/32
IPv6:      fdf9:7597:d29:90::10/128
```

RouterOS must associate only the addresses owned by the iPhone with this peer:

```routeros
/interface wireguard peers
add interface=wg-road name=peer1 comment="Iphone 15 Pro" \
    public-key="UezFQKsPPeRPRd2WY+uuyqzGom6oFFPdJQBmnVLpqjo=" \
    allowed-address=10.253.90.10/32,fdf9:7597:d29:90::10/128
```

Do not add home LAN prefixes to the RouterOS peer's `allowed-address`; those networks are behind the RB5009, not the iPhone.

The corresponding iPhone configuration is:

```ini
[Interface]
PrivateKey = <IPHONE_PRIVATE_KEY>
Address = 10.253.90.10/32, fdf9:7597:d29:90::10/128

[Peer]
PublicKey = 1OBrXcpODOJew77cY1iipMLSJvSwdoMNIAnzFxqFj0I=
Endpoint = fenrir.pochi.casa:51820
AllowedIPs = 10.253.90.0/24, 192.168.0.0/24, 2a07:7e81:85f5::/64, fdf9:7597:d29:90::/64
PersistentKeepalive = 25
```

The broader ULA allocation (`fdf9:7597:d29::/48`) also works in the client `AllowedIPs`, but the actual WireGuard `/64` is sufficient and avoids routing unused ULA networks into the tunnel.

## IPv6 firewall

These rules must appear before their respective default drop rules:

```routeros
/ipv6 firewall filter
add chain=input action=accept protocol=udp in-interface-list=WAN dst-port=51820 \
    comment="WG: allow ipv6 handshake"

add chain=forward action=accept in-interface=wg-road out-interface=wg-road \
    comment="WG: peer-to-peer ipv6"

add chain=forward action=accept in-interface=wg-road \
    dst-address=2a07:7e81:85f5::/64 comment="WG: home LAN IPv6"
```

Required ordering:

1. Standard established/related, invalid, and ICMPv6 rules.
2. `WG: allow ipv6 handshake`.
3. Final input drop for traffic not arriving from `LAN`.
4. Standard forward rules.
5. WireGuard peer-to-peer and home-LAN forward rules.
6. Final forward drop for traffic not arriving from `LAN`.

The original failure mode was caused by placing the WireGuard accept rules after the default drops. LAN testing still handshook because it entered through a LAN interface, while mobile traffic entered through `WAN` and was dropped before reaching the WireGuard rule.

The IPv4 WAN firewall must not accept UDP port `51820`; this keeps the public transport IPv6-only.

## Verification

Check DNS:

```bash
dig +short AAAA fenrir.pochi.casa
dig +short A fenrir.pochi.casa
```

Expected: the AAAA query returns `2a07:7e81:85f5::`, and the A query returns nothing.

Check the peer and recent handshake:

```routeros
/interface wireguard peers print detail
```

Check the WireGuard firewall rules and counters:

```routeros
/ipv6 firewall filter print where comment~"WG"
/ipv6 firewall filter print stats
```

Test LAN reachability with the WireGuard ULA as the source:

```routeros
/ping address=2a07:7e81:85f5::beef \
    src-address=fdf9:7597:d29:90::1 count=5
```

Jellyfin normally redirects `/` to `/web/`; RouterOS reporting HTTP status `302` for this fetch proves that TCP, TLS, and the service are reachable:

```routeros
/tool fetch url="https://jelly.pochi.casa/" \
    src-address=fdf9:7597:d29:90::1 check-certificate=no output=none
```

For packet-level diagnosis:

```routeros
/tool/sniffer/quick interface=wg-road \
    ip-address=2a07:7e81:85f5::beef/128 port=443
```

If a mobile network has no IPv6 connectivity, it cannot reach this endpoint by design. If small requests work but larger pages stall, test MTU `1280` on both `wg-road` and the iPhone before investigating further.
