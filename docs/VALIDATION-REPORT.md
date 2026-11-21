# Validation report — 21 November 2026

PASS: target-matched FreeBSD 14.2-RELEASE amd64 with pkg 2.4.2.
The test VM was separate from the build VM. Its only application dependencies
were the exact three library versions in the target inventory. No source/build
toolchain was needed to install or run the replacement.

| Check | Result |
| --- | --- |
| Target option comparison | 36 enabled options retained, none lost or added |
| Dynamic modules | All ten packaged modules loaded together; stream loaded first |
| Package metadata | FreeBSD:14:amd64, OSVERSION 1402000; SHA-256 verified |
| Dependency versions | libiconv 1.17_1, libmaxminddb 1.12.2, pcre2 10.45 unchanged |
| Old baseline | Reconstructed 1.28.0_1,3 with target features passed smoke tests |
| Upgrade | New core/modules installed; configuration checksum unchanged |
| Normal rollback | Original local pkg-create backup restored; smoke tests passed |
| Failure recovery | Deliberate unknown directive rejected; old package and saved configuration restored; smoke tests passed |
| Repeated upgrade | Final patched version running and passing smoke tests |
| Application smoke tests | Static file, HTTP health, GeoIP2 lookup, active upstream check/proxy, TCP stream proxy passed |
| External protocol requests | HTTP/1.1, TLS HTTP/2 and QUIC HTTP/3 returned 200 with expected bodies |
| Integrity | pkg check -s, pkg check -d and linked-library resolution passed |
| Recipient commands | Checksum script, old-version preflight, three dependency backups and documented upgrade sequence passed on FreeBSD |

External TLS tests used a lab-only self-signed certificate and bypassed trust
verification for that certificate. Production TLS trust, real-hostname/SNI,
application routes and firewall/UDP reachability require recipient validation.
All ten modules loaded; individual third-party module behaviors beyond GeoIP2,
upstream-check and stream forwarding were not exhaustively exercised. No CVE
exploit, load, soak, multi-worker or production-configuration test was performed.

The original test image contained pkg 1.21.3. Upgrade and first rollback passed,
but a later repeated install crashed that old pkg process (signal 139).
After replacing the lab tool with the target's pkg 2.4.2, the entire repeated
upgrade/rollback/failure-recovery sequence passed. No NGINX crash occurred.
The recipient preflight therefore requires the inventoried pkg 2.4.2; this
delivery does not ask the recipient to upgrade pkg or the OS.

The baseline lab NGINX was reconstructed from historical public port sources;
it was not a copy of the friend's executable. Recipient rollback must use a
fresh pkg-create backup of the actual installed production package.

Detailed lab logs and test scripts remain in the project. Selected concise
evidence accompanies this bundle. No production config or private keys included.
