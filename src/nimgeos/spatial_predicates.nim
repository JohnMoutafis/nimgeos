## Spatial predicates — binary topology relationships between two Geometries.
## All predicates follow the DE-9IM model (https://en.wikipedia.org/wiki/DE-9IM).
## GEOS _r functions return: 1 = true, 0 = false, 2 = exception.

import ./private/geos_abi
import ./errors
import ./geometry

# ── Internal helper ──────────────────────────────────────────────────────────

proc evalPredicate(g, other: Geometry; label: string;
                   fn: proc(ctx: GEOSContextHandle_t;
                            a, b: GEOSGeometry): cchar
                            {.cdecl, raises: [], gcsafe.}): bool {.inline.} =
  g.checkHandle(label & " g")
  other.checkHandle(label & " other")
  let rc = ord(fn(g.ctx.handle, g.handle, other.handle))
  if rc == 2:
    raise newException(GeosGeomError, label & " failed (GEOS returned exception)")
  return rc == 1

# ── Public API ───────────────────────────────────────────────────────────────

proc equals*(g, other: Geometry): bool =
  evalPredicate(g, other, "equals", GEOSEquals_r)

proc intersects*(g, other: Geometry): bool =
  evalPredicate(g, other, "intersects", GEOSIntersects_r)

proc contains*(g, other: Geometry): bool =
  evalPredicate(g, other, "contains", GEOSContains_r)

proc touches*(g, other: Geometry): bool =
  evalPredicate(g, other, "touches", GEOSTouches_r)

proc within*(g, other: Geometry): bool =
  evalPredicate(g, other, "within", GEOSWithin_r)

proc disjoint*(g, other: Geometry): bool =
  evalPredicate(g, other, "disjoint", GEOSDisjoint_r)

proc crosses*(g, other: Geometry): bool =
  evalPredicate(g, other, "crosses", GEOSCrosses_r)

proc overlaps*(g, other: Geometry): bool =
  evalPredicate(g, other, "overlaps", GEOSOverlaps_r)
