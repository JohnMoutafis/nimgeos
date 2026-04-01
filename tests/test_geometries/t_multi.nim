import unittest
import nimgeos

# ── Test data ─────────────────────────────────────────────────────────────────
const point2DA: (float, float) = (0.0, 0.0)
const point2DB: (float, float) = (1.0, 1.0)
const point2DC: (float, float) = (2.0, 2.0)

const lineString2DA: array[2, (float, float)] = [(0.0, 0.0), (1.0, 1.0)]
const lineString2DB: array[2, (float, float)] = [(2.0, 2.0), (3.0, 3.0)]
const lineString2DC: array[3, (float, float)] = [(4.0, 0.0), (5.0, 1.0), (6.0, 0.0)]

const linearRing2DA: array[5, (float, float)] = [
  (0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0), (0.0, 0.0),
]
const linearRing2DB: array[5, (float, float)] = [
  (2.0, 2.0), (3.0, 2.0), (3.0, 3.0), (2.0, 3.0), (2.0, 2.0),
]
const linearRing2DC: array[5, (float, float)] = [
  (5.0, 5.0), (7.0, 5.0), (7.0, 7.0), (5.0, 7.0), (5.0, 5.0),
]

# ══════════════════════════════════════════════════════════════════════════════
#  MultiPoint (all-Point input → inferred as MultiPoint)
# ══════════════════════════════════════════════════════════════════════════════

suite "MultiPoint construction":
  test "createMultiGeometry: 3 points → MultiPoint":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(point2DA[0], point2DA[1])),
      Geometry(ctx.createPoint(point2DB[0], point2DB[1])),
      Geometry(ctx.createPoint(point2DC[0], point2DC[1])),
    ]
    let mp = ctx.createMultiGeometry(geoms)
    check mp of MultiPoint
    check mp.type() == gtMultiPoint
    check not mp.isEmpty()
    check mp.isValid()
    check mp.numGeometries() == 3

  test "createMultiGeometry: single point → MultiPoint":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(5.0, 6.0)),
    ]
    let mp = ctx.createMultiGeometry(geoms)
    check mp of MultiPoint
    check mp.type() == gtMultiPoint
    check mp.numGeometries() == 1

  test "createMultiGeometry: 3D points → MultiPoint":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(1.0, 2.0, 3.0)),
      Geometry(ctx.createPoint(4.0, 5.0, 6.0)),
    ]
    let mp = ctx.createMultiGeometry(geoms)
    check mp of MultiPoint
    check mp.type() == gtMultiPoint
    check mp.numGeometries() == 2

  test "createMultiGeometry: empty seq raises GeosGeomError":
    var ctx = initGeosContext()
    var geoms = newSeq[Geometry]()
    expect GeosGeomError:
      discard ctx.createMultiGeometry(geoms)

  test "createMultiGeometry: input handles neutralised after creation":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(0.0, 0.0)),
      Geometry(ctx.createPoint(1.0, 1.0)),
    ]
    discard ctx.createMultiGeometry(geoms)
    check cast[pointer](geoms[0].handle) == nil
    check cast[pointer](geoms[1].handle) == nil

  # ── fromWKT produces concrete MultiPoint ────────────────────────────────────
  test "fromWKT: MULTIPOINT produces a MultiPoint":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("MULTIPOINT ((0 0), (1 1), (2 2))")
    check g of MultiPoint
    check g.numGeometries() == 3

  test "fromWKT: MULTIPOINT EMPTY produces a MultiPoint":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("MULTIPOINT EMPTY")
    check g of MultiPoint
    check g.isEmpty()

  # ── Nil safety ──────────────────────────────────────────────────────────────
  test "Nil Safety: isEmpty raises GeosGeomError on nil":
    var mp: MultiPoint
    expect GeosGeomError:
      discard mp.isEmpty()

  test "Nil Safety: isValid raises GeosGeomError on nil":
    var mp: MultiPoint
    expect GeosGeomError:
      discard mp.isValid()

  test "Nil Safety: type raises GeosGeomError on nil":
    var mp: MultiPoint
    expect GeosGeomError:
      discard mp.type()

  test "Nil Safety: numGeometries raises GeosGeomError on nil":
    var mp: MultiPoint
    expect GeosGeomError:
      discard mp.numGeometries()

  test "Nil Safety: geomN raises GeosGeomError on nil":
    var mp: MultiPoint
    expect GeosGeomError:
      discard mp.geomN(0)

# ── MultiPoint geomN ──────────────────────────────────────────────────────────

suite "MultiPoint geomN":
  test "geomN: returns Point subtype":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(5.0, 6.0)),
      Geometry(ctx.createPoint(7.0, 8.0)),
    ]
    let mp = ctx.createMultiGeometry(geoms)
    let sub = mp.geomN(0)
    check sub of Point
    check sub.type() == gtPoint

  test "geomN: each sub-geometry is accessible":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(point2DA[0], point2DA[1])),
      Geometry(ctx.createPoint(point2DB[0], point2DB[1])),
      Geometry(ctx.createPoint(point2DC[0], point2DC[1])),
    ]
    let mp = ctx.createMultiGeometry(geoms)
    for i in 0 ..< mp.numGeometries():
      let sub = mp.geomN(i)
      check sub of Point

  test "geomN: returned geometry is an independent clone":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(1.0, 2.0)),
    ]
    let mp = ctx.createMultiGeometry(geoms)
    let s1 = mp.geomN(0)
    let s2 = mp.geomN(0)
    check cast[pointer](s1.handle) != cast[pointer](s2.handle)

  test "geomN: negative index raises GeosGeomError":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[Geometry(ctx.createPoint(0.0, 0.0))]
    let mp = ctx.createMultiGeometry(geoms)
    expect GeosGeomError:
      discard mp.geomN(-1)

  test "geomN: index == numGeometries raises GeosGeomError":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[Geometry(ctx.createPoint(0.0, 0.0))]
    let mp = ctx.createMultiGeometry(geoms)
    expect GeosGeomError:
      discard mp.geomN(mp.numGeometries())

  test "geomN: index > numGeometries raises GeosGeomError":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[Geometry(ctx.createPoint(0.0, 0.0))]
    let mp = ctx.createMultiGeometry(geoms)
    expect GeosGeomError:
      discard mp.geomN(100)

# ── MultiPoint geometry properties ────────────────────────────────────────────

suite "MultiPoint geometry properties":
  test "numCoordinates: 3 points":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(0.0, 0.0)),
      Geometry(ctx.createPoint(1.0, 1.0)),
      Geometry(ctx.createPoint(2.0, 2.0)),
    ]
    let mp = ctx.createMultiGeometry(geoms)
    check mp.numCoordinates() == 3

  test "area is always 0 for MultiPoint":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(0.0, 0.0)),
      Geometry(ctx.createPoint(1.0, 1.0)),
    ]
    let mp = ctx.createMultiGeometry(geoms)
    check mp.area() == 0.0

  test "length is always 0 for MultiPoint":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(0.0, 0.0)),
      Geometry(ctx.createPoint(1.0, 1.0)),
    ]
    let mp = ctx.createMultiGeometry(geoms)
    check mp.length() == 0.0

# ── MultiPoint string representation ──────────────────────────────────────────

suite "MultiPoint string representation":
  test "$ with 3 points":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(0.0, 0.0)),
      Geometry(ctx.createPoint(1.0, 1.0)),
      Geometry(ctx.createPoint(2.0, 2.0)),
    ]
    let mp = ctx.createMultiGeometry(geoms)
    check $mp == "MultiPoint(3 points)"

  test "$ with 1 point":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[Geometry(ctx.createPoint(0.0, 0.0))]
    let mp = ctx.createMultiGeometry(geoms)
    check $mp == "MultiPoint(1 points)"

  test "$ nil MultiPoint raises NilAccessDefect":
    var mp: MultiPoint
    expect NilAccessDefect:
      discard $mp

# ══════════════════════════════════════════════════════════════════════════════
#  MultiLineString (all-LineString input → inferred as MultiLineString)
# ══════════════════════════════════════════════════════════════════════════════

suite "MultiLineString construction":
  test "createMultiGeometry: 2 lines → MultiLineString":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createLineString(lineString2DA)),
      Geometry(ctx.createLineString(lineString2DB)),
    ]
    let mls = ctx.createMultiGeometry(geoms)
    check mls of MultiLineString
    check mls.type() == gtMultiLineString
    check not mls.isEmpty()
    check mls.isValid()
    check mls.numGeometries() == 2

  test "createMultiGeometry: 3 lines → MultiLineString":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createLineString(lineString2DA)),
      Geometry(ctx.createLineString(lineString2DB)),
      Geometry(ctx.createLineString(lineString2DC)),
    ]
    let mls = ctx.createMultiGeometry(geoms)
    check mls of MultiLineString
    check mls.numGeometries() == 3

  test "createMultiGeometry: single line → MultiLineString":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[Geometry(ctx.createLineString(lineString2DA))]
    let mls = ctx.createMultiGeometry(geoms)
    check mls of MultiLineString
    check mls.numGeometries() == 1

  test "createMultiGeometry: line handles neutralised after creation":
    var ctx = initGeosContext()

    var geoms: seq[Geometry] = @[
      Geometry(ctx.createLineString(lineString2DA)),
      Geometry(ctx.createLineString(lineString2DB)),
    ]
    discard ctx.createMultiGeometry(geoms)
    check cast[pointer](geoms[0].handle) == nil
    check cast[pointer](geoms[1].handle) == nil

  # ── fromWKT produces concrete MultiLineString ──────────────────────────────
  test "fromWKT: MULTILINESTRING produces a MultiLineString":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("MULTILINESTRING ((0 0, 1 1), (2 2, 3 3))")
    check g of MultiLineString
    check g.numGeometries() == 2

  test "fromWKT: MULTILINESTRING EMPTY produces a MultiLineString":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("MULTILINESTRING EMPTY")
    check g of MultiLineString
    check g.isEmpty()

  # ── Nil safety ──────────────────────────────────────────────────────────────
  test "Nil Safety: isEmpty raises GeosGeomError on nil":
    var mls: MultiLineString
    expect GeosGeomError:
      discard mls.isEmpty()

  test "Nil Safety: isValid raises GeosGeomError on nil":
    var mls: MultiLineString
    expect GeosGeomError:
      discard mls.isValid()

  test "Nil Safety: type raises GeosGeomError on nil":
    var mls: MultiLineString
    expect GeosGeomError:
      discard mls.type()

  test "Nil Safety: numGeometries raises GeosGeomError on nil":
    var mls: MultiLineString
    expect GeosGeomError:
      discard mls.numGeometries()

  test "Nil Safety: geomN raises GeosGeomError on nil":
    var mls: MultiLineString
    expect GeosGeomError:
      discard mls.geomN(0)

# ── MultiLineString geomN ─────────────────────────────────────────────────────

suite "MultiLineString geomN":
  test "geomN: returns LineString subtype":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createLineString(lineString2DA)),
      Geometry(ctx.createLineString(lineString2DB)),
    ]
    let mls = ctx.createMultiGeometry(geoms)
    let sub = mls.geomN(0)
    check sub of LineString
    check sub.type() == gtLineString

  test "geomN: each sub-geometry is accessible":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createLineString(lineString2DA)),
      Geometry(ctx.createLineString(lineString2DB)),
      Geometry(ctx.createLineString(lineString2DC)),
    ]
    let mls = ctx.createMultiGeometry(geoms)
    for i in 0 ..< mls.numGeometries():
      let sub = mls.geomN(i)
      check sub of LineString

  test "geomN: returned geometry is an independent clone":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[Geometry(ctx.createLineString(lineString2DA))]
    let mls = ctx.createMultiGeometry(geoms)
    let s1 = mls.geomN(0)
    let s2 = mls.geomN(0)
    check cast[pointer](s1.handle) != cast[pointer](s2.handle)

  test "geomN: negative index raises GeosGeomError":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[Geometry(ctx.createLineString(lineString2DA))]
    let mls = ctx.createMultiGeometry(geoms)
    expect GeosGeomError:
      discard mls.geomN(-1)

  test "geomN: index == numGeometries raises GeosGeomError":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[Geometry(ctx.createLineString(lineString2DA))]
    let mls = ctx.createMultiGeometry(geoms)
    expect GeosGeomError:
      discard mls.geomN(mls.numGeometries())

  test "geomN: index > numGeometries raises GeosGeomError":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[Geometry(ctx.createLineString(lineString2DA))]
    let mls = ctx.createMultiGeometry(geoms)
    expect GeosGeomError:
      discard mls.geomN(100)

# ── MultiLineString geometry properties ───────────────────────────────────────

suite "MultiLineString geometry properties":
  test "numCoordinates: 2 lines of 2 points each":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createLineString(lineString2DA)),
      Geometry(ctx.createLineString(lineString2DB)),
    ]
    let mls = ctx.createMultiGeometry(geoms)
    check mls.numCoordinates() == 4

  test "length: sum of individual line lengths":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createLineString([(0.0, 0.0), (3.0, 4.0)])),  # length 5
      Geometry(ctx.createLineString([(0.0, 0.0), (0.0, 2.0)])),  # length 2
    ]
    let mls = ctx.createMultiGeometry(geoms)
    check abs(mls.length() - 7.0) < 1e-10

  test "area is always 0 for MultiLineString":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createLineString(lineString2DA)),
      Geometry(ctx.createLineString(lineString2DB)),
    ]
    let mls = ctx.createMultiGeometry(geoms)
    check mls.area() == 0.0

# ── MultiLineString string representation ─────────────────────────────────────

suite "MultiLineString string representation":
  test "$ with 2 lines":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createLineString(lineString2DA)),
      Geometry(ctx.createLineString(lineString2DB)),
    ]
    let mls = ctx.createMultiGeometry(geoms)
    check $mls == "MultiLineString(2 linestrings)"

  test "$ with 1 line":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[Geometry(ctx.createLineString(lineString2DA))]
    let mls = ctx.createMultiGeometry(geoms)
    check $mls == "MultiLineString(1 linestrings)"

  test "$ nil MultiLineString raises NilAccessDefect":
    var mls: MultiLineString
    expect NilAccessDefect:
      discard $mls

# ══════════════════════════════════════════════════════════════════════════════
#  MultiPolygon (all-Polygon input → inferred as MultiPolygon)
# ══════════════════════════════════════════════════════════════════════════════

suite "MultiPolygon construction":
  test "createMultiGeometry: 2 polygons → MultiPolygon":
    var ctx = initGeosContext()
    let shell1 = ctx.createLinearRing(linearRing2DA)
    let shell2 = ctx.createLinearRing(linearRing2DB)
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPolygon(shell1)),
      Geometry(ctx.createPolygon(shell2)),
    ]
    let mp = ctx.createMultiGeometry(geoms)
    check mp of MultiPolygon
    check mp.type() == gtMultiPolygon
    check not mp.isEmpty()
    check mp.isValid()
    check mp.numGeometries() == 2

  test "createMultiGeometry: 3 polygons → MultiPolygon":
    var ctx = initGeosContext()
    let s1 = ctx.createLinearRing(linearRing2DA)
    let s2 = ctx.createLinearRing(linearRing2DB)
    let s3 = ctx.createLinearRing(linearRing2DC)
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPolygon(s1)),
      Geometry(ctx.createPolygon(s2)),
      Geometry(ctx.createPolygon(s3)),
    ]
    let mp = ctx.createMultiGeometry(geoms)
    check mp of MultiPolygon
    check mp.numGeometries() == 3

  test "createMultiGeometry: single polygon → MultiPolygon":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(linearRing2DA)
    var geoms: seq[Geometry] = @[Geometry(ctx.createPolygon(shell))]
    let mp = ctx.createMultiGeometry(geoms)
    check mp of MultiPolygon
    check mp.numGeometries() == 1

  test "createMultiGeometry: polygon handles neutralised after creation":
    var ctx = initGeosContext()
    let s1 = ctx.createLinearRing(linearRing2DA)
    let s2 = ctx.createLinearRing(linearRing2DB)
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPolygon(s1)),
      Geometry(ctx.createPolygon(s2)),
    ]
    discard ctx.createMultiGeometry(geoms)
    check cast[pointer](geoms[0].handle) == nil
    check cast[pointer](geoms[1].handle) == nil

  # ── fromWKT produces concrete MultiPolygon ──────────────────────────────────
  test "fromWKT: MULTIPOLYGON produces a MultiPolygon":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(
      "MULTIPOLYGON (((0 0,1 0,1 1,0 1,0 0)),((2 2,3 2,3 3,2 3,2 2)))")
    check g of MultiPolygon
    check g.numGeometries() == 2

  test "fromWKT: MULTIPOLYGON EMPTY produces a MultiPolygon":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("MULTIPOLYGON EMPTY")
    check g of MultiPolygon
    check g.isEmpty()

  # ── Nil safety ──────────────────────────────────────────────────────────────
  test "Nil Safety: isEmpty raises GeosGeomError on nil":
    var mp: MultiPolygon
    expect GeosGeomError:
      discard mp.isEmpty()

  test "Nil Safety: isValid raises GeosGeomError on nil":
    var mp: MultiPolygon
    expect GeosGeomError:
      discard mp.isValid()

  test "Nil Safety: type raises GeosGeomError on nil":
    var mp: MultiPolygon
    expect GeosGeomError:
      discard mp.type()

  test "Nil Safety: numGeometries raises GeosGeomError on nil":
    var mp: MultiPolygon
    expect GeosGeomError:
      discard mp.numGeometries()

  test "Nil Safety: geomN raises GeosGeomError on nil":
    var mp: MultiPolygon
    expect GeosGeomError:
      discard mp.geomN(0)

# ── MultiPolygon geomN ────────────────────────────────────────────────────────

suite "MultiPolygon geomN":
  test "geomN: returns Polygon subtype":
    var ctx = initGeosContext()
    let s1 = ctx.createLinearRing(linearRing2DA)
    let s2 = ctx.createLinearRing(linearRing2DB)
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPolygon(s1)),
      Geometry(ctx.createPolygon(s2)),
    ]
    let mp = ctx.createMultiGeometry(geoms)
    let sub = mp.geomN(0)
    check sub of Polygon
    check sub.type() == gtPolygon

  test "geomN: each sub-geometry is accessible":
    var ctx = initGeosContext()
    let s1 = ctx.createLinearRing(linearRing2DA)
    let s2 = ctx.createLinearRing(linearRing2DB)
    let s3 = ctx.createLinearRing(linearRing2DC)
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPolygon(s1)),
      Geometry(ctx.createPolygon(s2)),
      Geometry(ctx.createPolygon(s3)),
    ]
    let mp = ctx.createMultiGeometry(geoms)
    for i in 0 ..< mp.numGeometries():
      let sub = mp.geomN(i)
      check sub of Polygon

  test "geomN: returned geometry is an independent clone":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(linearRing2DA)
    var geoms: seq[Geometry] = @[Geometry(ctx.createPolygon(shell))]
    let mp = ctx.createMultiGeometry(geoms)
    let s1 = mp.geomN(0)
    let s2 = mp.geomN(0)
    check cast[pointer](s1.handle) != cast[pointer](s2.handle)

  test "geomN: negative index raises GeosGeomError":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(linearRing2DA)
    var geoms: seq[Geometry] = @[Geometry(ctx.createPolygon(shell))]
    let mp = ctx.createMultiGeometry(geoms)
    expect GeosGeomError:
      discard mp.geomN(-1)

  test "geomN: index == numGeometries raises GeosGeomError":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(linearRing2DA)
    var geoms: seq[Geometry] = @[Geometry(ctx.createPolygon(shell))]
    let mp = ctx.createMultiGeometry(geoms)
    expect GeosGeomError:
      discard mp.geomN(mp.numGeometries())

  test "geomN: index > numGeometries raises GeosGeomError":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(linearRing2DA)
    var geoms: seq[Geometry] = @[Geometry(ctx.createPolygon(shell))]
    let mp = ctx.createMultiGeometry(geoms)
    expect GeosGeomError:
      discard mp.geomN(100)

# ── MultiPolygon geometry properties ──────────────────────────────────────────

suite "MultiPolygon geometry properties":
  test "numCoordinates: 2 unit-square polygons":
    var ctx = initGeosContext()
    let s1 = ctx.createLinearRing(linearRing2DA)
    let s2 = ctx.createLinearRing(linearRing2DB)
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPolygon(s1)),
      Geometry(ctx.createPolygon(s2)),
    ]
    let mp = ctx.createMultiGeometry(geoms)
    check mp.numCoordinates() == 10

  test "area: sum of individual polygon areas":
    var ctx = initGeosContext()
    let s1 = ctx.createLinearRing(linearRing2DA)
    let s2 = ctx.createLinearRing(linearRing2DB)
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPolygon(s1)),
      Geometry(ctx.createPolygon(s2)),
    ]
    let mp = ctx.createMultiGeometry(geoms)
    check abs(mp.area() - 2.0) < 1e-10

  test "area: different sized polygons":
    var ctx = initGeosContext()
    let s1 = ctx.createLinearRing(linearRing2DA)
    let s2 = ctx.createLinearRing(linearRing2DC)
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPolygon(s1)),
      Geometry(ctx.createPolygon(s2)),
    ]
    let mp = ctx.createMultiGeometry(geoms)
    check abs(mp.area() - 5.0) < 1e-10

  test "length: sum of perimeters":
    var ctx = initGeosContext()
    let s1 = ctx.createLinearRing(linearRing2DA)
    let s2 = ctx.createLinearRing(linearRing2DB)
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPolygon(s1)),
      Geometry(ctx.createPolygon(s2)),
    ]
    let mp = ctx.createMultiGeometry(geoms)
    check abs(mp.length() - 8.0) < 1e-10

# ── MultiPolygon string representation ────────────────────────────────────────

suite "MultiPolygon string representation":
  test "$ with 2 polygons":
    var ctx = initGeosContext()
    let s1 = ctx.createLinearRing(linearRing2DA)
    let s2 = ctx.createLinearRing(linearRing2DB)
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPolygon(s1)),
      Geometry(ctx.createPolygon(s2)),
    ]
    let mp = ctx.createMultiGeometry(geoms)
    check $mp == "MultiPolygon(2 polygons)"

  test "$ with 1 polygon":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(linearRing2DA)
    var geoms: seq[Geometry] = @[Geometry(ctx.createPolygon(shell))]
    let mp = ctx.createMultiGeometry(geoms)
    check $mp == "MultiPolygon(1 polygons)"

  test "$ nil MultiPolygon raises NilAccessDefect":
    var mp: MultiPolygon
    expect NilAccessDefect:
      discard $mp

# ══════════════════════════════════════════════════════════════════════════════
#  GeometryCollection (mixed input → inferred as GeometryCollection)
# ══════════════════════════════════════════════════════════════════════════════

suite "GeometryCollection construction":
  test "createMultiGeometry: mixed types → GeometryCollection":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(linearRing2DA)
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(0.0, 0.0)),
      Geometry(ctx.createLineString(lineString2DA)),
      Geometry(ctx.createPolygon(shell)),
    ]
    let gc = ctx.createMultiGeometry(geoms)
    check gc of GeometryCollection
    check gc.type() == gtGeometryCollection
    check not gc.isEmpty()
    check gc.isValid()
    check gc.numGeometries() == 3

  test "createMultiGeometry: Point + LineString → GeometryCollection":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(0.0, 0.0)),
      Geometry(ctx.createLineString(lineString2DA)),
    ]
    let gc = ctx.createMultiGeometry(geoms)
    check gc of GeometryCollection
    check gc.numGeometries() == 2

  test "createMultiGeometry: mixed handles neutralised after creation":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(0.0, 0.0)),
      Geometry(ctx.createLineString(lineString2DA)),
    ]
    discard ctx.createMultiGeometry(geoms)
    check cast[pointer](geoms[0].handle) == nil
    check cast[pointer](geoms[1].handle) == nil

  # ── fromWKT produces concrete GeometryCollection ────────────────────────────
  test "fromWKT: GEOMETRYCOLLECTION produces a GeometryCollection":
    var ctx = initGeosContext()
    let g = ctx.fromWKT(
      "GEOMETRYCOLLECTION (POINT (0 0), LINESTRING (0 0, 1 1))")
    check g of GeometryCollection
    check g.numGeometries() == 2

  test "fromWKT: GEOMETRYCOLLECTION EMPTY produces a GeometryCollection":
    var ctx = initGeosContext()
    let g = ctx.fromWKT("GEOMETRYCOLLECTION EMPTY")
    check g of GeometryCollection
    check g.isEmpty()

  # ── Nil safety ──────────────────────────────────────────────────────────────
  test "Nil Safety: isEmpty raises GeosGeomError on nil":
    var gc: GeometryCollection
    expect GeosGeomError:
      discard gc.isEmpty()

  test "Nil Safety: isValid raises GeosGeomError on nil":
    var gc: GeometryCollection
    expect GeosGeomError:
      discard gc.isValid()

  test "Nil Safety: type raises GeosGeomError on nil":
    var gc: GeometryCollection
    expect GeosGeomError:
      discard gc.type()

  test "Nil Safety: numGeometries raises GeosGeomError on nil":
    var gc: GeometryCollection
    expect GeosGeomError:
      discard gc.numGeometries()

  test "Nil Safety: geomN raises GeosGeomError on nil":
    var gc: GeometryCollection
    expect GeosGeomError:
      discard gc.geomN(0)

# ── GeometryCollection geomN ──────────────────────────────────────────────────

suite "GeometryCollection geomN":
  test "geomN: dispatches to correct concrete type":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(linearRing2DA)
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(1.0, 2.0)),
      Geometry(ctx.createLineString(lineString2DA)),
      Geometry(ctx.createPolygon(shell)),
    ]
    let gc = ctx.createMultiGeometry(geoms)
    check gc.geomN(0) of Point
    check gc.geomN(1) of LineString
    check gc.geomN(2) of Polygon

  test "geomN: each sub-geometry is accessible":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(linearRing2DA)
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(0.0, 0.0)),
      Geometry(ctx.createLineString(lineString2DA)),
      Geometry(ctx.createPolygon(shell)),
    ]
    let gc = ctx.createMultiGeometry(geoms)
    for i in 0 ..< gc.numGeometries():
      let sub = gc.geomN(i)
      check not sub.isNil

  test "geomN: returned geometry is an independent clone":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(1.0, 2.0)),
    ]
    let gc = ctx.createMultiGeometry(geoms)
    let s1 = gc.geomN(0)
    let s2 = gc.geomN(0)
    check cast[pointer](s1.handle) != cast[pointer](s2.handle)

  test "geomN: negative index raises GeosGeomError":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(0.0, 0.0)),
    ]
    let gc = ctx.createMultiGeometry(geoms)
    expect GeosGeomError:
      discard gc.geomN(-1)

  test "geomN: index == numGeometries raises GeosGeomError":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(0.0, 0.0)),
    ]
    let gc = ctx.createMultiGeometry(geoms)
    expect GeosGeomError:
      discard gc.geomN(gc.numGeometries())

  test "geomN: index > numGeometries raises GeosGeomError":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(0.0, 0.0)),
    ]
    let gc = ctx.createMultiGeometry(geoms)
    expect GeosGeomError:
      discard gc.geomN(100)

# ── GeometryCollection geometry properties ────────────────────────────────────

suite "GeometryCollection geometry properties":
  test "numCoordinates: mixed collection":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(linearRing2DA)
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(0.0, 0.0)),
      Geometry(ctx.createLineString(lineString2DA)),
      Geometry(ctx.createPolygon(shell)),
    ]
    let gc = ctx.createMultiGeometry(geoms)
    check gc.numCoordinates() == 8

  test "area: sum includes only polygons":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(linearRing2DA)
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(0.0, 0.0)),
      Geometry(ctx.createPolygon(shell)),
    ]
    let gc = ctx.createMultiGeometry(geoms)
    check abs(gc.area() - 1.0) < 1e-10

  test "length: sum includes only line-like geometries":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(0.0, 0.0)),
      Geometry(ctx.createLineString([(0.0, 0.0), (3.0, 4.0)])),
    ]
    let gc = ctx.createMultiGeometry(geoms)
    check abs(gc.length() - 5.0) < 1e-10

# ── GeometryCollection string representation ──────────────────────────────────

suite "GeometryCollection string representation":
  test "$ with 3 geometries":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing(linearRing2DA)
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(0.0, 0.0)),
      Geometry(ctx.createLineString(lineString2DA)),
      Geometry(ctx.createPolygon(shell)),
    ]
    let gc = ctx.createMultiGeometry(geoms)
    check $gc == "GeometryCollection(3 geometries)"

  test "$ with 1 geometry (mixed triggers collection)":
    var ctx = initGeosContext()
    var geoms: seq[Geometry] = @[
      Geometry(ctx.createPoint(0.0, 0.0)),
      Geometry(ctx.createLineString(lineString2DA)),
    ]
    let gc = ctx.createMultiGeometry(geoms)
    check $gc == "GeometryCollection(2 geometries)"

  test "$ nil GeometryCollection raises NilAccessDefect":
    var gc: GeometryCollection
    expect NilAccessDefect:
      discard $gc
