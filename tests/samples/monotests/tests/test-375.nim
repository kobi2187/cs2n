type a = ref object

type a.b = ref object

type c = ref object of a
  a_var: b

type c.d = ref object
  d_var: b

proc main*() =
  discard