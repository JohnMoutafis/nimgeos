# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.7.0] - 2026-04-21

### Added

- **GeoJSON Serialization**: New `serializers/geojson.nim` provides:
  - `toGeoJSON(g: Geometry)` — Serialize geometries as GeoJSON `geometry` object strings.
  - `fromGeoJSON(ctx, json)` — Parse GeoJSON `geometry` strings into `Geometry` objects.
- **ABI bindings**: Added `GEOSCoordSeq_getZ_r`, `GEOSCoordSeq_getDimensions_r`, and `GEOSGeom_getCoordSeq_r` to `geos_abi.nim`.
- **Tests**: `tests/test_serializers/t_geojson.nim` with round-trip, validation, error cases, 3D geometry, cross-format invariants, and edge case tests.

---

## [0.6.1] - 2026-04-20

### Fixed

- **ABI return-type mismatch for boolean GEOS functions** — 10 functions in
  `src/nimgeos/private/geos_abi.nim` were declared as returning `cint` but the
  underlying GEOS C API returns `char`. This caused `isEmpty()` and spatial predicates to return incorrect results on some platforms due to garbage in the upper bytes of the return register. 
  Changed the return type to `cchar` and wrapped callers with `ord()` for correct integer comparison. Affected functions: 
  - `GEOSisEmpty_r`
  - `GEOSisValid_r`
  - `GEOSEquals_r`
  - `GEOSIntersects_r`
  - `GEOSContains_r`
  - `GEOSTouches_r`
  - `GEOSWithin_r`
  - `GEOSDisjoint_r`
  - `GEOSCrosses_r`
  - `GEOSOverlaps_r`
- **CI: macOS ARM linker failure** — Homebrew on ARM runners installs to
  `/opt/homebrew` which is not in the default search paths. The CI workflow now
  exports `LIBRARY_PATH` and `C_INCLUDE_PATH` via `GITHUB_ENV` so the
  linker and compiler find `libgeos_c`.

---

## [0.6.0] - 2026-04-20

### Added

- **GitHub Actions CI pipeline** — `.github/workflows/ci.yml` runs the full test
  suite (`nimble test`) on every push to `main` and on all pull requests.
  - OS matrix: Ubuntu, macOS.
  - Nim version matrix: stable, devel (devel is allow-failure).
- **CI status badge** in `README.md`.

---

## [0.5.0] - 2026-04-08

### Added

- **WKB writer config ABI bindings** — `GEOSWKBWriter_setByteOrder_r`,
  `GEOSWKBWriter_getByteOrder_r`, `GEOSWKBWriter_setOutputDimension_r`,
  `GEOSWKBWriter_getOutputDimension_r`, `GEOSWKBWriter_setIncludeSRID_r` added to
  `src/nimgeos/private/geos_abi.nim`.
- **WKB serializer** — new module `src/nimgeos/serializers/wkb.nim` for WKB (Well-Known Binary)
  geometry encoding:
  - `fromWKB(ctx, bytes)` — parse a `seq[byte]`/`openArray[byte]` into a concrete `Geometry`.
  - `toWKB(g, byteOrder)` — serialize any `Geometry` to `seq[byte]` with configurable byte
    order (Little-Endian NDR default, Big-Endian XDR optional).
  - `toHexWKB(g, byteOrder)` — hex-encoded WKB string for PostGIS interop and debugging.
  - `fromHexWKB(ctx, hex)` — parse a hex-encoded WKB string.
  - `WkbByteOrder` enum — type-safe byte order selection (`wkbNDR`, `wkbXDR`).
- **WKB test suite** — `tests/test_serializers/t_wkb.nim` with tests for:
  round-trip, property preservation, byte order, hex encoding, deserialization errors,
  and cross-format invariants.

---

## [0.4.0] - 2026-04-07

### Added

- **Spatial operations** — new module `src/nimgeos/spatial_operations.nim` exposing 7 idiomatic
  Nim wrapper procs over the GEOS spatial operation functions:
  - **Binary** — `intersection`, `union`, `difference`: take two `Geometry` arguments and return
    a new `Geometry` representing the result of the set operation.
  - **Unary** — `convexHull`, `envelope`, `centroid`: take a single `Geometry` and return a new
    derived `Geometry`.
  - **Unary + params** — `buffer(g, width, quadsegs=8)`: expands or shrinks a geometry by the
    given width; `quadsegs` controls arc approximation quality.
  - All results are dispatched through `geomFromHandle` and returned as the correct concrete
    subtype (e.g. `centroid` always returns a `Point`).
  - `GeosGeomError` is raised on nil input or when GEOS returns a nil handle.
- **Spatial operations test suite** — `tests/t_spatial_operations.nim` with 57 tests across
  8 suites: one suite per operation (7) and a cross-operation relationships suite validating
  geometric invariants (union/intersection/difference area laws, envelope and hull containment).
- **`testSpatialOperations` nimble task** — convenience shortcut for running spatial operation
  tests only.

### Fixed

- `GEOSCentroid_r` binding in `src/nimgeos/private/geos_abi.nim` was incorrect: wrong function
  name (`GEOSCentroid_r` instead of `GEOSGetCentroid_r`) and wrong signature (out-parameter
  `ptr GEOSGeometry` + `cint` return instead of a direct `GEOSGeometry` return). Corrected to
  match the real GEOS C API.

---

## [0.3.0] - 2026-04-03

### Added

- **Spatial predicates** — new module `src/nimgeos/spatial_predicates.nim` exposing 8 idiomatic
  Nim wrapper procs over the GEOS spatial predicate functions:
  - `equals`, `intersects`, `contains`, `within`, `touches`, `disjoint`, `crosses`, `overlaps`
  - All procs operate on the base `Geometry` type and validate both arguments via `checkHandle`
    before delegating to the underlying GEOS `_r` function.
  - A GEOS exception result raises `GeosGeomError` consistently with the rest of the library.
- **`testPredicates` nimble task** — convenience shortcut for running predicate tests only.
- **Predicate test suite** — `tests/t_spatial_predicates.nim` with 62 tests across 9 suites:
  one suite per predicate and a cross-predicate relationships suite invariants.

### Changed

- `geos_abi.nim` moved from `src/nimgeos/` to `src/nimgeos/private/` to make explicit that the
  raw FFI bindings are an internal implementation detail and are not part of the public API.

---

## [0.2.0] - 2026-04-01

### Added

- **Multi-geometry types** — `MultiPoint`, `MultiLineString`, `MultiPolygon`, and
  `GeometryCollection` are now first-class types in `src/nimgeos/geometries/multi.nim`.
- **Unified constructor** — a single `createMultiGeometry` proc handles all four multi-types;
  the correct concrete type is returned based on the input geometry kinds.
- **`geomN` accessor** — retrieves the n-th sub-geometry from any multi-type as its concrete
  subtype (e.g. `MultiPoint.geomN(i)` returns a `Point`). Implemented in
  `geometries/factories.nim` to avoid circular imports.
    - TODO: Maybe a better implementation is in order for `geomN`.
- **Multi-geometry test suite** — `tests/test_geometries/t_multi.nim` with comprehensive
  coverage of construction, sub-geometry access, bounds-checking, geometry properties, and
  string representation for all multi-types.

---

## [0.1.0] - 2026-03-31

### Added

- **Concrete geometry types** — `Point`, `LineString`, `LinearRing`, and `Polygon` subtypes of
  the base `Geometry`, each with type-specific property accessors:
  - `Point` — `x()`, `y()`, `z()` (returns `NaN` for 2D geometries)
  - `LineString` — `numPoints()`, `pointN()`, `startPoint()`, `endPoint()`
  - `LinearRing` — closed-ring validation, `numCoordinates()`
  - `Polygon` — `exteriorRing()`, `numInteriorRings()`, `interiorRingN()`
- **Coordinate-based constructors** — `createPoint`, `createLineString`, `createLinearRing`,
  `createPolygon` on `GeosContext`, all accepting plain Nim tuples.
- **WKT serializer** — `src/nimgeos/serializers/wkt.nim`:
  - `fromWKT(ctx, wkt)` — parses any WKT string into the correct concrete `Geometry` subtype;
    raises `GeosParseError` on invalid input.
  - `toWKT(g)` — serialises any geometry back to a canonical WKT string.
- **Geometry factory** — `src/nimgeos/geometries/factories.nim` dispatches raw
  `GEOSGeometry` handles to the correct concrete Nim type.
- **`testGeometries` and `testSerializers` nimble tasks** — convenience shortcuts for
  running geometry and serializer tests independently.
- **Test suites** — `tests/test_geometries/` and `tests/test_serializers/` with full coverage
  of construction, coordinate accessors, geometry properties (`area`, `length`, `distance`,
  `numCoordinates`, `numGeometries`), string representation, and nil-safety for all types.

### Changed

- `Geometry` refactored to a pure base type; concrete subtypes now carry all
  type-specific logic. `geometry.nim` retains lifecycle hooks, shared accessors
  (`isEmpty`, `isValid`, `type`, `area`, `length`, `distance`), and the `clone` proc.
- WKT serialization extracted from `geometry.nim` into the dedicated
  `serializers/wkt.nim` module.

---

## [0.0.0] - 2026-03-27 — Initial scaffold

- Package scaffold: `nimgeos.nimble`, `src/nimgeos.nim`, directory layout.
- `GeosContext` — thread-local GEOS context lifecycle wrapper with deterministic
  destruction via ORC and a notice/error message handler pair.
- Base `Geometry` ref type with ORC-safe lifecycle hooks (`=destroy`, `=copy`, `=dup`)
  delegating to `GEOSGeom_destroy_r` and `GEOSGeom_clone_r`.
- `errors.nim` — `GeosError`, `GeosInitError`, `GeosGeomError`, `GeosParseError`.
- `geos_abi.nim` — raw FFI bindings to `libgeos_c` covering context management,
  geometry construction/destruction, property accessors, spatial predicates, and
  spatial operations.
- Smoke test (`t_geos_abi_smoke.nim`) and initial context/geometry test stubs.
