# AGENTS.md — M0 economy/stomach organ

Local guide for `core/src/economy`. The design source of truth is `core/docs/plans/M0-economy-organ-hub.md` plus M1–M7.

## Hard boundaries

- This is an **OUTER** organ. Organism-bound output is `Stomach → AdaBorder` with `OrganSecretion` provenance. Never add an inner-bus route.
- Traders never receive RPC, signing, or chain clients. All market actions enter M1 Marketplace.
- M1 deterministic law runs before M6 veto. M6 may veto a legal action; it may not legalize an illegal one.
- M4 wallet brakes are independent of M1/M6. Keep 1:1 trader↔wallet binding literal.
- M7 observes and reports. Enforcement belongs to M6/M1/M4, not the monitor.
- Live key custody and chain broadcast are intentionally absent until the M4 key-storage specification is ratified. Do not smuggle them in as convenience helpers.

## Build/test

Tcl 8.6, standard library only:

```sh
tclsh core/src/economy/tests/stomach.test
```

Use test-first changes. Keep `stomach.tcl` as composition/facade; put component behavior in the M1–M7 module that owns it.
