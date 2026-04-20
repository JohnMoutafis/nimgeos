# nimgeos

[![CI](https://github.com/JohnMoutafis/nimgeos/actions/workflows/ci.yml/badge.svg)](https://github.com/JohnMoutafis/nimgeos/actions/workflows/ci.yml)

Nim wrapper for the [GEOS](https://libgeos.org/) geometry engine (`libgeos_c`).

Build and manipulate 2D/3D geometries — points, linestrings, polygons,
multi-geometries and collections — using the battle-tested GEOS C library from
idiomatic Nim.

## Prerequisites

A working installation of **libgeos_c** is required at both compile time and
runtime.

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

Verify the library is available:

```sh
geos-config --version   # e.g. 3.12.1
```

## Installation

```sh
nimble install nimgeos
```

Or add it to your `.nimble` file:

```nim
requires "nimgeos"
```

## Quick start

```nim
import nimgeos

# Every GEOS operation runs inside a context
var ctx = initGeosContext()

# Create geometry from coordinates
let p  = ctx.createPoint(1.0, 2.0)
let ls = ctx.createLineString([(0.0, 0.0), (3.0, 4.0)])

echo p            # Point (1.0 2.0)
echo ls           # LineString(2 points)
echo ls.length()  # 5.0

# Build a polygon from a closed ring
let shell = ctx.createLinearRing([
  (0.0, 0.0), (10.0, 0.0), (10.0, 10.0), (0.0, 10.0), (0.0, 0.0)
])
let poly = ctx.createPolygon(shell)

echo poly         # Polygon(0 holes)
echo poly.area()  # 100.0

# Parse / serialize WKT
let g = ctx.fromWKT("POINT Z (1 2 3)")
echo g.toWKT()    # POINT Z (1 2 3)

# 3D geometries are supported everywhere
let p3d = ctx.createPoint(1.0, 2.0, 3.0)
echo p3d          # Point (1.0 2.0 3.0)
```

## Running the tests

```sh
nimble test
```

## License

MIT