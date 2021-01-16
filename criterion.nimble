version       = "0.2.6"
author        = "LemonBoy"
description   = "Statistic-driven microbenchmark framework"
license       = "MIT"

when not defined(release):
  requires "https://github.com/disruptek/balls >= 2.0.0 & < 3.0.0"

task test, "run unit tests":
  when defined(windows):
    exec "balls.cmd"
  else:
    exec "balls"

task demo, "generate svg":
  exec """demo docs/fib.svg "nim c -d:danger --out=\$1 --define:tfibOutput:off tests/tfib.nim""""
  exec """demo docs/brief.svg "nim c -d:danger --out=\$1 --define:briefOutput:on tests/tfib.nim""""
  exec """demo docs/many.svg "nim c -d:danger --out=\$1 tests/many.nim""""
