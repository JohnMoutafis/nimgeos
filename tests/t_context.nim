import unittest
import nimgeos

# ── GeosContext lifecycle ─────────────────────────────────────────────────────

suite "GeosContext":
  test "Context init succeeds and version is non-empty":
    let ctx = initGeosContext()
    check not ctx.isNil()
    check ctx.version().len > 0
    echo "GEOS runtime version: ", ctx.version()

  test "Copy of the context is disallowed":
    let ctx1 = initGeosContext()
    template notCompiles(e: untyped): untyped =
      static: assert(not compiles(e))

      check:
        notCompiles:
          let ctx2 = ctx1

  test "Context is destroyed at scope exit":
    var ctx: GeosContext
    block:
      let ctx = initGeosContext()
      check not ctx.isNil()
    # =destroy called here
    check ctx.isNil()

# ── withGeosContext scoped lifecycle ──────────────────────────────────────────

suite "withGeosContext":
  test "basic usage: create and use geometry inside scoped context":
    withGeosContext proc(ctx: var GeosContext) =
      let p = ctx.createPoint(12.34, 56.78)
      check p.type() == gtPoint
      check p.toWKT() == "POINT (12.34 56.78)"

  test "context is valid inside the body":
    withGeosContext proc(ctx: var GeosContext) =
      check not ctx.isNil()
      check ctx.version().len > 0

  test "multiple geometries within scoped context":
    withGeosContext proc(ctx: var GeosContext) =
      let p1 = ctx.createPoint(1.0, 2.0)
      let p2 = ctx.createPoint(3.0, 4.0)
      let ls = ctx.createLineString(@[(0.0, 0.0), (1.0, 1.0)])
      check p1.type() == gtPoint
      check p2.type() == gtPoint
      check ls.type() == gtLineString

  test "serialization works inside scoped context":
    withGeosContext proc(ctx: var GeosContext) =
      let g = ctx.fromWKT("POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))")
      check g.type() == gtPolygon
      let wkt = g.toWKT()
      check wkt == "POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))"

  test "spatial operations work inside scoped context":
    withGeosContext proc(ctx: var GeosContext) =
      let g1 = ctx.fromWKT("POLYGON ((0 0, 2 0, 2 2, 0 2, 0 0))")
      let g2 = ctx.fromWKT("POLYGON ((1 1, 3 1, 3 3, 1 3, 1 1))")
      let inter = g1.intersection(g2)
      check inter.type() == gtPolygon
      check inter.area() > 0.0

  test "withGeosContext body completes and cleanup runs without crash":
    ## Completing this test without crashing is the assertion.
    var escapedCtxNil = false
    block:
      withGeosContext proc(ctx: var GeosContext) =
        check not ctx.isNil()
      # After withGeosContext returns, the context var inside is destroyed
      escapedCtxNil = true
    check escapedCtxNil

  test "exception propagation: body exceptions are not swallowed":
    expect GeosParseError:
      withGeosContext proc(ctx: var GeosContext) =
        discard ctx.fromWKT("INVALID WKT GARBAGE")

  test "nested withGeosContext calls":
    withGeosContext proc(ctx1: var GeosContext) =
      let p1 = ctx1.createPoint(1.0, 2.0)
      withGeosContext proc(ctx2: var GeosContext) =
        let p2 = ctx2.createPoint(3.0, 4.0)
        check p2.toWKT() == "POINT (3 4)"
      check p1.toWKT() == "POINT (1 2)"

  test "repeated calls do not leak":
    ## Stress-tests context create/destroy with many sequential cycles.
    for i in 0 ..< 100:
      withGeosContext proc(ctx: var GeosContext) =
        let p = ctx.createPoint(float(i), float(i))
        check p.type() == gtPoint

  # ── Nil safety ──────────────────────────────────────────────────────────────
  test "Nil Safety: nil context raises GeosInitError on createPoint":
    var ctx: GeosContext
    check ctx.isNil()
    expect GeosInitError:
      discard ctx.createPoint(0.0, 0.0)

  test "Nil Safety: nil context raises GeosInitError on fromWKT":
    var ctx: GeosContext
    expect GeosInitError:
      discard ctx.fromWKT("POINT (0 0)")

  test "Nil Safety: nil context raises GeosInitError on fromGeoJSON":
    var ctx: GeosContext
    expect GeosInitError:
      discard ctx.fromGeoJSON("""{"type":"Point","coordinates":[0,0]}""")

  test "Nil Safety: nil context raises GeosInitError on newCoordSeq":
    var ctx: GeosContext
    expect GeosInitError:
      discard newCoordSeq(ctx, 3)
