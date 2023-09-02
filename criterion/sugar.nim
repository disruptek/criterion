import macros
import sequtils
import strutils
import streams
import typetraits

import impl
import config
import statistics

import exporter
import consoleExporter
import jsonExporter

const
  ELLIPSIZE_THRESHOLD = 15

proc ellipsize[T](obj: T): string =
  when T is object|tuple|array|seq:
    return $obj.type
  else:
    var s = $obj

    if s.len < ELLIPSIZE_THRESHOLD:
      return s

    result = s[0..5] & "..." & s[^6..^1] & "[" & $s.len & "]"

proc dissectType(t: NimNode): BiggestInt =
  let
    ty = getType(t)
  result = case ty.typeKind
  of ntyProc:
    # Get the return type
    dissectType(ty[^1])
  of ntyArray, ntySequence:
    # Get the type of the contained values
    dissectType(ty[^1])
  of ntyTuple:
    ty.len - 1
  of ntyEmpty, ntyNone:
    0
  else:
    1

proc countArguments(n: NimNode, req, max: var int, idents: var seq[string]) =
  case n.kind
  of nnkIdentDefs:
    # <ident1> ... <identN>, <type>, <default>
    for i in 0..<n.len - 2:
      idents.add($n[i])
    max += n.len - 2
    if n[^1].kind == nnkEmpty:
      req += n.len - 2
  of nnkFormalParams:
    # <return>, <args> ... <args>
    for i in 1..<n.len:
      countArguments(n[i], req, max, idents)
  else:
    doAssert false, "unhandled node kind " & $n.kind

template returnsVoid(params: NimNode): bool =
  params[0].kind == nnkEmpty or getType(params[0]).typeKind == ntyVoid

proc hasPragma(n: NimNode, id: string): NimNode =
  ## returns the matching pragma's arguments, or
  ## the matching pragma if it has none, or
  ## nil
  for p in pragma(n):
    case p.kind
    of nnkSym:
      if eqIdent($p, id):
        return p
    of nnkExprColonExpr:
      if eqIdent($p[0], id):
        return p
    else:
      doAssert false, "bad assumption about the ast: " & $p.kind

proc arityMismatchError(n: NimNode, name: string, got, expected: BiggestInt) =
  error("`" & name & "` expects " & $expected & " argument(s) but got " & $got, n)

proc genFixture(cfg, accum, n, args: NimNode): NimNode =
  ## Generates the benchmarking fixture for a given procedure ``n``.
  expectKind n, {nnkProcDef, nnkFuncDef}

  let procName = n.name
  let procParams = n.params

  var reqArgs, maxArgs = 0
  var argNames: seq[string] = @[]
  countArguments(procParams, reqArgs, maxArgs, argNames)

  if reqArgs != maxArgs:
    error("Procedures with default arguments are not supported", n)
  if not returnsVoid(procParams):
    error("This procedure return type is not void", n)

  let procNameStr = newStrLitNode($procName)

  var comment = # Reset the comment to a documentation comment, if available
    if n[^1][0].kind == nnkCommentStmt:  # first stmt of proc body
      newLit(n[^1][0].strVal)
    else:
      procNameStr

  if args != nil:
    # Try to figure out if `args` returns a n-element tuple and pass'em all as
    # distinct arguments
    let typeArity = dissectType(args)

    if typeArity != maxArgs:
      arityMismatchError(n, $procName, typeArity, maxArgs)

    var innerBody = newCall(procName)
    let collectArgsLoop = newStmtList()
    let arg = nskForVar.genSym("arg")
    var argsVar = nskVar.genSym("args")

    # Unpack `arg` if necessary and record the param <-> value assignment
    case typeArity:
    of 0:
      discard
    of 1:
      # Single argument only, pass as-is
      innerBody.add(arg)
      collectArgsLoop.add(newCall("add", argsVar,
        newPar(newStrLitNode(argNames[0]), newCall(bindSym"ellipsize", arg))))
    else:
      for i in 0..<typeArity.int:
        let argN = newNimNode(nnkBracketExpr).add(arg, newIntLitNode(i))
        innerBody.add(argN)
        collectArgsLoop.add(newCall("add", argsVar,
          newPar(newStrLitNode(argNames[i]), newCall(bindSym"ellipsize", argN))))

    # If an iterator/proc name is passed we must wrap it in a call node
    let iter = if getType(args).typeKind() == ntyProc:
      newCall(args)
    else:
      args

    result = quote do:
      when not compiles((for _ in `iter`: discard)):
        {.error: "The argument must be an iterable object".}
      else:
        for `arg` in `iter`:
          var `argsVar` = newSeqOfCap[(string, string)](`typeArity`)
          `collectArgsLoop`
          `accum`.add ((
            bench(`cfg`, `comment`, proc () = `innerBody`),
            `procNameStr`,
            `comment`,
            `argsVar`))
  else:
    if maxArgs != 0:
      arityMismatchError(n, $procName, 0, maxArgs)

    let innerBody = newCall(procName)
    result = quote do:
      `accum`.add ((
        bench(`cfg`, `comment`, proc () = `innerBody`),
        `procNameStr`,
        `comment`,
        @[]))

when not declared(openFileStream):
  # openFileStream isn't available on stable despite what the documentation says
  # so we replicate it here
  proc openFileStream(filename: string, mode: FileMode = fmRead,
    bufSize: int = -1): FileStream =
    var f: File
    if open(f, filename, mode, bufSize):
      return newFileStream(f)
    else:
      raise newException(IOError, "cannot open file")

macro xbenchmark(userCfg: Config, body: typed): untyped =
  result = newStmtList()
  let localCfg = ident"_cfg"
  let accum = ident"_accum"
  let strm = ident"_strm"

  result.add quote do:
    let `localCfg` = `userCfg`
    var `accum`: seq[BenchmarkResult] = @[]
    var `strm`: Stream = nil

    # Open the ``strm`` stream here so we can catch and report any error in the
    # user-supplied path before the time-consuming loop is reached
    if `localCfg`.outputPath.len != 0:
      var path: string
      try:
        path = `localCfg`.outputPath % []
        `strm` = openFileStream(path, fmWrite)
      except ValueError:
        # The format string is not valid
        echo "Invalid format string for 'outputPath': ", `localCfg`.outputPath
        quit(1)
      except IOError:
        echo "Could not open the output file: ", path
        quit(1)

  proc transform(dest, n: NimNode) =
    ## Perform an almost-exact copy of ``n`` into ``dest`` but add the
    ## benchmarking fixtures when needed
    case n.kind
    of nnkStmtList:
      let sl = newTree(nnkStmtList)
      for s in n.items:
        transform(sl, s)
      dest.add sl
    of nnkBlockStmt:
      let sl = newTree(nnkStmtList)
      # The transformed contents are appended into a fresh nnkStmtList
      # since the block body may not be one
      transform(sl, n[1])
      dest.add newBlockStmt(n[0], sl)
    of nnkProcDef, nnkFuncDef:
      # add the real version
      dest.add n

      # add the fixtured version
      let pNode = hasPragma(n, "measure")
      if pNode != nil:
        if pNode.kind == nnkExprColonExpr:
          dest.add genFixture(localCfg, accum, n, pNode[1])
        else:
          dest.add genFixture(localCfg, accum, n, nil)
    else:
      dest.add n

  transform(result, body)

  # Once all the benchmarks have been run print the results
  result.add quote do:
    let strm = newFileStream(stdout)
    toDisplay(cfg, strm, `accum`)
    # Flush only, don't close stdout!
    flush(strm)

  # If requested dump everything into a json file
  result.add quote do:
    if `strm` != nil:
      toJson(cfg, `strm`, `accum`)
      close(`strm`)

  when defined(criterionDebugMacro):
    echo repr result

template benchmark*(userCfg: Config, body: untyped): untyped =
  ## This template wraps the ``xbenchmark`` invocation that does the heavy
  ## lifting. This is needed in order to give ``body`` its own scope.
  block:
    xbenchmark(userCfg):
      body

# Those two pragmas are recognized by the ``benchmark`` macro
template measure*() {.pragma.}
template measure*(_: typed) {.pragma.}
