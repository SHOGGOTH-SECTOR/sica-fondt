"""
Ichor smoke wiring (D2 §9 test): round-trip an envelope between two stub organs
through the D1 admit check, and confirm an unscreened external payload is rejected
at the barrier.

Build (where ponyc exists):   ponyc src/ichor -o build
Run:                          ./build/ichor
"""

actor Main
  new create(env: Env) =>
    let broker = Broker(env.out)

    let soul = StubOrgan(Soul, env.out)
    let brain = StubOrgan(Brain, env.out)
    broker.register(Soul, soul)
    broker.register(Brain, brain)

    // A system-internal secretion soul -> brain: must cross D1 and be delivered.
    broker.route(Envelope(Soul, Brain, SystemInternal,
      "big4 drawn: sun/asc/moon/mother-other"))

    // An external payload aimed at the brain: D1 must reject it.
    broker.route(Envelope(AdaBorder, Brain, External,
      "unscreened external payload"))

    // Organ-to-organ perfusion (not Brain-bound): delivered directly.
    broker.route(Envelope(Brain, Soul, OrganSecretion,
      "reshuffle: cross-only"))
