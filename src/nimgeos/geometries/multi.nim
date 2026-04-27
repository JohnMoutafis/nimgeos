## Multi-geometry types and operations.
## All constructors take ownership of input geometry handles.

import std/sequtils
import ../private/geos_abi
import ../context
import ../errors
import ../geometry

# ── Type declarations ─────────────────────────────────────────────────────────
type
  MultiPointObj*           = object of GeometryObj
  MultiPoint*              = ref MultiPointObj

  MultiLineStringObj*      = object of GeometryObj
  MultiLineString*         = ref MultiLineStringObj

  MultiPolygonObj*         = object of GeometryObj
  MultiPolygon*            = ref MultiPolygonObj

  GeometryCollectionObj*   = object of GeometryObj
  GeometryCollection*      = ref GeometryCollectionObj

# --- Internal helpers ----------------------------------------------------------

proc inferCollectionGeomType(ctx: ptr GeosContext; handles: seq[GEOSGeometry]): GeomType =
  ## Infer the appropriate multi-geometry type from the GEOS handles.
  ##   all-Point      → MultiPoint
  ##   all-LineString → MultiLineString
  ##   all-Polygon    → MultiPolygon
  ##   mixed          → GeometryCollection.
  if handles.len == 0:
    raise newException(GeosGeomError, "Cannot infer geometry type from empty sequence")

  let firstId = GeomType(GEOSGeomTypeId_r(ctx.handle, handles[0]))
  if handles.allIt(GeomType(GEOSGeomTypeId_r(ctx.handle, it)) == firstId):
    case firstId
    of gtPoint:      return gtMultiPoint
    of gtLineString: return gtMultiLineString
    of gtPolygon:    return gtMultiPolygon
    else:            return gtGeometryCollection
  else:
    return gtGeometryCollection

proc wrapMultiHandle(ctx: ptr GeosContext; handle: GEOSGeometry; geomType: GeomType): Geometry =
  ## Wrap a raw collection handle in the correct concrete multi-geometry type.
  ##
  ## This helper intentionally duplicates the multi-type branch of
  ## ``geomFromHandle`` (in ``factories.nim``) because ``multi.nim`` **cannot**
  ## import ``factories.nim`` or ``geometry_base.nim`` without creating a
  ## circular dependency (both of those modules import this one).
  case geomType
  of gtMultiPoint:         MultiPoint(ctx: ctx, handle: handle)
  of gtMultiLineString:    MultiLineString(ctx: ctx, handle: handle)
  of gtMultiPolygon:       MultiPolygon(ctx: ctx, handle: handle)
  of gtGeometryCollection: GeometryCollection(ctx: ctx, handle: handle)
  else:
    raise newException(GeosGeomError, "wrapMultiHandle: unexpected kind " & $geomType)

# --- Constructor ---------------------------------------------------------------

proc createMultiGeometry*(ctx: var GeosContext; geoms: var seq[Geometry]): Geometry =
  ## Unified multi-geometry constructor.
  ## Infers the collection type from the input geometries:
  ##   all Point      → MultiPoint
  ##   all LineString → MultiLineString
  ##   all Polygon    → MultiPolygon
  ##   mixed          → GeometryCollection
  ## Takes ownership of all geometry handles.
  ## Do NOT use geoms after this call.
  checkContext(ctx, "createMultiGeometry")
  if geoms.len == 0:
    raise newException(GeosGeomError, "Cannot create multi-geometry from empty sequence")

  for i, g in geoms:
    g.checkHandle("createMultiGeometry geoms[" & $i & "]")

  var handles = newSeq[GEOSGeometry](geoms.len)
  for i, g in geoms: handles[i] = g.handle

  let geomType = inferCollectionGeomType(addr ctx, handles)

  let mHandle = GEOSGeom_createCollection_r(
    ctx.handle, geomType.cint, addr handles[0], handles.len.cuint)
  if cast[pointer](mHandle) == nil:
    raise newException(GeosGeomError, "GEOSGeom_createCollection_r failed (kind=" & $geomType & ")")

  # Neutralise — GEOS owns the handles now
  for g in geoms: g.handle = cast[GEOSGeometry](nil)

  return wrapMultiHandle(addr ctx, mHandle, geomType)

# ── String representations ────────────────────────────────────────────────────

method `$`*(g: MultiPoint): string =
  if g == nil or cast[pointer](g.handle) == nil: return "<nil MultiPoint>"
  return "MultiPoint(" & $g.numGeometries() & " points)"

method `$`*(g: MultiLineString): string =
  if g == nil or cast[pointer](g.handle) == nil: return "<nil MultiLineString>"
  return "MultiLineString(" & $g.numGeometries() & " linestrings)"

method `$`*(g: MultiPolygon): string =
  if g == nil or cast[pointer](g.handle) == nil: return "<nil MultiPolygon>"
  return "MultiPolygon(" & $g.numGeometries() & " polygons)"

method `$`*(g: GeometryCollection): string =
  if g == nil or cast[pointer](g.handle) == nil: return "<nil GeometryCollection>"
  return "GeometryCollection(" & $g.numGeometries() & " geometries)"
