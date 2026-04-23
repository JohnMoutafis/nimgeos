## GeoJSON serializer for Nimgeos.
## Handles GeoJSON geometry objects.
## - Features and FeatureCollections are out of scope of this module.

import std/json
import std/math

import ../private/geos_abi
import ../context
import ../geometry
import ../geometries/factories
import ../errors

# ── Internal helpers: Serialization ───────────────────────────────────────────

proc coordSeqDims(ctx: GEOSContextHandle_t; cs: GEOSCoordSequence): int =
  var dims: cuint
  discard GEOSCoordSeq_getDimensions_r(ctx, cs, addr dims)
  return dims.int

proc coordSeqLen(ctx: GEOSContextHandle_t; cs: GEOSCoordSequence): int =
  var size: cuint
  discard GEOSCoordSeq_getSize_r(ctx, cs, addr size)
  return size.int

proc coordToJson(ctx: GEOSContextHandle_t; cs: GEOSCoordSequence; idx: int; dims: int): JsonNode =
  var x, y: cdouble
  discard GEOSCoordSeq_getX_r(ctx, cs, idx.cuint, addr x)
  discard GEOSCoordSeq_getY_r(ctx, cs, idx.cuint, addr y)
  if dims >= 3:
    var z: cdouble
    discard GEOSCoordSeq_getZ_r(ctx, cs, idx.cuint, addr z)
    if not z.isNaN:
      return %* [x.float, y.float, z.float]
  return %* [x.float, y.float]

proc coordSeqToJson(ctx: GEOSContextHandle_t; cs: GEOSCoordSequence): JsonNode =
  let dims = coordSeqDims(ctx, cs)
  let size = coordSeqLen(ctx, cs)
  result = newJArray()
  for i in 0 ..< size:
    result.add(coordToJson(ctx, cs, i, dims))

proc ringToJson(ctx: GEOSContextHandle_t; ring: GEOSGeometry): JsonNode =
  let cs = GEOSGeom_getCoordSeq_r(ctx, ring)
  return coordSeqToJson(ctx, cs)

proc geomToJsonNode(ctx: GEOSContextHandle_t; handle: GEOSGeometry): JsonNode =
  let typeId = GeomType(GEOSGeomTypeId_r(ctx, handle))

  case typeId
  of gtPoint:
    if ord(GEOSisEmpty_r(ctx, handle)) == 1:
      return %* {"type": "Point", "coordinates": newJArray()}
    let cs = GEOSGeom_getCoordSeq_r(ctx, handle)
    let dims = coordSeqDims(ctx, cs)
    let coord = coordToJson(ctx, cs, 0, dims)
    return %* {"type": "Point", "coordinates": coord}
  of gtLineString, gtLinearRing:
    let cs = GEOSGeom_getCoordSeq_r(ctx, handle)
    let coords = coordSeqToJson(ctx, cs)
    return %* {"type": "LineString", "coordinates": coords}
  of gtPolygon:
    if ord(GEOSisEmpty_r(ctx, handle)) == 1:
      return %* {"type": "Polygon", "coordinates": newJArray()}
    var rings = newJArray()
    let shell = GEOSGetExteriorRing_r(ctx, handle)
    rings.add(ringToJson(ctx, shell))
    let numHoles = GEOSGetNumInteriorRings_r(ctx, handle)
    for i in 0 ..< numHoles:
      let hole = GEOSGetInteriorRingN_r(ctx, handle, i.cint)
      rings.add(ringToJson(ctx, hole))
    return %* {"type": "Polygon", "coordinates": rings}
  of gtMultiPoint:
    var coords = newJArray()
    let n = GEOSGetNumGeometries_r(ctx, handle)
    for i in 0 ..< n:
      let sub = GEOSGetGeometryN_r(ctx, handle, i.cint)
      let cs = GEOSGeom_getCoordSeq_r(ctx, sub)
      let dims = coordSeqDims(ctx, cs)
      coords.add(coordToJson(ctx, cs, 0, dims))
    return %* {"type": "MultiPoint", "coordinates": coords}
  of gtMultiLineString:
    var coords = newJArray()
    let n = GEOSGetNumGeometries_r(ctx, handle)
    for i in 0 ..< n:
      let sub = GEOSGetGeometryN_r(ctx, handle, i.cint)
      let cs = GEOSGeom_getCoordSeq_r(ctx, sub)
      coords.add(coordSeqToJson(ctx, cs))
    return %* {"type": "MultiLineString", "coordinates": coords}
  of gtMultiPolygon:
    var coords = newJArray()
    let n = GEOSGetNumGeometries_r(ctx, handle)
    for i in 0 ..< n:
      let sub = GEOSGetGeometryN_r(ctx, handle, i.cint)
      var rings = newJArray()
      let shell = GEOSGetExteriorRing_r(ctx, sub)
      rings.add(ringToJson(ctx, shell))
      let numHoles = GEOSGetNumInteriorRings_r(ctx, sub)
      for j in 0 ..< numHoles:
        let hole = GEOSGetInteriorRingN_r(ctx, sub, j.cint)
        rings.add(ringToJson(ctx, hole))
      coords.add(rings)
    return %* {"type": "MultiPolygon", "coordinates": coords}
  of gtGeometryCollection:
    var geoms = newJArray()
    let n = GEOSGetNumGeometries_r(ctx, handle)
    for i in 0 ..< n:
      let sub = GEOSGetGeometryN_r(ctx, handle, i.cint)
      geoms.add(geomToJsonNode(ctx, sub))
    return %* {"type": "GeometryCollection", "geometries": geoms}


# ── Internal helpers: Deserialization ─────────────────────────────────────────

proc getNum(node: JsonNode): float =
  case node.kind
  of JFloat: return node.getFloat
  of JInt:   return node.getInt.float
  else:
    raise newException(GeosParseError, "Expected a number in coordinate")

proc buildCoordSeq(ctx: GEOSContextHandle_t; coords: JsonNode): GEOSCoordSequence =
  if coords.kind != JArray or coords.len == 0:
    raise newException(GeosParseError, "Expected non-empty coordinates array")

  let first = coords[0]
  if first.kind != JArray:
    raise newException(GeosParseError, "Expected coordinate to be an array")

  let dims = if first.len >= 3: 3 else: 2
  let size = coords.len

  let cs = GEOSCoordSeq_create_r(ctx, size.cuint, dims.cuint)
  if cast[pointer](cs) == nil:
    raise newException(GeosParseError, "Failed to create coordinate sequence")

  for i in 0 ..< size:
    let c = coords[i]
    if c.kind != JArray or c.len < 2:
      GEOSCoordSeq_destroy_r(ctx, cs)
      raise newException(GeosParseError, "Invalid coordinate at index " & $i)
    discard GEOSCoordSeq_setX_r(ctx, cs, i.cuint, getNum(c[0]).cdouble)
    discard GEOSCoordSeq_setY_r(ctx, cs, i.cuint, getNum(c[1]).cdouble)
    if dims == 3 and c.len >= 3:
      discard GEOSCoordSeq_setZ_r(ctx, cs, i.cuint, getNum(c[2]).cdouble)

  return cs

proc parsePointGeom(ctx: GEOSContextHandle_t; coords: JsonNode): GEOSGeometry =
  if coords.kind != JArray:
    raise newException(GeosParseError, "Point coordinates must be an array")
  if coords.len == 0:
    return GEOSGeom_createEmptyPoint_r(ctx)
  if coords.len < 2:
    raise newException(GeosParseError, "Point coordinate must have at least 2 values")

  let x = getNum(coords[0])
  let y = getNum(coords[1])

  if coords.len >= 3:
    let z = getNum(coords[2])
    let cs = GEOSCoordSeq_create_r(ctx, 1.cuint, 3.cuint)
    if cast[pointer](cs) == nil:
      raise newException(GeosParseError, "Failed to create coord sequence for Point")
    discard GEOSCoordSeq_setX_r(ctx, cs, 0.cuint, x.cdouble)
    discard GEOSCoordSeq_setY_r(ctx, cs, 0.cuint, y.cdouble)
    discard GEOSCoordSeq_setZ_r(ctx, cs, 0.cuint, z.cdouble)
    let handle = GEOSGeom_createPoint_r(ctx, cs)
    if cast[pointer](handle) == nil:
      raise newException(GeosParseError, "Failed to create 3D Point from GeoJSON")
    return handle
  else:
    let handle = GEOSGeom_createPointFromXY_r(ctx, x.cdouble, y.cdouble)
    if cast[pointer](handle) == nil:
      raise newException(GeosParseError, "Failed to create Point from GeoJSON")
    return handle

proc parseLineStringGeom(ctx: GEOSContextHandle_t; coords: JsonNode): GEOSGeometry =
  let cs = buildCoordSeq(ctx, coords)
  let handle = GEOSGeom_createLineString_r(ctx, cs)
  if cast[pointer](handle) == nil:
    raise newException(GeosParseError, "Failed to create LineString from GeoJSON")
  return handle

proc parseLinearRingGeom(ctx: GEOSContextHandle_t; coords: JsonNode): GEOSGeometry =
  let cs = buildCoordSeq(ctx, coords)
  let handle = GEOSGeom_createLinearRing_r(ctx, cs)
  if cast[pointer](handle) == nil:
    raise newException(GeosParseError, "Failed to create LinearRing from GeoJSON")
  return handle

proc parsePolygonGeom(ctx: GEOSContextHandle_t; coords: JsonNode): GEOSGeometry =
  if coords.kind != JArray:
    raise newException(GeosParseError, "Polygon coordinates must be an array")
  if coords.len == 0:
    return GEOSGeom_createEmptyPolygon_r(ctx)

  let shell = parseLinearRingGeom(ctx, coords[0])
  let numHoles = coords.len - 1
  if numHoles == 0:
    let handle = GEOSGeom_createPolygon_r(ctx, shell, nil, 0.cuint)
    if cast[pointer](handle) == nil:
      GEOSGeom_destroy_r(ctx, shell)
      raise newException(GeosParseError, "Failed to create Polygon from GeoJSON")
    return handle

  var holes = newSeq[GEOSGeometry](numHoles)
  for i in 0 ..< numHoles:
    holes[i] = parseLinearRingGeom(ctx, coords[i + 1])

  let handle = GEOSGeom_createPolygon_r(ctx, shell, addr holes[0], numHoles.cuint)
  if cast[pointer](handle) == nil:
    GEOSGeom_destroy_r(ctx, shell)
    for h in holes:
      if cast[pointer](h) != nil:
        GEOSGeom_destroy_r(ctx, h)
    raise newException(GeosParseError, "Failed to create Polygon with holes from GeoJSON")
  return handle

proc parseMultiPointGeom(ctx: GEOSContextHandle_t; coords: JsonNode): GEOSGeometry =
  if coords.kind != JArray:
    raise newException(GeosParseError, "MultiPoint coordinates must be an array")
  var geoms = newSeq[GEOSGeometry](coords.len)
  for i in 0 ..< coords.len:
    geoms[i] = parsePointGeom(ctx, coords[i])
  let handle = GEOSGeom_createCollection_r(ctx, gtMultiPoint.cint,
    if geoms.len > 0: addr geoms[0] else: nil, geoms.len.cuint)
  if cast[pointer](handle) == nil:
    for g in geoms:
      if cast[pointer](g) != nil: GEOSGeom_destroy_r(ctx, g)
    raise newException(GeosParseError, "Failed to create MultiPoint from GeoJSON")
  return handle

proc parseMultiLineStringGeom(ctx: GEOSContextHandle_t;
                               coords: JsonNode): GEOSGeometry =
  if coords.kind != JArray:
    raise newException(GeosParseError, "MultiLineString coordinates must be an array")
  var geoms = newSeq[GEOSGeometry](coords.len)
  for i in 0 ..< coords.len:
    geoms[i] = parseLineStringGeom(ctx, coords[i])
  let handle = GEOSGeom_createCollection_r(ctx, gtMultiLineString.cint,
    if geoms.len > 0: addr geoms[0] else: nil, geoms.len.cuint)
  if cast[pointer](handle) == nil:
    for g in geoms:
      if cast[pointer](g) != nil: GEOSGeom_destroy_r(ctx, g)
    raise newException(GeosParseError, "Failed to create MultiLineString from GeoJSON")
  return handle

proc parseMultiPolygonGeom(ctx: GEOSContextHandle_t;
                            coords: JsonNode): GEOSGeometry =
  if coords.kind != JArray:
    raise newException(GeosParseError, "MultiPolygon coordinates must be an array")
  var geoms = newSeq[GEOSGeometry](coords.len)
  for i in 0 ..< coords.len:
    geoms[i] = parsePolygonGeom(ctx, coords[i])
  let handle = GEOSGeom_createCollection_r(ctx, gtMultiPolygon.cint,
    if geoms.len > 0: addr geoms[0] else: nil, geoms.len.cuint)
  if cast[pointer](handle) == nil:
    for g in geoms:
      if cast[pointer](g) != nil: GEOSGeom_destroy_r(ctx, g)
    raise newException(GeosParseError, "Failed to create MultiPolygon from GeoJSON")
  return handle

proc parseGeomFromNode(ctx: GEOSContextHandle_t; node: JsonNode): GEOSGeometry =
  if node.kind != JObject:
    raise newException(GeosParseError, "GeoJSON geometry must be a JSON object")
  if not node.hasKey("type"):
    raise newException(GeosParseError, "GeoJSON geometry missing 'type' field")

  let geomType = node["type"].getStr

  if geomType == "GeometryCollection":
    if not node.hasKey("geometries"):
      raise newException(GeosParseError, "GeoJSON 'GeometryCollection' missing 'geometries' field")
  else:
    if not node.hasKey("coordinates"):
      raise newException(GeosParseError, "GeoJSON " & geomType & " missing 'coordinates' field")

  case geomType
  of "Point":
    return parsePointGeom(ctx, node["coordinates"])
  of "LineString":
    return parseLineStringGeom(ctx, node["coordinates"])
  of "Polygon":
    return parsePolygonGeom(ctx, node["coordinates"])
  of "MultiPoint":
    return parseMultiPointGeom(ctx, node["coordinates"])
  of "MultiLineString":
    return parseMultiLineStringGeom(ctx, node["coordinates"])
  of "MultiPolygon":
    return parseMultiPolygonGeom(ctx, node["coordinates"])
  of "GeometryCollection":
    let geomsNode = node["geometries"]
    if geomsNode.kind != JArray:
      raise newException(GeosParseError, "GeometryCollection 'geometries' must be an array")
    var geoms = newSeq[GEOSGeometry](geomsNode.len)
    for i in 0 ..< geomsNode.len:
      geoms[i] = parseGeomFromNode(ctx, geomsNode[i])
    let handle = GEOSGeom_createCollection_r(ctx, gtGeometryCollection.cint,
      if geoms.len > 0: addr geoms[0] else: nil, geoms.len.cuint)
    if cast[pointer](handle) == nil:
      for g in geoms:
        if cast[pointer](g) != nil: GEOSGeom_destroy_r(ctx, g)
      raise newException(GeosParseError, "Failed to create GeometryCollection from GeoJSON")
    return handle
  else:
    raise newException(GeosParseError, "Unsupported GeoJSON geometry type: " & geomType)

# ── Public API ────────────────────────────────────────────────────────────────

proc toGeoJSON*(g: Geometry): string =
  ## Serialize any Geometry to a GeoJSON geometry object string.
  checkHandle(g, "toGeoJSON")
  let node = geomToJsonNode(g.ctx.handle, g.handle)
  return $node

proc fromGeoJSON*(ctx: var GeosContext; json: string): Geometry =
  ## Parse a GeoJSON geometry object string into a concrete Geometry.
  var node: JsonNode
  try:
    node = parseJson(json)
  except JsonParsingError:
    raise newException(GeosParseError, "Invalid JSON: " & getCurrentExceptionMsg())

  let handle = parseGeomFromNode(ctx.handle, node)
  if cast[pointer](handle) == nil:
    raise newException(GeosParseError, "Failed to parse GeoJSON geometry")
  return geomFromHandle(addr ctx, handle)
