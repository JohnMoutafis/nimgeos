import unittest
import std/math
import nimgeos

suite "Point with NaN coordinates":
  test "createPoint with NaN x and y succeeds":
    var ctx = initGeosContext()
    try:
      let p = ctx.createPoint(NaN, NaN)
      # If creation succeeds, x() and y() should return NaN
      check p.x().isNaN()
      check p.y().isNaN()
    except GeosGeomError:
      # Some GEOS versions may reject NaN outright
      check true

  test "Point with NaN coords is not valid":
    var ctx = initGeosContext()
    try:
      let p = ctx.createPoint(NaN, NaN)
      check not p.isValid()
    except GeosGeomError:
      check true

  test "Point with NaN coords is not empty":
    var ctx = initGeosContext()
    try:
      let p = ctx.createPoint(NaN, NaN)
      # NaN point is technically not EMPTY — it has coordinates, just invalid ones
      check not p.isEmpty()
    except GeosGeomError:
      check true

suite "Point with Infinity coordinates":
  test "createPoint with Inf and -Inf":
    var ctx = initGeosContext()
    try:
      let p = ctx.createPoint(Inf, -Inf)
      check p.x() == Inf
      check p.y() == -Inf
    except GeosGeomError:
      check true

  test "Point with Inf coords isValid is false":
    var ctx = initGeosContext()
    try:
      let p = ctx.createPoint(Inf, -Inf)
      check not p.isValid()
    except GeosGeomError:
      check true

  test "createPoint with positive Inf in both":
    var ctx = initGeosContext()
    try:
      let p = ctx.createPoint(Inf, Inf)
      check p.x() == Inf
      check p.y() == Inf
      check not p.isValid()
    except GeosGeomError:
      check true

suite "Point with very large values":
  test "createPoint with 1e308":
    var ctx = initGeosContext()
    let p = ctx.createPoint(1e308, 1e308)
    check p.x() == 1e308
    check p.y() == 1e308
    check not p.isEmpty()

  test "Point with 1e308 is valid":
    var ctx = initGeosContext()
    let p = ctx.createPoint(1e308, 1e308)
    # Large but finite values should be valid
    check p.isValid()

  test "createPoint with negative large values":
    var ctx = initGeosContext()
    let p = ctx.createPoint(-1e308, -1e308)
    check p.x() == -1e308
    check p.y() == -1e308
    check p.isValid()

suite "Point with very small values":
  test "createPoint with 1e-308":
    var ctx = initGeosContext()
    let p = ctx.createPoint(1e-308, 1e-308)
    check p.x() == 1e-308
    check p.y() == 1e-308
    check not p.isEmpty()
    check p.isValid()

  test "createPoint with subnormal values":
    var ctx = initGeosContext()
    let p = ctx.createPoint(5e-324, 5e-324)
    check p.x() == 5e-324
    check p.y() == 5e-324
    check p.isValid()

suite "Point with mixed NaN and normal values":
  test "createPoint with x=1.0 and y=NaN":
    var ctx = initGeosContext()
    try:
      let p = ctx.createPoint(1.0, NaN)
      check p.x() == 1.0
      check p.y().isNaN()
      check not p.isValid()
    except GeosGeomError:
      check true

  test "createPoint with x=NaN and y=2.0":
    var ctx = initGeosContext()
    try:
      let p = ctx.createPoint(NaN, 2.0)
      check p.x().isNaN()
      check p.y() == 2.0
      check not p.isValid()
    except GeosGeomError:
      check true

suite "3D Point with NaN Z":
  test "createPoint 3D with NaN Z":
    var ctx = initGeosContext()
    try:
      let p = ctx.createPoint(1.0, 2.0, NaN)
      check p.x() == 1.0
      check p.y() == 2.0
      check p.z().isNaN()
    except GeosGeomError:
      check true

  test "3D point with NaN Z: isValid may still be true (Z often ignored)":
    var ctx = initGeosContext()
    try:
      let p = ctx.createPoint(1.0, 2.0, NaN)
      # GEOS typically validates only X/Y, so this might be valid
      # We just check it doesn't crash
      discard p.isValid()
    except GeosGeomError:
      check true

  test "createPoint 3D with all NaN":
    var ctx = initGeosContext()
    try:
      let p = ctx.createPoint(NaN, NaN, NaN)
      check p.x().isNaN()
      check p.y().isNaN()
      check p.z().isNaN()
      check not p.isValid()
    except GeosGeomError:
      check true

  test "createPoint 3D with Inf Z":
    var ctx = initGeosContext()
    try:
      let p = ctx.createPoint(1.0, 2.0, Inf)
      check p.x() == 1.0
      check p.y() == 2.0
      check p.z() == Inf
    except GeosGeomError:
      check true

suite "LineString with NaN in coordinates":
  test "LineString with NaN in second point":
    var ctx = initGeosContext()
    try:
      let ls = ctx.createLineString(@[(0.0, 0.0), (NaN, 1.0)])
      check not ls.isValid()
      check ls.numCoordinates() == 2
    except GeosGeomError:
      check true

  test "LineString with NaN in first point":
    var ctx = initGeosContext()
    try:
      let ls = ctx.createLineString(@[(NaN, NaN), (1.0, 1.0)])
      check not ls.isValid()
    except GeosGeomError:
      check true

  test "LineString with Inf coordinates":
    var ctx = initGeosContext()
    try:
      let ls = ctx.createLineString(@[(0.0, 0.0), (Inf, Inf)])
      check not ls.isValid()
    except GeosGeomError:
      check true

  test "LineString with all NaN coordinates":
    var ctx = initGeosContext()
    try:
      let ls = ctx.createLineString(@[(NaN, NaN), (NaN, NaN)])
      check not ls.isValid()
    except GeosGeomError:
      check true

  test "LineString length with NaN coords is NaN":
    var ctx = initGeosContext()
    try:
      let ls = ctx.createLineString(@[(0.0, 0.0), (NaN, 1.0)])
      let len = ls.length()
      check len.isNaN()
    except GeosGeomError:
      check true

suite "CoordSeq with NaN":
  test "setX with NaN round-trips":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 1, 2)
    cs.setX(0, NaN)
    cs.setY(0, 0.0)
    check cs.getX(0).isNaN()

  test "setY with NaN round-trips":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 1, 2)
    cs.setX(0, 0.0)
    cs.setY(0, NaN)
    check cs.getY(0).isNaN()

  test "setZ with NaN round-trips":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 1, 3)
    cs.setX(0, 0.0)
    cs.setY(0, 0.0)
    cs.setZ(0, NaN)
    check cs.getZ(0).isNaN()

  test "setCoord with NaN values":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 1, 2)
    cs.setCoord(0, NaN, NaN)
    let (x, y) = cs.getCoord(0)
    check x.isNaN()
    check y.isNaN()

  test "setCoord 3D with NaN values":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 1, 3)
    cs.setCoord(0, NaN, NaN, NaN)
    let (x, y, z) = cs.getCoord3D(0)
    check x.isNaN()
    check y.isNaN()
    check z.isNaN()

suite "CoordSeq with Infinity":
  test "setX with Inf round-trips":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 1, 2)
    cs.setX(0, Inf)
    cs.setY(0, 0.0)
    check cs.getX(0) == Inf

  test "setX with -Inf round-trips":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 1, 2)
    cs.setX(0, -Inf)
    cs.setY(0, 0.0)
    check cs.getX(0) == -Inf

  test "setY with Inf round-trips":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 1, 2)
    cs.setX(0, 0.0)
    cs.setY(0, Inf)
    check cs.getY(0) == Inf

  test "setCoord with Inf values":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 1, 2)
    cs.setCoord(0, Inf, -Inf)
    let (x, y) = cs.getCoord(0)
    check x == Inf
    check y == -Inf

suite "Serialization of NaN-containing geometry":
  test "toWKT with NaN point":
    var ctx = initGeosContext()
    try:
      let p = ctx.createPoint(NaN, NaN)
      # toWKT should either produce a string or raise
      let wkt = p.toWKT()
      check wkt.len > 0
    except GeosGeomError:
      check true

  test "toWKB with NaN point":
    var ctx = initGeosContext()
    try:
      let p = ctx.createPoint(NaN, NaN)
      let wkb = p.toWKB()
      # If WKB is produced, it should be non-empty
      check wkb.len > 0
    except GeosGeomError:
      check true

  test "toGeoJSON with NaN point":
    var ctx = initGeosContext()
    try:
      let p = ctx.createPoint(NaN, NaN)
      let gj = p.toGeoJSON()
      check gj.len > 0
    except GeosGeomError:
      check true

  test "WKB round-trip with NaN preserves NaN":
    var ctx = initGeosContext()
    try:
      let p = ctx.createPoint(NaN, NaN)
      let wkb = p.toWKB()
      let restored = ctx.fromWKB(wkb)
      check restored.type() == gtPoint
      let rp = Point(restored)
      check rp.x().isNaN()
      check rp.y().isNaN()
    except GeosGeomError:
      check true
    except GeosParseError:
      check true

  test "toWKT with Inf point":
    var ctx = initGeosContext()
    try:
      let p = ctx.createPoint(Inf, -Inf)
      let wkt = p.toWKT()
      check wkt.len > 0
    except GeosGeomError:
      check true

  test "toWKB with Inf point":
    var ctx = initGeosContext()
    try:
      let p = ctx.createPoint(Inf, -Inf)
      let wkb = p.toWKB()
      check wkb.len > 0
    except GeosGeomError:
      check true

  test "WKT round-trip with Inf":
    var ctx = initGeosContext()
    try:
      let p = ctx.createPoint(Inf, -Inf)
      let wkt = p.toWKT()
      let restored = ctx.fromWKT(wkt)
      let rp = Point(restored)
      check rp.x() == Inf
      check rp.y() == -Inf
    except GeosGeomError:
      check true
    except GeosParseError:
      # WKT with Inf might not be parseable
      check true

  test "toGeoJSON with Inf point":
    var ctx = initGeosContext()
    try:
      let p = ctx.createPoint(Inf, -Inf)
      let gj = p.toGeoJSON()
      check gj.len > 0
    except GeosGeomError:
      check true

suite "Negative zero":
  test "createPoint with -0.0 and 0.0":
    var ctx = initGeosContext()
    let p = ctx.createPoint(-0.0, 0.0)
    # IEEE 754: -0.0 == 0.0
    check p.x() == 0.0
    check p.y() == 0.0
    check -0.0 == 0.0  # sanity check

  test "Point with -0.0 is valid":
    var ctx = initGeosContext()
    let p = ctx.createPoint(-0.0, 0.0)
    check p.isValid()
    check not p.isEmpty()

  test "Point with -0.0 numCoordinates":
    var ctx = initGeosContext()
    let p = ctx.createPoint(-0.0, -0.0)
    check p.numCoordinates() == 1

  test "CoordSeq with -0.0 round-trips":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 1, 2)
    cs.setX(0, -0.0)
    cs.setY(0, -0.0)
    check cs.getX(0) == 0.0
    check cs.getY(0) == 0.0

  test "WKT round-trip with -0.0":
    var ctx = initGeosContext()
    let p = ctx.createPoint(-0.0, -0.0)
    let wkt = p.toWKT()
    let restored = ctx.fromWKT(wkt)
    let rp = Point(restored)
    check rp.x() == 0.0
    check rp.y() == 0.0
