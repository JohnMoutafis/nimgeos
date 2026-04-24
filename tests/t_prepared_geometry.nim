import unittest
import std/times
import nimgeos

const outerPoly = "POLYGON ((0 0, 20 0, 20 20, 0 20, 0 0))"
const innerPoly = "POLYGON ((5 5, 10 5, 10 10, 5 10, 5 5))"
const overlapPoly = "POLYGON ((15 15, 25 15, 25 25, 15 25, 15 15))"
const disjointPoly = "POLYGON ((30 30, 35 30, 35 35, 30 35, 30 30))"

suite "toPreparedGeometry":
  test "creates prepared geometry for valid polygon":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(outerPoly)
    let pg = g.toPreparedGeometry()
    check pg != nil

  test "prepared geometry remains usable after source variable reassignment":
    var ctx = initGeosContext()
    var g = ctx.fromWKT(outerPoly)
    let pg = g.toPreparedGeometry()
    g = ctx.fromWKT(disjointPoly)
    let inside = ctx.fromWKT("POINT (2 2)")
    check pg.preparedContains(inside)

  test "nil geometry raises GeosGeomError":
    var g: Geometry
    expect GeosGeomError:
      discard g.toPreparedGeometry()

suite "preparedContains":
  test "prepared contains inner polygon":
    var ctx = initGeosContext()
    let pg = ctx.fromWKT(outerPoly).toPreparedGeometry()
    let inner = ctx.fromWKT(innerPoly)
    check pg.preparedContains(inner)

  test "prepared does not contain disjoint polygon":
    var ctx = initGeosContext()
    let pg = ctx.fromWKT(outerPoly).toPreparedGeometry()
    let disjoint = ctx.fromWKT(disjointPoly)
    check not pg.preparedContains(disjoint)

  test "prepared contains interior point":
    var ctx = initGeosContext()
    let pg = ctx.fromWKT(outerPoly).toPreparedGeometry()
    let p = ctx.fromWKT("POINT (1 1)")
    check pg.preparedContains(p)

  test "prepared contains matches non-prepared contains":
    var ctx = initGeosContext()
    let base = ctx.fromWKT(outerPoly)
    let pg = base.toPreparedGeometry()
    let probe = ctx.fromWKT(overlapPoly)
    check pg.preparedContains(probe) == base.contains(probe)

  test "passing Geometry to preparedContains raises GeosGeomError":
    var ctx = initGeosContext()
    let base = ctx.fromWKT(outerPoly)
    let probe = ctx.fromWKT(innerPoly)
    expect GeosGeomError:
      discard base.preparedContains(probe)

suite "preparedIntersects":
  test "prepared intersects overlapping polygon":
    var ctx = initGeosContext()
    let pg = ctx.fromWKT(outerPoly).toPreparedGeometry()
    let overlap = ctx.fromWKT(overlapPoly)
    check pg.preparedIntersects(overlap)

  test "prepared does not intersect disjoint polygon":
    var ctx = initGeosContext()
    let pg = ctx.fromWKT(outerPoly).toPreparedGeometry()
    let disjoint = ctx.fromWKT(disjointPoly)
    check not pg.preparedIntersects(disjoint)

  test "prepared intersects matches non-prepared intersects":
    var ctx = initGeosContext()
    let base = ctx.fromWKT(outerPoly)
    let pg = base.toPreparedGeometry()
    let probe = ctx.fromWKT(overlapPoly)
    check pg.preparedIntersects(probe) == base.intersects(probe)

  test "prepared intersects performance sanity on repeated point checks":
    var ctx = initGeosContext()
    let base = ctx.fromWKT(outerPoly)
    let pg = base.toPreparedGeometry()

    var points: seq[Geometry] = @[]
    for i in 0 ..< 4000:
      let x = (i mod 80).float * 0.4
      let y = (i div 80).float * 0.4
      points.add(ctx.createPoint(x, y))

    var countPrepared = 0
    let tPreparedStart = cpuTime()
    for p in points:
      if pg.preparedIntersects(p):
        inc countPrepared
    let preparedElapsed = cpuTime() - tPreparedStart

    var countPlain = 0
    let tPlainStart = cpuTime()
    for p in points:
      if base.intersects(p):
        inc countPlain
    let plainElapsed = cpuTime() - tPlainStart

    check countPrepared == countPlain
    # Keep this robust across noisy CI environments.
    check preparedElapsed <= plainElapsed * 5.0

  test "passing Geometry to preparedIntersects raises GeosGeomError":
    var ctx = initGeosContext()
    let base = ctx.fromWKT(outerPoly)
    let probe = ctx.fromWKT(overlapPoly)
    expect GeosGeomError:
      discard base.preparedIntersects(probe)

suite "preparedCovers":
  test "prepared covers interior point":
    var ctx = initGeosContext()
    let pg = ctx.fromWKT(outerPoly).toPreparedGeometry()
    let p = ctx.fromWKT("POINT (0 10)")
    check pg.preparedCovers(p)

  test "prepared covers inner polygon":
    var ctx = initGeosContext()
    let pg = ctx.fromWKT(outerPoly).toPreparedGeometry()
    let inner = ctx.fromWKT(innerPoly)
    check pg.preparedCovers(inner)

  test "prepared does not cover disjoint polygon":
    var ctx = initGeosContext()
    let pg = ctx.fromWKT(outerPoly).toPreparedGeometry()
    let disjoint = ctx.fromWKT(disjointPoly)
    check not pg.preparedCovers(disjoint)

  test "prepared covers agrees with non-prepared contains for inner polygon":
    var ctx = initGeosContext()
    let base = ctx.fromWKT(outerPoly)
    let pg = base.toPreparedGeometry()
    let inner = ctx.fromWKT(innerPoly)
    check pg.preparedCovers(inner) == base.contains(inner)

  test "passing Geometry to preparedCovers raises GeosGeomError":
    var ctx = initGeosContext()
    let base = ctx.fromWKT(outerPoly)
    let probe = ctx.fromWKT(innerPoly)
    expect GeosGeomError:
      discard base.preparedCovers(probe)

suite "preparedCoveredBy":
  test "inner polygon prepared is covered by outer polygon":
    var ctx = initGeosContext()
    let pg = ctx.fromWKT(innerPoly).toPreparedGeometry()
    let outer = ctx.fromWKT(outerPoly)
    check pg.preparedCoveredBy(outer)

  test "outer polygon prepared is not covered by inner polygon":
    var ctx = initGeosContext()
    let pg = ctx.fromWKT(outerPoly).toPreparedGeometry()
    let inner = ctx.fromWKT(innerPoly)
    check not pg.preparedCoveredBy(inner)

  test "preparedCoveredBy matches reverse preparedCovers relation":
    var ctx = initGeosContext()
    let a = ctx.fromWKT(innerPoly).toPreparedGeometry()
    let b = ctx.fromWKT(outerPoly)
    check a.preparedCoveredBy(b) == b.toPreparedGeometry().preparedCovers(ctx.fromWKT(innerPoly))

  test "preparedCoveredBy handles edge-overlap case":
    var ctx = initGeosContext()
    let edgeLine = ctx.fromWKT("LINESTRING (0 5, 20 5)").toPreparedGeometry()
    let outer = ctx.fromWKT(outerPoly)
    check edgeLine.preparedCoveredBy(outer)

  test "passing Geometry to preparedCoveredBy raises GeosGeomError":
    var ctx = initGeosContext()
    let base = ctx.fromWKT(innerPoly)
    let probe = ctx.fromWKT(outerPoly)
    expect GeosGeomError:
      discard base.preparedCoveredBy(probe)
