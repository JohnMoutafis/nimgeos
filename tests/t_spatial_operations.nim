import unittest
import std/math
import nimgeos

# ── Test data ─────────────────────────────────────────────────────────────────
# polyA and polyB overlap in the (2,2)-(4,4) region → intersection area = 4.0
const polyA       = "POLYGON ((0 0, 4 0, 4 4, 0 4, 0 0))"            # 4×4 square, area = 16
const polyB       = "POLYGON ((2 2, 6 2, 6 6, 2 6, 2 2))"            # 4×4 square offset, area = 16
const polyInner   = "POLYGON ((1 1, 2 1, 2 2, 1 2, 1 1))"            # 1×1 inside polyA, area = 1
const polyDisjoint = "POLYGON ((10 10, 11 10, 11 11, 10 11, 10 10))" # fully disjoint, area = 1

const polyDiamond = "POLYGON ((2 0, 4 2, 2 4, 0 2, 2 0))"            # rotated diamond, area = 8
const polyCShape  = "POLYGON ((0 0, 4 0, 4 1, 1 1, 1 3, 4 3, 4 4, 0 4, 0 0))" # non-convex, area = 10

const lineA         = "LINESTRING (0 0, 4 4)"
const lineCollinear = "LINESTRING (0 0, 2 2, 4 4)"  # collinear — hull is a LineString

const triangleWKT = "POLYGON ((0 0, 4 0, 2 3, 0 0))" # centroid at (2.0, 1.0)
const pointA      = "POINT (2 3)"

const lineDense     = "LINESTRING (0 0, 0.5 0.1, 1 0, 1.5 -0.1, 2 0, 2.5 0.1, 3 0, 3.5 -0.1, 4 0)"
const polyWithHole  = "POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0), (3 3, 7 3, 7 7, 3 7, 3 3))"
const linesForSnapA = "LINESTRING (0 0, 1 1, 2 2)"
const linesForSnapB = "LINESTRING (0 0.25, 1 1.25, 2 2.25)"

# ── intersection ──────────────────────────────────────────────────────────────

suite "intersection":
  test "overlapping polygons produce non-empty valid intersection":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyA)
    let b = ctx.fromWKT(polyB)
    let result = a.intersection(b)
    check not result.isEmpty()
    check result.isValid()

  test "intersection area of overlapping squares":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyA)
    let b = ctx.fromWKT(polyB)
    # Overlap region is (2,2)-(4,4) → 2×2 = 4.0
    check abs(a.intersection(b).area() - 4.0) < 1e-10

  test "intersection of overlapping polygons returns a Polygon":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyA)
    let b = ctx.fromWKT(polyB)
    check a.intersection(b) of Polygon

  test "intersection of disjoint polygons is empty":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyA)
    let b = ctx.fromWKT(polyDisjoint)
    check a.intersection(b).isEmpty()

  test "intersection is commutative":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyA)
    let b = ctx.fromWKT(polyB)
    check abs(a.intersection(b).area() - b.intersection(a).area()) < 1e-10

  test "Nil Safety: g nil raises GeosGeomError":
    var g: Geometry
    var ctx = initGeosContext()
    let other = ctx.fromWKT(polyA)
    expect GeosGeomError:
      discard g.intersection(other)

  test "Nil Safety: other nil raises GeosGeomError":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(polyA)
    var other: Geometry
    expect GeosGeomError:
      discard g.intersection(other)

# ── union ─────────────────────────────────────────────────────────────────────

suite "union":
  test "union of overlapping polygons is non-empty and valid":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyA)
    let b = ctx.fromWKT(polyB)
    let result = a.union(b)
    check not result.isEmpty()
    check result.isValid()

  test "union area of overlapping squares":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyA)
    let b = ctx.fromWKT(polyB)
    # 16 + 16 - 4 (overlap) = 28
    check abs(a.union(b).area() - 28.0) < 1e-10

  test "union area of disjoint polygons equals sum of areas":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyA)
    let b = ctx.fromWKT(polyDisjoint)
    # 16 + 1 = 17
    check abs(a.union(b).area() - 17.0) < 1e-10

  test "union with itself has same area as original":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyA)
    check abs(a.union(a).area() - a.area()) < 1e-10

  test "union is commutative":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyA)
    let b = ctx.fromWKT(polyB)
    check abs(a.union(b).area() - b.union(a).area()) < 1e-10

  test "Nil Safety: g nil raises GeosGeomError":
    var g: Geometry
    var ctx = initGeosContext()
    let other = ctx.fromWKT(polyA)
    expect GeosGeomError:
      discard g.union(other)

  test "Nil Safety: other nil raises GeosGeomError":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(polyA)
    var other: Geometry
    expect GeosGeomError:
      discard g.union(other)

# ── difference ────────────────────────────────────────────────────────────────

suite "difference":
  test "difference of overlapping polygons is non-empty and valid":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyA)
    let b = ctx.fromWKT(polyB)
    let result = a.difference(b)
    check not result.isEmpty()
    check result.isValid()

  test "difference area equals original minus intersection":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyA)
    let b = ctx.fromWKT(polyB)
    # 16 - 4 (overlap) = 12
    check abs(a.difference(b).area() - 12.0) < 1e-10

  test "difference is NOT commutative":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyA)
    let b = ctx.fromWKT(polyInner)
    # a.diff(inner) = 16 - 1 = 15; inner.diff(a) = 0 (inner fully inside a)
    check abs(a.difference(b).area() - 15.0) < 1e-10
    check abs(b.difference(a).area() - 0.0) < 1e-10

  test "difference with itself is empty":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyA)
    check a.difference(a).isEmpty()

  test "difference with disjoint polygon preserves original area":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyA)
    let b = ctx.fromWKT(polyDisjoint)
    check abs(a.difference(b).area() - a.area()) < 1e-10

  test "Nil Safety: g nil raises GeosGeomError":
    var g: Geometry
    var ctx = initGeosContext()
    let other = ctx.fromWKT(polyA)
    expect GeosGeomError:
      discard g.difference(other)

  test "Nil Safety: other nil raises GeosGeomError":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(polyA)
    var other: Geometry
    expect GeosGeomError:
      discard g.difference(other)

# ── buffer ────────────────────────────────────────────────────────────────────

suite "buffer":
  test "point buffer produces a non-empty valid Polygon":
    var ctx = initGeosContext()
    let pt = ctx.fromWKT(pointA)
    let result = pt.buffer(1.0)
    check result of Polygon
    check not result.isEmpty()
    check result.isValid()

  test "point buffer area approximates π r² (default quadsegs)":
    var ctx = initGeosContext()
    let pt = ctx.fromWKT("POINT (0 0)")
    # quadsegs=8 → 32 segments, area ≈ 3.121 vs π ≈ 3.1416
    check abs(pt.buffer(1.0).area() - PI) < 0.1

  test "line buffer produces a Polygon":
    var ctx = initGeosContext()
    let line = ctx.fromWKT(lineA)
    let result = line.buffer(1.0)
    check result of Polygon
    check not result.isEmpty()

  test "positive buffer grows polygon area":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyA)
    check poly.buffer(1.0).area() > poly.area()

  test "negative buffer shrinks polygon area":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyA)
    check poly.buffer(-0.5).area() < poly.area()

  test "zero buffer preserves area":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyA)
    check abs(poly.buffer(0.0).area() - poly.area()) < 1e-6

  test "higher quadsegs gives area closer to π r²":
    var ctx = initGeosContext()
    let pt = ctx.fromWKT("POINT (0 0)")
    let coarse = pt.buffer(1.0, 4)   # 16 segments
    let fine   = pt.buffer(1.0, 32)  # 128 segments
    check abs(fine.area() - PI) < abs(coarse.area() - PI)

  test "buffer result is valid":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyA)
    check poly.buffer(0.5).isValid()

  test "Nil Safety: g nil raises GeosGeomError":
    var g: Geometry
    expect GeosGeomError:
      discard g.buffer(1.0)

# ── convexHull ────────────────────────────────────────────────────────────────

suite "convexHull":
  test "convex polygon hull has same area as original":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyA)    # axis-aligned square is already convex
    check abs(poly.convexHull().area() - poly.area()) < 1e-10

  test "non-convex polygon hull has larger area than original":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyCShape)  # C-shape, area = 10
    let hull = poly.convexHull()
    check hull.area() > poly.area()     # hull area = 16

  test "hull contains the original geometry":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyCShape)
    check poly.convexHull().contains(poly)

  test "collinear linestring hull returns a LineString":
    var ctx = initGeosContext()
    let line = ctx.fromWKT(lineCollinear)
    check line.convexHull() of LineString

  test "single point hull returns a Point":
    var ctx = initGeosContext()
    let pt = ctx.fromWKT(pointA)
    check pt.convexHull() of Point

  test "hull result is valid":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyCShape)
    check poly.convexHull().isValid()

  test "Nil Safety: g nil raises GeosGeomError":
    var g: Geometry
    expect GeosGeomError:
      discard g.convexHull()

# ── envelope ──────────────────────────────────────────────────────────────────

suite "envelope":
  test "axis-aligned square envelope has same area as original":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyA)   # 4×4 axis-aligned square
    check abs(poly.envelope().area() - poly.area()) < 1e-10

  test "rotated diamond envelope has larger area than original":
    var ctx = initGeosContext()
    let diamond = ctx.fromWKT(polyDiamond)  # area = 8
    let env = diamond.envelope()
    check env.area() > diamond.area()       # bounding box area = 16

  test "point envelope returns a Point":
    var ctx = initGeosContext()
    let pt = ctx.fromWKT(pointA)
    check pt.envelope() of Point

  test "envelope contains the original geometry":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyDiamond)
    check poly.envelope().contains(poly)

  test "envelope area is greater than or equal to original area":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyCShape)
    check poly.envelope().area() >= poly.area()

  test "envelope result is valid":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyA)
    check poly.envelope().isValid()

  test "Nil Safety: g nil raises GeosGeomError":
    var g: Geometry
    expect GeosGeomError:
      discard g.envelope()

# ── centroid ──────────────────────────────────────────────────────────────────

suite "centroid":
  test "centroid returns a Point":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyA)
    check poly.centroid() of Point

  test "centroid of axis-aligned square is at its centre":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyA)     # (0,0)-(4,4) → centroid at (2,2)
    let c = Point(poly.centroid())
    check abs(c.x() - 2.0) < 1e-10
    check abs(c.y() - 2.0) < 1e-10

  test "centroid of triangle matches known value":
    var ctx = initGeosContext()
    let tri = ctx.fromWKT(triangleWKT) # vertices (0,0),(4,0),(2,3) → centroid (2.0, 1.0)
    let c = Point(tri.centroid())
    check abs(c.x() - 2.0) < 1e-10
    check abs(c.y() - 1.0) < 1e-10

  test "centroid of a point returns the same coordinates":
    var ctx = initGeosContext()
    let pt = ctx.fromWKT(pointA)       # POINT (2 3)
    let c = Point(pt.centroid())
    check abs(c.x() - 2.0) < 1e-10
    check abs(c.y() - 3.0) < 1e-10

  test "centroid of a linestring returns a Point":
    var ctx = initGeosContext()
    let line = ctx.fromWKT(lineA)
    check line.centroid() of Point

  test "centroid result is valid":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyA)
    check poly.centroid().isValid()

  test "Nil Safety: g nil raises GeosGeomError":
    var g: Geometry
    expect GeosGeomError:
      discard g.centroid()

# ── Operation relationships ───────────────────────────────────────────────────

suite "Operation relationships":
  test "union area equals sum of areas minus intersection area":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyA)
    let b = ctx.fromWKT(polyB)
    let expected = a.area() + b.area() - a.intersection(b).area()
    check abs(a.union(b).area() - expected) < 1e-10

  test "difference area plus intersection area equals original area":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyA)
    let b = ctx.fromWKT(polyB)
    check abs(a.difference(b).area() + a.intersection(b).area() - a.area()) < 1e-10

  test "zero buffer preserves area":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyA)
    check abs(poly.buffer(0.0).area() - poly.area()) < 1e-6

  test "envelope contains original geometry":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyDiamond)
    check poly.envelope().contains(poly)

  test "convexHull contains original geometry":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyCShape)
    check poly.convexHull().contains(poly)

# ── simplify ──────────────────────────────────────────────────────────────────

suite "simplify":
  test "simplify preserves validity for simple polygon":
    var ctx = initGeosContext()
    let p = ctx.fromWKT(polyA)
    let s = p.simplify(0.25)
    check s.isValid()

  test "simplify reduces coordinate count on dense line":
    var ctx = initGeosContext()
    let l = ctx.fromWKT(lineDense)
    let s = l.simplify(0.2)
    check s.numCoordinates() < l.numCoordinates()

  test "simplify with zero tolerance is topologically equal":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(lineDense)
    check g.equals(g.simplify(0.0))

  test "simplify with larger tolerance simplifies at least as much":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(lineDense)
    let lo = g.simplify(0.05)
    let hi = g.simplify(0.3)
    check hi.numCoordinates() <= lo.numCoordinates()

  test "Nil Safety: g nil raises GeosGeomError":
    var g: Geometry
    expect GeosGeomError:
      discard g.simplify(1.0)

# ── topologyPreserveSimplify ──────────────────────────────────────────────────

suite "topologyPreserveSimplify":
  test "topology-preserving simplify keeps polygon valid":
    var ctx = initGeosContext()
    let p = ctx.fromWKT(polyWithHole)
    let s = p.topologyPreserveSimplify(0.6)
    check s.isValid()

  test "topology-preserving simplify keeps hole count":
    var ctx = initGeosContext()
    let p = Polygon(ctx.fromWKT(polyWithHole))
    let s = Polygon(p.topologyPreserveSimplify(0.6))
    check s.numInteriorRings() == p.numInteriorRings()

  test "topology-preserving simplify reduces coordinate count on dense line":
    var ctx = initGeosContext()
    let l = ctx.fromWKT(lineDense)
    let s = l.topologyPreserveSimplify(0.2)
    check s.numCoordinates() < l.numCoordinates()

  test "topology-preserving simplify with zero tolerance is equal":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(polyA)
    check g.equals(g.topologyPreserveSimplify(0.0))

  test "Nil Safety: g nil raises GeosGeomError":
    var g: Geometry
    expect GeosGeomError:
      discard g.topologyPreserveSimplify(1.0)

# ── symmetricDifference ───────────────────────────────────────────────────────

suite "symmetricDifference":
  test "symmetric difference of overlapping polygons is non-empty":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyA)
    let b = ctx.fromWKT(polyB)
    check not a.symmetricDifference(b).isEmpty()

  test "symmetric difference is commutative":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyA)
    let b = ctx.fromWKT(polyB)
    check a.symmetricDifference(b).equals(b.symmetricDifference(a))

  test "symmetric difference area matches union minus intersection":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyA)
    let b = ctx.fromWKT(polyB)
    let lhs = a.symmetricDifference(b).area()
    let rhs = a.union(b).area() - a.intersection(b).area()
    check abs(lhs - rhs) < 1e-9

  test "symmetric difference with itself is empty":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyA)
    check a.symmetricDifference(a).isEmpty()

  test "Nil Safety: g nil raises GeosGeomError":
    var a: Geometry
    var ctx = initGeosContext()
    let b = ctx.fromWKT(polyA)
    expect GeosGeomError:
      discard a.symmetricDifference(b)

# ── unaryUnion ────────────────────────────────────────────────────────────────

suite "unaryUnion":
  test "unaryUnion dissolves overlapping multipolygon":
    var ctx = initGeosContext()
    let m = ctx.fromWKT("MULTIPOLYGON (((0 0, 4 0, 4 4, 0 4, 0 0)), ((2 2, 6 2, 6 6, 2 6, 2 2)))")
    let u = m.unaryUnion()
    check u.area() < m.area()
    check u.isValid()

  test "unaryUnion preserves area for disjoint multipolygon":
    var ctx = initGeosContext()
    let m = ctx.fromWKT("MULTIPOLYGON (((0 0, 2 0, 2 2, 0 2, 0 0)), ((3 3, 5 3, 5 5, 3 5, 3 3)))")
    check abs(m.unaryUnion().area() - m.area()) < 1e-9

  test "unaryUnion of geometry collection is valid":
    var ctx = initGeosContext()
    let c = ctx.fromWKT("GEOMETRYCOLLECTION (LINESTRING (0 0, 3 3), LINESTRING (0 3, 3 0))")
    check c.unaryUnion().isValid()

  test "unaryUnion of empty collection is empty":
    var ctx = initGeosContext()
    let c = ctx.fromWKT("GEOMETRYCOLLECTION EMPTY")
    check c.unaryUnion().isEmpty()

  test "Nil Safety: g nil raises GeosGeomError":
    var g: Geometry
    expect GeosGeomError:
      discard g.unaryUnion()

# ── snap ──────────────────────────────────────────────────────────────────────

suite "snap":
  test "snap with zero tolerance keeps source geometry":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(linesForSnapA)
    let b = ctx.fromWKT(linesForSnapB)
    check a.equals(a.snap(b, 0.0))

  test "snap with larger tolerance moves geometry closer to target":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(linesForSnapA)
    let b = ctx.fromWKT(linesForSnapB)
    let loose = a.snap(b, 0.5)
    check loose.distance(b) < a.distance(b)

  test "snap with increasing tolerance does not increase distance":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(linesForSnapA)
    let b = ctx.fromWKT(linesForSnapB)
    let t1 = a.snap(b, 0.1)
    let t2 = a.snap(b, 0.5)
    check t2.distance(b) <= t1.distance(b)

  test "snap result is valid":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(linesForSnapA)
    let b = ctx.fromWKT(linesForSnapB)
    check a.snap(b, 0.5).isValid()

  test "Nil Safety: g nil raises GeosGeomError":
    var a: Geometry
    var ctx = initGeosContext()
    let b = ctx.fromWKT(linesForSnapB)
    expect GeosGeomError:
      discard a.snap(b, 0.5)

# ── boundaryOp ────────────────────────────────────────────────────────────────

suite "boundaryOp":
  test "boundary of polygon is linestring or multiline":
    var ctx = initGeosContext()
    let p = ctx.fromWKT(polyA)
    let b = p.boundaryOp()
    check (b of LineString) or (b of MultiLineString)

  test "boundary of linestring is two endpoints":
    var ctx = initGeosContext()
    let l = LineString(ctx.fromWKT("LINESTRING (0 0, 2 2, 4 4)"))
    let b = l.boundaryOp()
    check b of MultiPoint
    check b.numGeometries() == 2

  test "boundary of point is empty":
    var ctx = initGeosContext()
    let p = ctx.fromWKT("POINT (1 1)")
    check p.boundaryOp().isEmpty()

  test "boundary of empty point is empty":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT EMPTY")
    check g.boundaryOp().isEmpty()

  test "Nil Safety: g nil raises GeosGeomError":
    var g: Geometry
    expect GeosGeomError:
      discard g.boundaryOp()

# ── Extended operation invariants ─────────────────────────────────────────────

suite "Extended operation invariants":
  test "A xor B equals B xor A":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyA)
    let b = ctx.fromWKT(polyB)
    check a.symmetricDifference(b).equals(b.symmetricDifference(a))

  test "point boundary is empty set":
    var ctx = initGeosContext()
    let p = ctx.fromWKT("POINT (0 0)")
    check p.boundaryOp().isEmpty()

  test "hole structure survives topology-preserving simplify":
    var ctx = initGeosContext()
    let p = Polygon(ctx.fromWKT(polyWithHole))
    let s = Polygon(p.topologyPreserveSimplify(0.8))
    check s.numInteriorRings() == p.numInteriorRings()

  test "simplify may alter area but keeps finite area":
    var ctx = initGeosContext()
    let p = ctx.fromWKT(polyWithHole)
    let s = p.simplify(0.8)
    check s.area().classify != fcNan

  test "symmetric difference and intersection have zero area overlap":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyA)
    let b = ctx.fromWKT(polyB)
    let x = a.symmetricDifference(b)
    let i = a.intersection(b)
    check abs(x.intersection(i).area()) < 1e-9
