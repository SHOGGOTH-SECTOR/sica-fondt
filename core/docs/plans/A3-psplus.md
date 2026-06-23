# A3 — PS+ (Primal Sensates+) driver

## 1. Component
Driver 2: the body. Reads the endomotiv array (A4) + priors (A5) and **passes the raw sensates +
arguments to the agent** — **never summed, no Existential-Load scalar**. It describes and convinces;
it does not aggregate.

## 2. Status / certainty
Structure WORKING (`driver_ps_plus.R`, 63 L); the old aggregate-sum + friction are removed (Anja).

## 3. Language & location
R · `src/endocrine/driver_ps_plus.R` (sources `endocrine_array.R` + `priors.R`; + `test_ps_plus.R`).

## 4. Does / does-not
- **Does:** read the active endomotiv vectors (A4) — **no friction**; read priors (A5); **pass all 30 raw
  sensates + the 2 most salient priors to the agent before tool listing** (Anja — sensates in full, priors
  ranked to the top 2). They describe & convince — the agent then decides, with the per-tool costs from A2.
- **Does-not:** sum, reason, gate, or decide. It asserts "X is happening"; it never approves or routes.

## 5. Interface contract
- `init_ps_plus_state() -> { endocrines:A4, priors:A5 }`.
- `evaluate_reality(state) -> { sensates:[raw per-channel, 30], arguments:[str], is_logical:FALSE }`
  — **all 30 sensates raw, not summed; no friction term; no load scalar.** `arguments` carries the
  **2 most salient priors only** (ranked, not the whole prior set). Surfaced **before tool listing**.

## 6. Dependencies & stubs
A4 endomotiv array — *stub:* `init_endocrine_state()` with canned channel magnitudes.
A5 priors — **priors are *derived*** from what the **outer BERT** reports as frequently-recorded memory
themes, **tied to descriptors of taste / smell / sound + location** (not hand-added records, Anja).
*Stub:* a canned set of derived priors. (Updates A5.)

## 7. Invariants / laws
- **L1 (C5):** PS+ is **illogical by design** — `is_logical = FALSE`. This is **not a deficiency**; it is
  *the source of its power*: sensates **rule the flesh precisely because they can't be reasoned away**
  (sensation, not proposition — no argument to refute, so they steer beneath cognition).
- **L2 (C5):** sensates are sent **raw, never summed** — qualia (the field) and any economy (priced
  elsewhere, A2) ride separate rails; PS+ aggregates nothing.
- **L3 (C4):** the **2 most salient** priors inject large, specific arguments (priors derived per §6);
  only the top 2 surface, ranked by salience — the rest stay silent.

## 8. Build steps
1. **[test approach was wrong — Anja]** rewrite `test_ps_plus.R` for the corrected model: raw/unsummed
   output, no friction, `is_logical=FALSE` as the power-law (L1), sensates-before-tool-listing.
2. Wire the derived-priors source (BERT themes + sensory/location descriptors) — see A5.

## 9. Tests
`Rscript src/endocrine/test_ps_plus.R` (rewritten per §8).

## 10. Open items
- Argument register/format (how the raw sensates are phrased to the agent) — ties to A4 sensational lines.
- The derived-priors pipeline from the outer BERT (C1, shared with A5/F1).
