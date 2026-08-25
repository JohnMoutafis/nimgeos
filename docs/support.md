# Support Policy

The supported configurations, version guarantees, and behavioral contracts of nimgeos 1.0.0. For runtime edge-case details, see [Edge Cases](edge-cases.md).

---

## Support matrix

| Component | Minimum | Policy |
|---|---|---|
| Nim | 2.0.0 | `stable` CI-gated; `devel` best-effort (failures non-blocking) |
| GEOS (`libgeos_c`) | 3.8 | Oldest C API symbol used is `GEOSGeom_createPointFromXY_r` (`\since 3.8`); all bindings use the reentrant `_r` API |
| Linux (Ubuntu) | — | Supported; full CI on every PR and push |
| macOS | — | Supported; full CI on every PR and push |
| Windows | — | Experimental; CI runs, failures non-blocking |

The GEOS floor is set by `GEOSGeom_createPointFromXY_r`, which `createPoint` and the GeoJSON parser depend on.

### Windows status and intentions

Windows support is experimental: its CI lane runs on every push but failures do not block merges. The intent is to promote Windows to fully supported once its CI lane is reliably green; community reports and fixes are welcome in the meantime.

## Versioning policy

nimgeos follows [Semantic Versioning](https://semver.org/). Within a major version the public API does not change incompatibly.

## Geometry support expectations

- **2D geometries** — fully supported across construction, predicates, operations, and serialization.
- **3D (Z) geometries** — supported for construction (`createPoint(x, y, z)`), coordinate access (`z()`, CoordSeq `items3D`), and serialization (WKB output dimension, GeoJSON 3-value coordinates).
- **Empty geometries** (`POINT EMPTY`, …) — behavior per operation is defined; see [Empty geometries](edge-cases.md#empty-geometries).
- **NaN / ±Inf coordinates** — accepted at creation time, downstream results undefined; see [Special floating-point values](edge-cases.md#special-floating-point-values).

## Error & exception guarantees

Every failure raises an exception from the `GeosError` hierarchy — operations never fail silently or return sentinel values:

- `GeosInitError` — context initialization failure, reader/writer creation failure, or passing a destroyed context to any constructor/deserializer.
- `GeosGeomError` — geometry operation failure, nil-handle misuse, index out of bounds, or prepared-geometry guard violation.
- `GeosParseError` — malformed WKT/WKB/hex-WKB/GeoJSON input.

Nil-handle misuse raises `GeosGeomError` labelled `"<op> called on nil Geometry"`. String conversion (`$`) of a nil geometry deliberately raises `NilAccessDefect` instead — a `Defect`, which is not catchable as `CatchableError`.

Full trigger lists and examples: [Edge cases → Error types](edge-cases.md#error-types).

## Context lifetime limitations

- A `GeosContext` must outlive every geometry derived from it.
- `GeosContext` is non-copyable.
- Using geometries created in one context with another context is **undefined behavior**.
- Objects escaping a `withGeosContext` block reference a destroyed context and must not be used afterwards.
- One context per thread — never share a context across threads without external synchronization.

Details and patterns: [Context lifecycle](getting-started/context-lifecycle.md).
