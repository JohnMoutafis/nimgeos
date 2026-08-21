## Base Geometry type. All concrete types inherit from this.
## Owns the GEOSGeometry handle — destroyed when ref count hits zero.
## See also: `docs/geometries/overview.md`.

import ./private/geos_abi
import ./context
import ./errors

# ── Geometry type enum ────────────────────────────────────────────────────────
type
  GeomType* = enum
    gtPoint              = 0  ## A single point geometry (2D or 3D).
    gtLineString         = 1  ## A path defined by a sequence of points.
    gtLinearRing         = 2  ## A closed ring used for Polygon boundaries.
    gtPolygon            = 3  ## An area geometry with optional holes.
    gtMultiPoint         = 4  ## A collection of Point geometries.
    gtMultiLineString    = 5  ## A collection of LineString geometries.
    gtMultiPolygon       = 6  ## A collection of Polygon geometries.
    gtGeometryCollection = 7  ## A mixed collection of any geometry types.
# ── Base type ─────────────────────────────────────────────────────────────────
type
  GeometryObj* = object of RootObj
    ## Internal base — never instantiate directly. Use concrete subtypes.
    ctx*:    ptr GeosContext    ## Internal — not part of stable API. Subject to change.
    handle*: GEOSGeometry      ## Internal — not part of stable API. Subject to change.
  Geometry* = ref GeometryObj ## Base reference type for all concrete geometries
                              ## (Point, LineString, LinearRing, Polygon, multi-geometries, GeometryCollection).


# ── Lifecycle hooks ────────────────────────────────────────────────────────────
proc `=destroy`*(g: GeometryObj) =
  ## Fires for ALL subtypes when their ref count hits zero.
  if cast[pointer](g.handle) != nil and g.ctx != nil:
    GEOSGeom_destroy_r(g.ctx.handle, g.handle)

proc `=copy`*(dst: var GeometryObj; src: GeometryObj) =
  ## Deep copy via GEOSGeom_clone_r — never copies the raw pointer.
  ## Shares the context pointer; only the GEOS handle is deep-cloned.
  if cast[pointer](src.handle) == nil or src.ctx == nil:
    dst.ctx    = nil
    dst.handle = cast[GEOSGeometry](nil)
    return
  dst.ctx    = src.ctx
  dst.handle = GEOSGeom_clone_r(src.ctx.handle, src.handle)

proc `=dup`*(src: GeometryObj): GeometryObj =
  ## Hook for deep copy via GEOSGeom_clone_r — called by the compiler when a
  ## GeometryObj is moved or assigned, ensuring independent GEOS handle ownership.
  ## Shares the context pointer; only the GEOS handle is deep-cloned.
  if cast[pointer](src.handle) == nil or src.ctx == nil:
    return
  result.ctx    = src.ctx
  result.handle = GEOSGeom_clone_r(src.ctx.handle, src.handle)

proc clone*(g: Geometry): Geometry =
  ## Deep copy via GEOSGeom_clone_r — returns a new independent Geometry ref.
  ## The caller owns the returned Geometry; the original is unaffected.
  ## Returns `nil` if `g` is nil or its handle is nil.
  if g == nil or cast[pointer](g.handle) == nil or g.ctx == nil:
    return nil
  return  Geometry(
    ctx:    g.ctx,
    handle: GEOSGeom_clone_r(g.ctx.handle, g.handle)
  )

# ── Internal helpers ──────────────────────────────────────────────────────────
proc checkHandle*(g: Geometry; label: string) {.inline.} =
  ## Internal — not part of stable API. Subject to change without notice.
  if g == nil or cast[pointer](g.handle) == nil:
    raise newException(GeosGeomError, label & " called on nil Geometry")

proc wrapHandle*(ctx: ptr GeosContext; handle: GEOSGeometry): Geometry =
  ## Internal — not part of stable API. Subject to change without notice.
  ## Wraps a raw handle in the base Geometry type.
  ## Used by spatial operation results before kind-dispatch is needed.
  if cast[pointer](handle) == nil:
    raise newException(GeosGeomError, "wrapHandle received nil from GEOS")
  result = Geometry(ctx: ctx, handle: handle)

# ── Representation ─────────────────────────────────────────────────────
method `$`*(g: Geometry): string {.base.} =
  ## String representation — returns the concrete type name.
  ## Raises `NilAccessDefect` if the Geometry is nil.
  if g == nil or cast[pointer](g.handle) == nil:
    raise newException(NilAccessDefect, "Cannot convert nil Geometry to string")
  "<Geometry: " & $g.type() & ">"

# ── Property accessors ────────────────────────────────────────────────────────
proc type*(g: Geometry): GeomType =
  ## Returns the concrete GEOS geometry type of `g` (e.g. `gtPoint`, `gtPolygon`).
  ## Raises `GeosGeomError` if the geometry is nil or GEOS fails.
  g.checkHandle("type")
  let id = GEOSGeomTypeId_r(g.ctx.handle, g.handle)
  if id < 0:
    raise newException(GeosGeomError, "GEOSGeomTypeId_r failed")
  return GeomType(id)

proc isEmpty*(g: Geometry): bool =
  ## Returns `true` if the geometry has no coordinates.
  ## Raises `GeosGeomError` if the geometry is nil or GEOS fails.
  g.checkHandle("isEmpty")
  return ord(GEOSisEmpty_r(g.ctx.handle, g.handle)) == 1

proc isValid*(g: Geometry): bool =
  ## Returns `true` if the geometry is topologically valid per OGC rules.
  ## Raises `GeosGeomError` if the geometry is nil or GEOS fails.
  g.checkHandle("isValid")
  return ord(GEOSisValid_r(g.ctx.handle, g.handle)) == 1

proc numCoordinates*(g: Geometry): int =
  ## Returns the total number of coordinate points in the geometry.
  ## For multi-geometries, this includes all sub-geometry coordinates.
  ## Raises `GeosGeomError` if the geometry is nil or GEOS fails.
  g.checkHandle("numCoordinates")
  return GEOSGetNumCoordinates_r(g.ctx.handle, g.handle).int

proc numGeometries*(g: Geometry): int =
  ## Returns the number of component geometries.
  ## For simple geometries (Point, LineString, Polygon) this is 1.
  ## For multi-geometries this is the member count.
  ## Raises `GeosGeomError` if the geometry is nil or GEOS fails.
  g.checkHandle("numGeometries")
  return GEOSGetNumGeometries_r(g.ctx.handle, g.handle).int

proc area*(g: Geometry): float =
  ## Returns the planar area of the geometry.
  ## For polygons and multi-polygons this computes the surface area.
  ## Returns 0.0 for non-polygonal geometries.
  ## Raises `GeosGeomError` if the geometry is nil or GEOS fails.
  g.checkHandle("area")
  var a: cdouble
  if GEOSArea_r(g.ctx.handle, g.handle, addr a) == 0:
    raise newException(GeosGeomError, "GEOSArea_r failed")
  return a.float

proc length*(g: Geometry): float =
  ## Returns the length (perimeter) of the geometry.
  ## For LineStrings this is the path length.
  ## For Polygons this is the perimeter (including holes).
  ## Returns 0.0 for points.
  ## Raises `GeosGeomError` if the geometry is nil or GEOS fails.
  g.checkHandle("length")
  var l: cdouble
  if GEOSLength_r(g.ctx.handle, g.handle, addr l) == 0:
    raise newException(GeosGeomError, "GEOSLength_r failed")
  return l.float

proc distance*(g: Geometry, other: Geometry): float =
  ## Returns the minimum Euclidean distance between `g` and `other`.
  ## Both geometries must be in the same coordinate reference system.
  ## Raises `GeosGeomError` if either argument is nil or invalid.
  g.checkHandle("distance g")
  other.checkHandle("distance other")
  var d: cdouble
  if GEOSDistance_r(g.ctx.handle, g.handle, other.handle, addr d) == 0:
    raise newException(GeosGeomError, "GEOSDistance_r failed")
  return d.float
