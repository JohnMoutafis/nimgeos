# WKT Serialization

Read and write Well-Known Text (WKT) — the standard text format for representing vector geometry objects.

---

## Parsing (from WKT)

```nim
proc fromWKT*(ctx: var GeosContext; wkt: string): Geometry
```

Parses any WKT string into the corresponding concrete `Geometry`. Supports all geometry types: `POINT`, `LINESTRING`, `LINEARRING`, `POLYGON`, `MULTIPOINT`, `MULTILINESTRING`, `MULTIPOLYGON`, `GEOMETRYCOLLECTION`.

Returns a concrete-typed geometry (e.g. `Point`, `LineString`, `Polygon`).

Raises `GeosParseError` on invalid or unparseable input. Raises `GeosInitError` if the WKT reader cannot be created.

```nim
var ctx = initGeosContext()

let pt = ctx.fromWKT("POINT (12.34 56.78)")
echo pt.type()  # gtPoint

let poly = ctx.fromWKT("POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))")
echo poly.area()
```

### Invalid input

```nim
try:
  let bad = ctx.fromWKT("NOT WKT")
except GeosParseError as e:
  echo "caught: ", e.msg
```

---

## Serializing (to WKT)

```nim
proc toWKT*(g: Geometry): string
```

Serializes a `Geometry` to its WKT string representation.

Output is **trimmed** (no trailing zeros) and uses **6 decimal places** of precision by default.

```nim
var ctx = initGeosContext()

let pt   = ctx.fromWKT("POINT (1.230000 4.560000)")
echo pt.toWKT()  # "POINT (1.23 4.56)"
```

### Empty geometry serialization

```nim
# Create an empty geometry
let empty = ctx.fromWKT("POINT EMPTY")
echo empty.toWKT()  # "POINT EMPTY"
```

---

## Full example

```nim
import nimgeos

var ctx = initGeosContext()

# Parse various WKT types
let point = ctx.fromWKT("POINT (10 20)")
let line  = ctx.fromWKT("LINESTRING (0 0, 10 10, 20 0)")
let polygon = ctx.fromWKT("POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))")
let multi  = ctx.fromWKT("MULTIPOINT ((0 0), (1 1), (2 2))")

# Serialize back to WKT (trimmed, 6 decimal places)
echo point.toWKT()     # "POINT (10 20)"
echo line.toWKT()      # "LINESTRING (0 0, 10 10, 20 0)"
echo polygon.toWKT()   # "POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))"
echo multi.toWKT()     # "MULTIPOINT ((0 0), (1 1), (2 2))"

# Round-trip
let wkt = point.toWKT()
let restored = ctx.fromWKT(wkt)
echo restored.type()   # gtPoint

# Precision example
let precise = ctx.fromWKT("POINT (1.23456789 9.87654321)")
echo precise.toWKT()   # "POINT (1.234568 9.876543)" — rounded to 6 decimal places
```
