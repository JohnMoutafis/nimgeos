## Spatial operations — produce new Geometry instances from existing ones.
## All operations return concrete-typed Geometry refs via factories/geomFromHandle.
## See also: `docs/operations/spatial-operations.md`.

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

proc evalUnaryTolOp(g: Geometry; tol: float; label: string;
                    fn: proc(ctx: GEOSContextHandle_t;
                             a: GEOSGeometry;
                             tolerance: cdouble): GEOSGeometry
                             {.cdecl, raises: [], gcsafe.}): Geometry {.inline.} =
  ## Helper for unary tolerance operations (simplify variants).
  g.checkHandle(label)
  let handle = fn(g.ctx.handle, g.handle, tol.cdouble)
  if cast[pointer](handle) == nil:
    raise newException(GeosGeomError, label & " failed (GEOS returned nil)")
  return geomFromHandle(g.ctx, handle)

proc evalBinaryTolOp(g, other: Geometry; tol: float; label: string;
                     fn: proc(ctx: GEOSContextHandle_t;
                              a, b: GEOSGeometry;
                              tolerance: cdouble): GEOSGeometry
                              {.cdecl, raises: [], gcsafe.}): Geometry {.inline.} =
  ## Helper for binary tolerance operations (snap).
  g.checkHandle(label & " g")
  other.checkHandle(label & " other")
  let handle = fn(g.ctx.handle, g.handle, other.handle, tol.cdouble)
  if cast[pointer](handle) == nil:
    raise newException(GeosGeomError, label & " failed (GEOS returned nil)")
  return geomFromHandle(g.ctx, handle)

# ── Binary operations ─────────────────────────────────────────────────────────

proc intersection*(g, other: Geometry): Geometry =
  ## Returns the geometry shared by both inputs.
  ##
  ## .. code-block:: nim
  ##   var ctx = initGeosContext()
  ##   let a = ctx.fromWKT("POLYGON ((0 0, 0 10, 10 10, 10 0, 0 0))")
  ##   let b = ctx.fromWKT("POLYGON ((5 5, 5 15, 15 15, 15 5, 5 5))")
  ##   echo a.intersection(b).area()   # 25.0
  ##
  ## Raises `GeosGeomError` if either argument is nil or GEOS fails.
  evalBinaryOp(g, other, "intersection", GEOSIntersection_r)

proc union*(g, other: Geometry): Geometry =
  ## Returns the geometry covered by either input.
  ## Raises `GeosGeomError` if either argument is nil or GEOS fails.
  evalBinaryOp(g, other, "union", GEOSUnion_r)

proc difference*(g, other: Geometry): Geometry =
  ## Returns the part of `g` that does not intersect `other`.
  ## Raises `GeosGeomError` if either argument is nil or GEOS fails.
  evalBinaryOp(g, other, "difference", GEOSDifference_r)

proc symmetricDifference*(g, other: Geometry): Geometry =
  ## Returns the geometry covered by exactly one input (exclusive-or).
  ## Raises `GeosGeomError` if either argument is nil or GEOS fails.
  evalBinaryOp(g, other, "symmetricDifference", GEOSSymmetricDifference_r)

proc snap*(g, other: Geometry; tol: float): Geometry =
  ## Snaps `g` vertices/segments toward `other` where within tolerance `tol`.
  ## Raises `GeosGeomError` if either argument is nil or GEOS fails.
  evalBinaryTolOp(g, other, tol, "snap", GEOSSnap_r)

# ── Unary operations ──────────────────────────────────────────────────────────

proc buffer*(g: Geometry; width: float; quadsegs: int = 8): Geometry =
  ## Returns a geometry expanded (or shrunk if negative) by `width`.
  ## `quadsegs` controls arc approximation quality (default 8, matching GEOS default).
  ##
  ## .. code-block:: nim
  ##   var ctx = initGeosContext()
  ##   let p = ctx.createPoint(0.0, 0.0)
  ##   echo p.buffer(10.0).area()   # ≈ 312.14 (polygon approx. of π·10² = 314.16)
  ##
  ## Raises `GeosGeomError` if `g` is nil or GEOS fails.
  g.checkHandle("buffer")
  let handle = GEOSBuffer_r(g.ctx.handle, g.handle, width.cdouble, quadsegs.cint)
  if cast[pointer](handle) == nil:
    raise newException(GeosGeomError, "buffer failed (GEOS returned nil)")
  return geomFromHandle(g.ctx, handle)

proc convexHull*(g: Geometry): Geometry =
  ## Returns the smallest convex polygon that contains the geometry.
  ## Raises `GeosGeomError` if `g` is nil or GEOS fails.
  evalUnaryOp(g, "convexHull", GEOSConvexHull_r)

proc envelope*(g: Geometry): Geometry =
  ## Returns the bounding box of the geometry as a Polygon (or Point/Line for degenerate cases).
  ## Raises `GeosGeomError` if `g` is nil or GEOS fails.
  evalUnaryOp(g, "envelope", GEOSEnvelope_r)

proc centroid*(g: Geometry): Geometry =
  ## Returns the geometric centre of the geometry as a Point.
  ## Raises `GeosGeomError` if `g` is nil or GEOS fails.
  evalUnaryOp(g, "centroid", GEOSGetCentroid_r)

proc simplify*(g: Geometry; tol: float): Geometry =
  ## Simplifies the geometry using the Douglas-Peucker tolerance `tol`.
  ## Higher tolerance removes more detail but may alter topology.
  ## Raises `GeosGeomError` if `g` is nil or GEOS fails.
  evalUnaryTolOp(g, tol, "simplify", GEOSSimplify_r)

proc topologyPreserveSimplify*(g: Geometry; tol: float): Geometry =
  ## Simplifies the geometry while preserving topology, using tolerance `tol`.
  ## Useful for polygons where validity must be retained.
  ## Raises `GeosGeomError` if `g` is nil or GEOS fails.
  evalUnaryTolOp(g, tol, "topologyPreserveSimplify", GEOSTopologyPreserveSimplify_r)

proc unaryUnion*(g: Geometry): Geometry =
  ## Computes a union over all components of a collection geometry.
  ## For non-collections, GEOS returns an equivalent normalized geometry.
  ## Raises `GeosGeomError` if `g` is nil or GEOS fails.
  evalUnaryOp(g, "unaryUnion", GEOSUnaryUnion_r)

proc boundary*(g: Geometry): Geometry =
  ## Returns the topological boundary of a geometry.
  ## For points, boundary is empty; for polygons, boundary is ring(s).
  ## Raises `GeosGeomError` if `g` is nil or GEOS fails.
  evalUnaryOp(g, "boundary", GEOSBoundary_r)

