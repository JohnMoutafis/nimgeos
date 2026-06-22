# LineString

A `LineString` is a sequence of two or more coordinates connected by straight line segments. It inherits from `GeometryObj`.

## Creating a LineString

### 2D

Requires at least 2 `(x, y)` tuples:

```nim
let ls = ctx.createLineString([(0.0, 0.0), (3.0, 4.0)])
```

### 3D

Requires at least 2 `(x, y, z)` tuples:

```nim
let ls3d = ctx.createLineString([(0.0, 0.0, 1.0), (3.0, 4.0, 2.0)])
```

Passing fewer than 2 coordinates raises `GeosGeomError`.

## Accessors

### `numPoints()`

Returns the number of points in the LineString.

```nim
echo ls.numPoints()   # 2
```

### `pointN(index)`

Returns the point at `index` (0-based) as a `Point`. Raises `GeosGeomError` if the index is out of bounds.

```nim
let first = ls.pointN(0)
echo first.x()        # 0.0
```

### `startPoint()`

Returns the first point as a `Point`.

```nim
let start = ls.startPoint()
```

### `endPoint()`

Returns the last point as a `Point`.

```nim
let end = ls.endPoint()
```

## String representation

```nim
echo ls   # LineString(2 points)
```

## Full example

```nim
import nimgeos

var ctx = initGeosContext()

# 2D LineString
let trail = ctx.createLineString([
  (1.0, 1.0), (2.5, 3.0), (4.0, 2.0)
])
echo "Points: ", trail.numPoints()   # 3
echo "Length: ", trail.length()      # ~4.61
echo trail                           # LineString(3 points)

# 3D LineString
let flight = ctx.createLineString([
  (0.0, 0.0, 100.0), (10.0, 0.0, 150.0), (20.0, 10.0, 200.0)
])
echo "3D points: ", flight.numPoints()

# Access individual points
let mid = trail.pointN(1)
echo "Midpoint: ", mid.x(), ", ", mid.y()

let first = trail.startPoint()
let last  = trail.endPoint()
echo "Trail from (", first.x(), ", ", first.y(), ") to (", last.x(), ", ", last.y(), ")"
```
