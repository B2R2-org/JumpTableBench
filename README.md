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
they ship as one tarball per configuration attached to a release. A
configuration is an architecture and a compiler, `<arch>-<compiler>` (e.g.,
`x64-gcc`), and both `ground-truth/` and `binaries/` are split by it.

```
SHA256SUMS                        one line per binary; the integrity anchor
exclusions.json                   cases left out of scoring, and why
ground-truth/<config>/<case>.json one file per binary
schema/jumptable.schema.json      JSON Schema for the above
scripts/                          generate shasums, pack tarballs, find redundant cases
```

`binaries/<config>/` is where a local build lands; it is gitignored.

## Dataset Overview

Every case is a stripped binary, built both as a PIE and as a non-PIE at
`-O2` and `-Os`, named
`<project>-<version>-<compiler>-<pie|nopie>-<opt>-<program>`:

| | |
| -- | -- |
| projects | GNU coreutils 9.9 and GNU binutils 2.45 |
| compilers | gcc 16.2.0 and clang 23.0.0 |
| architectures | `x86` and `x64`, 546 (`x86`) and 548 (`x64`) binaries, 24 of each from binutils |
| tables | 9,582 (`x64`) and 10,458 (`x86`) |

- We exclude 37 coreutils programs (e.g., ls, vdir, test, true, yes) whose jump tables are already covered by another included program, to avoid redundant evaluation. Two tables count as the same when their kind, entry size, entry count, and targets relative to the indirect branch all match; `scripts/find-redundant.py` lists any case that adds no distinct table.
- We keep three binutils programs: `as-new`, `objdump` and `readelf`. The other seven link the same libbfd, so they add only about 10% of the distinct binutils tables but would take over 60% of the binutils scoring time.
- We leave out `-O0` and `-O1` because they mostly repeat `-O2`: gcc builds almost no jump table at `-O0`, and 85-89% of the tables at `-O1` have an `-O2` counterpart of the same kind, entry size, entry count, and target count in the same program.
- We leave out `-O3` and `-Oz` to bound the scoring time. Every jump table bug B2R2 has hit at those levels so far also showed up at `-O2` or `-Os`.
- clang builds no `stdbuf`, and neither does gcc for the non-PIE `x86` build.
