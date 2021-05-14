import unittest, os, sequtils, strutils
import ./utils, ../types

# suite "using mono's tests C#":
#   test "mono tests C#":
#     let scanned = getMonoTests()
#     for a in scanned:
#       # check genTest(a, hasDir=true, glNim)
#       assert genTest(a, hasDir=true, glCSharp)

suite "C# code generation tests":
  # these should work:
  test "01. enums in C#":
    check genTest("enums", gl = glCSharp)
  test "02. a minimal class in C#":
    check genTest("justClass", gl = glCSharp)
  test "03. sample3 in C#":
    check genTest("sample3", gl = glCSharp)
  test "04. sample2 in C#":
    check genTest("sample2", gl = glCSharp)
  test "05. sample4 in C#":
    check genTest("sample4", gl = glCSharp)
  test "06. sample5 in C#":
    check genTest("sample5", gl = glCSharp)
  test "07. sample6 in C#":
    check genTest("sample6", gl = glCSharp)
    #[
  test "08. sample8 in C#":
    check genTest("sample8", gl = glCSharp)
  test "09. sample7 in C#":
    check genTest("sample7", gl = glCSharp)
  test "10. sample1 in C#":
    check genTest("sample1", gl = glCSharp)
  test "11. return new class in C#":
    check genTest("xwtButtonTests", gl = glCSharp)
  test "12. assign in C#":
    check genTest("sample10", gl = glCSharp)
  test "13. functions1 in C#":
    check genTest("sample11", gl = glCSharp)
  test "14. functions2 in C#":
    check genTest("sample12", gl = glCSharp)
  test "15. binary expression in C#":
    check genTest("binexp", gl = glCSharp)
  test "16. field and assignment between variables in C#":
    check genTest("sample13", gl = glCSharp)

]#