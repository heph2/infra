# Lorebound alpha backend on Gengar

Gengar runs the Medusa API/Admin, PostgreSQL 17, and Redis with Docker Compose under a NixOS-managed systemd unit. The database and Redis have persistent Docker volumes and are not published on host ports. Caddy serves `https://api.lorebound.shop`; the storefront stays separately hosted. This is a single-host alpha setup, not a highly available or backed-up production service.

The backend image must be published for both `linux/amd64` and `linux/arm64`; Gengar is `aarch64-linux`. Use the immutable commit SHA tag from `ghcr.io/heph2/lorebound-backend`.

## First setup

1. Point `api.lorebound.shop` at Gengar's public address. If Cloudflare proxying is enabled, use Full (strict) TLS.
2. Ensure the Lorebound backend image is public to Gengar or configure Docker's GHCR login.
3. Create the root-only runtime environment file:

   ```sh
   sudo install -d -m 0700 /var/lib/lorebound
   sudo install -m 0600 /dev/null /var/lib/lorebound/.env
   sudoedit /var/lib/lorebound/.env
   ```

   Set these Compose variables in that file. Generate the three application/database secrets with `openssl rand -hex 32`; use hex for the database and Redis passwords so their values are safe in connection URLs.

   ```dotenv
   LOREBOUND_IMAGE_TAG=<published-git-commit-sha>
   POSTGRES_PASSWORD=<random-hex>
   REDIS_PASSWORD=<random-hex>
   JWT_SECRET=<random-secret>
   COOKIE_SECRET=<random-secret>
   STORE_CORS=https://lorebound.shop,https://www.lorebound.shop
   AUTH_CORS=https://lorebound.shop,https://www.lorebound.shop,https://api.lorebound.shop
   S3_FILE_URL=https://<public-r2-custom-domain-or-r2-dev-url>
   S3_ACCESS_KEY_ID=<R2-token-access-key-id>
   S3_SECRET_ACCESS_KEY=<R2-token-secret>
   S3_BUCKET=<R2-bucket-name>
   S3_ENDPOINT=https://<cloudflare-account-id>.r2.cloudflarestorage.com
   ```

   Create an R2 bucket for public product assets and an R2 token scoped to that bucket with object read/write permissions. Set `S3_FILE_URL` to the bucket's public custom domain (recommended) or its public `r2.dev` URL. The S3 endpoint is the account-specific API endpoint, not the public asset URL. Keep these credentials out of Git and do not use this public bucket for database backups.

4. Apply the NixOS configuration, then start the stack:

   ```sh
   sudo systemctl start lorebound-stack
   sudo systemctl status lorebound-stack
   curl --fail https://api.lorebound.shop/health
   ```

   The unit starts PostgreSQL and Redis, runs `medusa db:migrate` from the selected image, and only then starts the backend.

5. Create the initial Admin user from the running backend container, then open `https://api.lorebound.shop/app` and create a publishable API key for the storefront.

## Updating the backend

After CI publishes a multi-architecture image for a commit, update `LOREBOUND_IMAGE_TAG` to that commit SHA in `/var/lib/lorebound/.env` and restart the unit:

```sh
sudo systemctl restart lorebound-stack
```

The unit reruns the idempotent Medusa migration command before bringing up the new backend container. Review logs with `docker-compose --file /etc/lorebound/compose.yaml --env-file /var/lib/lorebound/.env logs --follow backend`.

## Host metrics

Node Exporter is enabled on loopback only (port 9100), so it is not exposed to the public network. To inspect current host metrics, use an SSH tunnel and query `http://127.0.0.1:9100/metrics`. The metrics are not retained; add a remote Prometheus scrape target if historical graphs or alerts are needed.

## Alpha limitations

- Gengar, PostgreSQL, and Redis are single points of failure.
- PostgreSQL and Redis data survive container replacement in local Docker volumes, but this is not a backup. Configure off-host PostgreSQL backups and test a restore before live payments.
- Redis uses AOF persistence, but a Redis volume failure can still lose queued work.
- The Medusa API and worker run in shared mode in one backend container.
- The R2 asset bucket must be publicly readable through its `S3_FILE_URL`; keep its API token narrowly scoped.
- Deployments are manual. A failed migration prevents the new backend from starting, but rollbacks still need a compatible database schema.
