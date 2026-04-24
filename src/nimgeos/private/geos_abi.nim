## Geos Application Binary Interface (ABI)
## Raw importc bindings for libgeos_c — DO NOT use directly.
## All functions use the reentrant (_r) API for thread safety.

{.passL: "-lgeos_c".}

# ── Shared pragmas ────────────────────────────────────────────────────────────
{.pragma: geosImport,    importc, cdecl, raises: [], gcsafe.}
{.pragma: geosCallback,  cdecl,   raises: [], gcsafe.}

# ── Opaque handle types ───────────────────────────────────────────────────────
# distinct pointer prevents accidental cross-type assignment at compile time
type
  GEOSContextHandle_t*  = distinct pointer
  GEOSGeometry*         = distinct pointer
  GEOSPreparedGeometry* = distinct pointer
  GEOSCoordSequence*    = distinct pointer
  GEOSWKTReader*        = distinct pointer
  GEOSWKTWriter*        = distinct pointer
  GEOSWKBReader*        = distinct pointer
  GEOSWKBWriter*        = distinct pointer
  GEOSSTRtree*          = distinct pointer

# ── Message handler callback type ─────────────────────────────────────────────
type
  GEOSMessageHandler_r* = proc(message: cstring; userdata: pointer) {.geosCallback.}

# ── Version ───────────────────────────────────────────────────────────────────
proc GEOSversion*(): cstring {.geosImport.}

# ── Context lifecycle ─────────────────────────────────────────────────────────
proc GEOS_init_r*(): GEOSContextHandle_t {.geosImport.}
proc GEOS_finish_r*(ctx: GEOSContextHandle_t) {.geosImport.}
proc GEOSContext_setNoticeMessageHandler_r*(
  ctx:      GEOSContextHandle_t;
  nf:       GEOSMessageHandler_r;
  userdata: pointer) {.geosImport.}
proc GEOSContext_setErrorMessageHandler_r*(
  ctx:      GEOSContextHandle_t;
  ef:       GEOSMessageHandler_r;
  userdata: pointer) {.geosImport.}

# ── Memory ────────────────────────────────────────────────────────────────────
proc GEOSFree_r*(ctx: GEOSContextHandle_t; p: pointer) {.geosImport.}

# ── Geometry lifecycle ────────────────────────────────────────────────────────
proc GEOSGeom_destroy_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry) {.geosImport.}
proc GEOSGeom_clone_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry): GEOSGeometry {.geosImport.}

# ── Geometry constructors ─────────────────────────────────────────────────────
proc GEOSGeom_createPoint_r*(ctx: GEOSContextHandle_t; s: GEOSCoordSequence): GEOSGeometry {.geosImport.}
proc GEOSGeom_createPointFromXY_r*(ctx: GEOSContextHandle_t; x, y: cdouble): GEOSGeometry {.geosImport.}
proc GEOSGeom_createEmptyPoint_r*(ctx: GEOSContextHandle_t): GEOSGeometry {.geosImport.}
proc GEOSGeom_createLineString_r*(ctx: GEOSContextHandle_t; s: GEOSCoordSequence): GEOSGeometry {.geosImport.}
proc GEOSGeom_createLinearRing_r*(ctx: GEOSContextHandle_t; s: GEOSCoordSequence): GEOSGeometry {.geosImport.}
proc GEOSGeom_createPolygon_r*(ctx: GEOSContextHandle_t;
                                shell: GEOSGeometry;
                                holes: ptr GEOSGeometry;
                                nholes: cuint): GEOSGeometry {.geosImport.}
proc GEOSGeom_createEmptyPolygon_r*(ctx: GEOSContextHandle_t): GEOSGeometry {.geosImport.}
proc GEOSGeom_createCollection_r*(ctx: GEOSContextHandle_t;
                                   kind: cint;
                                   geoms: ptr GEOSGeometry;
                                   ngeoms: cuint): GEOSGeometry {.geosImport.}

# ── CoordSequence ─────────────────────────────────────────────────────────────
proc GEOSCoordSeq_create_r*(ctx: GEOSContextHandle_t; size, dims: cuint): GEOSCoordSequence {.geosImport.}
proc GEOSCoordSeq_destroy_r*(ctx: GEOSContextHandle_t; s: GEOSCoordSequence) {.geosImport.}
proc GEOSCoordSeq_setX_r*(ctx: GEOSContextHandle_t; s: GEOSCoordSequence; idx: cuint; val: cdouble): cint {.geosImport.}
proc GEOSCoordSeq_setY_r*(ctx: GEOSContextHandle_t; s: GEOSCoordSequence; idx: cuint; val: cdouble): cint {.geosImport.}
proc GEOSCoordSeq_setZ_r*(ctx: GEOSContextHandle_t; s: GEOSCoordSequence; idx: cuint; val: cdouble): cint {.geosImport.}
proc GEOSCoordSeq_getX_r*(ctx: GEOSContextHandle_t;
                           s: GEOSCoordSequence; idx: cuint;
                           val: ptr cdouble): cint {.geosImport.}
proc GEOSCoordSeq_getY_r*(ctx: GEOSContextHandle_t;
                           s: GEOSCoordSequence; idx: cuint;
                           val: ptr cdouble): cint {.geosImport.}
proc GEOSCoordSeq_getSize_r*(ctx: GEOSContextHandle_t; s: GEOSCoordSequence; size: ptr cuint): cint {.geosImport.}
proc GEOSCoordSeq_getZ_r*(ctx: GEOSContextHandle_t;
                           s: GEOSCoordSequence; idx: cuint;
                           val: ptr cdouble): cint {.geosImport.}
proc GEOSCoordSeq_getDimensions_r*(ctx: GEOSContextHandle_t; s: GEOSCoordSequence; dims: ptr cuint): cint {.geosImport.}
proc GEOSGeom_getCoordSeq_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry): GEOSCoordSequence {.geosImport.}

# ── Geometry type queries ─────────────────────────────────────────────────────
proc GEOSGeomTypeId_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry): cint {.geosImport.}
proc GEOSGetNumGeometries_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry): cint {.geosImport.}
proc GEOSGetNumCoordinates_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry): cint {.geosImport.}
proc GEOSisEmpty_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry): cchar {.geosImport.}
proc GEOSisValid_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry): cchar {.geosImport.}

# ── Spatial predicates ────────────────────────────────────────────────────────
proc GEOSEquals_r*(ctx: GEOSContextHandle_t; g1, g2: GEOSGeometry): cchar {.geosImport.}
proc GEOSIntersects_r*(ctx: GEOSContextHandle_t; g1, g2: GEOSGeometry): cchar {.geosImport.}
proc GEOSContains_r*(ctx: GEOSContextHandle_t; g1, g2: GEOSGeometry): cchar {.geosImport.}
proc GEOSTouches_r*(ctx: GEOSContextHandle_t; g1, g2: GEOSGeometry): cchar {.geosImport.}
proc GEOSWithin_r*(ctx: GEOSContextHandle_t; g1, g2: GEOSGeometry): cchar {.geosImport.}
proc GEOSDisjoint_r*(ctx: GEOSContextHandle_t; g1, g2: GEOSGeometry): cchar {.geosImport.}
proc GEOSCrosses_r*(ctx: GEOSContextHandle_t; g1, g2: GEOSGeometry): cchar {.geosImport.}
proc GEOSOverlaps_r*(ctx: GEOSContextHandle_t; g1, g2: GEOSGeometry): cchar {.geosImport.}

# ── Spatial operations ────────────────────────────────────────────────────────
proc GEOSIntersection_r*(ctx: GEOSContextHandle_t; g1, g2: GEOSGeometry): GEOSGeometry {.geosImport.}
proc GEOSUnion_r*(ctx: GEOSContextHandle_t; g1, g2: GEOSGeometry): GEOSGeometry {.geosImport.}
proc GEOSDifference_r*(ctx: GEOSContextHandle_t; g1, g2: GEOSGeometry): GEOSGeometry {.geosImport.}
proc GEOSSymmetricDifference_r*(ctx: GEOSContextHandle_t; 
                                g1, g2: GEOSGeometry): GEOSGeometry {.importc: "GEOSSymDifference_r", 
                                                                      cdecl, raises: [], gcsafe.}
proc GEOSUnaryUnion_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry): GEOSGeometry {.geosImport.}
proc GEOSBuffer_r*(ctx: GEOSContextHandle_t;
                    g: GEOSGeometry;
                    width: cdouble;
                    quadsegs: cint): GEOSGeometry {.geosImport.}
proc GEOSSimplify_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry; tolerance: cdouble): GEOSGeometry {.geosImport.}
proc GEOSTopologyPreserveSimplify_r*(ctx: GEOSContextHandle_t; 
                                      g: GEOSGeometry; tolerance: cdouble): GEOSGeometry {.geosImport.}
proc GEOSSnap_r*(ctx: GEOSContextHandle_t; g1, g2: GEOSGeometry; tolerance: cdouble): GEOSGeometry {.geosImport.}
proc GEOSConvexHull_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry): GEOSGeometry {.geosImport.}
proc GEOSEnvelope_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry): GEOSGeometry {.geosImport.}
proc GEOSGetCentroid_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry): GEOSGeometry {.geosImport.}
proc GEOSBoundary_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry): GEOSGeometry {.geosImport.}

# ── Prepared geometry ─────────────────────────────────────────────────────────
proc GEOSPreparedGeom_create_r*(ctx: GEOSContextHandle_t; 
                                 g: GEOSGeometry): GEOSPreparedGeometry {.importc: "GEOSPrepare_r", 
                                                                          cdecl, raises: [], gcsafe.}
# Note: unlike GEOSPrepare_r (create), the destroy symbol actually IS named
# GEOSPreparedGeom_destroy_r in the GEOS C API, so geosImport (importc) works.
proc GEOSPreparedGeom_destroy_r*(ctx: GEOSContextHandle_t; prep: GEOSPreparedGeometry) {.geosImport.}
proc GEOSPreparedContains_r*(ctx: GEOSContextHandle_t; 
                              prep: GEOSPreparedGeometry; g: GEOSGeometry): cchar {.geosImport.}
proc GEOSPreparedIntersects_r*(ctx: GEOSContextHandle_t; 
                                prep: GEOSPreparedGeometry; g: GEOSGeometry): cchar {.geosImport.}
proc GEOSPreparedCovers_r*(ctx: GEOSContextHandle_t; prep: GEOSPreparedGeometry; g: GEOSGeometry): cchar {.geosImport.}
proc GEOSPreparedCoveredBy_r*(ctx: GEOSContextHandle_t; 
                               prep: GEOSPreparedGeometry; g: GEOSGeometry): cchar {.geosImport.}

# ── Metrics ───────────────────────────────────────────────────────────────────
proc GEOSArea_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry; area: ptr cdouble): cint {.geosImport.}
proc GEOSLength_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry; len: ptr cdouble): cint {.geosImport.}
proc GEOSDistance_r*(ctx: GEOSContextHandle_t; g1, g2: GEOSGeometry; dist: ptr cdouble): cint {.geosImport.}

# ── WKT I/O ───────────────────────────────────────────────────────────────────
proc GEOSWKTReader_create_r*(ctx: GEOSContextHandle_t): GEOSWKTReader {.geosImport.}
proc GEOSWKTReader_destroy_r*(ctx: GEOSContextHandle_t; r: GEOSWKTReader) {.geosImport.}
proc GEOSWKTReader_read_r*(ctx: GEOSContextHandle_t; r: GEOSWKTReader; wkt: cstring): GEOSGeometry {.geosImport.}
proc GEOSWKTWriter_create_r*(ctx: GEOSContextHandle_t): GEOSWKTWriter {.geosImport.}
proc GEOSWKTWriter_destroy_r*(ctx: GEOSContextHandle_t; w: GEOSWKTWriter) {.geosImport.}
proc GEOSWKTWriter_write_r*(ctx: GEOSContextHandle_t; w: GEOSWKTWriter; g: GEOSGeometry): cstring {.geosImport.}
proc GEOSWKTWriter_setTrim_r*(ctx: GEOSContextHandle_t; w: GEOSWKTWriter; trim: cint) {.geosImport.}
proc GEOSWKTWriter_setRoundingPrecision_r*(ctx: GEOSContextHandle_t; w: GEOSWKTWriter; precision: cint) {.geosImport.}

# ── WKB I/O ───────────────────────────────────────────────────────────────────
proc GEOSWKBReader_create_r*(ctx: GEOSContextHandle_t): GEOSWKBReader {.geosImport.}
proc GEOSWKBReader_destroy_r*(ctx: GEOSContextHandle_t; r: GEOSWKBReader) {.geosImport.}
proc GEOSWKBReader_read_r*(ctx: GEOSContextHandle_t;
                            r: GEOSWKBReader;
                            wkb: ptr uint8;
                            size: csize_t): GEOSGeometry {.geosImport.}
proc GEOSWKBWriter_create_r*(ctx: GEOSContextHandle_t): GEOSWKBWriter {.geosImport.}
proc GEOSWKBWriter_destroy_r*(ctx: GEOSContextHandle_t; w: GEOSWKBWriter) {.geosImport.}
proc GEOSWKBWriter_write_r*(ctx: GEOSContextHandle_t;
                             w: GEOSWKBWriter;
                             g: GEOSGeometry;
                             size: ptr csize_t): ptr uint8 {.geosImport.}
proc GEOSWKBWriter_setByteOrder_r*(ctx: GEOSContextHandle_t; w: GEOSWKBWriter; order: cint) {.geosImport.}
proc GEOSWKBWriter_getByteOrder_r*(ctx: GEOSContextHandle_t; w: GEOSWKBWriter): cint {.geosImport.}
proc GEOSWKBWriter_setOutputDimension_r*(ctx: GEOSContextHandle_t; w: GEOSWKBWriter; dim: cint) {.geosImport.}
proc GEOSWKBWriter_getOutputDimension_r*(ctx: GEOSContextHandle_t; w: GEOSWKBWriter): cint {.geosImport.}
proc GEOSWKBWriter_setIncludeSRID_r*(ctx: GEOSContextHandle_t; w: GEOSWKBWriter; include_srid: cint) {.geosImport.}

# ── Point coordinate getters ──────────────────────────────────────────────────
proc GEOSGeomGetX_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry; x: ptr cdouble): cint {.geosImport.}
proc GEOSGeomGetY_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry; y: ptr cdouble): cint {.geosImport.}
proc GEOSGeomGetZ_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry; z: ptr cdouble): cint {.geosImport.}

# ── LineString point access ───────────────────────────────────────────────────
proc GEOSGeomGetNumPoints_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry): cint {.geosImport.}
proc GEOSGeomGetPointN_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry; n: cint): GEOSGeometry {.geosImport.}
proc GEOSGeomGetStartPoint_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry): GEOSGeometry {.geosImport.}
proc GEOSGeomGetEndPoint_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry): GEOSGeometry {.geosImport.}

# ── Polygon ring access ───────────────────────────────────────────────────────
proc GEOSGetExteriorRing_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry): GEOSGeometry {.geosImport.}
proc GEOSGetInteriorRingN_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry; n: cint): GEOSGeometry {.geosImport.}
proc GEOSGetNumInteriorRings_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry): cint {.geosImport.}

# ── Collection sub-geometry access ────────────────────────────────────────────
proc GEOSGetGeometryN_r*(ctx: GEOSContextHandle_t; g: GEOSGeometry; n: cint): GEOSGeometry {.geosImport.}
