# Empty Geometries

GEOS supports the concept of an **empty geometry** — a geometry with no coordinates.

## Detection

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

## Behavior of operations on empty geometries

| Operation | Behavior |
|---|---|
| `isEmpty()` | Returns `true` |
| `area()` | Returns `0.0` |
| `length()` | Returns `0.0` |
| `toWKT()` | Returns `"POINT EMPTY"`, `"LINESTRING EMPTY"`, etc. |
| `toGeoJSON()` | Returns `{"type": "Point", "coordinates": []}` |
| Predicates (`contains`, `intersects`, etc.) | Returns `false` (DE-9IM consistent) |
| `distance()` | Returns `0.0` (JTS/GEOS semantics; pinned here so the value does not depend on the loaded `libgeos_c` build) |
| Spatial operations (`intersection`, `union`, etc.) | May return an empty geometry |
| `numCoordinates()` | Returns `0` |

See also [Special floating-point values](special-values.md) for how NaN interacts with emptiness checks.
