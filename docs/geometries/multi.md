# Multi-Geometry Types

Four collection geometry types for grouping geometries of the same (or mixed) kind: `MultiPoint`, `MultiLineString`, `MultiPolygon`, and `GeometryCollection`.

---

## Types

```nim
MultiPoint*          = ref MultiPointObj
MultiLineString*     = ref MultiLineStringObj
MultiPolygon*        = ref MultiPolygonObj
GeometryCollection*  = ref GeometryCollectionObj
```

Each inherits from `Geometry` and can be passed to any function accepting a `Geometry`.

---

## Constructor

```nim
proc createMultiGeometry*(ctx: var GeosContext; geoms: var seq[Geometry]): Geometry
```

Creates a multi-geometry from a sequence of existing geometry objects. **Ownership is transferred** — do not use the input geometries after this call (their handles are neutralized).

### Type inference

`createMultiGeometry` inspects the input types and selects the appropriate result type:

| Input types | Result |
|---|---|
| All `Point` | `MultiPoint` |
| All `LineString` | `MultiLineString` |
| All `Polygon` | `MultiPolygon` |
| Mixed types | `GeometryCollection` |

```nim
var ctx = initGeosContext()

var points: seq[Geometry] = @[
  ctx.createPoint(0.0, 0.0),
  ctx.createPoint(1.0, 1.0),
  ctx.createPoint(2.0, 2.0),
]

let mp = ctx.createMultiGeometry(points)
# `points` items are now neutralized
echo mp.type()  # gtMultiPoint
```

---

## Sub-geometry access

```nim
proc geomN*(g: Geometry; n: int): Geometry
```

Returns a **clone** of the n-th sub-geometry (0-based) as a concrete-typed `Geometry`. Works on any multi-geometry or collection. Raises `GeosGeomError` if `n` is out of bounds.

```nim
let first = mp.geomN(0)
echo first.type()  # gtPoint
```

---

## Iterators

Each multi-geometry type provides a typed iterator that yields cloned sub-geometries:

```nim
iterator items*(g: MultiPoint): Point
iterator items*(g: MultiLineString): LineString
iterator items*(g: MultiPolygon): Polygon
iterator items*(g: GeometryCollection): Geometry
```

### Iterating a MultiPoint

```nim
let mp = ctx.createMultiGeometry(points).MultiPoint

for pt in mp:
  echo "(", pt.x(), ", ", pt.y(), ")"
```

### Iterating a MultiLineString

```nim
for ls in multiLineString:
  echo ls.numPoints(), " points"
```

### Iterating a MultiPolygon

```nim
for poly in multiPolygon:
  echo "area: ", poly.area()
```

### Iterating a GeometryCollection (mixed types)

```nim
for geom in geometryCollection:
  echo geom.type()
```

---

## Full example

```nim
import nimgeos

var ctx = initGeosContext()

# Build a MultiPoint from individual Points
var pts: seq[Geometry] = @[
  ctx.createPoint(0.0, 0.0),
  ctx.createPoint(1.0, 1.0),
  ctx.createPoint(2.0, 2.0),
]
let mp = ctx.createMultiGeometry(pts)

echo mp.numGeometries()  # 3

# Iterate
for pt in mp:
  echo "(", pt.x(), ", ", pt.y(), ")"

# Build a GeometryCollection from mixed types
var mixed: seq[Geometry] = @[
  ctx.createPoint(3.0, 4.0),
  ctx.createLineString([(0.0, 0.0), (5.0, 5.0)]),
]
let coll = ctx.createMultiGeometry(mixed)
echo coll.type()  # gtGeometryCollection

for geom in coll:
  echo geom.type()
```
