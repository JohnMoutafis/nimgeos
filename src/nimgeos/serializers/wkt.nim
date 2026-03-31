## A WKT (Well-Known Text) serializer for Nimgeos.

import ../geos_abi
import ../context
import ../geometry
import ../geometries/factories
import ../errors

# -- WKT Deserialization ────────────────────────────────────────────────────────
proc fromWKT*(ctx: var GeosContext; wkt: string): Geometry =
  ## Parse any WKT string into the corresponding concrete Geometry.
  let reader = GEOSWKTReader_create_r(ctx.handle)
  if cast[pointer](reader) == nil:
    raise newException(GeosInitError, "Failed to create WKT reader")
  defer: GEOSWKTReader_destroy_r(ctx.handle, reader)
  let handle = GEOSWKTReader_read_r(ctx.handle, reader, wkt.cstring)
  if cast[pointer](handle) == nil:
    raise newException(GeosParseError, "Failed to parse WKT: " & wkt)
  result = geomFromHandle(addr ctx, handle)

# -- WKT Serialization ──────────────────────────────────────────────────────────
proc toWKT*(g: Geometry): string =
  ## Serialize a `Geometry` to WKT.
  checkHandle(g, "toWKT")
  let writer = GEOSWKTWriter_create_r(g.ctx.handle)
  if cast[pointer](writer) == nil:
    raise newException(GeosInitError, "Failed to create WKT writer")

  defer: GEOSWKTWriter_destroy_r(g.ctx.handle, writer)
  GEOSWKTWriter_setTrim_r(g.ctx.handle, writer, 1)
  GEOSWKTWriter_setRoundingPrecision_r(g.ctx.handle, writer, 6)
  let wkt = GEOSWKTWriter_write_r(g.ctx.handle, writer, g.handle)
  if wkt == nil:
    raise newException(GeosGeomError, "WKT serialization failed")
  defer: GEOSFree_r(g.ctx.handle, cast[pointer](wkt))
  return $wkt
