import unittest
import nimgeos/context

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
