import unittest
import std/strformat
import nimgeos

# ── Test data ─────────────────────────────────────────────────────────────────
const polyUnit    = "POLYGON ((0 0, 4 0, 4 4, 0 4, 0 0))"
const polyInner   = "POLYGON ((1 1, 2 1, 2 2, 1 2, 1 1))"
const polyOverlap = "POLYGON ((2 2, 6 2, 6 6, 2 6, 2 2))"
const polyDisjoint = "POLYGON ((10 10, 11 10, 11 11, 10 11, 10 10))"
const polyTouching = "POLYGON ((4 0, 8 0, 8 4, 4 4, 4 0))"

const lineAB = "LINESTRING (0 0, 2 2)"
const lineCD = "LINESTRING (0 2, 2 0)"       # crosses lineAB
const lineEF = "LINESTRING (3 3, 4 4)"       # disjoint from lineAB
const lineThrough = "LINESTRING (-1 2, 5 2)" # crosses through polyUnit

const pointInside  = "POINT (2 2)"
const pointOutside = "POINT (5 5)"
const pointOnEdge  = "POINT (0 2)"           # on boundary of polyUnit

# ── equals ────────────────────────────────────────────────────────────────────

suite "equals":
  test "same WKT produces equal geometries":
    var ctx = initGeosContext()
    let a = ctx.fromWKT("POINT (1 2)")
    let b = ctx.fromWKT("POINT (1 2)")
    check a.equals(b)

  test "clone equals original":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyUnit)
    let b = a.clone()
    check a.equals(b)

  test "different coordinates are not equal":
    var ctx = initGeosContext()
    let a = ctx.fromWKT("POINT (0 0)")
    let b = ctx.fromWKT("POINT (1 1)")
    check not a.equals(b)

  test "different geometry types are not equal":
    var ctx = initGeosContext()
    let a = ctx.fromWKT("POINT (0 0)")
    let b = ctx.fromWKT("LINESTRING (0 0, 1 1)")
    check not a.equals(b)

  test "polygon equals itself":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyUnit)
    check a.equals(a)

  test "linestring equals its clone":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(lineAB)
    let b = a.clone()
    check a.equals(b)

  test "Nil Safety: g nil raises GeosGeomError":
    var g: Geometry
    var ctx = initGeosContext()
    let other = ctx.fromWKT("POINT (0 0)")
    expect GeosGeomError:
      discard g.equals(other)

  test "Nil Safety: other nil raises GeosGeomError":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT (0 0)")
    var other: Geometry
    expect GeosGeomError:
      discard g.equals(other)

# ── intersects ────────────────────────────────────────────────────────────────

suite "intersects":
  test "overlapping polygons intersect":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyUnit)
    let b = ctx.fromWKT(polyOverlap)
    check a.intersects(b)

  test "point inside polygon intersects":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyUnit)
    let pt = ctx.fromWKT(pointInside)
    check poly.intersects(pt)

  test "crossing lines intersect":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(lineAB)
    let b = ctx.fromWKT(lineCD)
    check a.intersects(b)

  test "disjoint polygons do not intersect":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyUnit)
    let b = ctx.fromWKT(polyDisjoint)
    check not a.intersects(b)

  test "touching polygons intersect":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyUnit)
    let b = ctx.fromWKT(polyTouching)
    check a.intersects(b)

  test "point outside polygon does not intersect":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyUnit)
    let pt = ctx.fromWKT(pointOutside)
    check not poly.intersects(pt)

  test "Nil Safety: g nil raises GeosGeomError":
    var g: Geometry
    var ctx = initGeosContext()
    let other = ctx.fromWKT("POINT (0 0)")
    expect GeosGeomError:
      discard g.intersects(other)

  test "Nil Safety: other nil raises GeosGeomError":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT (0 0)")
    var other: Geometry
    expect GeosGeomError:
      discard g.intersects(other)

# ── contains ──────────────────────────────────────────────────────────────────

suite "contains":
  test "polygon contains inner polygon":
    var ctx = initGeosContext()
    let outer = ctx.fromWKT(polyUnit)
    let inner = ctx.fromWKT(polyInner)
    check outer.contains(inner)

  test "inner polygon does NOT contain outer":
    var ctx = initGeosContext()
    let outer = ctx.fromWKT(polyUnit)
    let inner = ctx.fromWKT(polyInner)
    check not inner.contains(outer)

  test "polygon contains interior point":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyUnit)
    let pt = ctx.fromWKT(pointInside)
    check poly.contains(pt)

  test "polygon does NOT contain exterior point":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyUnit)
    let pt = ctx.fromWKT(pointOutside)
    check not poly.contains(pt)

  test "geometry contains itself":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyUnit)
    check poly.contains(poly)

  test "polygon does NOT contain disjoint polygon":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyUnit)
    let b = ctx.fromWKT(polyDisjoint)
    check not a.contains(b)

  test "Nil Safety: g nil raises GeosGeomError":
    var g: Geometry
    var ctx = initGeosContext()
    let other = ctx.fromWKT("POINT (0 0)")
    expect GeosGeomError:
      discard g.contains(other)

  test "Nil Safety: other nil raises GeosGeomError":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT (0 0)")
    var other: Geometry
    expect GeosGeomError:
      discard g.contains(other)

# ── within ────────────────────────────────────────────────────────────────────

suite "within":
  test "inner polygon is within outer":
    var ctx = initGeosContext()
    let outer = ctx.fromWKT(polyUnit)
    let inner = ctx.fromWKT(polyInner)
    check inner.within(outer)

  test "outer polygon is NOT within inner":
    var ctx = initGeosContext()
    let outer = ctx.fromWKT(polyUnit)
    let inner = ctx.fromWKT(polyInner)
    check not outer.within(inner)

  test "point inside polygon is within":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyUnit)
    let pt = ctx.fromWKT(pointInside)
    check pt.within(poly)

  test "point outside polygon is NOT within":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyUnit)
    let pt = ctx.fromWKT(pointOutside)
    check not pt.within(poly)

  test "geometry is within itself":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyUnit)
    check poly.within(poly)

  test "disjoint polygon is NOT within":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyUnit)
    let b = ctx.fromWKT(polyDisjoint)
    check not b.within(a)

  test "Nil Safety: g nil raises GeosGeomError":
    var g: Geometry
    var ctx = initGeosContext()
    let other = ctx.fromWKT("POINT (0 0)")
    expect GeosGeomError:
      discard g.within(other)

  test "Nil Safety: other nil raises GeosGeomError":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT (0 0)")
    var other: Geometry
    expect GeosGeomError:
      discard g.within(other)

# ── touches ───────────────────────────────────────────────────────────────────

suite "touches":
  test "touching polygons":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyUnit)
    let b = ctx.fromWKT(polyTouching)
    check a.touches(b)

  test "overlapping polygons do NOT touch":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyUnit)
    let b = ctx.fromWKT(polyOverlap)
    check not a.touches(b)

  test "disjoint polygons do NOT touch":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyUnit)
    let b = ctx.fromWKT(polyDisjoint)
    check not a.touches(b)

  test "point on boundary touches polygon":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyUnit)
    let pt = ctx.fromWKT(pointOnEdge)
    check pt.touches(poly)

  test "point inside polygon does NOT touch":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyUnit)
    let pt = ctx.fromWKT(pointInside)
    check not pt.touches(poly)

  test "touching is symmetric":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyUnit)
    let b = ctx.fromWKT(polyTouching)
    check a.touches(b) == b.touches(a)

  test "Nil Safety: g nil raises GeosGeomError":
    var g: Geometry
    var ctx = initGeosContext()
    let other = ctx.fromWKT("POINT (0 0)")
    expect GeosGeomError:
      discard g.touches(other)

  test "Nil Safety: other nil raises GeosGeomError":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT (0 0)")
    var other: Geometry
    expect GeosGeomError:
      discard g.touches(other)

# ── disjoint ──────────────────────────────────────────────────────────────────

suite "disjoint":
  test "disjoint polygons":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyUnit)
    let b = ctx.fromWKT(polyDisjoint)
    check a.disjoint(b)

  test "overlapping polygons are NOT disjoint":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyUnit)
    let b = ctx.fromWKT(polyOverlap)
    check not a.disjoint(b)

  test "touching polygons are NOT disjoint":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyUnit)
    let b = ctx.fromWKT(polyTouching)
    check not a.disjoint(b)

  test "disjoint lines":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(lineAB)
    let b = ctx.fromWKT(lineEF)
    check a.disjoint(b)

  test "crossing lines are NOT disjoint":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(lineAB)
    let b = ctx.fromWKT(lineCD)
    check not a.disjoint(b)

  test "disjoint is symmetric":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyUnit)
    let b = ctx.fromWKT(polyDisjoint)
    check a.disjoint(b) == b.disjoint(a)

  test "Nil Safety: g nil raises GeosGeomError":
    var g: Geometry
    var ctx = initGeosContext()
    let other = ctx.fromWKT("POINT (0 0)")
    expect GeosGeomError:
      discard g.disjoint(other)

  test "Nil Safety: other nil raises GeosGeomError":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT (0 0)")
    var other: Geometry
    expect GeosGeomError:
      discard g.disjoint(other)

# ── crosses ───────────────────────────────────────────────────────────────────

suite "crosses":
  test "crossing lines":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(lineAB)
    let b = ctx.fromWKT(lineCD)
    check a.crosses(b)

  test "disjoint lines do NOT cross":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(lineAB)
    let b = ctx.fromWKT(lineEF)
    check not a.crosses(b)

  test "line through polygon crosses":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyUnit)
    let line = ctx.fromWKT(lineThrough)
    check line.crosses(poly)

  test "line inside polygon does NOT cross":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyUnit)
    let line = ctx.fromWKT("LINESTRING (1 1, 2 2)")
    check not line.crosses(poly)

  test "crossing is symmetric for lines":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(lineAB)
    let b = ctx.fromWKT(lineCD)
    check a.crosses(b) == b.crosses(a)

  test "Nil Safety: g nil raises GeosGeomError":
    var g: Geometry
    var ctx = initGeosContext()
    let other = ctx.fromWKT("POINT (0 0)")
    expect GeosGeomError:
      discard g.crosses(other)

  test "Nil Safety: other nil raises GeosGeomError":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT (0 0)")
    var other: Geometry
    expect GeosGeomError:
      discard g.crosses(other)

# ── overlaps ──────────────────────────────────────────────────────────────────

suite "overlaps":
  test "partially overlapping polygons":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyUnit)
    let b = ctx.fromWKT(polyOverlap)
    check a.overlaps(b)

  test "contained polygon does NOT overlap":
    var ctx = initGeosContext()
    let outer = ctx.fromWKT(polyUnit)
    let inner = ctx.fromWKT(polyInner)
    check not outer.overlaps(inner)

  test "disjoint polygons do NOT overlap":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyUnit)
    let b = ctx.fromWKT(polyDisjoint)
    check not a.overlaps(b)

  test "same geometry does NOT overlap itself":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyUnit)
    check not a.overlaps(a)

  test "touching polygons do NOT overlap":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyUnit)
    let b = ctx.fromWKT(polyTouching)
    check not a.overlaps(b)

  test "overlaps is symmetric":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyUnit)
    let b = ctx.fromWKT(polyOverlap)
    check a.overlaps(b) == b.overlaps(a)

  test "Nil Safety: g nil raises GeosGeomError":
    var g: Geometry
    var ctx = initGeosContext()
    let other = ctx.fromWKT("POINT (0 0)")
    expect GeosGeomError:
      discard g.overlaps(other)

  test "Nil Safety: other nil raises GeosGeomError":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("POINT (0 0)")
    var other: Geometry
    expect GeosGeomError:
      discard g.overlaps(other)

# ── Predicate relationships ───────────────────────────────────────────────────

const relationshipCases: array[5, (string, string, string)] = [
  (polyUnit, polyOverlap, "overlapping polygons"),
  (polyUnit, polyDisjoint, "disjoint polygons"),
  (polyUnit, polyTouching, "touching polygons"),
  (polyUnit, polyInner, "contained polygon"),
  (lineAB, lineCD, "crossing lines"),
]

suite "Predicate relationships":
  for (wktA, wktB, label) in relationshipCases:
    test &"disjoint is the inverse of intersects: {label}":
      var ctx = initGeosContext()
      let a = ctx.fromWKT(wktA)
      let b = ctx.fromWKT(wktB)
      check a.disjoint(b) == (not a.intersects(b))

  test "contains/within symmetry: outer contains inner iff inner within outer":
    var ctx = initGeosContext()
    let outer = ctx.fromWKT(polyUnit)
    let inner = ctx.fromWKT(polyInner)
    check outer.contains(inner) == inner.within(outer)

  test "contains/within symmetry: inner does not contain outer":
    var ctx = initGeosContext()
    let outer = ctx.fromWKT(polyUnit)
    let inner = ctx.fromWKT(polyInner)
    check inner.contains(outer) == outer.within(inner)

  test "contains/within symmetry: point inside polygon":
    var ctx = initGeosContext()
    let poly = ctx.fromWKT(polyUnit)
    let pt = ctx.fromWKT(pointInside)
    check poly.contains(pt) == pt.within(poly)

  test "touching geometries intersect but do not overlap":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyUnit)
    let b = ctx.fromWKT(polyTouching)
    check a.touches(b)
    check a.intersects(b)
    check not a.overlaps(b)

  test "contained geometry intersects but does not overlap":
    var ctx = initGeosContext()
    let outer = ctx.fromWKT(polyUnit)
    let inner = ctx.fromWKT(polyInner)
    check outer.contains(inner)
    check outer.intersects(inner)
    check not outer.overlaps(inner)

  test "equal geometries are not disjoint":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(polyUnit)
    let b = ctx.fromWKT(polyUnit)
    check a.equals(b)
    check not a.disjoint(b)
    check a.intersects(b)
