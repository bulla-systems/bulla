#!/usr/bin/env python3
# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
"""
Migrate `.th` sources between the Thermite 2 and Thermite 3 clause surfaces.

The Thermite 3 anchor is a rename plus a reposition and nothing else, so this is
a source-to-source rewrite rather than a parse and print: comments, blank lines,
expression text survive untouched. The gap between a keyword and its expression
is preserved verbatim rather than re-aligned, which is what makes the rewrite
exactly invertible; re-aligning a column is a formatter's job and not a
migration's. A formatter would produce a diff
nobody can review, and the change does not need one.

    req P                 ->  requires P
    ens P                 ->  ensures P
    inv P                 ->  keeps P
    dec E                 ->  measures E
    fx  E   (last)        ->  ! E   (first, on its own line)

`--to-v2` inverts it. The two directions exist so the rewrite can be *proved*
information-preserving on a real corpus: `to_v2(to_v3(x)) == x` byte for byte,
for every file, is a much stronger check than eyeballing a diff — and it is the
only check available until a parser accepts the new surface.

A clause runs from its keyword until its expression closes, tracked by delimiter
balance, so a clause whose expression wraps across lines moves as one unit.
Keywords are only recognised at the head of a clause line, so an identifier
called `req` in a body is left alone.

Usage:

    python3 thermite-migrate.py [--to-v2] [--check] <path>...
    uv run  thermite-migrate.py --check .          # round-trip the whole tree
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

V2_TO_V3 = {"req": "requires", "ens": "ensures", "inv": "keeps", "dec": "measures"}
V3_TO_V2 = {v: k for k, v in V2_TO_V3.items()}

CLAUSE_V2 = re.compile(r"^(\s*)(req|ens|fx|inv|dec)(\s+)(.*)$")
CLAUSE_V3 = re.compile(r"^(\s*)(requires|ensures|keeps|measures)(\s+)(.*)$")
ROW_V3 = re.compile(r"^(\s*)!(\s+)(.*)$")


def _balance(text: str, depth: int) -> int:
    """Delimiter depth after `text`, ignoring anything in a line comment or a
    string. A clause ends at end-of-line when this returns to zero."""
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if c == '"':
            i += 1
            while i < n and text[i] != '"':
                i += 2 if text[i] == "\\" else 1
        elif c == "/" and i + 1 < n and text[i + 1] == "/":
            break
        elif c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        i += 1
    return depth


def _clauses(lines: list[str], start: int, pattern: re.Pattern):
    """Yield (keyword, [line, ...]) for the run of clauses beginning at `start`,
    then the index just past the run."""
    i = start
    out = []
    while i < len(lines):
        m = pattern.match(lines[i]) or (ROW_V3.match(lines[i]) if pattern is CLAUSE_V3 else None)
        if not m:
            break
        kw = m.group(2) if pattern.match(lines[i]) else "!"
        body = [lines[i]]
        depth = _balance(lines[i], 0)
        while depth > 0 and i + 1 < len(lines):
            i += 1
            body.append(lines[i])
            depth = _balance(lines[i], depth)
        out.append((kw, body))
        i += 1
    return out, i


def to_v3(text: str) -> str:
    lines = text.split("\n")
    out: list[str] = []
    i = 0
    while i < len(lines):
        if not CLAUSE_V2.match(lines[i]):
            out.append(lines[i])
            i += 1
            continue

        run, nxt = _clauses(lines, i, CLAUSE_V2)
        row = [c for c in run if c[0] == "fx"]
        rest = [c for c in run if c[0] != "fx"]

        for kw, body in row:                       # the effect row moves to the front
            m = CLAUSE_V2.match(body[0])
            indent, gap, expr = m.group(1), m.group(3), m.group(4)
            out.append(f"{indent}!{gap}{expr}")
            out.extend(body[1:])
        for kw, body in rest:                      # everything else renames in place
            m = CLAUSE_V2.match(body[0])
            indent, gap, expr = m.group(1), m.group(3), m.group(4)
            out.append(f"{indent}{V2_TO_V3[kw]}{gap}{expr}")
            out.extend(body[1:])
        i = nxt
    return "\n".join(out)


def to_v2(text: str) -> str:
    lines = text.split("\n")
    out: list[str] = []
    i = 0
    while i < len(lines):
        if not (CLAUSE_V3.match(lines[i]) or ROW_V3.match(lines[i])):
            out.append(lines[i])
            i += 1
            continue

        run, nxt = _clauses(lines, i, CLAUSE_V3)
        row = [c for c in run if c[0] == "!"]
        # v2 order is `req, ens+, fx, dec?` — the row goes before a measure, not
        # last. A recursive fn carries its `dec` after `fx`.
        head = [c for c in run if c[0] not in ("!", "measures")]
        tail = [c for c in run if c[0] == "measures"]

        def emit(kw, body):
            m = CLAUSE_V3.match(body[0])
            indent, gap, expr = m.group(1), m.group(3), m.group(4)
            out.append(f"{indent}{V3_TO_V2[kw]}{gap}{expr}")
            out.extend(body[1:])

        for kw, body in head:
            emit(kw, body)
        for kw, body in row:
            m = ROW_V3.match(body[0])
            indent, gap, expr = m.group(1), m.group(2), m.group(3)
            out.append(f"{indent}fx{gap}{expr}")
            out.extend(body[1:])
        for kw, body in tail:
            emit(kw, body)
        i = nxt
    return "\n".join(out)


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("paths", nargs="+", type=Path)
    ap.add_argument("--to-v2", action="store_true", help="rewrite Thermite 3 back to Thermite 2")
    ap.add_argument("--check", action="store_true",
                    help="round-trip every file and report any that does not restore byte for byte")
    ap.add_argument("--write", action="store_true", help="rewrite files in place")
    args = ap.parse_args(argv)

    files = sorted(
        {f for p in args.paths for f in ([p] if p.is_file() else p.rglob("*.th"))}
    )
    if not files:
        print("no .th files", file=sys.stderr)
        return 2

    if args.check:
        bad = []
        for f in files:
            src = f.read_text(encoding="utf-8")
            if to_v2(to_v3(src)) != src:
                bad.append(f)
        print(f"round-trip: {len(files) - len(bad)}/{len(files)} files restore byte for byte")
        for f in bad:
            print(f"  DIFFERS  {f}", file=sys.stderr)
        return 1 if bad else 0

    fn = to_v2 if args.to_v2 else to_v3
    for f in files:
        result = fn(f.read_text(encoding="utf-8"))
        if args.write:
            f.write_text(result, encoding="utf-8")
        else:
            sys.stdout.write(result)
    if args.write:
        print(f"rewrote {len(files)} file(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
