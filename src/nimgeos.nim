## nimgeos — Nim wrapper for the GEOS geometry engine.
##
## Public API re-exports. Internal modules (``private/``, ``factories``) are
## intentionally **not** re-exported.

# ── Core ──────────────────────────────────────────────────────────────────────
import nimgeos/errors
import nimgeos/context

# ── Geometry types ────────────────────────────────────────────────────────────
import nimgeos/geometry
import nimgeos/geometries/point
import nimgeos/geometries/linestring
import nimgeos/geometries/linearring
import nimgeos/geometries/polygon
import nimgeos/geometries/multi
import nimgeos/geometries/prepared
import nimgeos/geometries/coord_seq

# ── Base operations & iterators (geomN, items) ───────────────────────────────
import nimgeos/geometry_base

# ── Serializers ───────────────────────────────────────────────────────────────
import nimgeos/serializers/wkt
import nimgeos/serializers/wkb
import nimgeos/serializers/geojson

# ── Predicates & spatial operations ───────────────────────────────────────────
import nimgeos/spatial_predicates
import nimgeos/spatial_operations

# ══════════════════════════════════════════════════════════════════════════════
# Public exports — only user-facing modules are listed here.
# `private/*` and `geometries/factories` are internal and NOT exported.
# ══════════════════════════════════════════════════════════════════════════════

export errors
export context
## Geometry types
export geometry
export point
export linestring
export linearring
export polygon
export multi
export prepared
export coord_seq
## Base operations & iterators
export geometry_base
## Serializers
export wkt
export wkb
export geojson
## Predicates & spatial operations
export spatial_predicates
export spatial_operations
