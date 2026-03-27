import unittest
import strutils
import std/strformat
import nimgeos

suite "Geometry lifecycle":

  # ── =destroy ────────────────────────────────────────────────────────────────

  test "=destroy fires cleanly at scope exit":
    ## Completing this test without crashing is the assertion.
    block:
      var ctx = initGeosContext()
      let g = ctx.fromWKT("POINT (0 0)")
      check not g.isEmpty()
    # =destroy fired on g's GeometryObj here — no crash, no double-free

  test "=destroy fires on var reassignment":
    ## Assigning a new Geometry to an existing var destroys the old handle first.
    var ctx = initGeosContext()
    var g = ctx.fromWKT("POINT (0 0)")
    g = ctx.fromWKT("POINT (1 2)")  # first GEOSGeometry freed here
    check g.toWKT().contains("1 2") # second handle still valid

  test "repeated create/destroy cycles do not crash":
    ## Stress-tests =destroy with many sequential handle allocations/frees.
    var ctx = initGeosContext()
    for _ in 0 ..< 50:
      let g = ctx.fromWKT("POINT (0 0)")
      check g.type() == Point

  # ── ref sharing ─────────────────────────────────────────────────────────────

  test "ref assignment shares the underlying GEOS handle":
    var ctx = initGeosContext()
    let g1 = ctx.fromWKT("POINT (0 0)")
    let g2 = g1
    check cast[pointer](g1.handle) == cast[pointer](g2.handle)
    check g1.toWKT() == g2.toWKT()

  test "all aliases remain valid while any ref is live":
    var ctx = initGeosContext()
    let g1 = ctx.fromWKT("POINT (0 0)")
    let g2 = g1
    let g3 = g2
    check g1.type() == g2.type()
    check g2.type() == g3.type()
    check g1.numCoordinates() == g3.numCoordinates()

  # ── =copy on GeometryObj ────────────────────────────────────────────────────

  test "=copy on GeometryObj deep-clones the GEOS handle":
    ## Dereferencing a Geometry ref and copying it as a value triggers =copy.
    ## The copy must own an independent GEOS handle via GEOSGeom_clone_r.
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT (0 0)")
    var objCopy: GeometryObj = g[]    # triggers =copy on GeometryObj
    check cast[pointer](objCopy.handle) != cast[pointer](g.handle)

  test "=copy on GeometryObj preserves ctx pointer":
    ## The copy must share the same context as the original.
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT (0 0)")
    var objCopy: GeometryObj = g[]
    check objCopy.ctx == g.ctx

  # ── clone ────────────────────────────────────────────────────────────────────

  test "clone produces equal WKT":
    var ctx = initGeosContext()
    let g1 = ctx.fromWKT("POINT (0 0)")
    let g2 = g1.clone()
    check not g2.isNil()
    check g1.toWKT() == g2.toWKT()

  test "clone produces a distinct GEOS handle":
    var ctx = initGeosContext()
    let g1 = ctx.fromWKT("POINT (0 0)")
    let g2 = g1.clone()
    check cast[pointer](g1.handle) != cast[pointer](g2.handle)

  test "clone shares the same context pointer":
    var ctx = initGeosContext()
    let g1 = ctx.fromWKT("POINT (0 0)")
    let g2 = g1.clone()
    check g1.ctx == g2.ctx

  test "clone is independent: original destroyed while clone remains valid":
    var ctx = initGeosContext()
    var g2: Geometry
    block:
      let g1 = ctx.fromWKT("POINT (0 0)")
      g2 = g1.clone()
      # g1 goes out of scope here; its GEOSGeometry handle is freed by =destroy
    check not g2.isNil()
    check g2.toWKT().contains("POINT") # clone's handle is still valid

  test "clone is independent: clone destroyed while original remains valid":
    var ctx = initGeosContext()
    let g1 = ctx.fromWKT("POINT (0 0)")
    block:
      let g2 = g1.clone()
      check g2.toWKT().contains("POINT")
      # g2 destroyed here
    check g1.toWKT().contains("POINT") # original unaffected

  test "clone of nil Geometry returns nil":
    var g: Geometry                     # nil ref
    check g.clone().isNil()

  # ── nil / uninitialised Geometry ─────────────────────────────────────────────

  test "uninitialised Geometry is nil":
    var g: Geometry
    check g.isNil()

  test "isEmpty raises GeosGeomError on nil Geometry":
    var g: Geometry
    expect GeosGeomError:
      discard g.isEmpty()

  test "toWKT raises GeosGeomError on nil Geometry":
    var g: Geometry
    expect GeosGeomError:
      discard g.toWKT()

  test "type raises GeosGeomError on nil Geometry":
    var g: Geometry
    expect GeosGeomError:
      discard g.type()

# ── Serialization ─────────────────────────────────────────────────────────────

const roundTripCases: array[7, (string, string)] = [
  ("POINT (1 2)", "POINT"),
  ("LINESTRING (0 0, 1 1, 2 2)", "LINESTRING"),
  ("POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))", "POLYGON"),
  ("MULTIPOINT ((0 0), (1 1))", "MULTIPOINT"),
  ("MULTILINESTRING ((0 0, 1 1), (2 2, 3 3))", "MULTILINESTRING"),
  ("MULTIPOLYGON (((0 0, 1 0, 1 1, 0 1, 0 0)), ((2 2, 3 2, 3 3, 2 3, 2 2)))", "MULTIPOLYGON"),
  ("GEOMETRYCOLLECTION (POINT (0 0), LINESTRING (0 0, 1 1))", "GEOMETRYCOLLECTION"),
]

const geomTypeCases: array[7, (string, GeomType)] = [
  ("POINT (1 2)", Point),
  ("LINESTRING (0 0, 1 1, 2 2)", LineString),
  ("POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))", Polygon),
  ("MULTIPOINT ((0 0), (1 1))", MultiPoint),
  ("MULTILINESTRING ((0 0, 1 1), (2 2, 3 3))", MultiLineString),
  ("MULTIPOLYGON (((0 0, 1 0, 1 1, 0 1, 0 0)), ((2 2, 3 2, 3 3, 2 3, 2 2)))", MultiPolygon),
  ("GEOMETRYCOLLECTION (POINT (0 0), LINESTRING (0 0, 1 1))", GeometryCollection),
]

const invalidWktCases: array[3, string] = [
  "NOT VALID WKT",
  "PONT (1 2)",
  "LINESTRING NO COORDS",
]

suite "Geometry serialization":

  # ── fromWKT -> toWKT round-trips ─────────────────────────────────────────────

  for (wkt, prefix) in roundTripCases:
    test &"fromWKT/toWKT round-trip: {prefix}":
      var ctx = initGeosContext()
      let g = ctx.fromWKT(wkt)
      check g.toWKT().startsWith(prefix)

  # ── GeomType resolution ───────────────────────────────────────────────────────

  for (wkt, kind) in geomTypeCases:
    test &"GeomType: {$kind}":
      var ctx = initGeosContext()
      let g = ctx.fromWKT(wkt)
      check g.type() == kind

  # ── invalid WKT raises GeosParseError ────────────────────────────────────────

  for wkt in invalidWktCases:
    test &"invalid WKT raises GeosParseError: \"{wkt}\"":
      var ctx = initGeosContext()
      expect GeosParseError:
        discard ctx.fromWKT(wkt)
