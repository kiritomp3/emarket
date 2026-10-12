#!/usr/bin/env bash
set -euo pipefail
remote="${1:?Usage: bash scripts/deploy.sh user@server}"
case "$remote" in *[!a-zA-Z0-9@._-]*) echo "Invalid SSH target" >&2; exit 2;; esac
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
release="$(date -u +%Y%m%dT%H%M%SZ)-$(git -C "$repo_dir" rev-parse --short HEAD)"
archive="$(mktemp -t powderlab.XXXXXX)"
trap 'rm -f -- "$archive"' EXIT
COPYFILE_DISABLE=1 tar --no-xattrs -czf "$archive" -C "$repo_dir/public" .
ssh -o ClearAllForwardings=yes "$remote" "mkdir -p /var/www/powderlab-releases/$release"
scp -o ClearAllForwardings=yes "$archive" "$remote:/var/www/powderlab-releases/$release/site.tar.gz"
ssh -o ClearAllForwardings=yes "$remote" "set -eu; test ! -e /var/www/powderlab || test -L /var/www/powderlab; tar -xzf /var/www/powderlab-releases/$release/site.tar.gz -C /var/www/powderlab-releases/$release; rm /var/www/powderlab-releases/$release/site.tar.gz; find /var/www/powderlab-releases/$release -type d -exec chmod 755 {} +; find /var/www/powderlab-releases/$release -type f -exec chmod 644 {} +; test -f /var/www/powderlab-releases/$release/index.html; ln -s /var/www/powderlab-releases/$release /var/www/powderlab.next; mv -Tf /var/www/powderlab.next /var/www/powderlab"
printf 'Deployed %s to https://boost-gta6.ru/powderlab/\n' "$release"
