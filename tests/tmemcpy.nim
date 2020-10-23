import criterion
import strutils

var cfg = newDefaultConfig()
cfg.warmupBudget = 0.1
cfg.budget = 0.1

benchmark cfg:
  var dst = newString(8192)

  iterator srcDstPair(): string =
    for n in [8,64,512,1024,8192]:
      yield 'x'.repeat(n)

  proc BM_memcpy(n: string) {.measure: srcDstPair.} =
    copyMem(unsafeAddr dst[0], unsafeAddr n[0], n.len)
