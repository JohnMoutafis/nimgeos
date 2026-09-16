## Error types for GEOS operations.
## See also: `docs/edge-cases.md`.
type
  GeosError* = object of CatchableError
    ## Base error type for GEOS operations.
  GeosInitError* = object of GeosError
    ## Raised when GEOS context initialisation fails.
  GeosGeomError* = object of GeosError
    ## Raised when a GEOS geometry operation or calculation fails.
  GeosParseError* = object of GeosError
    ## Raised when parsing WKT, WKB, or GeoJSON input fails.
