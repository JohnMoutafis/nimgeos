# Contributing to nimgeos

First off, thank you for your interest in contributing!

**Reporting issues** — please open a [GitHub issue](https://github.com/JohnMoutafis/nimgeos/issues/new).

**Changelog** — see [CHANGELOG.md](CHANGELOG.md) for a record of all notable changes.

---

## Development Setup

- **Nim ≥ 2.0.0** — install via [choosenim](https://github.com/dom96/choosenim) or your distribution's package manager.
- **GEOS ≥ 3.8** development package — platform-specific commands are in the [installation guide](docs/getting-started/installation.md).
- Verify the GEOS installation reports ≥ 3.8:

```sh
geos-config --version
```

- Sanity-check your environment with the fastest test suite:

```sh
nimble testPredicates
```

---

## Supported Platforms

### Officially supported

- **Ubuntu** (latest) — CI-tested on every PR and push to `main`.
- **macOS** (latest) — CI-tested on every PR and push to `main`.

### Experimental

- **Windows** — CI runs, but failures are non-blocking. Community contributions to improve Windows support are welcome.

### Nim versions

- **Stable** — required; all CI jobs must pass.
- **Devel** — CI runs but uses `continue-on-error`, so failures are non-blocking.

### GEOS

**GEOS ≥ 3.8** — any version providing `libgeos_c` with the reentrant (`_r`) API; the floor is set by `GEOSGeom_createPointFromXY_r` (see the [support policy](docs/support.md#support-matrix)). Verify availability with:

```sh
geos-config --version
```

---

## CI / Testing Policy

- CI runs on **every PR** and **every push to `main`**.
- All test suites execute on each run:
  - Core tests
  - Geometry tests
  - Serializer tests
  - Spatial predicates
  - Spatial operations
  - Edge cases
- **PRs must pass CI on at least one supported platform** (Ubuntu or macOS) before merge.
- Windows and Nim devel failures are **non-blocking** (informational only).
- Documentation build is verified in CI.

---

## Running Tests Locally

Install `libgeos_c` first (see the [README](README.md#prerequisites) for platform-specific instructions).

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

---

## Building Documentation

```sh
nimble docs               # build API documentation
```

---

## Code Style

Follow the official [Nim style guide](https://nim-lang.org/docs/nep1.html) as used throughout the codebase:

- 2-space indentation, `camelCase` for procs and variables, `PascalCase` for types.
- Mark public API symbols with `*`; keep implementation details unexported.
- Declare raw `libgeos_c` bindings **only** in `src/nimgeos/private/geos_abi.nim` — feature modules import it but never re-declare bindings elsewhere.
- Guard every public entry point with the existing guards — `checkContext` (`context.nim`), `checkHandle` for `Geometry` (`geometry.nim`) and `CoordSeq` (`geometries/coord_seq.nim`) — following the established pattern: guard → call the `_r` binding → raise `GeosGeomError` when GEOS returns nil or an exception code.
- Raise only error types from `src/nimgeos/errors.nim`, with messages matching the existing conventions (`"<op> called on nil Geometry"`, `"<op> failed"`).
- Name test files `t_*.nim` under `tests/` (or its `test_*/` subdirectories). The nimble `findTestFiles` helper skips anything else, so misnamed tests silently never run under `nimble test`.
- Update [CHANGELOG.md](CHANGELOG.md) for every user-visible change (Keep a Changelog format).

---

## Release Process

Maintainer checklist for cutting a release:

1. **Bump the version** — update `version` in `nimgeos.nimble`.
2. **Update the changelog** — add a `[X.Y.Z] - YYYY-MM-DD` heading to [CHANGELOG.md](CHANGELOG.md) with entries under the Keep-a-Changelog categories.
3. **Check deprecations** — confirm any currently-deprecated API aliases still work, unless this release removes them per the [support policy](docs/support.md#versioning-policy).
4. **Verify CI** — green on Ubuntu and macOS with stable Nim (Windows and Nim-devel failures are informational).
5. **Tag** — create tag `vX.Y.Z` on `main` and push it.
6. **Publish the GitHub release** from the tag with notes taken from the changelog entry — publishing triggers the docs workflow, which rebuilds and deploys the documentation site including the API reference.
7. Nimble resolves releases from git tags — no separate registry publish step is needed.

---

## How to Contribute

1. **Fork** the repository and create a feature branch from `main`.
2. **Make your changes** — ensure the code compiles and follows the existing style.
3. **Run tests locally** before submitting.
4. **Open a pull request** against the `main` branch.

### Guidelines

- **Merge gate:** CI green on `ubuntu-latest` and `macos-latest` with stable Nim; Windows and Nim-devel failures are informational only.
- **Review:** maintainer approval is required before merge.
- **New features** should include tests covering the new functionality.
- **Bug fixes** should include a regression test that fails before the fix and passes after.
- **Keep the changelog updated** — see [CHANGELOG.md](CHANGELOG.md) for the format. This project follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

*Thank you for helping make nimgeos better!*
