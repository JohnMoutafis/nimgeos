# LinearRing

A `LinearRing` is a closed `LineString` where the first and last coordinates are identical. It inherits from `GeometryObj` and is primarily used as the shell (exterior ring) or holes (interior rings) of a `Polygon`.

## Creating a LinearRing

### 2D

Requires at least 4 coordinates forming a closed ring:

```nim
let ring = ctx.createLinearRing([
  (0.0, 0.0), (10.0, 0.0), (10.0, 10.0), (0.0, 10.0), (0.0, 0.0)
])
```

### 3D

Requires at least 4 `(x, y, z)` tuples forming a closed ring:

```nim
let ring3d = ctx.createLinearRing([
  (0.0, 0.0, 0.0), (10.0, 0.0, 1.0), (10.0, 10.0, 2.0), (0.0, 10.0, 3.0), (0.0, 0.0, 0.0)
])
```

Passing fewer than 4 coordinates raises `GeosGeomError`. The ring **must** be closed (first point == last point); GEOS will fail if it is not.

## Usage as polygon shell and holes

The most common use of `LinearRing` is constructing polygons:

```nim
let shell = ctx.createLinearRing([
  (0.0, 0.0), (100.0, 0.0), (100.0, 100.0), (0.0, 100.0), (0.0, 0.0)
])

let hole = ctx.createLinearRing([
  (25.0, 25.0), (75.0, 25.0), (75.0, 75.0), (25.0, 75.0), (25.0, 25.0)
])

let poly = ctx.createPolygon(shell, [hole])
```

**Ownership note:** `createPolygon` takes ownership of the shell and hole handles. After calling it, the passed-in `LinearRing` handles are neutralised (set to nil) to prevent double-free.

## String representation

```nim
echo ring   # LinearRing(5 coords)
```

## Full example

```nim
import nimgeos

var ctx = initGeosContext()

# Create a triangular ring
let triangle = ctx.createLinearRing([
  (0.0, 0.0), (5.0, 0.0), (2.5, 5.0), (0.0, 0.0)
])
echo triangle   # LinearRing(4 coords)

# Use as a polygon (no holes)
let poly = ctx.createPolygon(triangle)
echo poly.area()   # 12.5
```
