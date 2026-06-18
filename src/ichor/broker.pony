// The perfusion broker. Organs register, then emit envelopes by `route` — the
// broker delivers to the destination organ. Brain-bound traffic is forced through
// the D1 Barrier first (law L2). No organ holds another's reference (law L1); the
// broker is the only shared point.
//
// In full deployment this actor backs a socket broker hosted on the Ada barrier;
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
    // L2: everything reaching the Brain crosses Ada (D1) first.
    if (envl.dest is Brain) and (not Barrier.admit(envl)) then
      _out.print("[ichor] D1 REJECT " + envl.string())
      return
    end

    try
      _organs(envl.dest.string())?.receive(envl)
      _out.print("[ichor] perfuse  " + envl.string())
    else
      _out.print("[ichor] no organ registered at " + envl.dest.string())
    end
