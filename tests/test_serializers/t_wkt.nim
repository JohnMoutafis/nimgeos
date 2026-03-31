import unittest
import std/strformat
import nimgeos

# ── WKT Deserialization test data ─────────────────────────────────────────────
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

const invalidWktCases: array[3, string] = [
  "NOT VALID WKT",
  "PONT (1 2)",
  "LINESTRING NO COORDS",
]

suite "WKT Deserialization":
  # ── GeomType resolution ───────────────────────────────────────────────────────
  for (wkt, testCase, kind) in geomTypeCases:
    test &"GeomType: {$testCase}":
      var ctx = initGeosContext()
      let g = ctx.fromWKT(wkt)
      check g.type() == kind

  # ── invalid WKT raises GeosParseError ────────────────────────────────────────
  for wkt in invalidWktCases:
    test &"Invalid WKT raises GeosParseError: \"{wkt}\"":
      var ctx = initGeosContext()
      expect GeosParseError:
        discard ctx.fromWKT(wkt)


# ── WKT Serialization test data ──────────────────────────────────────────────
const toWktCases: array[15, (string, string, string)] = [
  ("POINT EMPTY", "Point EMPTY", "POINT EMPTY"),
  ("POINT (1 2)", "Point 2D", "POINT (1 2)"),
  ("POINT (1 2 3)", "Point 3D", "POINT Z (1 2 3)"),
  ("LINESTRING (0 0, 1 1, 2 2)", "LineString 2D", "LINESTRING (0 0, 1 1, 2 2)"),
  ("LINESTRING (0 0 0, 1 1 1, 2 2 2)", "LineString 3D", "LINESTRING Z (0 0 0, 1 1 1, 2 2 2)"),
  ("POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))", "Polygon 2D", "POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))"),
  ("POLYGON ((0 0 0, 1 0 1, 1 1 0, 0 1 1, 0 0 0))", "Polygon 3D", "POLYGON Z ((0 0 0, 1 0 1, 1 1 0, 0 1 1, 0 0 0))"),
  ("MULTIPOINT ((0 0), (1 1))", "MultiPoint 2D", "MULTIPOINT ((0 0), (1 1))"),
  ("MULTIPOINT ((0 0 0), (1 1 1))", "MultiPoint 3D", "MULTIPOINT Z ((0 0 0), (1 1 1))"),
  ("MULTILINESTRING ((0 0, 1 1), (2 2, 3 3))", "MultiLineString 2D", "MULTILINESTRING ((0 0, 1 1), (2 2, 3 3))"),
  ("MULTILINESTRING ((0 0 0, 1 1 1), (2 2 2, 3 3 3))", "MultiLineString 3D",
    "MULTILINESTRING Z ((0 0 0, 1 1 1), (2 2 2, 3 3 3))"),
  ("MULTIPOLYGON (((0 0, 1 0, 1 1, 0 1, 0 0)), ((2 2, 3 2, 3 3, 2 3, 2 2)))", "MultiPolygon 2D",
   "MULTIPOLYGON (((0 0, 1 0, 1 1, 0 1, 0 0)), ((2 2, 3 2, 3 3, 2 3, 2 2)))"),
  ("MULTIPOLYGON (((0 0 0, 1 0 1, 1 1 1, 0 1 0, 0 0 0)), ((2 2 1, 3 2 1, 3 3 2, 2 3 2, 2 2 1)))", "MultiPolygon 3D",
    "MULTIPOLYGON Z (((0 0 0, 1 0 1, 1 1 1, 0 1 0, 0 0 0)), ((2 2 1, 3 2 1, 3 3 2, 2 3 2, 2 2 1)))"),
  ("GEOMETRYCOLLECTION (POINT (0 0), LINESTRING (0 0, 1 1))", "GeometryCollection 2D",
    "GEOMETRYCOLLECTION (POINT (0 0), LINESTRING (0 0, 1 1))"),
  ("GEOMETRYCOLLECTION (POINT (0 0 1), LINESTRING (0 0 0, 1 1 1))", "GeometryCollection 3D",
   "GEOMETRYCOLLECTION Z (POINT Z (0 0 1), LINESTRING Z (0 0 0, 1 1 1))"),
]

suite "WKT Serialization":
  # ── Round trip: fromWKT -> toWKT ─────────────────-------
  for (inputWkt, testCase, expected) in toWktCases:
    test &"toWKT: {testCase}":
      var ctx = initGeosContext()
      let g = ctx.fromWKT(inputWkt)
      check g.toWKT() == expected

  test "toWKT: Raises GeosGeomError on nil Geometry":
    var g: Geometry
    expect GeosGeomError:
      discard g.toWKT()
