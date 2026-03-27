## Base Geometry type. All concrete types inherit from this.
## Owns the GEOSGeometry handle — destroyed when ref count hits zero.

import ./geos_abi
import ./context
import ./errors

# ── Geometry type enum ────────────────────────────────────────────────────────

type
  GeomType* = enum
    Point              = 0
    LineString         = 1
    LinearRing         = 2
    Polygon            = 3
    MultiPoint         = 4
    MultiLineString    = 5
    MultiPolygon       = 6
    GeometryCollection = 7

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
  result = Geometry(
    ctx:    g.ctx,
    handle: GEOSGeom_clone_r(g.ctx.handle, g.handle)
  )

# ── Internal helpers ──────────────────────────────────────────────────────────

proc checkHandle*(g: Geometry; label: string) {.inline.} =
  if g == nil or cast[pointer](g.handle) == nil:
    raise newException(GeosGeomError, label & " called on nil Geometry")

# -- Serialization ──────────────────────────────────────────────────────────────

proc fromWKT*(ctx: var GeosContext; wkt: string): Geometry =
  ## Parse any WKT string into a base `Geometry`.
  ## Use type specific constructors when the geometry is known upfornt.
  let reader = GEOSWKTReader_create_r(ctx.handle)
  if cast[pointer](reader) == nil:
    raise newException(GeosInitError, "Failed to create WKT reader")

  defer: GEOSWKTReader_destroy_r(ctx.handle, reader)
  let handle = GEOSWKTReader_read_r(ctx.handle, reader, wkt.cstring)
  if cast[pointer](handle) == nil:
    raise newException(GeosParseError, "Failed to parse WKT: " & wkt)
  result = Geometry(ctx: addr ctx, handle: handle)

proc toWKT*(g: Geometry): string =
  ## Serialize a `Geometry` to WKT.
  checkHandle(g, "toWKT")
  let writer = GEOSWKTWriter_create_r(g.ctx.handle)
  if cast[pointer](writer) == nil:
    raise newException(GeosInitError, "Failed to create WKT writer")

  defer: GEOSWKTWriter_destroy_r(g.ctx.handle, writer)
  GEOSWKTWriter_setTrim_r(g.ctx.handle, writer, 1)
  GEOSWKTWriter_setRoundingPrecision_r(g.ctx.handle, writer, 6)
  let wkt = GEOSWKTWriter_write_r(g.ctx.handle, writer, g.handle)
  if wkt == nil:
    raise newException(GeosGeomError, "WKT serialization failed")
  defer: GEOSFree_r(g.ctx.handle, cast[pointer](wkt))
  result = $wkt

# ── Representation ─────────────────────────────────────────────────────

method `$`*(g: Geometry): string {.base.} =
  if g == nil or cast[pointer](g.handle) == nil:
    return "<nil Geometry>"
  g.toWKT()

# ── Property accessors ────────────────────────────────────────────────────────

proc type*(g: Geometry): GeomType =
  g.checkHandle("type")
  let id = GEOSGeomTypeId_r(g.ctx.handle, g.handle)
  if id < 0:
    raise newException(GeosGeomError, "GEOSGeomTypeId_r failed")
  result = GeomType(id)

proc isEmpty*(g: Geometry): bool =
  g.checkHandle("isEmpty")
  GEOSisEmpty_r(g.ctx.handle, g.handle) == 1

proc isValid*(g: Geometry): bool =
  g.checkHandle("isValid")
  GEOSisValid_r(g.ctx.handle, g.handle) == 1

proc numCoordinates*(g: Geometry): int =
  g.checkHandle("numCoordinates")
  GEOSGetNumCoordinates_r(g.ctx.handle, g.handle).int

proc numGeometries*(g: Geometry): int =
  g.checkHandle("numGeometries")
  GEOSGetNumGeometries_r(g.ctx.handle, g.handle).int

proc area*(g: Geometry): float =
  g.checkHandle("area")
  var a: cdouble
  if GEOSArea_r(g.ctx.handle, g.handle, addr a) == 0:
    raise newException(GeosGeomError, "GEOSArea_r failed")
  result = a.float

proc length*(g: Geometry): float =
  g.checkHandle("length")
  var l: cdouble
  if GEOSLength_r(g.ctx.handle, g.handle, addr l) == 0:
    raise newException(GeosGeomError, "GEOSLength_r failed")
  result = l.float

proc distance*(g: Geometry, other: Geometry): float =
  g.checkHandle("distance g")
  other.checkHandle("distance other")
  var d: cdouble
  if GEOSDistance_r(g.ctx.handle, g.handle, other.handle, addr d) == 0:
    raise newException(GeosGeomError, "GEOSDistance_r failed")
  result = d.float
