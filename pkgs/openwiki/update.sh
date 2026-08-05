#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nodejs_22 nix-update jq curl gnutar
# Regenerates package.json + package-lock.json for the published npm tarball
# (which ships neither a lock file nor a build-ready manifest), then bumps the
# hashes in package.nix.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
version=$(npm view openwiki version)

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

curl -sSL "https://registry.npmjs.org/openwiki/-/openwiki-${version}.tgz" |
  tar xz -C "$work" --strip-components=1 package/package.json

cd "$work"

# Drop devDependencies (nothing is built from source: dist/ is prebuilt), but
# keep the optional peers openwiki needs at runtime for mermaid validation.
jq '
  .dependencies += { jsdom: .devDependencies.jsdom, mermaid: .devDependencies.mermaid }
  | del(.devDependencies)
  | del(.scripts)
' package.json >package.json.new
mv package.json.new package.json

# deepagents pins langsmith ^0.7.1 against openwiki's ^0.8.3; upstream uses
# pnpm, which tolerates that, so npm has to be told to.
npm install --package-lock-only --ignore-scripts --legacy-peer-deps

cp package.json package-lock.json "$here/"

cd "$here"
nix-update --flake openwiki --version "$version"
