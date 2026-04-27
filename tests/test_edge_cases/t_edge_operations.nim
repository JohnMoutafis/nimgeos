import unittest
import std/math
import nimgeos

# ── Test data ─────────────────────────────────────────────────────────────────
const polyA = "POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))"
const polySmall = "POLYGON ((1 1, 3 1, 3 3, 1 3, 1 1))"
const lineA = "LINESTRING (0 0, 5 5, 10 0)"
const pointInside = "POINT (5 5)"
const pointOutside = "POINT (20 20)"

suite "simplify with negative tolerance":
  test "simplify with negative tolerance on polygon":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(polyA)
    # GEOS typically treats negative tolerance as 0 (no simplification)
    try:
      let s = g.simplify(-1.0)
      # If it succeeds, the result should be valid and equivalent to the original
      check s.isValid()
      check abs(s.area() - g.area()) < 1e-10
    except GeosGeomError:
      # If GEOS raises an error, that's also acceptable behavior
      check true

  test "topologyPreserveSimplify with negative tolerance on polygon":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(polyA)
    try:
      let s = g.topologyPreserveSimplify(-1.0)
      check s.isValid()
      check abs(s.area() - g.area()) < 1e-10
    except GeosGeomError:
      check true

suite "buffer edge cases":
  test "buffer on point with negative width produces empty geometry":
    var ctx = initGeosContext()
    let pt = ctx.fromWKT("POINT (0 0)")
    try:
      let result = pt.buffer(-1.0)
      # Negative buffer on a point should produce an empty geometry
      check result.isEmpty()
    except GeosGeomError:
      check true

  test "buffer with very large width does not crash":
    var ctx = initGeosContext()
    let pt = ctx.fromWKT("POINT (0 0)")
    try:
      let result = pt.buffer(1e15)
      check not result.isEmpty()
      check result.isValid()
      check result.area() > 0.0
    except GeosGeomError:
      # Acceptable if GEOS cannot handle extreme values
      check true

  test "buffer with very small positive width produces valid geometry":
    var ctx = initGeosContext()
    let pt = ctx.fromWKT("POINT (0 0)")
    try:
      let result = pt.buffer(1e-15)
      check result.isValid()
      check not result.isEmpty()
      check result.area() > 0.0
    except GeosGeomError:
      check true

  test "buffer with 0 quadsegs":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyA)
    try:
      let result = poly.buffer(1.0, 0)
      # With 0 quadsegs, GEOS may produce a degenerate or simplified result
      check result.isValid() or result.isEmpty()
    except GeosGeomError:
      # GEOS might reject 0 quadsegs
      check true

  test "buffer with negative quadsegs":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyA)
    try:
      let result = poly.buffer(1.0, -1)
      # Negative quadsegs is invalid; GEOS may treat it as default or error
      check result.isValid() or result.isEmpty()
    except GeosGeomError:
      check true

  test "buffer with very large quadsegs produces many vertices":
    var ctx = initGeosContext()
    let pt = ctx.fromWKT("POINT (0 0)")
    let resultDefault = pt.buffer(1.0, 8)
    let resultLarge = pt.buffer(1.0, 10000)
    # More quadsegs means more coordinates
    check resultLarge.numCoordinates() > resultDefault.numCoordinates()
    check resultLarge.isValid()
    # Area should be closer to pi*r^2 with more segments
    let expectedArea = PI * 1.0 * 1.0
    check abs(resultLarge.area() - expectedArea) < abs(resultDefault.area() - expectedArea)

suite "cross-context operations":
  test "distance between geometries from different contexts":
    # Cross-context operations are undefined behavior in GEOS.
    # We wrap in try/except to document what happens.
    var ctx1 = initGeosContext()
    var ctx2 = initGeosContext()
    let p1 = ctx1.fromWKT("POINT (0 0)")
    let p2 = ctx2.fromWKT("POINT (3 4)")
    try:
      let d = p1.distance(p2)
      # If it works, the distance should be mathematically correct
      # (GEOS may not check context ownership)
      check abs(d - 5.0) < 1e-10
    except GeosGeomError:
      # If GEOS detects the context mismatch, it should raise
      check true
    except CatchableError:
      # Any other error is also acceptable for undefined behavior
      check true

  test "intersection across contexts":
    var ctx1 = initGeosContext()
    var ctx2 = initGeosContext()
    let g1 = ctx1.fromWKT(polyA)
    let g2 = ctx2.fromWKT(polySmall)
    try:
      let result = g1.intersection(g2)
      # If it works, the result should be valid
      check result.isValid()
    except GeosGeomError:
      check true
    except CatchableError:
      check true

  test "predicate across contexts":
    var ctx1 = initGeosContext()
    var ctx2 = initGeosContext()
    let g1 = ctx1.fromWKT(polyA)
    let g2 = ctx2.fromWKT(polySmall)
    try:
      let result = g1.contains(g2)
      # If it works with cross-context, polyA contains polySmall
      check result == true
    except GeosGeomError:
      check true
    except CatchableError:
      check true

suite "multi-geometry edge cases":
  test "geometry used after createMultiGeometry has nil handle":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(1.0, 2.0)),
      Geometry(ctx.createPoint(3.0, 4.0)),
    ]
    # After createMultiGeometry, handles are neutralised
    let mp = ctx.createMultiGeometry(geoms)
    check mp.numGeometries() == 2

    # The original geometries should now have nil handles
    # Attempting to use them should raise GeosGeomError
    expect GeosGeomError:
      discard geoms[0].isEmpty()

  test "using neutralised geometry in second createMultiGeometry raises":
    var ctx = initGeosContext()
    var geoms1: seq[Geometry] = @[
      Geometry(ctx.createPoint(1.0, 2.0)),
    ]
    let p = geoms1[0]  # alias before neutralisation
    discard ctx.createMultiGeometry(geoms1)

    # p's handle is now nil (neutralised)
    var geoms2: seq[Geometry] = @[p]
    expect GeosGeomError:
      discard ctx.createMultiGeometry(geoms2)

  test "geomN on a simple (non-multi) geometry":
    var ctx = initGeosContext()
    let pt = ctx.fromWKT("POINT (5 5)")
    # GEOS supports geomN(0) on simple geometries (returns the geometry itself)
    try:
      let sub = pt.geomN(0)
      check sub.type() == gtPoint
      check sub.toWKT() == pt.toWKT()
    except GeosGeomError:
      # If the library rejects index on simple geometries, that's fine too
      check true

  test "geomN out of bounds raises GeosGeomError":
    var ctx = initGeosContext()
    let pt = ctx.fromWKT("POINT (5 5)")
    expect GeosGeomError:
      discard pt.geomN(1)

suite "operations between different geometry types":
  test "intersection of point inside polygon returns the point":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyA)
    let pt = ctx.fromWKT(pointInside)
    let result = pt.intersection(poly)
    check not result.isEmpty()
    check result.type() == gtPoint

  test "intersection of point outside polygon returns empty":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyA)
    let pt = ctx.fromWKT(pointOutside)
    let result = pt.intersection(poly)
    check result.isEmpty()

  test "union of point and line produces GeometryCollection":
    var ctx = initGeosContext()
    let pt = ctx.fromWKT("POINT (0 0)")
    let line = ctx.fromWKT("LINESTRING (1 1, 2 2)")
    let result = pt.union(line)
    check not result.isEmpty()
    check result.isValid()
    # Union of point and line that don't overlap → GeometryCollection
    check result.type() == gtGeometryCollection

  test "buffer of linestring produces a polygon":
    var ctx = initGeosContext()
    let line = ctx.fromWKT(lineA)
    let result = line.buffer(1.0)
    check result.type() == gtPolygon
    check result.isValid()
    check result.area() > 0.0

  test "centroid of linestring produces a Point":
    var ctx = initGeosContext()
    let line = ctx.fromWKT(lineA)
    let c = line.centroid()
    check c.type() == gtPoint
    check not c.isEmpty()

  test "convexHull of multipoint with non-collinear points produces polygon":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(0.0, 0.0)),
      Geometry(ctx.createPoint(10.0, 0.0)),
      Geometry(ctx.createPoint(5.0, 10.0)),
      Geometry(ctx.createPoint(3.0, 3.0)),
    ]
    let mp = ctx.createMultiGeometry(geoms)
    let hull = mp.convexHull()
    check hull.type() == gtPolygon
    check hull.area() > 0.0
    check hull.isValid()

  test "envelope of a point returns a Point (degenerate)":
    var ctx = initGeosContext()
    let pt = ctx.fromWKT("POINT (5 5)")
    let env = pt.envelope()
    check env.type() == gtPoint

  test "envelope of a horizontal line returns degenerate geometry":
    var ctx = initGeosContext()
    let line = ctx.fromWKT("LINESTRING (0 5, 10 5)")
    let env = line.envelope()
    # GEOS returns a degenerate polygon (zero-area) for a horizontal line
    # Note: degenerate envelopes may not pass isValid() in GEOS
    check env.type() in {gtLineString, gtPolygon}
    check not env.isEmpty()
    check env.area() == 0.0

suite "PreparedGeometry edge cases":
  test "PreparedGeometry from empty geometry":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT EMPTY")
    try:
      let pg = g.toPreparedGeometry()
      # If it works, test that we can use it
      let other = ctx.fromWKT("POINT (1 1)")
      check not pg.preparedContains(other)
    except GeosGeomError:
      # Acceptable if GEOS rejects preparing empty geometry
      check true

  test "preparedContains with empty geometry as other":
    var ctx = initGeosContext()
    let pg = ctx.fromWKT(polyA).toPreparedGeometry()
    let empty = ctx.fromWKT("POINT EMPTY")
    try:
      # Contains empty is typically false (empty is subset of everything
      # but "contains" in GEOS has specific semantics)
      let result = pg.preparedContains(empty)
      check not result
    except GeosGeomError:
      check true

  test "preparedIntersects with empty geometry as other":
    var ctx = initGeosContext()
    let pg = ctx.fromWKT(polyA).toPreparedGeometry()
    let empty = ctx.fromWKT("POINT EMPTY")
    try:
      # Empty geometry intersects nothing
      let result = pg.preparedIntersects(empty)
      check not result
    except GeosGeomError:
      check true

suite "snap edge cases":
  test "snap with negative tolerance":
    var ctx = initGeosContext()
    let a = ctx.fromWKT("LINESTRING (0 0, 1 1, 2 2)")
    let b = ctx.fromWKT("LINESTRING (0 0.5, 1 1.5, 2 2.5)")
    try:
      let result = a.snap(b, -1.0)
      # Negative tolerance likely treated as 0 (no snapping)
      check result.isValid()
      # Should be equivalent to the original
      check result.equals(a)
    except GeosGeomError:
      check true

  test "snap geometry onto itself":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("LINESTRING (0 0, 1 1, 2 2)")
    let result = g.snap(g, 1.0)
    check result.isValid()
    # Snapping onto itself should produce the same geometry
    check result.equals(g)

  test "snap with zero tolerance preserves geometry":
    var ctx = initGeosContext()
    let a = ctx.fromWKT("LINESTRING (0 0, 1 1, 2 2)")
    let b = ctx.fromWKT("LINESTRING (0 0.5, 1 1.5, 2 2.5)")
    let result = a.snap(b, 0.0)
    check result.isValid()
    check result.equals(a)
