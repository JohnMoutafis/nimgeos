# Installation

nimgeos requires a working installation of **libgeos\_c** at both compile time and runtime. The GEOS C library provides the geometry engine that all operations delegate to.

## Prerequisites

### macOS

```sh
brew install geos
```

### Debian / Ubuntu

```sh
sudo apt-get install libgeos-dev
```

### Fedora / RHEL

```sh
sudo dnf install geos-devel
```

### Windows

Windows support is experimental. GEOS binaries can be obtained from [vcpkg](https://vcpkg.io/), [conda-forge](https://anaconda.org/conda-forge/libgeos), or by building from [source](https://github.com/libgeos/geos).

```sh
# via vcpkg
vcpkg install geos
```

## Verify the installation

Confirm that `geos-config` is on your `PATH` and reports a version:

```sh
geos-config --version   # e.g. 3.12.1
```

If this command fails, the GEOS development headers are not installed or `geos-config` is not on `PATH`.

## Install the nimble package

```sh
nimble install nimgeos
```

## Add to a project

Add the dependency to your `.nimble` file:

```nim
requires "nimgeos"
```

## Platform support

| Platform   | Status       |
|------------|--------------|
| Ubuntu LTS | ✅ Supported |
| macOS      | ✅ Supported |
| Windows    | 🧪 Experimental |

## Build documentation

```sh
nimble docs
```

Output is written to `src/htmldocs/`.

## Run tests

```sh
nimble test
```

## Code example

```nim
import nimgeos

# Verify GEOS is reachable
var ctx = initGeosContext()
echo "GEOS version: ", ctx.version()   # e.g. 3.12.1
```
