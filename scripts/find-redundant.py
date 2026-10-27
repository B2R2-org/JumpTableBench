#!/usr/bin/env python3
# Prints the ground-truth files of programs whose every jump table also
# appears in a program that is kept, so dropping them loses no distinct table.
# Run from the repository root; pipe to `xargs git rm` to drop them.
#
# Two tables are the same when kind, entrySize, numEntries and the targets
# relative to insAddr all match: the same object code linked at a different
# address. Programs are chosen per project and kept or dropped across every
# arch and compiler together, so all configurations share one program list.
import collections, glob, json, os

def key(table):
  ins = int(table["insAddr"], 16)
  rel = tuple(sorted(int(t, 16) - ins for t in table["targets"]))
  return (table["kind"], table["entrySize"], table["numEntries"], rel)

def parse(path):
  name = os.path.basename(path)[:-len(".json")]
  project, _, compiler, _, _, program = name.split("-", 5)
  return project, compiler, program

owners = collections.defaultdict(lambda: collections.defaultdict(set))
files = collections.defaultdict(list)
for path in sorted(glob.glob("ground-truth/*/*.json")):
  case = json.load(open(path))
  project, compiler, program = parse(path)
  files[project, program].append(path)
  for table in case["jumpTables"]:
    k = (case["arch"], compiler, key(table))
    owners[project][k].add(program)

for project, tables in sorted(owners.items()):
  # A table held by one program forces that program in; whatever those leave
  # uncovered is filled greedily.
  kept = { next(iter(o)) for o in tables.values() if len(o) == 1 }
  left = [ o for o in tables.values() if not (o & kept) ]
  while left:
    count = collections.Counter(p for o in left for p in o)
    best = max(sorted(count), key=count.__getitem__)
    kept.add(best)
    left = [ o for o in left if best not in o ]
  programs = { p for (q, p) in files if q == project }
  for program in sorted(programs - kept):
    for path in files[project, program]:
      print(path)
