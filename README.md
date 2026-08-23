# JumpTableBench

Ground truth for jump table recovery, used to measure the accuracy of
[B2R2](https://github.com/B2R2-org/B2R2)'s middle-end on every push.

A jump table is how compilers implement a dense `switch`: an indirect branch
reads a target out of a table in the binary. Recovering those tables is what
decides whether a reconstructed CFG is complete, and getting it wrong is silent.
This repository pins down the right answer for about 100 real binaries so that a
regression shows up as a failing check rather than as a quietly worse CFG.

## What is here

Ground truth lives in git; binaries do not. The JSON is small, reviewable, and
belongs in history. The binaries are large and change a few times a year, so
they ship as per-architecture tarballs attached to a release.

```
SHA256SUMS                      one line per binary; the integrity anchor
exclusions.json                 cases left out of scoring, and why
ground-truth/<arch>/<case>.json one file per binary
schema/jumptable.schema.json    JSON Schema for the above
scripts/                        build, extract, validate
```

`binaries/` is where a local build lands; it is gitignored.
