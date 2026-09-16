# Error Types

nimgeos defines a hierarchy of error types, all inheriting from `GeosError` (which inherits from `CatchableError`):

```nim
GeosError* = object of CatchableError
GeosInitError*  = object of GeosError   # GEOS initialization failures
GeosGeomError*  = object of GeosError   # Geometry operation failures
GeosParseError* = object of GeosError   # WKT/WKB/GeoJSON parse failures
```

## GeosInitError

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

## GeosGeomError

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

## GeosParseError

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

See also [Nil-safety](nil-safety.md) for the handle guards behind most `GeosGeomError` raises.
