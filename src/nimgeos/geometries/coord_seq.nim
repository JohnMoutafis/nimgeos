## CoordSeq — user-friendly wrapper around GEOSCoordSequence.
##
## Provides constructors, getters/setters, and iterators for coordinate
## sequences used by Points, LineStrings, and LinearRings.
##
## Ownership: a CoordSeq created via `newCoordSeq` owns its handle and will
## destroy it when the object goes out of scope. A CoordSeq obtained from a
## geometry via `coordSeq()` is cloned, so the caller owns the result.

import ../private/geos_abi
import ../context
import ../errors
import ../geometry

# ── Type ──────────────────────────────────────────────────────────────────────

type
  CoordSeq* = object
    ## Wraps a GEOSCoordSequence handle with ownership tracking.
    ctx*: ptr GeosContext
    handle*: GEOSCoordSequence
    owned: bool  ## true when we own the handle and must destroy it

# ── Lifecycle ─────────────────────────────────────────────────────────────────

proc `=destroy`*(cs: CoordSeq) =
  if cs.owned and cast[pointer](cs.handle) != nil and cs.ctx != nil:
    GEOSCoordSeq_destroy_r(cs.ctx.handle, cs.handle)

proc `=copy`*(dst: var CoordSeq; src: CoordSeq) {.error:
  "CoordSeq is non-copyable. Use clone() or pass by var.".}

# ── Handle check ──────────────────────────────────────────────────────────────

proc checkHandle*(cs: CoordSeq; label: string) {.inline.} =
  ## Raises GeosGeomError if the CoordSeq handle is nil.
  if cast[pointer](cs.handle) == nil:
    raise newException(GeosGeomError, label & " called on nil CoordSeq")

# ── Internal helpers ──────────────────────────────────────────────────────────

proc copyCoordSeq(ctxHandle: GEOSContextHandle_t;
                  src, dst: GEOSCoordSequence;
                  size: int; dims: int) =
  ## Copy all coordinates from `src` into `dst`.
  ## Both sequences must already be allocated with matching size/dims.
  for i in 0 ..< size:
    var x, y: cdouble
    discard GEOSCoordSeq_getX_r(ctxHandle, src, i.cuint, addr x)
    discard GEOSCoordSeq_getY_r(ctxHandle, src, i.cuint, addr y)
    discard GEOSCoordSeq_setX_r(ctxHandle, dst, i.cuint, x)
    discard GEOSCoordSeq_setY_r(ctxHandle, dst, i.cuint, y)
    if dims >= 3:
      var z: cdouble
      discard GEOSCoordSeq_getZ_r(ctxHandle, src, i.cuint, addr z)
      discard GEOSCoordSeq_setZ_r(ctxHandle, dst, i.cuint, z)

# ── Constructor ───────────────────────────────────────────────────────────────

proc newCoordSeq*(ctx: var GeosContext; size: int; dims: int = 2): CoordSeq =
  ## Create a new coordinate sequence with `size` slots and `dims` dimensions.
  ##
  ## .. code-block:: nim
  ##   var cs = newCoordSeq(ctx, 3, 2)
  ##   cs.setCoord(0, 1.0, 2.0)
  checkContext(ctx, "newCoordSeq")
  let handle = GEOSCoordSeq_create_r(ctx.handle, size.cuint, dims.cuint)
  if cast[pointer](handle) == nil:
    raise newException(GeosGeomError, "Failed to create CoordSequence")
  CoordSeq(ctx: addr ctx, handle: handle, owned: true)

# ── Extract from Geometry ─────────────────────────────────────────────────────

proc coordSeq*(g: Geometry): CoordSeq =
  ## Extract a **clone** of the coordinate sequence from a geometry.
  ## Works on Points, LineStrings, and LinearRings.
  ## The caller owns the returned CoordSeq.
  ##
  ## .. code-block:: nim
  ##   let cs = myLineString.coordSeq()
  ##   for coord in cs:
  ##     echo coord
  g.checkHandle("coordSeq")
  let borrowed = GEOSGeom_getCoordSeq_r(g.ctx.handle, g.handle)
  if cast[pointer](borrowed) == nil:
    raise newException(GeosGeomError, "GEOSGeom_getCoordSeq_r failed")

  # Get size and dims — check return codes to avoid silent zero-initialisation
  var size, dims: cuint
  if GEOSCoordSeq_getSize_r(g.ctx.handle, borrowed, addr size) == 0:
    raise newException(GeosGeomError, "GEOSCoordSeq_getSize_r failed in coordSeq")
  if GEOSCoordSeq_getDimensions_r(g.ctx.handle, borrowed, addr dims) == 0:
    raise newException(GeosGeomError, "GEOSCoordSeq_getDimensions_r failed in coordSeq")

  let cloned = GEOSCoordSeq_create_r(g.ctx.handle, size, dims)
  if cast[pointer](cloned) == nil:
    raise newException(GeosGeomError, "Failed to clone CoordSequence")

  copyCoordSeq(g.ctx.handle, borrowed, cloned, size.int, dims.int)
  CoordSeq(ctx: g.ctx, handle: cloned, owned: true)

# ── Property accessors ────────────────────────────────────────────────────────

proc len*(cs: CoordSeq): int =
  ## Return the number of coordinates in the sequence.
  cs.checkHandle("len")
  var size: cuint
  if GEOSCoordSeq_getSize_r(cs.ctx.handle, cs.handle, addr size) == 0:
    raise newException(GeosGeomError, "GEOSCoordSeq_getSize_r failed")
  size.int

proc dims*(cs: CoordSeq): int =
  ## Return the number of dimensions (2 or 3).
  cs.checkHandle("dims")
  var d: cuint
  if GEOSCoordSeq_getDimensions_r(cs.ctx.handle, cs.handle, addr d) == 0:
    raise newException(GeosGeomError, "GEOSCoordSeq_getDimensions_r failed")
  d.int

# ── Individual setters ────────────────────────────────────────────────────────

proc setX*(cs: CoordSeq; idx: int; val: float) =
  ## Set the X value at index `idx`.
  cs.checkHandle("setX")
  if GEOSCoordSeq_setX_r(cs.ctx.handle, cs.handle, idx.cuint, val.cdouble) == 0:
    raise newException(GeosGeomError, "GEOSCoordSeq_setX_r failed at index " & $idx)

proc setY*(cs: CoordSeq; idx: int; val: float) =
  ## Set the Y value at index `idx`.
  cs.checkHandle("setY")
  if GEOSCoordSeq_setY_r(cs.ctx.handle, cs.handle, idx.cuint, val.cdouble) == 0:
    raise newException(GeosGeomError, "GEOSCoordSeq_setY_r failed at index " & $idx)

proc setZ*(cs: CoordSeq; idx: int; val: float) =
  ## Set the Z value at index `idx`.
  cs.checkHandle("setZ")
  if GEOSCoordSeq_setZ_r(cs.ctx.handle, cs.handle, idx.cuint, val.cdouble) == 0:
    raise newException(GeosGeomError, "GEOSCoordSeq_setZ_r failed at index " & $idx)

# ── Individual getters ────────────────────────────────────────────────────────

proc getX*(cs: CoordSeq; idx: int): float =
  ## Get the X value at index `idx`.
  cs.checkHandle("getX")
  var v: cdouble
  if GEOSCoordSeq_getX_r(cs.ctx.handle, cs.handle, idx.cuint, addr v) == 0:
    raise newException(GeosGeomError, "GEOSCoordSeq_getX_r failed at index " & $idx)
  v.float

proc getY*(cs: CoordSeq; idx: int): float =
  ## Get the Y value at index `idx`.
  cs.checkHandle("getY")
  var v: cdouble
  if GEOSCoordSeq_getY_r(cs.ctx.handle, cs.handle, idx.cuint, addr v) == 0:
    raise newException(GeosGeomError, "GEOSCoordSeq_getY_r failed at index " & $idx)
  v.float

proc getZ*(cs: CoordSeq; idx: int): float =
  ## Get the Z value at index `idx`.
  cs.checkHandle("getZ")
  var v: cdouble
  if GEOSCoordSeq_getZ_r(cs.ctx.handle, cs.handle, idx.cuint, addr v) == 0:
    raise newException(GeosGeomError, "GEOSCoordSeq_getZ_r failed at index " & $idx)
  v.float

# ── Convenience setters ──────────────────────────────────────────────────────

proc setCoord*(cs: CoordSeq; idx: int; x, y: float) =
  ## Set both X and Y for coordinate at `idx`.
  cs.setX(idx, x)
  cs.setY(idx, y)

proc setCoord*(cs: CoordSeq; idx: int; x, y, z: float) =
  ## Set X, Y, and Z for coordinate at `idx`.
  cs.setX(idx, x)
  cs.setY(idx, y)
  cs.setZ(idx, z)

# ── Clone ─────────────────────────────────────────────────────────────────────

proc clone*(cs: CoordSeq): CoordSeq =
  ## Deep-copy a CoordSeq.  The caller owns the returned sequence.
  ##
  ## .. code-block:: nim
  ##   var copy = original.clone()
  cs.checkHandle("clone")
  let n = cs.len
  let d = cs.dims
  let newHandle = GEOSCoordSeq_create_r(cs.ctx.handle, n.cuint, d.cuint)
  if cast[pointer](newHandle) == nil:
    raise newException(GeosGeomError, "Failed to clone CoordSequence")
  copyCoordSeq(cs.ctx.handle, cs.handle, newHandle, n, d)
  CoordSeq(ctx: cs.ctx, handle: newHandle, owned: true)

# ── Convenience getters ──────────────────────────────────────────────────────

proc getCoord*(cs: CoordSeq; idx: int): (float, float) =
  ## Get `(x, y)` for coordinate at `idx`.
  (cs.getX(idx), cs.getY(idx))

proc getCoord3D*(cs: CoordSeq; idx: int): (float, float, float) =
  ## Get `(x, y, z)` for coordinate at `idx`.
  (cs.getX(idx), cs.getY(idx), cs.getZ(idx))

# ── Iterators ─────────────────────────────────────────────────────────────────

iterator items*(cs: CoordSeq): (float, float) =
  ## Iterate over all coordinates as `(x, y)` tuples.
  ##
  ## .. code-block:: nim
  ##   for (x, y) in cs:
  ##     echo x, ", ", y
  cs.checkHandle("items(CoordSeq)")
  let n = cs.len
  for i in 0 ..< n:
    var x, y: cdouble
    discard GEOSCoordSeq_getX_r(cs.ctx.handle, cs.handle, i.cuint, addr x)
    discard GEOSCoordSeq_getY_r(cs.ctx.handle, cs.handle, i.cuint, addr y)
    yield (x.float, y.float)

iterator items3D*(cs: CoordSeq): (float, float, float) =
  ## Iterate over all coordinates as `(x, y, z)` tuples.
  ##
  ## .. code-block:: nim
  ##   for (x, y, z) in cs:
  ##     echo x, ", ", y, ", ", z
  cs.checkHandle("items3D(CoordSeq)")
  let n = cs.len
  for i in 0 ..< n:
    var x, y, z: cdouble
    discard GEOSCoordSeq_getX_r(cs.ctx.handle, cs.handle, i.cuint, addr x)
    discard GEOSCoordSeq_getY_r(cs.ctx.handle, cs.handle, i.cuint, addr y)
    discard GEOSCoordSeq_getZ_r(cs.ctx.handle, cs.handle, i.cuint, addr z)
    yield (x.float, y.float, z.float)

# ── String representation ─────────────────────────────────────────────────────

proc `$`*(cs: CoordSeq): string =
  ## Display summary: ``CoordSeq(N coords, Dd)``.
  if cast[pointer](cs.handle) == nil:
    return "<nil CoordSeq>"
  "CoordSeq(" & $cs.len & " coords, " & $cs.dims & "D)"
