# G1 — Stress-loop contract  *(cross-cutting)*

## 1. Component
The cross-organ loop that turns conviction-violation into existential motion. Binds SAE (F2),
Eth-Int's conviction array (A7), the endomotiv array (A4), ETR (A8), and identity reshuffle (B2).
This is the contract those organs build against; it is **not new code**, it is the wiring law.

## 2. Status / certainty
C2/C3 — the shape is decided; the **stress endomotiv choice + thresholds are C1**.

## 3. Language & location
Contract doc (this file) realized across A4/A7/A8/B2/F2; transport via the medium (D2).

## 4. Does / does-not
- **Does:** define the signal path and each organ's obligation in it.
- **Does-not:** implement any organ (each owns its end).

## 5. Interface contract (the loop)
1. **A7** convictions carry semantic-isomorphy tags; expose `top_convictions`.
2. **F2 (SAE)** detects agent outputs opposing those top convictions (tag match) → `opposition_signal`.
3. **A4** releases a **stress endomotiv** on opposition (*which channel = undecided, C1*).
4. The stress (a) **drives ETR drift** (A8) — endocrine pressure shapes *how* — and is the **L5 cross-axis
   coupling mediator**; (b) if **strong enough → full re-natal reshuffle** (B2); (c) **raises conviction
   shift-rates** (A7).
- **Signal shape:** `stress{ magnitude, source_conviction_id, endomotiv_channel }`.

## 6. Dependencies & stubs
Each participating organ stubs the others at this contract (already noted in A4/A7/A8/B2/F2 specs).

## 7. Invariants / laws
- **L1 (C3):** stress originates from **conduct** (outputs vs convictions), detected at the boundary — "judge the fruits."
- **L2 (C2):** stress is the **single mediator** for ETR cross-axis coupling (A8 L5) and the reshuffle/shift-rate effects.
- **L3 (C1):** the "too strong → full reshuffle" threshold; which endomotiv carries stress; the shift-rate response.

## 8. Build steps
1. Lock the signal shape (§5). 2. Implement each end against it (A7 tags, F2 detect, A4 release, A8 drift, B2 trigger).
3. Fit the thresholds invariants-first (no asserted cutoffs).

## 9. Tests
End-to-end on stubs: an opposing output → stress signal → ETR drifts + (above threshold) reshuffle + shift-rate↑.

## 10. Open items
- **Which endomotiv** carries stress (C1, A4). **Reshuffle threshold** (C1, B2). **Shift-rate curve** (C1, A7).
  ETR coupling mapping (C1, A8 L5).
