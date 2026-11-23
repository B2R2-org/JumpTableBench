# JumpTableBench

Ground truth for jump table recovery, used to measure the accuracy of
[B2R2](https://github.com/B2R2-org/B2R2)'s middle-end on every push.

A jump table is how compilers implement a dense `switch`: an indirect branch
reads a target out of a table in the binary. Recovering those tables is what
decides whether a reconstructed CFG is complete, and getting it wrong is silent.
This repository pins down the right answer for real binaries per
architecture (x86, x64, 32-bit ARM, AArch64, MIPS, RISC-V, PowerPC, m68k,
S390 and SPARC) so that a regression shows up as a failing check rather than
as a quietly worse CFG.

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

Every case is a stripped binary, built both as a PIE and as a non-PIE, named
`<project>-<version>-<compiler>-<pie|nopie>-<opt>-<program>`:

| | |
| -- | -- |
| projects | GNU coreutils 9.9 and GNU binutils 2.45 |
| compilers | gcc 16.2.0 and clang 23.0.0 |
| architectures | `x86`, `x64`, ARMv7 as `armhf` (hard float) and `armel` (soft float), `aarch64`, big-endian MIPS32r2 (o32) and MIPS64r2 (n64) as `mips32` and `mips64`, RV32GC (ilp32d) and RV64GC (lp64d) as `riscv32` and `riscv64`, big-endian 32-bit PowerPC (SysV, hard float) and 64-bit PowerPC (ELFv1) as `ppc32` and `ppc64`, the Motorola 68020 as `m68k`, big-endian 31-bit S/390 and 64-bit z/Architecture as `s390` and `s390x`, and 64-bit SPARC V9 as `sparcv9` |
| binaries | 546 (`x86`), 548 (`x64`), 397 each (`armhf`, `armel`), 548 (`aarch64`), 409 (`mips32`), 548 (`mips64`), 546 each (`riscv32`, `riscv64`), 548 each (`ppc32`, `ppc64`), 276 (`m68k`), 276 (`s390`), 548 (`s390x`) and 276 (`sparcv9`), of which 24, 24, 6, 24, 18, 24, 24, 24, 12, 12, 24 and 12 are from binutils |
| tables | 10,458 (`x86`), 9,582 (`x64`), 5,279 each (`armhf`, `armel`), 5,581 (`aarch64`), 9,287 (`mips32`), 10,280 (`mips64`), 8,964 (`riscv32`), 8,273 (`riscv64`), 4,948 (`ppc32`), 4,528 (`ppc64`), 4,736 (`m68k`), 5,835 (`s390`), 11,861 (`s390x`) and 4,006 (`sparcv9`) |

- We exclude 37 coreutils programs (e.g., ls, vdir, test, true, yes) whose jump tables are already covered by another included program, to avoid redundant evaluation. Two tables count as the same when their kind, entry size, entry count, and targets relative to the indirect branch all match; `scripts/find-redundant.py` lists any case that adds no distinct table.
- We keep three binutils programs: `as-new`, `objdump` and `readelf`. The other seven link the same libbfd, so they add only about 10% of the distinct binutils tables but would take over 60% of the binutils scoring time.

Each architecture takes only some optimization levels; the sections below say
which, and why the others are left out. Many of the levels left out mostly
repeat one that is in, which we measure by counterparts: a table has a
counterpart at another level when the same program has a table of the same
kind, entry size, entry count, and target count at that level.

### Intel

`x86` and `x64` take both compilers at `-O2` and `-Os`.

- We leave out `-O0` and `-O1` because they add little: gcc builds almost no jump table at `-O0`, and 85-89% of the `-O1` tables have an `-O2` counterpart.
- We leave out `-O3` and `-Oz` to keep the scoring time short. So far, every jump table bug B2R2 has hit at those levels also showed up at `-O2` or `-Os`.
- clang builds no `stdbuf`, and gcc builds none for the non-PIE `x86` build.

### ARM

`armhf` and `armel` take a cell, one compiler at one optimization level, only
once B2R2 gets all of it right on both. The check fails on any missed or
invented table, so a cell that fails from the start would catch no
regression. These cells are in so far:

- gcc at `-O2` and clang at `-Os`, coreutils only. Their binutils programs are left out: of those, only the clang PIE `as-new` passes at `-O2` and `-Os`. gcc at `-Os` and clang at `-O2` are not in yet, because B2R2 still misses a table or two in five and six programs, respectively.
- clang at `-O0`, binutils included. Most of its tables are new: only a third of its coreutils tables have an `-Os` counterpart. clang at `-O2` would repeat two thirds of them, but it is not in yet.

clang builds no `stdbuf`, and gcc builds none for the non-PIE build at `-O2`.

### AArch64

`aarch64` takes both compilers at `-O2` and `-Os`, binutils included. As for
ARM, a cell joins only once B2R2 gets all of it right, and these four cells
already pass.

- We leave out `-O1` and `-O3` because they mostly repeat `-O2`: 73-75% (gcc) and 88-95% (clang) of their tables have an `-O2` counterpart. gcc builds no jump table at `-O0`, and its `-Oz` binaries are byte for byte its `-Os` ones.
- clang at `-O0` and `-Oz` is not in yet. Both would add new tables: none of the `-O0` tables and only 41% of the `-Oz` ones have an `-Os` counterpart. But B2R2 still gets some of them wrong: it invents targets in the non-PIE `as-new` and `objdump` at `-O0`, and misses or invents some in `as-new`, `objdump` and the non-PIE `expr` at `-Oz`.
- clang builds no `stdbuf`.

### MIPS

`mips32` and `mips64` take both compilers at `-O2` and `-Os`, binutils
included, except gcc at `-Os` for `mips32`. As for ARM, a cell joins only once
B2R2 gets all of it right, and B2R2 still misses a table in the PIE `sort`
there.

- We leave out `-O1` and `-O3` because they mostly repeat `-O2`: 83-90% (gcc) and 91-97% (clang) of their tables have an `-O2` counterpart. gcc builds almost no jump table at `-O0` (none for `mips32`, 14 for `mips64`), and its `-Oz` binaries are byte for byte its `-Os` ones.
- We leave out clang at `-O0` and `-Oz` to keep the scoring time short: 71-74% of the `-O0` tables and 98% of the `-Oz` ones have an `-O2` or an `-Os` counterpart, respectively.
- clang builds no `stdbuf`, and gcc builds none for the non-PIE `mips32` build.

### RISC-V

`riscv32` and `riscv64` take both compilers at `-O2` and `-Os`, binutils
included. B2R2 already gets every jump table right at every optimization level
of both, so we leave levels out only to keep the scoring time short:

- We leave out `-O1` and `-O3` because they mostly repeat `-O2`: 69-92% (gcc) and 95-97% (clang) of their tables have an `-O2` counterpart. gcc builds almost no jump table at `-O0` (14 per architecture), and its `-Oz` binaries are byte for byte its `-Os` ones.
- We leave out clang at `-O0` and `-Oz`: 67-69% of the `-O0` tables and 99% of the `-Oz` ones have an `-O2` or an `-Os` counterpart, respectively.
- clang builds no `stdbuf`, and gcc builds none for the non-PIE build.

### PowerPC

`ppc32` and `ppc64` take both compilers at `-O2` and `-Os`, binutils included.
B2R2 already gets every jump table right at every optimization level of both,
so we leave levels out only to keep the scoring time short:

- We leave out `-O1` and `-O3` because they mostly repeat `-O2`: 64-93% (gcc) and 96-100% (clang) of their tables have an `-O2` counterpart. gcc builds no jump table at `-O0`, and its `-Oz` binaries are byte for byte its `-Os` ones.
- We leave out clang at `-O0` and `-Oz`: 55-59% of the `-O0` tables and all of the `-Oz` ones have an `-O2` or an `-Os` counterpart, respectively.
- clang builds a jump table on PowerPC only for a switch of 64 cases or more, so its configurations hold only 132 (`ppc32`) and 140 (`ppc64`) tables, all but 8 of them in binutils. The 252 cases of each that hold none still check that no table is invented.
- clang builds no `stdbuf`.

### m68k

`m68k` takes gcc only, at `-O2` and `-Os`, binutils included. B2R2 gets every
jump table right at both levels.

- We leave out `-O1` and `-O3` because they mostly repeat `-O2`: 78-93% of their tables have an `-O2` counterpart. B2R2 also still misses some of their tables, almost all of them in dead code. gcc builds no jump table at `-O0`, and its `-Oz` binaries are byte for byte its `-Os` ones.
- gcc builds `stdbuf` for both the PIE and the non-PIE build.

### S390

`s390x` takes both compilers, and `s390` takes gcc only: clang cannot build
31-bit S/390 code, because its SystemZ backend supports only the 64-bit
z/Architecture. Both take `-O2` and `-Os`, binutils included. B2R2 already
gets every jump table right at every optimization level of both, so we leave
levels out only to keep the scoring time short:

- We leave out `-O1` and `-O3` because they mostly repeat `-O2`: 70-89% (gcc) and 90-96% (clang) of their tables have an `-O2` counterpart. gcc builds no jump table at `-O0`, and its `-Oz` binaries are byte for byte its `-Os` ones.
- We leave out clang at `-O0` and `-Oz`: 70% of the `-O0` tables and 98% of the `-Oz` ones have an `-O2` or an `-Os` counterpart, respectively.
- gcc builds `stdbuf` for both the PIE and the non-PIE build; clang builds no `stdbuf`.

### SPARC

`sparcv9` takes gcc only, at `-O2` and `-Os`, binutils included: none of the
clang SPARC binaries holds a jump table, at any optimization level. B2R2
already gets every jump table right at every optimization level, so we leave
levels out only to keep the scoring time short:

- We leave out `-O1` and `-O3` because they mostly repeat `-O2`: 81-90% of their tables have an `-O2` counterpart. gcc builds no jump table at `-O0`, and its `-Oz` binaries are byte for byte its `-Os` ones.
- gcc builds `stdbuf` for both the PIE and the non-PIE build.
