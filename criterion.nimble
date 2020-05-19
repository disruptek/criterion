# Package

version       = "0.1.0"
author        = "LemonBoy"
description   = "Statistic-driven microbenchmark framework"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 1.0.6"

task test, "Runs the test suite":
  exec "nim c -d:danger -r tests/tfib.nim"
  when NimMajor >= 1 and NimMinor >= 1:
    execCmd "nim c --useVersion:1.0 -d:danger -r " & test
    execCmd "nim c   --gc:arc -r " & test
    execCmd "nim cpp --gc:arc -d:danger -r " & test
