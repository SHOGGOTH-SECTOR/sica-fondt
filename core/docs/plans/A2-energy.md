# A2 — E: literal tool-use energy economy

## 1. Component
E is the **tool-call energy** branch of DriveBox, containing PS+ and EthInt as subfunctions. PS+/EthInt alter tool prices and independently signal the homunculus. E is **not** a global existential-load calculator and does not own ETR.

## 2. Status / certainty
**Target specified; runtime stale.** `driver_energy.R` still has a global lock threshold, exponential drag constants, `is_alive` and a hard-death pathway. Those are not the current design.

## 3. Language & location
Current R: `core/src/endocrine/driver_energy.R`; gate-bearing affordability at the trust boundary requires a future Ada/SPARK contract.

## 4. Does / does-not
- **Does:** maintain available activity budget, quote **per-tool** costs, expose **per-tool** minimum-energy requirements independent of cost, consume on action, and recover through rest/replenishment.
- **Does not:** classify what an action morally means, decide whether an action *should* be taken, emit a death verdict at zero, or continuously disturb ETR with normal expenditure.

## 5. Interface contract (target)
- `energy_state -> {current, capacity, ...}` with units and reserve policy open.
- `tool_cost(E, tool, PS+_effect, EthInt_effect) -> cost` (pure). Tool-specific cost functions may differ radically; fixed coefficients are **not** inherited from code.
- `tool_min(tool) -> threshold` (capability requirement independent of cost); `tool_locked := current < tool_min(tool)`.
- `tool_listing` displays cost for unlocked tools, and for locked tools replaces the tool name **in-band** using the established token `[====L⍉¢K€D ϟ ∅ΩΤ====] 《E≠<minimumfortool>》`. No color-only indication.
- `consume(E, chosen_tool) -> E'`; `restore(E, event) -> E'`. Cost, minimum, and restoration rates are to be fitted from invariants, not asserted.
- `catastrophic_depletion_event(E) -> evidence` is a **separate extraordinary event** delivered toward ETR. Catastrophic is not synonymous with low, locked, or ordinary tiredness. Threshold/qualification undecided.

## 6. Dependencies & stubs
A3 PS+ and A6 EthInt provide price modifiers and their own unmediated cognitive secretions. A1 organizes but never approves; A8 receives only qualified catastrophic E events.

## 7. Invariants / laws
- **L1:** E only limits literal tool usage; the homunculus still deliberates and internal activity is not deemed dead at a floor.
- **L2:** no unrecoverable death state from E exhaustion; restoration possible.
- **L3:** tool cost and tool minimum are distinct per-tool values; same-cost tools can lock at different E values.
- **L4:** PS+ and EthInt simultaneously influence E's economics and present their raw/structured signals to cognition.
- **L5:** ordinary E changes do not induce Graph drift. Catastrophic depletion may.
- **L6:** pure cost query cannot mutate E; expenditure follows the homunculus's choice.

## 8. Build steps
Replace the current dead/alive gate and global lock table with invariant-driven per-tool pricing and rendering. Add separate catastrophe qualification. Test bounded consumption and restoration without making up numerical laws.

## 9. Tests
`core/src/endocrine/test_energy.R` needs replacement tests for no-death, tool minima independent of price, in-band lock rendering, and zero ordinary E→ETR coupling.

## 10. Open items
Units, cost functions, tool minima, restoration dynamics, catastrophe threshold, cost-modifier combination rule, source of available energy, and expenditure receipts.
