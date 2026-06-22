# DE-9IM Spatial Predicates

The 8 standard binary topology predicates defined by the [DE-9IM](https://en.wikipedia.org/wiki/DE-9IM) model. Each takes two `Geometry` values and returns `bool`, raising `GeosGeomError` if GEOS reports an exception.

## Function Reference

| Proc | Signature | Meaning |
|------|-----------|---------|
| `equals` | `(g, other: Geometry): bool` | Geometries are topologically equal (same set of points) |
| `intersects` | `(g, other: Geometry): bool` | Geometries share at least one point |
| `disjoint` | `(g, other: Geometry): bool` | Geometries have no points in common (inverse of `intersects`) |
| `contains` | `(g, other: Geometry): bool` | `g` entirely contains `other` (no point of `other` lies outside `g`) |
| `within` | `(g, other: Geometry): bool` | `g` is entirely inside `other` (`g.within(other)` ⇔ `other.contains(g)`) |
| `touches` | `(g, other: Geometry): bool` | Geometries share boundary points but no interior points |
| `crosses` | `(g, other: Geometry): bool` | Geometries share some but not all interior points, and their dimension decreases |
| `overlaps` | `(g, other: Geometry): bool` | Geometries share interior points of the same dimension but neither contains the other |

All predicates accept a `Geometry` and a second `Geometry` from the same `GeosContext`. Nil handles or cross-context usage raises `GeosGeomError`.

## Example — Containment Check

```nim
import nimgeos

let ctx = initGeosContext()

let polygon = ctx.fromWKT("POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))")
let pointInside  = ctx.fromWKT("POINT (5 5)")
let pointOutside = ctx.fromWKT("POINT (20 5)")

echo polygon.contains(pointInside)   # true
echo polygon.contains(pointOutside)  # false
echo pointInside.within(polygon)     # true

echo polygon.intersects(pointOutside)  # false
echo polygon.disjoint(pointOutside)    # true
```

## Edge Cases

- Empty geometries: `contains`, `within`, `touches` return `false` when either operand is empty. `intersects` returns `false` if either is empty. `disjoint` returns `true` if both are empty.
- `equals` on two empty geometries of the same type returns `true`.
- A `Point` `within` itself returns `true`; `contains` from a `Point` to itself also returns `true`.
