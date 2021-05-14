# testtest

type
  A = ref object of RootRef
  S = enum X, Y, Z

method done(it:A,X) = echo "1"
method done(it:A,Z) = echo "2"

done(A(),Z)