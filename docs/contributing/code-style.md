# Code Style

Follow the official [Nim style guide](https://nim-lang.org/docs/nep1.html) as used throughout the codebase:

- 2-space indentation, `camelCase` for procs and variables, `PascalCase` for types.
- Mark public API symbols with `*`; keep implementation details unexported.

## GEOS binding rules

- Declare raw `libgeos_c` bindings **only** in `src/nimgeos/private/geos_abi.nim` — feature modules import it but never re-declare bindings elsewhere.
- Guard every public entry point with the existing guards — `checkContext` (`context.nim`), `checkHandle` for `Geometry` (`geometry.nim`) and `CoordSeq` (`geometries/coord_seq.nim`) — following the established pattern: guard → call the `_r` binding → raise `GeosGeomError` when GEOS returns nil or an exception code.
- Raise only error types from `src/nimgeos/errors.nim`, with messages matching the existing conventions (`"<op> called on nil Geometry"`, `"<op> failed"`). See [Error Types](../patterns/error-types.md).
