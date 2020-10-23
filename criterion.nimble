version       = "0.2.1"
author        = "LemonBoy"
description   = "Statistic-driven microbenchmark framework"
license       = "MIT"

proc execCmd(cmd: string) =
  echo "exec: " & cmd
  exec cmd

proc execTest(test: string) =
  when getEnv("GITHUB_ACTIONS", "false") != "true":
    execCmd "nim c -d:danger -r " & test
    when (NimMajor, NimMinor) >= (1, 2):
      execCmd "nim cpp --gc:orc -d:danger -r " & test
  else:
    when (NimMajor, NimMinor) >= (1, 2):
      execCmd "nim c   --gc:arc -d:danger -r " & test
      execCmd "nim cpp --gc:orc -d:danger -r " & test
    else:
      execCmd "nim c   -d:danger  -r " & test
      execCmd "nim cpp -d:danger  -r " & test

task test, "run tests for ci":
  execTest("tests/test1.nim")
  execTest("tests/tfib.nim")
  execTest("tests/tmany.nim")
  execTest("tests/tmemcpy.nim")
  execTest("tests/tnest.nim")

task docs, "generate svg":
  exec "termtosvg docs/tfib.svg --max-frame-duration=2000 --loop-delay=10000 --screen-geometry=80x30 --template=window_frame_powershell --command=\"nim c --gc:arc --define:danger --define:tfibOutput:off -r tests/tfib.nim\""
  exec "termtosvg docs/brief.svg --max-frame-duration=2000 --loop-delay=10000 --screen-geometry=80x30 --template=window_frame_powershell --command=\"nim c --gc:arc --define:danger --define:briefOutput:on -r tests/tfib.nim\""
  #exec "termtosvg docs/test1.svg --max-frame-duration=2000 --loop-delay=10000 --screen-geometry=80x30 --template=window_frame_powershell --command=\"nim c --gc:arc --define:danger -r tests/test1.nim\""
  exec "termtosvg docs/tmany.svg --max-frame-duration=2000 --loop-delay=10000 --screen-geometry=80x80 --template=window_frame_powershell --command=\"nim c --gc:arc --define:danger -r tests/tmany.nim\""
  #exec "termtosvg docs/tmemcpy.svg --max-frame-duration=2000 --loop-delay=10000 --screen-geometry=80x30 --template=window_frame_powershell --command=\"nim c --gc:arc --define:danger -r tests/tmemcpy.nim\""
