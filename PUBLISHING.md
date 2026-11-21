# Publishing

Destination: `Cyclotronic/NGINX-FreeBSD` on GitHub.

1. Build on the target FreeBSD userland with pinned sources and ports.
2. Compare options/modules and dependencies with the intended target. Test
   installation, original-package rollback and configuration recovery separately.
3. Update the manifest, validation report and concise guide. Render and inspect
   the PDF. Verify package digests, archive entries and all internal checksums.
4. Review `git diff --cached` and `git ls-files`. Only allowlisted public files
   belong in Git. Inventories, credentials, lab details, access scripts, private
   logs and reconstructed vulnerable baseline packages stay local.
5. Commit as the repository's human identity, without tooling/co-author trailers.
   Push main, tag the tested commit and create a GitHub release.
6. Attach the verified bundle, its SHA-256 file and the matching PDF. Compare
   published asset sizes/digests with local files and verify the tagged commit.

Original work uses MIT/Cyclotron attribution. Preserve third-party notices
and corresponding sources. Binary bundles are release assets, not Git history.
Any guide/bundle edit requires refreshed checksums.
