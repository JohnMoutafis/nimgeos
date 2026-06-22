# Spatial Operations

Produce new `Geometry` instances from one or two input geometries. All operations return a concrete-typed `Geometry` ref and raise `GeosGeomError` on failure.

## Binary Operations

| Proc | Signature | Description |
|------|-----------|-------------|
| `intersection` | `(g, other: Geometry): Geometry` | Points shared by both inputs |
| `union` | `(g, other: Geometry): Geometry` | Points covered by either input |
| `difference` | `(g, other: Geometry): Geometry` | Part of `g` not in `other` |
| `symmetricDifference` | `(g, other: Geometry): Geometry` | Points covered by exactly one input (XOR) |
| `snap` | `(g, other: Geometry; tol: float): Geometry` | Snaps `g` vertices/segments toward `other` where within tolerance |

## Unary Operations

| Proc | Signature | Description |
|------|-----------|-------------|
| `convexHull` | `(g: Geometry): Geometry` | Smallest convex polygon containing the geometry |
| `envelope` | `(g: Geometry): Geometry` | Bounding box (Polygon, or Point/Line for degenerate cases) |
| `centroid` | `(g: Geometry): Geometry` | Geometric centre as a Point |
| `boundary` | `(g: Geometry): Geometry` | Topological boundary (ring(s) for polygon, empty for point) |
| `unaryUnion` | `(g: Geometry): Geometry` | Union over all components of a collection |

## Parameterized Operations

| Proc | Signature | Description |
|------|-----------|-------------|
| `buffer` | `(g: Geometry; width: float; quadsegs: int = 8): Geometry` | Area expanded (positive) or shrunk (negative) around the geometry |
| `simplify` | `(g: Geometry; tol: float): Geometry` | Douglas-Peucker simplification; higher `tol` = coarser, may alter topology |
| `topologyPreserveSimplify` | `(g: Geometry; tol: float): Geometry` | Simplification that preserves valid polygon topology |

## Example — Buffer and Intersection

```nim
import nimgeos

let ctx = initGeosContext()

let road = ctx.fromWKT("LINESTRING (0 0, 100 0)")

# Create a 5-unit buffer around the road (a corridor polygon)
let corridor = road.buffer(5.0)

let building = ctx.fromWKT("POLYGON ((30 -5, 40 -5, 40 5, 30 5, 30 -5))")

# Find the overlapping area
let overlap = corridor.intersection(building)
echo overlap.toWKT()  # POLYGON ((30 -5, 40 -5, 40 5, 30 5, 30 -5))

# Simplify a noisy boundary
let noisy = ctx.fromWKT("POLYGON ((0 0, 5 0.1, 10 0, 10 10, 0 10, 0 0))")
let clean = noisy.simplify(0.5)
echo clean.toWKT()
```

All binary operations require both inputs to share the same `GeosContext`. Passing geometries from different contexts raises `GeosGeomError`.
