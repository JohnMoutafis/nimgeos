import unittest
import nimgeos

suite "CoordSeq construction":
  test "newCoordSeq: 2D with 3 coordinates":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 3, 2)
    check cs.len == 3
    check cs.dims == 2

  test "newCoordSeq: 3D with 2 coordinates":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 2, 3)
    check cs.len == 2
    check cs.dims == 3

  test "newCoordSeq: default dims is 2":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 5)
    check cs.dims == 2

  test "newCoordSeq: single coordinate":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 1)
    check cs.len == 1

suite "CoordSeq getters and setters":
  test "setX/getX round-trip":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 2)
    cs.setX(0, 1.5)
    cs.setX(1, 2.5)
    check cs.getX(0) == 1.5
    check cs.getX(1) == 2.5

  test "setY/getY round-trip":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 2)
    cs.setY(0, 3.5)
    cs.setY(1, 4.5)
    check cs.getY(0) == 3.5
    check cs.getY(1) == 4.5

  test "setZ/getZ round-trip":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 1, 3)
    cs.setZ(0, 9.9)
    check cs.getZ(0) == 9.9

  test "setCoord 2D":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 2)
    cs.setCoord(0, 1.0, 2.0)
    cs.setCoord(1, 3.0, 4.0)
    check cs.getCoord(0) == (1.0, 2.0)
    check cs.getCoord(1) == (3.0, 4.0)

  test "setCoord 3D":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 1, 3)
    cs.setCoord(0, 1.0, 2.0, 3.0)
    check cs.getCoord3D(0) == (1.0, 2.0, 3.0)

  test "negative coordinate values":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 1)
    cs.setCoord(0, -10.5, -20.7)
    check cs.getCoord(0) == (-10.5, -20.7)

  test "zero coordinate values":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 1)
    cs.setCoord(0, 0.0, 0.0)
    check cs.getCoord(0) == (0.0, 0.0)

suite "CoordSeq from geometry":
  test "coordSeq from Point":
    var ctx = initGeosContext()
    let p = ctx.createPoint(1.5, 2.5)
    var cs = p.coordSeq()
    check cs.len == 1
    check cs.getCoord(0) == (1.5, 2.5)

  test "coordSeq from 3D Point":
    var ctx = initGeosContext()
    let p = ctx.createPoint(1.0, 2.0, 3.0)
    var cs = p.coordSeq()
    check cs.len == 1
    check cs.dims == 3
    check cs.getCoord3D(0) == (1.0, 2.0, 3.0)

  test "coordSeq from LineString":
    var ctx = initGeosContext()
    let ls = ctx.createLineString(@[(0.0, 0.0), (1.0, 1.0), (2.0, 2.0)])
    var cs = ls.coordSeq()
    check cs.len == 3
    check cs.getCoord(0) == (0.0, 0.0)
    check cs.getCoord(1) == (1.0, 1.0)
    check cs.getCoord(2) == (2.0, 2.0)

  test "coordSeq from LinearRing":
    var ctx = initGeosContext()
    let ring = ctx.createLinearRing(@[
      (0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 0.0)
    ])
    var cs = ring.coordSeq()
    check cs.len == 4
    check cs.getCoord(0) == (0.0, 0.0)
    check cs.getCoord(3) == (0.0, 0.0)

  test "coordSeq is independent of source geometry":
    var ctx = initGeosContext()
    let p = ctx.createPoint(5.0, 6.0)
    var cs = p.coordSeq()
    # Modifying the coord seq should not affect the original geometry
    cs.setX(0, 99.0)
    check cs.getX(0) == 99.0
    # Original point unchanged
    check Point(p).x() == 5.0

suite "CoordSeq iteration":
  test "items iterator: 2D":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 3)
    cs.setCoord(0, 1.0, 2.0)
    cs.setCoord(1, 3.0, 4.0)
    cs.setCoord(2, 5.0, 6.0)

    var coords: seq[(float, float)] = @[]
    for coord in cs:
      coords.add(coord)
    check coords.len == 3
    check coords[0] == (1.0, 2.0)
    check coords[1] == (3.0, 4.0)
    check coords[2] == (5.0, 6.0)

  test "items3D iterator":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 2, 3)
    cs.setCoord(0, 1.0, 2.0, 3.0)
    cs.setCoord(1, 4.0, 5.0, 6.0)

    var coords: seq[(float, float, float)] = @[]
    for coord in cs.items3D:
      coords.add(coord)
    check coords.len == 2
    check coords[0] == (1.0, 2.0, 3.0)
    check coords[1] == (4.0, 5.0, 6.0)

  test "items iterator from geometry coordSeq":
    var ctx = initGeosContext()
    let ls = ctx.createLineString(@[(10.0, 20.0), (30.0, 40.0)])
    var cs = ls.coordSeq()
    var coords: seq[(float, float)] = @[]
    for coord in cs:
      coords.add(coord)
    check coords == @[(10.0, 20.0), (30.0, 40.0)]

  test "items iterator: empty-like single coordinate":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 1)
    cs.setCoord(0, 42.0, 24.0)
    var count = 0
    for coord in cs:
      check coord == (42.0, 24.0)
      count += 1
    check count == 1

suite "CoordSeq string representation":
  test "$ 2D":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 3, 2)
    check $cs == "CoordSeq(3 coords, 2D)"

  test "$ 3D":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 5, 3)
    check $cs == "CoordSeq(5 coords, 3D)"

suite "CoordSeq nil safety":
  test "len raises on nil handle":
    var cs: CoordSeq
    expect GeosGeomError:
      discard cs.len

  test "dims raises on nil handle":
    var cs: CoordSeq
    expect GeosGeomError:
      discard cs.dims

  test "getX raises on nil handle":
    var cs: CoordSeq
    expect GeosGeomError:
      discard cs.getX(0)

  test "setX raises on nil handle":
    var cs: CoordSeq
    expect GeosGeomError:
      cs.setX(0, 1.0)

  test "items raises on nil handle":
    var cs: CoordSeq
    expect GeosGeomError:
      for coord in cs:
        discard coord

  test "$ on nil":
    var cs: CoordSeq
    check $cs == "<nil CoordSeq>"

suite "CoordSeq clone":
  test "clone produces equal coordinates":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 2)
    cs.setCoord(0, 1.0, 2.0)
    cs.setCoord(1, 3.0, 4.0)
    var copy = cs.clone()
    check copy.len == 2
    check copy.getCoord(0) == (1.0, 2.0)
    check copy.getCoord(1) == (3.0, 4.0)

  test "clone is independent of original":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 1)
    cs.setCoord(0, 10.0, 20.0)
    var copy = cs.clone()
    copy.setX(0, 99.0)
    check copy.getX(0) == 99.0
    check cs.getX(0) == 10.0  # original unchanged

  test "clone 3D preserves Z":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 1, 3)
    cs.setCoord(0, 1.0, 2.0, 3.0)
    var copy = cs.clone()
    check copy.dims == 3
    check copy.getCoord3D(0) == (1.0, 2.0, 3.0)

  test "clone nil raises GeosGeomError":
    var cs: CoordSeq
    expect GeosGeomError:
      discard cs.clone()
