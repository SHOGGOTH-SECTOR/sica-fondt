# G2 — Governance  *(DESIGN-FIRST · EXPLORED/UNRATIFIED)*

## 1. Component
The polity layer: identity keying, scope tiers, roles + weights, permission engine, council, crypto,
tokens, hosting rules. Surfaced by red-lining a flowchart; **parked intact-but-unauthoritative**.

## 2. Status / certainty
DESIGN-FIRST · **C2 (explored, unratified)** — nothing here is a confirmed codebase contract yet.

## 3. Language & location
TBD · new location e.g. `src/governance/`. Likely Ada/SPARK for the permission engine (gate-bearing) +
a crypto sub-extension.

## 4. Does / does-not
- **Does (when ratified):** key identity, gate permissions, seat roles, run the council, govern hosting.
- **Does-not:** touch cognition. It is access/authority, orthogonal to the organs.

## 5. Interface contract (explored — not ratified)
- **Identity:** Discord snowflake (`author.id`, unforgeable); tokenless = *spookgeister*.
- **Scope tiers:** local → regional → global → universal (regional-by-default).
- **Roles + weights (command-quanta):** Tributträger·1 / Mitgehende·2 / Bezirkseigen·8 / Vereinsunbequeme·16 /
  Kumpaneigen·16 / Freigefährten·16 / Kunstschaffenden·? / Haftungsfängerin·256 / das Einzigkunsteigene·256.
- **Permission engine:** default-deny reads; `add_perm`/`del_perm`; self-grant keyless, authority-grant keyed (DM/CLI);
  grantor ladder local→Mitgehende, regional→Bezirkseigen, global→Freigefährten(+key); gates accumulate upward.
- **Council:** two-key (Haftungsfängerin + das Einzigkunsteigene, equal 256, mutual consent); may mint architects,
  escalate, write the invariant core (downtime only); anchor above council.

## 6. Dependencies & stubs
E1 invariant core (council writes it at downtime). D1 (permission gating is border-adjacent). All stubbable.

## 7. Invariants / laws (proposed)
- **L1 (C2):** default-deny; gates accumulate upward; authority-grants are keyed + out-of-band.
- **L2 (C2):** invariant core written **only at downtime**, **only by council** (ties E1).
- **L3 (C2):** anchor (Haftungsfängerin) sits above council.

## 8. Build steps
**Do not build until ratified.** When ratified: 1. permission engine (Ada/SPARK). 2. role/weight registry.
3. council two-key. 4. crypto (LTHING/ML-DSA).

## 9. Tests
(Deferred to ratification.) Permission accumulation; keyed-grant enforcement; downtime-only core writes.

## 10. Open items
- **Everything here is unratified (C2).** Kunstschaffenden weight · formal-inheritance rule · hosting mapping ·
  LTHING crypto primitives · UFT token economics — all C1.
