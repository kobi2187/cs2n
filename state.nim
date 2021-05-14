# common.nim
import stacks, sets, uuids, sequtils
# import json
# import constructs/cs_root
import types

type Block* = object
  id*: UUID
  name*: string
  info*: Info

type SearchOption* = enum
  soBlocks, soAll

var blocks* = newStack[Block]()
proc currentPath*(): seq[Block] = blocks.toSeq()
var currentConstruct* = newSeq[Block]()

import algorithm, hashes
import options

import strutils

# proc getLastBlockTypes_Orig*(typeStrs: openArray[string]): Option[Block] =
#   let loweredTypeStrs = typeStrs.mapIt(it.toLowerAscii)
#   result = getLastBlock(proc(c: Block): bool = c.name.toLowerAscii in loweredTypeStrs)


<<<<<<< HEAD
proc getLastBlockTypes(typeStrs: openArray[string], childId:UUID; so: SearchOption): Option[Block] =
=======
proc getLastBlockTypes(typeStrs: openArray[string], so: SearchOption): Option[Block] =
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
  var x = if so == soBlocks: currentPath() else: currentConstruct
  let loweredTypeStrsSet = typeStrs.mapIt(it.toLowerAscii).toHashSet()
  # let constrSet = currentConstruct.mapIt(it.name.toLowerAscii).toHashSet()
  let constrSet = x.mapIt(it.name.toLowerAscii).toHashSet()
  # the order is important though
  if (constrSet - loweredTypeStrsSet).len > 0:
    # for c in currentConstruct.reversed:
<<<<<<< HEAD
    x = x.filterIt(it.id != childId)
    for c in x.filterIt(it.name notin [ "BlockStarts"]).reversed:
      echo "- matching " & c.name
      # echo loweredTypeStrsSet
      if c.name.toLowerAscii in loweredTypeStrsSet:
        echo "found it: " & c.name
        result = some(c)
        break
  else: result = none(Block)

proc getLastTypes*(typeStrs: openArray[string], childId:UUID): Option[Block] =
  result = getLastBlockTypes(typeStrs, childId, soAll)
proc getLastBlocks*(typeStrs: openArray[string],childId:UUID): Option[Block] =
  result = getLastBlockTypes(typeStrs, childId, soBlocks)
proc getLastType*(typeStr: string, childId:UUID): Option[Block] =
  result = getLastTypes(@[typestr], childId)

proc getLastBlock*(cond: (proc(c: Block): bool), childId:UUID, so = soBlocks): Option[Block] =
  var x = if so == soBlocks: currentPath() else: currentConstruct
  for c in x.reversed.filterIt(it.id != childId):
    if c.cond(): return c.some
  return none(Block)

proc getLastType*(cond: (proc(c: Block): bool), childId:UUID): Option[Block] =
  result = getLastBlock(cond, childId, soAll)
=======
    for c in x.reversed:
      if c.name.toLowerAscii in loweredTypeStrsSet:
        result = some(c)
  else: result = none(Block)

proc getLastTypes*(typeStrs: openArray[string]): Option[Block] =
  result = getLastBlockTypes(typeStrs, soAll)
proc getLastBlocks*(typeStrs: openArray[string]): Option[Block] =
  result = getLastBlockTypes(typeStrs, soBlocks)
proc getLastType*(typeStr: string): Option[Block] =
  result = getLastTypes(@[typestr])

proc getLastBlock*(cond: (proc(c: Block): bool), so = soBlocks): Option[Block] =
  var x = if so == soBlocks: currentPath() else: currentConstruct
  for c in x.reversed:
    if c.cond(): return c.some
  return none(Block)

proc getLastType*(cond: (proc(c: Block): bool)): Option[Block] =
  result = getLastBlock(cond, soAll)

# import construct, tables


>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3

proc prevprevConstruct*: Block =
  let skipList = @[
    "BlockStarts"
  ].toHashSet()
  assert currentConstruct.len >= 3
  for i, c in currentConstruct[0 .. ^3].reversed:
    if not (c.name in skipList):
      return c

proc previousConstruct*: Block =
  let skipList = @[
    "BlockStarts"
  ].toHashSet()
  assert currentConstruct.len >= 2
  for i, c in currentConstruct[0 .. ^2].reversed:
    # if i > 0:
    if not (c.name in skipList):
      return c

# declaration string as received from cs side.
let blockTypesTxt* = [ # everything in C# that has an opening { brace
  "BlockStarts",       # needed!!
  "AccessorDeclaration",
  "AnonymousMethodExpression",
  "CatchClause",
  "CheckedStatement",
  "ClassDeclaration",
  "ConstructorDeclaration",
  "ConversionOperatorDeclaration",
  "DestructorDeclaration",
  "DoStatement",
  "ElseClause",
  "EnumDeclaration",
  "FinallyClause",
  "FixedStatement",
  "ForEachStatement",
  "ForStatement",
  "IfStatement",
  "IndexerDeclaration",
  "LockStatement",
  "MethodDeclaration",
<<<<<<< HEAD
  "LocalFunctionStatement",
=======
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
  "NamespaceDeclaration",
  "OperatorDeclaration",
  "ParenthesizedLambdaExpression",
  "PropertyDeclaration",
  "SimpleLambdaExpression",
  "StructDeclaration",
  "SwitchSection",
  "SwitchStatement",
  "TryStatement",
  "UnsafeStatement",
  "UsingStatement",
  "WhileStatement",

].toHashSet
# note: if endblock raises an assert, it means a previous construct was not recorded here.


