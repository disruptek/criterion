import criterion

var cfg = newDefaultConfig()
cfg.warmupBudget = 0.1
cfg.budget = 0.1

benchmark(cfg):
  # in block
  block foo:
    block bar:
      proc f() {.measure.} =
        discard
