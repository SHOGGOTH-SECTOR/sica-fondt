// The perfusion broker for the OUTER bus. Outer organs register, then emit
// envelopes by `route` — the broker delivers to the destination organ. Traffic
// bound for Ada (AdaBorder) — i.e. inbound across the membrane toward the inner
// brain — is forced through the D1 Barrier first (law L2). No organ holds
// another's reference (law L1); the broker is the only shared point.
//
// This is the OUTER bus only. It does not carry inner organs and does not reach
// the inner brain directly — it hands off to Ada, which routes the inner bus.
// In full deployment this actor backs a socket broker hosted on the Ada border;
// here it routes in-process so the wiring is exercisable without sockets.

use "collections"

actor Broker
  let _out: OutStream
  let _organs: Map[String, OrganReceiver tag] = Map[String, OrganReceiver tag]

  new create(out': OutStream) =>
    _out = out'

  be register(id: OrganId, organ: OrganReceiver tag) =>
    _organs(id.string()) = organ
    _out.print("[ichor] register " + id.string())

  be route(envl: Envelope) =>
    // L2: anything inbound across the membrane (bound for Ada) is screened first.
    if (envl.dest is AdaBorder) and (not Barrier.admit(envl)) then
      _out.print("[ichor] D1 REJECT " + envl.string())
      return
    end

    try
      _organs(envl.dest.string())?.receive(envl)
      _out.print("[ichor] perfuse  " + envl.string())
    else
      _out.print("[ichor] no organ registered at " + envl.dest.string())
    end
