import unittest
import std/[strformat, math]
import nimgeos

# ── Test data ─────────────────────────────────────────────────────────────────
const point2dCases: array[3, (float, float)] = [
  (1.0, 2.0),
  (0.0, 0.0),
  (-10.5, 42.7),
]

const point3dCases: array[2, (float, float, float)] = [
  (1.0, 2.0, 3.0),
  (0.0, 0.0, 0.0),
]

# ── Construction ──────────────────────────────────────────────────────────────

suite "Point construction":
  for (x, y) in point2dCases:
    test &"createPoint: 2D ({x}, {y})":
      var ctx = initGeosContext()
      let p = ctx.createPoint(x, y)
      check p of Point
      check p.type() == gtPoint
      check not p.isEmpty()
      check p.isValid()
      check p.numCoordinates() == 1

  for (x, y, z) in point3dCases:
    test &"createPoint: 3D ({x}, {y}, {z})":
      var ctx = initGeosContext()
      let p = ctx.createPoint(x, y, z)
      check p of Point
      check p.type() == gtPoint
      check not p.isEmpty()
      check p.isValid()
      check p.numCoordinates() == 1

  # ── fromWKT produces concrete Point ─────────────────────────────────────────
  test "fromWKT: POINT produces a Point":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT (1 2)")
    check g of Point

  test "fromWKT: POINT Z produces a Point":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT Z (1 2 3)")
    check g of Point

  test "fromWKT: POINT EMPTY produces a Point":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT EMPTY")
    check g of Point
    check g.isEmpty()

  # ── Nil safety ──────────────────────────────────────────────────────────────
  test "Nil Safety: x raises GeosGeomError on nil":
    var p: Point
    expect GeosGeomError:
      discard p.x()

  test "Nil Safety: y raises GeosGeomError on nil":
    var p: Point
    expect GeosGeomError:
      discard p.y()

  test "Nil Safety: z raises GeosGeomError on nil":
    var p: Point
    expect GeosGeomError:
      discard p.z()

  test "Nil Safety: isEmpty raises GeosGeomError on nil":
    var p: Point
    expect GeosGeomError:
      discard p.isEmpty()

  test "Nil Safety: isValid raises GeosGeomError on nil":
    var p: Point
    expect GeosGeomError:
      discard p.isValid()

  test "Nil Safety: type raises GeosGeomError on nil":
    var p: Point
    expect GeosGeomError:
      discard p.type()

# ── Coordinate accessors ─────────────────────────────────────────────────────

suite "Point coordinate accessors":
  # ── 2D x/y ─────────────────────────────────────────────────────────────────
  for (x, y) in point2dCases:
    test &"2D: x, y for ({x}, {y})":
      var ctx = initGeosContext()
      let p = ctx.createPoint(x, y)
      check p.x() == x
      check p.y() == y

  # ── 2D z is NaN ────────────────────────────────────────────────────────────
  for (x, y) in point2dCases:
    test &"2D: z is NaN for ({x}, {y})":
      var ctx = initGeosContext()
      let p = ctx.createPoint(x, y)
      check p.z().isNaN()

  # ── 3D x/y/z ──────────────────────────────────────────────────────────────
  for (x, y, z) in point3dCases:
    test &"3D: x, y, z for ({x}, {y}, {z})":
      var ctx = initGeosContext()
      let p = ctx.createPoint(x, y, z)
      check p.x() == x
      check p.y() == y
      check p.z() == z

# ── String representation ─────────────────────────────────────────────────────

const point2dReprCases: array[3, (float, float, string)] = [
  (1.0, 2.0, "Point (1.0 2.0)"),
  (0.0, 0.0, "Point (0.0 0.0)"),
  (-10.5, 42.7, "Point (-10.5 42.7)"),
]

const point3dReprCases: array[2, (float, float, float, string)] = [
  (1.0, 2.0, 3.0, "Point (1.0 2.0 3.0)"),
  (0.0, 0.0, 0.0, "Point (0.0 0.0 0.0)"),
]


suite "Point string representation":
  # ── 2D $ ────────────────────────────────────────────────────────────────────
  for (x, y, expected) in point2dReprCases:
    test &"$ 2D: {expected}":
      var ctx = initGeosContext()
      check $ctx.createPoint(x, y) == expected

  # ── 3D $ ────────────────────────────────────────────────────────────────────
  for (x, y, z, expected) in point3dReprCases:
    test &"$ 3D: {expected}":
      var ctx = initGeosContext()
      check $ctx.createPoint(x, y, z) == expected

  # ── nil $ ───────────────────────────────────────────────────────────────────
  test "$ nil Point raises NilAccessDefect":
    var p: Point
    expect NilAccessDefect:
      discard $p
