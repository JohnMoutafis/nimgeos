## Factory procs: wrap raw GEOSGeometry handles in the correct concrete type.
## This module is an internal helper — not re-exported in the public API.

import ../private/geos_abi
import ../context
import ../errors
import ../geometry
import ./point
import ./linestring
import ./linearring
import ./polygon
import ./multi


# ── Concrete geometry from handle factory ─────────────────────────────────────

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
