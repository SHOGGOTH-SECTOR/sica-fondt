# Endocrine — self-improvement loop (clean-room SPEC, NO code copied)

Source: `advanced_evolution` — **AGPL-3.0**, nothing copied. Clean-room
description of the *concept* to implement as an R learning loop in the drive
system (not an Ada daemon — Ada is membrane-only).

## Concept

Population-based mutate/evaluate loop (Darwin-Goedel-ish) for self-improving
prompts/skills:

1. Maintain a population of candidate prompts/skill-configs.
2. `mutate()` — LLM-driven variation of a candidate.
3. `evaluate()` — score against a task oracle (noisy is fine).
4. Select survivors; iterate; keep a lineage log.

## Placement

- Lives in `src/endocrine/` as an R module: an autonomous *drive* toward
  improvement, gated by Energy (cost) and Ethical-Integrity (alignment) like the
  other drivers.
- Reimplement from this description only; do not read the AGPL source.
