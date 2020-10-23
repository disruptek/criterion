import criterion
import std/sha1
import strutils

var cfg = newDefaultConfig()
cfg.warmupBudget = 0.1
cfg.budget = 0.1

benchmark cfg:
  iterator strsrc(): string =
    yield repeat('a', 20)
    yield repeat('a', 200)
    yield repeat('a', 2000)

  proc fastSHA(input: string) {.measure: strsrc.} =
    discard secureHash(input)
