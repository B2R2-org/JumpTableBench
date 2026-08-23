#!/bin/bash
set -euo pipefail
export LC_ALL=C
find binaries -type f | sort | xargs sha256sum > SHA256SUMS
