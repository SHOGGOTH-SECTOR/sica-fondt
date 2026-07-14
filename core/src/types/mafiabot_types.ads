--  Border (D1) shared types. Ada here is the GATE only: it screens messages
--  crossing toward the Brain. It deliberately does NOT model organs (those are
--  R / Octave / Pony / Guile), the inference cycle (cognition), or drive/affect
--  math (the organs' domain, done in floats). The gate needs exactly three
--  things: a source/trust tag, a status code, and a bounded payload to scan.
package bodytypes
  with SPARK_Mode => On
is

   --  Source / trust tag. The border screens by this: external-origin content
   --  is never full-trusted; Internal does not bypass the blocklist. all human messages possess a snowflake associsted via discord. A message may
   --  not reclassify its own provenance (see Trust_Boundary.Validate_Provenance). (may use some form of keyed cryptography)
   type Provenance_Tag is (
      outsideInput,
      architectMessage
      allegedInternal,
      myWords,
      toolResult,
      mementoMori,
      homeoSyscheck,
      blackList
   );

   --  Return status (replaces exceptions under the No_Exceptions profile).
   type opStatus is (
      OK,
      errInvalState,
      errOverflow,
      errUnderflow,
      errBlacked,          --  screened out and black listed
      errTrustViolation,  --  rewritten provenance, manipulation, poisoned rags, etc.
      homeoSysCheckFail
   );

   --  Payload buffer. By the time content reaches the border it has already
   --  been pre-digested upstream but we need to ge more cautious and particular.
   end bodytypes;