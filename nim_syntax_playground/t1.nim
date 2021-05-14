proc hello() =
  proc sum (a,b:int): int =
    proc another() = echo "hi!"
    3
  echo sum(1,2)
hello()