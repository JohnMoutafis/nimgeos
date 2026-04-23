import unittest
import std/json
import nimgeos


# ── Round-trip tests ──────────────────────────────────────────────────────────

suite "GeoJSON Round-trip":
  test "Round-trip Point":
    var ctx = initGeosContext()
    let original = ctx.fromWKT("POINT (1.5 2.5)")
    let restored = ctx.fromGeoJSON(original.toGeoJSON())
    check restored.type() == gtPoint
    check restored.equals(original)

  test "Round-trip LineString":
    var ctx = initGeosContext()
    let original = ctx.fromWKT("LINESTRING (0 0, 1 1, 2 2)")
    let restored = ctx.fromGeoJSON(original.toGeoJSON())
    check restored.type() == gtLineString
    check restored.equals(original)

  test "Round-trip Polygon":
    var ctx = initGeosContext()
    let original = ctx.fromWKT("POLYGON ((0 0, 4 0, 4 4, 0 4, 0 0))")
    let restored = ctx.fromGeoJSON(original.toGeoJSON())
    check restored.type() == gtPolygon
    check restored.equals(original)

  test "Round-trip MultiPoint":
    var ctx = initGeosContext()
    let original = ctx.fromWKT("MULTIPOINT ((0 0), (1 1), (2 2))")
    let restored = ctx.fromGeoJSON(original.toGeoJSON())
    check restored.type() == gtMultiPoint
    check restored.equals(original)

  test "Round-trip MultiLineString":
    var ctx = initGeosContext()
    let original = ctx.fromWKT("MULTILINESTRING ((0 0, 1 1), (2 2, 3 3))")
    let restored = ctx.fromGeoJSON(original.toGeoJSON())
    check restored.type() == gtMultiLineString
    check restored.equals(original)

  test "Round-trip MultiPolygon":
    var ctx = initGeosContext()
    let original = ctx.fromWKT("MULTIPOLYGON (((0 0, 1 0, 1 1, 0 1, 0 0)), ((2 2, 3 2, 3 3, 2 3, 2 2)))")
    let restored = ctx.fromGeoJSON(original.toGeoJSON())
    check restored.type() == gtMultiPolygon
    check restored.equals(original)

  test "Round-trip GeometryCollection":
    var ctx = initGeosContext()
    let original = ctx.fromWKT("GEOMETRYCOLLECTION (POINT (0 0), LINESTRING (0 0, 1 1))")
    let restored = ctx.fromGeoJSON(original.toGeoJSON())
    check restored.type() == gtGeometryCollection
    check restored.equals(original)


# ── Serialization structure tests ─────────────────────────────────────────────

suite "GeoJSON Serialization structure":
  test "Point JSON has correct type and coordinates":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT (1 2)")
    let node = parseJson(g.toGeoJSON())
    check node["type"].getStr == "Point"
    check node["coordinates"].kind == JArray
    check node["coordinates"].len == 2
    check node["coordinates"][0].getFloat == 1.0
    check node["coordinates"][1].getFloat == 2.0

  test "LineString JSON has correct structure":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("LINESTRING (0 0, 1 1, 2 2)")
    let node = parseJson(g.toGeoJSON())
    check node["type"].getStr == "LineString"
    check node["coordinates"].kind == JArray
    check node["coordinates"].len == 3
    check node["coordinates"][0][0].getFloat == 0.0
    check node["coordinates"][2][1].getFloat == 2.0

  test "Polygon JSON has correct ring structure":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POLYGON ((0 0, 4 0, 4 4, 0 4, 0 0))")
    let node = parseJson(g.toGeoJSON())
    check node["type"].getStr == "Polygon"
    check node["coordinates"].kind == JArray
    check node["coordinates"].len == 1  # one ring (shell)
    check node["coordinates"][0].len == 5  # 5 points (closed)

  test "MultiPoint JSON has correct structure":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("MULTIPOINT ((0 0), (1 1))")
    let node = parseJson(g.toGeoJSON())
    check node["type"].getStr == "MultiPoint"
    check node["coordinates"].len == 2

  test "MultiLineString JSON has correct structure":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("MULTILINESTRING ((0 0, 1 1), (2 2, 3 3))")
    let node = parseJson(g.toGeoJSON())
    check node["type"].getStr == "MultiLineString"
    check node["coordinates"].len == 2
    check node["coordinates"][0].len == 2

  test "MultiPolygon JSON has correct structure":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("MULTIPOLYGON (((0 0, 1 0, 1 1, 0 1, 0 0)), ((2 2, 3 2, 3 3, 2 3, 2 2)))")
    let node = parseJson(g.toGeoJSON())
    check node["type"].getStr == "MultiPolygon"
    check node["coordinates"].len == 2
    check node["coordinates"][0].len == 1  # one ring per polygon

  test "GeometryCollection JSON uses 'geometries' array":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("GEOMETRYCOLLECTION (POINT (0 0), LINESTRING (0 0, 1 1))")
    let node = parseJson(g.toGeoJSON())
    check node["type"].getStr == "GeometryCollection"
    check node.hasKey("geometries")
    check node["geometries"].len == 2
    check node["geometries"][0]["type"].getStr == "Point"
    check node["geometries"][1]["type"].getStr == "LineString"


# ── 3D geometry tests ─────────────────────────────────────────────────────────

suite "GeoJSON 3D geometries":
  test "3D Point round-trip preserves Z":
    var ctx = initGeosContext()
    let original = ctx.fromWKT("POINT (1 2 3)")
    let geoJson = original.toGeoJSON()
    let node = parseJson(geoJson)
    check node["coordinates"].len == 3
    check node["coordinates"][2].getFloat == 3.0
    let restored = ctx.fromGeoJSON(geoJson)
    check restored.type() == gtPoint
    check restored.equals(original)

  test "3D LineString round-trip":
    var ctx = initGeosContext()
    let original = ctx.fromWKT("LINESTRING (0 0 0, 1 1 1, 2 2 2)")
    let geoJson = original.toGeoJSON()
    let node = parseJson(geoJson)
    # Check all coordinates have Z
    for coord in node["coordinates"]:
      check coord.len == 3
    let restored = ctx.fromGeoJSON(geoJson)
    check restored.type() == gtLineString
    check restored.equals(original)

  test "3D Polygon round-trip":
    var ctx = initGeosContext()
    let original = ctx.fromWKT("POLYGON ((0 0 1, 4 0 1, 4 4 1, 0 4 1, 0 0 1))")
    let geoJson = original.toGeoJSON()
    let node = parseJson(geoJson)
    for coord in node["coordinates"][0]:
      check coord.len == 3
    let restored = ctx.fromGeoJSON(geoJson)
    check restored.type() == gtPolygon
    check restored.equals(original)


# ── Deserialization error tests ───────────────────────────────────────────────

suite "GeoJSON Deserialization errors":
  test "Invalid JSON raises GeosParseError":
    var ctx = initGeosContext()
    expect GeosParseError:
      discard ctx.fromGeoJSON("{not valid json}")

  test "Missing type field raises GeosParseError":
    var ctx = initGeosContext()
    expect GeosParseError:
      discard ctx.fromGeoJSON("""{"coordinates": [1, 2]}""")

  test "Unsupported type raises GeosParseError":
    var ctx = initGeosContext()
    expect GeosParseError:
      discard ctx.fromGeoJSON("""{"type": "Feature", "coordinates": [1, 2]}""")

  test "Missing coordinates raises GeosParseError":
    var ctx = initGeosContext()
    expect GeosParseError:
      discard ctx.fromGeoJSON("""{"type": "Point"}""")

  test "Non-object input raises GeosParseError":
    var ctx = initGeosContext()
    expect GeosParseError:
      discard ctx.fromGeoJSON("[]")

  test "Nil geometry toGeoJSON raises GeosGeomError":
    var g: Geometry
    expect GeosGeomError:
      discard g.toGeoJSON()

  test "Empty string raises GeosParseError":
    var ctx = initGeosContext()
    expect GeosParseError:
      discard ctx.fromGeoJSON("")


# ── Cross-format tests ────────────────────────────────────────────────────────

suite "GeoJSON Cross-format":
  test "WKT → GeoJSON → WKT round-trip":
    var ctx = initGeosContext()
    let wkt = "POLYGON ((0 0, 4 0, 4 4, 0 4, 0 0))"
    let viaGeoJson = ctx.fromGeoJSON(ctx.fromWKT(wkt).toGeoJSON()).toWKT()
    let direct = ctx.fromWKT(wkt).toWKT()
    check viaGeoJson == direct

  test "WKB → GeoJSON → WKB geometries are equal":
    var ctx = initGeosContext()
    let original = ctx.fromWKT("LINESTRING (0 0, 1 1, 2 2)")
    let viaGeoJson = ctx.fromGeoJSON(original.toGeoJSON())
    let viaWkb = ctx.fromWKB(original.toWKB())
    check viaGeoJson.equals(viaWkb)

  test "GeoJSON → WKT → GeoJSON type preserved":
    var ctx = initGeosContext()
    let json = """{"type":"Point","coordinates":[3.14,2.72]}"""
    let g = ctx.fromGeoJSON(json)
    let viaWkt = ctx.fromWKT(g.toWKT())
    check viaWkt.type() == gtPoint
    let restoredJson = parseJson(viaWkt.toGeoJSON())
    check restoredJson["type"].getStr == "Point"

  test "Area preserved across GeoJSON serialization":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT("POLYGON ((0 0, 4 0, 4 4, 0 4, 0 0))")
    let restored = ctx.fromGeoJSON(poly.toGeoJSON())
    check abs(poly.area() - restored.area()) < 1e-10

  test "Spatial predicates work on GeoJSON-deserialized geometries":
    var ctx = initGeosContext()
    let poly = ctx.fromGeoJSON(ctx.fromWKT("POLYGON ((0 0, 4 0, 4 4, 0 4, 0 0))").toGeoJSON())
    let point = ctx.fromGeoJSON(ctx.fromWKT("POINT (2 2)").toGeoJSON())
    check poly.contains(point)

  test "All three formats agree: WKT → WKB, WKT → GeoJSON":
    var ctx = initGeosContext()
    let wkt = "MULTIPOINT ((0 0), (1 1), (2 2))"
    let fromWkt = ctx.fromWKT(wkt)
    let fromWkb = ctx.fromWKB(fromWkt.toWKB())
    let fromGeoJson = ctx.fromGeoJSON(fromWkt.toGeoJSON())
    check fromWkb.equals(fromGeoJson)


# ── Edge cases ────────────────────────────────────────────────────────────────

suite "GeoJSON Edge cases":
  test "Empty Point serialization":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT EMPTY")
    let node = parseJson(g.toGeoJSON())
    check node["type"].getStr == "Point"
    check node["coordinates"].len == 0

  test "Empty Polygon serialization":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POLYGON EMPTY")
    let node = parseJson(g.toGeoJSON())
    check node["type"].getStr == "Polygon"
    check node["coordinates"].len == 0

  test "Polygon with hole round-trip":
    var ctx = initGeosContext()
    let wkt = "POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0), (2 2, 2 4, 4 4, 4 2, 2 2))"
    let original = ctx.fromWKT(wkt)
    let geoJson = original.toGeoJSON()
    let node = parseJson(geoJson)
    check node["coordinates"].len == 2  # shell + 1 hole
    let restored = ctx.fromGeoJSON(geoJson)
    check restored.type() == gtPolygon
    check restored.equals(original)

  test "Integer coordinates in GeoJSON are accepted":
    var ctx = initGeosContext()
    let json = """{"type":"Point","coordinates":[1,2]}"""
    let g = ctx.fromGeoJSON(json)
    check g.type() == gtPoint

  test "Coordinates with many decimal places":
    var ctx = initGeosContext()
    let json = """{"type":"Point","coordinates":[1.123456789012345,2.987654321098765]}"""
    let g = ctx.fromGeoJSON(json)
    check g.type() == gtPoint
