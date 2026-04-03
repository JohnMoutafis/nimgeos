import unittest
import nimgeos/private/geos_abi

suite "Geos ABI smoke test":
  test "GEOSversion returns a non-empty string":
    let v = $GEOSversion()
    check v.len > 0
    echo "GEOS version: ", v

  test "Context init and finish":
    let ctx = GEOS_init_r()
    check cast[pointer](ctx) != nil
    GEOS_finish_r(ctx)

  test "Create and destroy a Point":
    let ctx = GEOS_init_r()
    let p = GEOSGeom_createPointFromXY_r(ctx, 0.0, 0.0)
    check cast[pointer](p) != nil
    GEOSGeom_destroy_r(ctx, p)
    GEOS_finish_r(ctx)
