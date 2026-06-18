# Ichor — the medium / "the blood" (D2)

The perfusion bus the organs share. Organs never wire to each other directly
(perfusion law **L1**); they emit a typed **`Envelope`** to the **`Broker`**, and
everything reaching the **Brain** crosses the **`Barrier`** (Ada D1) first (law
**L2**). Every envelope carries **provenance** so D1 can enforce its laws (**L3**).

Written in **Pony**: actors are the natural shape for a message-passing medium,
and Pony's capabilities give data-race-free sends for free. The broker actor here
backs a socket broker hosted on the Ada barrier in full deployment; the C/Fortran
seam (`ichor_ada_shim.c`) is where it crosses into the Ada border.

## Files
- `envelope.pony` — `Envelope {source, dest, provenance, payload}` + `OrganId` /
  `Provenance` (mirrors Ada `Organ_Message`).
- `barrier.pony` — `Barrier.admit` = the D1 screening decision (Pony mirror of the
  provenance law now; FFI to Ada `Trust_Guard` sketched for when the shim is built).
- `broker.pony` — the perfusion `Broker` actor (register + route; forces Brain-bound
  traffic through the barrier).
- `organ.pony` — `OrganReceiver` interface + a `StubOrgan` for tests.
- `main.pony` — smoke wiring (D2 §9): deliver an internal secretion through D1,
  reject an unscreened external payload, perfuse organ→organ.
- `ichor_ada_shim.c` — the C/Fortran binding seam to the Ada D1 border (stub).

## Build / run (needs ponyc — NOT installed in this env)
```
ponyc src/ichor -o build      # compile the package
./build/ichor                  # run the smoke wiring
```
To wire the real Ada border: build `ichor_ada_shim.c` into `libichor_ada`, enable
`use "lib:ichor_ada"` + the `admit_via_ada` body in `barrier.pony`, and point the
shim at an Ada `Trust_Guard.Screen_Inbound` export.

## Status
Starting scaffold. Pony + Fortran toolchains are absent in this environment, so
this is design-complete source to build where Pony exists — not yet compiled here.
