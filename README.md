# JumpTableBench

Ground truth for jump table recovery, used to measure the accuracy of
[B2R2](https://github.com/B2R2-org/B2R2)'s middle-end on every push.

A jump table is how compilers implement a dense `switch`: an indirect branch
reads a target out of a table in the binary. Recovering those tables is what
decides whether a reconstructed CFG is complete, and getting it wrong is silent.
This repository pins down the right answer for real binaries per
architecture (x86 and x64) so that a regression shows up as a failing check
rather than as a quietly worse CFG.

## What is here

Ground truth lives in git; binaries do not. The JSON is small, reviewable, and
belongs in history. The binaries are large and change a few times a year, so
they ship as per-architecture tarballs attached to a release.

```
SHA256SUMS                      one line per binary; the integrity anchor
exclusions.json                 cases left out of scoring, and why
ground-truth/<arch>/<case>.json one file per binary
schema/jumptable.schema.json    JSON Schema for the above
scripts/                        generate shasums, pack tarballs
```

`binaries/` is where a local build lands; it is gitignored.

## Dataset Overview

Every case is a stripped PIE built at `-O2`, named
`<project>-<version>-<compiler>-pie-o2-<program>`:

| | |
| -- | -- |
| projects | GNU coreutils 9.9 and GNU binutils 2.45 |
| compilers | gcc 16.2.0 and clang 23.0.0 |
| architectures | `x86` and `x64`, 201 binaries (181 from coreutils and 20 from binutils) each |
| tables | 4,940 (`x64`) and 5,793 (`x86`) |

- We exclude 12 coreutils programs (e.g., dir, vdir, [, sha1sum) whose jump tables are already covered by another included program, to avoid redundant evaluation.
