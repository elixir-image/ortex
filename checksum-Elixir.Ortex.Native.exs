# SHA256 checksums for the precompiled NIF artifacts published to the
# project's GitHub releases. RustlerPrecompiled refuses to download
# any artifact whose checksum is not pinned here — this file is the
# integrity boundary between consumers and the release tarballs.
#
# This file is auto-populated as part of the release process; do not
# hand-edit. To regenerate after a tag's CI run finishes:
#
#     mix rustler_precompiled.download Ortex.Native --all --print
#
# The above will download every artifact attached to the matching
# GitHub release, verify each, and write this file. Commit the result
# before running `mix hex.publish`.
#
# An empty or stale checksum map means consumers must opt into the
# source-build path (`ORTEX_BUILD=true`) until the next release fills
# this file in.
%{}
