## Point geometry type and operations.

import std/math
import ../private/geos_abi
import ../context
import ../errors
import ../geometry

type
  PointObj* = object of GeometryObj
  Point*    = ref PointObj

proc createPoint*(ctx: var GeosContext; x, y: float): Point =
  checkContext(ctx, "createPoint")
  let handle = GEOSGeom_createPointFromXY_r(ctx.handle, x.cdouble, y.cdouble)
  if cast[pointer](handle) == nil:
    raise newException(GeosGeomError, "Failed to create Point")
  return Point(ctx: addr ctx, handle: handle)

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

proc x*(p: Point): float =
  p.checkHandle("x")
  var v: cdouble
  if GEOSGeomGetX_r(p.ctx.handle, p.handle, addr v) == 0:
    raise newException(GeosGeomError, "GEOSGeomGetX_r failed")
  return v.float

proc y*(p: Point): float =
  p.checkHandle("y")
  var v: cdouble
  if GEOSGeomGetY_r(p.ctx.handle, p.handle, addr v) == 0:
    raise newException(GeosGeomError, "GEOSGeomGetY_r failed")
  return v.float

proc z*(p: Point): float =
  ## Returns NaN if the point has no Z coordinate.
  p.checkHandle("z")
  var v: cdouble
  discard GEOSGeomGetZ_r(p.ctx.handle, p.handle, addr v)
  return v.float

method `$`*(p: Point): string =
  if p == nil or cast[pointer](p.handle) == nil: return "<nil Point>"
  elif p.z().isNaN():
    return "Point (" & $p.x() & " " & $p.y() & ")"
  else:
    return "Point (" & $p.x() & " " & $p.y() & " " & $p.z() & ")"
