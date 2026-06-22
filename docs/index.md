# nimgeos

Nim wrapper for the [GEOS](https://libgeos.org/) geometry engine (`libgeos_c`).

Build and manipulate 2D/3D geometries — points, linestrings, polygons,
multi-geometries and collections — using the battle-tested GEOS C library from
idiomatic Nim.

```nim
import nimgeos

var ctx = initGeosContext()

let p  = ctx.createPoint(1.0, 2.0)
let ls = ctx.createLineString([(0.0, 0.0), (3.0, 4.0)])

echo p            # Point (1.0 2.0)
echo ls           # LineString(2 points)
echo ls.length()  # 5.0

# Serialize to WKT
echo p.toWKT()    # POINT (1 2)
```

Navigate the sidebar to explore the full API and usage guides.
