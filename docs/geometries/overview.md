# Geometry Overview

All spatial types in nimgeos inherit from `GeometryObj` (a `ref` type), which owns a GEOS geometry handle. The handle is destroyed automatically when the ref count reaches zero via ORC.

## Type hierarchy

```
GeometryObj (abstract base)
  ├── PointObj
  ├── LineStringObj
  ├── LinearRingObj
  ├── PolygonObj
  ├── MultiPointObj
  ├── MultiLineStringObj
  ├── MultiPolygonObj
  └── GeometryCollectionObj
```

## `GeomType` enum

The `type()` proc returns the concrete geometry kind:

```nim
type GeomType* = enum
  gtPoint              = 0
  gtLineString         = 1
  gtLinearRing         = 2
  gtPolygon            = 3
  gtMultiPoint         = 4
  gtMultiLineString    = 5
  gtMultiPolygon       = 6
  gtGeometryCollection = 7
```

## Base geometry procs

These procs are available on **all** geometry types:

### `type()`

Returns the `GeomType` of the geometry.

```nim
echo p.type()   # gtPoint
```

### `isEmpty()`

Returns `true` if the geometry is empty (no coordinates).

```nim
echo someGeom.isEmpty()   # bool
```

### `isValid()`

Returns `true` if the geometry is topologically valid per OGC rules.

```nim
echo someGeom.isValid()
```

### `area()`

Returns the area of the geometry (polygons and multi-polygons). Returns 0 for non-area geometries.

```nim
echo poly.area()   # 100.0
```

### `length()`

Returns the length of the geometry (linestrings and multi-linestrings). Returns 0 for non-linear geometries.

```nim
echo line.length()   # 5.0
```

### `distance(other)`

Returns the minimum distance between two geometries.

```nim
let d = p.distance(q)
```

### `numCoordinates()`

Returns the total number of coordinates in the geometry.

```nim
echo ls.numCoordinates()   # 2
```

### `numGeometries()`

Returns the number of component geometries (1 for simple types, N for multi-geometries).

```nim
echo multi.numGeometries()   # 3 points
```

### `clone()`

Deep-copies the geometry via `GEOSGeom_clone_r`. The caller owns the new independent copy.

```nim
let copy = original.clone()
```

### `$` (string representation)

Returns a compact summary of the geometry. Each concrete type implements its own format:

```nim
echo p      # Point (1.0 2.0)
echo ls     # LineString(2 points)
echo poly   # Polygon(0 holes)
```

## Full example

```nim
import nimgeos

var ctx = initGeosContext()

let p  = ctx.createPoint(0.0, 0.0)
let ls = ctx.createLineString([(0.0, 0.0), (3.0, 4.0)])
let shell = ctx.createLinearRing([
  (0.0, 0.0), (10.0, 0.0), (10.0, 10.0), (0.0, 10.0), (0.0, 0.0)])
let poly = ctx.createPolygon(shell)

echo p.type()          # gtPoint
echo p.isEmpty()       # false
echo ls.length()       # 5.0
echo poly.area()       # 100.0
echo p.distance(ls)    # 0.0
echo poly.numCoordinates()  # 5
```
