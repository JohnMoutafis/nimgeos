## Base Geometry type. All concrete types inherit from this.
## Owns the GEOSGeometry handle — destroyed when ref count hits zero.

import ./geos_abi
import ./context
import ./errors

# ── Geometry type enum ────────────────────────────────────────────────────────
type
  GeomType* = enum
    gtPoint              = 0
    gtLineString         = 1
    gtLinearRing         = 2
    gtPolygon            = 3
    gtMultiPoint         = 4
    gtMultiLineString    = 5
    gtMultiPolygon       = 6
    gtGeometryCollection = 7

# ── Base type ─────────────────────────────────────────────────────────────────
type
  GeometryObj* = object of RootObj
    ## Internal base — never instantiate directly. Use concrete subtypes.
    ctx*:    ptr GeosContext
    handle*: GEOSGeometry

  Geometry* = ref GeometryObj

# ── Lifecycle hooks ────────────────────────────────────────────────────────────
proc `=destroy`*(g: GeometryObj) =
  ## Fires for ALL subtypes when their ref count hits zero.
  if cast[pointer](g.handle) != nil and g.ctx != nil:
    GEOSGeom_destroy_r(g.ctx.handle, g.handle)

proc `=copy`*(dst: var GeometryObj; src: GeometryObj) =
  ## Deep copy via GEOSGeom_clone_r — never copies the raw pointer.
  if cast[pointer](src.handle) == nil or src.ctx == nil:
    dst.ctx    = nil
    dst.handle = cast[GEOSGeometry](nil)
    return
  dst.ctx    = src.ctx
  dst.handle = GEOSGeom_clone_r(src.ctx.handle, src.handle)

proc `=dup`*(src: GeometryObj): GeometryObj =
  if cast[pointer](src.handle) == nil or src.ctx == nil:
    return
  result.ctx    = src.ctx
  result.handle = GEOSGeom_clone_r(src.ctx.handle, src.handle)

proc clone*(g: Geometry): Geometry =
  ## Deep copy via GEOSGeom_clone_r — returns a new independent Geometry ref.
  if g == nil or cast[pointer](g.handle) == nil or g.ctx == nil:
    return nil
  return  Geometry(
    ctx:    g.ctx,
    handle: GEOSGeom_clone_r(g.ctx.handle, g.handle)
  )

# ── Internal helpers ──────────────────────────────────────────────────────────
proc checkHandle*(g: Geometry; label: string) {.inline.} =
  if g == nil or cast[pointer](g.handle) == nil:
    raise newException(GeosGeomError, label & " called on nil Geometry")

proc wrapHandle*(ctx: ptr GeosContext; handle: GEOSGeometry): Geometry =
  ## Internal factory: wraps a raw handle in the base Geometry type.
  ## Used by spatial operation results before kind-dispatch is needed.
  if cast[pointer](handle) == nil:
    raise newException(GeosGeomError, "wrapHandle received nil from GEOS")
  result = Geometry(ctx: ctx, handle: handle)

# ── Representation ─────────────────────────────────────────────────────
method `$`*(g: Geometry): string {.base.} =
  if g == nil or cast[pointer](g.handle) == nil:
    return "<nil Geometry>"
  "<Geometry: " & $g.type() & ">"

# ── Property accessors ────────────────────────────────────────────────────────
proc type*(g: Geometry): GeomType =
  g.checkHandle("type")
  let id = GEOSGeomTypeId_r(g.ctx.handle, g.handle)
  if id < 0:
    raise newException(GeosGeomError, "GEOSGeomTypeId_r failed")
  return GeomType(id)

proc isEmpty*(g: Geometry): bool =
  g.checkHandle("isEmpty")
  return GEOSisEmpty_r(g.ctx.handle, g.handle) == 1

proc isValid*(g: Geometry): bool =
  g.checkHandle("isValid")
  return GEOSisValid_r(g.ctx.handle, g.handle) == 1

proc numCoordinates*(g: Geometry): int =
  g.checkHandle("numCoordinates")
  return GEOSGetNumCoordinates_r(g.ctx.handle, g.handle).int

proc numGeometries*(g: Geometry): int =
  g.checkHandle("numGeometries")
  return GEOSGetNumGeometries_r(g.ctx.handle, g.handle).int

proc area*(g: Geometry): float =
  g.checkHandle("area")
  var a: cdouble
  if GEOSArea_r(g.ctx.handle, g.handle, addr a) == 0:
    raise newException(GeosGeomError, "GEOSArea_r failed")
  return a.float

proc length*(g: Geometry): float =
  g.checkHandle("length")
  var l: cdouble
  if GEOSLength_r(g.ctx.handle, g.handle, addr l) == 0:
    raise newException(GeosGeomError, "GEOSLength_r failed")
  return l.float

proc distance*(g: Geometry, other: Geometry): float =
  g.checkHandle("distance g")
  other.checkHandle("distance other")
  var d: cdouble
  if GEOSDistance_r(g.ctx.handle, g.handle, other.handle, addr d) == 0:
    raise newException(GeosGeomError, "GEOSDistance_r failed")
  return d.float
