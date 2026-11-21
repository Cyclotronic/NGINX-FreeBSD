# Release license audit — 21 November 2026

## Scope of the MIT claim

Only original project scripts and documentation are offered under MIT/Cyclotron.
Third-party binaries, sources and copyright/license notices are excluded.
This limitation is now explicit in LICENSE itself, as well as README and NOTICE.

## Evidence inspected

Read the actual upstream archives in delivery-source.tar.gz and the license
metadata/files in all four distributed .pkg files. Original upstream source
archives and selected port patches/settings are present in the release bundle.
THIRD-PARTY-NOTICES.txt additionally exposes upstream texts without requiring
users to unpack nested source tarballs. See NOTICE.md for the component map.

## Findings

The initial publication review scoped MIT correctly but was not a complete
component audit. It should not be described as one.

1. push-stream 0.6.2 is GPL-3.0-or-later, despite nginx's core-only BSD2CLAUSE
   package metadata. Its LICENSE, COPYING and complete source are in the
   delivered source archive. The combined notice now identifies it explicitly.
2. libiconv's libraries are LGPL; its utility is GPL. The package's GPLv3
   metadata does not describe every library's license. Complete source and
   build/patch settings are supplied. PCRE2 also has a named license exception.
3. The pinned upstream-fair fork (jaygooby, 10ecdcf) includes a copyright header
   crediting Grzegorz Nosek and Igor Sysoev, but no standalone license grant was
   found in its four-file source snapshot. Other distributions classify related
   versions as BSD; that does not independently prove this fork's permission.
   Confirm the applicable grant with an authoritative upstream record or author
   before claiming the entire custom binary has a fully verified license audit.

No third-party code was changed or relicensed in this documentation correction.
The published runtime packages and tested package digest are unchanged.
The original package metadata has not been rewritten. This report establishes
the scope of our claim and records remaining uncertainty; it is not a blanket
license-compliance certification.
