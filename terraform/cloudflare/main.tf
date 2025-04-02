data "sops_file" "terraform_secrets" {
  source_file = "../../secrets/secrets.yaml"
}

resource "cloudflare_record" "www" {
  zone_id = var.zone_id
  name    = "www"
  value   = "203.0.113.10"
  type    = "A"
  proxied = true
}

resource "cloudflare_record" "_dnslink" {
  zone_id = var.zone_id
  name    = "_dnslink.ipfs"
  value   = "dnslink=/ipfs/QmRWup7MWSUB8gKZ1e8sSAsRCvw6cTYHyNHT8kSpveb2uu"
  type    = "TXT"
  proxied = false
}

resource "cloudflare_record" "ipfs_cname" {
  zone_id = var.zone_id
  name    = "ipfs"
  value   = "gateway.ipfs.io"
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "firefly" {
  zone_id = var.zone_id
  name    = "wallet"
  value   = "100.76.226.130"
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "firefly-importer" {
  zone_id = var.zone_id
  name    = "wallet-importer"
  value   = "100.76.226.130"
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "caldav-radicale" {
  zone_id = var.zone_id
  name    = "calendar"
  value   = "100.93.253.62"
  type    = "A"  
  proxied = false
}

resource "cloudflare_record" "wildcard-tailscale" {
  zone_id = var.zone_id
  name    = "*.ts"
  value   = "100.75.100.69"
  type    = "A"
  proxied = false
}

#### TEST
resource "cloudflare_record" "photoprism" {
  zone_id = var.zone_id
  name    = "photo"
  value   = "100.116.32.35"
  type    = "A"
  proxied = false
}

##### mbauce.com
resource "cloudflare_record" "mail" {
  zone_id = "c76d32c0ea57d5c2dc646543a5906a4f"
  name    = "mail"
  value   = "135.181.85.238"
  type    = "A"  
  proxied = false
}

resource "cloudflare_record" "mail_mx" {
  zone_id = "c76d32c0ea57d5c2dc646543a5906a4f"
  name = "@" # apex
  value   = "mail.mbauce.com"
  priority = 10
  type    = "MX"  
  proxied = false
}

resource "cloudflare_record" "mail_spf" {
  zone_id = "c76d32c0ea57d5c2dc646543a5906a4f"
  name = "@" # apex
  value   = "v=spf1 a:mail.mbauce.com -all"
  type    = "TXT"
  proxied = false
}

resource "cloudflare_record" "mail_dkim" {
  zone_id = "c76d32c0ea57d5c2dc646543a5906a4f"
  name = "mail._domainkey"
  value   = "v=DKIM1; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDel3AUu/glMl7yPhYOYsxsZoX1ChEFIpv12KuBqMkeaiKuPWetULUCHY7qSgJ5i2kJwzH8GSgCk2dk8dFbD8b1wq9HxF/kjCmjxAewfNnbEv9Xo4Gv393rmOm+jdqXpHV03/RVl9lx0QVafjCRpbUms7ak24pOGyp7y2L0qWlLewIDAQAB"
  type    = "TXT"
  proxied = false
}

resource "cloudflare_record" "mail_dmarc" {
  zone_id = "c76d32c0ea57d5c2dc646543a5906a4f"
  name = "_dmarc"
  value   = "v=DMARC1; p=quarantine"
  type    = "TXT"
  proxied = false
}

resource "cloudflare_record" "_dnslink_test" {
  zone_id = "c76d32c0ea57d5c2dc646543a5906a4f"
  name    = "_dnslink.ipfs"
  value   = "dnslink=/ipfs/QmYMCnPLwkF2ASuStJqFsUzY2sXZSsR4zHA89H7hcK9cY8"
  type    = "TXT"
  proxied = false
}

## Bluesky
resource "cloudflare_record" "_atproto" {
  zone_id = "c76d32c0ea57d5c2dc646543a5906a4f"
  name    = "_atproto.bsky"
  value   = "did=did:plc:3p6agdyhmcrnkijgz2mgtqh2"
  type    = "TXT"
  proxied = false
}

resource "cloudflare_record" "murmur" {
  zone_id = "c76d32c0ea57d5c2dc646543a5906a4f"
  name    = "voice"
  value   = "135.181.85.238"
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "blog" {
  zone_id = "c76d32c0ea57d5c2dc646543a5906a4f"
  name    = "www"
  value   = "heph2.github.io"
  type    = "CNAME"
  proxied = false
}
