#!/bin/bash
# Packs binaries/<arch> into one deterministic tarball per architecture.
# Run from the repository root. Architectures are whatever directories
# binaries/ holds, so adding one needs no change here. Pass names to
# restrict: ./scripts/pack-tarballs.sh x64 riscv64
set -euo pipefail
export LC_ALL=C

[ -d binaries ] || { echo "no binaries/ here; run from the root" >&2; exit 1; }

if [ "$#" -gt 0 ]; then
  archs=( "$@" )
else
  archs=()
  for dir in binaries/*/; do
    [ -d "$dir" ] || continue
    archs+=( "$(basename "$dir")" )
  done
fi

[ "${#archs[@]}" -gt 0 ] || { echo "binaries/ has no architecture" >&2; exit 1; }

for arch in "${archs[@]}"; do
  dir=binaries/$arch
  [ -d "$dir" ] || { echo "no such architecture: $arch" >&2; exit 1; }
  count=$(find "$dir" -type f | wc -l)
  [ "$count" -gt 0 ] || { echo "$dir is empty" >&2; exit 1; }
  chmod 755 "$dir"/*
  # Member paths must stay binaries/<arch>/... to match SHA256SUMS, so the
  # directory is named as-is rather than entered with -C.
  tar --sort=name \
      --format=posix \
      --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
      --owner=0 --group=0 --numeric-owner \
      --mtime='UTC 2020-01-01' \
      --mode='u=rwX,go=rX' \
      --no-acls --no-selinux --no-xattrs \
      -cf "binaries-$arch.tar" "$dir"
  gzip -n -9 -f "binaries-$arch.tar"
  echo "packed binaries-$arch.tar.gz ($count files)"
done
