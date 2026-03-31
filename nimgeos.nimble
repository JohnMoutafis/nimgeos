# Package
version       = "0.1.0"
author        = "John Moutafis"
description   = "Nim wrapper for the GEOS geometry engine (libgeos_c)"
license       = "MIT"
srcDir        = "src"

# Dependencies
requires "nim >= 2.0.0"

proc findTestFiles(dir: string): seq[string] =
  for file in listFiles(dir):
    if file.startsWith("t") and file.endsWith(".nim"):
      result.add(file)
  for subdir in listDirs(dir):
    result.add(findTestFiles(subdir))

task test, "Run all tests":
  for file in findTestFiles("tests"):
    echo "Running: " & file
    exec "nim r --hints:off " & file

task testSerializers, "Run serializer tests":
  for file in findTestFiles("tests/test_serializers"):
    echo "Running: " & file
    exec "nim r --hints:off " & file

task testGeometries, "Run geometry tests":
  for file in findTestFiles("tests/test_geometries"):
    echo "Running: " & file
    exec "nim r --hints:off " & file
