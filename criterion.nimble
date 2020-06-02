# Package

version       = "0.1.2"
author        = "LemonBoy"
description   = "Statistic-driven microbenchmark framework"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 1.0.6"

task test, "Runs the test suite":
  var test = "tests/tfib.nim"
  exec "nim c -d:danger -r " & test
  when NimMajor >= 1 and NimMinor >= 1:
    exec "nim c --useVersion:1.0 -d:danger -r " & test
    exec "nim c   --gc:arc -r " & test
    exec "nim cpp --gc:arc -d:danger -r " & test
