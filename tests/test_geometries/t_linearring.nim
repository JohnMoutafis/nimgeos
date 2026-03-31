import unittest
import nimgeos

# ── Test data ─────────────────────────────────────────────────────────────────
const ring2dTriangle: array[4, (float, float)] = [
  (0.0, 0.0),
  (4.0, 0.0),
  (4.0, 3.0),
  (0.0, 0.0),
]

const ring3dTriangle: array[4, (float, float, float)] = [
  (0.0, 0.0, 10.0),
  (4.0, 0.0, 20.0),
  (4.0, 3.0, 30.0),
  (0.0, 0.0, 10.0),
]

const ring2dSquare: array[5, (float, float)] = [
  (0.0, 0.0),
  (4.0, 0.0),
  (4.0, 4.0),
  (0.0, 4.0),
  (0.0, 0.0),
]

const ring3dSquare: array[5, (float, float, float)] = [
  (0.0, 0.0, 1.0),
  (4.0, 0.0, 2.0),
  (4.0, 4.0, 3.0),
  (0.0, 4.0, 4.0),
  (0.0, 0.0, 1.0),
]

# ── Construction ──────────────────────────────────────────────────────────────

suite "LinearRing construction":
  test "createLinearRing: 2D triangle (4 coords)":
    var ctx = initGeosContext()
    let lr = ctx.createLinearRing(ring2dTriangle)
    check lr of LinearRing
    check lr.type() == gtLinearRing
    check not lr.isEmpty()
    check lr.isValid()
    check lr.numCoordinates() == 4

  test "createLinearRing: 3D triangle (4 coords)":
    var ctx = initGeosContext()
    let lr = ctx.createLinearRing(ring3dTriangle)
    check lr of LinearRing
    check lr.type() == gtLinearRing
    check not lr.isEmpty()
    check lr.isValid()
    check lr.numCoordinates() == 4

  test "createLinearRing: 2D square (5 coords)":
    var ctx = initGeosContext()
    let lr = ctx.createLinearRing(ring2dSquare)
    check lr of LinearRing
    check lr.type() == gtLinearRing
    check not lr.isEmpty()
    check lr.isValid()
    check lr.numCoordinates() == 5

  test "createLinearRing: 3D square (5 coords)":
    var ctx = initGeosContext()
    let lr = ctx.createLinearRing(ring3dSquare)
    check lr of LinearRing
    check lr.type() == gtLinearRing
    check not lr.isEmpty()
    check lr.isValid()
    check lr.numCoordinates() == 5

  test "createLinearRing: fewer than 4 coords raises GeosGeomError":
    var ctx = initGeosContext()
    expect GeosGeomError:
      discard ctx.createLinearRing([(0.0, 0.0), (1.0, 1.0), (0.0, 0.0)])

  test "createLinearRing: empty coords raises GeosGeomError":
    var ctx = initGeosContext()
    let empty: seq[(float, float)] = @[]
    expect GeosGeomError:
      discard ctx.createLinearRing(empty)

  test "createLinearRing: 3D fewer than 4 coords raises GeosGeomError":
    var ctx = initGeosContext()
    expect GeosGeomError:
      discard ctx.createLinearRing([(0.0, 0.0, 1.0), (1.0, 1.0, 2.0), (0.0, 0.0, 1.0)])

  # ── Nil safety ──────────────────────────────────────────────────────────────
  test "Nil Safety: isEmpty raises GeosGeomError on nil":
    var lr: LinearRing
    expect GeosGeomError:
      discard lr.isEmpty()

  test "Nil Safety: isValid raises GeosGeomError on nil":
    var lr: LinearRing
    expect GeosGeomError:
      discard lr.isValid()

  test "Nil Safety: type raises GeosGeomError on nil":
    var lr: LinearRing
    expect GeosGeomError:
      discard lr.type()

  test "Nil Safety: numCoordinates raises GeosGeomError on nil":
    var lr: LinearRing
    expect GeosGeomError:
      discard lr.numCoordinates()

# ── Geometry properties ───────────────────────────────────────────────────────

suite "LinearRing geometry properties":
  test "numCoordinates: 2D triangle":
    var ctx = initGeosContext()
    let lr = ctx.createLinearRing(ring2dTriangle)
    check lr.numCoordinates() == 4

  test "numCoordinates: 2D square":
    var ctx = initGeosContext()
    let lr = ctx.createLinearRing(ring2dSquare)
    check lr.numCoordinates() == 5

  test "numCoordinates: 3D triangle":
    var ctx = initGeosContext()
    let lr = ctx.createLinearRing(ring3dTriangle)
    check lr.numCoordinates() == 4

  test "numCoordinates: 3D square":
    var ctx = initGeosContext()
    let lr = ctx.createLinearRing(ring3dSquare)
    check lr.numCoordinates() == 5

  test "length: 2D triangle perimeter":
    var ctx = initGeosContext()
    let lr = ctx.createLinearRing(ring2dTriangle)
    # sides: 4, 3, 5 (3-4-5 right triangle)
    check lr.length() == 12.0

  test "length: 2D square perimeter":
    var ctx = initGeosContext()
    let lr = ctx.createLinearRing(ring2dSquare)
    # 4 sides of length 4
    check lr.length() == 16.0

  test "area is always 0 for a LinearRing":
    var ctx = initGeosContext()
    let lr = ctx.createLinearRing(ring2dTriangle)
    check lr.area() == 0.0

  test "numGeometries is 1 for a LinearRing":
    var ctx = initGeosContext()
    let lr = ctx.createLinearRing(ring2dTriangle)
    check lr.numGeometries() == 1

# ── String representation ─────────────────────────────────────────────────────

suite "LinearRing string representation":
  test "$ 2D triangle":
    var ctx = initGeosContext()
    let lr = ctx.createLinearRing(ring2dTriangle)
    check $lr == "LinearRing(4 coords)"

  test "$ 3D triangle":
    var ctx = initGeosContext()
    let lr = ctx.createLinearRing(ring3dTriangle)
    check $lr == "LinearRing(4 coords)"

  test "$ 2D square":
    var ctx = initGeosContext()
    let lr = ctx.createLinearRing(ring2dSquare)
    check $lr == "LinearRing(5 coords)"

  test "$ 3D square":
    var ctx = initGeosContext()
    let lr = ctx.createLinearRing(ring3dSquare)
    check $lr == "LinearRing(5 coords)"

  test "$ nil LinearRing raises NilAccessDefect":
    var lr: LinearRing
    expect NilAccessDefect:
      discard $lr
