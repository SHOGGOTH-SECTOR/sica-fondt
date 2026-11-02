# AGENTS.md — M0 economy/stomach organ

Local guide for `core/src/economy`. The design source of truth is `core/docs/plans/M0-economy-organ-hub.md` plus M1–M7.

## Hard boundaries

- This is an **OUTER** organ. Organism-bound output is `Stomach → AdaBorder` with `OrganSecretion` provenance. Never add an inner-bus route.
- Traders never receive RPC, signing, or chain clients. All market actions enter M1 Marketplace.
- M1 deterministic law runs before M6 veto. M6 may veto a legal action; it may not legalize an illegal one.
- M4 wallet brakes are independent of M1/M6. Keep 1:1 trader↔wallet binding literal.
- M7 observes and reports. Enforcement belongs to M6/M1/M4, not the monitor.
- Live key custody and chain broadcast are intentionally absent until the M4 key-storage specification is ratified. Do not smuggle them in as convenience helpers.
- Registry/source presence is **not** runtime wiring. M3a/M3b/M3c/M3e have tested native query
  bridges; M3d/M3f/M3g do not yet.
- The M3 horizon clock is live, but it does not yet dispatch/refresh all native engines
  automatically. Do not document or code-review it as continuous native execution until that loop
  exists and has an explicit test.
- M5 identity state is not Trader inference, M6 veto state is not Conductor inference, and M7
  logging is not SAE inference. Keep those boundaries literal.

## Build/test

Tcl 8.6 orchestration, plus native simulator runtimes:

```sh
tclsh core/src/economy/tests/stomach.test
tclsh core/src/economy/sims/tests/hub_runtime.test
tclsh core/src/economy/sims/run_tests.tcl
```

Dedicated CI owns the end-to-end native boundary for M3a, M3b, M3c, and M3e. Fortran kernels are
compiled under `-std=f2018 -Wall -Wextra -Werror -pedantic`.

Use test-first changes for behavior. Keep `stomach.tcl` as composition/facade; put component
behavior in the M1–M7 module or M3 native runner that owns it.
