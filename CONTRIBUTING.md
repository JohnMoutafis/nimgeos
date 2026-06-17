# Contributing to nimgeos

First off, thank you for your interest in contributing!

**Reporting issues** — please open a [GitHub issue](https://github.com/JohnMoutafis/nimgeos/issues/new).

**Changelog** — see [CHANGELOG.md](CHANGELOG.md) for a record of all notable changes.

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

Any version providing `libgeos_c` with the reentrant (`_r`) API. Verify availability with:

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

## How to Contribute

1. **Fork** the repository and create a feature branch from `main`.
2. **Make your changes** — ensure the code compiles and follows the existing style.
3. **Run tests locally** before submitting.
4. **Open a pull request** against the `main` branch.

### Guidelines

- **New features** should include tests covering the new functionality.
- **Bug fixes** should include a regression test that fails before the fix and passes after.
- **Keep the changelog updated** — see [CHANGELOG.md](CHANGELOG.md) for the format. This project follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

*Thank you for helping make nimgeos better!*
