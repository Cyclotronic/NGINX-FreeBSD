# NGINX upgrade & rollback

FreeBSD 14.2-RELEASE amd64 | pkg 2.4.2 | 21 November 2026

**1.28.0_1,3 to 1.30.7_1,3.** All 36 enabled options and 10 dynamic modules retained.
Existing libraries and base OpenSSL stay in place; `dependencies/` is contingency material.

## Verify

Run as root during a maintenance window, with console access available.
Compare the archive digest with the supplied `.sha256` file, then extract:

```sh
/bin/sh
ARCHIVE=nginx-freebsd14.2-amd64-1.30.7_1-20261121.tar.gz
sha256 -q "$ARCHIVE"
tar -xzf "$ARCHIVE"
cd "${ARCHIVE%.tar.gz}"
BUNDLE_DIR=$(pwd -P)
sh verify-checksums.sh && sh preflight.sh
```

Preflight checks the recorded OS, package versions and current configuration.
Resolve any failure before installing.

## Back up

```sh
umask 077
BACKUP_DIR=/root/nginx-backup-$(date -u +%Y%m%dT%H%M%SZ)
mkdir -p "$BACKUP_DIR/packages"
pkg create -o "$BACKUP_DIR/packages" nginx
OLD="$BACKUP_DIR/packages/nginx-1.28.0_1,3.pkg"
test -s "$OLD" && pkg info -F "$OLD"
sha256 -q "$OLD" > "$BACKUP_DIR/original.sha256"
tar -czpf "$BACKUP_DIR/config.tar.gz" -C / usr/local/etc/nginx
nginx -T > "$BACKUP_DIR/nginx-T.txt" 2>&1
if [ -d /usr/local/etc/letsencrypt ]; then
    tar -czpf "$BACKUP_DIR/certs.tar.gz" -C / usr/local/etc/letsencrypt
fi
printf 'Backup: %s\nBundle: %s\n' "$BACKUP_DIR" "$BUNDLE_DIR"
```

Verify the backup commands succeeded and record both paths. Back up external
configuration/certificate paths and custom service settings as applicable.
Backups contain private data. An optional VM/ZFS snapshot must cover the relevant datasets.

<!-- pagebreak -->

## Upgrade & validate

```sh
service nginx stop &&
    pkg add -f "$BUNDLE_DIR/packages/nginx-1.30.7_1,3.pkg" &&
    nginx -t && service nginx start
pkg query '%n %v' nginx
service nginx status
pkg check -d nginx && pkg check -s nginx
tail -n 50 /var/log/nginx/error.log
```

Expected package: `nginx 1.30.7_1,3`. If installation or startup fails, roll back.
Use the configured log path if different. Check actual sites by hostname/SNI,
including TLS, redirects and upstream applications, before restoring traffic.
Upgrade, rollback, configuration recovery and HTTP/1.1-3 passed in the lab;
details are in `VALIDATION-REPORT.md`.

## Package rollback

After reconnecting, enter `/bin/sh` and set `BACKUP_DIR` to the saved path.
Compare the original package digest before reinstalling:

```sh
OLD="$BACKUP_DIR/packages/nginx-1.28.0_1,3.pkg"
sha256 -q "$OLD"
cat "$BACKUP_DIR/original.sha256"
if service nginx onestatus; then service nginx stop; fi
pkg add -f "$OLD" && nginx -t && service nginx start
```

Expected restored version: `1.28.0_1,3`. Repeat the site checks.
Rollback restores the old vulnerabilities.

## Configuration recovery

If configuration changed and the old binary rejects it, stop NGINX and restore:

```sh
tar -czpf "$BACKUP_DIR/failed-config.tar.gz" -C / usr/local/etc/nginx
tar -xzpf "$BACKUP_DIR/config.tar.gz" -C /
nginx -t && service nginx start
```

Extraction overlays files; review any newly added include files separately.
Restore external files or certificates only if they changed and require recovery.

**Interrupted install:** reconnect via SSH/console; check `pgrep -laf pkg` before
starting another transaction. Once pkg has exited, inspect the installed version
and follow rollback. If pkg/database/filesystem repair is unavailable, use the
prepared snapshot or rescue route. Keep the original package backup until acceptance.
