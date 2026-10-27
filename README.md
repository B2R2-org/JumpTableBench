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

## The cases (0.2)

Every case is a stripped PIE built at `-O2`, named
`<project>-<version>-<compiler>-pie-o2-<program>`:

| | |
|---|---|
| projects | GNU coreutils 9.9 (a git snapshot taken after the 9.9 release: commit `9200747`, 2026-01-08; 102 programs with clang, 103 with gcc) and GNU binutils 2.45 (`addr2line`, `ar`, `as-new`, `ld-new`, `nm-new`, `objdump`, `readelf`, `size`, `strings`, `strip-new`) |
| compilers | gcc 16.2.0 and clang 23.0.0git (`d023577e`), each carrying our ground-truth patches (see below) |
| architectures | `x86` and `x64`, 225 binaries each |
| tables | 5,132 (`x64`) and 6,039 (`x86`) |

Version 0.1 held coreutils 8.30 built with gcc only; 0.2 replaces it.

## Where the ground truth comes from

The compilers record, while they lower a `switch`, the table, the indirect
branch that dispatches through it, whether a range check guards it, and the
target of every entry. Nothing is recovered from the finished binary, so the
answer does not depend on a heuristic. Two fields the compilers do not record,
`entrySize` and `jumpBase`, were derived from the binary and accepted only when
decoding every entry of the table reproduced the compiler's targets in the
compiler's order; all tables passed, so every `confidence` is `exact`.

* `numEntries` counts table slots, `targets` is the sorted set of distinct
  targets, so `targets` can be shorter.
* `targets` lists the value of every slot. A slot that the dispatching code can
  never index (a hole filled with a label of empty code) is still listed.
* `insAddr` is one dispatching instruction per table. If the compiler
  duplicates the dispatch, the same table is reachable from other indirect
  branches, and a recovery that reports the table at one of those scores as one
  table missed and one invented.
