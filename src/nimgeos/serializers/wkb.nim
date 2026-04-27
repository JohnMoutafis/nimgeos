## A WKB (Well-Known Binary) serializer for Nimgeos.

import ../private/geos_abi
import ../context
import ../geometry
import ../geometries/factories
import ../errors

# ── Types ─────────────────────────────────────────────────────────────────────

type
  WkbByteOrder* = enum
    wkbXDR = 0   ## Big-Endian (network byte order)
    wkbNDR = 1   ## Little-Endian (x86/ARM native)

# ── Private helpers ───────────────────────────────────────────────────────────

proc parseHexDigit(c: char): int =
  ## Converts a single hex character to its integer value (0–15).
  ## Raises GeosParseError on invalid input.
  case c
  of '0'..'9': return ord(c) - ord('0')
  of 'a'..'f': return ord(c) - ord('a') + 10
  of 'A'..'F': return ord(c) - ord('A') + 10
  else:
    raise newException(GeosParseError, "Invalid hex character: " & $c)

# ── WKB Deserialization ───────────────────────────────────────────────────────

proc fromWKB*(ctx: var GeosContext; wkb: openArray[byte]): Geometry =
  ## Parse a WKB byte sequence into the corresponding concrete Geometry.
  checkContext(ctx, "fromWKB")
  if wkb.len == 0:
    raise newException(GeosParseError, "Cannot parse empty WKB")
  let reader = GEOSWKBReader_create_r(ctx.handle)
  if cast[pointer](reader) == nil:
    raise newException(GeosInitError, "Failed to create WKB reader")
  defer: GEOSWKBReader_destroy_r(ctx.handle, reader)
  let handle = GEOSWKBReader_read_r(ctx.handle, reader,
                                     unsafeAddr wkb[0], wkb.len.csize_t)
  if cast[pointer](handle) == nil:
    raise newException(GeosParseError, "Failed to parse WKB")
  result = geomFromHandle(addr ctx, handle)

# ── WKB Serialization ─────────────────────────────────────────────────────────

proc toWKB*(g: Geometry; byteOrder: WkbByteOrder = wkbNDR): seq[byte] =
  ## Serialize a `Geometry` to a WKB byte sequence.
  ## byteOrder selects Little-Endian NDR (default) or Big-Endian XDR.
  checkHandle(g, "toWKB")
  let writer = GEOSWKBWriter_create_r(g.ctx.handle)
  if cast[pointer](writer) == nil:
    raise newException(GeosInitError, "Failed to create WKB writer")
  defer: GEOSWKBWriter_destroy_r(g.ctx.handle, writer)
  GEOSWKBWriter_setByteOrder_r(g.ctx.handle, writer, byteOrder.cint)
  var size: csize_t
  let buf = GEOSWKBWriter_write_r(g.ctx.handle, writer, g.handle, addr size)
  if cast[pointer](buf) == nil or size == 0:
    raise newException(GeosGeomError, "WKB serialization failed")
  defer: GEOSFree_r(g.ctx.handle, cast[pointer](buf))
  result = newSeq[byte](size)
  copyMem(addr result[0], buf, size)

# ── Hex WKB ───────────────────────────────────────────────────────────────────

proc toHexWKB*(g: Geometry; byteOrder: WkbByteOrder = wkbNDR): string =
  ## Serialize a `Geometry` to an uppercase hex-encoded WKB string.
  const hexChars = "0123456789ABCDEF"
  let bytes = g.toWKB(byteOrder)
  result = newStringOfCap(bytes.len * 2)
  for b in bytes:
    result.add(hexChars[b.int shr 4])
    result.add(hexChars[b.int and 0x0F])

proc fromHexWKB*(ctx: var GeosContext; hex: string): Geometry =
  ## Parse a hex-encoded WKB string into the corresponding concrete Geometry.
  if hex.len == 0 or hex.len mod 2 != 0:
    raise newException(GeosParseError,
      "Invalid hex WKB string: length must be non-zero and even, got " & $hex.len)
  var bytes = newSeq[byte](hex.len div 2)
  for i in 0 ..< bytes.len:
    let hi = parseHexDigit(hex[i * 2])
    let lo = parseHexDigit(hex[i * 2 + 1])
    bytes[i] = byte(hi shl 4 or lo)
  result = ctx.fromWKB(bytes)
