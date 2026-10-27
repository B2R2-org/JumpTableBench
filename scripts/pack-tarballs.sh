#!/bin/bash
# Packs binaries/<arch>-<compiler> into one deterministic tarball per
# configuration. Run from the repository root. Configurations are whatever
# directories binaries/ holds, so adding one needs no change here. Pass names
# to restrict: ./scripts/pack-tarballs.sh x64-gcc x64-clang
set -euo pipefail
export LC_ALL=C

[ -d binaries ] || { echo "no binaries/ here; run from the root" >&2; exit 1; }

if [ "$#" -gt 0 ]; then
  configs=( "$@" )
else
  configs=()
  for dir in binaries/*/; do
    [ -d "$dir" ] || continue
    configs+=( "$(basename "$dir")" )
  done
fi

[ "${#configs[@]}" -gt 0 ] || { echo "binaries/ has no configuration" >&2; exit 1; }

for config in "${configs[@]}"; do
  dir=binaries/$config
  [ -d "$dir" ] || { echo "no such configuration: $config" >&2; exit 1; }
  count=$(find "$dir" -type f | wc -l)
  [ "$count" -gt 0 ] || { echo "$dir is empty" >&2; exit 1; }
  chmod 755 "$dir"/*
  # Member paths must stay binaries/<config>/... to match SHA256SUMS, so the
  # directory is named as-is rather than entered with -C.
  tar --sort=name \
      --format=posix \
      --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
      --owner=0 --group=0 --numeric-owner \
      --mtime='UTC 2020-01-01' \
      --mode='u=rwX,go=rX' \
      --no-acls --no-selinux --no-xattrs \
      -cf "binaries-$config.tar" "$dir"
  gzip -n -9 -f "binaries-$config.tar"
  echo "packed binaries-$config.tar.gz ($count files)"
done
