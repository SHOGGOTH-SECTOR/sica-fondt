// The membrane (D1). `Barrier.admit` is the screening decision every envelope
// crossing INTO Ada (inbound toward the inner brain) must pass — perfusion law
// L2: nothing reaches the inner brain without crossing Ada first.
//
// STUB NOTE: this `admit` is a pure-Pony STAND-IN that only mirrors the
// provenance law. The real decision lives in Ada's `Trust_Guard` (blocklist +
// provenance + rate) and, above that, the E1 invariant laws. This stand-in must
// be replaced by the real Ada call — see the Ada seam below — before anything
// ships. Do not mistake this for the actual safety screen.
//
// To switch to the Ada border, add `use "lib:ichor_ada"` and replace the body of
// `admit` with the FFI call sketched below.

primitive Barrier
  fun admit(envl: Envelope): Bool =>
    // Pony-side mirror of D1's provenance law (stand-in for Trust_Guard).
    match envl.provenance
    | SystemInternal => true
    | External => false  // external never free-passes the barrier; D1 must screen
    else
      true
    end

  // --- Ada seam (enable once the C shim + ponyc are present) -----------------
  // use "lib:ichor_ada"
  //
  // fun admit_via_ada(envl: Envelope): Bool =>
  //   @ichor_ada_admit[Bool](
  //     _provenance_code(envl.provenance),
  //     envl.payload.cpointer(),
  //     envl.payload.size())
  //
  // fun _provenance_code(p: Provenance): U8 =>
  //   match p
  //   | SystemInternal => 0
  //   | UserInput => 1
  //   | OrganSecretion => 2
  //   | External => 3
  //   end
