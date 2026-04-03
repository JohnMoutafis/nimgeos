## GEOS context lifecycle wrapper.
## One GeosContext per thread. Non-copyable, deterministically destroyed by ORC.

import ./private/geos_abi
import ./errors

# ── Message handler callbacks ─────────────────────────────────────────────────
# These are plain C callbacks — no Nim GC objects may be captured.
proc defaultNoticeHandler(message: cstring; userdata: pointer) {.cdecl, raises: [], gcsafe.} =
  ## Default notice handler that writes to stderr.
  when defined(geosDebug):
    try:
      stderr.write("GEOS notice: " & $message & "\n")
    except IOError:
      discard

proc defaultErrorHandler(message: cstring; userdata: pointer) {.cdecl, raises: [], gcsafe.} =
  ## Default error handler that writes to stderr.
  try:
    stderr.write("GEOS error: " & $message & "\n")
  except IOError:
    discard

# ── GeosContext type ───────────────────────────────────────────────────────────
type
  GeosContext* = object
    handle*: GEOSContextHandle_t

## Disallows copying of GeosContext
proc `=copy`*(dst: var GeosContext; src: GeosContext) {.error:
  "GeosContext is non-copyable. Pass by var or use move().".}

proc `=destroy`*(ctx: GeosContext) =
  ## Destroys the GEOS context, freeing any resources associated with it.
  if cast[pointer](ctx.handle) != nil:
    GEOS_finish_r(ctx.handle)

# ── Constructor ───────────────────────────────────────────────────────────────
proc initGeosContext*(
  noticeHandler: GEOSMessageHandler_r = defaultNoticeHandler,
  errorHandler:  GEOSMessageHandler_r = defaultErrorHandler
): GeosContext =
  ## Initialise a GEOS context. Raises GeosInitError if GEOS fails to start.
  let handle = GEOS_init_r()
  if cast[pointer](handle) == nil:
    raise newException(GeosInitError, "GEOS_init_r() returned nil — is libgeos_c installed?")

  GEOSContext_setNoticeMessageHandler_r(handle, noticeHandler, nil)
  GEOSContext_setErrorMessageHandler_r(handle, errorHandler, nil)
  return GeosContext(handle: handle)

# ── Utility ───────────────────────────────────────────────────────────────────
proc version*(ctx: GeosContext): string =
  ## Returns the runtime GEOS version string e.g. "3.12.1"
  return $GEOSversion()

proc isNil*(ctx: GeosContext): bool {.inline.} =
  ## Checks if the context handle is nil (i.e. the context has been destroyed).
  cast[pointer](ctx.handle) == nil
