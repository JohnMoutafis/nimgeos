# WKB Serialization

Well-Known Binary (WKB) is a compact, portable binary format for geometry data. It is the standard representation used in PostGIS and many spatial databases.

## Byte Order

```nim
type WkbByteOrder* = enum
  wkbXDR = 0  ## Big-Endian (network byte order)
  wkbNDR = 1  ## Little-Endian (x86/ARM native)
```

`wkbNDR` (little-endian) is the default for both serializers.

## Function Reference

| Proc | Signature | Description |
|------|-----------|-------------|
| `fromWKB` | `(ctx: var GeosContext; wkb: openArray[byte]): Geometry` | Parse WKB bytes into a geometry |
| `toWKB` | `(g: Geometry; byteOrder: WkbByteOrder = wkbNDR): seq[byte]` | Serialize geometry to WKB bytes |
| `toHexWKB` | `(g: Geometry; byteOrder: WkbByteOrder = wkbNDR): string` | Serialize to an uppercase hex-encoded string |
| `fromHexWKB` | `(ctx: var GeosContext; hex: string): Geometry` | Parse hex-encoded WKB back into a geometry |

All procedures raise `GeosInitError` on writer/reader creation failure and `GeosParseError` on malformed input.

## Example — Round Trip

```nim
import nimgeos

let ctx = initGeosContext()
let original = ctx.fromWKT("POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))")

# Serialize to binary WKB (little-endian)
let bytes = original.toWKB()
echo bytes.len  # 93 bytes (2D polygon)

# Round-trip back
let restored = ctx.fromWKB(bytes)
echo original.equals(restored)  # true

# Hex WKB for text-safe transport
let hex = original.toHexWKB(wkbXDR)  # big-endian
echo hex  # "00000003..."
let fromHex = ctx.fromHexWKB(hex)
echo original.equals(fromHex)  # true
```

## PostGIS Interop

WKB bytes produced by `toWKB` can be inserted directly into PostGIS:

```sql
INSERT INTO spatial_table (geom)
VALUES (ST_GeomFromWKB(?))
```

Conversely, reading from PostGIS via `ST_AsBinary(geom)` produces a byte sequence compatible with `fromWKB`. Use `wkbXDR` (big-endian) for network interoperability or when the receiving system expects the PostgreSQL default byte order.
