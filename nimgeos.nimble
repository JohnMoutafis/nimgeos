# Package
version       = "0.1.0"
author        = "John Moutafis"
description   = "Nim wrapper for the GEOS geometry engine (libgeos_c)"
license       = "MIT"
srcDir        = "src"

# Dependencies
requires "nim >= 2.0.0"

# Tasks
task test, "Run all tests":
  exec "nimble -d:testing test"
