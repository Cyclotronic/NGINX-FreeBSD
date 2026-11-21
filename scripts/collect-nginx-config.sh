#!/bin/sh
# Copyright (c) 2026 Cyclotron. MIT; see LICENSE.
# FreeBSD configuration collector. No installs, reloads, or service changes.
# Usage: sh collect-nginx-config.sh [site-name] [existing-output-directory]
set -u
umask 077
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export PATH
LC_ALL=C
export LC_ALL
die() { printf '%s\n' "$*" >&2; exit 1; }
case "${1-}" in -h|--help)
    printf '%s\n' 'Usage: sh collect-nginx-config.sh [site-name] [existing-output-directory]'
    exit 0 ;;
esac
[ "$#" -le 2 ] || die 'Too many arguments.'
[ "$(uname -s)" = FreeBSD ] || die 'Run on the FreeBSD NGINX server.'
[ "$(id -u)" = 0 ] || die 'Run as root to read the effective configuration.'
site=${1:-xdevs.com}
case "$site" in ''|*[!A-Za-z0-9._-]*) die 'Use a hostname as the site label.';; esac
out=$(CDPATH= cd -- "${2:-.}" 2>/dev/null && pwd -P) || die 'Output directory does not exist.'
nginx=${NGINX_BIN:-/usr/local/sbin/nginx}
[ -x "$nginx" ] || die 'NGINX binary not found; set NGINX_BIN.'
work=$(mktemp -d /tmp/nginx-config.XXXXXXXX) || die 'Cannot create temporary directory.'
cleanup() { rm -rf -- "$work"; }
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP
root="$work/nginx-config"
mkdir -p "$root/system" "$root/nginx" "$root/services" "$root/php-fpm" || die 'mkdir failed.'
status="$root/check-status.tsv"
printf 'report\texit_status\n' > "$status"

# Conservative line redaction, not a guarantee that arbitrary secrets are detected.
# Raw command output is streamed through awk, never saved in the archive.
cat > "$work/redact.awk" <<'AWK'
BEGIN { pem=0; continuation=0 }
{
    lower=tolower($0)
    if (lower ~ /-----begin .*private key-----/) {
        print "# [REDACTED PRIVATE KEY]"; pem=1
    }
    if (pem) {
        if (lower ~ /-----end .*private key-----/) pem=0
        next
    }
    if (continuation) {
        if ($0 ~ /;/) continuation=0
        next
    }
    if (lower ~ /password|passwd|secret|token|authorization|cookie|api[_-]?key|access[_-]?key/ ||
        lower ~ /[a-z][a-z0-9+.-]*:\/\/[^\/ \t]*@/ ||
        lower ~ /ssl_certificate_key[ \t]+["\047]?data:/ ||
        lower ~ /[?&][a-z0-9_.-]+=/) {
        print "# [REDACTED potentially sensitive line]"
        # Handle a sensitive directive with its value on subsequent lines.
        if ($0 !~ /;/ && $0 !~ /[{}]/ && $0 !~ /^[ \t]*#/) continuation=1
        next
    }
    print
}
AWK
redact() { awk -f "$work/redact.awk"; }
capture() {
    report=$1
    shift
    ( "$@" 2>&1; printf '%s\n' "$?" > "$work/command.exit" ) |
        redact > "$root/$report"
    filter_rc=$?
    rc=$(cat "$work/command.exit" 2>/dev/null || printf '125')
    [ "$filter_rc" -eq 0 ] || die "Redaction failed: $report"
    printf '%s\t%s\n' "$report" "$rc" >> "$status"
}

printf 'Site label: %s\nCollected UTC: %s\n' "$site" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$root/collection.txt"
capture system/freebsd-version.txt freebsd-version -kru
capture system/architecture.txt uname -mp
capture system/resources.txt sysctl hw.ncpu hw.physmem hw.pagesize kern.maxfiles kern.maxfilesperproc kern.ipc.somaxconn
capture system/memory-sample.txt vmstat 1 3
capture system/disk-space.txt df -h
capture system/swap.txt swapinfo -h
capture system/interfaces.txt ifconfig -a
capture system/interface-counters.txt netstat -ibn
capture system/listeners.txt sockstat -l
capture system/processes.txt ps -axo pid,ppid,user,comm
capture services/enabled.txt service -e
capture services/nginx-status.txt service nginx onestatus
capture services/web-rc-settings.txt sh -c 'sysrc -a 2>/dev/null | awk "/^(nginx|php_fpm|fcgiwrap|apache24|varnish|redis|memcached)_/"'
capture nginx/version-build.txt "$nginx" -V

# These options must match the service if it uses a non-default config/prefix.
set -- -T -e stderr
[ -z "${NGINX_CONF:-}" ] || set -- "$@" -c "$NGINX_CONF"
[ -z "${NGINX_PREFIX:-}" ] || set -- "$@" -p "$NGINX_PREFIX"
capture nginx/effective-config-redacted.txt "$nginx" "$@"
conf=${NGINX_CONF:-/usr/local/etc/nginx/nginx.conf}
if [ -f "$conf" ]; then
    capture nginx/main-config-redacted.txt cat "$conf"
fi

if [ -x /usr/local/sbin/pkg ]; then
    capture services/packages.txt /usr/local/sbin/pkg query -a '%n %v %o'
    capture nginx/package-files.txt /usr/local/sbin/pkg info -l nginx
fi
capture nginx/module-files.txt sh -c '
    for d in /usr/local/libexec/nginx /usr/local/etc/nginx/modules; do
        if [ -d "$d" ]; then
            ls -ld "$d"
            find -H "$d" -maxdepth 1 -name "*.so" -exec ls -l {} \;
        fi
    done'

# Pool/server configuration only: no php.ini, application config, .env or webroot.
if [ -f /usr/local/etc/php-fpm.conf ]; then
    capture php-fpm/main-redacted.txt cat /usr/local/etc/php-fpm.conf
fi
n=0
for f in /usr/local/etc/php-fpm.d/*.conf; do
    [ -f "$f" ] || continue
    n=$((n+1))
    # Redact all PHP pool environment assignments, including innocuously named secrets.
    capture "php-fpm/pool-$n-redacted.txt" awk '
        /^[[:space:]]*env\[/ { print "; [REDACTED environment assignment]"; next }
        { print }' "$f"
    printf '%s\t%s\n' "pool-$n-redacted.txt" "$f" >> "$root/php-fpm/files.tsv"
done

cat > "$root/README.txt" <<'EOF'
NGINX CONFIGURATION REVIEW

Includes effective NGINX configuration (nginx -T), compiled features, module
paths, listening sockets, process names, enabled services, web service rc
settings, package versions, resource samples and PHP-FPM pool settings if present.
check-status.tsv records command failures; a failed nginx -T may omit includes.
If service flags select another config/prefix, rerun with NGINX_CONF/NGINX_PREFIX.

Does not copy private key/certificate files, password files, application files,
web content, access/error logs, full process arguments, crontabs or firewall rules.
No HTTP probes, package downloads or service configuration changes are performed.
nginx -T tests configuration, can resolve upstream names and open log/key files.

Common credential/cookie/token lines, URL credentials/query strings, inline
private keys and PHP pool environment assignments are redacted. This is best
effort: custom directives and arbitrary literal values can contain secrets.
Redacted reports are for analysis, NOT deployment-ready configuration.
The archive still contains private topology, paths and configuration details.
Review it before sharing privately; do not upload it to the public repository.
EOF

( cd "$root" && find . -type f ! -name SHA256SUMS -exec sha256 {} \; > SHA256SUMS ) || die 'Checksum generation failed.'
archive="$out/nginx-config-$site-$(date -u +%Y%m%dT%H%M%SZ)-$$.tar.gz"
tar -czf "$archive" -C "$work" nginx-config || die 'Archive creation failed.'
chmod 600 "$archive" || die 'Cannot set archive permissions.'
printf '%s\n' "$archive"
