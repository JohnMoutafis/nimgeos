## LineString geometry type and operations.
## See also: `docs/geometries/linestring.md`.

import ../private/geos_abi
import ../context
import ../errors
import ../geometry
import ./point

type
  LineStringObj* = object of GeometryObj
    ## A LineString geometry — a path defined by a sequence of points.
  LineString* = ref LineStringObj ## Reference type for a LineString geometry.
proc validateCoords[T](ctx: GeosContext; coords: openArray[T]): GEOSCoordSequence =
  ## Shared validation and CoordSequence construction for LineString.
  ## GEOS requires at least 2 points.
  if coords.len < 2:
    raise newException(GeosGeomError, "LineString requires at least 2 coordinates")

  const dim = when compiles(coords[0][2]): 3 else: 2
  let sq = GEOSCoordSeq_create_r(ctx.handle, coords.len.cuint, dim.cuint)
  if cast[pointer](sq) == nil:
    raise newException(GeosGeomError, "Failed to create CoordSequence for LineString")

  for i, point in coords:
    discard GEOSCoordSeq_setX_r(ctx.handle, sq, i.cuint, point[0].cdouble)
    discard GEOSCoordSeq_setY_r(ctx.handle, sq, i.cuint, point[1].cdouble)
    when dim == 3:
      discard GEOSCoordSeq_setZ_r(ctx.handle, sq, i.cuint, point[2].cdouble)
  return sq

proc createLineString*(ctx: var GeosContext; coords: openArray[(float, float)]): LineString =
  ## Create a 2D LineString from an array of (x, y) tuples.
  ## Requires at least 2 coordinates.
  ##
  ## .. code-block:: nim
  ##   var ctx = initGeosContext()
  ##   let ls = ctx.createLineString([(0.0, 0.0), (3.0, 4.0)])
  ##   echo ls.numPoints()   # 2
  ##
  ## Raises `GeosInitError` if `ctx` is destroyed; `GeosGeomError` if fewer
  ## than 2 coordinates or GEOS fails.
  checkContext(ctx, "createLineString")
  let sq = validateCoords(ctx, coords)
  let handle = GEOSGeom_createLineString_r(ctx.handle, sq)
  if cast[pointer](handle) == nil:
    raise newException(GeosGeomError, "Failed to create LineString")
  return LineString(ctx: addr ctx, handle: handle)

proc createLineString*(ctx: var GeosContext; coords: openArray[(float, float, float)]): LineString =
  ## Create a 3D LineString from an array of (x, y, z) tuples.
  ## Requires at least 2 coordinates.
  ## Raises `GeosInitError` if `ctx` is destroyed; `GeosGeomError` if fewer
  ## than 2 coordinates or GEOS fails.
  checkContext(ctx, "createLineString")
  let sq = validateCoords(ctx, coords)
  let handle = GEOSGeom_createLineString_r(ctx.handle, sq)
  if cast[pointer](handle) == nil:
    raise newException(GeosGeomError, "Failed to create 3D LineString")
  return LineString(ctx: addr ctx, handle: handle)

proc numPoints*(ls: LineString): int =
  ## Return the number of points in the LineString.
  ## Raises `GeosGeomError` if the LineString is nil or GEOS fails.
  ls.checkHandle("numPoints")
  GEOSGeomGetNumPoints_r(ls.ctx.handle, ls.handle).int

proc pointN*(ls: LineString; n: int): Point =
  ## Return the point at index `n` (0-based).
  ## Raises `GeosGeomError` if `n` is out of bounds or the LineString is nil.
  ls.checkHandle("pointN")
  if n < 0 or n >= ls.numPoints():
    raise newException(GeosGeomError, "pointN index out of bounds: " & $n)
  # GEOSGeomGetPointN_r returns a new geometry — we own it
  let handle = GEOSGeomGetPointN_r(ls.ctx.handle, ls.handle, n.cint)
  if cast[pointer](handle) == nil:
    raise newException(GeosGeomError, "GEOSGeomGetPointN_r failed at index " & $n)
  return  Point(ctx: ls.ctx, handle: handle)

proc startPoint*(ls: LineString): Point =
  ## Return the first point of the LineString.
  ## Raises `GeosGeomError` if the LineString is nil or GEOS fails.
  ls.checkHandle("startPoint")
  let handle = GEOSGeomGetStartPoint_r(ls.ctx.handle, ls.handle)
  if cast[pointer](handle) == nil:
    raise newException(GeosGeomError, "GEOSGeomGetStartPoint_r failed")
  return Point(ctx: ls.ctx, handle: handle)

proc endPoint*(ls: LineString): Point =
  ## Return the last point of the LineString.
  ## Raises `GeosGeomError` if the LineString is nil or GEOS fails.
  ls.checkHandle("endPoint")
  let handle = GEOSGeomGetEndPoint_r(ls.ctx.handle, ls.handle)
  if cast[pointer](handle) == nil:
    raise newException(GeosGeomError, "GEOSGeomGetEndPoint_r failed")
  return Point(ctx: ls.ctx, handle: handle)

## String representation — returns "LineString(N points)" where N is the point count.
## Raises `NilAccessDefect` if the LineString is nil.
method `$`*(ls: LineString): string =
  if ls == nil or cast[pointer](ls.handle) == nil:
    raise newException(NilAccessDefect, "Cannot convert nil LineString to string")
  return "LineString(" & $ls.numPoints() & " points)"
