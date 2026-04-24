## Prepared geometry API for fast repeated spatial predicates.
## A PreparedGeometry precomputes topology structures in GEOS and can be reused
## across many predicate calls to reduce query cost.

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

  PreparedGeometry* = ref PreparedGeometryObj

proc `=destroy`*(pg: PreparedGeometryObj) =
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

proc toPreparedGeometry*(g: Geometry): PreparedGeometry =
  ## Builds an immutable prepared geometry from `g`.
  ##
  ## The implementation clones `g` and stores it internally so the GEOS prepared
  ## handle never outlives its source geometry.
  g.checkHandle("toPreparedGeometry")
  let sourceClone = g.clone()
  if sourceClone == nil or cast[pointer](sourceClone.handle) == nil:
    raise newException(GeosGeomError, "toPreparedGeometry failed to clone source geometry")

  let prepHandle = GEOSPreparedGeom_create_r(sourceClone.ctx.handle, sourceClone.handle)
  if cast[pointer](prepHandle) == nil:
    raise newException(GeosGeomError, "toPreparedGeometry failed (GEOS returned nil)")

  return PreparedGeometry(
    ctx: sourceClone.ctx,
    source: sourceClone,
    handle: prepHandle
  )

proc preparedContains*(pg: PreparedGeometry; other: Geometry): bool =
  ## Returns true when `pg` contains `other`.
  evalPreparedPredicate(pg, other, "preparedContains", GEOSPreparedContains_r)

proc preparedIntersects*(pg: PreparedGeometry; other: Geometry): bool =
  ## Returns true when `pg` intersects `other`.
  evalPreparedPredicate(pg, other, "preparedIntersects", GEOSPreparedIntersects_r)

proc preparedCovers*(pg: PreparedGeometry; other: Geometry): bool =
  ## Returns true when `pg` covers `other`.
  evalPreparedPredicate(pg, other, "preparedCovers", GEOSPreparedCovers_r)

proc preparedCoveredBy*(pg: PreparedGeometry; other: Geometry): bool =
  ## Returns true when the prepared source geometry is covered by `other`.
  evalPreparedPredicate(pg, other, "preparedCoveredBy", GEOSPreparedCoveredBy_r)

proc preparedContains*(g: Geometry; other: Geometry): bool =
  ## Guard overload to provide a clear runtime error when callers pass Geometry
  ## instead of PreparedGeometry.
  raise newException(GeosGeomError, "preparedContains requires PreparedGeometry; call toPreparedGeometry first")

proc preparedIntersects*(g: Geometry; other: Geometry): bool =
  ## Guard overload to provide a clear runtime error when callers pass Geometry
  ## instead of PreparedGeometry.
  raise newException(GeosGeomError, "preparedIntersects requires PreparedGeometry; call toPreparedGeometry first")

proc preparedCovers*(g: Geometry; other: Geometry): bool =
  ## Guard overload to provide a clear runtime error when callers pass Geometry
  ## instead of PreparedGeometry.
  raise newException(GeosGeomError, "preparedCovers requires PreparedGeometry; call toPreparedGeometry first")

proc preparedCoveredBy*(g: Geometry; other: Geometry): bool =
  ## Guard overload to provide a clear runtime error when callers pass Geometry
  ## instead of PreparedGeometry.
  raise newException(GeosGeomError, "preparedCoveredBy requires PreparedGeometry; call toPreparedGeometry first")
