# Economy organ — M0 stomach

Executable scaffold for M0–M7. The stomach is an OUTER organ: its only organism-facing product is an Ada-bound `organ_secretion`; it never joins the inner bus.

## Implemented now

- **M1 Marketplace** — single action ingress; wallet-first admission; deterministic action/chain law; wallet brake; Conductor veto after law; simulated execution only.
- **M2 Feeds** — normalized datum history with explicit backpressure instead of silent eviction.
- **M3 Sims** — all seven native engine trees are now built in: M3a R statistical, M3b ECLiPSe sociological, M3c Solidity AMM, M3d Fortran MEV, M3e Fortran tokenomics, M3f ECLiPSe consensus, and M3g Fortran microstructure. A live Tcl event-loop clock runs all six horizons at 90:1 or faster; the registry exposes source/runtime status through M0.
- **M4 Wallets** — permanent 1:1 trader binding plus per-action/session exposure brakes. No private-key field, signer, or RPC surface exists yet.
- **M5 Traders** — trader registry and mechanical pause state. AI trader inference is not implemented here.
- **M6 Conductor** — veto-next, pause/resume, SAE alert intake, append-only in-memory decision log. Specialist inference is not implemented yet.
- **M7 SAE** — records Marketplace tool calls and produces alert envelopes; actual sparse-autoencoder inference/training is not implemented yet.
- **M0** — composes the above, stages tax receipts without moving value, and emits a stomach→Ada status secretion.

There is deliberately no live transaction broadcaster. A successful action returns `execution simulated` and a deterministic `simtx-*` identifier. Live custody/execution should not appear until the unresolved M4 key-storage design is ratified.

## Test

```sh
tclsh core/src/economy/tests/stomach.test
```

Expected: `Total 17 Passed 17 ... Failed 0` once the current branch is checked out.

The simulator family also has its own polyglot driver:

```sh
tclsh core/src/economy/sims/run_tests.tcl
```

It executes Tcl + every native suite whose runtime is installed. Use `--strict` to make missing R/ECLiPSe/Foundry runtimes a failure rather than an explicit skip.

## Public scaffold API

`::stomach::Economy` exposes `register_trader`, `bind_wallet`, `submit_action`, `feed_publish`, `feed_history`, `sim_publish`, `query_predictions`, `sim_engines`, `sim_engine_status`, `sim_horizons`, `sim_running`, `sim_advance`, `conductor_veto_next`, `conductor_pause`, `conductor_resume`, `sae_alert`, `tax_event`, and `secretion`.

`secretion` returns the envelope-compatible metadata `source stomach`, `destination ada_border`, `provenance organ_secretion`. The runtime Pony↔Tcl bridge is still an integration task; no code may shortcut D1 while that bridge is built.
