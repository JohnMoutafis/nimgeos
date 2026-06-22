# Polygon

Create, inspect, and serialize polygon geometries with optional holes (interior rings).

---

## Constructor

```nim
proc createPolygon*(ctx: var GeosContext; shell: LinearRing; holes: openArray[LinearRing] = []): Polygon
```

Creates a `Polygon` from a shell `LinearRing` and zero or more hole `LinearRing`s.

**Ownership transfer.** The shell and all holes transfer ownership to the new polygon. After calling `createPolygon`, the passed-in ring handles are neutralized (set to nil) — do not use those variables again.

```nim
var ctx = initGeosContext()

let shell = ctx.createLinearRing([(0.0, 0.0), (10.0, 0.0), (10.0, 10.0), (0.0, 10.0), (0.0, 0.0)])
let poly  = ctx.createPolygon(shell)
# `shell` handle is now neutralized — cannot be used further
```

---

## Polygon with holes

Pass one or more interior ring `LinearRing`s as the `holes` parameter:

```nim
var ctx = initGeosContext()

let shell = ctx.createLinearRing([(0.0, 0.0), (10.0, 0.0), (10.0, 10.0), (0.0, 10.0), (0.0, 0.0)])
let hole  = ctx.createLinearRing([(2.0, 2.0), (8.0, 2.0), (8.0, 8.0), (2.0, 8.0), (2.0, 2.0)])

let poly = ctx.createPolygon(shell, [hole])
# Both `shell` and `hole` handles are now neutralized
```

---

## Accessors

### exteriorRing

```nim
proc exteriorRing*(p: Polygon): LinearRing
```

Returns a **clone** of the exterior ring (shell) as a `LinearRing`. The caller owns the result. Modifications to the returned ring do not affect the polygon.

```nim
let ring = poly.exteriorRing()
echo ring.numCoordinates()  # 5
```

### numInteriorRings

```nim
proc numInteriorRings*(p: Polygon): int
```

Returns the number of interior rings (holes). Returns `0` for a polygon with no holes.

### interiorRingN

```nim
proc interiorRingN*(p: Polygon; n: int): LinearRing
```

Returns a **clone** of the interior ring at 0-based index `n`. Raises `GeosGeomError` if `n` is out of bounds.

```nim
if poly.numInteriorRings() > 0:
  let firstHole = poly.interiorRingN(0)
  echo firstHole.numCoordinates()
```

---

## String representation

```nim
method `$`*(p: Polygon): string
```

Returns a summary string showing the number of holes:

```nim
let simple = ctx.createPolygon(shell)
echo simple  # "Polygon(0 holes)"

let withHole = ctx.createPolygon(shell, [hole])
echo withHole  # "Polygon(1 holes)"
```

---

## Full example

```nim
import nimgeos

var ctx = initGeosContext()

# Shell: 10×10 square
let shell = ctx.createLinearRing([(0.0, 0.0), (10.0, 0.0), (10.0, 10.0), (0.0, 10.0), (0.0, 0.0)])

# Hole: 6×6 inner square
let hole = ctx.createLinearRing([(2.0, 2.0), (8.0, 2.0), (8.0, 8.0), (2.0, 8.0), (2.0, 2.0)])

let poly = ctx.createPolygon(shell, [hole])

echo poly               # "Polygon(1 holes)"
echo poly.exteriorRing()  # LinearRing (5 coords)
echo poly.numInteriorRings()  # 1

let inner = poly.interiorRingN(0)
echo inner.numCoordinates()  # 5
```
