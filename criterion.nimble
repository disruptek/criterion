# Package

version       = "0.1.0"
author        = "LemonBoy"
description   = "Statistic-driven microbenchmark framework"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 1.2.0"

task test, "Runs the test suite":
  exec "nim c -d:danger --gc:arc -r tests/tfib.nim"
