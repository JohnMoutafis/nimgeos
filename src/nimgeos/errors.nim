type
  GeosError* = object of CatchableError

  GeosInitError* = object of GeosError
  GeosGeomError* = object of GeosError
  GeosParseError* = object of GeosError
