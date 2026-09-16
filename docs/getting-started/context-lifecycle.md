# Context Lifecycle

Every GEOS operation runs inside a `GeosContext`. The context holds the GEOS thread-local state, error/notice handlers, and owns all geometry objects created through it. A context must outlive every geometry that refers to it.

## Recommended: `withGeosContext`

The simplest and safest way to work with GEOS is the `withGeosContext` template. It creates a context, runs your code, then destroys the context automatically — even if an exception is raised.

```nim
import nimgeos

withGeosContext proc(ctx: var GeosContext) =
  let p = ctx.createPoint(1.0, 2.0)
  let q = ctx.createPoint(4.0, 6.0)
  echo "Distance: ", p.distance(q)    # 5.0
# ctx is destroyed here — any escaped Geometry refs are now invalid
```

## Explicit construction: `initGeosContext`

When you need more control over the lifetime — for example, reusing a context across many operations — create it explicitly:

```nim
var ctx = initGeosContext()
# ... use ctx ...
# ctx is destroyed automatically when it goes out of scope (ORC)
```

### Custom error and notice handlers

`initGeosContext` accepts optional callbacks for GEOS messages. The defaults write to stderr.

```nim
proc myNotice(msg: cstring; userdata: pointer) {.cdecl.} =
  echo "NOTICE: ", $msg

proc myError(msg: cstring; userdata: pointer) {.cdecl.} =
  stderr.writeLine("ERROR: ", $msg)

var ctx = initGeosContext(myNotice, myError)
```

The handlers are plain C callbacks — they must not capture Nim GC objects.

## Utility procs

### `version()`

Returns the runtime GEOS version string:

```nim
var ctx = initGeosContext()
echo ctx.version()   # "3.12.1"
```

### `isNil()`

Checks if the context handle has been destroyed (or was never initialised):

```nim
var ctx = initGeosContext()
echo ctx.isNil()     # false
# context goes out of scope and is destroyed
```

### `checkContext()`

A template used internally by constructors and deserializers to raise `GeosInitError` when a nil/destroyed context is passed. You can use it in your own code as a guard:

```nim
checkContext(ctx, "myOperation")
# raises GeosInitError if ctx.handle is nil
```

## Nil-context safety

All geometry constructors, serializers, and operations call `checkContext` before touching the GEOS C API. Passing a destroyed or uninitialised context raises `GeosInitError` with a descriptive message.

## Context is non-copyable

`GeosContext` cannot be copied. Pass it by `var` or move it explicitly.

```nim
proc process(ctx: var GeosContext) =
  let p = ctx.createPoint(0.0, 0.0)
  # ...
```

## Thread safety

GEOS contexts are single-threaded. Create one context per thread; never share a context across threads without external synchronisation.

## Cross-context operations

Using geometries from different `GeosContext` objects in the same operation is **undefined behavior**. GEOS contexts are independent of each other and geometries created in one context must not be used with another.

```nim
var ctxA = initGeosContext()
var ctxB = initGeosContext()

let ptA = ctxA.createPoint(0.0, 0.0)
let ptB = ctxB.createPoint(1.0, 1.0)

# UNDEFINED: geometries from different contexts
# let dist = ptA.distance(ptB)
```

Always use the same `GeosContext` for a given computation chain. When using `withGeosContext`, any geometries that escape the block reference a destroyed context and must not be used after the block exits.

## Ownership transfer

Constructors that take ownership of input handles **neutralize** those handles. After calling `createPolygon`, `createMultiGeometry`, or similar, the input variables must not be used:

```nim
let shell = ctx.createLinearRing(/* ... */)
let poly  = ctx.createPolygon(shell)
# shell.handle is now nil — do not use `shell`
```
