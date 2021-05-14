import utils, ../types
import unittest, os, sequtils, strutils

suite "tests from mono":
  test "mono tests":
    let scanned = getMonoTests()
    var good:seq[string]
    for a in scanned:
      let res = genTest(a, hasDir=true, glCSharp)
      # check genTest(a, hasDir=true, glCSharp)
      if res: good.add a
      else:
        echo good; assert false

      assert res