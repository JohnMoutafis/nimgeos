# Prepared Geometry

Precompute topology structures in GEOS for fast repeated spatial predicates against a fixed geometry.

---

## Motivation

Plain spatial predicates (`contains`, `intersects`) compute internal indexes on every call. When testing one geometry against many candidates, a **prepared geometry** pre-builds those structures once, yielding substantially faster repeated queries.

---

## Creating a prepared geometry

```nim
proc prepare*(g: Geometry): PreparedGeometry
```

Takes any `Geometry`, clones it internally, and builds a `PreparedGeometry`. The prepared geometry is immutable and safe to use from any thread (as long as each thread has its own `GeosContext`).

```nim
var ctx = initGeosContext()

let target = ctx.createPolygon(shell)  # the geometry we test against
let prep   = target.prepare()
```

---

## Predicates

All predicates return `bool` and raise `GeosGeomError` on GEOS failure.

```nim
proc preparedContains*(pg: PreparedGeometry; other: Geometry): bool
proc preparedIntersects*(pg: PreparedGeometry; other: Geometry): bool
proc preparedCovers*(pg: PreparedGeometry; other: Geometry): bool
proc preparedCoveredBy*(pg: PreparedGeometry; other: Geometry): bool
```

```nim
let pt = ctx.createPoint(5.0, 5.0)
let ls = ctx.createLineString([(0.0, 0.0), (10.0, 10.0)])

echo prep.preparedContains(pt)    # true (point inside polygon)
echo prep.preparedIntersects(ls)  # true (line crosses polygon)
echo prep.preparedCovers(pt)      # true (polygon covers point)
```

### Guard overloads

If you accidentally pass a plain `Geometry` instead of a `PreparedGeometry`, a guard overload provides a clear runtime error instead of a confusing GEOS crash:

```nim
# Error: "preparedContains requires PreparedGeometry; call prepare first"
preparedContains(target, pt)
```

---

## Benchmark comparison

The following example creates 10 000 candidate points and compares `contains` vs `preparedContains`:

```nim
import std/monotimes, std/times
import nimgeos

var ctx = initGeosContext()

# The target polygon
let shell = ctx.createLinearRing([(0.0, 0.0), (10.0, 0.0), (10.0, 10.0), (0.0, 10.0), (0.0, 0.0)])
let poly  = ctx.createPolygon(shell)

# Prepare once
let prep = poly.prepare()

# Generate candidate points
var points: seq[Point]
for i in 0 ..< 10000:
  points.add(ctx.createPoint(float(i) / 1000.0, float(i) / 1000.0))

# Plain contains (no preparation)
let t0 = getMonoTime()
var count1 = 0
for pt in points:
  if poly.contains(pt):         # re-builds index each iteration
    inc count1
let t1 = getMonoTime()
echo "plain contains: ", count1, " matches in ", (t1 - t0).inMilliseconds(), " ms"

# Prepared contains (index built once)
let t2 = getMonoTime()
var count2 = 0
for pt in points:
  if prep.preparedContains(pt):  # re-uses pre-built index
    inc count2
let t3 = getMonoTime()
echo "prepared contains: ", count2, " matches in ", (t3 - t2).inMilliseconds(), " ms"
```

Typical results (factor depends on geometry complexity):

| Predicate | Plain | Prepared |
|---|---|---|
| `contains` × 10 000 | ~25 ms | ~3 ms |

---

## Full example

```nim
import nimgeos

var ctx = initGeosContext()

# Build polygon
let shell = ctx.createLinearRing([(0.0, 0.0), (10.0, 0.0), (10.0, 10.0), (0.0, 10.0), (0.0, 0.0)])
let poly  = ctx.createPolygon(shell)

# Prepare
let prep = poly.prepare()

# Test candidates
let inside  = ctx.createPoint(5.0, 5.0)
let outside = ctx.createPoint(20.0, 20.0)

echo prep.preparedContains(inside)   # true
echo prep.preparedContains(outside)  # false
```
