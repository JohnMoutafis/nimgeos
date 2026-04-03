## Factory procs: wrap raw GEOSGeometry handles in the correct concrete type.

import ../private/geos_abi
import ../context
import ../errors
import ../geometry
import ./point
import ./linestring
import ./linearring
import ./polygon
import ./multi


# ── Concrete geometry from Geometry factory ───────────────────────────────────

proc geomFromHandle*(ctx: ptr GeosContext; handle: GEOSGeometry): Geometry =
  ## Wraps a raw GEOSGeometry handle in the correct concrete Geometry subtype.
  ## The caller must NOT destroy `handle` afterwards — ownership transfers here.
  if cast[pointer](handle) == nil:
    raise newException(GeosGeomError, "geomFromHandle received nil handle")

  let id = GEOSGeomTypeId_r(ctx.handle, handle)
  return case GeomType(id):
    of gtPoint:              Point(ctx: ctx, handle: handle)
    of gtLineString:         LineString(ctx: ctx, handle: handle)
    of gtLinearRing:         LinearRing(ctx: ctx, handle: handle)
    of gtPolygon:            Polygon(ctx: ctx, handle: handle)
    of gtMultiPoint:         MultiPoint(ctx: ctx, handle: handle)
    of gtMultiLineString:    MultiLineString(ctx: ctx, handle: handle)
    of gtMultiPolygon:       MultiPolygon(ctx: ctx, handle: handle)
    of gtGeometryCollection: GeometryCollection(ctx: ctx, handle: handle)

# ── Sub-geometry accessor ─────────────────────────────────────────────────────

## TODO: This is here to avoid circular imports with geometries/multi.
##       Maybe find a better solution in later versions.
proc geomN*(g: Geometry; n: int): Geometry =
  ## Returns a clone of the nth sub-geometry as a concrete-typed Geometry.
  ## Works on any multi-geometry or collection.
  g.checkHandle("geomN")
  let count = g.numGeometries()
  if n < 0 or n >= count:
    raise newException(GeosGeomError, "geomN index out of bounds: " & $n & " (size=" & $count & ")")

  # GEOSGetGeometryN_r does NOT transfer ownership — clone before wrapping
  let borrowed = GEOSGetGeometryN_r(g.ctx.handle, g.handle, n.cint)
  if cast[pointer](borrowed) == nil:
    raise newException(GeosGeomError, "GEOSGetGeometryN_r failed at index " & $n)

  let cloned = GEOSGeom_clone_r(g.ctx.handle, borrowed)
  if cast[pointer](cloned) == nil:
    raise newException(GeosGeomError, "GEOSGeom_clone_r failed at index " & $n)

  return geomFromHandle(g.ctx, cloned)
