## Spatial predicates — binary topology relationships between two Geometries.
## All predicates follow the DE-9IM model (https://en.wikipedia.org/wiki/DE-9IM).
## GEOS _r functions return: 1 = true, 0 = false, 2 = exception.
## See also: `docs/operations/predicates.md`.

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

  
## Returns `true` if `g` is spatially equal to `other` (same point set).
## Based on the DE-9IM model.
##
## Raises `GeosGeomError` if `g` or `other` is nil or GEOS returns an exception.
proc equals*(g, other: Geometry): bool =
  return evalPredicate(g, other, "equals", GEOSEquals_r)
  
## Returns `true` if `g` and `other` share any point in space.
## Based on the DE-9IM model.
##
## .. code-block:: nim
##   var ctx = initGeosContext()
##   let a = ctx.fromWKT("LINESTRING (0 0, 2 2)")
##   let b = ctx.fromWKT("LINESTRING (0 2, 2 0)")
##   echo a.intersects(b)   # true
##
## Raises `GeosGeomError` if `g` or `other` is nil or GEOS returns an exception.
proc intersects*(g, other: Geometry): bool =
  return evalPredicate(g, other, "intersects", GEOSIntersects_r)
  
## Returns `true` if `other` lies entirely within `g`.
## Based on the DE-9IM model.
##
## Raises `GeosGeomError` if `g` or `other` is nil or GEOS returns an exception.
proc contains*(g, other: Geometry): bool =
  return evalPredicate(g, other, "contains", GEOSContains_r)
  
## Returns `true` if `g` and `other` touch at their boundaries but do not
## intersect in their interiors. Based on the DE-9IM model.
##
## Raises `GeosGeomError` if `g` or `other` is nil or GEOS returns an exception.
proc touches*(g, other: Geometry): bool =
  return evalPredicate(g, other, "touches", GEOSTouches_r)
  
## Returns `true` if `g` lies entirely within `other` (the inverse of `contains`).
## Based on the DE-9IM model.
##
## Raises `GeosGeomError` if `g` or `other` is nil or GEOS returns an exception.
proc within*(g, other: Geometry): bool =
  return evalPredicate(g, other, "within", GEOSWithin_r)
  
## Returns `true` if `g` and `other` share no points in common.
## Based on the DE-9IM model.
##
## Raises `GeosGeomError` if `g` or `other` is nil or GEOS returns an exception.
proc disjoint*(g, other: Geometry): bool =
  return evalPredicate(g, other, "disjoint", GEOSDisjoint_r)
  
## Returns `true` if `g` and `other` intersect at interior points but not all
## of one is contained in the other. Based on the DE-9IM model.
##
## Raises `GeosGeomError` if `g` or `other` is nil or GEOS returns an exception.
proc crosses*(g, other: Geometry): bool =
  return evalPredicate(g, other, "crosses", GEOSCrosses_r)
  
## Returns `true` if `g` and `other` share interior points but neither
## contains the other. Based on the DE-9IM model.
##
## Raises `GeosGeomError` if `g` or `other` is nil or GEOS returns an exception.
proc overlaps*(g, other: Geometry): bool =
  return evalPredicate(g, other, "overlaps", GEOSOverlaps_r)
