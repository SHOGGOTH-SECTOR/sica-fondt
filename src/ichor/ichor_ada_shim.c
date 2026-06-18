/* ichor_ada_shim.c
 *
 * The C/Fortran binding seam between Ichor (Pony) and the Ada D1 border
 * (Trust_Boundary.Trust_Guard). Pony's FFI calls `ichor_ada_admit`; this shim
 * is where the call crosses into Ada.
 *
 * Stub: returns admit=true. Replace the body with a call into an Ada export of
 * Trust_Guard.Screen_Inbound (provenance + blocklist + rate), e.g. via a
 * `pragma Export (C, ...)` wrapper on the Ada side.
 *
 * Build into a lib so Pony's `use "lib:ichor_ada"` can link it.
 */
#include <stdbool.h>
#include <stddef.h>

/* provenance codes mirror Ichor's Provenance:
 * 0 system_internal, 1 user_input, 2 organ_secretion, 3 external */
bool ichor_ada_admit(unsigned char provenance,
                     const char *payload,
                     size_t len)
{
    (void)payload;
    (void)len;

    /* TODO: cross into Ada Trust_Guard.Screen_Inbound and return its verdict. */
    if (provenance == 3 /* external */) {
        return false;
    }
    return true;
}
