# Testing & CI Policy

Install `libgeos_c` first (see the [installation guide](../getting-started/installation.md)).

## Running tests locally

```sh
nimble test              # run all tests
```

Sub-task shortcuts:

```sh
nimble testGeometries    # geometry tests (Point, LineString, Polygon, Multi*, LinearRing)
nimble testSerializers   # WKT, WKB, GeoJSON round-trips
nimble testPredicates    # spatial predicates
nimble testSpatialOperations  # spatial operations
nimble testPreparedGeom  # prepared geometry tests
nimble testEdgeCases     # edge-case tests
```

Test files MUST be named `t_*.nim` under `tests/` (or its `test_*/` subdirectories) — the nimble `findTestFiles` helper skips anything else, so misnamed tests silently never run under `nimble test`.

## CI policy

- CI runs on **every PR** and **every push to `main`**.
- All test suites execute on each run: core, geometries, serializers, predicates, spatial operations, edge cases.
- Documentation build is verified in CI.
- **PRs must pass CI on at least one supported platform** (Ubuntu or macOS) before merge.
- Windows and Nim devel failures are **non-blocking** (informational only).

## Contributing changes

1. **Fork** the repository and create a feature branch from `main`.
2. **Make your changes** — ensure the code compiles and follows the [code style](code-style.md).
3. **Run tests locally** before submitting.
4. **Open a pull request** against the `main` branch.

Guidelines:
- New features should include tests covering the new functionality.
- Bug fixes should include a regression test that fails before the fix and passes after.
- Keep [CHANGELOG.md](https://github.com/JohnMoutafis/nimgeos/blob/main/CHANGELOG.md) updated for every user-visible change ([Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format).
