# Development Setup

- **Nim ≥ 2.0.0** — install via [choosenim](https://github.com/dom96/choosenim) or your distribution's package manager.
- **GEOS ≥ 3.8** development package — platform-specific commands are in the [installation guide](../getting-started/installation.md).
- Verify the GEOS installation reports ≥ 3.8:

```sh
geos-config --version
```

- Sanity-check your environment with the fastest test suite:

```sh
nimble testPredicates
```

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

**GEOS ≥ 3.8** — any version providing `libgeos_c` with the reentrant (`_r`) API; the floor is set by `GEOSGeom_createPointFromXY_r` (see the [support policy](../support.md)). Verify availability with:

```sh
geos-config --version
```

See also [Testing](testing.md) for the local test commands and CI policy.
