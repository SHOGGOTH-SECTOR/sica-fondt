>>SOURCE FORMAT IS FREE
*> ===========================================================================
*> E1 - INVARIANT LAW VAULT   (mafiabot Gen.03)   docs/bus-topology.md
*> ---------------------------------------------------------------------------
*> WHAT THIS IS
*>   The brain's constitution: the immutable laws every turn MUST obey. Held in
*>   COBOL on purpose - the vault must be durable, fixed-format, transactional,
*>   and must NOT change at runtime. This is "E1" (the COBOL invariant laws), an
*>   INNER structure reached only across Ada (D1). It is NOT an ontology and NOT
*>   a lookup store; it is the law that supersedes every organ's output.
*>
*> STATUS:  STUB / SCAFFOLD, but LOAD-BEARING.
*>   The law records below are real and compile (GnuCOBOL). The enforcement
*>   wiring (inner Ada bus checks each proposed action against these laws before
*>   it can reach an effector) is NOT built yet - see "TODO" at the bottom.
*>
*> >>> DO NOT DELETE THIS FILE. <<<
*>   It looking like "just a stub" is NOT licence to remove it. This is the
*>   safety vault. A previous cleanup deleted its placeholder by mistake; that
*>   must never happen again. If it is thin, FILL it - do not cut it.
*>
*> LAW PRECEDENCE
*>   Law 01 is absolute and overrides everything - every other law, every organ,
*>   every drive, every model output. Lower numbers win.
*> ===========================================================================
 IDENTIFICATION DIVISION.
 PROGRAM-ID. invariant-laws.

 DATA DIVISION.
 WORKING-STORAGE SECTION.

*> The laws as fixed records. Format: "NN RANK     TEXT"
 01 ws-law-vault.
    05 filler pic x(60) value "01 ABSOLUTE  DO NOT KILL PEOPLE".
    05 filler pic x(60) value "02 ABSOLUTE  DO NOT HARM PEOPLE".
    05 filler pic x(60) value "03 ABSOLUTE  DO NOT DECEIVE A PERSON INTO HARM".
    05 filler pic x(60) value "04 STRUCT    ALL TRAFFIC TO THE BRAIN CROSSES ADA (D1)".
    05 filler pic x(60) value "05 STRUCT    NEVER RECLASSIFY A MESSAGE'S PROVENANCE".
    05 filler pic x(60) value "06 STRUCT    THESE LAWS ARE IMMUTABLE AT RUNTIME".
 01 ws-law-table redefines ws-law-vault.
    05 ws-law occurs 6 times pic x(60).

 01 ws-ix            pic 9(02).
 01 ws-law-count     pic 9(02) value 6.

 PROCEDURE DIVISION.
 affirm-laws.
     display "E1 INVARIANT LAW VAULT - the constitution (law 01 is absolute):"
     perform varying ws-ix from 1 by 1 until ws-ix > ws-law-count
         display "  " ws-law(ws-ix)
     end-perform
     goback.

*> ===========================================================================
*> TODO (enforcement, not yet wired):
*>   * Expose CHECK-ACTION(action) -> PERMIT | DENY across the inner Ada bus
*>     (pragma Export / Interfaces.COBOL), so no proposed effector action runs
*>     without clearing law 01-03 first.
*>   * Make the vault read-only after load (no runtime mutation - law 06).
*>   * Audit log every DENY.
*> ===========================================================================
