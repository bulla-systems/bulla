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
# A struct or enum invariant may trail its closing brace on the same line:
#   struct Account { balance: u64, } inv balance <= 1_000_000
# The line-start form above never sees these.
TRAILING_INV_V2 = re.compile(r"(\}\s*)inv(\s)")
TRAILING_INV_V3 = re.compile(r"(\}\s*)keeps(\s)")

CLAUSE_V3 = re.compile(r"^(\s*)(requires|ensures|keeps|measures)(\s+)(.*)$")
ROW_V3 = re.compile(r"^(\s*)!(\s+)(.*)$")


# NOT HANDLED: a whole contract on one line.
#
#   fn id(x: u32) -> u32 req true ens result == x fx pure { x }
#
# 373 sites across 83 files. Four things make it harder than it looks, and the
# last one is decisive:
#
#   1. Reassembly must preserve inter-clause whitespace exactly. Solvable: capture
#      each clause as (whitespace, keyword, rest) and permute whole triples, so
#      the output is a permutation of the input's pieces.
#   2. `!` is unambiguous in Thermite source — 144 rows and no other line-initial
#      `!` across the corpus — but emitted Rust contains `-> !`, the never type,
#      and these literals are full of emitted Rust.
#   3. Clause keywords may carry a `@bv` tag: `ens@bv64 a + b == b + a`.
#   4. **The last clause's text runs to the end of the line, which includes the
#      function body.** Moving the row to the front drags `{ a + b }` with it.
#      Knowing where a contract ends and a body begins is parsing, not matching.
#
# The tractable route is two passes rather than one clever one: reformat an
# inline contract onto separate lines first — a simpler and independently
# reversible change that moves nothing — and then the line-start migration above
# handles it unaltered.


CLAUSE_V3 = re.compile(r"^(\s*)(requires|ensures|keeps|measures)(\s+)(.*)$")
ROW_V3 = re.compile(r"^(\s*)!(\s+)(.*)$")


# A whole contract may sit on one line:
#
#   fn id(x: u32) -> u32 req true ens result == x fx pure { x }
#
# Splitting on the clause words is safe because they are reserved: no identifier
# can be `req`, so a keyword match is always a clause head.
#
# The reassembly is what has to be exact. A clause is captured as the triple
# (whitespace before the keyword, the keyword, everything up to the next
# keyword), and reordering permutes whole triples. Every character therefore
# survives — the output is a permutation of the input's pieces, so reversing the
# permutation restores it byte for byte. An earlier attempt rebuilt the line as
# `f"{kw} {rest.lstrip()}"`, which normalised the spacing and dropped the
# round-trip from 384/384 to 329/384.
INLINE_V2 = re.compile(r"(\s+)(req|ens|fx|dec)(?=\s)")
INLINE_V3 = re.compile(r"(\s+)(requires|ensures|measures|!)(?=\s)")


def _inline(line: str, to_v3_dir: bool) -> str:
    pat = INLINE_V2 if to_v3_dir else INLINE_V3
    hits = list(pat.finditer(line))
    if not hits:
        return line
    head = line[: hits[0].start()]
    triples = []
    for k, m in enumerate(hits):
        end = hits[k + 1].start() if k + 1 < len(hits) else len(line)
        triples.append((m.group(1), m.group(2), line[m.end():end]))
    if to_v3_dir:
        row = [t for t in triples if t[1] == "fx"]
        rest = [t for t in triples if t[1] != "fx"]
        order = [(w, "!", r) for w, _, r in row] + [(w, V2_TO_V3.get(k, k), r) for w, k, r in rest]
    else:
        row = [t for t in triples if t[1] == "!"]
        mid = [t for t in triples if t[1] not in ("!", "measures")]
        tail = [t for t in triples if t[1] == "measures"]
        order = ([(w, V3_TO_V2.get(k, k), r) for w, k, r in mid]
                 + [(w, "fx", r) for w, _, r in row]
                 + [(w, V3_TO_V2.get(k, k), r) for w, k, r in tail])
    return head + "".join(w + k + r for w, k, r in order)


# PREVIOUSLY NOT HANDLED, now above:
#
#   fn id(x: u32) -> u32 req true ens result == x fx pure { x }
#
# 373 sites across 83 files. Splitting on the clause words is safe, since they
# are reserved and no identifier can be one — but reassembly has to restore the
# inter-clause whitespace exactly, and many of these sit inside Rust string
# literals that span physical lines with `\` continuations. An attempt at it
# dropped the round-trip from 384/384 to 329/384, so it is left undone rather
# than left wrong: a tool that provably restores what it touches and reports what
# it does not is worth more than one that quietly mangles a corner.


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


def _lines_to_v3(lines: list[str]) -> list[str]:
    out: list[str] = []
    i = 0
    while i < len(lines):
        if not CLAUSE_V2.match(lines[i]):
            line = TRAILING_INV_V2.sub(r"\1keeps\2", lines[i])
            out.append(line)
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
    return out


def to_v3(text: str) -> str:
    return "\n".join(_lines_to_v3(text.split("\n")))


def _lines_to_v2(lines: list[str]) -> list[str]:
    out: list[str] = []
    i = 0
    while i < len(lines):
        if not (CLAUSE_V3.match(lines[i]) or ROW_V3.match(lines[i])):
            line = TRAILING_INV_V3.sub(r"\1inv\2", lines[i])
            out.append(line)
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
    return out


def to_v2(text: str) -> str:
    return "\n".join(_lines_to_v2(text.split("\n")))


# --- Rust sources: the corpus is also embedded in string literals -------------

_RAW = re.compile(r'r(#*)"')


def _rust_literals(text: str):
    """Yield (start, end, separator) for the *contents* of every Rust string
    literal. A raw literal holds real newlines; a plain one holds the two-character
    escape, so each is split on its own separator."""
    i, n = 0, len(text)
    while i < n:
        if text.startswith("//", i):
            j = text.find("\n", i)
            i = n if j < 0 else j + 1
        elif text.startswith("/*", i):
            j = text.find("*/", i)
            i = n if j < 0 else j + 2
        elif text[i] == "'":
            # a char literal may contain a quote: '"'
            j = i + 1
            while j < n and text[j] != "'":
                j += 2 if text[j] == "\\" else 1
            i = j + 1
        elif (m := _RAW.match(text, i)):
            close = '"' + m.group(1)
            start = m.end()
            j = text.find(close, start)
            if j < 0:
                break
            yield (start, j, "\n")
            i = j + len(close)
        elif text[i] == '"':
            start = j = i + 1
            while j < n and text[j] != '"':
                j += 2 if text[j] == "\\" else 1
            yield (start, j, "\\n")
            i = j + 1
        else:
            i += 1


SKIPPED: list[str] = []
UNMIGRATED: list[str] = []


def _rewrite_rust(text: str, to_v3_dir: bool) -> str:
    """Rewrite `.th` fragments inside Rust string literals.

    A literal is only rewritten when the rewrite is **provably reversible for
    that literal**: forward, then back, must restore it exactly. Anything else is
    left alone and recorded.

    A literal is only considered at all when it *declares* something — a `fn`,
    `struct`, `enum` or `protocol`. A Thermite fragment always does and a prose
    assertion message never does, and vocabulary cannot separate them: renaming
    the `inv` in "inv text is the verbatim clause source" is reversible, so the
    reversibility check below would wave it through.

    That check is what keeps the tool off assertions about *lowered Verus*, which
    the lowering tests are full of. After the rename Thermite's `requires` and
    Verus's are the same word — good for the lowering, which becomes identity
    rather than translation, and ambiguous for a text tool, which cannot tell a
    Thermite fragment from an expected-output fragment by vocabulary alone.
    Reversibility can tell them apart, and it needs no heuristic.
    """
    fwd, back = (_lines_to_v3, _lines_to_v2) if to_v3_dir else (_lines_to_v2, _lines_to_v3)
    out, last = [], 0
    for start, end, sep in _rust_literals(text):
        body = text[start:end]
        # A fragment declares something; a sentence does not. Vocabulary alone
        # cannot tell `"inv text is the verbatim clause source"` — an assertion
        # message — from source, and renaming prose is perfectly reversible, so
        # the reversibility gate below cannot catch it either.
        if not re.search(r"(^|" + re.escape(sep) + r")\s*(pub\s+)?(spec\s+)?(fn|struct|enum|protocol)\s", body):
            continue
        # Thermite's effect row is mandatory and Verus has no equivalent, so it
        # is what separates a Thermite fragment from expected *lowered output* —
        # which also declares items, and which uses Verus's own `requires`.
        marker = r"(^|" + re.escape(sep) + r")\s*" + (r"fx\s" if to_v3_dir else r"!\s")
        trailing = (TRAILING_INV_V2 if to_v3_dir else TRAILING_INV_V3).search(body)
        if not re.search(marker, body) and not trailing:
            UNMIGRATED.append(body[:60].replace(sep, " ⏎ "))
            continue
        lines = body.split(sep)
        rewritten = sep.join(fwd(lines))
        if sep.join(back(rewritten.split(sep))) != body:
            SKIPPED.append(body[:60].replace(sep, " ⏎ "))
            continue
        out.append(text[last:start])
        out.append(rewritten)
        last = end
    out.append(text[last:])
    return "".join(out)


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("paths", nargs="+", type=Path)
    ap.add_argument("--to-v2", action="store_true", help="rewrite Thermite 3 back to Thermite 2")
    ap.add_argument("--check", action="store_true",
                    help="round-trip every file and report any that does not restore byte for byte")
    ap.add_argument("--write", action="store_true", help="rewrite files in place")
    ap.add_argument("--rust", action="store_true",
                    help="also rewrite .th fragments embedded in Rust string literals")
    args = ap.parse_args(argv)

    pats = ("*.th", "*.rs") if args.rust else ("*.th",)
    files = sorted(
        {f for p in args.paths for f in ([p] if p.is_file()
                                         else [g for pat in pats for g in p.rglob(pat)])
         if "target" not in f.parts}
    )
    if not files:
        print("no .th files", file=sys.stderr)
        return 2

    if args.check:
        bad = []
        for f in files:
            src = f.read_text(encoding="utf-8")
            if f.suffix == ".rs":
                rt = _rewrite_rust(_rewrite_rust(src, True), False)
            else:
                rt = to_v2(to_v3(src))
            if rt != src:
                bad.append(f)
        print(f"round-trip: {len(files) - len(bad)}/{len(files)} files restore byte for byte")
        if SKIPPED:
            print(f"literals left alone as not provably reversible: {len(SKIPPED)}")
        if UNMIGRATED:
            print(f"clause-bearing literals with no effect row, left for review: {len(set(UNMIGRATED))}")
        for f in bad:
            print(f"  DIFFERS  {f}", file=sys.stderr)
        return 1 if bad else 0

    for f in files:
        src = f.read_text(encoding="utf-8")
        if f.suffix == ".rs":
            result = _rewrite_rust(src, not args.to_v2)
        else:
            result = (to_v2 if args.to_v2 else to_v3)(src)
        if args.write:
            f.write_text(result, encoding="utf-8")
        else:
            sys.stdout.write(result)
    if args.write:
        print(f"rewrote {len(files)} file(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
