# Third-party software

Cyclotron's MIT license applies only to original scripts and documentation.
It grants no rights to third-party software and claims no ownership of it.

| Component | License in the bundled source |
| --- | --- |
| NGINX core, stream modules | BSD 2-Clause |
| fancyindex, footer, GeoIP2, sticky, upstream-check | BSD-style; exact notices retained |
| mod_zip | BSD 3-Clause |
| nchan | MIT, credited to Leo Ponomarev; embedded components retain their notices |
| push-stream | GPL-3.0-or-later, credited to Wandenberg Peixoto and Rogerio Carvalho Schneider |
| libiconv/libcharset libraries | LGPL-2.1-or-later |
| iconv utility | GPLv3 family; exact source notices retained |
| PCRE2 | BSD-3-Clause WITH PCRE2-exception |
| libmaxminddb | Apache-2.0, MaxMind copyright/NOTICE retained |
| upstream-fair pinned fork | Copyright header retained; explicit license grant not found in this snapshot |

See THIRD-PARTY-NOTICES.txt for upstream texts and docs/LICENSE-AUDIT.md for
the audit scope and unresolved upstream-fair point. The release source archive
contains corresponding sources, selected port files, patches and build settings.
Source/build tools retain their own licenses too.

The nginx package metadata's BSD2CLAUSE field describes the core. It is not a
complete license declaration for every bundled module: push-stream is GPLv3+.
No repository MIT notice overrides that license or its source obligations.
The library is dynamically linked to libiconv; the distributed dependency
package includes a GPL utility as well as LGPL libraries. Sources are supplied.

Base FreeBSD/OpenSSL binaries are not included. This notice does not certify
that every redistribution obligation has been independently resolved.
