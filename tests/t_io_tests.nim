import utils, ../writer_utils, ../types
import ../constructs/[justtypes,cs_root]
import ../constructs/cs_all_constructs
import unittest, os

proc modulesFromFiles(files: seq[string]): seq[Module] =
  var root = newCs(CsRoot)
  processFiles(root, files)
  result = root.gen(glNim)

proc names(modules: seq[Module]): seq[string] =
  var got: seq[string] #= @[]
  for m in modules:
    got.add(m.name)
  result = got

import sets, algorithm

proc compareNames(a, b: seq[string]): bool =
  check a.sorted == b.sorted
  return a.sorted == b.sorted

suite "module output tests - file naming according to namespace":
  test "one namespace":
    let modules = modulesFromFiles @["tests/samples/one_namespace.csast"]
    echo "modules", modules
    let expected: seq[string] = @[ "MyNamespace"]
    assert compareNames(names(modules), expected)

  test "namespaces translated to nim modules":
    let modules = modulesFromFiles @["tests/samples/many_namespaces.csast"]
    var expected: seq[string] = @[ "MyNamespace",
        "MyNamespace.Nested", "MyNamespace2"]
    var got = names(modules)
    assert compareNames(expected, got)


