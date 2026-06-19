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

## Build / run
```
ponyc src/ichor -o build      # compile the package (built clean on ponyc 0.64.0)
./build/ichor                  # run the smoke wiring
```
Expected output: internal secretion soul→brain perfused, external→brain rejected
at D1, brain→soul cross-perfused. Install ponyc via `ponyup` if absent (the env
is ephemeral, so the toolchain is per-session).
To wire the real Ada border: build `ichor_ada_shim.c` into `libichor_ada`, enable
`use "lib:ichor_ada"` + the `admit_via_ada` body in `barrier.pony`, and point the
shim at an Ada `Trust_Guard.Screen_Inbound` export.

## Status
Starting scaffold — **compiles and runs** (ponyc 0.64.0). The Ada-side shim
(`ichor_ada_shim.c`) is still a stub; wiring `Barrier.admit` to the real Ada
`Trust_Guard` is the next step.
