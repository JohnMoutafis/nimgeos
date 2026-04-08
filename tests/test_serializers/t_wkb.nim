import unittest
import std/strformat
import nimgeos

# ── Test data ─────────────────────────────────────────────────────────────────
const geomTypeCases: array[15, (string, string, GeomType)] = [
  ("POINT EMPTY", "Point Empty", gtPoint),
  ("POINT (1 2)", "Point 2D", gtPoint),
  ("POINT (1 2 3)", "Point 3D", gtPoint),
  ("LINESTRING (0 0, 1 1, 2 2)", "LineString 2D", gtLineString),
  ("LINESTRING (0 0 0, 1 1 1, 2 2 2)", "LineString 3D", gtLineString),
  ("POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))", "Polygon 2D", gtPolygon),
  ("POLYGON ((0 0 0, 1 0 1, 1 1 0, 0 1 1, 0 0 0))", "Polygon 3D", gtPolygon),
  ("MULTIPOINT ((0 0), (1 1))", "MultiPoint 2D", gtMultiPoint),
  ("MULTIPOINT ((0 0 0), (1 1 1))", "MultiPoint 3D", gtMultiPoint),
  ("MULTILINESTRING ((0 0, 1 1), (2 2, 3 3))", "MultiLineString 2D", gtMultiLineString),
  ("MULTILINESTRING ((0 0 0, 1 1 1), (2 2 2, 3 3 3))", "MultiLineString 3D", gtMultiLineString),
  ("MULTIPOLYGON (((0 0, 1 0, 1 1, 0 1, 0 0)), ((2 2, 3 2, 3 3, 2 3, 2 2)))",
    "MultiPolygon 2D", gtMultiPolygon),
  ("MULTIPOLYGON (((0 0 0, 1 0 1, 1 1 0, 0 1 1, 0 0 0)), ((2 2 0, 3 2 1, 3 3 0, 2 3 1, 2 2 0)))",
    "MultiPolygon 3D", gtMultiPolygon),
  ("GEOMETRYCOLLECTION (POINT (0 0), LINESTRING (0 0, 1 1))", "GeometryCollection 2D", gtGeometryCollection),
  ("GEOMETRYCOLLECTION (POINT (0 0 0), LINESTRING (0 0 0, 1 1 1))", "GeometryCollection 3D", gtGeometryCollection),
]

# ── WKB Round-trip via WKT ────────────────────────────────────────────────────

suite "WKB Round-trip via WKT":
  for (wkt, testCase, kind) in geomTypeCases:
    test &"Round-trip preserves GeomType: {testCase}":
      var ctx = initGeosContext()
      let original = ctx.fromWKT(wkt)
      let restored = ctx.fromWKB(original.toWKB())
      check restored.type() == kind
      if not original.isEmpty():
        check original.toWKT() == restored.toWKT()

# ── WKB property preservation ─────────────────────────────────────────────────

suite "WKB property preservation":
  for (wkt, testCase, kind) in geomTypeCases:
    test &"Properties preserved: {testCase}":
      var ctx = initGeosContext()
      let original = ctx.fromWKT(wkt)
      let restored = ctx.fromWKB(original.toWKB())
      check restored.isEmpty()        == original.isEmpty()
      check restored.isValid()        == original.isValid()
      check restored.numCoordinates() == original.numCoordinates()

# ── WKB Byte order ────────────────────────────────────────────────────────────

suite "WKB Byte order":
  test "NDR: first byte is 0x01":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT (1 2)")
    check g.toWKB(wkbNDR)[0] == 0x01'u8

  test "XDR: first byte is 0x00":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT (1 2)")
    check g.toWKB(wkbXDR)[0] == 0x00'u8

  test "NDR output is parseable and preserves type":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT (1 2)")
    let restored = ctx.fromWKB(g.toWKB(wkbNDR))
    check restored.type() == gtPoint

  test "XDR output is parseable and preserves type":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT (1 2)")
    let restored = ctx.fromWKB(g.toWKB(wkbXDR))
    check restored.type() == gtPoint

  test "NDR and XDR produce equal geometries":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POLYGON ((0 0, 4 0, 4 4, 0 4, 0 0))")
    let fromNDR = ctx.fromWKB(g.toWKB(wkbNDR))
    let fromXDR = ctx.fromWKB(g.toWKB(wkbXDR))
    check fromNDR.equals(fromXDR)

  test "NDR and XDR byte sequences differ":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POLYGON ((0 0, 4 0, 4 4, 0 4, 0 0))")
    check g.toWKB(wkbNDR) != g.toWKB(wkbXDR)

# ── Hex WKB ───────────────────────────────────────────────────────────────────

suite "Hex WKB":
  test "hex round-trip: Point":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT (1 2)")
    check ctx.fromHexWKB(g.toHexWKB()).toWKT() == g.toWKT()

  test "hex round-trip: Polygon":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POLYGON ((0 0, 4 0, 4 4, 0 4, 0 0))")
    check ctx.fromHexWKB(g.toHexWKB()).toWKT() == g.toWKT()

  test "hex round-trip: MultiPoint":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("MULTIPOINT ((0 0), (1 1))")
    check ctx.fromHexWKB(g.toHexWKB()).toWKT() == g.toWKT()

  test "hex output is uppercase":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT (1 2)")
    let hex = g.toHexWKB()
    for c in hex:
      check c in {'0'..'9', 'A'..'F'}

  test "hex output length equals 2 × byte length":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POLYGON ((0 0, 4 0, 4 4, 0 4, 0 0))")
    check g.toHexWKB().len == 2 * g.toWKB().len

  test "empty hex string raises GeosParseError":
    var ctx = initGeosContext()
    expect GeosParseError:
      discard ctx.fromHexWKB("")

  test "odd-length hex string raises GeosParseError":
    var ctx = initGeosContext()
    expect GeosParseError:
      discard ctx.fromHexWKB("ABC")

  test "invalid hex characters raise GeosParseError":
    var ctx = initGeosContext()
    expect GeosParseError:
      discard ctx.fromHexWKB("ZZZZ")

# ── WKB Deserialization errors ────────────────────────────────────────────────

suite "WKB Deserialization errors":
  test "empty byte seq raises GeosParseError":
    var ctx = initGeosContext()
    expect GeosParseError:
      discard ctx.fromWKB(newSeq[byte]())

  test "single byte raises GeosParseError":
    var ctx = initGeosContext()
    expect GeosParseError:
      discard ctx.fromWKB(@[0x01'u8])

  test "random garbage bytes raise GeosParseError":
    var ctx = initGeosContext()
    expect GeosParseError:
      discard ctx.fromWKB(@[0xFF'u8, 0xFE, 0xFD, 0xFC])

  test "nil geometry toWKB raises GeosGeomError":
    var g: Geometry
    expect GeosGeomError:
      discard g.toWKB()

  test "nil geometry toHexWKB raises GeosGeomError":
    var g: Geometry
    expect GeosGeomError:
      discard g.toHexWKB()

# ── WKB/WKT cross-format ──────────────────────────────────────────────────────

suite "WKB/WKT cross-format":
  test "WKT→WKB→WKT round-trip equals WKT identity":
    var ctx = initGeosContext()
    let wkt = "POLYGON ((0 0, 4 0, 4 4, 0 4, 0 0))"
    let via_wkb = ctx.fromWKB(ctx.fromWKT(wkt).toWKB()).toWKT()
    let direct  = ctx.fromWKT(wkt).toWKT()
    check via_wkb == direct

  test "two independent WKT→WKB→fromWKB geometries are equal":
    var ctx = initGeosContext()
    let wkt = "LINESTRING (0 0, 1 1, 2 2)"
    let a = ctx.fromWKB(ctx.fromWKT(wkt).toWKB())
    let b = ctx.fromWKB(ctx.fromWKT(wkt).toWKB())
    check a.equals(b)

  test "toWKB output length is greater than 0 for non-empty geometry":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT (1 2)")
    check g.toWKB().len > 0

  test "area is preserved across WKB serialization":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT("POLYGON ((0 0, 4 0, 4 4, 0 4, 0 0))")
    let restored = ctx.fromWKB(poly.toWKB())
    check abs(poly.area() - restored.area()) < 1e-10

  test "spatial predicates work on WKB-deserialized geometries":
    var ctx = initGeosContext()
    let poly  = ctx.fromWKB(ctx.fromWKT("POLYGON ((0 0, 4 0, 4 4, 0 4, 0 0))").toWKB())
    let point = ctx.fromWKB(ctx.fromWKT("POINT (2 2)").toWKB())
    check poly.contains(point)
