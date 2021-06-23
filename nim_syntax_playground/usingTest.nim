type A = ref object
proc open(a:A) = echo "enter open"
proc close(a:A) = echo "enter close"

template csusing(varOrAssignment:untyped, body:untyped) =
  let x = varOrAssignment
  block:
    defer: x.close
    body

proc test1() =
  let a = A()
  a.open
  csusing a:
    echo "doing something"

proc test2() =  
  csusing (var a = A()):
    a.open
    echo "doing something2"
test()