import unittest
import nimgeos

# ── Test data ─────────────────────────────────────────────────────────────────
# 2D triangle shell (3-4-5 right triangle)
const shell2dTriangle: array[4, (float, float)] = [
  (0.0, 0.0),
  (4.0, 0.0),
  (4.0, 3.0),
  (0.0, 0.0),
]

# 3D triangle shell
const shell3dTriangle: array[4, (float, float, float)] = [
  (0.0, 0.0, 10.0),
  (4.0, 0.0, 20.0),
  (4.0, 3.0, 30.0),
  (0.0, 0.0, 10.0),
]

# 2D square shell (4x4)
const shell2dSquare: array[5, (float, float)] = [
  (0.0, 0.0),
  (10.0, 0.0),
  (10.0, 10.0),
  (0.0, 10.0),
  (0.0, 0.0),
]

# A small hole inside the square shell
const hole2dSmall: array[5, (float, float)] = [
  (2.0, 2.0),
  (4.0, 2.0),
  (4.0, 4.0),
  (2.0, 4.0),
  (2.0, 2.0),
]

# A second small hole inside the square shell
const hole2dSmall2: array[5, (float, float)] = [
  (6.0, 6.0),
  (8.0, 6.0),
  (8.0, 8.0),
  (6.0, 8.0),
  (6.0, 6.0),
]

# ── Construction ──────────────────────────────────────────────────────────────

suite "Polygon construction":
  test "createPolygon: 2D triangle (no holes)":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell2dTriangle)
    let poly = ctx.createPolygon(shell)
    check poly of Polygon
    check poly.type() == gtPolygon
    check not poly.isEmpty()
    check poly.isValid()

  test "createPolygon: 3D triangle (no holes)":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell3dTriangle)
    let poly = ctx.createPolygon(shell)
    check poly of Polygon
    check poly.type() == gtPolygon
    check not poly.isEmpty()
    check poly.isValid()

  test "createPolygon: 2D with one hole":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell2dSquare)
    let hole = ctx.createLinearRing(hole2dSmall)
    let poly = ctx.createPolygon(shell, [hole])
    check poly of Polygon
    check poly.type() == gtPolygon
    check not poly.isEmpty()
    check poly.isValid()

  test "createPolygon: 2D with two holes":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell2dSquare)
    let h1 = ctx.createLinearRing(hole2dSmall)
    let h2 = ctx.createLinearRing(hole2dSmall2)
    let poly = ctx.createPolygon(shell, [h1, h2])
    check poly of Polygon
    check poly.type() == gtPolygon
    check not poly.isEmpty()
    check poly.isValid()

  test "createPolygon: nil shell raises GeosGeomError":
    var ctx = initGeosContext()
    var shell: LinearRing
    expect GeosGeomError:
      discard ctx.createPolygon(shell)

  # ── fromWKT produces concrete Polygon ───────────────────────────────────────
  test "fromWKT: POLYGON produces a Polygon":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POLYGON ((0 0, 4 0, 4 3, 0 0))")
    check g of Polygon

  test "fromWKT: POLYGON with hole produces a Polygon":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0), (2 2, 4 2, 4 4, 2 4, 2 2))")
    check g of Polygon

  test "fromWKT: POLYGON EMPTY produces a Polygon":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POLYGON EMPTY")
    check g of Polygon
    check g.isEmpty()

  # ── Nil safety ──────────────────────────────────────────────────────────────
  test "Nil Safety: exteriorRing raises GeosGeomError on nil":
    var p: Polygon
    expect GeosGeomError:
      discard p.exteriorRing()

  test "Nil Safety: numInteriorRings raises GeosGeomError on nil":
    var p: Polygon
    expect GeosGeomError:
      discard p.numInteriorRings()

  test "Nil Safety: interiorRingN raises GeosGeomError on nil":
    var p: Polygon
    expect GeosGeomError:
      discard p.interiorRingN(0)

  test "Nil Safety: isEmpty raises GeosGeomError on nil":
    var p: Polygon
    expect GeosGeomError:
      discard p.isEmpty()

  test "Nil Safety: isValid raises GeosGeomError on nil":
    var p: Polygon
    expect GeosGeomError:
      discard p.isValid()

  test "Nil Safety: type raises GeosGeomError on nil":
    var p: Polygon
    expect GeosGeomError:
      discard p.type()

# ── Rings ─────────────────────────────────────────────────────────────────────

suite "Polygon rings":
  test "exteriorRing: returns a LinearRing":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell2dTriangle)
    let poly = ctx.createPolygon(shell)
    let ext = poly.exteriorRing()
    check ext of LinearRing
    check ext.type() == gtLinearRing
    check ext.numCoordinates() == 4

  test "exteriorRing: is an independent clone":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell2dTriangle)
    let poly = ctx.createPolygon(shell)
    let ext1 = poly.exteriorRing()
    let ext2 = poly.exteriorRing()
    # Different handles (independent clones)
    check cast[pointer](ext1.handle) != cast[pointer](ext2.handle)
    # But same coordinate count
    check ext1.numCoordinates() == ext2.numCoordinates()

  test "numInteriorRings: 0 when no holes":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell2dTriangle)
    let poly = ctx.createPolygon(shell)
    check poly.numInteriorRings() == 0

  test "numInteriorRings: 1 with one hole":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell2dSquare)
    let hole = ctx.createLinearRing(hole2dSmall)
    let poly = ctx.createPolygon(shell, [hole])
    check poly.numInteriorRings() == 1

  test "numInteriorRings: 2 with two holes":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell2dSquare)
    let h1 = ctx.createLinearRing(hole2dSmall)
    let h2 = ctx.createLinearRing(hole2dSmall2)
    let poly = ctx.createPolygon(shell, [h1, h2])
    check poly.numInteriorRings() == 2

  test "interiorRingN: returns correct LinearRing":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell2dSquare)
    let hole = ctx.createLinearRing(hole2dSmall)
    let poly = ctx.createPolygon(shell, [hole])
    let ir = poly.interiorRingN(0)
    check ir of LinearRing
    check ir.type() == gtLinearRing
    check ir.numCoordinates() == 5

  test "interiorRingN: each hole is accessible":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell2dSquare)
    let h1 = ctx.createLinearRing(hole2dSmall)
    let h2 = ctx.createLinearRing(hole2dSmall2)
    let poly = ctx.createPolygon(shell, [h1, h2])
    for i in 0 ..< poly.numInteriorRings():
      let ir = poly.interiorRingN(i)
      check ir of LinearRing
      check ir.numCoordinates() == 5

  test "interiorRingN: negative index raises GeosGeomError":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell2dSquare)
    let hole = ctx.createLinearRing(hole2dSmall)
    let poly = ctx.createPolygon(shell, [hole])
    expect GeosGeomError:
      discard poly.interiorRingN(-1)

  test "interiorRingN: index == numInteriorRings raises GeosGeomError":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell2dSquare)
    let hole = ctx.createLinearRing(hole2dSmall)
    let poly = ctx.createPolygon(shell, [hole])
    expect GeosGeomError:
      discard poly.interiorRingN(poly.numInteriorRings())

  test "interiorRingN: index > numInteriorRings raises GeosGeomError":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell2dSquare)
    let hole = ctx.createLinearRing(hole2dSmall)
    let poly = ctx.createPolygon(shell, [hole])
    expect GeosGeomError:
      discard poly.interiorRingN(100)

  test "interiorRingN: on polygon with no holes raises GeosGeomError":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell2dTriangle)
    let poly = ctx.createPolygon(shell)
    expect GeosGeomError:
      discard poly.interiorRingN(0)

# ── Geometry properties ───────────────────────────────────────────────────────

suite "Polygon geometry properties":
  test "area: 2D triangle (3-4-5)":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell2dTriangle)
    let poly = ctx.createPolygon(shell)
    # area of 3-4-5 right triangle = 0.5 * 4 * 3 = 6
    check poly.area() == 6.0

  test "area: 2D square (10x10)":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell2dSquare)
    let poly = ctx.createPolygon(shell)
    check poly.area() == 100.0

  test "area: polygon with hole subtracts hole area":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell2dSquare)
    let hole = ctx.createLinearRing(hole2dSmall)
    let poly = ctx.createPolygon(shell, [hole])
    # 10*10 - 2*2 = 96
    check poly.area() == 96.0

  test "area: polygon with two holes subtracts both":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell2dSquare)
    let h1 = ctx.createLinearRing(hole2dSmall)
    let h2 = ctx.createLinearRing(hole2dSmall2)
    let poly = ctx.createPolygon(shell, [h1, h2])
    # 10*10 - 2*2 - 2*2 = 92
    check poly.area() == 92.0

  test "length: 2D triangle perimeter (3-4-5)":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell2dTriangle)
    let poly = ctx.createPolygon(shell)
    # perimeter: 4 + 3 + 5 = 12
    check poly.length() == 12.0

  test "length: 2D square perimeter":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell2dSquare)
    let poly = ctx.createPolygon(shell)
    # perimeter: 4 * 10 = 40
    check poly.length() == 40.0

  test "numCoordinates: triangle":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell2dTriangle)
    let poly = ctx.createPolygon(shell)
    check poly.numCoordinates() == 4

  test "numCoordinates: square with one hole":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell2dSquare)
    let hole = ctx.createLinearRing(hole2dSmall)
    let poly = ctx.createPolygon(shell, [hole])
    # 5 (shell) + 5 (hole)
    check poly.numCoordinates() == 10

  test "numGeometries is 1 for a simple Polygon":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell2dTriangle)
    let poly = ctx.createPolygon(shell)
    check poly.numGeometries() == 1

  test "distance between two Polygons":
    var ctx = initGeosContext()
    let s1 = ctx.createLinearRing([(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0), (0.0, 0.0)])
    let p1 = ctx.createPolygon(s1)
    let s2 = ctx.createLinearRing([(5.0, 0.0), (6.0, 0.0), (6.0, 1.0), (5.0, 1.0), (5.0, 0.0)])
    let p2 = ctx.createPolygon(s2)
    check p1.distance(p2) == 4.0

# ── String representation ─────────────────────────────────────────────────────

suite "Polygon string representation":
  test "$ no holes":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell2dTriangle)
    let poly = ctx.createPolygon(shell)
    check $poly == "Polygon(0 holes)"

  test "$ one hole":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell2dSquare)
    let hole = ctx.createLinearRing(hole2dSmall)
    let poly = ctx.createPolygon(shell, [hole])
    check $poly == "Polygon(1 holes)"

  test "$ two holes":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(shell2dSquare)
    let h1 = ctx.createLinearRing(hole2dSmall)
    let h2 = ctx.createLinearRing(hole2dSmall2)
    let poly = ctx.createPolygon(shell, [h1, h2])
    check $poly == "Polygon(2 holes)"

  test "$ nil Polygon raises NilAccessDefect":
    var p: Polygon
    expect NilAccessDefect:
      discard $p
