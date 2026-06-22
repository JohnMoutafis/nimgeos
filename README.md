# nimgeos

[![CI](https://github.com/JohnMoutafis/nimgeos/actions/workflows/ci.yml/badge.svg)](https://github.com/JohnMoutafis/nimgeos/actions/workflows/ci.yml)

Nim wrapper for the [GEOS](https://libgeos.org/) geometry engine (`libgeos_c`).

Build and manipulate 2D/3D geometries — points, linestrings, polygons,
multi-geometries and collections — using the battle-tested GEOS C library from
idiomatic Nim. Deterministic memory management via ORC, nil-safe, and
cross-platform (Linux, macOS, Windows).

## Quick start

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

# 3D geometries
let p3d = ctx.createPoint(1.0, 2.0, 3.0)
echo p3d   # Point (1.0 2.0 3.0)
```

---

## Documentation

### Getting started

- [Installation](docs/getting-started/installation.md) — Prerequisites, `nimble install`, platform compatibility
- [Context lifecycle](docs/getting-started/context-lifecycle.md) — `initGeosContext`, `withGeosContext`, error handlers, thread safety

### Geometry types

- [Geometry overview](docs/geometries/overview.md) — Type hierarchy, base procs (`type`, `isEmpty`, `area`, `length`, `distance`, `clone`, etc.)
- [Point](docs/geometries/point.md) — `createPoint` (2D/3D), `x`, `y`, `z`
- [LineString](docs/geometries/linestring.md) — `createLineString`, `numPoints`, `pointN`, `startPoint`, `endPoint`
- [LinearRing](docs/geometries/linearring.md) — `createLinearRing`, closed-ring requirement
- [Polygon](docs/geometries/polygon.md) — `createPolygon`, `exteriorRing`, holes (`numInteriorRings`, `interiorRingN`)
- [Multi-geometries](docs/geometries/multi.md) — `MultiPoint`, `MultiLineString`, `MultiPolygon`, `GeometryCollection`, `geomN`, iterators
- [Prepared geometry](docs/geometries/prepared.md) — `prepare` for fast repeated predicates
- [CoordSeq](docs/geometries/coord-seq.md) — Coordinate sequence API, getters/setters, iterators

### Serialization

- [WKT](docs/serialization/wkt.md) — `fromWKT`, `toWKT`
- [WKB](docs/serialization/wkb.md) — `fromWKB`, `toWKB`, `toHexWKB`, `fromHexWKB`, byte order
- [GeoJSON](docs/serialization/geojson.md) — `toGeoJSON`, `fromGeoJSON`

### Spatial operations

- [Predicates](docs/operations/predicates.md) — `equals`, `intersects`, `contains`, `touches`, `within`, `disjoint`, `crosses`, `overlaps`
- [Spatial operations](docs/operations/spatial-operations.md) — `intersection`, `union`, `difference`, `buffer`, `simplify`, `convexHull`, `centroid`, `envelope`, `boundary`, `snap`, `topologyPreserveSimplify`, `unaryUnion`, `symmetricDifference`

### Edge cases & error handling

- [Edge cases](docs/edge-cases.md) — Empty geometries, special floats, error types (`GeosInitError`, `GeosGeomError`, `GeosParseError`), nil-safety, cross-context operations, ownership transfer

## API reference

Generated HTML documentation is available at the [GitHub Pages site](https://johnmoutafis.github.io/nimgeos/)

## Running the tests

```sh
nimble test                   # all tests
nimble testGeometries         # geometry tests
nimble testSerializers        # WKT, WKB, GeoJSON
nimble testPredicates         # spatial predicates
nimble testSpatialOperations  # spatial operations
nimble testPreparedGeom       # prepared geometry
nimble testEdgeCases          # edge cases
```

## Supported platforms

| Platform     | Status      | CI                        |
|--------------|-------------|---------------------------|
| Ubuntu       | ✅ Supported | Full CI on every PR/push  |
| macOS        | ✅ Supported | Full CI on every PR/push  |
| Windows      | 🧪 Experimental | CI runs; failures non-blocking |

Nim versions: **stable** (required, CI-gated) and **devel** (CI runs but allow-failure).

See [installation guide](docs/getting-started/installation.md) for platform-specific prerequisites and [CONTRIBUTING.md](CONTRIBUTING.md) for CI policy.

## Deprecated APIs (removed in 2.0.0)

| Old name               | Replacement       |
|------------------------|-------------------|
| `boundaryOp(g)`        | `boundary(g)`     |
| `toPreparedGeometry(g)`| `prepare(g)`      |

## License

MIT
