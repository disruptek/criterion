switch("path", "../")

proc execCmd(cmd: string) =
  echo "exec: " & cmd
  exec cmd

proc execTest(test: string) =
  execCmd "nim c   --gc:arc --define:danger --run " & test
  execCmd "nim cpp --gc:orc --define:danger --run " & test

execTest("tests/test1.nim")
execTest("tests/tfib.nim")
execTest("tests/tmemcpy.nim")
execTest("tests/tnest.nim")
