# Point

A `Point` represents a single coordinate in 2D or 3D space. It is the simplest geometry type, inheriting from `GeometryObj`.

## Creating a Point

### 2D

```nim
let p = ctx.createPoint(1.0, 2.0)
```

### 3D

```nim
let p3d = ctx.createPoint(1.0, 2.0, 3.0)
```

## Accessors

### `x()`

Returns the X coordinate.

```nim
echo p.x()   # 1.0
```

### `y()`

Returns the Y coordinate.

```nim
echo p.y()   # 2.0
```

### `z()`

Returns the Z coordinate. Returns `NaN` if the point has no Z dimension (i.e. it is 2D).

```nim
echo p3d.z()   # 3.0
echo p.z()     # NaN (2D point)
```

## String representation

```nim
echo p    # Point (1.0 2.0)
echo p3d  # Point (1.0 2.0 3.0)
```

## Full example

```nim
import nimgeos

var ctx = initGeosContext()

# 2D point
let p = ctx.createPoint(12.34, 56.78)
echo "X: ", p.x()          # 12.34
echo "Y: ", p.y()          # 56.78
echo "Z: ", p.z()          # NaN
echo p                      # Point (12.34 56.78)

# 3D point
let p3d = ctx.createPoint(1.0, 2.0, 3.0)
echo "X: ", p3d.x()        # 1.0
echo "Y: ", p3d.y()        # 2.0
echo "Z: ", p3d.z()        # 3.0
echo p3d                    # Point (1.0 2.0 3.0)
```
