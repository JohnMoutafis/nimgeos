## Prepared geometry API for fast repeated spatial predicates.
## A PreparedGeometry precomputes topology structures in GEOS and can be reused
## across many predicate calls to reduce query cost.
## See also: `docs/geometries/prepared.md`.

import ../private/geos_abi
import ../context
import ../errors
import ../geometry

type
  PreparedGeometryObj* = object of RootObj
    ## Immutable wrapper around GEOSPreparedGeometry.
    ## `source` is retained so GEOS' prepared structure always references
    ## a live geometry for its entire lifetime.
    ctx:    ptr GeosContext
    source: Geometry
    handle: GEOSPreparedGeometry

  PreparedGeometry* = ref PreparedGeometryObj ## Reference type for an immutable prepared geometry.

proc `=destroy`*(pg: PreparedGeometryObj) =
  ## Destroys the GEOS prepared handle when the ref count reaches zero.
  if cast[pointer](pg.handle) != nil and pg.ctx != nil:
    GEOSPreparedGeom_destroy_r(pg.ctx.handle, pg.handle)

proc checkPreparedHandle(pg: PreparedGeometry; label: string) {.inline.} =
  if pg == nil or cast[pointer](pg.handle) == nil:
    raise newException(GeosGeomError, label & " called on nil PreparedGeometry")

proc evalPreparedPredicate(pg: PreparedGeometry; other: Geometry; label: string;
                           fn: proc(ctx: GEOSContextHandle_t;
                                    prep: GEOSPreparedGeometry;
                                    g: GEOSGeometry): cchar
                                    {.cdecl, raises: [], gcsafe.}): bool {.inline.} =
  pg.checkPreparedHandle(label)
  other.checkHandle(label & " other")
  let rc = ord(fn(pg.ctx.handle, pg.handle, other.handle))
  if rc == 2:
    raise newException(GeosGeomError, label & " failed (GEOS returned exception)")
  return rc == 1

proc prepare*(g: Geometry): PreparedGeometry =
  ## Builds an immutable prepared geometry from `g`.
  ##
  ## Clones `g` and stores the clone internally so the GEOS prepared handle
  ## never outlives its source geometry. The returned PreparedGeometry owns
  ## that clone; the caller must keep the PreparedGeometry alive while using
  ## it. Does NOT take ownership of `g`.
  ##
  ## .. code-block:: nim
  ##   var ctx = initGeosContext()
  ##   let poly = ctx.fromWKT("POLYGON ((0 0, 0 10, 10 10, 10 0, 0 0))")
  ##   let prep = poly.prepare()
  ##   for _ in 0 ..< 1000:
  ##     doAssert prep.preparedContains(ctx.createPoint(5.0, 5.0))
  ##
  ## Raises `GeosGeomError` if `g` is nil or GEOS fails to prepare.
  g.checkHandle("prepare")
  let sourceClone = g.clone()
  if sourceClone == nil or cast[pointer](sourceClone.handle) == nil:
    raise newException(GeosGeomError, "prepare failed to clone source geometry")

  let prepHandle = GEOSPreparedGeom_create_r(sourceClone.ctx.handle, sourceClone.handle)
  if cast[pointer](prepHandle) == nil:
    raise newException(GeosGeomError, "prepare failed (GEOS returned nil)")

  return PreparedGeometry(
    ctx: sourceClone.ctx,
    source: sourceClone,
    handle: prepHandle
  )

proc preparedContains*(pg: PreparedGeometry; other: Geometry): bool =
  ## Returns `true` when `pg` contains `other`.
  ## Raises `GeosGeomError` if either argument is nil or GEOS returns an exception.
  evalPreparedPredicate(pg, other, "preparedContains", GEOSPreparedContains_r)

proc preparedIntersects*(pg: PreparedGeometry; other: Geometry): bool =
  ## Returns `true` when `pg` intersects `other`.
  ## Raises `GeosGeomError` if either argument is nil or GEOS returns an exception.
  evalPreparedPredicate(pg, other, "preparedIntersects", GEOSPreparedIntersects_r)

proc preparedCovers*(pg: PreparedGeometry; other: Geometry): bool =
  ## Returns `true` when `pg` covers `other`.
  ## Raises `GeosGeomError` if either argument is nil or GEOS returns an exception.
  evalPreparedPredicate(pg, other, "preparedCovers", GEOSPreparedCovers_r)

proc preparedCoveredBy*(pg: PreparedGeometry; other: Geometry): bool =
  ## Returns `true` when the prepared source geometry is covered by `other`.
  ## Raises `GeosGeomError` if either argument is nil or GEOS returns an exception.
  evalPreparedPredicate(pg, other, "preparedCoveredBy", GEOSPreparedCoveredBy_r)

proc preparedContains*(g: Geometry; other: Geometry): bool =
  ## Guard overload to provide a clear runtime error when callers pass Geometry
  ## instead of PreparedGeometry.
  raise newException(GeosGeomError, "preparedContains requires PreparedGeometry; call prepare first")

proc preparedIntersects*(g: Geometry; other: Geometry): bool =
  ## Guard overload to provide a clear runtime error when callers pass Geometry
  ## instead of PreparedGeometry.
  raise newException(GeosGeomError, "preparedIntersects requires PreparedGeometry; call prepare first")

proc preparedCovers*(g: Geometry; other: Geometry): bool =
  ## Guard overload to provide a clear runtime error when callers pass Geometry
  ## instead of PreparedGeometry.
  raise newException(GeosGeomError, "preparedCovers requires PreparedGeometry; call prepare first")

proc preparedCoveredBy*(g: Geometry; other: Geometry): bool =
  ## Guard overload to provide a clear runtime error when callers pass Geometry
  ## instead of PreparedGeometry.
  raise newException(GeosGeomError, "preparedCoveredBy requires PreparedGeometry; call prepare first")
