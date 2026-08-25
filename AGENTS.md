# AGENTS.md

nimgeos is an idiomatic Nim wrapper over the GEOS C API (`libgeos_c`, reentrant `_r` bindings only). Geometry/context/coordseq handles are RAII-managed via ORC; the Nim layer is thin and delegates everything to GEOS.

## Commands

```sh
nimble test                   # all tests
nimble testGeometries         # geometry tests
nimble testSerializers        # WKT, WKB, GeoJSON
nimble testPredicates         # spatial predicates
nimble testSpatialOperations  # spatial operations
nimble testPreparedGeom       # prepared geometry
nimble testEdgeCases          # edge cases
nimble docs                   # API documentation (src/htmldocs/)
mkdocs build --strict         # docs site (needs: pip install mkdocs-material)
```

Requires Nim ≥ 2.0.0 and GEOS (`libgeos_c`) ≥ 3.8 on PATH.

## Layout

- `src/nimgeos.nim` — public module exports.
- `src/nimgeos/context.nim` — `GeosContext` lifecycle, `initGeosContext`, `withGeosContext`, `checkContext` guard.
- `src/nimgeos/errors.nim` — error hierarchy: `GeosError` → `GeosInitError`, `GeosGeomError`, `GeosParseError`.
- `src/nimgeos/geometry.nim` / `geometry_base.nim` — base type, metrics (`area`, `length`, …), `geomN`, multi-geometry iterators, `checkHandle`.
- `src/nimgeos/geometries/` — concrete types (`point`, `linestring`, `linearring`, `polygon`), `multi`, `prepared`, `coord_seq`, internal `factories`.
- `src/nimgeos/serializers/` — `wkt`, `wkb`, `geojson` (GeoJSON is hand-rolled JSON, not a GEOS binding).
- `src/nimgeos/spatial_predicates.nim`, `spatial_operations.nim` — DE-9IM predicates and set/buffer/simplify operations.
- `src/nimgeos/private/geos_abi.nim` — raw FFI declarations; the only place declaring `GEOS*_r` bindings.
- `tests/` — suites as `t_*.nim`; subdirs `test_geometries/`, `test_serializers/`, `test_edge_cases/`.

## Conventions

- Declare new `libgeos_c` bindings **only** in `private/geos_abi.nim`.
- Guard entry points with `checkContext` / `checkHandle`; pattern: guard → `_r` call → raise `GeosGeomError` on nil/exception return.
- Raise only `errors.nim` types; never fail silently.
- Test files MUST be named `t_*.nim` — anything else is silently skipped by `nimble test`.
- Ownership-transferring constructors neutralize input handles (e.g. after `createPolygon(shell, …)`, do not use `shell`).

## Read next

[CONTRIBUTING.md](CONTRIBUTING.md) · [Support policy](docs/support.md) · [Installation](docs/getting-started/installation.md) · [Context lifecycle](docs/getting-started/context-lifecycle.md) · [Edge cases](docs/edge-cases.md)
