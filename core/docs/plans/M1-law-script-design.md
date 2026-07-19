# M1 Marketplace — Deterministic Law Script Format Decision Document

## Executive Summary

The M1 Marketplace's law script is a **constitution**: deterministic, auditable, non-Turing, loaded at startup, immutable at runtime (L2). This document compares three candidate formats for expressing M1's scoped invariants (L1–L5), position limits, drawdown stops, action allowlists, wallet-binding requirements, and chain allowlists. We recommend **S-expressions with a fixed combinator set** for its optimal balance of expressiveness, auditability, non-Turing guarantees, and failure-mode isolation.

---

## 1. Candidate Formats

### 1.1 Format A: Declarative Rule Table (YAML/TOML-style records)

**Structure:**
```yaml
rules:
  - id: "rule_001"
    name: "Max BTC position"
    condition:
      asset: "BTC"
      action_type: "buy"
    constraint: { position_limit: 10.0 }
    
  - id: "rule_002"
    name: "Unauthorized chains blocked"
    condition:
      action_type: "*"
    constraint:
      chain_allowlist: ["ethereum", "solana"]
```

**Expressiveness:**
- ✅ Naturally expresses static constraints (position limits, allowlists, drawdown stops).
- ⚠️ Awkward for conditional logic (e.g., "if position > X, then drawdown stop"). Requires deep nesting or external evaluation logic.
- ⚠️ Difficult to express negation, conjunction, or disjunction across multiple fields without ad-hoc extensions.

**Auditability:**
- ✅ Human-readable; rules are self-documenting.
- ✅ Schema validation possible (e.g., JSON Schema, OpenAPI).
- ⚠️ No built-in way to trace evaluation: which rules matched? In what order? Why did law_check pass or fail?

**Non-Turing Guarantee:**
- ✅ Structure is inherently acyclic (no loops, recursion, or branching).
- ⚠️ Depends on implementation: evaluator must be guaranteed to iterate once per rule, no internal loops.
- ⚠️ If evaluator uses external functions (e.g., "call_oracle"), non-Turing status is lost.

**Failure Modes:**
- **Silent mismatches:** A typo in a field name (e.g., `chain_alowlist`) silently skips the rule.
- **Ambiguous precedence:** If multiple rules match, which one applies? YAML provides no ordering semantics.
- **Extension creep:** New logic (e.g., time-based rules, cross-asset constraints) requires schema mutations.

---

### 1.2 Format B: S-expressions with Fixed Combinator Set

**Structure:**
```scheme
(law
  (id "rule_001")
  (name "Max BTC position")
  (check (lambda (action trader wallet)
    (and
      (eq (asset action) "BTC")
      (eq (action-type action) "buy")
      (< (position trader "BTC") 10.0)))))

(law
  (id "rule_002")
  (name "Chain allowlist")
  (check (lambda (action trader wallet)
    (member (chain action) (list "ethereum" "solana")))))
```

**Expressiveness:**
- ✅ Combinator set (`and`, `or`, `not`, `<`, `>`, `member`, `eq`, etc.) is Turing-incomplete by construction.
- ✅ Natural for predicates, constraints, and conditional logic.
- ✅ Extensible via new combinators (e.g., add `ratio-check` for drawdown).
- ✅ Composable: build complex rules from simple primitives.
- ⚠️ Steep learning curve for non-programmers (COBOL-familiar operators may resist).

**Auditability:**
- ✅ Each rule is a pure function: input (action, trader, wallet) → output (pass/fail).
- ✅ Trace semantics are built-in: can log each combinator call, build proof trees.
- ✅ Debuggable: step through symbolic execution.
- ✅ Self-documenting via lambda structure.

**Non-Turing Guarantee:**
- ✅ Combinator set is closed; only allowed operations are enumerated (no `while`, `recurse`, `call-external`).
- ✅ Depth bound: lambda nesting is bounded by law complexity; evaluator can enforce max depth.
- ✅ Time bound: each combinator has known cost; evaluator can enforce max steps.
- ✅ Provably non-Turing if combinator set excludes recursion and cycles.

**Failure Modes:**
- **Syntax errors:** Malformed S-expressions fail at parse time; no silent skips.
- **Undefined combinator:** If a rule uses `(frobnicate ...)`, parser rejects it immediately.
- **Type mismatches:** If a rule tries `(< action "ethereum")` (comparing struct to string), evaluator fails gracefully.
- **Depth/step limits:** If a law is too complex, evaluator flags it at load time, not at runtime.

---

### 1.3 Format C: Decision-Table (Matrix Format)

**Structure:**
```
| Rule ID | Asset | Action | Position Limit | Chain Allowlist | Drawdown Stop | Outcome |
|---------|-------|--------|-----------------|-----------------|---------------|---------|
| R_001   | BTC   | buy    | < 10            | ethereum,solana | n/a           | PASS    |
| R_001   | BTC   | buy    | >= 10           | ethereum,solana | n/a           | FAIL    |
| R_002   | *     | *      | n/a             | ethereum,solana | n/a           | PASS if chain in list |
| R_003   | ETH   | sell   | n/a             | ethereum,solana | < 20% loss    | PASS    |
```

**Expressiveness:**
- ✅ Intuitive for auditors: each row is a rule, each column is a fact or constraint.
- ⚠️ Difficult to express complex logic (e.g., "if position > X AND wallet binding missing, fail"). Requires cartesian product of rows.
- ⚠️ Scaling: N conditions × M values = O(N×M) rows; easily becomes unwieldy.
- ✅ Good for classification / risk matrices.

**Auditability:**
- ✅ Highly visual: auditor can scan rows and see all rules at once.
- ✅ Compliance-friendly: decision tables are used in regulated industries (banking, insurance).
- ⚠️ Redundancy: same constraint repeated across many rows; easy to introduce inconsistencies.
- ⚠️ No inherent proof structure: why did a row match? Requires external tracing.

**Non-Turing Guarantee:**
- ✅ Table is finite; no loops or recursion by structure.
- ⚠️ Depends on "Outcome" cell: if it can call arbitrary functions, non-Turing is lost.
- ⚠️ Row matching logic must be deterministic and acyclic.

**Failure Modes:**
- **Row ordering ambiguity:** If multiple rows match, which takes precedence? Table format doesn't specify.
- **Incomplete coverage:** If no row matches, what happens? Default to PASS or FAIL?
- **Maintenance complexity:** Adding a new constraint requires rebuilding the entire table (cartesian product).
- **Hidden correlations:** Hard to see relationships between rules (e.g., "R_001 always paired with R_003").

---

## 2. Comparative Analysis

| Criterion | A (Declarative) | B (S-expr) | C (Decision-table) |
|-----------|-----------------|------------|-------------------|
| **Expressiveness** | ⭐⭐ (static constraints) | ⭐⭐⭐⭐⭐ (composable predicates) | ⭐⭐⭐ (classification) |
| **Auditability** | ⭐⭐⭐ (readable, schema-valid) | ⭐⭐⭐⭐⭐ (proof trees, trace logs) | ⭐⭐⭐⭐ (visual, tabular) |
| **Non-Turing guarantee** | ⭐⭐⭐ (structural, not airtight) | ⭐⭐⭐⭐⭐ (provable, combinator-closed) | ⭐⭐⭐ (structural) |
| **Extensibility** | ⭐⭐ (schema mutation) | ⭐⭐⭐⭐ (add combinators) | ⭐ (cartesian explosion) |
| **Human readability** | ⭐⭐⭐⭐ | ⭐⭐⭐ (for programmers) | ⭐⭐⭐⭐ |
| **Failure-mode isolation** | ⭐⭐ (silent mismatches) | ⭐⭐⭐⭐⭐ (fail-fast parsing) | ⭐⭐⭐ (depends on semantics) |

---

## 3. Recommendation: S-expressions with Fixed Combinator Set

**We recommend Format B** for the following reasons:

1. **Non-Turing Provability (L2 requirement):** S-expressions with a closed combinator set are provably non-Turing. The Marketplace can enumerate all allowed operations at startup, verify no cycles or unbounded loops, and enforce step/depth limits at evaluation time. This is unmatched by Formats A and C.

2. **Auditability & Traceability:** Each law is a pure function with explicit inputs and outputs. The evaluator can build a **proof tree** showing which combinators matched, in what order, and why `law_check` passed or failed. Auditors can step through the logic symbolically. Formats A and C lack this transparency.

3. **Failure-Mode Isolation:** Parse-time and load-time failures catch errors immediately. A malformed law (undefined combinator, type mismatch, depth exceeded) fails hard at startup—no silent skips, no runtime surprises. This mirrors the COBOL vault invariant (S3 / S99).

4. **Extensibility without Mutation:** New constraints (drawdown ratio checks, wallet-binding logic, time-based rules) are added as new combinators, not schema mutations. The core evaluator remains stable.

5. **Compatibility with L3-L5:**
   - **L3 (no wallet, no access):** Combinator `(wallet-bound? wallet)` is a primitive.
   - **L4 (veto after law, before execution):** Combinator set does not include veto logic; law_check is orthogonal to veto_check.
   - **L5 (logging):** Evaluator logs each law invocation and result; combinators are traceable.

6. **Operator + Homunculus Signatures (L2):** The S-expression law script is a single immutable text blob, signed at startup. Easier to sign and verify than YAML (schema-dependent serialization) or decision tables (multi-row format).

---

## 4. Fixed Combinator Set

The law script evaluator provides a **closed set** of combinators. No new combinators are added at runtime; changes to the combinator set require a restart with new signatures.

### Core Combinators

**Logical:**
- `(and expr1 expr2 ...)` — conjunction (short-circuits on false).
- `(or expr1 expr2 ...)` — disjunction (short-circuits on true).
- `(not expr)` — negation.

**Comparison:**
- `(eq x y)`, `(ne x y)` — equality / inequality.
- `(<  x y)`, `(>  x y)`, `(<=  x y)`, `(>=  x y)` — numeric comparison.

**Membership:**
- `(member item (list ...))` — item in list? Returns true/false.
- `(in-range value min max)` — value in [min, max)?

**Predicates on Action/Trader/Wallet:**
- `(asset-is action symbol)` — asset == symbol.
- `(action-type-is action type)` — action type (buy, sell, mint, etc.).
- `(position-limit trader asset limit)` — trader's position in asset < limit.
- `(drawdown-limit trader asset percent)` — realized drawdown < percent.
- `(chain-is action chain)` — blockchain == chain.
- `(wallet-bound wallet)` — wallet is non-null.
- `(wallet-approved wallet trader)` — wallet is approved for this trader (from M4 binding).
- `(status-is trader status)` — trader status (active, suspended, etc.).

**Arithmetic (safe):**
- `(+ x y)`, `(- x y)`, `(* x y)`, `(/ x y)` — bounded arithmetic (saturation on overflow).

**Control (non-Turing):**
- `(cond (test1 result1) (test2 result2) ...)` — if-then-else (no loops).
- `(comment "text" expr)` — documentation; evaluates expr, returns result.

### Forbidden Operations
- `(loop ...)`, `(while ...)`, `(recurse ...)` — unbounded iteration.
- `(call-external ...)`, `(invoke-oracle ...)` — non-deterministic side effects.
- `(eval ...)`, `(quote ...)` — metaprogramming.

---

## 5. Example Marketplace Constitution (M1-v1)

```scheme
;;; M1 Marketplace — Deterministic Law Script v1
;;; Loaded at startup; immutable at runtime (M1-L2).
;;; Operator & Homunculus signatures below.

;;; ============================================================
;;; HEADER: Version, Signatures, Metadata
;;; ============================================================

(constitution
  (version "1.0")
  (effective-date "2026-07-19T00:00:00Z")
  (operator-signature "0x1234...abcd") ; Operator's Ed25519 signature
  (homunculus-signature "0x5678...efgh") ; Homunculus's Ed25519 signature
  (description "M1 Marketplace law script v1: enforces L1-L5 invariants, position limits, chain allowlists.")
)

;;; ============================================================
;;; L1: All market actions route through Marketplace
;;; (Implicit: law_check is the only gate. No on-chain bypass possible.)
;;; ============================================================

;;; ============================================================
;;; L3: No wallet, no access
;;; ============================================================

(law
  (id "L3-wallet-binding")
  (name "Trader must have bound wallet")
  (description "L3 invariant: a trader without a bound wallet cannot submit actions.")
  (check (lambda (action trader wallet)
    (wallet-bound wallet))))

;;; ============================================================
;;; L4: Veto is checked after law, before execution
;;; (Implicit: law_check runs first, then veto_check. No veto in law script.)
;;; ============================================================

;;; ============================================================
;;; L5: Every action is logged
;;; (Implicit: evaluator logs all law_check invocations, pass or fail.)
;;; ============================================================

;;; ============================================================
;;; Position Limits (per-asset, per-trader)
;;; ============================================================

(law
  (id "LIMIT-BTC")
  (name "BTC position limit")
  (description "No single trader may hold > 10 BTC.")
  (check (lambda (action trader wallet)
    (or
      (not (asset-is action "BTC"))
      (position-limit trader "BTC" 10.0)))))

(law
  (id "LIMIT-ETH")
  (name "ETH position limit")
  (description "No single trader may hold > 100 ETH.")
  (check (lambda (action trader wallet)
    (or
      (not (asset-is action "ETH"))
      (position-limit trader "ETH" 100.0)))))

(law
  (id "LIMIT-USDC")
  (name "USDC position limit")
  (description "No single trader may hold > 1M USDC.")
  (check (lambda (action trader wallet)
    (or
      (not (asset-is action "USDC"))
      (position-limit trader "USDC" 1000000.0)))))

;;; ============================================================
;;; Drawdown Stops
;;; ============================================================

(law
  (id "STOP-20pct-drawdown")
  (name "Drawdown stop at 20%")
  (description "If a trader's realized drawdown exceeds 20%, no further sells (or limit actions) until reset.")
  (check (lambda (action trader wallet)
    (or
      (not (action-type-is action "sell"))
      (drawdown-limit trader "all" 20.0)))))

;;; ============================================================
;;; Action Allowlists: Only buy, sell, mint, provide_liquidity, withdraw, claim_rewards
;;; ============================================================

(law
  (id "ACTION-allowlist")
  (name "Only allowed action types")
  (description "Marketplace only accepts: buy, sell, mint, provide_liquidity, withdraw_liquidity, claim_rewards.")
  (check (lambda (action trader wallet)
    (member (action-type action) 
      (list "buy" "sell" "mint" "provide_liquidity" "withdraw_liquidity" "claim_rewards")))))

;;; ============================================================
;;; Chain Allowlist: ethereum, solana, arbitrum
;;; ============================================================

(law
  (id "CHAIN-allowlist")
  (name "Supported chains only")
  (description "Actions are allowed only on ethereum, solana, or arbitrum.")
  (check (lambda (action trader wallet)
    (member (chain action) 
      (list "ethereum" "solana" "arbitrum")))))

;;; ============================================================
;;; Wallet Approval: Wallet must be approved for this trader
;;; ============================================================

(law
  (id "WALLET-approval")
  (name "Wallet must be approved for trader")
  (description "The bound wallet must be explicitly approved for this trader by M4.")
  (check (lambda (action trader wallet)
    (wallet-approved wallet trader))))

;;; ============================================================
;;; Trader Status: Only active traders can submit actions
;;; ============================================================

(law
  (id "TRADER-status")
  (name "Trader must be active")
  (description "Only traders with status 'active' can submit actions. Suspended or banned traders are rejected.")
  (check (lambda (action trader wallet)
    (status-is trader "active"))))

;;; ============================================================
;;; End of Constitution
;;; ============================================================
```

---

## 6. Evaluation & Versioning

### Law Script Loading (Startup)

1. **Parse:** S-expression parser validates syntax. Reject if malformed.
2. **Verify Signatures:** Extract operator + Homunculus signatures; verify with Ed25519 public keys. Reject if invalid.
3. **Validate Combinators:** Scan all `(lambda ...)` expressions; ensure only allowed combinators are used. Reject if undefined combinator found.
4. **Enforce Depth Limits:** Check that lambda nesting depth < 20 (configurable). Reject if exceeded.
5. **Load into Memory:** Store law script as immutable bytecode. Set flag: law script is loaded and locked.

### Law Check Execution

```
law_check(action: MarketAction) -> { pass | violation(rule_id, reason) }
```

1. Iterate over all laws (in order of definition).
2. For each law, invoke `(check action trader wallet)`.
3. If lambda returns **false**, record violation(rule_id, reason) and stop.
4. If all laws return **true**, return pass.
5. Log every invocation: rule_id, inputs, output, timestamp.

### Versioning & Updates

- **Current Version:** `"1.0"` (loaded at startup).
- **Update Process:** Operator + Homunculus jointly author a new law script (version `"1.1"`), sign it, submit to Marketplace coordinator.
- **Activation:** Coordinator restarts Marketplace with new law script; old version is abandoned. (No in-flight migration; trades-in-progress must complete or be canceled.)
- **Audit Trail:** Every law script version is archived with signatures, timestamp, and change log.

---

## 7. Failure Modes & Mitigation

### Parse Failure
- **Mode:** Malformed S-expression (unmatched parens, undefined combinator).
- **Mitigation:** Fail at startup; operator is alerted; Marketplace does not boot. Prevents silent corruption.

### Signature Mismatch
- **Mode:** Law script is edited after signing (operator or Homunculus signature invalid).
- **Mitigation:** Fail at startup; abort boot. Ensures L2 immutability.

### Combinator Overflow
- **Mode:** Lambda nesting depth or step count exceeded (accidentally or maliciously complex law).
- **Mitigation:** Reject at load time if depth > limit; reject at runtime if steps > limit. Ensures termination.

### Silent Falses
- **Mode:** A law returns false due to unforeseen input (e.g., null asset).
- **Mitigation:** Combinator set includes explicit nil-checks (e.g., `(asset-is action "NULL")` returns false, not an error). Evaluator logs the false + reason.

### Type Mismatches
- **Mode:** Lambda tries to compare incompatible types (e.g., `(< "BTC" 10.0)`).
- **Mitigation:** Type-check at parse time or runtime. Reject with clear error. No silent type coercion.

---

## 8. Rationale for S-expressions

1. **Provable Non-Turing:** Closed combinator set with explicit enumeration. No ambiguity.
2. **Audit Trail:** Proof trees show exactly which laws matched, in what order. Compliance-ready.
3. **Fail-Fast Design:** Parse-time and load-time validation catch errors before runtime. Mirrors S99 / vault pattern.
4. **Composability:** Complex rules built from simple primitives. Easy to extend without schema mutations.
5. **Testability:** Each combinator is independently testable. Laws are pure functions.
6. **Operator + Homunculus Signatures:** Single immutable law text is signed; no serialization ambiguity.

---

## 9. Transition Path

1. **Phase 1 (Sprint N):** Implement S-expression parser + combinator evaluator. Write unit tests for all combinators.
2. **Phase 2 (Sprint N+1):** Wire M1 `law_check` to S-expression evaluator. Test with example constitution (above).
3. **Phase 3 (Sprint N+2):** Integrate M4 (wallet binding), M6 (veto), M7 (logging). End-to-end smoke test.
4. **Phase 4 (Sprint N+3):** Operator + Homunculus review; sign v1 law script. Deploy to production.

---

## 10. Open Questions for Review

1. **Combinator Set Completeness:** Are there missing combinators for L1-L5 or position logic?
2. **Step/Depth Limits:** What are safe upper bounds? (Suggest: max_depth=20, max_steps=1000.)
3. **Error Messages:** How granular should violation reasons be? (E.g., "position_limit_exceeded_BTC_5.2_of_10.0" vs. "position_limit_exceeded"?)
4. **Signature Algorithm:** Ed25519, ECDSA, or other? (Recommend: Ed25519, matching COBOL vault.)
5. **Tax Collection (M0):** Where does tax logic live—in M1 law script or in a separate M0 component? (Out of scope here; M1 calls tax stub.)

---

## Conclusion

**S-expressions with a fixed combinator set** provide the optimal combination of expressiveness, auditability, non-Turing provability, and failure-mode isolation for M1's deterministic law script. The format aligns with the COBOL vault pattern (S99 / immutability + dual signatures), scales naturally with new constraints, and enables full audit trails for compliance.
