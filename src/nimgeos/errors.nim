## Error types for GEOS operations.
type
  ## Base error type for GEOS operations.
  GeosError* = object of CatchableError
  ## Raised when GEOS context initialisation fails.
  GeosInitError* = object of GeosError
  ## Raised when a GEOS geometry operation or calculation fails.
  GeosGeomError* = object of GeosError
  ## Raised when parsing WKT, WKB, or GeoJSON input fails.
  GeosParseError* = object of GeosError
