#!/bin/sh
# FreeBSD NGINX package-build inventory. No network, installs, or service changes.
# Usage: sh collect-nginx-build-info.sh [existing-output-directory]
# Optional: NGINX_BIN=/absolute/path/to/nginx sh collect-nginx-build-info.sh
set -u
umask 077
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export PATH
LC_ALL=C
export LC_ALL

die() { printf '%s\n' "$*" >&2; exit 1; }
if [ "$#" -gt 1 ]; then die "Usage: sh $0 [existing-output-directory]"; fi
case "${1-}" in -h|--help) printf 'Usage: sh %s [existing-output-directory]\n' "$0"; exit 0;; esac
[ "$(uname -s)" = FreeBSD ] || die 'Run this script on the FreeBSD target or FreeBSD build host.'
outdir=$(CDPATH= cd -- "${1:-.}" 2>/dev/null && pwd -P) || die 'Output directory must exist and be accessible.'
work=$(mktemp -d /tmp/nginx-build-info.XXXXXXXX) || die 'Cannot create temporary directory.'
cleanup() { rm -rf -- "$work"; }
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP
root="$work/nginx-build-info"
mkdir -p "$root/system" "$root/nginx" "$root/packages" "$root/modules" || die 'Cannot create report directories.'
status="$root/check-status.tsv"
printf 'report\texit_status\n' > "$status"

# Capture failures without aborting collection. Nothing invokes pkg bootstrap.
capture() {
    report=$1
    shift
    "$@" > "$root/$report" 2>&1
    result=$?
    printf '%s\t%s\n' "$report" "$result" >> "$status"
}

capture system/freebsd-version.txt freebsd-version -kru
capture system/architecture.txt uname -mp
capture system/kernel-userland-abi.txt sh -c 'uname -K; uname -U'
capture system/cpu-and-jail.txt sysctl hw.machine hw.machine_arch hw.model hw.ncpu security.jail.jailed kern.osreldate
capture system/collection-time-utc.txt date -u '+%Y-%m-%dT%H:%M:%SZ'
capture system/collector-uid.txt id -u

pkgcmd=/usr/local/sbin/pkg
if [ -x "$pkgcmd" ] && "$pkgcmd" -N >/dev/null 2>&1; then
    capture packages/pkg-version.txt "$pkgcmd" -v
    capture packages/all-installed.tsv "$pkgcmd" query -a '%n\t%v\t%o\t%q'
    capture packages/nginx-package-names.txt "$pkgcmd" query -a '%n'
    # Only exact, installed package names are passed back to pkg; no eval.
    awk 'tolower($0) ~ /nginx/' "$root/packages/nginx-package-names.txt" > "$work/nginx-packages"
    mv "$work/nginx-packages" "$root/packages/nginx-package-names.txt"
    while IFS= read -r package; do
        [ -n "$package" ] || continue
        capture "packages/$package-info.txt" "$pkgcmd" info -f "$package"
        capture "packages/$package-files.txt" "$pkgcmd" info -l "$package"
    done < "$root/packages/nginx-package-names.txt"
else
    printf '%s\n' 'No usable, bootstrapped pkg database. No bootstrap was attempted.' > "$root/packages/UNAVAILABLE.txt"
fi

nginx=${NGINX_BIN:-}
if [ -z "$nginx" ]; then nginx=$(command -v nginx 2>/dev/null || :); fi
if [ -n "$nginx" ] && [ -x "$nginx" ]; then
    printf '%s\n' "$nginx" > "$root/nginx/binary-path.txt"
    capture nginx/build-settings.txt "$nginx" -V
    capture nginx/linked-libraries.txt ldd "$nginx"
    capture nginx/binary-sha256.txt sha256 "$nginx"
    if [ -x "$pkgcmd" ] && "$pkgcmd" -N >/dev/null 2>&1; then
        capture nginx/binary-package-owner.txt "$pkgcmd" which "$nginx"
    fi
else
    printf '%s\n' 'NGINX not found. For a custom location, rerun with NGINX_BIN=/absolute/path/to/nginx.' > "$root/nginx/NOT-FOUND.txt"
fi

# Inventory module files only: never archive binaries, configs, logs, or keys.
# Includes standard paths and an optional custom directory, without following
# directory symlinks. Custom modules elsewhere must be supplied via MODULE_DIR.
: > "$root/modules/inventory.txt"
module_index=0
for module_dir in /usr/local/libexec/nginx /usr/local/lib/nginx/modules "${MODULE_DIR:-}"; do
    [ -n "$module_dir" ] && [ -d "$module_dir" ] || continue
    find "$module_dir" \( -type f -o -type l \) -name '*.so' -print > "$work/module-paths"
    while IFS= read -r module; do
        [ -f "$module" ] || continue
        module_index=$((module_index + 1))
        printf '%s\t%s\n' "$module_index" "$module" >> "$root/modules/inventory.txt"
        capture "modules/$module_index-sha256.txt" sha256 "$module"
        capture "modules/$module_index-linked-libraries.txt" ldd "$module"
        if [ -x "$pkgcmd" ] && "$pkgcmd" -N >/dev/null 2>&1; then
            capture "modules/$module_index-package-owner.txt" "$pkgcmd" which "$module"
        fi
    done < "$work/module-paths"
done

# Record only module directive arguments, never surrounding configuration text.
# These are candidates: include order/conditions are deliberately not evaluated.
config_dir=${CONF_DIR:-/usr/local/etc/nginx}
if [ -d "$config_dir" ]; then
    capture nginx/module-directive-candidates.txt find "$config_dir" -type f -name '*.conf' -exec awk '
        /^[[:space:]]*load_module[[:space:]]/ {
            argument=$2; sub(/;.*/, "", argument)
            printf "%s:%d\t%s\n", FILENAME, FNR, argument
        }
    ' '{}' +
fi

# Saved ports OPTIONS are build metadata, not the full make.conf (which can
# contain credentials). Copy only recognized option assignment lines.
: > "$root/nginx/saved-ports-options.txt"
for options in /var/db/ports/*nginx*/options; do
    [ -f "$options" ] && [ -r "$options" ] || continue
    printf '\nSource: %s\n' "$options" >> "$root/nginx/saved-ports-options.txt"
    awk '/^(_OPTIONS_READ|_FILE_COMPLETE_OPTIONS_LIST|OPTIONS_FILE_SET|OPTIONS_FILE_UNSET)[+?:]?=/' "$options" >> "$root/nginx/saved-ports-options.txt"
done

cat > "$root/README.txt" <<'EOF'
NGINX / FreeBSD package-build handoff

This is an offline inventory, not a vulnerability scanner or compatibility
guarantee. Run it once on the target, and optionally on the FreeBSD lab host.
Reports are read-only. Only the temporary report and final archive are written.
No network access, package refresh/bootstrap, configuration validation, reload,
restart, or installation is performed. Root is optional; it can improve access.
check-status.tsv records every captured command's exit status; nonzero results
need review. All installed package versions are listed to identify recursive
dependencies, module providers, and compatible runtime libraries.

NOT INCLUDED: configuration contents, nginx -T output, keys, certificates,
logs, environment variables, repository URLs, make.conf, source code, or binaries.
Build settings, package names, CPU model and local file paths are included and
may identify aspects of the installation. Review the archive before forwarding.

Module inventory describes files present, not which modules are actively loaded.
module-directive-candidates.txt lists only load_module arguments found in *.conf
files under /usr/local/etc/nginx (or CONF_DIR). It does not resolve includes,
multiline directives, alternative configuration suffixes, or activation order.
It includes standard module paths and MODULE_DIR if supplied. Custom static
modules may be identified by nginx -V but their source is not recoverable here.
The installed package list and module ownership reports help identify providers.

Facts the operator still needs to supply separately:
- Is this the target or lab host? Is NGINX inside a jail?
- If jailed: collect this report inside the jail and on its host as appropriate.
- Are dependency upgrades acceptable? Is offline installation required?
- Any local source patches or custom module source/revision information?
- Any custom service/configuration path or module directory not shown here?
- For deployment testing: sanitized configuration and site-specific smoke tests.

Build against target architecture and 14.2 userland; match required options and
modules. Review runtime dependency versions. Rebuild third-party dynamic modules
for the new NGINX. Test package installation in a matching jail before delivery.
Back up the original package/configuration and validate on the actual target.
EOF

stamp=$(date -u '+%Y%m%dT%H%M%SZ')
name="nginx-build-info-$stamp-$$.tar.gz"
archive="$outdir/$name"
[ ! -e "$archive" ] || die 'Archive already exists; rerun to obtain a new filename.'
tar -czf "$work/$name" -C "$work" nginx-build-info || die 'Archive creation failed.'
tar -tzf "$work/$name" >/dev/null || die 'Archive verification failed.'
# -n prevents replacing an existing destination, including a race with another run.
mv -n "$work/$name" "$archive" || die 'Cannot save archive in output directory.'
[ ! -e "$work/$name" ] || die 'Destination already exists; archive was not saved.'
printf '%s\n' "$archive"
