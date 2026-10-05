# Lorebound alpha backend on Gengar

Gengar runs the Medusa API/Admin, PostgreSQL 17, and Redis with Docker Compose under a NixOS-managed systemd unit. The database and Redis have persistent Docker volumes and are not published on host ports. Caddy serves `https://api.lorebound.shop`; the storefront stays separately hosted. This is a single-host alpha setup, not a highly available or backed-up production service.

The backend image must be published for both `linux/amd64` and `linux/arm64`; Gengar is `aarch64-linux`. Use the immutable commit SHA tag from `ghcr.io/heph2/lorebound-backend`.

## Prepare the encrypted environment

The environment is an agenix secret at `secrets/gengar-lorebound-env.age`, encrypted for the Gengar SSH host key and the infra maintainer key. Never put the plaintext environment file in Git or send the R2 secret access key in chat.

Edit the encrypted secret locally from the infra repository's `secrets/` directory:

```sh
cd /home/heph/code/infra/secrets
AGENIX_RULES="$PWD/secrets.nix" nix run github:ryantm/agenix -- -e gengar-lorebound-env.age -i "$HOME/.ssh/sekai_ed"
```

The `-i` path must be the private SSH key matching a recipient in `secrets.nix`; `sekai_ed` is the maintainer key available on the current workstation. If your key is elsewhere, substitute its path. Replace the template values with the following variables:

```dotenv
LOREBOUND_IMAGE_TAG=84226066129f6f64cdb633c43605ede2d726922d
GHCR_TOKEN=<GitHub classic PAT with read:packages>
POSTGRES_PASSWORD=<random-hex>
REDIS_PASSWORD=<random-hex>
JWT_SECRET=<random-secret>
COOKIE_SECRET=<random-secret>
STORE_CORS=https://lorebound.shop,https://www.lorebound.shop
AUTH_CORS=https://lorebound.shop,https://www.lorebound.shop,https://api.lorebound.shop
S3_FILE_URL=<public-R2-asset-URL>
S3_ACCESS_KEY_ID=<R2-token-access-key-ID>
S3_SECRET_ACCESS_KEY=<R2-token-secret-access-key>
S3_BUCKET=<R2-bucket-name>
S3_ENDPOINT=https://<Cloudflare-account-ID>.r2.cloudflarestorage.com
```

The encrypted template already contains random database and app secrets; keep them or regenerate them locally with `openssl rand -hex 32` (hex is safe for database and Redis passwords in their connection URLs). The template uses the already-published image tag shown above; update it only when selecting a newer published commit. Create a GitHub classic personal access token for the `heph2` account with the `read:packages` scope and access to `lorebound-backend`; place it in `GHCR_TOKEN`. Never paste the token into chat or shell history. The start script logs in with `--password-stdin` using a temporary root-only Docker config under `/run`, which it deletes when startup finishes. Fill in all blank R2 values before starting the service. Keep `S3_FILE_URL` (the public asset URL) distinct from `S3_ENDPOINT` (the private S3-compatible API endpoint). The service is deliberately not enabled at boot by default; do not start it until all required values are valid and the NixOS configuration has deployed the agenix secret.

## Retrieve the R2 values in Cloudflare

1. Open **Cloudflare Dashboard → Storage & databases → R2 → Overview**. Note the **Account ID**; it goes into `S3_ENDPOINT` as `https://<ACCOUNT_ID>.r2.cloudflarestorage.com`.
2. Create or select the bucket for public product assets. Its exact name goes into `S3_BUCKET`.
3. Under **R2 → Overview → Manage (API Tokens)**, create an account or user API token with **Object Read & Write**, scoped to **this bucket only**. Copy the **Access Key ID** into `S3_ACCESS_KEY_ID` and the **Secret Access Key** into `S3_SECRET_ACCESS_KEY` in the encrypted file. The secret key is only shown at creation; store it directly in the agenix editor, not in chat or shell history.
4. In that bucket's **Settings**, expose it with a public URL. A Cloudflare-managed `r2.dev` URL is intended for development; for the alpha's customer-facing assets, prefer connecting a custom domain (for example, `assets.lorebound.shop`) under **Custom Domains**. Use the resulting base URL for `S3_FILE_URL`. Verify **Public URL Access** is allowed or the custom domain status is **Active**. Public access is required for storefront images; keep the S3 API token narrowly scoped.
5. `S3_REGION` is already set to `auto` in the Compose service and does not need to be added to the secret file.

## First start

Before starting the service, verify OCI permits inbound TCP 80 and 443 to Gengar in the VCN security list or attached NSG, and that the instance has a public IP, a public-subnet route through an Internet Gateway, and the NixOS firewall permits those ports. Then, after the encrypted environment is ready and the NixOS configuration is deployed:

```sh
sudo systemctl start lorebound-stack
sudo systemctl status lorebound-stack
curl --fail https://api.lorebound.shop/health
```

The unit starts PostgreSQL and Redis, runs `medusa db:migrate` from the selected image, and only then starts the backend. Keep the existing API DNS live until Gengar is independently validated; plan any DNS cutover separately. Create the initial Admin user after the backend is available, then open `https://api.lorebound.shop/app` and create a publishable API key for the storefront.

## Updating the backend

After CI publishes a multi-architecture image for a commit, edit `LOREBOUND_IMAGE_TAG` in the agenix-encrypted environment, deploy the updated NixOS configuration, and restart the unit:

```sh
sudo systemctl restart lorebound-stack
```

The unit reruns the idempotent Medusa migration command before bringing up the new backend container. Review logs with:

```sh
docker-compose --file /etc/lorebound/compose.yaml --env-file /run/agenix/lorebound-env logs --follow backend
```

## Host metrics

Node Exporter is enabled on loopback only (port 9100), so it is not exposed to the public network. To inspect current host metrics, use an SSH tunnel and query `http://127.0.0.1:9100/metrics`. The metrics are not retained; add a remote Prometheus scrape target if historical graphs or alerts are needed.

## Alpha limitations

- Gengar, PostgreSQL, and Redis are single points of failure.
- PostgreSQL and Redis data survive container replacement in local Docker volumes, but this is not a backup. Configure off-host PostgreSQL backups and test a restore before live payments.
- Redis uses AOF persistence, but a Redis volume failure can still lose queued work.
- The Medusa API and worker run in shared mode in one backend container.
- The R2 asset bucket must be publicly readable through its `S3_FILE_URL`; keep its API token narrowly scoped.
- Deployments are manual. A failed migration prevents the new backend from starting, but rollbacks still need a compatible database schema.
