// Ichor smoke wiring — exercises the OUTER bus + the D1 membrane only.
//
// SCOPE / STUB NOTE (read before extending):
//   * Ichor is the OUTER bus ("the skin"). It carries OUTER organs
//     (stomach/economy, microagents, SAE, MoRAG) and delivers inbound traffic
//     to Ada (the membrane). See docs/bus-topology.md.
//   * It is NOT the inner-brain bus (that is Ada-routed, Jorvik) and NOT where
//     Hermes, metacog, soul, drive-box, mini-rag, or the E1 laws live. Never
//     wire an inner organ onto this bus — that is plugging the brain onto the
//     skin.
//   * This is a provisional scaffold proving the broker + membrane mechanics,
//     not the final routing.
//
// Build:  ponyc src/ichor -o build      Run:  ./build/ichor

actor Main
  new create(env: Env) =>
    let broker = Broker(env.out)

    // Outer-bus endpoints. AdaBorder is the membrane: inbound traffic is screened
    // there before it can cross into the inner brain. MoRAG is an outer organ.
    let ada = StubOrgan(AdaBorder, env.out)
    let morag = StubOrgan(MoRAG, env.out)
    broker.register(AdaBorder, ada)
    broker.register(MoRAG, morag)

    // The stomach digests external input into context and sends it inbound to
    // Ada; system-origin context is admitted across the membrane.
    broker.route(Envelope(Stomach, AdaBorder, OrganSecretion,
      "digested context: <pre-chewed user turn>"))

    // A raw external payload aimed straight at the membrane: D1 rejects it.
    broker.route(Envelope(World, AdaBorder, External,
      "unscreened external payload"))

    // Outer organ-to-organ (not membrane-bound): delivered directly, no screen.
    broker.route(Envelope(Stomach, MoRAG, OrganSecretion,
      "retrieve: world context for the next turn"))
