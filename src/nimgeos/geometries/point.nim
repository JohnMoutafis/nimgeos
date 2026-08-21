## Point geometry type and operations.
## See also: `docs/geometries/point.md`.

import std/math
import ../private/geos_abi
import ../context
import ../errors
import ../geometry

type
  PointObj* = object of GeometryObj
    ## A 2D or 3D Point geometry. Holds a single coordinate with optional Z.
  Point* = ref PointObj ## Reference type for a Point geometry.

## Create a 2D Point from `x` and `y` coordinates.
##
## .. code-block:: nim
##   var ctx = initGeosContext()
##   let p = ctx.createPoint(1.0, 2.0)
##   echo p   # Point (1.0 2.0)
##
## Raises `GeosInitError` if `ctx` is destroyed; `GeosGeomError` if GEOS fails.
proc createPoint*(ctx: var GeosContext; x, y: float): Point =
  checkContext(ctx, "createPoint")
  let handle = GEOSGeom_createPointFromXY_r(ctx.handle, x.cdouble, y.cdouble)
  if cast[pointer](handle) == nil:
    raise newException(GeosGeomError, "Failed to create Point")
  return Point(ctx: addr ctx, handle: handle)

## Create a 3D Point from `x`, `y`, and `z` coordinates.
## Raises `GeosInitError` if `ctx` is destroyed; `GeosGeomError` if GEOS fails.
proc createPoint*(ctx: var GeosContext; x, y, z: float): Point =
  checkContext(ctx, "createPoint")
  let sq = GEOSCoordSeq_create_r(ctx.handle, 1.cuint, 3.cuint)
  if cast[pointer](sq) == nil:
    raise newException(GeosGeomError, "Failed to create CoordSequence for Point")
  # sq ownership transfers to GEOSGeom_createPoint_r — do NOT destroy sq after
  discard GEOSCoordSeq_setX_r(ctx.handle, sq, 0.cuint, x.cdouble)
  discard GEOSCoordSeq_setY_r(ctx.handle, sq, 0.cuint, y.cdouble)
  discard GEOSCoordSeq_setZ_r(ctx.handle, sq, 0.cuint, z.cdouble)
  let handle = GEOSGeom_createPoint_r(ctx.handle, sq)
  if cast[pointer](handle) == nil:
    raise newException(GeosGeomError, "Failed to create 3D Point")
  return Point(ctx: addr ctx, handle: handle)

## Returns the X coordinate of the Point.
## Raises `GeosGeomError` if the point is nil or GEOS fails.
proc x*(p: Point): float =
  p.checkHandle("x")
  var v: cdouble
  if GEOSGeomGetX_r(p.ctx.handle, p.handle, addr v) == 0:
    raise newException(GeosGeomError, "GEOSGeomGetX_r failed")
  return v.float

## Returns the Y coordinate of the Point.
## Raises `GeosGeomError` if the point is nil or GEOS fails.
proc y*(p: Point): float =
  p.checkHandle("y")
  var v: cdouble
  if GEOSGeomGetY_r(p.ctx.handle, p.handle, addr v) == 0:
    raise newException(GeosGeomError, "GEOSGeomGetY_r failed")
  return v.float

proc z*(p: Point): float =
  ## Returns the Z coordinate of the Point, or NaN if the point is 2D.
  ## Raises `GeosGeomError` if the point is nil or GEOS fails.
  p.checkHandle("z")
  var v: cdouble
  discard GEOSGeomGetZ_r(p.ctx.handle, p.handle, addr v)
  return v.float

method `$`*(p: Point): string =
  ## String representation — "Point (x y)" or "Point (x y z)" for 3D.
  ## Raises `NilAccessDefect` if the Point is nil.
  if p == nil or cast[pointer](p.handle) == nil:
    raise newException(NilAccessDefect, "Cannot convert nil Point to string")
  if p.z().isNaN():
    return "Point (" & $p.x() & " " & $p.y() & ")"
  else:
    return "Point (" & $p.x() & " " & $p.y() & " " & $p.z() & ")"
