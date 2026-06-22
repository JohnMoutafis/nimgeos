# Edge Cases

Behavior of nimgeos with empty geometries, special floating-point values, error conditions, nil-safety guards, and cross-context operations.

---

## Empty geometries

GEOS supports the concept of an **empty geometry** — a geometry with no coordinates.

### Detection

```nim
proc isEmpty*(g: Geometry): bool
```

Returns `true` if the geometry has no coordinates.

```nim
let empty = ctx.fromWKT("POINT EMPTY")
echo empty.isEmpty()  # true

let filled = ctx.fromWKT("POINT (0 0)")
echo filled.isEmpty()  # false
```

### Empty geometry behavior

| Operation | Behavior |
|---|---|
| `isEmpty()` | Returns `true` |
| `area()` | Returns `0.0` |
| `length()` | Returns `0.0` |
| `toWKT()` | Returns `"POINT EMPTY"`, `"LINESTRING EMPTY"`, etc. |
| `toGeoJSON()` | Returns `{"type": "Point", "coordinates": []}` |
| Predicates (`contains`, `intersects`, etc.) | Returns `false` (DE-9IM consistent) |
| Spatial operations (`intersection`, `union`, etc.) | May return an empty geometry |
| `numCoordinates()` | Returns `0` |

---

## Special floating-point values

### NaN (Not a Number)

Creating geometries with `NaN` coordinates is permitted at the GEOS level but may produce undefined results:

```nim
let nanPoint = ctx.createPoint(NaN, NaN)
# Behavior: GEOS may accept this but spatial operations may fail
```

- `isEmpty()` may return `false` even though the point is effectively invalid.
- Predicates and operations on NaN-containing geometries may return unexpected results or raise `GeosGeomError`.

### Infinity

Positive/negative infinity coordinates behave similarly to NaN — GEOS may accept them but results are undefined:

```nim
let infPoint = ctx.createPoint(Inf, Inf)
```

### Z-coordinate queries on 2D geometries

Calling `z()` on a 2D `Point` returns `NaN`:

```nim
let pt2d = ctx.createPoint(1.0, 2.0)
echo pt2d.z().isNaN()  # true
```

---

## Error types

nimgeos defines a hierarchy of error types, all inheriting from `GeosError` (which inherits from `CatchableError`):

```nim
GeosError* = object of CatchableError
GeosInitError*  = object of GeosError   # GEOS initialization failures
GeosGeomError*  = object of GeosError   # Geometry operation failures
GeosParseError* = object of GeosError   # WKT/WKB/GeoJSON parse failures
```

### GeosInitError

Raised when:
- `initGeosContext()` cannot create a GEOS context (e.g. `libgeos_c` not installed)
- A WKT/WKB reader or writer cannot be created
- A nil/destroyed context is passed to any operation (`checkContext` guard)

```nim
try:
  var ctx = initGeosContext()
except GeosInitError as e:
  echo "GEOS init failed: ", e.msg
  # Common cause: libgeos_c not installed
```

### GeosGeomError

Raised when:
- A GEOS operation fails (returns nil or exception code)
- A geometry handle is nil (`checkHandle` guards)
- Index is out of bounds (`pointN`, `interiorRingN`, `geomN`)
- A prepared-predicate guard catches a `Geometry` instead of `PreparedGeometry`

```nim
try:
  let result = poly.buffer(-10.0)  # may fail if buffer width is too negative
except GeosGeomError as e:
  echo "geometry operation failed: ", e.msg
```

### GeosParseError

Raised when:
- WKT input is malformed or unparseable
- WKB byte sequence is empty or corrupt
- Hex WKB has an odd length or invalid hex characters
- GeoJSON is missing required fields (`type`, `coordinates`) or has invalid structure
- GeoJSON coordinates have fewer than 2 values for a Point

```nim
try:
  let bad = ctx.fromWKT("NOT VALID WKT")
except GeosParseError as e:
  echo "parse error: ", e.msg
```

---

## Nil-safety

All geometry operations guard against nil handles and raise `GeosGeomError` with a descriptive label:

```nim
let nilPoly: Polygon = nil
try:
  echo nilPoly.exteriorRing()   # raises GeosGeomError: "exteriorRing called on nil Geometry"
except GeosGeomError as e:
  echo e.msg
```

This guard covers:
- Property accessors (`isEmpty`, `isValid`, `area`, `length`, `distance`, etc.)
- Sub-geometry access (`geomN`, `exteriorRing`, `interiorRingN`, `pointN`)
- Predicates (`contains`, `intersects`, etc.)
- Spatial operations (`buffer`, `difference`, `intersection`, etc.)
- Serialization (`toWKT`, `toWKB`, `toGeoJSON`)

**String representations** (`$`) gracefully return `"<nil ...>"` instead of raising:

```nim
let nilPt: Point = nil
echo nilPt  # "<nil Point>"
```

---

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

---

## Ownership transfer

Constructors that take ownership of input handles **neutralize** those handles. After calling `createPolygon`, `createMultiGeometry`, or similar, the input variables must not be used:

```nim
let shell = ctx.createLinearRing(/* ... */)
let poly  = ctx.createPolygon(shell)
# shell.handle is now nil — do not use `shell`
```
