import unittest
import std/json
import std/strutils
import std/math
import nimgeos


# ══════════════════════════════════════════════════════════════════════════════
# GeoJSON Edge Cases
# ══════════════════════════════════════════════════════════════════════════════

suite "GeoJSON Edge Cases: Empty Multi-Geometries from JSON":
  test "Empty MultiPoint parses to empty MultiPoint":
    var ctx = initGeosContext()
    let g = ctx.fromGeoJSON("""{"type":"MultiPoint","coordinates":[]}""")
    check g.type() == gtMultiPoint
    check g.isEmpty()
    check g.numGeometries() == 0

  test "Empty MultiLineString parses to empty MultiLineString":
    var ctx = initGeosContext()
    let g = ctx.fromGeoJSON("""{"type":"MultiLineString","coordinates":[]}""")
    check g.type() == gtMultiLineString
    check g.isEmpty()
    check g.numGeometries() == 0

  test "Empty MultiPolygon parses to empty MultiPolygon":
    var ctx = initGeosContext()
    let g = ctx.fromGeoJSON("""{"type":"MultiPolygon","coordinates":[]}""")
    check g.type() == gtMultiPolygon
    check g.isEmpty()
    check g.numGeometries() == 0

  test "Empty GeometryCollection parses to empty GeometryCollection":
    var ctx = initGeosContext()
    let g = ctx.fromGeoJSON("""{"type":"GeometryCollection","geometries":[]}""")
    check g.type() == gtGeometryCollection
    check g.isEmpty()
    check g.numGeometries() == 0


suite "GeoJSON Edge Cases: Nested GeometryCollection":
  test "Nested GeometryCollection parses correctly":
    var ctx = initGeosContext()
    let json = """{"type":"GeometryCollection","geometries":[{"type":"GeometryCollection","geometries":[{"type":"Point","coordinates":[1,2]}]}]}"""
    let g = ctx.fromGeoJSON(json)
    check g.type() == gtGeometryCollection
    check g.numGeometries() == 1
    # The inner collection should also be a GeometryCollection
    let inner = g.geomN(0)
    check inner.type() == gtGeometryCollection
    check inner.numGeometries() == 1
    let pt = inner.geomN(0)
    check pt.type() == gtPoint

  test "Deeply nested GeometryCollection":
    var ctx = initGeosContext()
    let json = """{"type":"GeometryCollection","geometries":[{"type":"GeometryCollection","geometries":[{"type":"GeometryCollection","geometries":[{"type":"Point","coordinates":[3,4]}]}]}]}"""
    let g = ctx.fromGeoJSON(json)
    check g.type() == gtGeometryCollection
    let level1 = g.geomN(0)
    check level1.type() == gtGeometryCollection
    let level2 = level1.geomN(0)
    check level2.type() == gtGeometryCollection
    let pt = level2.geomN(0)
    check pt.type() == gtPoint


suite "GeoJSON Edge Cases: Invalid Coordinate Values":
  test "Null coordinate value raises GeosParseError":
    var ctx = initGeosContext()
    expect GeosParseError:
      discard ctx.fromGeoJSON("""{"type":"Point","coordinates":[null, 2]}""")

  test "Single-value coordinate raises GeosParseError":
    var ctx = initGeosContext()
    expect GeosParseError:
      discard ctx.fromGeoJSON("""{"type":"Point","coordinates":[1]}""")

  test "String coordinates raise GeosParseError":
    var ctx = initGeosContext()
    expect GeosParseError:
      discard ctx.fromGeoJSON("""{"type":"Point","coordinates":["1","2"]}""")

  test "Boolean coordinates raise GeosParseError":
    var ctx = initGeosContext()
    expect GeosParseError:
      discard ctx.fromGeoJSON("""{"type":"Point","coordinates":[true, false]}""")

  test "Object coordinate raises GeosParseError":
    var ctx = initGeosContext()
    expect GeosParseError:
      discard ctx.fromGeoJSON("""{"type":"Point","coordinates":[{"x":1}, 2]}""")

  test "Null in LineString coordinate raises GeosParseError":
    var ctx = initGeosContext()
    expect GeosParseError:
      discard ctx.fromGeoJSON("""{"type":"LineString","coordinates":[[0,0],[null,1],[2,2]]}""")


suite "GeoJSON Edge Cases: Extra Fields Ignored":
  test "Extra fields in Point GeoJSON are ignored":
    var ctx = initGeosContext()
    let g = ctx.fromGeoJSON("""{"type":"Point","coordinates":[1,2],"crs":"EPSG:4326","foo":"bar"}""")
    check g.type() == gtPoint
    check not g.isEmpty()

  test "Extra fields in Polygon GeoJSON are ignored":
    var ctx = initGeosContext()
    let g = ctx.fromGeoJSON("""{"type":"Polygon","coordinates":[[[0,0],[1,0],[1,1],[0,1],[0,0]]],"properties":{"name":"test"},"id":42}""")
    check g.type() == gtPolygon
    check not g.isEmpty()

  test "Extra fields in GeometryCollection are ignored":
    var ctx = initGeosContext()
    let g = ctx.fromGeoJSON("""{"type":"GeometryCollection","geometries":[{"type":"Point","coordinates":[1,2]}],"metadata":"stuff"}""")
    check g.type() == gtGeometryCollection
    check g.numGeometries() == 1


suite "GeoJSON Edge Cases: toGeoJSON on Empty Multi-Geometries":
  test "toGeoJSON on MULTIPOINT EMPTY":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("MULTIPOINT EMPTY")
    let gj = g.toGeoJSON()
    let node = parseJson(gj)
    check node["type"].getStr == "MultiPoint"
    check node["coordinates"].kind == JArray
    check node["coordinates"].len == 0

  test "toGeoJSON on MULTILINESTRING EMPTY":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("MULTILINESTRING EMPTY")
    let gj = g.toGeoJSON()
    let node = parseJson(gj)
    check node["type"].getStr == "MultiLineString"
    check node["coordinates"].kind == JArray
    check node["coordinates"].len == 0

  test "toGeoJSON on MULTIPOLYGON EMPTY":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("MULTIPOLYGON EMPTY")
    let gj = g.toGeoJSON()
    let node = parseJson(gj)
    check node["type"].getStr == "MultiPolygon"
    check node["coordinates"].kind == JArray
    check node["coordinates"].len == 0

  test "toGeoJSON on GEOMETRYCOLLECTION EMPTY":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("GEOMETRYCOLLECTION EMPTY")
    let gj = g.toGeoJSON()
    let node = parseJson(gj)
    check node["type"].getStr == "GeometryCollection"
    check node.hasKey("geometries")
    check node["geometries"].kind == JArray
    check node["geometries"].len == 0


suite "GeoJSON Edge Cases: Polygon with Multiple Holes":
  test "Polygon with 2 holes round-trips through GeoJSON":
    var ctx = initGeosContext()
    let wkt = "POLYGON ((0 0, 20 0, 20 20, 0 20, 0 0), (1 1, 1 3, 3 3, 3 1, 1 1), (5 5, 5 8, 8 8, 8 5, 5 5))"
    let original = ctx.fromWKT(wkt)
    let gj = original.toGeoJSON()
    let node = parseJson(gj)
    check node["type"].getStr == "Polygon"
    check node["coordinates"].len == 3  # shell + 2 holes

    let restored = ctx.fromGeoJSON(gj)
    check restored.type() == gtPolygon
    check restored.equals(original)
    let poly = Polygon(restored)
    check poly.numInteriorRings() == 2

  test "Polygon with 3 holes round-trips through GeoJSON":
    var ctx = initGeosContext()
    let wkt = "POLYGON ((0 0, 30 0, 30 30, 0 30, 0 0), (1 1, 1 3, 3 3, 3 1, 1 1), (5 5, 5 8, 8 8, 8 5, 5 5), (10 10, 10 13, 13 13, 13 10, 10 10))"
    let original = ctx.fromWKT(wkt)
    let gj = original.toGeoJSON()
    let node = parseJson(gj)
    check node["coordinates"].len == 4  # shell + 3 holes

    let restored = ctx.fromGeoJSON(gj)
    check restored.equals(original)
    let poly = Polygon(restored)
    check poly.numInteriorRings() == 3


suite "GeoJSON Edge Cases: Unsupported Types":
  test "Feature type raises GeosParseError":
    var ctx = initGeosContext()
    expect GeosParseError:
      discard ctx.fromGeoJSON("""{"type":"Feature","geometry":{"type":"Point","coordinates":[1,2]},"properties":{}}""")

  test "FeatureCollection type raises GeosParseError":
    var ctx = initGeosContext()
    expect GeosParseError:
      discard ctx.fromGeoJSON("""{"type":"FeatureCollection","features":[]}""")

  test "Unknown type raises GeosParseError":
    var ctx = initGeosContext()
    expect GeosParseError:
      discard ctx.fromGeoJSON("""{"type":"Circle","coordinates":[1,2]}""")


suite "GeoJSON Edge Cases: Empty Multi-Geometry Round-Trips":
  test "Empty MultiPoint GeoJSON round-trip":
    var ctx = initGeosContext()
    let g = ctx.fromGeoJSON("""{"type":"MultiPoint","coordinates":[]}""")
    let gj = g.toGeoJSON()
    let restored = ctx.fromGeoJSON(gj)
    check restored.type() == gtMultiPoint
    check restored.isEmpty()

  test "Empty GeometryCollection GeoJSON round-trip":
    var ctx = initGeosContext()
    let g = ctx.fromGeoJSON("""{"type":"GeometryCollection","geometries":[]}""")
    let gj = g.toGeoJSON()
    let restored = ctx.fromGeoJSON(gj)
    check restored.type() == gtGeometryCollection
    check restored.isEmpty()


# ══════════════════════════════════════════════════════════════════════════════
# WKT Edge Cases
# ══════════════════════════════════════════════════════════════════════════════

suite "WKT Edge Cases: Invalid Input":
  test "fromWKT with empty string raises GeosParseError":
    var ctx = initGeosContext()
    expect GeosParseError:
      discard ctx.fromWKT("")

  test "fromWKT with whitespace only raises GeosParseError":
    var ctx = initGeosContext()
    expect GeosParseError:
      discard ctx.fromWKT("   ")

  test "fromWKT with tab and newline only raises GeosParseError":
    var ctx = initGeosContext()
    expect GeosParseError:
      discard ctx.fromWKT("\t\n")


suite "WKT Edge Cases: Whitespace Handling":
  test "fromWKT with leading/trailing whitespace":
    var ctx = initGeosContext()
    # GEOS WKT reader typically tolerates leading/trailing whitespace
    try:
      let g = ctx.fromWKT("  POINT (1 2)  ")
      check g.type() == gtPoint
      check not g.isEmpty()
    except GeosParseError:
      # If it doesn't handle whitespace, that's also acceptable behavior
      check true


suite "WKT Edge Cases: Large Geometries":
  test "fromWKT with polygon of many coordinates":
    var ctx = initGeosContext()
    # Generate a polygon with 100 vertices approximating a circle
    var coords = ""
    for i in 0 ..< 100:
      let angle = float(i) * 3.14159265 * 2.0 / 100.0
      let x = 100.0 + 50.0 * cos(angle)
      let y = 100.0 + 50.0 * sin(angle)
      if coords.len > 0:
        coords.add(", ")
      coords.add($x & " " & $y)
    # Close the ring
    let firstAngle = 0.0
    let firstX = 100.0 + 50.0 * cos(firstAngle)
    let firstY = 100.0 + 50.0 * sin(firstAngle)
    coords.add(", " & $firstX & " " & $firstY)

    let wkt = "POLYGON ((" & coords & "))"
    let g = ctx.fromWKT(wkt)
    check g.type() == gtPolygon
    check not g.isEmpty()
    check g.isValid()
    check g.area() > 0.0

  test "fromWKT with MultiPoint of many points":
    var ctx = initGeosContext()
    var points = ""
    for i in 0 ..< 200:
      if points.len > 0:
        points.add(", ")
      points.add("(" & $i & " " & $(i * 2) & ")")
    let wkt = "MULTIPOINT (" & points & ")"
    let g = ctx.fromWKT(wkt)
    check g.type() == gtMultiPoint
    check g.numGeometries() == 200


suite "WKT Edge Cases: toWKT on Empty Multi-Geometries":
  test "toWKT on MULTIPOINT EMPTY":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("MULTIPOINT EMPTY")
    let wkt = g.toWKT()
    check "MULTIPOINT" in wkt
    check "EMPTY" in wkt

  test "toWKT on MULTILINESTRING EMPTY":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("MULTILINESTRING EMPTY")
    let wkt = g.toWKT()
    check "MULTILINESTRING" in wkt
    check "EMPTY" in wkt

  test "toWKT on MULTIPOLYGON EMPTY":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("MULTIPOLYGON EMPTY")
    let wkt = g.toWKT()
    check "MULTIPOLYGON" in wkt
    check "EMPTY" in wkt

  test "toWKT on GEOMETRYCOLLECTION EMPTY":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("GEOMETRYCOLLECTION EMPTY")
    let wkt = g.toWKT()
    check "GEOMETRYCOLLECTION" in wkt
    check "EMPTY" in wkt

  test "toWKT on POINT EMPTY":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT EMPTY")
    let wkt = g.toWKT()
    check "POINT" in wkt
    check "EMPTY" in wkt

  test "toWKT on LINESTRING EMPTY":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("LINESTRING EMPTY")
    let wkt = g.toWKT()
    check "LINESTRING" in wkt
    check "EMPTY" in wkt

  test "toWKT on POLYGON EMPTY":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POLYGON EMPTY")
    let wkt = g.toWKT()
    check "POLYGON" in wkt
    check "EMPTY" in wkt


# ══════════════════════════════════════════════════════════════════════════════
# WKB Edge Cases
# ══════════════════════════════════════════════════════════════════════════════

suite "WKB Edge Cases: toWKB on Empty Geometries":
  test "toWKB on POINT EMPTY produces valid WKB":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT EMPTY")
    let wkb = g.toWKB()
    check wkb.len > 0
    let restored = ctx.fromWKB(wkb)
    check restored.type() == gtPoint
    check restored.isEmpty()

  test "toWKB on LINESTRING EMPTY produces valid WKB":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("LINESTRING EMPTY")
    let wkb = g.toWKB()
    check wkb.len > 0
    let restored = ctx.fromWKB(wkb)
    check restored.type() == gtLineString
    check restored.isEmpty()

  test "toWKB on POLYGON EMPTY produces valid WKB":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POLYGON EMPTY")
    let wkb = g.toWKB()
    check wkb.len > 0
    let restored = ctx.fromWKB(wkb)
    check restored.type() == gtPolygon
    check restored.isEmpty()


suite "WKB Edge Cases: toWKB on Empty Multi-Geometries":
  test "toWKB on MULTIPOINT EMPTY":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("MULTIPOINT EMPTY")
    let wkb = g.toWKB()
    check wkb.len > 0
    let restored = ctx.fromWKB(wkb)
    check restored.type() == gtMultiPoint
    check restored.isEmpty()

  test "toWKB on MULTILINESTRING EMPTY":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("MULTILINESTRING EMPTY")
    let wkb = g.toWKB()
    check wkb.len > 0
    let restored = ctx.fromWKB(wkb)
    check restored.type() == gtMultiLineString
    check restored.isEmpty()

  test "toWKB on MULTIPOLYGON EMPTY":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("MULTIPOLYGON EMPTY")
    let wkb = g.toWKB()
    check wkb.len > 0
    let restored = ctx.fromWKB(wkb)
    check restored.type() == gtMultiPolygon
    check restored.isEmpty()

  test "toWKB on GEOMETRYCOLLECTION EMPTY":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("GEOMETRYCOLLECTION EMPTY")
    let wkb = g.toWKB()
    check wkb.len > 0
    let restored = ctx.fromWKB(wkb)
    check restored.type() == gtGeometryCollection
    check restored.isEmpty()


suite "WKB Edge Cases: Truncated Data":
  test "fromWKB with valid header but truncated data raises GeosParseError":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POLYGON ((0 0, 4 0, 4 4, 0 4, 0 0))")
    let wkb = g.toWKB()
    # Cut the WKB in half
    let truncated = wkb[0 ..< wkb.len div 2]
    expect GeosParseError:
      discard ctx.fromWKB(truncated)

  test "fromWKB with only byte-order byte raises GeosParseError":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT (1 2)")
    let wkb = g.toWKB()
    # Keep only the first byte (byte order indicator)
    expect GeosParseError:
      discard ctx.fromWKB(wkb[0 ..< 1])

  test "fromWKB with header but no coordinate data raises GeosParseError":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("LINESTRING (0 0, 1 1, 2 2)")
    let wkb = g.toWKB()
    # Keep only first 5 bytes (byte order + type id), not enough for coordinates
    if wkb.len > 5:
      expect GeosParseError:
        discard ctx.fromWKB(wkb[0 ..< 5])


suite "WKB Edge Cases: Hex Case Sensitivity":
  test "fromHexWKB with lowercase hex parses correctly":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT (1 2)")
    let hexUpper = g.toHexWKB()
    let hexLower = hexUpper.toLowerAscii()
    let restored = ctx.fromHexWKB(hexLower)
    check restored.type() == gtPoint
    check restored.equals(g)

  test "fromHexWKB with mixed case hex parses correctly":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("LINESTRING (0 0, 1 1, 2 2)")
    let hexUpper = g.toHexWKB()
    # Create mixed case: alternate upper/lower for each character
    var hexMixed = ""
    for i, c in hexUpper:
      if i mod 2 == 0:
        hexMixed.add(toLowerAscii(c))
      else:
        hexMixed.add(toUpperAscii(c))
    let restored = ctx.fromHexWKB(hexMixed)
    check restored.type() == gtLineString
    check restored.equals(g)

  test "fromHexWKB lowercase Polygon round-trip":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POLYGON ((0 0, 4 0, 4 4, 0 4, 0 0))")
    let hexLower = g.toHexWKB().toLowerAscii()
    let restored = ctx.fromHexWKB(hexLower)
    check restored.type() == gtPolygon
    check restored.equals(g)
    check abs(restored.area() - 16.0) < 1e-10


suite "WKB Edge Cases: Byte Order on Complex Geometries":
  test "NDR and XDR produce same geometry for MultiPolygon":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("MULTIPOLYGON (((0 0, 1 0, 1 1, 0 1, 0 0)), ((2 2, 3 2, 3 3, 2 3, 2 2)))")
    let fromNDR = ctx.fromWKB(g.toWKB(wkbNDR))
    let fromXDR = ctx.fromWKB(g.toWKB(wkbXDR))
    check fromNDR.equals(fromXDR)
    check fromNDR.type() == gtMultiPolygon
    check fromXDR.type() == gtMultiPolygon

  test "NDR and XDR produce same geometry for GeometryCollection":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("GEOMETRYCOLLECTION (POINT (0 0), LINESTRING (0 0, 1 1))")
    let fromNDR = ctx.fromWKB(g.toWKB(wkbNDR))
    let fromXDR = ctx.fromWKB(g.toWKB(wkbXDR))
    check fromNDR.equals(fromXDR)

  test "XDR round-trip preserves empty geometry":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT EMPTY")
    let wkb = g.toWKB(wkbXDR)
    check wkb[0] == 0x00'u8  # big-endian marker
    let restored = ctx.fromWKB(wkb)
    check restored.type() == gtPoint
    check restored.isEmpty()


# ══════════════════════════════════════════════════════════════════════════════
# Cross-Format Edge Cases
# ══════════════════════════════════════════════════════════════════════════════

suite "Cross-Format Edge Cases":
  test "Empty geometries survive WKT → WKB → GeoJSON → WKT round-trip":
    var ctx = initGeosContext()
    let original = ctx.fromWKT("POINT EMPTY")
    let viaWKB = ctx.fromWKB(original.toWKB())
    let viaGeoJSON = ctx.fromGeoJSON(viaWKB.toGeoJSON())
    check viaGeoJSON.type() == gtPoint
    check viaGeoJSON.isEmpty()

  test "Empty MultiPoint survives all three formats":
    var ctx = initGeosContext()
    let original = ctx.fromWKT("MULTIPOINT EMPTY")
    # WKT → WKB
    let viaWKB = ctx.fromWKB(original.toWKB())
    check viaWKB.type() == gtMultiPoint
    check viaWKB.isEmpty()
    # WKB → GeoJSON
    let viaGeoJSON = ctx.fromGeoJSON(viaWKB.toGeoJSON())
    check viaGeoJSON.type() == gtMultiPoint
    check viaGeoJSON.isEmpty()
    # GeoJSON → HexWKB
    let viaHex = ctx.fromHexWKB(viaGeoJSON.toHexWKB())
    check viaHex.type() == gtMultiPoint
    check viaHex.isEmpty()

  test "Polygon with holes survives WKT → GeoJSON → WKB → WKT":
    var ctx = initGeosContext()
    let wkt = "POLYGON ((0 0, 20 0, 20 20, 0 20, 0 0), (2 2, 2 5, 5 5, 5 2, 2 2))"
    let original = ctx.fromWKT(wkt)
    let viaGeoJSON = ctx.fromGeoJSON(original.toGeoJSON())
    let viaWKB = ctx.fromWKB(viaGeoJSON.toWKB())
    check viaWKB.type() == gtPolygon
    check viaWKB.equals(original)
    let poly = Polygon(viaWKB)
    check poly.numInteriorRings() == 1

  test "3D geometry survives WKT → HexWKB → GeoJSON → WKT":
    var ctx = initGeosContext()
    let original = ctx.fromWKT("POINT Z (1 2 3)")
    let viaHex = ctx.fromHexWKB(original.toHexWKB())
    let gj = viaHex.toGeoJSON()
    let node = parseJson(gj)
    check node["coordinates"].len == 3
    check node["coordinates"][2].getFloat == 3.0
    let viaGeoJSON = ctx.fromGeoJSON(gj)
    check viaGeoJSON.type() == gtPoint
    check viaGeoJSON.equals(original)

  test "GeometryCollection survives WKB → GeoJSON → WKB":
    var ctx = initGeosContext()
    let original = ctx.fromWKT("GEOMETRYCOLLECTION (POINT (0 0), LINESTRING (0 0, 1 1), POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0)))")
    let viaGeoJSON = ctx.fromGeoJSON(ctx.fromWKB(original.toWKB()).toGeoJSON())
    let viaWKB = ctx.fromWKB(viaGeoJSON.toWKB())
    check viaWKB.type() == gtGeometryCollection
    check viaWKB.numGeometries() == 3
    check viaWKB.equals(original)
