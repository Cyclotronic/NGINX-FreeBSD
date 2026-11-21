# NGINX for FreeBSD 14.2

Custom NGINX **1.30.7_1,3** packages for **FreeBSD 14.2-RELEASE amd64**,
with an inventory collector, build settings and upgrade/rollback instructions.

## Download

Get the bundle and its `.sha256` file from [Releases](https://github.com/Cyclotronic/NGINX-FreeBSD/releases).
The bundle contains NGINX, rebuilt dynamic modules, matching dependency packages,
corresponding sources, checksums, a build manifest and validation results.

Read the [two-page guide](docs/NGINX-Upgrade-and-Recovery.pdf)
or its [Markdown version](docs/UPGRADE-GUIDE.md) before installation.

## Compatibility

Replaces `nginx-1.28.0_1,3`, retaining all **36 enabled options** and
**10 dynamic modules**. Uses base OpenSSL and existing
`libiconv-1.17_1`, `libmaxminddb-1.12.2` and `pcre2-10.45` packages.
The preflight checks the recorded target, including pkg **2.4.2**.

Modules: stream, stream GeoIP2, HTTP GeoIP2, fancyindex, footer, push-stream,
sticky, upstream-fair, zip and nchan. Upstream-check is compiled in.

Separate FreeBSD 14.2 build and test VMs were used. Upgrade, original-package
rollback, configuration recovery, and HTTP/1.1, TLS HTTP/2 and QUIC HTTP/3
requests passed. The [validation report](docs/VALIDATION-REPORT.md) records
the scope and the pkg 1.21.3 reinstall crash encountered before matching pkg 2.4.2.
Actual site configurations require their own checks.

This is a custom build, not an official FreeBSD package. It updates NGINX,
not the FreeBSD base system or other installed software.

## Collect another target's inventory

```sh
sh scripts/collect-nginx-build-info.sh
```

The read-only collector creates a compressed system/package/module inventory.
It makes no network requests and does not collect configuration contents or keys.
The output contains machine details; keep it private.

## Build and audit

- [Exact manifest](docs/BUILD-MANIFEST.json)
- [Source pins, licenses and rebuilding](docs/SOURCES.md)
- [Target options](build/target-options.make.conf)
- [libiconv dependency declaration](build/nginx-Makefile.local)
- [Build commands](scripts/build-nginx.sh), for an isolated builder
- [Release process](PUBLISHING.md)

The release source archive includes selected port files, framework pieces,
upstream tarballs and builder settings. Compiler/bootstrap dependencies may
require downloads. Builds are not claimed bit-for-bit reproducible.

## License

Original code and documentation: MIT, copyright Cyclotron.
Packaged software retains its own licenses; see [NOTICE](NOTICE.md).

The module set includes GPLv3+ push-stream. The [license audit](docs/LICENSE-AUDIT.md)
records exact-source checks and an unresolved license-grant question for
the pinned upstream-fair fork. The package core license label is not a
license for all bundled components.
