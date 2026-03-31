import unittest
import std/math
import nimgeos

# ── Test data ─────────────────────────────────────────────────────────────────
const ls2dCoords: array[3, (float, float)] = [
  (0.0, 0.0),
  (1.0, 1.0),
  (2.0, 0.0),
]

const ls3dCoords: array[3, (float, float, float)] = [
  (0.0, 0.0, 10.0),
  (1.0, 1.0, 20.0),
  (2.0, 0.0, 30.0),
]

const lsMinimal2d: array[2, (float, float)] = [
  (0.0, 0.0),
  (1.0, 1.0),
]

const lsMinimal3d: array[2, (float, float, float)] = [
  (0.0, 0.0, 5.0),
  (1.0, 1.0, 10.0),
]

# ── Construction ──────────────────────────────────────────────────────────────

suite "LineString construction":
  test "createLineString: 2D with 3 points":
    var ctx = initGeosContext()
    let ls = ctx.createLineString(ls2dCoords)
    check ls of LineString
    check ls.type() == gtLineString
    check not ls.isEmpty()
    check ls.isValid()
    check ls.numCoordinates() == 3

  test "createLineString: 3D with 3 points":
    var ctx = initGeosContext()
    let ls = ctx.createLineString(ls3dCoords)
    check ls of LineString
    check ls.type() == gtLineString
    check not ls.isEmpty()
    check ls.isValid()
    check ls.numCoordinates() == 3

  test "createLineString: minimal 2D (2 points)":
    var ctx = initGeosContext()
    let ls = ctx.createLineString(lsMinimal2d)
    check ls of LineString
    check ls.type() == gtLineString
    check not ls.isEmpty()
    check ls.isValid()
    check ls.numCoordinates() == 2

  test "createLineString: minimal 3D (2 points)":
    var ctx = initGeosContext()
    let ls = ctx.createLineString(lsMinimal3d)
    check ls of LineString
    check ls.type() == gtLineString
    check not ls.isEmpty()
    check ls.isValid()
    check ls.numCoordinates() == 2

  test "createLineString: fewer than 2 coords raises GeosGeomError":
    var ctx = initGeosContext()
    expect GeosGeomError:
      discard ctx.createLineString([(0.0, 0.0)])

  test "createLineString: empty coords raises GeosGeomError":
    var ctx = initGeosContext()
    let empty: seq[(float, float)] = @[]
    expect GeosGeomError:
      discard ctx.createLineString(empty)

  # ── fromWKT produces concrete LineString ────────────────────────────────────
  test "fromWKT: LINESTRING produces a LineString":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("LINESTRING (0 0, 1 1, 2 0)")
    check g of LineString

  test "fromWKT: LINESTRING Z produces a LineString":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("LINESTRING Z (0 0 1, 1 1 2, 2 0 3)")
    check g of LineString

  test "fromWKT: LINESTRING EMPTY produces a LineString":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("LINESTRING EMPTY")
    check g of LineString
    check g.isEmpty()

  # ── Nil safety ──────────────────────────────────────────────────────────────
  test "Nil Safety: numPoints raises GeosGeomError on nil":
    var ls: LineString
    expect GeosGeomError:
      discard ls.numPoints()

  test "Nil Safety: pointN raises GeosGeomError on nil":
    var ls: LineString
    expect GeosGeomError:
      discard ls.pointN(0)

  test "Nil Safety: startPoint raises GeosGeomError on nil":
    var ls: LineString
    expect GeosGeomError:
      discard ls.startPoint()

  test "Nil Safety: endPoint raises GeosGeomError on nil":
    var ls: LineString
    expect GeosGeomError:
      discard ls.endPoint()

  test "Nil Safety: isEmpty raises GeosGeomError on nil":
    var ls: LineString
    expect GeosGeomError:
      discard ls.isEmpty()

  test "Nil Safety: isValid raises GeosGeomError on nil":
    var ls: LineString
    expect GeosGeomError:
      discard ls.isValid()

  test "Nil Safety: type raises GeosGeomError on nil":
    var ls: LineString
    expect GeosGeomError:
      discard ls.type()

# ── LineString Points ────────────────────────────────────────────────────────

suite "LineString Points":
  test "numPoints returns correct count for 2D":
    var ctx = initGeosContext()
    let ls = ctx.createLineString(ls2dCoords)
    check ls.numPoints() == 3

  test "numPoints returns correct count for 3D":
    var ctx = initGeosContext()
    let ls = ctx.createLineString(ls3dCoords)
    check ls.numPoints() == 3

  test "numPoints returns 2 for minimal LineString":
    var ctx = initGeosContext()
    let ls = ctx.createLineString(lsMinimal2d)
    check ls.numPoints() == 2

  test "startPoint: matches first coordinate 2D":
    var ctx = initGeosContext()
    let ls = ctx.createLineString(ls2dCoords)
    let sp = ls.startPoint()
    check sp of Point
    check sp.x() == ls2dCoords[0][0]
    check sp.y() == ls2dCoords[0][1]

  test "startPoint: matches first coordinate 3D":
    var ctx = initGeosContext()
    let ls = ctx.createLineString(ls3dCoords)
    let sp = ls.startPoint()
    check sp of Point
    check sp.x() == ls3dCoords[0][0]
    check sp.y() == ls3dCoords[0][1]
    check sp.z() == ls3dCoords[0][2]

  test "endPoint: matches last coordinate 2D":
    var ctx = initGeosContext()
    let ls = ctx.createLineString(ls2dCoords)
    let ep = ls.endPoint()
    check ep of Point
    check ep.x() == ls2dCoords[^1][0]
    check ep.y() == ls2dCoords[^1][1]

  test "endPoint: matches last coordinate 3D":
    var ctx = initGeosContext()
    let ls = ctx.createLineString(ls3dCoords)
    let ep = ls.endPoint()
    check ep of Point
    check ep.x() == ls3dCoords[^1][0]
    check ep.y() == ls3dCoords[^1][1]
    check ep.z() == ls3dCoords[^1][2]

  test "startPoint equals pointN(0)":
    var ctx = initGeosContext()
    let ls = ctx.createLineString(ls2dCoords)
    let sp = ls.startPoint()
    let p0 = ls.pointN(0)
    check sp.x() == p0.x()
    check sp.y() == p0.y()

  test "endPoint equals pointN(numPoints - 1)":
    var ctx = initGeosContext()
    let ls = ctx.createLineString(ls2dCoords)
    let ep = ls.endPoint()
    let pLast = ls.pointN(ls.numPoints() - 1)
    check ep.x() == pLast.x()
    check ep.y() == pLast.y()

  test "pointN: returns correct 2D coordinates":
    var ctx = initGeosContext()
    let ls = ctx.createLineString(ls2dCoords)
    for i in 0 ..< ls2dCoords.len:
      let p = ls.pointN(i)
      check p of Point
      check p.x() == ls2dCoords[i][0]
      check p.y() == ls2dCoords[i][1]

  test "pointN: returns correct 3D coordinates":
    var ctx = initGeosContext()
    let ls = ctx.createLineString(ls3dCoords)
    for i in 0 ..< ls3dCoords.len:
      let p = ls.pointN(i)
      check p of Point
      check p.x() == ls3dCoords[i][0]
      check p.y() == ls3dCoords[i][1]
      check p.z() == ls3dCoords[i][2]

  test "pointN: negative index raises GeosGeomError":
    var ctx = initGeosContext()
    let ls = ctx.createLineString(ls2dCoords)
    expect GeosGeomError:
      discard ls.pointN(-1)

  test "pointN: index == numPoints raises GeosGeomError":
    var ctx = initGeosContext()
    let ls = ctx.createLineString(ls2dCoords)
    expect GeosGeomError:
      discard ls.pointN(ls.numPoints())

  test "pointN: index > numPoints raises GeosGeomError":
    var ctx = initGeosContext()
    let ls = ctx.createLineString(ls2dCoords)
    expect GeosGeomError:
      discard ls.pointN(100)

# ── Geometry base properties ──────────────────────────────────────────────────

suite "LineString geometry properties":
  test "length: 2D straight line":
    var ctx = initGeosContext()
    let ls = ctx.createLineString([(0.0, 0.0), (3.0, 4.0)])
    check ls.length() == 5.0

  test "length: 2D multi-segment":
    var ctx = initGeosContext()
    let ls = ctx.createLineString(ls2dCoords)
    # (0,0)->(1,1) = sqrt(2), (1,1)->(2,0) = sqrt(2)
    check ls.length() == 2.0 * sqrt(2.0)

  test "area is always 0 for a LineString":
    var ctx = initGeosContext()
    let ls = ctx.createLineString(ls2dCoords)
    check ls.area() == 0.0

  test "numGeometries is 1 for a simple LineString":
    var ctx = initGeosContext()
    let ls = ctx.createLineString(ls2dCoords)
    check ls.numGeometries() == 1

  test "distance between two LineStrings":
    var ctx = initGeosContext()
    let ls1 = ctx.createLineString([(0.0, 0.0), (1.0, 0.0)])
    let ls2 = ctx.createLineString([(0.0, 3.0), (1.0, 3.0)])
    check ls1.distance(ls2) == 3.0

# ── String representation ─────────────────────────────────────────────────────

suite "LineString string representation":
  test "$ 2D":
    var ctx = initGeosContext()
    let ls = ctx.createLineString(ls2dCoords)
    check $ls == "LineString(3 points)"

  test "$ 3D":
    var ctx = initGeosContext()
    let ls = ctx.createLineString(ls3dCoords)
    check $ls == "LineString(3 points)"

  test "$ minimal":
    var ctx = initGeosContext()
    let ls = ctx.createLineString(lsMinimal2d)
    check $ls == "LineString(2 points)"

  test "$ nil LineString raises NilAccessDefect":
    var ls: LineString
    expect NilAccessDefect:
      discard $ls
