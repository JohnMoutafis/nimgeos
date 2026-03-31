## Multi-geometry types and operations.
## All four multi-types share the same sub-geometry accessor pattern

import ../geos_abi
import ../context
import ../errors
import ../geometry

# ── Type declarations ─────────────────────────────────────────────────────────
type
  MultiPointObj*           = object of GeometryObj
  MultiPoint*              = ref MultiPointObj

  MultiLineStringObj*      = object of GeometryObj
  MultiLineString*         = ref MultiLineStringObj

  MultiPolygonObj*         = object of GeometryObj
  MultiPolygon*            = ref MultiPolygonObj

  GeometryCollectionObj*   = object of GeometryObj
  GeometryCollection*      = ref GeometryCollectionObj

# ── Shared sub-geometry accessor ──────────────────────────────────────────────
proc geomN*(g: Geometry; n: int): Geometry =
  ## Returns the nth sub-geometry as a cloned base Geometry.
  ## Works on any multi-geometry or collection.
  g.checkHandle("geomN")
  let count = g.numGeometries()
  if n < 0 or n >= count:
    raise newException(GeosGeomError, "geomN index out of bounds: " & $n)

  let borrowed = GEOSGetGeometryN_r(g.ctx.handle, g.handle, n.cint)
  if cast[pointer](borrowed) == nil:
    raise newException(GeosGeomError, "GEOSGetGeometryN_r failed at index " & $n)
  return wrapHandle(g.ctx, GEOSGeom_clone_r(g.ctx.handle, borrowed))

# ── String representations ────────────────────────────────────────────────────
method `$`*(g: MultiPoint): string =
  if g == nil or cast[pointer](g.handle) == nil: return "<nil MultiPoint>"
  return "MultiPoint(" & $g.numGeometries() & " points)"

method `$`*(g: MultiLineString): string =
  if g == nil or cast[pointer](g.handle) == nil: return "<nil MultiLineString>"
  return "MultiLineString(" & $g.numGeometries() & " linestrings)"

method `$`*(g: MultiPolygon): string =
  if g == nil or cast[pointer](g.handle) == nil: return "<nil MultiPolygon>"
  return "MultiPolygon(" & $g.numGeometries() & " polygons)"

method `$`*(g: GeometryCollection): string =
  if g == nil or cast[pointer](g.handle) == nil: return "<nil GeometryCollection>"
  return "GeometryCollection(" & $g.numGeometries() & " geometries)"
