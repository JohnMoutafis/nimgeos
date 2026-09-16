# Nil-Safety

All geometry operations guard against nil handles and raise `GeosGeomError` with a descriptive label:

```nim
let nilPoly: Polygon = nil
try:
  echo nilPoly.exteriorRing()   # raises GeosGeomError: "exteriorRing called on nil Geometry"
except GeosGeomError as e:
  echo e.msg
```

This guard covers:
- Property accessors (`isEmpty`, `isValid`, `area`, `length`, `distance`, etc.)
- Sub-geometry access (`geomN`, `exteriorRing`, `interiorRingN`, `pointN`)
- Predicates (`contains`, `intersects`, etc.)
- Spatial operations (`buffer`, `difference`, `intersection`, etc.)
- Serialization (`toWKT`, `toWKB`, `toGeoJSON`)

**String representations** (`$`) raise `NilAccessDefect` on a nil geometry:

```nim
let nilPt: Point = nil
try:
  echo nilPt
except NilAccessDefect:
  echo "nil Point"  # handled
```

See also [Error Types](error-types.md) and [Context Lifecycle](../getting-started/context-lifecycle.md) for related lifetime rules.
