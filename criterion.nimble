version       = "0.2.9"
author        = "LemonBoy"
description   = "Statistic-driven microbenchmark framework"
license       = "MIT"

task demo, "generate svg":
  exec """demo docs/fib.svg "nim c -d:danger --out=\$1 --define:tfibOutput:off tests/tfib.nim""""
  exec """demo docs/brief.svg "nim c -d:danger --out=\$1 --define:briefOutput:on tests/tfib.nim""""
  exec """demo docs/many.svg "nim c -d:danger --out=\$1 tests/many.nim""""
