# Ichor — the OUTER perfusion bus (D2)

Ichor is the **outer** bus — "the skin". It carries the **outer organs**
(stomach/economy, microagents, SAE, MoRAG/GoDAGRAG) and delivers inbound traffic
to **Ada (D1)**, the membrane. See `docs/bus-topology.md` for the full topology.

**What Ichor is NOT** (do not violate):
- It is **not** the inner-brain bus. The inner bus is **Ada-routed (Jorvik)**.
- It does **not** carry inner organs — soul, metacog, drive-box, mini-rag,
  **Hermes**, or the E1 invariant laws. Wiring any of those onto Ichor is
  "plugging the brain onto the skin". Don't.
- Hermes is an **inner** organ; it was never approved on Pony/Ichor.

Perfusion laws: organs never wire to each other directly (**L1**) — they emit a
typed `Envelope` to the `Broker`; anything crossing **into Ada** is screened by
the `Barrier` first (**L2**); every envelope carries **provenance** (**L3**).

## Files
- `envelope.pony` — `Envelope {source, dest, provenance, payload}` + `OrganId`
  (OUTER organs only) / `Provenance`. Mirrors the Ada `Border_Message` shape.
- `barrier.pony` — `Barrier.admit`: the membrane screen. **STUB** — a pure-Pony
  stand-in for the provenance law; the real screen is Ada `Trust_Guard`
  (blocklist + provenance + rate) plus the **E1 invariant laws**.
- `broker.pony` — the outer `Broker` (register + route; forces Ada-bound traffic
  through the barrier).
- `organ.pony` — `OrganReceiver` interface + a `StubOrgan` for tests.
- `main.pony` — smoke wiring: stomach digests → inbound to Ada (admitted); raw
  external → Ada (rejected); outer organ→organ (direct).
- `ichor_ada_shim.c` — **STUB** C/Fortran seam to the Ada border (not yet wired).

## Build / run
```
ponyc src/ichor -o build      # built clean on ponyc 0.64.0
./build/ichor
```
Expected: stomach→ada_border admitted, world→ada_border rejected at D1,
stomach→morag delivered directly. Install ponyc via `ponyup` if absent (the env
is ephemeral; toolchain is per-session, reinstalled by the SessionStart hook).

## Status
Provisional **outer-bus** scaffold — compiles and runs. The `Barrier` is a
**stand-in**, not the real safety screen; the real screen is Ada `Trust_Guard`
+ the E1 invariant laws, reached over the seam (transport TBD — IPC vs in-proc
is an open decision). Nothing here reaches the inner brain directly.
