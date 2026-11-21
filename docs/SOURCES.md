# Sources, licenses and rebuilding

The source archive includes upstream tarballs, the selected FreeBSD port
directories (including local patches/packaging files), Mk/Templates/Keywords,
the builder make.conf and its installed tooling inventory. Upstream tarballs
carry their own copyright/license texts. Retain these with redistribution;
libiconv includes GNU GPL/LGPL components. The binary packages also carry their
FreeBSD license metadata/files. This custom build has no upstream endorsement.

Extract delivery-source.tar.gz for the source tree. It is not needed to install.
The source bundle includes complete upstream libiconv 1.17 sources and the port
patches/options used to build its included binary, rather than a URL-only offer.

Full ports framework pin:
https://codeload.github.com/freebsd/freebsd-ports/tar.gz/9063bb5640e746b6ad815f6ec8f5959cf7a7c1bd
SHA256 f9ce3265b9c2a7454230c431ed97d43b17f1e9dc8b3c8375fe09595c9dad396a

Historical dependency/tool overlay archive:
https://codeload.github.com/freebsd/freebsd-ports/tar.gz/refs/heads/2025Q2
Recorded SHA256 07780eb520da88b25a8b1b5b7f154735f868731da26ffb8b86c866f19412d63e
This branch URL can change; prefer the exact selected port files included here.

Rebuild only in an isolated FreeBSD 14.2 amd64 builder. Populate /usr/ports from
the pinned full framework, overlay the included selected port directories, and
populate /usr/ports/distfiles from included distfiles. Apply build.make.conf
in that disposable builder, preserving ssl=base and target-options.make.conf.
Set PACKAGES to your chosen output directory. The included nginx Makefile.local
adds the libiconv dependency required by mod_zip without enabling ICONV features.
ALLOW_UNSUPPORTED_SYSTEM=yes is confined to the disposable old-OS builder.

The original builder bootstrapped pkg 2.9.3 and historical pkgconf 2.3.0,1;
global DOCS/EXAMPLES/NLS/INFO were disabled for tools, with m4 INFO disabled.
Run make install for the three library ports, pkg create for each library,
then make -C /usr/ports/www/nginx package (see build-nginx.sh). NGINX itself
need not be installed on the builder. Do not run these on the production host.
Tool dependencies may require additional downloads; this is an audit/source
bundle, not a complete offline compiler/bootstrap environment. Rebuilding is
not claimed bit-for-bit reproducible because timestamps/tool metadata can vary.

Reference security and packaging pages:
https://nginx.org/en/security_advisories.html
https://docs.freebsd.org/en/books/handbook/ports/
