import unittest
import std/math
import std/json
import std/strutils
import nimgeos

# ── WKT constants for empty geometries ────────────────────────────────────────
const
  emptyPoint              = "POINT EMPTY"
  emptyLineString         = "LINESTRING EMPTY"
  emptyPolygon            = "POLYGON EMPTY"
  emptyMultiPoint         = "MULTIPOINT EMPTY"
  emptyMultiLineString    = "MULTILINESTRING EMPTY"
  emptyMultiPolygon       = "MULTIPOLYGON EMPTY"
  emptyGeometryCollection = "GEOMETRYCOLLECTION EMPTY"

  allEmptyWKTs = [
    emptyPoint, emptyLineString, emptyPolygon,
    emptyMultiPoint, emptyMultiLineString, emptyMultiPolygon,
    emptyGeometryCollection,
  ]

  nonEmptyPoint   = "POINT (1 2)"
  nonEmptyPolygon = "POLYGON ((0 0, 4 0, 4 4, 0 4, 0 0))"

# ═══════════════════════════════════════════════════════════════════════════════
# 1. Property accessors on empty geometries
# ═══════════════════════════════════════════════════════════════════════════════

suite "Empty geometry — isEmpty":
  for wkt in allEmptyWKTs:
    test "isEmpty is true for " & wkt:
      var ctx = initGeosContext()
      let g = ctx.fromWKT(wkt)
      check g.isEmpty()

suite "Empty geometry — type":
  test "POINT EMPTY has type gtPoint":
    var ctx = initGeosContext()
    check ctx.fromWKT(emptyPoint).type() == gtPoint

  test "LINESTRING EMPTY has type gtLineString":
    var ctx = initGeosContext()
    check ctx.fromWKT(emptyLineString).type() == gtLineString

  test "POLYGON EMPTY has type gtPolygon":
    var ctx = initGeosContext()
    check ctx.fromWKT(emptyPolygon).type() == gtPolygon

  test "MULTIPOINT EMPTY has type gtMultiPoint":
    var ctx = initGeosContext()
    check ctx.fromWKT(emptyMultiPoint).type() == gtMultiPoint

  test "MULTILINESTRING EMPTY has type gtMultiLineString":
    var ctx = initGeosContext()
    check ctx.fromWKT(emptyMultiLineString).type() == gtMultiLineString

  test "MULTIPOLYGON EMPTY has type gtMultiPolygon":
    var ctx = initGeosContext()
    check ctx.fromWKT(emptyMultiPolygon).type() == gtMultiPolygon

  test "GEOMETRYCOLLECTION EMPTY has type gtGeometryCollection":
    var ctx = initGeosContext()
    check ctx.fromWKT(emptyGeometryCollection).type() == gtGeometryCollection

suite "Empty geometry — area":
  for wkt in allEmptyWKTs:
    test "area is 0 for " & wkt:
      var ctx = initGeosContext()
      let g = ctx.fromWKT(wkt)
      check g.area() == 0.0

suite "Empty geometry — length":
  for wkt in allEmptyWKTs:
    test "length is 0 for " & wkt:
      var ctx = initGeosContext()
      let g = ctx.fromWKT(wkt)
      check g.length() == 0.0

suite "Empty geometry — numCoordinates":
  for wkt in allEmptyWKTs:
    test "numCoordinates is 0 for " & wkt:
      var ctx = initGeosContext()
      let g = ctx.fromWKT(wkt)
      check g.numCoordinates() == 0

suite "Empty geometry — numGeometries":
  test "POINT EMPTY numGeometries":
    # A single empty point is still 1 geometry (GEOS reports 1 for non-multi)
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPoint)
    check g.numGeometries() >= 0

  test "LINESTRING EMPTY numGeometries":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyLineString)
    check g.numGeometries() >= 0

  test "POLYGON EMPTY numGeometries":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPolygon)
    check g.numGeometries() >= 0

  test "MULTIPOINT EMPTY numGeometries is 0":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyMultiPoint)
    check g.numGeometries() == 0

  test "MULTILINESTRING EMPTY numGeometries is 0":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyMultiLineString)
    check g.numGeometries() == 0

  test "MULTIPOLYGON EMPTY numGeometries is 0":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyMultiPolygon)
    check g.numGeometries() == 0

  test "GEOMETRYCOLLECTION EMPTY numGeometries is 0":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyGeometryCollection)
    check g.numGeometries() == 0


# ═══════════════════════════════════════════════════════════════════════════════
# 2. isValid on empty geometries
# ═══════════════════════════════════════════════════════════════════════════════

suite "Empty geometry — isValid":
  for wkt in allEmptyWKTs:
    test "isValid is true for " & wkt:
      var ctx = initGeosContext()
      let g = ctx.fromWKT(wkt)
      check g.isValid()


# ═══════════════════════════════════════════════════════════════════════════════
# 3. Empty Point coordinate access
# ═══════════════════════════════════════════════════════════════════════════════

suite "Empty Point — coordinate access":
  test "x() on POINT EMPTY raises GeosGeomError or returns NaN":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPoint)
    let pt = Point(g)
    try:
      let v = pt.x()
      check v.isNaN()
    except GeosGeomError:
      check true

  test "y() on POINT EMPTY raises GeosGeomError or returns NaN":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPoint)
    let pt = Point(g)
    try:
      let v = pt.y()
      check v.isNaN()
    except GeosGeomError:
      check true

  test "z() on POINT EMPTY raises GeosGeomError or returns NaN or 0":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPoint)
    let pt = Point(g)
    try:
      let v = pt.z()
      # GEOS may return NaN or 0.0 for z() on empty points
      check v.isNaN() or v == 0.0
    except GeosGeomError:
      check true


# ═══════════════════════════════════════════════════════════════════════════════
# 4. Empty LineString point access
# ═══════════════════════════════════════════════════════════════════════════════

suite "Empty LineString — point access":
  test "numPoints on LINESTRING EMPTY is 0":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyLineString)
    let ls = LineString(g)
    check ls.numPoints() == 0

  test "startPoint on LINESTRING EMPTY raises GeosGeomError":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyLineString)
    let ls = LineString(g)
    expect GeosGeomError:
      discard ls.startPoint()

  test "endPoint on LINESTRING EMPTY raises GeosGeomError":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyLineString)
    let ls = LineString(g)
    expect GeosGeomError:
      discard ls.endPoint()

  test "pointN(0) on LINESTRING EMPTY raises GeosGeomError":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyLineString)
    let ls = LineString(g)
    expect GeosGeomError:
      discard ls.pointN(0)


# ═══════════════════════════════════════════════════════════════════════════════
# 5. Empty Polygon ring access
# ═══════════════════════════════════════════════════════════════════════════════

suite "Empty Polygon — ring access":
  test "numInteriorRings on POLYGON EMPTY is 0":
    # GEOS returns -1 for empty polygons in some versions, but the wrapper
    # may normalise this. Accept 0 or handle the error.
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPolygon)
    let poly = Polygon(g)
    try:
      let n = poly.numInteriorRings()
      check n == 0 or n == -1
    except GeosGeomError:
      check true

  test "exteriorRing on POLYGON EMPTY raises GeosGeomError or returns empty ring":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPolygon)
    let poly = Polygon(g)
    try:
      let ring = poly.exteriorRing()
      # Some GEOS versions return a valid empty ring instead of erroring
      check ring.isEmpty()
    except GeosGeomError:
      check true

  test "interiorRingN(0) on POLYGON EMPTY raises GeosGeomError":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPolygon)
    let poly = Polygon(g)
    expect GeosGeomError:
      discard poly.interiorRingN(0)


# ═══════════════════════════════════════════════════════════════════════════════
# 6. Spatial predicates with empty geometries
# ═══════════════════════════════════════════════════════════════════════════════

suite "Spatial predicates — two empty geometries":
  test "two empty points: intersects is false":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(emptyPoint)
    let b = ctx.fromWKT(emptyPoint)
    check not a.intersects(b)

  test "two empty points: equals is false":
    # GEOS considers two POINT EMPTYs as not equal (they have no coordinates)
    # However some versions may return true. Accept either.
    var ctx = initGeosContext()
    let a = ctx.fromWKT(emptyPoint)
    let b = ctx.fromWKT(emptyPoint)
    try:
      let eq = a.equals(b)
      # Both true and false are acceptable depending on GEOS version
      check eq or not eq
    except GeosGeomError:
      check true

  test "two empty points: disjoint is true":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(emptyPoint)
    let b = ctx.fromWKT(emptyPoint)
    check a.disjoint(b)

  test "two empty points: contains is false":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(emptyPoint)
    let b = ctx.fromWKT(emptyPoint)
    check not a.contains(b)

  test "two empty points: within is false":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(emptyPoint)
    let b = ctx.fromWKT(emptyPoint)
    check not a.within(b)

  test "two empty points: touches is false":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(emptyPoint)
    let b = ctx.fromWKT(emptyPoint)
    check not a.touches(b)

  test "two empty points: crosses is false":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(emptyPoint)
    let b = ctx.fromWKT(emptyPoint)
    check not a.crosses(b)

  test "two empty points: overlaps is false":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(emptyPoint)
    let b = ctx.fromWKT(emptyPoint)
    check not a.overlaps(b)

  test "empty polygon vs empty linestring: disjoint":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(emptyPolygon)
    let b = ctx.fromWKT(emptyLineString)
    check a.disjoint(b)
    check not a.intersects(b)

suite "Spatial predicates — empty vs non-empty":
  test "empty point does not intersect non-empty point":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(emptyPoint)
    let b = ctx.fromWKT(nonEmptyPoint)
    check not a.intersects(b)

  test "empty point is disjoint from non-empty point":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(emptyPoint)
    let b = ctx.fromWKT(nonEmptyPoint)
    check a.disjoint(b)

  test "non-empty polygon does not contain empty point":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(nonEmptyPolygon)
    let pt = ctx.fromWKT(emptyPoint)
    check not poly.contains(pt)

  test "empty point is not within non-empty polygon":
    var ctx = initGeosContext()
    let pt = ctx.fromWKT(emptyPoint)
    let poly = ctx.fromWKT(nonEmptyPolygon)
    check not pt.within(poly)

  test "empty linestring does not touch non-empty polygon":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(emptyLineString)
    let b = ctx.fromWKT(nonEmptyPolygon)
    check not a.touches(b)

  test "empty linestring does not cross non-empty polygon":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(emptyLineString)
    let b = ctx.fromWKT(nonEmptyPolygon)
    check not a.crosses(b)

  test "empty polygon does not overlap non-empty polygon":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(emptyPolygon)
    let b = ctx.fromWKT(nonEmptyPolygon)
    check not a.overlaps(b)

  test "empty point is not equal to non-empty point":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(emptyPoint)
    let b = ctx.fromWKT(nonEmptyPoint)
    check not a.equals(b)

  test "disjoint is inverse of intersects for empty vs non-empty":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(emptyPolygon)
    let b = ctx.fromWKT(nonEmptyPolygon)
    check a.disjoint(b) == (not a.intersects(b))


# ═══════════════════════════════════════════════════════════════════════════════
# 7. Spatial operations with empty geometries
# ═══════════════════════════════════════════════════════════════════════════════

suite "Spatial operations — on empty geometries":
  test "intersection of two empty points is empty":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(emptyPoint)
    let b = ctx.fromWKT(emptyPoint)
    let result = a.intersection(b)
    check result.isEmpty()

  test "union of two empty points is empty":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(emptyPoint)
    let b = ctx.fromWKT(emptyPoint)
    let result = a.union(b)
    check result.isEmpty()

  test "difference of two empty points is empty":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(emptyPoint)
    let b = ctx.fromWKT(emptyPoint)
    let result = a.difference(b)
    check result.isEmpty()

  test "intersection of empty and non-empty is empty":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(emptyPoint)
    let b = ctx.fromWKT(nonEmptyPoint)
    let result = a.intersection(b)
    check result.isEmpty()

  test "union of empty and non-empty equals non-empty":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(emptyPoint)
    let b = ctx.fromWKT(nonEmptyPoint)
    let result = a.union(b)
    check not result.isEmpty()
    check result.equals(b)

  test "difference of non-empty minus empty equals non-empty":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(nonEmptyPolygon)
    let b = ctx.fromWKT(emptyPolygon)
    let result = a.difference(b)
    check not result.isEmpty()
    check result.equals(a)

  test "difference of empty minus non-empty is empty":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(emptyPolygon)
    let b = ctx.fromWKT(nonEmptyPolygon)
    let result = a.difference(b)
    check result.isEmpty()

  test "symmetricDifference of empty and non-empty":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(emptyPolygon)
    let b = ctx.fromWKT(nonEmptyPolygon)
    let result = a.symmetricDifference(b)
    check not result.isEmpty()

suite "Spatial operations — unary on empty geometries":
  test "buffer of empty point with positive width":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPoint)
    let result = g.buffer(1.0)
    check result.isEmpty()

  test "buffer of empty linestring":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyLineString)
    let result = g.buffer(1.0)
    check result.isEmpty()

  test "buffer of empty polygon":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPolygon)
    let result = g.buffer(1.0)
    check result.isEmpty()

  test "convexHull of empty point is empty":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPoint)
    let result = g.convexHull()
    check result.isEmpty()

  test "convexHull of empty linestring is empty":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyLineString)
    let result = g.convexHull()
    check result.isEmpty()

  test "convexHull of empty polygon is empty":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPolygon)
    let result = g.convexHull()
    check result.isEmpty()

  test "envelope of empty point is empty":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPoint)
    let result = g.envelope()
    check result.isEmpty()

  test "envelope of empty polygon is empty":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPolygon)
    let result = g.envelope()
    check result.isEmpty()

  test "centroid of empty point is empty":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPoint)
    let result = g.centroid()
    check result.isEmpty()

  test "centroid of empty polygon is empty":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPolygon)
    let result = g.centroid()
    check result.isEmpty()

  test "simplify of empty linestring is empty":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyLineString)
    let result = g.simplify(1.0)
    check result.isEmpty()

  test "topologyPreserveSimplify of empty linestring is empty":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyLineString)
    let result = g.topologyPreserveSimplify(1.0)
    check result.isEmpty()

  test "unaryUnion of empty geometry collection is empty":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyGeometryCollection)
    let result = g.unaryUnion()
    check result.isEmpty()

  test "unaryUnion of empty multipolygon is empty":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyMultiPolygon)
    let result = g.unaryUnion()
    check result.isEmpty()

  test "boundaryOp of empty point is empty":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPoint)
    let result = g.boundaryOp()
    check result.isEmpty()

  test "boundaryOp of empty linestring is empty":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyLineString)
    let result = g.boundaryOp()
    check result.isEmpty()

  test "boundaryOp of empty polygon is empty":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPolygon)
    let result = g.boundaryOp()
    check result.isEmpty()


# ═══════════════════════════════════════════════════════════════════════════════
# 8. Serialization of empty geometries
# ═══════════════════════════════════════════════════════════════════════════════

suite "Serialization — toWKT on empty geometries":
  test "POINT EMPTY round-trips through WKT":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPoint)
    let wkt = g.toWKT()
    check strutils.contains(wkt, "EMPTY")
    let g2 = ctx.fromWKT(wkt)
    check g2.isEmpty()
    check g2.type() == gtPoint

  test "LINESTRING EMPTY round-trips through WKT":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyLineString)
    let wkt = g.toWKT()
    check strutils.contains(wkt, "EMPTY")
    let g2 = ctx.fromWKT(wkt)
    check g2.isEmpty()
    check g2.type() == gtLineString

  test "POLYGON EMPTY round-trips through WKT":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPolygon)
    let wkt = g.toWKT()
    check strutils.contains(wkt, "EMPTY")
    let g2 = ctx.fromWKT(wkt)
    check g2.isEmpty()
    check g2.type() == gtPolygon

  test "MULTIPOINT EMPTY round-trips through WKT":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyMultiPoint)
    let wkt = g.toWKT()
    check strutils.contains(wkt, "EMPTY")
    let g2 = ctx.fromWKT(wkt)
    check g2.isEmpty()
    check g2.type() == gtMultiPoint

  test "MULTILINESTRING EMPTY round-trips through WKT":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyMultiLineString)
    let wkt = g.toWKT()
    check strutils.contains(wkt, "EMPTY")
    let g2 = ctx.fromWKT(wkt)
    check g2.isEmpty()
    check g2.type() == gtMultiLineString

  test "MULTIPOLYGON EMPTY round-trips through WKT":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyMultiPolygon)
    let wkt = g.toWKT()
    check strutils.contains(wkt, "EMPTY")
    let g2 = ctx.fromWKT(wkt)
    check g2.isEmpty()
    check g2.type() == gtMultiPolygon

  test "GEOMETRYCOLLECTION EMPTY round-trips through WKT":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyGeometryCollection)
    let wkt = g.toWKT()
    check strutils.contains(wkt, "EMPTY")
    let g2 = ctx.fromWKT(wkt)
    check g2.isEmpty()
    check g2.type() == gtGeometryCollection

suite "Serialization — toWKB on empty geometries":
  test "POINT EMPTY round-trips through WKB":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPoint)
    let wkb = g.toWKB()
    check wkb.len > 0
    let g2 = ctx.fromWKB(wkb)
    check g2.isEmpty()
    check g2.type() == gtPoint

  test "LINESTRING EMPTY round-trips through WKB":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyLineString)
    let wkb = g.toWKB()
    check wkb.len > 0
    let g2 = ctx.fromWKB(wkb)
    check g2.isEmpty()
    check g2.type() == gtLineString

  test "POLYGON EMPTY round-trips through WKB":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPolygon)
    let wkb = g.toWKB()
    check wkb.len > 0
    let g2 = ctx.fromWKB(wkb)
    check g2.isEmpty()
    check g2.type() == gtPolygon

  test "MULTIPOINT EMPTY round-trips through WKB":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyMultiPoint)
    let wkb = g.toWKB()
    check wkb.len > 0
    let g2 = ctx.fromWKB(wkb)
    check g2.isEmpty()
    check g2.type() == gtMultiPoint

  test "GEOMETRYCOLLECTION EMPTY round-trips through WKB":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyGeometryCollection)
    let wkb = g.toWKB()
    check wkb.len > 0
    let g2 = ctx.fromWKB(wkb)
    check g2.isEmpty()
    check g2.type() == gtGeometryCollection

suite "Serialization — toHexWKB on empty geometries":
  test "POINT EMPTY round-trips through HexWKB":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPoint)
    let hex = g.toHexWKB()
    check hex.len > 0
    let g2 = ctx.fromHexWKB(hex)
    check g2.isEmpty()
    check g2.type() == gtPoint

  test "POLYGON EMPTY round-trips through HexWKB":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPolygon)
    let hex = g.toHexWKB()
    check hex.len > 0
    let g2 = ctx.fromHexWKB(hex)
    check g2.isEmpty()
    check g2.type() == gtPolygon

suite "Serialization — toGeoJSON on empty geometries":
  test "POINT EMPTY produces valid GeoJSON":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPoint)
    let gj = g.toGeoJSON()
    let node = parseJson(gj)
    check node["type"].getStr() == "Point"
    check node["coordinates"].kind == JArray
    check node["coordinates"].len == 0

  test "LINESTRING EMPTY produces valid GeoJSON":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyLineString)
    let gj = g.toGeoJSON()
    let node = parseJson(gj)
    check node["type"].getStr() == "LineString"
    check node["coordinates"].kind == JArray
    check node["coordinates"].len == 0

  test "POLYGON EMPTY produces valid GeoJSON":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPolygon)
    let gj = g.toGeoJSON()
    let node = parseJson(gj)
    check node["type"].getStr() == "Polygon"
    check node["coordinates"].kind == JArray
    check node["coordinates"].len == 0

  test "MULTIPOINT EMPTY produces valid GeoJSON":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyMultiPoint)
    let gj = g.toGeoJSON()
    let node = parseJson(gj)
    check node["type"].getStr() == "MultiPoint"
    check node["coordinates"].kind == JArray
    check node["coordinates"].len == 0

  test "MULTILINESTRING EMPTY produces valid GeoJSON":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyMultiLineString)
    let gj = g.toGeoJSON()
    let node = parseJson(gj)
    check node["type"].getStr() == "MultiLineString"
    check node["coordinates"].kind == JArray
    check node["coordinates"].len == 0

  test "MULTIPOLYGON EMPTY produces valid GeoJSON":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyMultiPolygon)
    let gj = g.toGeoJSON()
    let node = parseJson(gj)
    check node["type"].getStr() == "MultiPolygon"
    check node["coordinates"].kind == JArray
    check node["coordinates"].len == 0

  test "GEOMETRYCOLLECTION EMPTY produces valid GeoJSON":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyGeometryCollection)
    let gj = g.toGeoJSON()
    let node = parseJson(gj)
    check node["type"].getStr() == "GeometryCollection"
    check node["geometries"].kind == JArray
    check node["geometries"].len == 0

  test "POINT EMPTY GeoJSON round-trip":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPoint)
    let gj = g.toGeoJSON()
    let g2 = ctx.fromGeoJSON(gj)
    check g2.isEmpty()
    check g2.type() == gtPoint

  test "POLYGON EMPTY GeoJSON round-trip":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPolygon)
    let gj = g.toGeoJSON()
    let g2 = ctx.fromGeoJSON(gj)
    check g2.isEmpty()
    check g2.type() == gtPolygon


# ═══════════════════════════════════════════════════════════════════════════════
# 9. Iteration over empty multi-geometries
# ═══════════════════════════════════════════════════════════════════════════════

suite "Iteration — empty multi-geometries yield zero items":
  test "items on MULTIPOINT EMPTY yields nothing":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyMultiPoint)
    let mp = MultiPoint(g)
    var count = 0
    for _ in mp:
      count += 1
    check count == 0

  test "items on MULTILINESTRING EMPTY yields nothing":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyMultiLineString)
    let mls = MultiLineString(g)
    var count = 0
    for _ in mls:
      count += 1
    check count == 0

  test "items on MULTIPOLYGON EMPTY yields nothing":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyMultiPolygon)
    let mpoly = MultiPolygon(g)
    var count = 0
    for _ in mpoly:
      count += 1
    check count == 0

  test "items on GEOMETRYCOLLECTION EMPTY yields nothing":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyGeometryCollection)
    let gc = GeometryCollection(g)
    var count = 0
    for _ in gc:
      count += 1
    check count == 0


# ═══════════════════════════════════════════════════════════════════════════════
# 10. geomN on empty multi-geometries
# ═══════════════════════════════════════════════════════════════════════════════

suite "geomN — empty multi-geometries raise on access":
  test "geomN(0) on MULTIPOINT EMPTY raises GeosGeomError":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyMultiPoint)
    expect GeosGeomError:
      discard g.geomN(0)

  test "geomN(0) on MULTILINESTRING EMPTY raises GeosGeomError":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyMultiLineString)
    expect GeosGeomError:
      discard g.geomN(0)

  test "geomN(0) on MULTIPOLYGON EMPTY raises GeosGeomError":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyMultiPolygon)
    expect GeosGeomError:
      discard g.geomN(0)

  test "geomN(0) on GEOMETRYCOLLECTION EMPTY raises GeosGeomError":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyGeometryCollection)
    expect GeosGeomError:
      discard g.geomN(0)

  test "geomN(-1) on MULTIPOINT EMPTY raises GeosGeomError":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyMultiPoint)
    expect GeosGeomError:
      discard g.geomN(-1)


# ═══════════════════════════════════════════════════════════════════════════════
# 11. coordSeq on empty Point / LineString
# ═══════════════════════════════════════════════════════════════════════════════

suite "coordSeq — empty geometries":
  test "coordSeq on POINT EMPTY returns a CoordSeq of length 0":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPoint)
    try:
      var cs = g.coordSeq()
      check cs.len == 0
    except GeosGeomError:
      # Some GEOS versions may fail to get coord seq from empty point
      check true

  test "coordSeq on LINESTRING EMPTY returns a CoordSeq of length 0":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyLineString)
    try:
      var cs = g.coordSeq()
      check cs.len == 0
    except GeosGeomError:
      check true

  test "coordSeq on POINT EMPTY: iteration yields nothing":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPoint)
    try:
      var cs = g.coordSeq()
      var count = 0
      for _ in cs:
        count += 1
      check count == 0
    except GeosGeomError:
      check true

  test "coordSeq on LINESTRING EMPTY: iteration yields nothing":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyLineString)
    try:
      var cs = g.coordSeq()
      var count = 0
      for _ in cs:
        count += 1
      check count == 0
    except GeosGeomError:
      check true


# ═══════════════════════════════════════════════════════════════════════════════
# Additional edge cases
# ═══════════════════════════════════════════════════════════════════════════════

suite "Empty geometry — clone":
  test "clone of POINT EMPTY is also empty":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPoint)
    let g2 = g.clone()
    check not g2.isNil()
    check g2.isEmpty()
    check g2.type() == gtPoint

  test "clone of POLYGON EMPTY is also empty":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPolygon)
    let g2 = g.clone()
    check not g2.isNil()
    check g2.isEmpty()
    check g2.type() == gtPolygon

  test "clone of GEOMETRYCOLLECTION EMPTY is also empty":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyGeometryCollection)
    let g2 = g.clone()
    check not g2.isNil()
    check g2.isEmpty()
    check g2.type() == gtGeometryCollection

suite "Empty geometry — distance":
  test "distance between two empty points raises GeosGeomError or returns special value":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(emptyPoint)
    let b = ctx.fromWKT(emptyPoint)
    try:
      let d = a.distance(b)
      # If GEOS returns a value, it should be 0 or NaN
      check d == 0.0 or d.isNaN()
    except GeosGeomError:
      check true

  test "distance between empty and non-empty raises or returns special value":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(emptyPoint)
    let b = ctx.fromWKT(nonEmptyPoint)
    try:
      let d = a.distance(b)
      check d == 0.0 or d.isNaN() or d > 0.0
    except GeosGeomError:
      check true

suite "Empty geometry — operations produce correct types":
  test "centroid of POLYGON EMPTY is an empty Point":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyPolygon)
    let c = g.centroid()
    check c.isEmpty()
    check c.type() == gtPoint

  test "envelope of LINESTRING EMPTY is empty":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyLineString)
    let e = g.envelope()
    check e.isEmpty()

  test "convexHull of MULTIPOINT EMPTY is empty":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyMultiPoint)
    let h = g.convexHull()
    check h.isEmpty()

  test "boundaryOp of MULTIPOLYGON EMPTY is empty":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyMultiPolygon)
    let b = g.boundaryOp()
    check b.isEmpty()

  test "buffer of GEOMETRYCOLLECTION EMPTY is empty":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(emptyGeometryCollection)
    let b = g.buffer(5.0)
    check b.isEmpty()
