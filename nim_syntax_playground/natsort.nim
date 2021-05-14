# natsort.nim
import math
proc cmp*(a,b:float64):int =
  let la = log10(a).floor.toInt
  let lb = log10(b).floor.toInt
  if la == lb:
    system.cmp(a,b)
  elif la < lb: -1
  else: 1
proc cmp*[T](a,b:(float64,T)):int =
  cmp(a[0],b[0])

# proc cmp*(a,b:SomeNumber):int =
#   var bb,aa:float64
#   if a isnot float64:
#     aa = a.toBiggestFloat
#   if b isnot float64:
#     bb = b.toBiggestFloat
#   cmp(aa,bb)

when isMainModule:
  # test
  assert cmp(100.0, 100) == 0
  assert cmp(100.0, 101) == -1
  assert cmp(102.0, 101) == 1
  assert cmp(1, 10) == -1
  assert cmp(1, 100) == -1
  assert cmp(1000, 100) == 1
