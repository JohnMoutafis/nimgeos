# GeoJSON Serialization

Serialize geometry objects to and from the GeoJSON format (RFC 7946). Only **geometry objects** are supported — `Feature` and `FeatureCollection` wrappers are out of scope.

## Function Reference

| Proc | Signature | Description |
|------|-----------|-------------|
| `toGeoJSON` | `(g: Geometry): string` | Serialize geometry to a GeoJSON geometry object string |
| `fromGeoJSON` | `(ctx: var GeosContext; json: string): Geometry` | Parse a GeoJSON geometry object string into a geometry |

`toGeoJSON` produces compact output (no pretty-printing). `fromGeoJSON` accepts any valid GeoJSON geometry object: `Point`, `LineString`, `Polygon`, `MultiPoint`, `MultiLineString`, `MultiPolygon`, and `GeometryCollection`. Both raise `GeosParseError` on malformed input.

## Coordinate Dimensions

Points with a Z coordinate are serialized to `[x, y, z]` arrays. Input coordinates with at least 3 values are deserialized as 3D geometries. NaN Z values are omitted during serialization.

## Example — Round Trip

```nim
import nimgeos

let ctx = initGeosContext()

# Serialize
let point = ctx.fromWKT("POINT (30 10)")
let json = point.toGeoJSON()
echo json  # {"type":"Point","coordinates":[30.0,10.0]}

# Deserialize back
let parsed = ctx.fromGeoJSON(json)
echo point.equals(parsed)  # true

# Polygon with a hole
let polygon = ctx.fromGeoJSON("""
  {
    "type": "Polygon",
    "coordinates": [
      [[0,0], [10,0], [10,10], [0,10], [0,0]],
      [[2,2], [2,8], [8,8], [8,2], [2,2]]
    ]
  }
""")
echo polygon.toWKT()
# POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0), (2 2, 2 8, 8 8, 8 2, 2 2))
```

Empty geometries are serialized with an empty coordinate array: `{"type":"Point","coordinates":[]}`.
