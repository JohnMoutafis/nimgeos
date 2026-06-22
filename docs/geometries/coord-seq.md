# CoordSeq

Coordinate sequence — the underlying data structure for `Point`, `LineString`, and `LinearRing` geometries.

---

## Type

```nim
CoordSeq* = object
```

A `CoordSeq` wraps a GEOS `CoordSequence` handle. It is **non-copyable** — assign by `var` or use `clone()`.

---

## Constructor

```nim
proc newCoordSeq*(ctx: var GeosContext; size: int; dims: int = 2): CoordSeq
```

Creates a new coordinate sequence with `size` slots and `dims` dimensions (2 or 3). The sequence owns its handle and will be destroyed when it goes out of scope.

```nim
var ctx = initGeosContext()
var cs  = newCoordSeq(ctx, 5, 2)
```

---

## Extract from geometry

```nim
proc coordSeq*(g: Geometry): CoordSeq
```

Extracts a **clone** of the coordinate sequence from a `Point`, `LineString`, or `LinearRing`. The caller owns the returned `CoordSeq`.

```nim
let ls   = ctx.createLineString([(0.0, 0.0), (1.0, 1.0), (2.0, 2.0)])
let cs   = ls.coordSeq()
echo cs.len  # 3
```

---

## Property accessors

```nim
proc len*(cs: CoordSeq): int     # number of coordinates
proc dims*(cs: CoordSeq): int    # 2 or 3
```

```nim
echo cs.len()   # "5"
echo cs.dims()  # "2"
```

---

## Setters

```nim
proc setX*(cs: CoordSeq; idx: int; val: float)
proc setY*(cs: CoordSeq; idx: int; val: float)
proc setZ*(cs: CoordSeq; idx: int; val: float)
proc setCoord*(cs: CoordSeq; idx: int; x, y: float)
proc setCoord*(cs: CoordSeq; idx: int; x, y, z: float)
```

Set individual coordinates by index.

```nim
cs.setX(0, 10.0)
cs.setY(0, 20.0)
cs.setCoord(1, 30.0, 40.0)
cs.setCoord(2, 50.0, 60.0, 70.0)  # 3D
```

---

## Getters

```nim
proc getX*(cs: CoordSeq; idx: int): float
proc getY*(cs: CoordSeq; idx: int): float
proc getZ*(cs: CoordSeq; idx: int): float
proc getCoord*(cs: CoordSeq; idx: int): (float, float)
proc getCoord3D*(cs: CoordSeq; idx: int): (float, float, float)
```

```nim
let x = cs.getX(0)
let y = cs.getY(0)
let (cx, cy) = cs.getCoord(0)
let (cx, cy, cz) = cs.getCoord3D(0)
```

---

## Clone

```nim
proc clone*(cs: CoordSeq): CoordSeq
```

Deep-copies the coordinate sequence. The caller owns the result.

```nim
let copy = cs.clone()
```

---

## Iterators

```nim
iterator items*(cs: CoordSeq): (float, float)
iterator items3D*(cs: CoordSeq): (float, float, float)
```

```nim
for (x, y) in cs:
  echo x, ", ", y

for (x, y, z) in cs:
  echo x, ", ", y, ", ", z
```

---

## String representation

```nim
proc `$`*(cs: CoordSeq): string
```

Returns a summary: `CoordSeq(N coords, Dd)`.

```nim
echo cs  # "CoordSeq(5 coords, 2D)"
```

---

## Full example

```nim
import nimgeos

var ctx = initGeosContext()

# Create a coordinate sequence
var cs = newCoordSeq(ctx, 3, 2)
cs.setCoord(0, 0.0, 0.0)
cs.setCoord(1, 1.0, 1.0)
cs.setCoord(2, 2.0, 2.0)

echo cs.len()   # 3
echo cs.dims()  # 2

# Iterate
for (x, y) in cs:
  echo "(", x, ", ", y, ")"

# Clone
let copy = cs.clone()

# Extract from geometry
let ls    = ctx.createLineString([(10.0, 10.0), (20.0, 20.0)])
let ls_cs = ls.coordSeq()
echo ls_cs.len()  # 2

# 3D coordinates
var cs3d = newCoordSeq(ctx, 2, 3)
cs3d.setCoord(0, 1.0, 2.0, 3.0)
cs3d.setCoord(1, 4.0, 5.0, 6.0)
let (x, y, z) = cs3d.getCoord3D(0)
echo x, ", ", y, ", ", z  # 1.0, 2.0, 3.0
```
