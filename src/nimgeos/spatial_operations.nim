## Spatial operations — produce new Geometry instances from existing ones.
## All operations return concrete-typed Geometry refs via factories/geomFromHandle.

import ./private/geos_abi
import ./errors
import ./geometry
import ./geometries/factories

# ── Internal helpers ──────────────────────────────────────────────────────────

proc evalBinaryOp(g, other: Geometry; label: string;
                  fn: proc(ctx: GEOSContextHandle_t;
                           a, b: GEOSGeometry): GEOSGeometry
                           {.cdecl, raises: [], gcsafe.}): Geometry {.inline.} =
  ## Helper for binary operations (intersection, union, difference).
  ## Validates both inputs, calls GEOS, wraps result via geomFromHandle.
  g.checkHandle(label & " g")
  other.checkHandle(label & " other")
  let handle = fn(g.ctx.handle, g.handle, other.handle)
  if cast[pointer](handle) == nil:
    raise newException(GeosGeomError, label & " failed (GEOS returned nil)")
  return geomFromHandle(g.ctx, handle)

proc evalUnaryOp(g: Geometry; label: string;
                 fn: proc(ctx: GEOSContextHandle_t;
                          a: GEOSGeometry): GEOSGeometry
                          {.cdecl, raises: [], gcsafe.}): Geometry {.inline.} =
  ## Helper for unary operations (convexHull, envelope, centroid).
  ## Validates input, calls GEOS, wraps result via geomFromHandle.
  g.checkHandle(label)
  let handle = fn(g.ctx.handle, g.handle)
  if cast[pointer](handle) == nil:
    raise newException(GeosGeomError, label & " failed (GEOS returned nil)")
  return geomFromHandle(g.ctx, handle)

# ── Binary operations ─────────────────────────────────────────────────────────

proc intersection*(g, other: Geometry): Geometry =
  ## Returns the geometry shared by both inputs.
  evalBinaryOp(g, other, "intersection", GEOSIntersection_r)

proc union*(g, other: Geometry): Geometry =
  ## Returns the geometry covered by either input.
  evalBinaryOp(g, other, "union", GEOSUnion_r)

proc difference*(g, other: Geometry): Geometry =
  ## Returns the part of g that does not intersect other.
  evalBinaryOp(g, other, "difference", GEOSDifference_r)

# ── Unary operations ──────────────────────────────────────────────────────────

proc buffer*(g: Geometry; width: float; quadsegs: int = 8): Geometry =
  ## Returns a geometry expanded (or shrunk if negative) by the given width.
  ## quadsegs controls arc approximation quality (default 8, matching GEOS default).
  g.checkHandle("buffer")
  let handle = GEOSBuffer_r(g.ctx.handle, g.handle, width.cdouble, quadsegs.cint)
  if cast[pointer](handle) == nil:
    raise newException(GeosGeomError, "buffer failed (GEOS returned nil)")
  return geomFromHandle(g.ctx, handle)

proc convexHull*(g: Geometry): Geometry =
  ## Returns the smallest convex polygon that contains the geometry.
  evalUnaryOp(g, "convexHull", GEOSConvexHull_r)

proc envelope*(g: Geometry): Geometry =
  ## Returns the bounding box of the geometry as a Polygon (or Point/Line for degenerate cases).
  evalUnaryOp(g, "envelope", GEOSEnvelope_r)

proc centroid*(g: Geometry): Geometry =
  ## Returns the geometric centre of the geometry as a Point.
  evalUnaryOp(g, "centroid", GEOSGetCentroid_r)
