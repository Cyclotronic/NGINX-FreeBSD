#!/bin/sh
# Run only in the disposable, target-matched project VM after bootstrap.
set -eu
export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export ASSUME_ALWAYS_YES=yes
cd /root/nginx-build
mkdir -p logs output/All
date -u > logs/build-started.txt
freebsd-version -kru > logs/build-freebsd-version.txt
uname -m > logs/build-architecture.txt
for spec in converters/libiconv:libiconv-1.17_1 devel/pcre2:pcre2-10.45 net/libmaxminddb:libmaxminddb-1.12.2; do
    port=${spec%:*}
    expected=${spec#*:}
    if ! pkg info -e "$expected"; then
        make -C "/usr/ports/$port" install
    fi
    # Modern ports remove the staging metadir after install. Repackage the
    # installed dependency rather than calling the stage package target later.
    pkg create -o /root/nginx-build/output/All "$expected"
done
pkg query -a '%n %v %o' > logs/installed-build-packages.txt
make -C /usr/ports/www/nginx package
find output -type f -name '*.pkg' -exec sha256 '{}' \; > logs/package-sha256.txt
date -u > logs/build-complete.txt
