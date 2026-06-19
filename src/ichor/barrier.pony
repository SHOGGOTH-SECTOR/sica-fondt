// The blood-brain barrier (D1). `Barrier.admit` is the screening decision every
// Brain-bound envelope must pass — perfusion law L2: everything reaching the
// Brain crosses Ada (D1) first.
//
// Real wiring crosses into Ada's `Trust_Guard` (provenance + blocklist + rate)
// via the C/Fortran seam (`ichor_ada_shim.c`). Until that binding is built, this
// mirrors the provenance law in pure Pony so the broker is testable standalone.
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
