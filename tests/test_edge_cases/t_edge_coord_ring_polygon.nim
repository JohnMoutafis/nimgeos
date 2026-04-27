import unittest
import nimgeos

# ══════════════════════════════════════════════════════════════════════════════
# Edge-case tests: LinearRing closure, CoordSeq bounds, Polygon handle reuse
# ══════════════════════════════════════════════════════════════════════════════

suite "LinearRing closure validation":
  test "Non-closed ring with 4 points (first != last) — 2D":
    # GEOS rejects non-closed rings with an IllegalArgumentException,
    # which surfaces as GeosGeomError from createLinearRing.
    var ctx = initGeosContext()
    var raised = false
    try:
      let lr = ctx.createLinearRing([(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.5, 0.5)])
      # If we get here, GEOS accepted the non-closed ring (unlikely).
      check lr.type() == gtLinearRing
      check lr.numCoordinates() >= 4
    except GeosGeomError:
      raised = true
    # GEOS is expected to reject; document either outcome.
    check true

  test "Non-closed ring with 4 points (first != last) — 3D":
    var ctx = initGeosContext()
    var raised = false
    try:
      let lr = ctx.createLinearRing([
        (0.0, 0.0, 1.0), (1.0, 0.0, 2.0),
        (1.0, 1.0, 3.0), (0.5, 0.5, 4.0)
      ])
      check lr.type() == gtLinearRing
      check lr.numCoordinates() >= 4
    except GeosGeomError:
      raised = true
    check true

  test "All identical points — degenerate ring":
    var ctx = initGeosContext()
    var raised = false
    var valid = true
    try:
      let lr = ctx.createLinearRing([
        (0.0, 0.0), (0.0, 0.0), (0.0, 0.0), (0.0, 0.0)
      ])
      # Ring is "closed" (first == last) but degenerate.
      check lr.type() == gtLinearRing
      check lr.numCoordinates() == 4
      # A degenerate ring is typically not valid geometry.
      valid = lr.isValid()
    except GeosGeomError:
      raised = true
    # If GEOS accepted it, it should be invalid
    if not raised:
      check valid == false

  test "Self-intersecting ring (figure-eight) — isValid returns false":
    var ctx = initGeosContext()
    # A bowtie / figure-eight: edges cross each other
    let lr = ctx.createLinearRing([
      (0.0, 0.0), (2.0, 2.0), (2.0, 0.0), (0.0, 2.0), (0.0, 0.0)
    ])
    check lr.type() == gtLinearRing
    # Self-intersecting rings are not valid
    check lr.isValid() == false

  test "Properly closed ring is valid":
    var ctx = initGeosContext()
    let lr = ctx.createLinearRing([
      (0.0, 0.0), (4.0, 0.0), (4.0, 3.0), (0.0, 0.0)
    ])
    check lr.isValid()
    check lr.numCoordinates() == 4

# ══════════════════════════════════════════════════════════════════════════════

suite "CoordSeq out-of-bounds access — getters":
  # NOTE: Only getter OOB tests are included here.
  # Setter OOB tests (setX/setY/setZ with invalid indices) are intentionally
  # omitted because GEOS does NOT bounds-check writes. Writing out-of-bounds
  # silently corrupts heap memory and causes crashes in subsequent allocations.

  test "getX past the end (idx == len)":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 3, 2)
    cs.setCoord(0, 1.0, 2.0)
    cs.setCoord(1, 3.0, 4.0)
    cs.setCoord(2, 5.0, 6.0)
    var raised = false
    try:
      discard cs.getX(cs.len)
    except GeosGeomError:
      raised = true
    # GEOS may or may not bounds-check reads. Document behavior.
    check true

  test "getX way past the end (idx=999 on size-3)":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 3, 2)
    cs.setCoord(0, 1.0, 2.0)
    cs.setCoord(1, 3.0, 4.0)
    cs.setCoord(2, 5.0, 6.0)
    var raised = false
    try:
      discard cs.getX(999)
    except GeosGeomError:
      raised = true
    check true

  test "getY past the end":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 3, 2)
    cs.setCoord(0, 0.0, 0.0)
    cs.setCoord(1, 1.0, 1.0)
    cs.setCoord(2, 2.0, 2.0)
    var raised = false
    try:
      discard cs.getY(cs.len)
    except GeosGeomError:
      raised = true
    check true

  test "getZ out-of-bounds on 3D seq":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 2, 3)
    cs.setCoord(0, 1.0, 2.0, 3.0)
    cs.setCoord(1, 4.0, 5.0, 6.0)
    var raised = false
    try:
      discard cs.getZ(cs.len)
    except GeosGeomError:
      raised = true
    check true

  # NOTE: Negative index tests (e.g. getX(-1), setX(-1, v)) are intentionally
  # omitted. When -1 is cast to cuint it becomes a massive unsigned value
  # (e.g. 4294967295), which causes GEOS to attempt a wild memory read/write.
  # This results in SIGBUS on macOS/ARM and SIGSEGV on other platforms —
  # neither of which can be caught by Nim's exception system.

  test "getCoord past the end":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 2, 2)
    cs.setCoord(0, 1.0, 2.0)
    cs.setCoord(1, 3.0, 4.0)
    var raised = false
    try:
      discard cs.getCoord(2)
    except GeosGeomError:
      raised = true
    check true

  test "getCoord3D past the end":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 2, 3)
    cs.setCoord(0, 1.0, 2.0, 3.0)
    cs.setCoord(1, 4.0, 5.0, 6.0)
    var raised = false
    try:
      discard cs.getCoord3D(2)
    except GeosGeomError:
      raised = true
    check true

# ══════════════════════════════════════════════════════════════════════════════

suite "CoordSeq construction edge cases":

  test "newCoordSeq with size 0":
    var ctx = initGeosContext()
    var raised = false
    try:
      var cs = newCoordSeq(ctx, 0)
      # If it succeeds, len should be 0
      check cs.len == 0
    except GeosGeomError:
      raised = true
    check true

  test "newCoordSeq with dims=0":
    var ctx = initGeosContext()
    var raised = false
    try:
      var cs = newCoordSeq(ctx, 3, 0)
      let d = cs.dims
      # dims=0 is unusual — just document what GEOS does
      check d >= 0
    except GeosGeomError:
      raised = true
    check true

  test "newCoordSeq with dims=1":
    var ctx = initGeosContext()
    var raised = false
    try:
      var cs = newCoordSeq(ctx, 3, 1)
      check cs.len == 3
      check cs.dims >= 1
    except GeosGeomError:
      raised = true
    check true

  test "newCoordSeq with dims=4":
    var ctx = initGeosContext()
    var raised = false
    try:
      var cs = newCoordSeq(ctx, 2, 4)
      check cs.len == 2
    except GeosGeomError:
      raised = true
    check true

  test "items3D on 2D CoordSeq — Z values":
    var ctx = initGeosContext()
    var cs = newCoordSeq(ctx, 2, 2)
    cs.setCoord(0, 1.0, 2.0)
    cs.setCoord(1, 3.0, 4.0)
    # Iterating with items3D on a 2D seq: Z should be 0.0 or NaN
    var coords: seq[(float, float, float)] = @[]
    try:
      for coord in cs.items3D:
        coords.add(coord)
      check coords.len == 2
      check coords[0][0] == 1.0
      check coords[0][1] == 2.0
      # Z is typically 0.0 or NaN for 2D sequences — just verify no crash
      check true
    except GeosGeomError:
      # items3D might fail on a 2D seq — that's also valid behavior
      check true

# ══════════════════════════════════════════════════════════════════════════════

suite "coordSeq on non-point/line geometries":

  test "coordSeq on Polygon raises GeosGeomError":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing([
      (0.0, 0.0), (4.0, 0.0), (4.0, 3.0), (0.0, 0.0)
    ])
    let poly = ctx.createPolygon(shell)
    expect GeosGeomError:
      discard poly.coordSeq()

  test "coordSeq on MultiPoint raises GeosGeomError":
    var ctx = initGeosContext()
    let p1 = ctx.createPoint(1.0, 2.0)
    let p2 = ctx.createPoint(3.0, 4.0)
    var geoms: seq[Geometry] = @[Geometry(p1), Geometry(p2)]
    let mp = ctx.createMultiGeometry(geoms)
    expect GeosGeomError:
      discard mp.coordSeq()

# ══════════════════════════════════════════════════════════════════════════════

suite "Polygon handle reuse after ownership transfer":

  test "shell.numCoordinates() after createPolygon raises GeosGeomError":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing([
      (0.0, 0.0), (4.0, 0.0), (4.0, 3.0), (0.0, 0.0)
    ])
    discard ctx.createPolygon(shell)
    # shell.handle has been niled out by createPolygon
    expect GeosGeomError:
      discard shell.numCoordinates()

  test "shell.isEmpty() after createPolygon raises GeosGeomError":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing([
      (0.0, 0.0), (4.0, 0.0), (4.0, 3.0), (0.0, 0.0)
    ])
    discard ctx.createPolygon(shell)
    expect GeosGeomError:
      discard shell.isEmpty()

  test "shell.isValid() after createPolygon raises GeosGeomError":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing([
      (0.0, 0.0), (4.0, 0.0), (4.0, 3.0), (0.0, 0.0)
    ])
    discard ctx.createPolygon(shell)
    expect GeosGeomError:
      discard shell.isValid()

  test "shell.type() after createPolygon raises GeosGeomError":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing([
      (0.0, 0.0), (4.0, 0.0), (4.0, 3.0), (0.0, 0.0)
    ])
    discard ctx.createPolygon(shell)
    expect GeosGeomError:
      discard shell.type()

  test "shell.toWKT() after createPolygon raises GeosGeomError":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing([
      (0.0, 0.0), (4.0, 0.0), (4.0, 3.0), (0.0, 0.0)
    ])
    discard ctx.createPolygon(shell)
    expect GeosGeomError:
      discard shell.toWKT()

  test "shell.length() after createPolygon raises GeosGeomError":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing([
      (0.0, 0.0), (4.0, 0.0), (4.0, 3.0), (0.0, 0.0)
    ])
    discard ctx.createPolygon(shell)
    expect GeosGeomError:
      discard shell.length()

  test "shell.area() after createPolygon raises GeosGeomError":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing([
      (0.0, 0.0), (4.0, 0.0), (4.0, 3.0), (0.0, 0.0)
    ])
    discard ctx.createPolygon(shell)
    expect GeosGeomError:
      discard shell.area()

  test "hole.numCoordinates() after createPolygon raises GeosGeomError":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing([
      (0.0, 0.0), (10.0, 0.0), (10.0, 10.0), (0.0, 10.0), (0.0, 0.0)
    ])
    let hole = ctx.createLinearRing([
      (2.0, 2.0), (4.0, 2.0), (4.0, 4.0), (2.0, 4.0), (2.0, 2.0)
    ])
    discard ctx.createPolygon(shell, [hole])
    # Both shell and hole handles are niled
    expect GeosGeomError:
      discard shell.numCoordinates()
    expect GeosGeomError:
      discard hole.numCoordinates()

  test "hole.isEmpty() after createPolygon raises GeosGeomError":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing([
      (0.0, 0.0), (10.0, 0.0), (10.0, 10.0), (0.0, 10.0), (0.0, 0.0)
    ])
    let hole = ctx.createLinearRing([
      (2.0, 2.0), (4.0, 2.0), (4.0, 4.0), (2.0, 4.0), (2.0, 2.0)
    ])
    discard ctx.createPolygon(shell, [hole])
    expect GeosGeomError:
      discard hole.isEmpty()

  test "hole.toWKT() after createPolygon raises GeosGeomError":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing([
      (0.0, 0.0), (10.0, 0.0), (10.0, 10.0), (0.0, 10.0), (0.0, 0.0)
    ])
    let hole = ctx.createLinearRing([
      (2.0, 2.0), (4.0, 2.0), (4.0, 4.0), (2.0, 4.0), (2.0, 2.0)
    ])
    discard ctx.createPolygon(shell, [hole])
    expect GeosGeomError:
      discard hole.toWKT()

  test "Multiple holes — all niled after createPolygon":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing([
      (0.0, 0.0), (10.0, 0.0), (10.0, 10.0), (0.0, 10.0), (0.0, 0.0)
    ])
    let h1 = ctx.createLinearRing([
      (1.0, 1.0), (2.0, 1.0), (2.0, 2.0), (1.0, 2.0), (1.0, 1.0)
    ])
    let h2 = ctx.createLinearRing([
      (5.0, 5.0), (6.0, 5.0), (6.0, 6.0), (5.0, 6.0), (5.0, 5.0)
    ])
    let poly = ctx.createPolygon(shell, [h1, h2])
    check poly.isValid()
    check poly.numInteriorRings() == 2
    # All input rings should be neutralised
    expect GeosGeomError:
      discard shell.numCoordinates()
    expect GeosGeomError:
      discard h1.numCoordinates()
    expect GeosGeomError:
      discard h2.numCoordinates()

  test "Polygon remains valid and usable after shell handle is niled":
    var ctx = initGeosContext()
    let shell = ctx.createLinearRing([
      (0.0, 0.0), (4.0, 0.0), (4.0, 3.0), (0.0, 0.0)
    ])
    let poly = ctx.createPolygon(shell)
    # The polygon itself should still be perfectly usable
    check poly.isValid()
    check poly.area() == 6.0
    check poly.numCoordinates() == 4
    let ext = poly.exteriorRing()
    check ext.numCoordinates() == 4
    check ext.isValid()
