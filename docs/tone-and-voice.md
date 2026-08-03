# Tone and voice

The standard for prose in this repository: documentation, commit messages, PR
text, and code comments. The goal is an affirmative, precise case for the work.
Credibility comes from the content, and the plainness is what makes it land.

Adapted from Thermite's `.design/tone-and-voice.md` (MIT, dollspace.gay), which
is the upstream original. The additions here are the sections on status
vocabulary and evidence, which is where this project's prose tends to drift.

## Affirmative, not defensive

Prose written in response to critique argues with an imagined skeptic. Remove
that register.

- State what the system does and why. Build the case forward rather than
  preempting objections.
- Cut defensive scaffolding: "don't trust us," "this is operational, not
  aspirational," "no new claims are made here." If a limitation is real, state
  it once as a plain fact and move on.
- One clear statement beats a repeated disclaimer.

## Plain, not emphatic

- No ALL-CAPS for emphasis. Keep ALL-CAPS for acronyms (SMT, UEFI, DMA) and for
  the status labels the project's vocabulary depends on: SHIPPED, NOT STARTED.
- No intensifiers doing emphatic work: "exactly," "precisely," "actually,"
  "genuinely," "deliberately," "truly."
- No dramatic framing: "the single most," "load-bearing" when decorative.
- Prefer the precise engineering claim to the vivid one. "Two builds on one host
  produced identical bytes" beats "determinism confirmed rather than inherited."

`exactly` deserves a claim-by-claim check rather than blanket removal. It is
technical when it disambiguates — "matched against one registry entry on fifteen
fields" is a cardinality claim — and tonal otherwise. Strip the tonal use; often
the precise verb or noun was the real claim. In code comments this matters twice
over: residual emphasis is what a later reader or agent anchors on and drifts
toward.

## Narrative stays localized

- A brief metaphor is welcome in an introduction or a closing note. The README's
  opening paragraph about the clay bulla is the intended shape.
- Everywhere else — mechanism descriptions, build steps, evidence tables, API
  docs, comments — stay technical.

## Avoid the tics

These patterns read as performative and erode credibility.

- **The antithesis pair.** "Not tested — proven." "X, not Y." "Not just X but
  Y." State the positive claim directly.
- **Virtue adverbs.** "fails *loudly*," "*cleanly* separated," "reports
  *honestly*." Describe the behavior; do not praise it.
- **Em-dash drama.** A dash landing a punchy aside is a tell. Prefer a period.
  At most one dash per paragraph, and only for a genuine parenthetical.
- **Rhetorical bold.** Bold marks a defined term or a real label, not a sentence
  the reader is meant to feel.
- **Cute asides.** Delete them.

## Status vocabulary is not tone

SHIPPED and NOT STARTED are labels with definitions in
[CONTRIBUTING.md](../CONTRIBUTING.md). They are not emphasis and are not
softened. A tone pass never converts a binary status into a hedge, and never
introduces a third category by wording.

## Let the evidence carry the weight

This project's claims are unusually checkable: digests, per-scenario boot
results, per-clause tuples. Where a number or a digest is available, it does the
persuading. Prose that restates how rigorous the check was is doing work the
number already did.

- "Two builds, same 67108864 bytes, `e08db880…`" needs no adjective.
- Report a limitation in the same register as a success. "The digests differ
  between hosts" is the whole sentence.

## Preserve substance

This is a register change, not a content change.

- Do not alter claims, numbers, digests, identifiers, file paths, requirement
  names, certificate fields, or document structure.
- Do not soften a true, specific guarantee into a vague one. Calm the framing
  and keep the precision.
- Do not remove a stated limitation while removing the emphasis around it.
