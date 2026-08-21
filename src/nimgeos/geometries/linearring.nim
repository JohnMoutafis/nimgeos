## LinearRing geometry type and operations.
## LinearRing is a closed LineString.
## - Used as Polygon shell and holes.
## - Not typically created directly by end users.
## See also: `docs/geometries/linearring.md`.

import ../private/geos_abi
import ../context
import ../errors
import ../geometry

type
  LinearRingObj* = object of GeometryObj
    ## A LinearRing geometry — a closed ring used for Polygon boundaries.
  LinearRing* = ref LinearRingObj ## Reference type for a LinearRing geometry.

proc validateRingCoords[T](ctx: GeosContext; coords: openArray[T]): GEOSCoordSequence =
  ## Shared validation and CoordSequence construction for LinearRing.
  ## coords must form a closed ring: first and last point must be equal.
  ## GEOS requires at least 4 points (3 unique + closing point).
  if coords.len < 4:
    raise newException(GeosGeomError, "LinearRing requires at least 4 coordinates (closed)")

  const dim = when compiles(coords[0][2]): 3 else: 2

  let sq = GEOSCoordSeq_create_r(ctx.handle, coords.len.cuint, dim.cuint)
  if cast[pointer](sq) == nil:
    raise newException(GeosGeomError, "Failed to create CoordSequence for LinearRing")

  for i, point in coords:
    discard GEOSCoordSeq_setX_r(ctx.handle, sq, i.cuint, point[0].cdouble)
    discard GEOSCoordSeq_setY_r(ctx.handle, sq, i.cuint, point[1].cdouble)
    when dim == 3:
      discard GEOSCoordSeq_setZ_r(ctx.handle, sq, i.cuint, point[2].cdouble)
  return sq

proc createLinearRing*(ctx: var GeosContext; coords: openArray[(float, float)]): LinearRing =
  ## Create a 2D LinearRing from an array of (x, y) tuples.
  ## coords must form a closed ring: first and last point must be equal.
  ## GEOS requires at least 4 points (3 unique + closing point).
  ## Raises `GeosInitError` if `ctx` is destroyed; `GeosGeomError` if the
  ## ring is not closed or GEOS fails.
  checkContext(ctx, "createLinearRing")
  let sq = validateRingCoords(ctx, coords)
  let handle = GEOSGeom_createLinearRing_r(ctx.handle, sq)
  if cast[pointer](handle) == nil:
    raise newException(GeosGeomError, "Failed to create LinearRing — check coords form a closed ring")
  return LinearRing(ctx: addr ctx, handle: handle)

proc createLinearRing*(ctx: var GeosContext; coords: openArray[(float, float, float)]): LinearRing =
  ## Create a 3D LinearRing from an array of (x, y, z) tuples.
  ## coords must form a closed ring: first and last point must be equal.
  ## GEOS requires at least 4 points (3 unique + closing point).
  ## Raises `GeosInitError` if `ctx` is destroyed; `GeosGeomError` if the
  ## ring is not closed or GEOS fails.
  checkContext(ctx, "createLinearRing")
  let sq = validateRingCoords(ctx, coords)
  let handle = GEOSGeom_createLinearRing_r(ctx.handle, sq)
  if cast[pointer](handle) == nil:
    raise newException(GeosGeomError, "Failed to create 3D LinearRing — check coords form a closed ring")
  return LinearRing(ctx: addr ctx, handle: handle)

## String representation — returns "LinearRing(N coords)" where N is the coordinate count.
## Raises `NilAccessDefect` if the LinearRing is nil.
method `$`*(lr: LinearRing): string =
  if lr == nil or cast[pointer](lr.handle) == nil:
    raise newException(NilAccessDefect, "Cannot convert nil LinearRing to string")
  return "LinearRing(" & $lr.numCoordinates() & " coords)"
