## Shared base operations for geometry dispatch and multi-geometry iteration.
## - `geomN` — retrieve the nth sub-geometry of any multi-geometry or collection.
## - Iterators for `MultiPoint`, `MultiLineString`, `MultiPolygon`, `GeometryCollection`.
##
## This module breaks the circular-import chain that previously forced `geomN`
## to live in `factories.nim`.

import ./private/geos_abi
import ./context
import ./errors
import ./geometry
import ./geometries/point
import ./geometries/linestring
import ./geometries/polygon
import ./geometries/multi
import ./geometries/factories

# ── Sub-geometry accessor ─────────────────────────────────────────────────────

proc geomN*(g: Geometry; n: int): Geometry =
  ## Returns a clone of the nth sub-geometry as a concrete-typed Geometry.
  ## Works on any multi-geometry or collection.
  ##
  ## .. code-block:: nim
  ##   var ctx = initGeosContext()
  ##   let mp = ctx.fromWKT("MULTIPOINT ((0 0), (1 1), (2 2))")
  ##   let sub = mp.geomN(1)   # → Point (1 1)
  ##   echo sub.toWKT()
  g.checkHandle("geomN")
  let count = g.numGeometries()
  if n < 0 or n >= count:
    raise newException(GeosGeomError,
      "geomN index out of bounds: " & $n & " (size=" & $count & ")")

  # GEOSGetGeometryN_r does NOT transfer ownership — clone before wrapping
  let borrowed = GEOSGetGeometryN_r(g.ctx.handle, g.handle, n.cint)
  if cast[pointer](borrowed) == nil:
    raise newException(GeosGeomError,
      "GEOSGetGeometryN_r failed at index " & $n)

  let cloned = GEOSGeom_clone_r(g.ctx.handle, borrowed)
  if cast[pointer](cloned) == nil:
    raise newException(GeosGeomError,
      "GEOSGeom_clone_r failed at index " & $n)

  return geomFromHandle(g.ctx, cloned)

# ── Internal iterator helper ──────────────────────────────────────────────────

proc borrowAndClone(ctx: ptr GeosContext; parent: GEOSGeometry;
                    i: int): GEOSGeometry {.inline.} =
  ## Borrow the i-th sub-geometry from `parent`, clone it, and return the
  ## cloned handle.  Raises `GeosGeomError` on nil from either GEOS call.
  let borrowed = GEOSGetGeometryN_r(ctx.handle, parent, i.cint)
  if cast[pointer](borrowed) == nil:
    raise newException(GeosGeomError,
      "GEOSGetGeometryN_r failed at index " & $i)
  let cloned = GEOSGeom_clone_r(ctx.handle, borrowed)
  if cast[pointer](cloned) == nil:
    raise newException(GeosGeomError,
      "GEOSGeom_clone_r failed at index " & $i)
  return cloned

# ── Multi-geometry iterators ──────────────────────────────────────────────────

iterator items*(g: MultiPoint): Point =
  ## Iterate over all points in a MultiPoint.
  ##
  ## .. code-block:: nim
  ##   for pt in multiPoint:
  ##     echo pt.x(), " ", pt.y()
  g.checkHandle("items(MultiPoint)")
  let n = g.numGeometries()
  for i in 0 ..< n:
    let cloned = borrowAndClone(g.ctx, g.handle, i)
    yield Point(ctx: g.ctx, handle: cloned)

iterator items*(g: MultiLineString): LineString =
  ## Iterate over all line strings in a MultiLineString.
  ##
  ## .. code-block:: nim
  ##   for ls in multiLineString:
  ##     echo ls.numPoints(), " points"
  g.checkHandle("items(MultiLineString)")
  let n = g.numGeometries()
  for i in 0 ..< n:
    let cloned = borrowAndClone(g.ctx, g.handle, i)
    yield LineString(ctx: g.ctx, handle: cloned)

iterator items*(g: MultiPolygon): Polygon =
  ## Iterate over all polygons in a MultiPolygon.
  ##
  ## .. code-block:: nim
  ##   for poly in multiPolygon:
  ##     echo poly.area()
  g.checkHandle("items(MultiPolygon)")
  let n = g.numGeometries()
  for i in 0 ..< n:
    let cloned = borrowAndClone(g.ctx, g.handle, i)
    yield Polygon(ctx: g.ctx, handle: cloned)

iterator items*(g: GeometryCollection): Geometry =
  ## Iterate over all geometries in a GeometryCollection.
  ## Each yielded value is a concrete subtype (Point, LineString, etc.).
  ##
  ## .. code-block:: nim
  ##   for geom in geometryCollection:
  ##     echo geom.type()
  g.checkHandle("items(GeometryCollection)")
  let n = g.numGeometries()
  for i in 0 ..< n:
    let cloned = borrowAndClone(g.ctx, g.handle, i)
    yield geomFromHandle(g.ctx, cloned)
