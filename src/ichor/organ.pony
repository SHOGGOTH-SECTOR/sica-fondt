// What an organ is, to Ichor: anything that can receive a perfused envelope.
// Organs hold no hard reference to each other (perfusion law L1) — they only know
// the Broker. `StubOrgan` is a canned receiver for standalone tests.

interface tag OrganReceiver
  be receive(envl: Envelope)

actor StubOrgan is OrganReceiver
  let _id: OrganId
  let _out: OutStream

  new create(id': OrganId, out': OutStream) =>
    _id = id'
    _out = out'

  be receive(envl: Envelope) =>
    _out.print("    [" + _id.string() + "] received: " + envl.payload)
