# Special Floating-Point Values

Behavior of nimgeos geometries containing NaN or infinity coordinates, and Z-coordinate queries on 2D geometries.

## NaN (Not a Number)

Creating geometries with `NaN` coordinates is permitted at the GEOS level but may produce undefined results:

```nim
let nanPoint = ctx.createPoint(NaN, NaN)
# Behavior: GEOS may accept this but spatial operations may fail
```

- `isEmpty()` may return `false` even though the point is effectively invalid.
- Predicates and operations on NaN-containing geometries may return unexpected results or raise `GeosGeomError`.

## Infinity

Positive/negative infinity coordinates behave similarly to NaN — GEOS may accept them but results are undefined:

```nim
let infPoint = ctx.createPoint(Inf, Inf)
```

## Z-coordinate queries on 2D geometries

Calling `z()` on a 2D `Point` returns `NaN`:

```nim
let pt2d = ctx.createPoint(1.0, 2.0)
echo pt2d.z().isNaN()  # true
```
