import unittest
import nimgeos

# ── Test data ─────────────────────────────────────────────────────────────────
const
  ringA = @[(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0), (0.0, 0.0)]
  ringB = @[(10.0, 10.0), (11.0, 10.0), (11.0, 11.0), (10.0, 11.0), (10.0, 10.0)]
  ringC = @[(20.0, 20.0), (22.0, 20.0), (22.0, 22.0), (20.0, 22.0), (20.0, 20.0)]

suite "MultiPoint iteration":
  test "items: iterate over all points":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(1.0, 2.0)),
      Geometry(ctx.createPoint(3.0, 4.0)),
      Geometry(ctx.createPoint(5.0, 6.0)),
    ]
    let mp = ctx.createMultiGeometry(geoms)

    var count = 0
    for pt in MultiPoint(mp):
      check pt of Point
      check pt.type() == gtPoint
      count += 1
    check count == 3

  test "items: yields correct coordinate values":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(10.0, 20.0)),
      Geometry(ctx.createPoint(30.0, 40.0)),
    ]
    let mp = ctx.createMultiGeometry(geoms)

    var xs: seq[float] = @[]
    for pt in MultiPoint(mp):
      xs.add(pt.x())
    check xs == @[10.0, 30.0]

  test "items: single point MultiPoint":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[Geometry(ctx.createPoint(1.0, 1.0))]
    let mp = ctx.createMultiGeometry(geoms)

    var count = 0
    for pt in MultiPoint(mp):
      count += 1
    check count == 1

  test "items: yielded points are independent clones":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(1.0, 2.0)),
      Geometry(ctx.createPoint(3.0, 4.0)),
    ]
    let mp = ctx.createMultiGeometry(geoms)

    var collected: seq[Point] = @[]
    for pt in MultiPoint(mp):
      collected.add(pt)
    check collected.len == 2
    check collected[0].toWKT() != collected[1].toWKT()

suite "MultiLineString iteration":
  test "items: iterate over all line strings":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createLineString(@[(0.0, 0.0), (1.0, 1.0)])),
      Geometry(ctx.createLineString(@[(2.0, 2.0), (3.0, 3.0)])),
    ]
    let mls = ctx.createMultiGeometry(geoms)

    var count = 0
    for ls in MultiLineString(mls):
      check ls of LineString
      check ls.type() == gtLineString
      count += 1
    check count == 2

  test "items: access numPoints on each line":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createLineString(@[(0.0, 0.0), (1.0, 1.0), (2.0, 2.0)])),
      Geometry(ctx.createLineString(@[(3.0, 3.0), (4.0, 4.0)])),
    ]
    let mls = ctx.createMultiGeometry(geoms)

    var pointCounts: seq[int] = @[]
    for ls in MultiLineString(mls):
      pointCounts.add(ls.numPoints())
    check pointCounts == @[3, 2]

suite "MultiPolygon iteration":
  test "items: iterate over all polygons":
    var ctx = initGeosContext()
    let s1 = ctx.createLinearRing(ringA)
    let s2 = ctx.createLinearRing(ringB)
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPolygon(s1)),
      Geometry(ctx.createPolygon(s2)),
    ]
    let mp = ctx.createMultiGeometry(geoms)

    var count = 0
    for poly in MultiPolygon(mp):
      check poly of Polygon
      check poly.type() == gtPolygon
      count += 1
    check count == 2

  test "items: access area on each polygon":
    var ctx = initGeosContext()
    let s1 = ctx.createLinearRing(ringA)
    let s2 = ctx.createLinearRing(ringB)
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPolygon(s1)),
      Geometry(ctx.createPolygon(s2)),
    ]
    let mp = ctx.createMultiGeometry(geoms)

    var areas: seq[float] = @[]
    for poly in MultiPolygon(mp):
      areas.add(poly.area())
    check areas.len == 2
    check areas[0] == 1.0
    check areas[1] == 1.0

  test "items: three polygons":
    var ctx = initGeosContext()
    let s1 = ctx.createLinearRing(ringA)
    let s2 = ctx.createLinearRing(ringB)
    let s3 = ctx.createLinearRing(ringC)
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPolygon(s1)),
      Geometry(ctx.createPolygon(s2)),
      Geometry(ctx.createPolygon(s3)),
    ]
    let mp = ctx.createMultiGeometry(geoms)

    var count = 0
    for poly in MultiPolygon(mp):
      count += 1
    check count == 3

suite "GeometryCollection iteration":
  test "items: iterate over mixed types":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(ringA)
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(1.0, 2.0)),
      Geometry(ctx.createLineString(@[(0.0, 0.0), (1.0, 1.0)])),
      Geometry(ctx.createPolygon(shell)),
    ]
    let gc = ctx.createMultiGeometry(geoms)

    var types: seq[GeomType] = @[]
    for g in GeometryCollection(gc):
      types.add(g.type())
    check types == @[gtPoint, gtLineString, gtPolygon]

  test "items: each yielded geometry is concrete subtype":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(1.0, 2.0)),
      Geometry(ctx.createLineString(@[(0.0, 0.0), (1.0, 1.0)])),
    ]
    let gc = ctx.createMultiGeometry(geoms)

    var idx = 0
    for g in GeometryCollection(gc):
      if idx == 0:
        check g of Point
      elif idx == 1:
        check g of LineString
      idx += 1
    check idx == 2

  test "items: yielded geometries are independent clones":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(1.0, 2.0)),
      Geometry(ctx.createLineString(@[(0.0, 0.0), (1.0, 1.0)])),
    ]
    let gc = ctx.createMultiGeometry(geoms)

    var collected: seq[Geometry] = @[]
    for g in GeometryCollection(gc):
      collected.add(g)
    check collected.len == 2
    check cast[pointer](collected[0].handle) != cast[pointer](collected[1].handle)

suite "Iterator + geomN symmetry":
  test "iterator yields same WKT as geomN for MultiPoint":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(1.0, 2.0)),
      Geometry(ctx.createPoint(3.0, 4.0)),
      Geometry(ctx.createPoint(5.0, 6.0)),
    ]
    let mp = ctx.createMultiGeometry(geoms)

    var iterWkts: seq[string] = @[]
    for pt in MultiPoint(mp):
      iterWkts.add(pt.toWKT())

    for i in 0 ..< mp.numGeometries():
      check mp.geomN(i).toWKT() == iterWkts[i]

  test "iterator yields same WKT as geomN for GeometryCollection":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(ringA)
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(1.0, 2.0)),
      Geometry(ctx.createLineString(@[(0.0, 0.0), (1.0, 1.0)])),
      Geometry(ctx.createPolygon(shell)),
    ]
    let gc = ctx.createMultiGeometry(geoms)

    var iterWkts: seq[string] = @[]
    for g in GeometryCollection(gc):
      iterWkts.add(g.toWKT())

    for i in 0 ..< gc.numGeometries():
      check gc.geomN(i).toWKT() == iterWkts[i]

  test "geomN on single-element MultiPoint matches sub-geometry WKT":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[Geometry(ctx.createPoint(42.0, 24.0))]
    let mp = ctx.createMultiGeometry(geoms)
    check mp.numGeometries() == 1
    let sub = mp.geomN(0)
    check sub.toWKT() == "POINT (42 24)"
    check sub.type() == gtPoint

  test "geomN on single-element MultiPolygon matches sub-geometry WKT":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(ringA)
    var geoms: seq[Geometry] = @[Geometry(ctx.createPolygon(shell))]
    let mp = ctx.createMultiGeometry(geoms)
    check mp.numGeometries() == 1
    let sub = mp.geomN(0)
    check sub.type() == gtPolygon
    check sub.toWKT() == mp.geomN(0).toWKT()
