# M3 — Cost ledger

## 1. Component
The stomach's accounting book: records **every resource expenditure** across the economy organ and,
optionally, across the organism. Every token spent on digestion (M2), every budget check (M4),
every outer-bus exchange (M7) — the ledger knows. This is the "money" in "M for money": if it
costs something, it's in the ledger.

## 2. Status / certainty
DESIGN-FIRST · ABSENT. No cost tracking exists anywhere in the system. A2 (energy driver) tracks
an internal activation/rest budget but has no concept of external resource costs. Role C3;
implementation C1.

## 3. Language & location
TBD · `src/economy/ledger/` or similar. Needs durable-enough storage to survive a session (but
the container is ephemeral, so "durable" means in-memory with optional flush — not a database).
Could be R (to sit near A2), Pony (bus-native), or a simple append-only log.

## 4. Does / does-not
- **Does:** record every resource expenditure as a `LedgerEntry` (who spent, what action, how much,
  when); provide totals by organ, by action type, and grand total; answer "how much has been spent?"
  and "how much is left?" (the latter via M4's budget).
- **Does-not:** decide whether to spend (M4 governs that); price tools (A2 does); restrict actions
  (Ada D1 polices); optimize or suggest cheaper paths (that's a future concern, not a ledger's job).

## 5. Interface contract
- `record(entry: LedgerEntry) -> receipt_id`.
  `LedgerEntry { organ_id, action, resource_type, amount, timestamp }`.
  `resource_type` ∈ { `input_tokens`, `output_tokens`, `compute_ms`, `api_call` }.
- `total(filter?) -> num` — total spent, optionally filtered by organ/action/resource_type/time range.
- `entries(filter?) -> [LedgerEntry]` — raw entries for audit.
- The ledger is **append-only** at runtime — entries are never modified or deleted (the books don't
  get cooked). A session-start reset is fine (ephemeral container).

## 6. Dependencies & stubs
- M2 digestion core — primary cost source (reports `actual_cost` per digestion).
- M4 budget governor — reads totals to compute remaining budget; *stub:* the ledger is usable
  without M4 (it just records, doesn't enforce).
- A2 energy driver — potential consumer of cost data for pricing; *stub:* no integration initially.

## 7. Invariants / laws
- **L1 (C4):** the ledger is **append-only** — no entry is ever mutated or deleted at runtime.
- **L2 (C4):** **completeness** — every resource expenditure in the economy organ produces a
  ledger entry; no "off-books" spending.
- **L3 (C3):** the ledger is **passive** — it records, it never blocks or delays an action.
  Enforcement is M4's job.

## 8. Build steps
1. Define `LedgerEntry` shape and the append-only store (in-memory list; consider a ring buffer
   with a cap if memory is a concern in long sessions).
2. Wire M2 → M3 (digestion cost recording).
3. Implement `total` and `entries` queries with filtering.
4. Optional: flush to disk / log file for post-session audit.

## 9. Tests
Append: entries accumulate, count matches. Immutability: no mutation API exists. Totals: filtered
totals match manual sum. Completeness: a mock M2 digestion produces a corresponding ledger entry.

## 10. Open items
- Whether the ledger scope extends beyond the economy organ to track costs for other organs
  (MoRAG model calls, SAE compute, Brain inference). Start organ-scoped; expand if needed.
- Storage cap / eviction policy for very long sessions (ring buffer vs unbounded).
- Post-session export format (JSON log? CSV?).
