## Polygon geometry type and operations.

import ../geos_abi
import ../context
import ../errors
import ../geometry
import ./linearring

type
  PolygonObj* = object of GeometryObj
  Polygon*    = ref PolygonObj

proc createPolygon*(ctx: var GeosContext; shell: LinearRing; holes: openArray[LinearRing] = []): Polygon =
  ## Create a Polygon from a shell LinearRing and optional hole LinearRings.
  ## Shell and all holes transfer ownership to the new Polygon.
  ## After creation, the passed-in ring handles are neutralised.
  shell.checkHandle("createPolygon shell")

  if holes.len == 0:
    let handle = GEOSGeom_createPolygon_r(
      ctx.handle, shell.handle, nil, 0.cuint)
    if cast[pointer](handle) == nil:
      raise newException(GeosGeomError, "Failed to create Polygon")
    shell.handle = cast[GEOSGeometry](nil)  # ownership transferred
    return Polygon(ctx: addr ctx, handle: handle)

  # Build a C array of hole handles
  var holeHandles = newSeq[GEOSGeometry](holes.len)
  for i, h in holes:
    h.checkHandle("createPolygon hole[" & $i & "]")
    holeHandles[i] = h.handle

  let handle = GEOSGeom_createPolygon_r(
    ctx.handle, shell.handle,
    addr holeHandles[0], holes.len.cuint)
  if cast[pointer](handle) == nil:
    raise newException(GeosGeomError, "Failed to create Polygon with holes")

  # Neutralise all transferred handles
  shell.handle = cast[GEOSGeometry](nil)
  for h in holes: h.handle = cast[GEOSGeometry](nil)

  return Polygon(ctx: addr ctx, handle: handle)

proc exteriorRing*(p: Polygon): LinearRing =
  ## Return a clone of the exterior ring (shell) of the Polygon.
  ## The caller owns the returned LinearRing.
  p.checkHandle("exteriorRing")
  let borrowed = GEOSGetExteriorRing_r(p.ctx.handle, p.handle)
  if cast[pointer](borrowed) == nil:
    raise newException(GeosGeomError, "GEOSGetExteriorRing_r failed")
  return LinearRing(ctx: p.ctx, handle: GEOSGeom_clone_r(p.ctx.handle, borrowed))

proc numInteriorRings*(p: Polygon): int =
  ## Return the number of interior rings (holes) in the Polygon.
  p.checkHandle("numInteriorRings")
  return GEOSGetNumInteriorRings_r(p.ctx.handle, p.handle).int

proc interiorRingN*(p: Polygon; n: int): LinearRing =
  ## Return a clone of the interior ring at index `n` (0-based).
  ## Raises `GeosGeomError` if `n` is out of bounds.
  ## The caller owns the returned LinearRing.
  p.checkHandle("interiorRingN")
  if n < 0 or n >= p.numInteriorRings():
    raise newException(GeosGeomError, "interiorRingN index out of bounds: " & $n)
  let borrowed = GEOSGetInteriorRingN_r(p.ctx.handle, p.handle, n.cint)
  if cast[pointer](borrowed) == nil:
    raise newException(GeosGeomError, "GEOSGetInteriorRingN_r failed at index " & $n)
  return LinearRing(ctx: p.ctx, handle: GEOSGeom_clone_r(p.ctx.handle, borrowed))

method `$`*(p: Polygon): string =
  ## String representation showing the number of interior rings (holes).
  if p == nil or cast[pointer](p.handle) == nil: return "<nil Polygon>"
  return "Polygon(" & $p.numInteriorRings() & " holes)"
