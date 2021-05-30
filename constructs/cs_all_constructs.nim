{.experimental: "codeReordering".}
# import ../state_utils
import nre, sequtils, strutils, sets, re, uuids, options, tables, hashes
import ../types, justtypes
import sequtils, algorithm
# import :store_utils
include "../missingAdds.nim"

# TODO!! stop ignoring identifier names. they are important.!

var indentation* = 0
proc startBlock() =
  indentation += 2
proc endBlock() =
  indentation -= 2

template notNil(x:untyped) : bool =
  not x.isNil

proc genBody(body:seq[BodyExpr]) : string =
  var tmp :seq[string]
  for b in body:
    echo b.typ
    let gen = b.genNim()
    echo gen
    tmp.add gen
  result = tmp.mapIt(indent() & it).join("\n")

# import system
proc genPred(c:CsWhereClause|CsWhileStatement|CsDoStatement|CsIfStatement|CsConditionalExpression) : string =
  echo "in genPred"
  echo c.typ, c.src
  # assert not c.hasNoPredicate
  if not c.predicatePartLit.isNil:
    result &= c.predicatePartLit.genNim()
  elif not c.predicate.isNil:
    echo "predicate is " & c.predicate.typ
    result &= c.predicate.genNim()

  elif not c.exprThatLeadsToBoolean.isNil:
    result &= "(" & c.exprThatLeadsToBoolean.genNim() & ")"
  elif c.condTxt.len>0:
    result &= "( TODO!! " & c.condTxt & ")"

  else: assert false, " has no predicate!!"
  echo "end of genPred"

method addToUsing(parent: CsUsingStatement; item: BodyExpr) =
  if parent.variable.isNil:
    parent.variable = item
  else:
    parent.body.add item

proc `$`*(parent:CsConditionalExpression):string =
  result &= "some kind of predicate?"
  result &= " has pred:" & $(not parent.predicate.isNil)
  result &= " has leads:" & $(not parent.exprThatLeadsToBoolean.isNil)
  result &= " has lit:" & $(not parent.predicatePartLit.isNil)
  result &= " true clause empty?: " & $parent.bodyTrue.isNil
  result &= " false clause empty?: " & $parent.bodyFalse.isNil

method addConditional*(parent: CsConditionalExpression; item: BodyExpr) =
  echo "in method add*(parent: CsConditionalExpression; item: BodyExpr)"
  echo "before", parent
  # assert not parent.hasNoPredicate # commented out, because we ignore identifierName which is sometimes in the predicate part.
  if parent.bodyTrue.isNil:
    parent.bodyTrue = item
  else:
    if parent.bodyFalse.isNil:
      parent.bodyFalse = item
    else:
      assert false, "t = " & parent.bodyTrue.typ & parent.bodyTrue.src & ": f = " & parent.bodyFalse.typ & parent.bodyFalse.src
  echo "after", parent

proc colonsToTable*(s: seq[string]): TableRef[string, string] =
  new result
  for x in s:
    assert x.contains(":")
    let r = x.split(":", 1)
    let k = r[0]
    let v = r[1]
    result[k] = v

method add*(a: var ref CsObject, b: CsObject) {.base.} =
  raise newException(Exception, "missing implementation for " & a.typ & ", " & b.typ)

proc newCs*(t: typedesc[CsAccessorList]): CsAccessorList =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsIdentifier]; info: Info): CsIdentifier =
  assert false # TODO
proc extract*(t: typedesc[CsAccessorList]; info: Info): CsAccessorList =
  # let val = info.essentials[0]
  echo info
  result = newCs(CsAccessorList)
  # if val.contains("get;"):
  #   result.hasDefaultGet = true
  #   # result.hasGetBody = false
  # if val.contains("set;"):
  #   result.hasDefaultSet = true
  #   # result.hasSetBody = false
  # if val.contains(nre.re"get\s*{"):
  #   echo val;
  #   result.hasGetBody = true # TODO: check against real code.
  # if val.contains(nre.re"set\s*{"): echo val; result.hasSetBody = true

method add*(parent: CsAccessorList; item: CsAccessor) =
  parent.accessors.add item

method genCs*(c: CsIfStatement): string =
  result = "[GENCS:CsIfStatement]"

  echo "--> in genCs*(c: CsIfStatement): string ="
  todoimplGen()


method genNim*(c: CsIfStatement): string =
  echo "--> in  genNim*(c: var CsIfStatement)"
  result = "[GENNIM:CsIfStatement]"
  result = "if "
  result &= genPred(c)
  result &= ": "
  result &= c.body.genBody()
  if not c.melse.isNil:
    result &= "else: " & c.melse.genNim()
  echo "<-- end of genNim*(c: var CsIfStatement)"

method genCs*(c: CsAccessorList): string =
  result = "[GENCS:CsAccessorList]"

  echo "--> in genCs*(c: var CsAccessorList): string ="
  todoimplGen()
method genNim*(c: CsAccessorList): string =
  result = "[GENNIM:CsAccessorList]"
  echo "--> in  genNim*(c: var CsAccessorList)"
  for ac in c.accessors:
    result &= ac.genNim()
    result &= "\n"
  echo "<-- end of genNim*(c: var CsAccessorList)"

proc newCs*(t: typedesc[CsAccessor]): CsAccessor =
  new result
  result.typ = $typeof(t)

import sequtils
proc extract*(t: typedesc[CsAccessor]; info: Info): CsAccessor =
  echo info
  let tbl = colonsToTable(info.essentials)
  result = newCs(CsAccessor)
  result.kind = tbl["keyword"]
  result.statementsTxt = if tbl.hasKey("statements"): tbl["statements"] else: ""

method genCs*(c: CsAccessor): string =
  result = "[GENCS:CsAccessor]"
  echo "--> in genCs*(c: var CsAccessor): string ="
  todoimplGen()

proc genRemoveForEvent(c:CsAccessor):string =
    result = "TODO [GENNIM:CsAccessor - Remove]"
proc genAddForEvent(c:CsAccessor):string =
  result = "TODO [GENNIM:CsAccessor - Add]"
proc genSet(c:CsAccessor):string =
  result = "proc " & c.name & "(this:TODOClassName, value: type) = this._name = value"


proc genGet(c:CsAccessor):string =
  result = "TODO!! proc c.name(this:ClassName): type = "
  # echo c.statements.len
  echo c.body.len
  if c.body.len == 0 and c.expressionBody.isNil: result &= "return this._name" # simple case
  else:
    if not c.body.len == 0: # umm, or statements?
      result &= genBody(c.body)
    else:
      if not c.expressionBody.isNil:
        result &= c.expressionBody.genNim()



method genNim*(c: CsAccessor): string =
  result = "[GENNIM:CsAccessor]"
  if c.kind == "get":
    result = c.genGet()
  elif c.kind == "set":
    result = c.genSet()
  elif c.kind == "add":
    result = genAddForEvent(c)
  elif c.kind == "remove":
    result = genRemoveForEvent(c)
  else:
    assert false
  echo "--> in  genNim*(c: var CsAccessor)"

  todoimplGen()
proc newCs*(t: typedesc[CsAliasQualifiedName]): CsAliasQualifiedName =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsAliasQualifiedName]; info: Info): CsAliasQualifiedName =
  echo info
  result = newCs(CsAliasQualifiedName)

method genCs*(c: CsAliasQualifiedName): string =
  result = "[GENCS:CsAliasQualifiedName]"

  echo "--> in genCs*(c: var CsAliasQualifiedName): string ="
  todoimplGen()

method genNim*(c: CsAliasQualifiedName): string =
  result = "[GENNIM:CsAliasQualifiedName]"
  echo "--> in  genNim*(c: var CsAliasQualifiedName)"
  todoimplGen()

proc newCs*(t: typedesc[CsField]): CsField =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsField]; info: Info): CsField =
  echo info
  result = newCs(CsField)
  let tbl = colonsToTable(info.essentials)
  let mods = tbl["modifiers"]
  # info.essentials[2]
  result.name = tbl["variables"] # implies that there can be a few. get as-is unless we meet with a problem
  result.thetype = tbl["type"]

  result.isStatic = mods.contains("static")
  result.isPublic = mods.contains("public")

proc hackFindType(item: CsProperty): string =
  echo item.src
  let regex = nre.re(".*?(\\w+)\\s*" & item.name & ".*")
  let res = item.src.match(regex)
  if res.isNone: return ""
  else: return res.get.captures[0]

method genNim*(f: CsField): string =
  result = "[GENNIM:CsField]"

  echo "--> in  genNim*(f: CsField)"
  result = f.name
  if f.ispublic: result &= "*"
  result &= ": " & f.thetype

proc newCs*(t: typedesc[CsAnonymousMethodExpression]): CsAnonymousMethodExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsAnonymousMethodExpression]; info: Info): CsAnonymousMethodExpression =
  echo info
  result = newCs(CsAnonymousMethodExpression)

method genCs*(c: CsAnonymousMethodExpression): string =
  result = "[GENCS:CsAnonymousMethodExpression]"

  echo "--> in genCs*(c: var CsAnonymousMethodExpression): string ="
  todoimplGen()
method genNim*(c: CsAnonymousMethodExpression): string =
  result = "[GENNIM:CsAnonymousMethodExpression]"

  echo "--> in  genNim*(c: var CsAnonymousMethodExpression)"

  todoimplGen()
proc newCs*(t: typedesc[CsAnonymousObjectCreationExpression]): CsAnonymousObjectCreationExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsAnonymousObjectCreationExpression]; info: Info): CsAnonymousObjectCreationExpression =
  echo info
  result = newCs(CsAnonymousObjectCreationExpression)

method genCs*(c: CsAnonymousObjectCreationExpression): string =
  result = "[GENCS:CsAnonymousObjectCreationExpression]"

  echo "--> in genCs*(c: var CsAnonymousObjectCreationExpression): string ="
  todoimplGen()
method genNim*(c: CsAnonymousObjectCreationExpression): string =
  result = "[GENNIM:CsAnonymousObjectCreationExpression]"

  echo "--> in  genNim*(c: var CsAnonymousObjectCreationExpression)"

  todoimplGen()
proc newCs*(t: typedesc[CsAnonymousObjectMemberDeclarator]): CsAnonymousObjectMemberDeclarator =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsAnonymousObjectMemberDeclarator]; info: Info): CsAnonymousObjectMemberDeclarator =
  echo info
  result = newCs(CsAnonymousObjectMemberDeclarator)

method genCs*(c: CsAnonymousObjectMemberDeclarator): string =
  result = "[GENCS:CsAnonymousObjectMemberDeclarator]"

  echo "--> in genCs*(c: var CsAnonymousObjectMemberDeclarator): string ="
  todoimplGen()
method genNim*(c: CsAnonymousObjectMemberDeclarator): string =
  result = "[GENNIM:CsAnonymousObjectMemberDeclarator]"

  echo "--> in  genNim*(c: var CsAnonymousObjectMemberDeclarator)"

  todoimplGen()
proc newCs*(t: typedesc[CsArgumentList]): CsArgumentList =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsArgumentList]; info: Info): CsArgumentList =
  result = newCs(CsArgumentList) #, info.essentials[0].split(","))


proc replacementGenericTypes (s: string): string =
  if s.contains("<") and s.contains(">"):
    result = s.replace("<", "[").replace(">", "]")
  else: result = s

proc toNimType(s:string):string = # todo: feature: maybe need to change cs type names to nim type names.
  result = s.replacementGenericTypes

method genCs*(c: CsArgumentList): string =
  result = "[GENCS:CsArgumentList]"

  echo "--> in genCs*(c: var CsArgumentList): string ="
  todoimplGen()
method genNim*(c: CsArgumentList): string =
  result = "[GENNIM:CsArgumentList]"

  echo "--> in  genNim*(c: var CsArgumentList)"
  result = ""
  if not c.isNil:
    result = c.args.mapIt(it.genNim()).join(", ")

proc newCs*(t: typedesc[CsArgument]): CsArgument =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsArgument]; info: Info): CsArgument =
  result = newCs(CsArgument)
  let tbl = colonsToTable(info.essentials)
  echo info;
  # result.name = tbl["value"]
  result.value = tbl["value"]

method genCs*(c: CsArgument): string =
  result = "[GENCS:CsArgument]"

  echo "--> in genCs*(c: CsArgument): string ="
  todoimplGen()
method genNim*(c: CsArgument): string =
  result = "[GENNIM:CsArgument]"
  echo "--> in  genNim*(c: CsArgument)"
  if c.expr.isNil:
    result = c.value
  else: result = c.expr.genNim()
  echo result
  echo "<-- end of genNim csArgument"
proc newCs*(t: typedesc[CsArrayCreationExpression]): CsArrayCreationExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsArrayCreationExpression]; info: Info): CsArrayCreationExpression =
  echo info
  result = newCs(CsArrayCreationExpression)

method genCs*(c: CsArrayCreationExpression): string =
  result = "[GENCS:CsArrayCreationExpression]"

  echo "--> in genCs*(c: var CsArrayCreationExpression): string ="
  todoimplGen()
method genNim*(c: CsArrayCreationExpression): string =
  result = "[GENNIM:CsArrayCreationExpression]"

  echo "--> in  genNim*(c: var CsArrayCreationExpression)"

  todoimplGen()
proc newCs*(t: typedesc[CsArrayRankSpecifier]): CsArrayRankSpecifier =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsArrayRankSpecifier]; info: Info): CsArrayRankSpecifier =
  echo info
  result = newCs(CsArrayRankSpecifier)

method genCs*(c: CsArrayRankSpecifier): string =
  result = "[GENCS:CsArrayRankSpecifier]"

  echo "--> in genCs*(c: var CsArrayRankSpecifier): string ="
  todoimplGen()

method genNim*(c: CsArrayRankSpecifier): string =
  result = "[GENNIM:CsArrayRankSpecifier]"
  echo "--> in  genNim*(c: var CsArrayRankSpecifier)"
  # if not c.gotType.isNil: echo c.gotType.genNim()
  # if not c.omitted.isNil: echo c.omitted.genNim()
  if not c.theRankValue.isNil:
    echo c.theRankValue.typ
    result = c.theRankValue.genNim()
  echo "<-- end of genNim*(c: var CsArrayRankSpecifier)"

proc newCs*(t: typedesc[CsArrayType]): CsArrayType =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsArrayType]; info: Info): CsArrayType =
  echo info
  result = newCs(CsArrayType)

method genCs*(c: CsArrayType): string =
  result = "[GENCS:CsArrayType]"

  echo "--> in genCs*(c: var CsArrayType): string ="
  todoimplGen()
method genNim*(c: CsArrayType): string =
  result = "[GENNIM:CsArrayType]"
  echo "--> in  genNim*(c: var CsArrayType)"
  let t = c.gotType.genNim()
  echo t
  let rank = if c.rankSpecifier != nil: c.rankSpecifier.genNim() else: ""
  echo rank
  if rank.len == 0:
    result = "array[" & t & "]"
  else:
    result = "array[" & rank & ", " & t & "]"
  echo result
  echo "<-- end of  genNim*(c: var CsArrayType)"
  # todoimplGen()

proc newCs*(t: typedesc[CsArrowExpressionClause]): CsArrowExpressionClause =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsArrowExpressionClause]; info: Info): CsArrowExpressionClause =
  echo info
  result = newCs(CsArrowExpressionClause)

method genCs*(c: CsArrowExpressionClause): string =
  result = "[GENCS:CsArrowExpressionClause]"
  echo "--> in genCs*(c: var CsArrowExpressionClause): string ="
  todoimplGen()

method genNim*(c: CsArrowExpressionClause): string =
  result = "[GENNIM:CsArrowExpressionClause]"
  echo "--> in  genNim*(c: var CsArrowExpressionClause)"
  echo "for property/accessor, we generate a proc, so it's a ="
  # TODO: solve indent levels.
  result = " = \n" & c.body.mapIt(it.genNim()).mapIt("  " & it).join("\n")
  # todoimplGen()

method genCs*(c: CsAssignmentExpression): string =
  result = "[GENCS:CsAssignmentExpression]"

  echo "--> in genCs*(c: CsAssignmentExpression): string ="
  todoimplGen()
method genNim*(c: CsAssignmentExpression): string =
  result = "[GENNIM:CsAssignmentExpression]"

  echo "--> in  genNim*(c: CsAssignmentExpression)"
  assert c.leftStr.len > 0
  assert not c.right.isNil
  echo c.right.typ
  result = c.leftStr & " = " & c.right.genNim()
  # assert false #TODO(genNim:CsAssignmentExpression)

proc newCs*(t: typedesc[CsAttributeArgumentList];
    name: string): CsAttributeArgumentList =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsAttributeArgumentList];
    info: Info): CsAttributeArgumentList = todoimpl("extract")

method genCs*(c: CsAttributeArgumentList): string =
  result = "[GENCS:CsAttributeArgumentList]"

  echo "--> in genCs*(c: var CsAttributeArgumentList): string ="
  todoimplGen()
method genNim*(c: CsAttributeArgumentList): string =
  result = "[GENNIM:CsAttributeArgumentList]"

  echo "--> in  genNim*(c: var CsAttributeArgumentList)"

  todoimplGen()
proc newCs*(t: typedesc[CsAttributeArgument];
    name: string): CsAttributeArgument =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsAttributeArgument];
    info: Info): CsAttributeArgument = todoimpl("extract")

method genCs*(c: CsAttributeArgument): string =
  result = "[GENCS:CsAttributeArgument]"

  echo "--> in genCs*(c: var CsAttributeArgument): string ="
  todoimplGen()
method genNim*(c: CsAttributeArgument): string =
  result = "[GENNIM:CsAttributeArgument]"

  echo "--> in  genNim*(c: var CsAttributeArgument)"

  todoimplGen()
proc newCs*(t: typedesc[CsAttributeList]; name: string): CsAttributeList =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsAttributeList];
    info: Info): CsAttributeList = todoimpl("extract")

method genCs*(c: CsAttributeList): string =
  result = "[GENCS:CsAttributeList]"

  echo "--> in genCs*(c: var CsAttributeList): string ="
  todoimplGen()
method genNim*(c: CsAttributeList): string =
  result = "[GENNIM:CsAttributeList]"

  echo "--> in  genNim*(c: var CsAttributeList)"

  todoimplGen()
proc newCs*(t: typedesc[CsAttribute]; name: string): CsAttribute =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsAttribute]; info: Info): CsAttribute =
  todoimpl("extract")

method genCs*(c: CsAttribute): string =
  result = "[GENCS:CsAttribute]"

  echo "--> in genCs*(c: var CsAttribute): string ="
  todoimplGen()
method genNim*(c: CsAttribute): string =
  result = "[GENNIM:CsAttribute]"

  echo "--> in  genNim*(c: var CsAttribute)"

  todoimplGen()
proc newCs*(t: typedesc[CsAttributeTargetSpecifier];
    name: string): CsAttributeTargetSpecifier =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsAttributeTargetSpecifier];
    info: Info): CsAttributeTargetSpecifier = todoimpl("extract")

method genCs*(c: CsAttributeTargetSpecifier): string =
  result = "[GENCS:CsAttributeTargetSpecifier]"

  echo "--> in genCs*(c: var CsAttributeTargetSpecifier): string ="
  todoimplGen()
method genNim*(c: CsAttributeTargetSpecifier): string =
  result = "[GENNIM:CsAttributeTargetSpecifier]"

  echo "--> in  genNim*(c: var CsAttributeTargetSpecifier)"

  todoimplGen()
proc newCs*(t: typedesc[CsAwaitExpression]): CsAwaitExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsAwaitExpression]; info: Info): CsAwaitExpression =
  echo info
  result = newCs(CsAwaitExpression)

method genCs*(c: CsAwaitExpression): string =
  result = "[GENCS:CsAwaitExpression]"

  echo "--> in genCs*(c: var CsAwaitExpression): string ="
  todoimplGen()
method genNim*(c: CsAwaitExpression): string =
  result = "[GENNIM:CsAwaitExpression]"

  echo "--> in  genNim*(c: var CsAwaitExpression)"

  todoimplGen()
proc newCs*(t: typedesc[CsBaseExpression]): CsBaseExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsBaseExpression]; info: Info): CsBaseExpression =
  echo info
  result = newCs(CsBaseExpression)

method genCs*(c: CsBaseExpression): string =
  result = "[GENCS:CsBaseExpression]"

  echo "--> in genCs*(c: var CsBaseExpression): string ="
  todoimplGen()
method genNim*(c: CsBaseExpression): string =
  result = "[GENNIM:CsBaseExpression]"

  echo "--> in  genNim*(c: var CsBaseExpression)"

  todoimplGen()
proc newCs*(t: typedesc[CsBaseList]): CsBaseList =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsBaseList]; info: Info): CsBaseList =
  result = newCs(CsBaseList)
  if info.essentials.len > 0:
    result.baseList = info.essentials[0].split(", ").mapIt(it.strip)

method genCs*(c: CsBaseList): string =
  result = "[GENCS:CsBaseList]"

  echo "--> in genCs*(c: var CsBaseList): string ="
  todoimplGen()
method genNim*(c: CsBaseList): string =
  result = "[GENNIM:CsBaseList]"

  echo "--> in  genNim*(c: var CsBaseList)"

  todoimplGen()
method genCs*(c: CsBinaryExpression): string =
  result = "[GENCS:CsBinaryExpression]"

  echo "--> in genCs*(c: CsBinaryExpression): string ="
  result = c.left.genCs() & " " & c.op & " " & c.right.genCs()

method genNim*(c: CsBinaryExpression): string =
  echo "--> in genNim*(c: CsBinaryExpression): string ="
  result = "[GENNIM:CsBinaryExpression]"
  assert c.op != ""
  echo "op is " & c.op
  if c.gotType != nil:
    echo "got a type: (for right side?)" & c.gotType.typ & "--" & c.gotType.name
  let genLeft =
    if c.left != nil:
      echo c.left.typ
      c.left.genNim()
    else:
      c.leftStr
  let genRight =
    if c.right != nil:
      echo c.right.typ
      c.right.genNim()
    else:
      c.rightStr
  result = genLeft & " " & c.op & " " & genRight
  echo "<-- end of genNim*(c: CsBinaryExpression): string ="

proc newCs*(t: typedesc[CsBinaryExpression]): CsBinaryExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsBinaryExpression]; info: Info): CsBinaryExpression =
  result = newCs(t)
  let tbl = colonsToTable(info.essentials)
  result.leftStr = tbl["left"]
  result.op = tbl["op"]
  result.rightStr = tbl["right"]


proc newCs*(t: typedesc[CsBracketedArgumentList]): CsBracketedArgumentList =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsBracketedArgumentList]; info: Info): CsBracketedArgumentList =
  echo info
  result = newCs(CsBracketedArgumentList)

method genCs*(c: CsBracketedArgumentList): string =
  result = "[GENCS:CsBracketedArgumentList]"

  echo "--> in genCs*(c: var CsBracketedArgumentList): string ="
  todoimplGen()
method genNim*(c: CsBracketedArgumentList): string =
  result = "[GENNIM:CsBracketedArgumentList]"
  echo "--> in  genNim*(c: var CsBracketedArgumentList)"
  var tmp : seq[string]
  for a in c.args:
    echo a.typ
    tmp &= a.genNim()
    echo tmp
  result = tmp.join(", ")
  echo "<-- end of  genNim*(c: var CsBracketedArgumentList)"

  # todoimplGen()
proc newCs*(t: typedesc[CsBracketedParameterList]): CsBracketedParameterList =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsBracketedParameterList];
    info: Info): CsBracketedParameterList =
  result = newCs(CsBracketedParameterList) # for indexer, and what else?
  result.plist = info.essentials[0]
  # I suspect parameters will come next. most likely unneeded, i can easily parse that text.

method genCs*(c: CsBracketedParameterList): string =
  result = "[GENCS:CsBracketedParameterList]"

  echo "--> in genCs*(c: var CsBracketedParameterList): string ="
  todoimplGen()
method genNim*(c: CsBracketedParameterList): string =
  result = "[GENNIM:CsBracketedParameterList]"

  echo "--> in  genNim*(c: var CsBracketedParameterList)"

  todoimplGen()
proc newCs*(t: typedesc[CsBreakStatement]): CsBreakStatement =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsBreakStatement]; info: Info): CsBreakStatement =
  echo info
  result = newCs(CsBreakStatement)

method genCs*(c: CsBreakStatement): string =
  result = "[GENCS:CsBreakStatement]"

  echo "--> in genCs*(c: var CsBreakStatement): string ="
  todoimplGen()
method genNim*(c: CsBreakStatement): string =
  result = "[GENNIM:CsBreakStatement]"
  echo "--> in  genNim*(c: var CsBreakStatement)"
  result = "break\n"
  # todoimplGen()
proc newCs*(t: typedesc[CsCasePatternSwitchLabel]): CsCasePatternSwitchLabel =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsCasePatternSwitchLabel]; info: Info): CsCasePatternSwitchLabel =
  echo info
  result = newCs(CsCasePatternSwitchLabel)

method genCs*(c: CsCasePatternSwitchLabel): string =
  result = "[GENCS:CsCasePatternSwitchLabel]"

  echo "--> in genCs*(c: var CsCasePatternSwitchLabel): string ="
  todoimplGen()
method genNim*(c: CsCasePatternSwitchLabel): string =
  result = "[GENNIM:CsCasePatternSwitchLabel]"

  echo "--> in  genNim*(c: var CsCasePatternSwitchLabel)"

  todoimplGen()
proc newCs*(t: typedesc[CsCaseSwitchLabel]): CsCaseSwitchLabel =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsCaseSwitchLabel]; info: Info): CsCaseSwitchLabel =
  echo info
  result = newCs(CsCaseSwitchLabel)

method genCs*(c: CsCaseSwitchLabel): string =
  result = "[GENCS:CsCaseSwitchLabel]"

  echo "--> in genCs*(c: var CsCaseSwitchLabel): string ="
  todoimplGen()
method genNim*(c: CsCaseSwitchLabel): string =
  result = "[GENNIM:CsCaseSwitchLabel]"

  echo "--> in  genNim*(c: var CsCaseSwitchLabel)"

  todoimplGen()
proc newCs*(t: typedesc[CsCastExpression]): CsCastExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsCastExpression]; info: Info): CsCastExpression =
  echo info
  result = newCs(CsCastExpression)
  let tbl = colonsToTable(info.essentials)
  result.theType = tbl["type"]
  result.theExpr = tbl["expr"]

method genCs*(c: CsCastExpression): string =
  result = "[GENCS:CsCastExpression]"
  echo "--> in genCs*(c: var CsCastExpression): string ="

  todoimplGen()
method genNim*(c: CsCastExpression): string =
  result = "[GENNIM:CsCastExpression]"
  echo "--> in  genNim*(c: var CsCastExpression)"
  var genType : string
  if not c.gotType.isNil:
    genType = c.gotType.genNim()
  else:
    genType = c.theType
  echo "the type is: " & genType
  let expression = if c.expr.isNil: c.theExpr else:  c.expr.genNim()
  echo "the expr is " & expression
  result = genType & "(" & expression & ")"
  echo result
  # todoimplGen()
proc newCs*(t: typedesc[CsCatchClause]): CsCatchClause =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsCatchClause]; info: Info): CsCatchClause =
  echo info
  result = newCs(CsCatchClause)

method genCs*(c: CsCatchClause): string =
  result = "[GENCS:CsCatchClause]"

  echo "--> in genCs*(c: var CsCatchClause): string ="
  todoimplGen()
method genNim*(c: CsCatchClause): string =
  result = "[GENNIM:CsCatchClause]"
  echo "--> in genNim*(c: var CsCatchClause)"
  echo "has filter:" & $(not c.filter.isNil)
  if c.what.isNil:
    result = "except:"
  else:
    result = "except" & c.what.genNim() & ":"
  result.nl
  startBlock()
  let body = c.body.genBody()
  result &= body
  endBlock()
  echo "<-- end of genNim*(c: CsCatchClause)"

proc newCs*(t: typedesc[CsCatchFilterClause]): CsCatchFilterClause =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsCatchFilterClause]; info: Info): CsCatchFilterClause =
  echo info
  result = newCs(CsCatchFilterClause)

method genCs*(c: CsCatchFilterClause): string =
  result = "[GENCS:CsCatchFilterClause]"

  echo "--> in genCs*(c: var CsCatchFilterClause): string ="
  todoimplGen()
method genNim*(c: CsCatchFilterClause): string =
  result = "[GENNIM:CsCatchFilterClause]"

  echo "--> in  genNim*(c: var CsCatchFilterClause)"

  todoimplGen()
proc newCs*(t: typedesc[CsCatch]): CsCatch =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsCatch]; info: Info): CsCatch =
  echo info
  result = newCs(CsCatch)

method genCs*(c: CsCatch): string =
  result = "[GENCS:CsCatch]"

  echo "--> in genCs*(c: var CsCatch): string ="
  todoimplGen()
method genNim*(c: CsCatch): string =
  result = "[GENNIM:CsCatch]"
  echo "--> in  genNim*(c: var CsCatch)"
  if c.gotType != nil:
    echo c.gotType.typ
    result = c.gotType.genNim()
  else: result = ""
  echo "<-- end of genNim*(c: var CsCatch)"
proc newCs*(t: typedesc[CsCheckedExpression]): CsCheckedExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsCheckedExpression]; info: Info): CsCheckedExpression =
  echo info
  result = newCs(CsCheckedExpression)

method genCs*(c: CsCheckedExpression): string =
  result = "[GENCS:CsCheckedExpression]"

  echo "--> in genCs*(c: var CsCheckedExpression): string ="
  todoimplGen()
method genNim*(c: CsCheckedExpression): string =
  result = "[GENNIM:CsCheckedExpression]"

  echo "--> in  genNim*(c: var CsCheckedExpression)"

  todoimplGen()
proc newCs*(t: typedesc[CsCheckedStatement]): CsCheckedStatement =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsCheckedStatement]; info: Info): CsCheckedStatement =
  echo info
  result = newCs(CsCheckedStatement)

method genCs*(c: CsCheckedStatement): string =
  result = "[GENCS:CsCheckedStatement]"

  echo "--> in genCs*(c: var CsCheckedStatement): string ="
  todoimplGen()

proc indent() : string =
  " ".repeat(indentation)

method genNim*(c: CsCheckedStatement): string =
  result = "[GENNIM:CsCheckedStatement]"
  echo "--> in  genNim*(c: var CsCheckedStatement)"
  echo "overflow checking explicit disable/enable"
  if c.checked.isSome:
    result = "block "
    let res = if c.checked.get == true: "checked" else: "unchecked"
    result &= res
    result &= ": " & "# overflow checking explicit disable/enable"
    for b in c.body:
      result &= indent() & b.genNim()
  # todoimplGen()

method add*(parent: CsProperty, item: CsAccessorList) =
  parent.acclist = item

method add*(parent: CsMethod, item: CsAssignmentExpression) =
  parent.body.add item

method add*(parent: CsMethod, item: CsIfStatement) =
  parent.body.add item

method add*(parent: CsMethod, item: CsGenericName) =
  parent.genericName = item

method add*(parent: CsMethod, item: CsInvocationExpression) =
  parent.body.add item

method add*(parent: CsMethod, item: CsVariableDeclarator) =
  parent.body.add item

method add*(parent: CsEqualsValueClause, item: CsBinaryExpression) =
  echo "in method add*(parent: CsEqualsValueClause, item: CsBinaryExpression)"
  parent.rhsValue = item

method add*(parent: CsEqualsValueClause, item: CsMemberAccessExpression) =
  echo "in ", "method add*(parent: CsEqualsValueClause, item: CsMemberAccessExpression)"
  parent.rhsValue = item
  # if parent.rhsValue.isNil:
  #   parent.rhsValue = item
method add*(parent: CsEqualsValueClause, item: CsObjectCreationExpression) =
  echo "in ", "method add*(parent: CsEqualsValueClause, item: CsObjectCreationExpression)="
  parent.rhsValue = item
  # if parent.rhsValue.isNil:
  #   parent.rhsValue = item
method add*(parent: CsEqualsValueClause, item: CsLiteralExpression) =
  echo "in ", "method add*(parent: CsEqualsValueClause, item: CsLiteralExpression)"
  parent.rhsValue = item
  # if parent.rhsValue.isNil:
  #   parent.rhsValue = item

method add*(parent: CsInvocationExpression, item: CsArgumentList) =
  parent.args = item

method add*(parent: CsInvocationExpression, item: CsMemberAccessExpression) =
  echo "in add*(parent:var CsInvocationExpression, item: CsMemberAccessExpression)"
  parent.invoker = item

method add*(c: var CsIndexer, item: CsAccessorList) =
  c.aclist = item

proc newCs*(t: typedesc[CsClass]; name: string; base = ""; impls: seq[
    string] = @[]): CsClass =
  new result
  result.typ = $typeof(t)

  result.name = name
  result.extends = base
  result.implements = impls

proc newCs*(t: typedesc[CsParameter]; a, b: string): CsParameter =
  new result
  result.typ = $typeof(t)
  #
  result.name = a
  result.ptype = b

method addSelfParam(m: var CsMethod) =
  let p = newCs(CsParameter, "this", m.parentClass)
  m.parameterList.parameters.insert(@[p], 0)

method addSelfTypedesc(m:var CsMethod)=
  let p = newCs(CsParameter, "_", "typedesc[" & m.parentClass & "]")
  m.parameterList.parameters.insert(@[p], 0)

method genNim*(p: CsParameter): string =
  result = "[GENNIM:CsParameter]"

  echo "--> in  genNim*(p: CsParameter)"
  result = p.name & ": "
  if p.isRef:
    result &= "var "
  if p.isOut:
    result &= "out "
  if p.genericType.isNil and p.gotType.isNil:
    result &= p.ptype.replacementGenericTypes()
  else:
    if not p.genericType.isNil:
      result &= p.genericType.genNim()
    elif not p.gotType.isNil:
      result &= p.gotType.genNim()
  if not p.initValueExpr.isNil:
    result &= " = " & p.initValueExpr.genNim()
  echo "<-- end of  genNim*(p: CsParameter)"


method genCs*(p: CsParameter): string =
  result = "[GENCS:CsParameter]"
  result = ""
  if p.isRef:
    result &= "ref "
  elif p.isOut:
    result &= "out "
  result &= p.ptype.strip & " "
  result &= p.name

method genNim*(p: CsParameterList): string =
  result = "[GENNIM:CsParameterList]"
  echo "--> in  genNim*(p: CsParameterList)"
  var temp : seq[string]
  for pm in p.parameters:
    echo pm.typ
    let gen = pm.genNim()
    echo gen
    temp.add gen
  # result = p.parameters.mapIt(it.genNim()).join("; ")
  result = temp.mapIt(it.strip).join("; ")

method genCs*(p: CsParameterList): string =
  result = "[GENCS:CsParameterList]"

  result = p.parameters.mapIt(it.genCs()).join(", ")

import ../common_utils

let preferFullProc = false

method genCs*(m: CsMethod): string =
  result = "[GENCS:CsMethod]"

  let plist = if not m.parameterList.isnil: m.parameterList.genCs() else: ""
  result = fmt"{m.returnType} {m.name}({plist})"
  result &= "{\r\n"
  for ln in m.body:
    result &= ln.genCs()
    result &= "\r\n"
  result &= "}"

method genNim*(b: CsMethod): string =
  var m = b
  result = "[GENNIM:CsMethod]"
  result = ""
  echo "--> in  genNim*(m: var CsMethod)"
  echo "generating method (wip): " & m.name
  if not m.isStatic: result = "method " else: result = "proc "
  if not m.isStatic:
    m.addSelfParam()
  else: # a static c# method.
    if preferFullProc:
      m.addSelfTypedesc()

  let pubstr = if m.isPublic: "*" else: ""
  let tplist = if m.tpl.isNil: "" else: m.tpl.genNim()
  let parameterList = m.parameterList.genNim()
  let returnType = if m.returnType != "void": m.returnType.replacementGenericTypes() else: ""
  let body =
    if m.body.len == 0: "discard"
    else:
      var lines: seq[string]
      for ln in m.body: # a sequence of bodyExpr -- only known at runtime.
        echo ln.typ, " ", ln.ttype
        let generatedString = ln.genNim()
        echo "generated string for the method bodyexpr was: " & generatedString
        lines.add generatedString
      lines.join("\r\n  ")

  result &= m.name.lowerFirst & tplist & pubStr & "(" & parameterList.replacementGenericTypes() & ")"
  if returnType != "": result &= ": " & returnType.replacementGenericTypes()
  result &= " ="
  result &= "\r\n  "

  result &= body
  result &= "\r\n"

  echo "<-- end of genNim*(m: var CsMethod)"

method genCs*(c: CsConstructor): string =
  result = "[GENCS:CsConstructor]"
  result = ""
  echo "--> in genCs*(c: var CsConstructor): string ="
  result &= c.modifiers.join(" ") & " "  & c.name & "(" & c.parameterList.genCs() & ")"
  if c.body.len == 0:
    result &= ";"
  else:
    result &= "{"
    for it in c.body:
      result &= it.genCs()
      result &= "\r\n"
    result &= "}"

method genNim*(c: CsConstructor): string =
  result = "[GENNIM:CsConstructor]"

  echo "--> in  genNim*(c: var CsConstructor)"
  echo "generating ctor (wip): (new)" & c.name
  result = "proc "
  let parameterList = c.parameterList.genNim()
  let returnType = c.parentClass
  let body =
    if c.body.len == 0: "new result"
    else: c.body.mapIt(it.genNim()).join("\r\n  ")

  result &= "new" & c.name & "(" & parameterList & ")"
  if returnType != "": result &= ": " & returnType
  result &= " ="
  result &= "\r\n  "

  result &= body

# type AccessorType = enum atIndexer, atMethod

method genCs*(c: CsIndexer): string =
  result = "[GENCS:CsIndexer]"
 #TODO: handle when indexer has some body, less strings, more objects stored. (lookup in csdisplay to see fields) =
  echo "--> in genCs*(c: var CsIndexer): string"
  result = c.retType & " " & c.explSpecifier & "this" & c.pmlist & " " & c.acclist
  echo result
# varName
# varType
# firstVarType
# paramlist
# aclist
# exprBody
# pmlist
# acclist
# mods
# hasDefaultGet
# hasDefaultSet
# hasBody
method genNim*(c: CsIndexer): string =
  result = "[GENNIM:CsIndexer]"
  result = ""
 #TODO: handle when indexer has some body, less strings, more objects stored. (lookup in csdisplay to see fields)
  echo "--> in  genNim*(c: var CsIndexer)"
  echo "generating indexer"
  let x = c.firstVarType.rsplit(".", 1)[^1]
  var setPart, getPart: string

  let sq = c.pmlist[1..^2].split(" ")
  echo "pmlist:" & sq[1] & sq[0]
  let part = "(this: var " & x & "; " & sq[1] & ": " & sq[0]
  if c.hasDefaultGet:
    getPart = "proc `[]`*" & part & "): " & c.retType & " = discard"
  if c.hasDefaultSet:
    setPart = "proc `[]=`*" & part & "; value: object" & ") = discard"
  result &= getPart & "\n" & setPart

method genCs*(c: CsProperty): string =
  result = "[GENCS:CsProperty]"

  echo "--> in genCs*(c: CsProperty): string ="
  todoimplGen()
method genNim*(c: CsProperty): string =
  result = "[GENNIM:CsProperty]"

  echo "--> in  genNim*(c: CsProperty)"
  result = ""
  if c.hasGet:
    result &= # this is a getter
      "method " & c.name.lowerFirst() &
      "*(this: " & c.parentClass & "): " & c.retType & " = " &
      "this.u_" & c.name
  if c.hasSet:
    result &=
      "method " & c.name.lowerFirst &
      "*(this: " & c.parentClass & ", value: " & c.retType & "): " & c.retType &
          " = " &
      "this.u_" & c.name & " = value"

# import ../type_utils

proc hasIndexer*(c: CsClass): bool =
  result = not c.indexer.isNil

import ../common_utils
proc getLastClass*(ns: CsNamespace): Option[CsClass] =
  # echo ns
  if ns.classes.len == 0:
    result = none(CsClass)
  else:
    result = some(ns.classes.last)

proc getLastMethod*(cls: CsClass): Option[CsMethod] =
  if cls.methods.len == 0: return
  else:
    return some(cls.methods.last)

proc getLastCtor*(cls: CsClass): Option[CsConstructor] =
  if cls.ctors.len == 0: return
  else:
    return some(cls.ctors.last)

import tables, options, strformat

proc genFields(ls:seq[CsField]):string =
  if ls.len > 0:
    result &= "\r\n"
    for f in ls:
      result &= "  " & f.genNim() & "\r\n"

method genCs*(c: CsClass): string =
  result = "[GENCS:CsClass]"
  result = ""
  echo "--> in genCs*(c: CsClass): string ="
  result &= c.mods.toSeq.reversed.join(" ") & " "
  result &= "class " & c.name
  if not c.extends.isEmptyOrWhitespace or c.implements.len > 0:
    result &= " : "
  var hadExtend:bool
  if not c.extends.isEmptyOrWhitespace:
    result &= c.extends
    hadExtend = true
  if c.implements.len > 0:
    if hadExtend: result &= ", "
    result &= c.implements.join(", ")
  result &= "{"
  for m in c.methods:
    result &= m.genCs()
    result &= "\r\n"

  for it in c.fields:
    result &= it.genCs()
    result &= "\r\n"
  for it in c.ctors:
    result &= it.genCs()
    result &= "\r\n"
  for it in c.properties:
    result &= it.genCs()
    result &= "\r\n"
  if c.hasIndexer:
    result &= c.indexer.genCs()
    result &= "\r\n"
  result &= "}"

method genNim*(c: CsClass): string =
  result = "[GENNIM:CsClass]"
  result = ""
  echo "--> in  genNim*(c: CsClass)"
  echo "generating class:" & c.name

  if c.isNil:
    result = ""
    return
  else:
    # start with type name
    result &= "type " & c.name
    # add generic params
    # var tmp:seq[string]
    if not c.genericTypeList.isNil:
      result &= c.genericTypeList.genNim()
    # add public marker if available
    if "public" in c.mods: result &= "*"
    # finish type declaration
    result &= " = ref object"

  if c.extends != "": result &= " of " & c.extends
  result &= genFields(c.fields)
  result &= "\r\n\r\n"

  echo "methods count: " & $c.methods.len
  echo "generating methods:"

  for m in c.methods.mitems:
    result &= m.genNim()
    result &= "\r\n"
  echo "ctors count: " & $c.ctors.len
  for ctor in c.ctors.mitems:
    result &= ctor.genNim()
    result &= "\r\n"
  echo "has Indexer: " & $c.hasIndexer
  if c.hasIndexer:
    result &= c.indexer.genNim()
  echo "has properties: " & $c.properties.len
  for p in c.properties:
    result &= p.genNim() & "\r\n"
  echo "<-- end of genNim*(c: CsClass)"

method add*(parent: CsClass; m: CsConstructor) =
  echo "adding ctor to class"

  parent.ctors.add m
  parent.lastAddedTo = some(Ctors)
  m.parentClass = parent.name

method add*(parent: CsClass; m: CsMethod) =
  echo "adding method to class"
  parent.methods.add m
  parent.lastAddedTo = some(Methods)
  m.parentClass = parent.name

proc addField(parent: CsClass; name, typ: string) =
  var f = newCs(CsField)
  f.name = name
  f.isStatic = false
  f.isPublic = false
  f.thetype = typ
  parent.fields.add f

proc addFieldForProperty(parent: CsClass, item: CsProperty) =
  var fieldName = "u_" & item.name
  var fieldType = item.retType
  if fieldType == "":
    fieldType = hackFindType(item)

  parent.addField(fieldName, fieldType)


method add*(parent: CsNamespace; item: CsEnum) =
  # echo parent.name
  assert not parent.isnil
  parent.enums.add item
  item.ns = parent
  parent.enumTable[item.name] = item
  parent.lastAddedTo = some(NamespaceParts.Enums)

method add*(parent: CsClass; item: CsEnum) =#Forwards to NS without changing the enum's name
  if parent.ns.isNil:
    parent.ns = currentRoot.global
  parent.ns.add item

method add*(parent: CsClass; item: CsTypeParameterList) =
  echo "in method add*(parent: CsClass; item: CsTypeParameterList)"
  # echo parent.name
  parent.genericTypeList = item

method add*(ns: CsNamespace; class: CsClass) =
  assert not ns.isnil
  echo ns.name
  ns.classes.add(class)
  assert not ns.classTable.isNil
  ns.classTable[class.name] = class
  ns.lastAddedTo = some(NamespaceParts.Classes)
  class.ns = ns

template forward(parent,item:untyped) =
  item.name = parent.name & "." & item.name
  if parent.ns.isnil:
    parent.ns = currentRoot.global
  assert not parent.ns.isnil
  parent.ns.add item

method add*(parent: CsClass; item: CsClass) = #Forwards to NS but changes the class's name
  echo "in method add*(parent: CsClass; item: CsClass)"
  # the item class doesn't have an ns parent. we should give it the default one.
  item.name = parent.name & "." & item.name
  if parent.ns.isnil:
    parent.ns = currentRoot.global
  assert not parent.ns.isnil
  parent.ns.add item #, " get the parent of class, i.e. namespace and add there."

method add*(parent: CsClass; item: CsField) =
  parent.fields.add item
method add*(parent: CsClass; item: CsProperty) =
  parent.properties.add item
  parent.lastAddedTo = some(Properties)
  item.parentClass = parent.name
  if (item.hasGet or item.hasSet) and
    item.bodyGet.len == 0 and item.bodySet.len == 0:
    parent.addFieldForProperty(item)

method add*(parent: CsClass; item: CsIndexer) =
  parent.indexer = item
  parent.lastAddedTo = some(Indexer)
  # item.parentName = parent.name

method add*(parent: CsClass; item: CsBaseList) =
  if item.baseList.len > 0:
    parent.extends = item.baseList[0]
  if item.baseList.len > 1:
    parent.implements = item.baselist[1..^1]

proc newCs*(t: typedesc[CsClassOrStructConstraint]): CsClassOrStructConstraint =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsClassOrStructConstraint]; info: Info): CsClassOrStructConstraint =
  echo info
  result = newCs(CsClassOrStructConstraint)

method genCs*(c: CsClassOrStructConstraint): string =
  result = "[GENCS:CsClassOrStructConstraint]"

  echo "--> in genCs*(c: var CsClassOrStructConstraint): string ="
  todoimplGen()
method genNim*(c: CsClassOrStructConstraint): string =
  result = "[GENNIM:CsClassOrStructConstraint]"

  echo "--> in  genNim*(c: var CsClassOrStructConstraint)"

  todoimplGen()
proc newCs*(t: typedesc[CsConditionalAccessExpression]): CsConditionalAccessExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsConditionalAccessExpression]; info: Info): CsConditionalAccessExpression =
  echo info
  result = newCs(CsConditionalAccessExpression)

method genCs*(c: CsConditionalAccessExpression): string =
  result = "[GENCS:CsConditionalAccessExpression]"

  echo "--> in genCs*(c: var CsConditionalAccessExpression): string ="
  todoimplGen()
method genNim*(c: CsConditionalAccessExpression): string =
  result = "[GENNIM:CsConditionalAccessExpression]"

  echo "--> in  genNim*(c: var CsConditionalAccessExpression)"

  todoimplGen()
proc newCs*(t: typedesc[CsConditionalExpression]): CsConditionalExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsConditionalExpression]; info: Info): CsConditionalExpression =
  echo info
  result = newCs(CsConditionalExpression)
  let tbl = colonsToTable(info.essentials)
  result.condTxt = tbl.getOrDefault("condition")
  result.trueTxt = tbl.getOrDefault("whentrue")
  result.falseTxt = tbl.getOrDefault("whenfalse")

method genCs*(c: CsConditionalExpression): string =
  result = "[GENCS:CsConditionalExpression]"

  echo "--> in genCs*(c: var CsConditionalExpression): string ="
  todoimplGen()
method genNim*(c: CsConditionalExpression): string =
  result = "[GENNIM:CsConditionalExpression]"
  echo "--> in  genNim*(c: var CsConditionalExpression)"
  result = "if "
  result &= genPred(c)
  result &= ":\n"
  startBlock()
  assert c.bodyTrue.notNil, result
  echo c.bodyTrue.typ
  result &= c.bodyTrue.genNim()
  endBlock()
  if not c.bodyFalse.isNil:
    result &= "else:\n"
    startBlock()
    result &= c.bodyFalse.genNim()
    endBlock()
  echo "<-- end of genNim*(c: var CsConditionalExpression)"
proc newCs*(t: typedesc[CsConstantPattern]): CsConstantPattern =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsConstantPattern]; info: Info): CsConstantPattern =
  echo info
  result = newCs(CsConstantPattern)

method genCs*(c: CsConstantPattern): string =
  result = "[GENCS:CsConstantPattern]"

  echo "--> in genCs*(c: var CsConstantPattern): string ="
  todoimplGen()
method genNim*(c: CsConstantPattern): string =
  result = "[GENNIM:CsConstantPattern]"

  echo "--> in  genNim*(c: var CsConstantPattern)"

  todoimplGen()
proc newCs*(t: typedesc[CsConstructorConstraint]): CsConstructorConstraint =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsConstructorConstraint]; info: Info): CsConstructorConstraint =
  echo info
  result = newCs(CsConstructorConstraint)

method genCs*(c: CsConstructorConstraint): string =
  result = "[GENCS:CsConstructorConstraint]"

  echo "--> in genCs*(c: var CsConstructorConstraint): string ="
  todoimplGen()
method genNim*(c: CsConstructorConstraint): string =
  result = "[GENNIM:CsConstructorConstraint]"

  echo "--> in  genNim*(c: var CsConstructorConstraint)"

  todoimplGen()
proc newCs*(t: typedesc[CsConstructorInitializer]): CsConstructorInitializer =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsConstructorInitializer]; info: Info): CsConstructorInitializer =
  echo info
  result = newCs(CsConstructorInitializer)

method genCs*(c: CsConstructorInitializer): string =
  result = "[GENCS:CsConstructorInitializer]"

  echo "--> in genCs*(c: var CsConstructorInitializer): string ="
  todoimplGen()
method genNim*(c: CsConstructorInitializer): string =
  result = "[GENNIM:CsConstructorInitializer]"

  echo "--> in  genNim*(c: var CsConstructorInitializer)"

  todoimplGen()
proc newCs*(t: typedesc[CsConstructor]): CsConstructor =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsConstructor]; info: Info): CsConstructor =
  let tbl = colonsToTable(info.essentials)
  let name = tbl["name"]
  let mods = tbl["modifiers"]
  result = newCs(CsConstructor)
  result.name = name
  result.modifiers = mods.split(",").mapIt(it.strip)

method add*(parent: CsConstructor; item: CsLocalDeclarationStatement) =
  parent.body.add item

method add*(parent: CsConstructor; item: CsArgumentList) =
  assert (parent.initializer != nil)
  assert parent.initializerArgList.isNil
  parent.initializerArgList = item

method add*(parent: CsConstructor; item: CsParameterList) =
  parent.parameterList = item

proc newCs*(t: typedesc[CsContinueStatement]): CsContinueStatement =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsContinueStatement]; info: Info): CsContinueStatement =
  echo info
  result = newCs(CsContinueStatement)

method genCs*(c: CsContinueStatement): string =
  result = "[GENCS:CsContinueStatement]"

  echo "--> in genCs*(c: var CsContinueStatement): string ="
  todoimplGen()
method genNim*(c: CsContinueStatement): string =
  result = "[GENNIM:CsContinueStatement]"
  echo "--> in  genNim*(c: var CsContinueStatement)"
  result = "continue\n"

proc newCs*(t: typedesc[CsConversionOperator]): CsConversionOperator =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsConversionOperator]; info: Info): CsConversionOperator =
  echo info
  result = newCs(CsConversionOperator)

method genCs*(c: CsConversionOperator): string =
  result = "[GENCS:CsConversionOperator]"

  echo "--> in genCs*(c: var CsConversionOperator): string ="
  todoimplGen()
method genNim*(c: CsConversionOperator): string =
  result = "[GENNIM:CsConversionOperator]"

  echo "--> in  genNim*(c: var CsConversionOperator)"

  todoimplGen()
proc newCs*(t: typedesc[CsDeclarationExpression]): CsDeclarationExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsDeclarationExpression]; info: Info): CsDeclarationExpression =
  echo info
  result = newCs(CsDeclarationExpression)

method genCs*(c: CsDeclarationExpression): string =
  result = "[GENCS:CsDeclarationExpression]"

  echo "--> in genCs*(c: var CsDeclarationExpression): string ="
  todoimplGen()
method genNim*(c: CsDeclarationExpression): string =
  result = "[GENNIM:CsDeclarationExpression]"

  echo "--> in  genNim*(c: var CsDeclarationExpression)"

  todoimplGen()
proc newCs*(t: typedesc[CsDeclarationPattern]): CsDeclarationPattern =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsDeclarationPattern]; info: Info): CsDeclarationPattern =
  echo info
  result = newCs(CsDeclarationPattern)

method genCs*(c: CsDeclarationPattern): string =
  result = "[GENCS:CsDeclarationPattern]"

  echo "--> in genCs*(c: var CsDeclarationPattern): string ="
  todoimplGen()
method genNim*(c: CsDeclarationPattern): string =
  result = "[GENNIM:CsDeclarationPattern]"

  echo "--> in  genNim*(c: var CsDeclarationPattern)"

  todoimplGen()
proc newCs*(t: typedesc[CsDefaultExpression]): CsDefaultExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsDefaultExpression]; info: Info): CsDefaultExpression =
  echo info
  result = newCs(CsDefaultExpression)

method genCs*(c: CsDefaultExpression): string =
  result = "[GENCS:CsDefaultExpression]"

  echo "--> in genCs*(c: var CsDefaultExpression): string ="
  todoimplGen()
method genNim*(c: CsDefaultExpression): string =
  result = "[GENNIM:CsDefaultExpression]"

  echo "--> in  genNim*(c: var CsDefaultExpression)"

  todoimplGen()
proc newCs*(t: typedesc[CsDefaultSwitchLabel]): CsDefaultSwitchLabel =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsDefaultSwitchLabel]; info: Info): CsDefaultSwitchLabel =
  echo info
  result = newCs(CsDefaultSwitchLabel)

method genCs*(c: CsDefaultSwitchLabel): string =
  result = "[GENCS:CsDefaultSwitchLabel]"

  echo "--> in genCs*(c: var CsDefaultSwitchLabel): string ="
  todoimplGen()
method genNim*(c: CsDefaultSwitchLabel): string =
  result = "[GENNIM:CsDefaultSwitchLabel]"

  echo "--> in  genNim*(c: var CsDefaultSwitchLabel)"

  todoimplGen()
proc newCs*(t: typedesc[CsDelegate]): CsDelegate =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsDelegate]; info: Info): CsDelegate =
  result = newCs(CsDelegate)
  echo info

  # todo. get name, but probably following constructs fill it well.

method genCs*(c: CsDelegate): string =
  result = "[GENCS:CsDelegate]"

  echo "--> in genCs*(c: var CsDelegate): string ="
  todoimplGen()
method genNim*(c: CsDelegate): string =
  result = "[GENNIM:CsDelegate]"

  echo "--> in  genNim*(c: var CsDelegate)"

  todoimplGen()
proc newCs*(t: typedesc[CsDestructor]): CsDestructor =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsDestructor]; info: Info): CsDestructor =
  echo info
  result = newCs(CsDestructor)

method genCs*(c: CsDestructor): string =
  result = "[GENCS:CsDestructor]"

  echo "--> in genCs*(c: var CsDestructor): string ="
  todoimplGen()
method genNim*(c: CsDestructor): string =
  result = "[GENNIM:CsDestructor]"

  echo "--> in  genNim*(c: var CsDestructor)"

  todoimplGen()
proc newCs*(t: typedesc[CsDiscardDesignation]): CsDiscardDesignation =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsDiscardDesignation]; info: Info): CsDiscardDesignation =
  echo info
  result = newCs(CsDiscardDesignation)

method genCs*(c: CsDiscardDesignation): string =
  result = "[GENCS:CsDiscardDesignation]"

  echo "--> in genCs*(c: var CsDiscardDesignation): string ="
  todoimplGen()
method genNim*(c: CsDiscardDesignation): string =
  result = "[GENNIM:CsDiscardDesignation]"

  echo "--> in  genNim*(c: var CsDiscardDesignation)"

  todoimplGen()
proc newCs*(t: typedesc[CsDoStatement]): CsDoStatement =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsDoStatement]; info: Info): CsDoStatement =
  echo info
  result = newCs(CsDoStatement)

method genCs*(c: CsDoStatement): string =
  result = "[GENCS:CsDoStatement]"

  echo "--> in genCs*(c: var CsDoStatement): string ="
  todoimplGen()
method genNim*(c: CsDoStatement): string =
  result = "[GENNIM:CsDoStatement]"

  echo "--> in  genNim*(c: var CsDoStatement)"

  todoimplGen()
proc newCs*(t: typedesc[CsElementAccessExpression]): CsElementAccessExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsElementAccessExpression]; info: Info): CsElementAccessExpression =
  echo info
  result = newCs(CsElementAccessExpression)
  # we add to it later.

method genCs*(c: CsElementAccessExpression): string =
  result = "[GENCS:CsElementAccessExpression]"
  echo "--> in genCs*(c: var CsElementAccessExpression): string ="
  todoimplGen()

method genNim*(c: CsElementAccessExpression): string =
  result = "[GENNIM:CsElementAccessExpression]"
  echo "--> in  genNim*(c: var CsElementAccessExpression)"
  var left: string
  if c.lhs.isNil:
    if not c.gotType.isNil:
      echo c.gotType.typ
      left = c.gotType.genNim()
  else: left = c.lhs.genNim()
  assert not c.value.isNil
  let bracketVal = c.value.genNim()
  result = left & "[" & bracketVal & "]"
  echo "<-- end of genNim*(c: var CsElementAccessExpression)"

proc newCs*(t: typedesc[CsElementBindingExpression]): CsElementBindingExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsElementBindingExpression]; info: Info): CsElementBindingExpression =
  echo info
  result = newCs(CsElementBindingExpression)

method genCs*(c: CsElementBindingExpression): string =
  result = "[GENCS:CsElementBindingExpression]"

  echo "--> in genCs*(c: var CsElementBindingExpression): string ="
  todoimplGen()
method genNim*(c: CsElementBindingExpression): string =
  result = "[GENNIM:CsElementBindingExpression]"

  echo "--> in  genNim*(c: var CsElementBindingExpression)"

  todoimplGen()
proc newCs*(t: typedesc[CsElseClause]): CsElseClause =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsElseClause]; info: Info): CsElseClause =
  echo info
  result = newCs(CsElseClause)

method genCs*(c: CsElseClause): string =
  result = "[GENCS:CsElseClause]"
  echo "--> in genCs*(c: var CsElseClause): string ="
  todoimplGen()



method genNim*(c: CsElseClause): string =
  result = "[GENNIM:CsElseClause]"
  echo "--> in genNim*(c: var CsElseClause)"
  result = c.body.genBody()
  echo "<-- end of genNim*(c: var CsElseClause)"
proc newCs*(t: typedesc[CsEmptyStatement]): CsEmptyStatement =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsEmptyStatement]; info: Info): CsEmptyStatement =
  echo info
  result = newCs(CsEmptyStatement)

method genCs*(c: CsEmptyStatement): string =
  result = "[GENCS:CsEmptyStatement]"

  echo "--> in genCs*(c: var CsEmptyStatement): string ="
  todoimplGen()
method genNim*(c: CsEmptyStatement): string =
  result = "[GENNIM:CsEmptyStatement]"

  echo "--> in  genNim*(c: var CsEmptyStatement)"
  todoimplGen()
proc newCs*(t: typedesc[CsEnumMember]; name, value: auto): CsEnumMember =
  new result
  result.typ = $typeof(t)

  result.name = name
  result.value = value

import tables, sequtils
proc extract*(t: typedesc[CsEnumMember]; info: Info): CsEnumMember =
  echo info
  let tbl = colonsToTable(info.essentials)
  let name = tbl.getOrDefault("name")
  let value = tbl.getOrDefault("value")
  result = newCs(CsEnumMember, name, value)

method add*(em: CsEnumMember; val: string) =
  echo "val:", val
  if em.value.isEmptyOrWhitespace:
    em.value = val.strip
  else: echo "value is already set:`", em.value, "`. got `", val, "`;"
  # assert false # stop here

method genCs*(e: CsEnumMember): string =
  result = "[GENCS:CsEnumMember]"

  echo "--> in  genCs*(e: CsEnumMember)"
  echo e.name, e.value
  result = e.name
  if e.value != "": result &= " = " & $e.value

method genNim*(e: CsEnumMember): string =
  result = "[GENNIM:CsEnumMember]"

  echo "--> in  genNim*(e: CsEnumMember)"
  # echo e.name, e.value
  result = e.name
  if e.value != "": result &= " = " & $e.value

proc newCs*(t: typedesc[CsEnum]): CsEnum =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsEnum]; info: Info): CsEnum =
  assert info.essentials.len > 0
  let tbl = colonsToTable(info.essentials)
  let name = tbl.getOrDefault("name")
  let mods = tbl.getOrDefault("modifiers")
  result = newCs(CsEnum)
  result.name = name
  result.modifiers = mods.split(",").mapIt(it.strip)

method add*(parent: CsEnum; item: CsEnumMember) =
  parent.items.add item

method genCs*(e: CsEnum): string =
  result = "[GENCS:CsEnum]"
  result = ""

  result &= e.modifiers.join(" ") & " "
  result &= "enum " & e.name & " {"
  for i, it in e.items:
    if i != 0:
      result &= ", "
    result &= it.genCs()
  result &= "}"

method genNim*(e: CsEnum): string =
  result = "[GENNIM:CsEnum]"

  echo "--> in  genNim*(e: CsEnum)"
  echo "members count:" & $e.items.len
  result = "type " & e.name & "* = enum"
  if e.items.len > 0:
    result &= "\n  "
    let strs = e.items.mapIt(it.genNim())
    result &= strs.join(", ")
  # echo result

method add*(em: var CsEnumMember; item: CsEqualsValueClause) =
  em.value = item.value

proc newCs*(t: typedesc[CsEqualsValueClause]): CsEqualsValueClause =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsEqualsValueClause]; info: Info): CsEqualsValueClause =
  let tbl = info.essentials.colonsToTable()
  let val = tbl["value"]
  result = newCs(CsEqualsValueClause)
  result.value = val

method genCs*(c: CsEqualsValueClause): string =
  result = "[GENCS:CsEqualsValueClause]"

  echo "--> in genCs*(c: CsEqualsValueClause): string ="
  todoimplGen()
method genNim*(c: CsEqualsValueClause): string =
  result = "[GENNIM:CsEqualsValueClause]"

  echo "--> in  genNim*(c: var CsEqualsValueClause)"
  result = c.value

proc newCs*(t: typedesc[CsEventField]): CsEventField =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsEventField]; info: Info): CsEventField =
  echo info
  result = newCs(CsEventField)

method genCs*(c: CsEventField): string =
  result = "[GENCS:CsEventField]"

  echo "--> in genCs*(c: var CsEventField): string ="
  todoimplGen()
method genNim*(c: CsEventField): string =
  result = "[GENNIM:CsEventField]"

  echo "--> in  genNim*(c: var CsEventField)"

  todoimplGen()
proc newCs*(t: typedesc[CsEvent]): CsEvent =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsEvent]; info: Info): CsEvent =
  echo info
  result = newCs(CsEvent)

method genCs*(c: CsEvent): string =
  result = "[GENCS:CsEvent]"

  echo "--> in genCs*(c: var CsEvent): string ="
  todoimplGen()
method genNim*(c: CsEvent): string =
  result = "[GENNIM:CsEvent]"

  echo "--> in  genNim*(c: var CsEvent)"

  todoimplGen()
proc newCs*(t: typedesc[CsExplicitInterfaceSpecifier];
    name: string): CsExplicitInterfaceSpecifier =
  new result
  result.typ = $typeof(t)

  result.name = name

proc extract*(t: typedesc[CsExplicitInterfaceSpecifier];
    info: Info): CsExplicitInterfaceSpecifier = #TODO(extract:CsExplicitInterfaceSpecifier)
  let name = info.essentials[0]
  result = newCs(CsExplicitInterfaceSpecifier, name)

method genNim*(c: CsExplicitInterfaceSpecifier): string =
  result = "[GENNIM:CsExplicitInterfaceSpecifier]"

  todoimplGen()

# A method body's line.

method add*(c: var CsConstructor; item: CsExpressionStatement) =
  c.body.add(item)
method add*(c: var CsConstructor; item: CsAssignmentExpression) =
  c.body.add(item)
method add*(c: var CsConstructor; item: CsConstructorInitializer) =
  c.initializer = item

proc newCs*(t: typedesc[CsExpressionStatement]): CsExpressionStatement =
  new result
  result.typ = $typeof(t)
  result.ttype = "CsExpressionStatement"
  # result.typ = $typeof(t)

proc extract*(t: typedesc[CsExpressionStatement];
    info: Info): CsExpressionStatement =
  result = newCs(CsExpressionStatement)

method add*(parent: CsExpressionStatement; item: CsArgumentList) =
  parent.args = item

method add*(parent: CsTypeArgumentList; item: CsPredefinedType) =
  parent.types.add item.name
method add*(parent: CsArgument; item: CsLiteralExpression) =
  parent.expr = item



method add*(parent: CsArgumentList; item: CsArgument) =
  parent.args.add item

method add*(parent: CsExpressionStatement; item: CsAssignmentExpression) =
  parent.assign = item

method add*(parent: CsExpressionStatement; item: CsArgument) =
  parent.args.add item

method add*(parent: CsExpressionStatement; item: CsInvocationExpression) =
  parent.call = item


method genCs*(c: CsExpressionStatement): string =
  result = "[GENCS:CsExpressionStatement]"

  echo "--> in genCs*(c: CsExpressionStatement): string ="
  todoimplGen()
method genNim*(c: CsExpressionStatement): string =
  result = "[GENNIM:CsExpressionStatement]"
  result = ""

  echo "--> in  genNim*(c: CsExpressionStatement)"
  echo "generating for expression statement"
  echo "source is: " & c.src.strip()
  if not c.call.isNil:
    result = c.call.genNim()
    if c.call.callName.contains(".") and c.call.callName.startsWith(re.re"[A-Z]"):
      result &= " # " & c.call.callName.beforeFirstDot
  echo "expression statement generated result: " & result
  echo "<-- end of genNim*(c: CsExpressionStatement)"

proc newCs*(t: typedesc[CsExternAliasDirective];
    name: string): CsExternAliasDirective =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsExternAliasDirective];
    info: Info): CsExternAliasDirective =
  echo info
  let name = "" # info.essentials[0] # TODO!! cs environ got messed up after last extension update. after fixing, add name to info
  result = newCs(t, name) # rare, it's a name for the dll when ns+class ambiguity occurs, should be in Namespace i think.

method genCs*(c: CsExternAliasDirective): string =
  result = "[GENCS:CsExternAliasDirective]"

  echo "--> in genCs*(c: var CsExternAliasDirective): string ="
  todoimplGen()
method genNim*(c: CsExternAliasDirective): string =
  result = "[GENNIM:CsExternAliasDirective]"

  echo "--> in  genNim*(c: var CsExternAliasDirective)"

  todoimplGen()# hmm, it's actually called a property.

proc newCs*(t: typedesc[CsFinallyClause]): CsFinallyClause =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsFinallyClause]; info: Info): CsFinallyClause =
  echo info
  result = newCs(CsFinallyClause)

method genCs*(c: CsFinallyClause): string =
  result = "[GENCS:CsFinallyClause]"

  echo "--> in genCs*(c: var CsFinallyClause): string ="
  todoimplGen()
method genNim*(c: CsFinallyClause): string =
  result = "[GENNIM:CsFinallyClause]"

  echo "--> in  genNim*(c: var CsFinallyClause)"

  todoimplGen()
proc newCs*(t: typedesc[CsFixedStatement]): CsFixedStatement =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsFixedStatement]; info: Info): CsFixedStatement =
  echo info
  result = newCs(CsFixedStatement)

method genCs*(c: CsFixedStatement): string =
  result = "[GENCS:CsFixedStatement]"

  echo "--> in genCs*(c: var CsFixedStatement): string ="
  todoimplGen()
method genNim*(c: CsFixedStatement): string =
  result = "[GENNIM:CsFixedStatement]"

  echo "--> in  genNim*(c: var CsFixedStatement)"

  todoimplGen()
proc newCs*(t: typedesc[CsForEachStatement]): CsForEachStatement =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsForEachStatement]; info: Info): CsForEachStatement =
  echo info
  result = newCs(CsForEachStatement)

method genCs*(c: CsForEachStatement): string =
  result = "[GENCS:CsForEachStatement]"

  echo "--> in genCs*(c: var CsForEachStatement): string ="
  todoimplGen()
method genNim*(c: CsForEachStatement): string =
  result = "[GENNIM:CsForEachStatement]"
  echo "--> in  genNim*(c: var CsForEachStatement)"
  let lst = c.listPart.genNim()
  result = "for "
  result &= "todo!varName" # TODO!!
  if not c.gotType.isNil:
    result &= ": " & c.gotType.genNim()
  result &= " in " & lst & ":\n" & c.body.genBody()
  echo "<-- end of  genNim*(c: var CsForEachStatement)"

  todoimplGen()
proc newCs*(t: typedesc[CsForEachVariableStatement]): CsForEachVariableStatement =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsForEachVariableStatement]; info: Info): CsForEachVariableStatement =
  echo info
  result = newCs(CsForEachVariableStatement)

method genCs*(c: CsForEachVariableStatement): string =
  result = "[GENCS:CsForEachVariableStatement]"

  echo "--> in genCs*(c: var CsForEachVariableStatement): string ="
  todoimplGen()

method genNim*(c: CsForEachVariableStatement): string =
  result = "[GENNIM:CsForEachVariableStatement]"
  echo "--> in  genNim*(c: var CsForEachVariableStatement)"
  let lst = c.listPart.genNim()
  let v = c.varDecl.genNim()
  result = "for "
  result &= v
  if not c.gotType.isNil:
    result &= ": " & c.gotType.genNim()

  result &= " in " & lst & ":\n" & c.body.genBody()

  # todoimplGen()
proc newCs*(t: typedesc[CsForStatement]): CsForStatement =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsForStatement]; info: Info): CsForStatement =
  echo "in proc extract*(t: typedesc[CsForStatement];    info: Info): CsForStatement"
  echo info
  result = newCs(t)

method genCs*(c: CsForStatement): string =
  result = "[GENCS:CsForStatement]"

  echo "--> in genCs*(c: var CsForStatement): string ="
  todoimplGen()
method genNim*(c: CsForStatement): string =
  result = "[GENNIM:CsForStatement]"
  echo "--> in  genNim*(c: var CsForStatement)"
  # part1, and part3 with if, two fields for each.
  # part2 assert exists. gen it.
  # type... not sure why it should be here.
  # body.. gen body normally, if exists. else discard.
  # result = ""; result &= "for "
  # if not c.forPart1var.isNil: ....   .. in .. :\n" & genBody(c.body)
  let body = genBody(c.body)
  # for now, make it into a while loop, is there a c-like for in nim?
  var pt1 = ""
  var vartype = ""
  if not c.gotType.isNil: vartype = ": " & c.gotType.genNim()
  if not c.forPart1.isNil: pt1 = c.forPart1.genNim()
  elif not c.forPart1var.isNil: pt1 = c.forPart1var.genNim()
  assert not c.forPart2.isNil
  let pt2 = c.forPart2.genNim()
  var pt3 = ""
  if not c.forPart3.isNil: pt3 = c.forPart3.genNim()
  elif not c.forPart3prefix.isNil: pt3 = c.forPart3prefix.genNim()
  result = pt1 & vartype & "\n" & "while " & pt2 & ":\n" & indent() & body & "\n" & indent() & pt3
  echo "<-- end of genNim*(c: var CsForStatement)"


proc newCs*(t: typedesc[CsFromClause]): CsFromClause =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsFromClause]; info: Info): CsFromClause =
  echo info
  result = newCs(CsFromClause)

method genCs*(c: CsFromClause): string =
  result = "[GENCS:CsFromClause]"

  echo "--> in genCs*(c: var CsFromClause): string ="
  todoimplGen()
method genNim*(c: CsFromClause): string =
  result = "[GENNIM:CsFromClause]"

  echo "--> in  genNim*(c: var CsFromClause)"

  todoimplGen()
proc newCs*(t: typedesc[CsGenericName]): CsGenericName =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsGenericName]; info: Info): CsGenericName =
  result = newCs(CsGenericName)
  let tbl = colonsToTable(info.essentials)
  let tmp = tbl.getOrDefault("arity")
  result.arity = if tmp.isEmptyOrWhitespace: 0 else: tmp.parseInt
  result.name = tbl.getOrDefault("identifier")
  result.tplTxt = tbl.getOrDefault("typeArgumentList")
  result.tplArgsTxt = tbl.getOrDefault("typeArgumentListArgs")

method genCs*(c: CsGenericName): string =
  result = "[GENCS:CsGenericName]"
  echo "--> in genCs*(c: var CsGenericName): string ="
  todoimplGen()

method genNim*(c: CsGenericName): string =
  result = "[GENNIM:CsGenericName]"
  echo "--> in  genNim*(c: CsGenericName)"
  echo c.name
  echo c.arity
  echo c.tplTxt
  echo c.tplArgsTxt
  echo "tparglist nil? " , c.typearglist.isNil
  if not c.typearglist.isNil:
    result = c.name & "[" & c.typearglist.genNim() & "]"
  else:
    result = c.name & c.tplTxt.replacementGenericTypes()
  echo "<-- end of genNim*(c: CsGenericName)"

proc newCs*(t: typedesc[CsGlobalStatement]): CsGlobalStatement =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsGlobalStatement]; info: Info): CsGlobalStatement =
  echo info
  result = newCs(CsGlobalStatement)

method genCs*(c: CsGlobalStatement): string =
  result = "[GENCS:CsGlobalStatement]"

  echo "--> in genCs*(c: var CsGlobalStatement): string ="
  todoimplGen()
method genNim*(c: CsGlobalStatement): string =
  result = "[GENNIM:CsGlobalStatement]"

  echo "--> in  genNim*(c: var CsGlobalStatement)"

  todoimplGen()
proc newCs*(t: typedesc[CsGotoStatement]): CsGotoStatement =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsGotoStatement]; info: Info): CsGotoStatement =
  echo info
  result = newCs(CsGotoStatement)

method genCs*(c: CsGotoStatement): string =
  result = "[GENCS:CsGotoStatement]"

  echo "--> in genCs*(c: var CsGotoStatement): string ="
  todoimplGen()
method genNim*(c: CsGotoStatement): string =
  result = "[GENNIM:CsGotoStatement]"

  echo "--> in  genNim*(c: var CsGotoStatement)"

  todoimplGen()
proc newCs*(t: typedesc[CsGroupClause]): CsGroupClause =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsGroupClause]; info: Info): CsGroupClause =
  echo info
  result = newCs(CsGroupClause)

method genCs*(c: CsGroupClause): string =
  result = "[GENCS:CsGroupClause]"

  echo "--> in genCs*(c: var CsGroupClause): string ="
  todoimplGen()
method genNim*(c: CsGroupClause): string =
  result = "[GENNIM:CsGroupClause]"

  echo "--> in  genNim*(c: var CsGroupClause)"

  todoimplGen()
proc newCs*(t: typedesc[CsIfStatement]): CsIfStatement =
  new result
  result.typ = $typeof(t)
  result.ttype = $typeof(t)


proc extract*(t: typedesc[CsIfStatement]; info: Info): CsIfStatement =
  echo info
  result = newCs(CsIfStatement)
  let tbl = colonsToTable(info.essentials)
  result.condTxt = tbl.getOrDefault("condition")
  result.statementsTxt = tbl.getOrDefault("statement")
  result.elseTxt = tbl.getOrDefault("else")

proc newCs*(t: typedesc[CsImplicitArrayCreationExpression]): CsImplicitArrayCreationExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsImplicitArrayCreationExpression]; info: Info): CsImplicitArrayCreationExpression =
  echo info
  result = newCs(CsImplicitArrayCreationExpression)

method genCs*(c: CsImplicitArrayCreationExpression): string =
  result = "[GENCS:CsImplicitArrayCreationExpression]"

  echo "--> in genCs*(c: var CsImplicitArrayCreationExpression): string ="
  todoimplGen()
method genNim*(c: CsImplicitArrayCreationExpression): string =
  result = "[GENNIM:CsImplicitArrayCreationExpression]"

  echo "--> in  genNim*(c: var CsImplicitArrayCreationExpression)"

  todoimplGen()
proc newCs*(t: typedesc[CsImplicitElementAccess]): CsImplicitElementAccess =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsImplicitElementAccess]; info: Info): CsImplicitElementAccess =
  echo info
  result = newCs(CsImplicitElementAccess)

method genCs*(c: CsImplicitElementAccess): string =
  result = "[GENCS:CsImplicitElementAccess]"

  echo "--> in genCs*(c: var CsImplicitElementAccess): string ="
  todoimplGen()
method genNim*(c: CsImplicitElementAccess): string =
  result = "[GENNIM:CsImplicitElementAccess]"

  echo "--> in  genNim*(c: var CsImplicitElementAccess)"

  todoimplGen()
proc newCs*(t: typedesc[CsIncompleteMember]): CsIncompleteMember =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsIncompleteMember]; info: Info): CsIncompleteMember =
  echo info
  result = newCs(CsIncompleteMember)

method genCs*(c: CsIncompleteMember): string =
  result = "[GENCS:CsIncompleteMember]"

  echo "--> in genCs*(c: var CsIncompleteMember): string ="
  todoimplGen()
method genNim*(c: CsIncompleteMember): string =
  result = "[GENNIM:CsIncompleteMember]"

  echo "--> in  genNim*(c: var CsIncompleteMember)"

  todoimplGen()
proc newCs*(t: typedesc[CsIndexer]): CsIndexer =
  new result
  result.typ = $typeof(t)

  result.hasDefaultGet = true
  result.hasDefaultSet = true

proc extract*(t: typedesc[CsIndexer]; info: Info): CsIndexer =
  echo "extract info:", info
  let tbl = colonsToTable(info.essentials)
  result = newCs(CsIndexer)
  result.pmlist = tbl.getOrDefault("parameterList")
  result.exprBody = tbl.getOrDefault("expressionBody")
  result.acclist = tbl.getOrDefault("accessorList")
  result.mods = tbl.getOrDefault("modifiers")
  result.explSpecifier = tbl.getOrDefault "explicitInterfaceSpecifier"

method add*(parent: CsIndexer; item: CsParameter) =
  parent.varName = item.name
  parent.varType = item.ptype

method add*(parent: CsIndexer; item: CsBracketedParameterList) =
  parent.paramlist = item

method add*(parent: CsIndexer; item: CsPredefinedType) =
  parent.retType = item.name

method add*(parent: CsIndexer; item: CsExplicitInterfaceSpecifier) =
  parent.firstVarType = item.name

method add*(parent: CsLiteralExpression; item: CsPrefixUnaryExpression) =
  parent.value = item.prefix & parent.value

#

proc newCs*(t: typedesc[CsInitializerExpression]): CsInitializerExpression =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsInitializerExpression]; info: Info): CsInitializerExpression =
  result = newCs(t)
  echo info
  if info.essentials.len > 1:
    let tbl = colonsToTable(info.essentials)
    result.valueReceived = tbl["expressions"]

method genCs*(c: CsInitializerExpression): string =
  result = "[GENCS:CsInitializerExpression]"

  echo "--> in genCs*(c: var CsInitializerExpression): string ="
  todoimplGen()
method genNim*(c: CsInitializerExpression): string =
  result = "[GENNIM:CsInitializerExpression]"
  echo "--> in  genNim*(c: var CsInitializerExpression)"
  echo "genNim CsInitializerExpression, got values:", c.valueReceived
  # result = ".initWith("
  result = ".initWith(@["
  var ls: seq[string] = @[]
  for b in c.bexprs:
    echo "gen for " & b.typ
    let generated = b.genNim()
    echo b.typ, " generated: ", generated
    ls.add generated
  result &= ls.join(", ")
  # result &= ")"
  result &= "])"
  echo "genNim result CsInitializerExpression" & result

proc newCs*(t: typedesc[CsInterface]): CsInterface =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsInterface]; info: Info): CsInterface =
  echo info
  result = newCs(CsInterface)

method add*(parent: CsInterface; item: CsProperty) =
  parent.properties.add item

method genCs*(c: CsInterface): string =
  result = "[GENCS:CsInterface]"

  echo "--> in genCs*(c: var CsInterface): string ="
  todoimplGen()
method genNim*(c: CsInterface): string =
  result = "[GENNIM:CsInterface]"

  echo "--> in  genNim*(c: var CsInterface)"

  todoimplGen()
proc newCs*(t: typedesc[CsInterpolatedStringExpression]): CsInterpolatedStringExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsInterpolatedStringExpression]; info: Info): CsInterpolatedStringExpression =
  echo info
  result = newCs(CsInterpolatedStringExpression)

method genCs*(c: CsInterpolatedStringExpression): string =
  result = "[GENCS:CsInterpolatedStringExpression]"

  echo "--> in genCs*(c: var CsInterpolatedStringExpression): string ="
  todoimplGen()
method genNim*(c: CsInterpolatedStringExpression): string =
  result = "[GENNIM:CsInterpolatedStringExpression]"

  echo "--> in  genNim*(c: var CsInterpolatedStringExpression)"

  todoimplGen()
proc newCs*(t: typedesc[CsInterpolatedStringText]): CsInterpolatedStringText =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsInterpolatedStringText]; info: Info): CsInterpolatedStringText =
  echo info
  result = newCs(CsInterpolatedStringText)

method genCs*(c: CsInterpolatedStringText): string =
  result = "[GENCS:CsInterpolatedStringText]"

  echo "--> in genCs*(c: var CsInterpolatedStringText): string ="
  todoimplGen()
method genNim*(c: CsInterpolatedStringText): string =
  result = "[GENNIM:CsInterpolatedStringText]"

  echo "--> in  genNim*(c: var CsInterpolatedStringText)"

  todoimplGen()
proc newCs*(t: typedesc[CsInterpolationAlignmentClause]): CsInterpolationAlignmentClause =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsInterpolationAlignmentClause]; info: Info): CsInterpolationAlignmentClause =
  echo info
  result = newCs(CsInterpolationAlignmentClause)

method genCs*(c: CsInterpolationAlignmentClause): string =
  result = "[GENCS:CsInterpolationAlignmentClause]"

  echo "--> in genCs*(c: var CsInterpolationAlignmentClause): string ="
  todoimplGen()
method genNim*(c: CsInterpolationAlignmentClause): string =
  result = "[GENNIM:CsInterpolationAlignmentClause]"

  echo "--> in  genNim*(c: var CsInterpolationAlignmentClause)"

  todoimplGen()
proc newCs*(t: typedesc[CsInterpolationFormatClause]): CsInterpolationFormatClause =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsInterpolationFormatClause]; info: Info): CsInterpolationFormatClause =
  echo info
  result = newCs(CsInterpolationFormatClause)

method genCs*(c: CsInterpolationFormatClause): string =
  result = "[GENCS:CsInterpolationFormatClause]"

  echo "--> in genCs*(c: var CsInterpolationFormatClause): string ="
  todoimplGen()
method genNim*(c: CsInterpolationFormatClause): string =
  result = "[GENNIM:CsInterpolationFormatClause]"

  echo "--> in  genNim*(c: var CsInterpolationFormatClause)"

  todoimplGen()
proc newCs*(t: typedesc[CsInterpolation]): CsInterpolation =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsInterpolation]; info: Info): CsInterpolation =
  echo info
  result = newCs(CsInterpolation)

method genCs*(c: CsInterpolation): string =
  result = "[GENCS:CsInterpolation]"

  echo "--> in genCs*(c: var CsInterpolation): string ="
  todoimplGen()
method genNim*(c: CsInterpolation): string =
  result = "[GENNIM:CsInterpolation]"

  echo "--> in  genNim*(c: var CsInterpolation)"

  todoimplGen()
proc newCs*(t: typedesc[CsInvocationExpression]): CsInvocationExpression =
  new result
  result.typ = $typeof(t)
  result.ttype = "CsInvocationExpression"

proc extract*(t: typedesc[CsInvocationExpression]; info: Info): CsInvocationExpression =
  result = newCs(CsInvocationExpression)
  let tbl = colonsToTable(info.essentials)
  let name = tbl["expression"]
  result.callName = name

func normalizeCallName(s: string): string =
  assert s.contains(".") and s.startsWith(re.re"[A-Z]")
  let parts = s.rsplit(".", 1)
  let lastPart = parts[1] # last part is the function name that was called.
  result = lastPart.lowerFirst()

func beforeFirstDot(s:string):string =
  let parts = s.rsplit(".", 1)
  result = parts[0]


method genCs*(c: CsInvocationExpression): string =
  result = "[GENCS:CsInvocationExpression]"

  echo "--> in genCs*(c: CsInvocationExpression): string ="
  todoimplGen()
method genNim*(c: CsInvocationExpression): string =
  result = "[GENNIM:CsInvocationExpression]"
  echo "--> in  genNim*(c: CsInvocationExpression)"
  echo c.callName
  result = if c.callName.contains(".") and c.callName.startsWith(re.re"[A-Z]"):
    normalizeCallName(c.callName)
  elif c.callName.startsWith(re.re"[A-Z]"):
    c.callName.lowerFirst()
  else:
    c.callName
  result = result.replacementGenericTypes()
  result &= "("
  if c.args != nil:
    result &= c.args.genNim()
    #  and c.args.args.len > 0:
    # let args = c.args.args.mapIt(it.value).join(", ").replacementGenericTypes()
    # result &= args
  result &= ")"
  echo result
  echo "<-- end of genNim*(c: CsInvocationExpression)"

proc newCs*(t: typedesc[CsIsPatternExpression]): CsIsPatternExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsIsPatternExpression]; info: Info): CsIsPatternExpression =
  echo info
  result = newCs(CsIsPatternExpression)

method genCs*(c: CsIsPatternExpression): string =
  result = "[GENCS:CsIsPatternExpression]"

  echo "--> in genCs*(c: var CsIsPatternExpression): string ="
  todoimplGen()
method genNim*(c: CsIsPatternExpression): string =
  result = "[GENNIM:CsIsPatternExpression]"

  echo "--> in  genNim*(c: var CsIsPatternExpression)"

  todoimplGen()
proc newCs*(t: typedesc[CsJoinClause]): CsJoinClause =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsJoinClause]; info: Info): CsJoinClause =
  echo info
  result = newCs(CsJoinClause)

method genCs*(c: CsJoinClause): string =
  result = "[GENCS:CsJoinClause]"

  echo "--> in genCs*(c: var CsJoinClause): string ="
  todoimplGen()
method genNim*(c: CsJoinClause): string =
  result = "[GENNIM:CsJoinClause]"

  echo "--> in  genNim*(c: var CsJoinClause)"

  todoimplGen()
proc newCs*(t: typedesc[CsJoinIntoClause]): CsJoinIntoClause =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsJoinIntoClause]; info: Info): CsJoinIntoClause =
  echo info
  result = newCs(CsJoinIntoClause)

method genCs*(c: CsJoinIntoClause): string =
  result = "[GENCS:CsJoinIntoClause]"

  echo "--> in genCs*(c: var CsJoinIntoClause): string ="
  todoimplGen()
method genNim*(c: CsJoinIntoClause): string =
  result = "[GENNIM:CsJoinIntoClause]"

  echo "--> in  genNim*(c: var CsJoinIntoClause)"

  todoimplGen()
proc newCs*(t: typedesc[CsLabeledStatement]): CsLabeledStatement =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsLabeledStatement]; info: Info): CsLabeledStatement =
  echo info
  result = newCs(CsLabeledStatement)

method genCs*(c: CsLabeledStatement): string =
  result = "[GENCS:CsLabeledStatement]"

  echo "--> in genCs*(c: var CsLabeledStatement): string ="
  todoimplGen()
method genNim*(c: CsLabeledStatement): string =
  result = "[GENNIM:CsLabeledStatement]"

  echo "--> in  genNim*(c: var CsLabeledStatement)"

  todoimplGen()
proc newCs*(t: typedesc[CsLetClause]): CsLetClause =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsLetClause]; info: Info): CsLetClause =
  echo info
  result = newCs(CsLetClause)

method genCs*(c: CsLetClause): string =
  result = "[GENCS:CsLetClause]"

  echo "--> in genCs*(c: var CsLetClause): string ="
  todoimplGen()
method genNim*(c: CsLetClause): string =
  result = "[GENNIM:CsLetClause]"

  echo "--> in  genNim*(c: var CsLetClause)"

  todoimplGen()
method add*(parent: CsInitializerExpression; item: CsMemberAccessExpression) =
  parent.bexprs.add item
method add*(parent: CsInitializerExpression; item: CsInitializerExpression) =
  parent.bexprs.add item
method add*(parent: CsInitializerExpression; item: CsAssignmentExpression) =
  parent.bexprs.add item
method add*(parent: CsInitializerExpression; item: CsObjectCreationExpression) =
  parent.bexprs.add item
method add*(parent: CsInitializerExpression; item: CsPrefixUnaryExpression) =
  parent.bexprs.add item

method add*(parent: CsInitializerExpression; item: CsLiteralExpression) =
  parent.bexprs.add item

method add*(parent: CsBaseList; item: CsSimpleBaseType) =
  parent.baseList2.add item
  parent.baseList.add item.name

method add*(parent: CsBracketedParameterList; item: CsParameter) =
  parent.plist.add item.genNim()

method add*(parent: CsPrefixUnaryExpression; item: CsLiteralExpression) =
  parent.actingOn = item

method add*(em: var CsEnumMember; item: CsLiteralExpression) =
  em.add(item.value)
proc newCs(t: typedesc[CsLiteralExpression]; val: string): CsLiteralExpression =
  new result
  result.typ = $typeof(t)
  result.ttype = "CsLiteralExpression"
  result.value = val

proc extract*(_: typedesc[CsLiteralExpression]; info: Info): CsLiteralExpression =
  let tbl = colonsToTable(info.essentials)
  let strVal = tbl["token"]
  result = newCs(CsLiteralExpression, strVal)

method genCs*(lit: CsLiteralExpression): string =
  result = "[GENCS:CsLiteralExpression]"

  echo "--> in genCs*(lit: CsLiteralExpression): string ="
  result = lit.value

method genNim*(lit: CsLiteralExpression): string =
  echo "--> in  genNim*(lit: CsLiteralExpression)"
  result = "[GENNIM:CsLiteralExpression]"
  result = lit.value
  # some nim replacements. make it into a proper proc dictionary based. (it should include numbers with suffixes)
  if result == "null": result = "nil"

  echo result

  echo "end of genNim*(lit: CsLiteralExpression)"

proc newCs*(t: typedesc[CsLocalFunctionStatement]): CsLocalFunctionStatement =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsLocalFunctionStatement]; info: Info): CsLocalFunctionStatement =
  echo info
  result = newCs(CsLocalFunctionStatement)

method genCs*(c: CsLocalFunctionStatement): string =
  result = "[GENCS:CsLocalFunctionStatement]"

  echo "--> in genCs*(c: var CsLocalFunctionStatement): string ="
  todoimplGen()
method genNim*(c: CsLocalFunctionStatement): string =
  result = "[GENNIM:CsLocalFunctionStatement]"

  echo "--> in  genNim*(c: var CsLocalFunctionStatement)"

  todoimplGen()
proc newCs*(t: typedesc[CsAssignmentExpression]): CsAssignmentExpression =
  new result
  result.typ = $typeof(t)

proc newCs*(t: typedesc[CsLockStatement]): CsLockStatement =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsLockStatement]; info: Info): CsLockStatement =
  echo info
  result = newCs(CsLockStatement)

method genCs*(c: CsLockStatement): string =
  result = "[GENCS:CsLockStatement]"

  echo "--> in genCs*(c: var CsLockStatement): string ="
  todoimplGen()
method genNim*(c: CsLockStatement): string =
  result = "[GENNIM:CsLockStatement]"
  echo "--> in  genNim*(c: var CsLockStatement)"
  assert not c.locker.isNil # TODO: maybe should have identifier, but we ignored them. need to enable them again.
  let someLock = c.locker.genNim()
  result = "" # let locker = " & someLock  # possibly nim just wants the variable?
  result &= "withLock(" & someLock & "):" # TODO: need to import locks, meaning, we should have an import list for the nim generated code.
  startBlock()
  result &= genBody(c.body)
  endBlock()
  echo "<-- end of  genNim*(c: var CsLockStatement)"

proc newCs*(t: typedesc[CsMakeRefExpression]): CsMakeRefExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsMakeRefExpression]; info: Info): CsMakeRefExpression =
  echo info
  result = newCs(CsMakeRefExpression)

method genCs*(c: CsMakeRefExpression): string =
  result = "[GENCS:CsMakeRefExpression]"

  echo "--> in genCs*(c: var CsMakeRefExpression): string ="
  todoimplGen()
method genNim*(c: CsMakeRefExpression): string =
  result = "[GENNIM:CsMakeRefExpression]"

  echo "--> in  genNim*(c: var CsMakeRefExpression)"

  todoimplGen()
proc newCs*(t: typedesc[CsMemberBindingExpression]): CsMemberBindingExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsMemberBindingExpression]; info: Info): CsMemberBindingExpression =
  echo info
  result = newCs(CsMemberBindingExpression)

method genCs*(c: CsMemberBindingExpression): string =
  result = "[GENCS:CsMemberBindingExpression]"

  echo "--> in genCs*(c: var CsMemberBindingExpression): string ="
  todoimplGen()
method genNim*(c: CsMemberBindingExpression): string =
  result = "[GENNIM:CsMemberBindingExpression]"

  echo "--> in  genNim*(c: var CsMemberBindingExpression)"

  todoimplGen()
proc newCs*(t: typedesc[CsMethod]): CsMethod =
  new result
  result.typ = $typeof(t)

method add*(parent: CsMethod; t: CsPredefinedType) =
  parent.returnType = t.name

method add*(parent: CsMethod; p: CsParameterList) =
  parent.parameterList = p

method genCs*(item: CsObjectCreationExpression): string =
  result = "[GENCS:CsObjectCreationExpression]"

  echo "--> in genCs*(item: CsObjectCreationExpression): string ="
  todoimplGen()
method genNim*(item: CsObjectCreationExpression): string =
  result = "[GENNIM:CsObjectCreationExpression]"

  echo "--> in  genNim*(item:CsObjectCreationExpression) "
  result = "new" & item.name.replacementGenericTypes() &
    "(" &
    item.args.genNim().replacementGenericTypes() &
    ")"
  if not item.initExpr.isNil:
    echo "trying to genNim initExpr"
    result &= item.initExpr.genNim()

method add*(parent: CsObjectCreationExpression; item: CsGenericName) =
  parent.genericName = item

method add*(parent: CsObjectCreationExpression; item: CsPredefinedType) =
  parent.gotType = item

method add*(parent: CsObjectCreationExpression;
    item: CsInitializerExpression) =
  parent.initExpr = item
  # assert false

proc extract*(t: typedesc[CsAssignmentExpression]; info: Info): CsAssignmentExpression =
  echo "extract*(t: typedesc[CsAssignmentExpression]; info: Info): CsAssignmentExpression"
  result = newCs(CsAssignmentExpression)
  # let t = colonsToTable(info.essentials)
  # echo t
  echo info
  result.leftStr = info.essentials[0]
  # result.right = info.essentials[1]

method add*(parent: CsAssignmentExpression; item: CsTypeArgumentList) =
  echo "havent implemented method add*(parent:CsAssignmentExpression; item: CsTypeArgumentList) "
  todoimplAdd()

method add*(parent: CsAssignmentExpression; item: CsGenericName) =
  echo "havent implemented method add*(parent:CsAssignmentExpression; item: CsGenericName) "
  todoimplAdd()

method add*(parent: CsAssignmentExpression; item: CsArgumentList) =
  echo "havent implemented method add*(parent:CsAssignmentExpression; item: CsArgumentList) "
  todoimplAdd()

method add*(parent: CsAssignmentExpression; item: CsObjectCreationExpression) =
  parent.right = item

method add*(parent: CsGenericName; item: CsTypeArgumentList) =
  parent.typearglist = item

method genCs*(c: CsVariableDeclarator): string =
  result = "[GENCS:CsVariableDeclarator]"

  echo "--> in genCs*(c: CsVariableDeclarator): string ="
  todoimplGen()

method genNim*(c: CsVariableDeclarator) : string =
  # assert c.rhs != nil
  if not c.rhs.isNil:
    echo "rhs is: " & c.rhs.typ & c.rhs.ttype
    result &= c.rhs.genNim()
  else:
    if c.ev != nil and c.ev.rhsValue != nil:
      echo c.ev.rhsValue.typ
      result = c.ev.rhsValue.genNim()
  echo result


method add*(parent: CsMethod; item: CsReturnStatement) =
  parent.body.add item
method add*(parent: CsMethod; item: CsExpressionStatement) =
  parent.body.add item

proc newCs*(t: typedesc[CsNameColon]): CsNameColon =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsNameColon]; info: Info): CsNameColon =
  echo info
  result = newCs(CsNameColon)

method genCs*(c: CsNameColon): string =
  result = "[GENCS:CsNameColon]"

  echo "--> in genCs*(c: var CsNameColon): string ="
  todoimplGen()

method genNim*(c: CsNameColon): string =
  result = "[GENNIM:CsNameColon]"

  echo "--> in  genNim*(c: var CsNameColon)"
  todoimplGen()

proc newCs*(t: typedesc[CsNameEquals]; name: string): CsNameEquals =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsNameEquals]; info: Info): CsNameEquals =
  var name = ""
  if info.essentials.len > 0:
    name = info.essentials[0] # TODO: add in csdisplay
  result = newCs(CsNameEquals, name)

method add*(parent: CsNameEquals; item: CsGenericName) =
  parent.genericName = item

method add*(parent: CsField; item: CsVariableDeclarator) =
  echo "in add*(parent: CsField; item: CsVariableDeclarator)"

method add*(parent: CsField; item: CsVariable) =
  echo "in add*(parent: CsField; item: CsVariable)"
  if parent.name.isEmptyOrWhitespace:
    parent.name = item.name
  if parent.thetype.isEmptyOrWhitespace:
    parent.thetype = item.thetype

method add*(parent: CsParameter; item: CsPredefinedType) =
  parent.ptype = item.name
method add*(parent: CsParameter; item: CsGenericName) =
  parent.genericType = item

method genCs*(c: CsNameEquals): string =
  result = "[GENCS:CsNameEquals]"

  echo "--> in genCs*(c: var CsNameEquals): string ="
  todoimplGen()
method genNim*(c: CsNameEquals): string =
  result = "[GENNIM:CsNameEquals]"

  echo "--> in  genNim*(c: var CsNameEquals)"

  todoimplGen()
proc `$`*(c: CsUsingDirective): string =
  result = "import: ("
  result &= "name: " & c.name
  result &= ")"

proc `$`*(c: CsClass): string =
  result = "class: (name: " & c.name
  result &= "; methods: " & $c.methods.len
  result &= "; properties: " & $c.properties.len
  result &= ")"

proc `$`*(e: CsEnum): string =
  result = "enum: (name: " & e.name
  result &= "; items: " & $e.items.len
  result &= " )"

proc `$`*(n: CsNamespace): string =
  result = "namespace: ("
  result &= "name: " & n.name
  result &= "; imports: [" & n.imports.mapIt($it).join(", ") & "]"
  result &= "; classes: [" & n.classes.mapIt($it).join(", ") & "]"
  result &= "; enums: [" & n.enums.mapIt($it).join(", ") & "]"
  result &= ")"

proc newCs*(t: typedesc[CsNamespace]; name:string): CsNamespace =
  new result
  result.typ = $typeof(t)
  result.name = name

  result.classes = @[]
  result.classTable = newTable[string, CsClass]()
  result.enums = @[]
  result.enumTable = newTable[string, CsEnum]()
  result.interfaces = @[]
  result.interfaceTable = newTable[string, CsInterface]()

proc extract*(t: typedesc[CsMethod]; info: Info; data: AllNeededData): CsMethod =
  let tblE = colonsToTable(info.essentials)
  let tblX = colonsToTable(info.extras)
  let name = tblE["name"]
  let ret = tblE["return"]
  let mods = tblX["modifiers"]
  result = newCs(CsMethod)
  result.name = name
  if mods.contains("static"):
    result.isStatic = true
  if mods.contains("public"): result.isPublic = true
  if not ret.isEmptyOrWhitespace: result.returnType = ret

proc extract*(t: typedesc[CsClass]; info: Info; data: AllNeededData): CsClass =
  # new result
  let tbl = colonsToTable(info.essentials)
  let tblX = colonsToTable(info.extras)
  let name = tbl["name"]
  let mods = tblX["modifiers"]

  if tbl.hasKey("basetypes"):
    let baseTypes = tbl["basetypes"].split(", ")
    # echo "BASETYPES: " & $baseTypes
    if baseTypes.len > 1:
      result = newCs(CsClass, name, baseTypes[0], baseTypes[1..^1])
    else: result = newCs(CsClass, name, baseTypes[0])
  else:
    result = newCs(CsClass, name)
  if info.extras.len > 0:
    for m in mods.split(" "):
      result.mods.incl(m)

proc extract*(t: typedesc[CsNamespace]; info: Info; ): CsNamespace =
  echo "extract CsNamespace"
  let table = colonsToTable(info.essentials)
  let name = table["name"]
  result = newCs(CsNamespace,name)

proc extract*(t: typedesc[CsNamespace]; info: Info;    data: AllNeededData): CsNamespace =
  extract(t, info)


method add*(ns: var CsNamespace; use: CsUsingDirective) =
  ns.imports.add use
  ns.lastAddedTo = some(NamespaceParts.Using)

method genCs*(c: CsUsingDirective): string =
  result = "[GENCS:CsUsingDirective]"

  echo "--> in genCs*(c: CsUsingDirective): string ="
  result = "using " & c.name & ";"

method genNim*(c: CsUsingDirective): string =
  result = "[GENNIM:CsUsingDirective]"

  echo "--> in  genNim*(c: CsUsingDirective)"
  result = "import dotnet/" & c.name.toLowerAscii.replace(".", "/")

method genCs*(r: CsNamespace): string =
  result = "[GENCS:CsNamespace]"
  result = ""

  echo "--> in genCs*(r: CsNamespace)"
  echo "generating namespace: " & r.name
  var s: seq[string] = @[]
  for u in r.imports:
    s.add(u.genCs())
  s.add("")
  for c in r.classes:
    s.add(c.genCs())
  s.add("")
  for e in r.enums:
    let genEnum = e.genCs()
    echo genEnum
    s.add(genEnum)
  result &= s.join("\r\n")
  if r.name != "default":
    result = "namespace " & r.name & "{" & result & "}"

method genNim*(r: CsNamespace): string =
  result = "[GENNIM:CsNamespace]"
  result = ""

  echo "--> in  genNim*(r: CsNamespace)"
  echo "generating namespace: " & r.name
  var s: seq[string] = @[]
  for u in r.imports:
    s.add(u.genNim())
  s.add("")
  for c in r.classes:
    s.add(c.genNim())
  s.add("")
  for e in r.enums:
    s.add(e.genNim())
  result = s.join("\r\n")

proc hash*(c: CsNamespace): Hash =
  result = hash(c.name)

method add*(parent: CsUsingDirective; item: CsGenericName) =
  # likely in order to alias a type to a shorter text.
  parent.genericName = item

method add*(parent: CsUsingDirective; item: CsNameEquals) =
  parent.alias = item

proc newCs*(t: typedesc[CsNullableType]): CsNullableType =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsNullableType]; info: Info): CsNullableType =
  echo info
  result = newCs(CsNullableType)

method genCs*(c: CsNullableType): string =
  result = "[GENCS:CsNullableType]"

  echo "--> in genCs*(c: var CsNullableType): string ="
  todoimplGen()

method genNim*(c: CsNullableType): string =
  result = "[GENNIM:CsNullableType]"
  echo "--> in  genNim*(c: var CsNullableType)"
  todoimplGen()
  echo "<-- end of genNim*(c: var CsNullableType)"

proc newCs*(t: typedesc[CsObjectCreationExpression]): CsObjectCreationExpression =
  new result
  result.typ = $typeof(t)
  result.ttype = "CsObjectCreationExpression"

proc extract*(t: typedesc[CsObjectCreationExpression];info: Info): CsObjectCreationExpression =
  let tbl = colonsToTable(info.essentials)
  result = newCs(CsObjectCreationExpression )
  let newClassName = tbl["type"]
  result.name = newClassName

method add*(parent: CsObjectCreationExpression; item: CsArgumentList) =
  parent.args = item

proc newCs*(t: typedesc[CsOmittedArraySizeExpression]): CsOmittedArraySizeExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsOmittedArraySizeExpression]; info: Info): CsOmittedArraySizeExpression =
  echo info
  result = newCs(CsOmittedArraySizeExpression)

method genCs*(c: CsOmittedArraySizeExpression): string =
  result = "[GENCS:CsOmittedArraySizeExpression]"

  echo "--> in genCs*(c: var CsOmittedArraySizeExpression): string ="
  todoimplGen()
method genNim*(c: CsOmittedArraySizeExpression): string =
  result = "[GENNIM:CsOmittedArraySizeExpression]"
  echo "--> in  genNim*(c: var CsOmittedArraySizeExpression)"
  todoimplGen()
  echo "<-- end of  genNim*(c: var CsOmittedArraySizeExpression)"

proc newCs*(t: typedesc[CsOmittedTypeArgument]): CsOmittedTypeArgument =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsOmittedTypeArgument]; info: Info): CsOmittedTypeArgument =
  echo info
  result = newCs(CsOmittedTypeArgument)

method genCs*(c: CsOmittedTypeArgument): string =
  result = "[GENCS:CsOmittedTypeArgument]"

  echo "--> in genCs*(c: var CsOmittedTypeArgument): string ="
  todoimplGen()
method genNim*(c: CsOmittedTypeArgument): string =
  result = "[GENNIM:CsOmittedTypeArgument]"

  echo "--> in  genNim*(c: var CsOmittedTypeArgument)"

  todoimplGen()
proc newCs*(t: typedesc[CsOperator]): CsOperator =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsOperator]; info: Info): CsOperator =
  echo info
  result = newCs(CsOperator)

method genCs*(c: CsOperator): string =
  result = "[GENCS:CsOperator]"

  echo "--> in genCs*(c: var CsOperator): string ="
  todoimplGen()
method genNim*(c: CsOperator): string =
  result = "[GENNIM:CsOperator]"

  echo "--> in  genNim*(c: var CsOperator)"

  todoimplGen()
proc newCs*(t: typedesc[CsOrderByClause]): CsOrderByClause =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsOrderByClause]; info: Info): CsOrderByClause =
  echo info
  result = newCs(CsOrderByClause)

method genCs*(c: CsOrderByClause): string =
  result = "[GENCS:CsOrderByClause]"

  echo "--> in genCs*(c: var CsOrderByClause): string ="
  todoimplGen()
method genNim*(c: CsOrderByClause): string =
  result = "[GENNIM:CsOrderByClause]"

  echo "--> in  genNim*(c: var CsOrderByClause)"

  todoimplGen()
proc newCs*(t: typedesc[CsOrdering]): CsOrdering =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsOrdering]; info: Info): CsOrdering =
  echo info
  result = newCs(CsOrdering)

method genCs*(c: CsOrdering): string =
  result = "[GENCS:CsOrdering]"

  echo "--> in genCs*(c: var CsOrdering): string ="
  todoimplGen()
method genNim*(c: CsOrdering): string =
  result = "[GENNIM:CsOrdering]"

  echo "--> in  genNim*(c: var CsOrdering)"

  todoimplGen()
proc newCs*(t: typedesc[CsParameterList]): CsParameterList =
  new result # start empty.
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsParameterList]; info: Info; data: AllNeededData): CsParameterList =
  result = newCs(CsParameterList)

method add*(parent: CsParameterList; item: CsParameter) =
  parent.parameters.add item

proc extract*(t: typedesc[CsParameter]; info: Info): CsParameter =
  assert info.essentials.len >= 2
  let tbl = colonsToTable(info.essentials)
  echo info
  # assert false
  let name = tbl["name"]
  let ty = tbl["type"]
  result = newCs(CsParameter, name, ty)
  if info.extras.len > 0:
    let e = info.extras[0]
    if e.contains("ref"): result.isRef = true

proc newCs*(t: typedesc[CsParenthesizedExpression]): CsParenthesizedExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsParenthesizedExpression]; info: Info): CsParenthesizedExpression =
  echo info
  result = newCs(CsParenthesizedExpression)

method genCs*(c: CsParenthesizedExpression): string =
  result = "[GENCS:CsParenthesizedExpression]"

  echo "--> in genCs*(c: var CsParenthesizedExpression): string ="
  todoimplGen()
method genNim*(c: CsParenthesizedExpression): string =
  result = "[GENNIM:CsParenthesizedExpression]"
  echo "--> in  genNim*(c: var CsParenthesizedExpression)"
  let body = c.body.genBody()
  result = "(" & body & ")"
  echo "<-- end of  genNim*(c: var CsParenthesizedExpression)"
  # todoimplGen()

proc newCs*(t: typedesc[CsParenthesizedLambdaExpression]): CsParenthesizedLambdaExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsParenthesizedLambdaExpression]; info: Info): CsParenthesizedLambdaExpression =
  echo info
  result = newCs(CsParenthesizedLambdaExpression)

method genCs*(c: CsParenthesizedLambdaExpression): string =
  result = "[GENCS:CsParenthesizedLambdaExpression]"

  echo "--> in genCs*(c: var CsParenthesizedLambdaExpression): string ="
  todoimplGen()
method genNim*(c: CsParenthesizedLambdaExpression): string =
  result = "[GENNIM:CsParenthesizedLambdaExpression]"
  echo "--> in  genNim*(c: var CsParenthesizedLambdaExpression)"
  result = "(" & c.paramList.genNim() & ")" & "=>" & c.body.genBody()
  echo "<-- end of genNim*(c: var CsParenthesizedLambdaExpression)"

proc newCs*(t: typedesc[CsParenthesizedVariableDesignation]): CsParenthesizedVariableDesignation =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsParenthesizedVariableDesignation]; info: Info): CsParenthesizedVariableDesignation =
  echo info
  result = newCs(CsParenthesizedVariableDesignation)

method genCs*(c: CsParenthesizedVariableDesignation): string =
  result = "[GENCS:CsParenthesizedVariableDesignation]"

  echo "--> in genCs*(c: var CsParenthesizedVariableDesignation): string ="
  todoimplGen()
method genNim*(c: CsParenthesizedVariableDesignation): string =
  result = "[GENNIM:CsParenthesizedVariableDesignation]"

  echo "--> in  genNim*(c: var CsParenthesizedVariableDesignation)"

  todoimplGen()
proc newCs*(t: typedesc[CsPointerType]): CsPointerType =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsPointerType]; info: Info): CsPointerType =
  echo info
  result = newCs(CsPointerType)

method genCs*(c: CsPointerType): string =
  result = "[GENCS:CsPointerType]"

  echo "--> in genCs*(c: var CsPointerType): string ="
  todoimplGen()
method genNim*(c: CsPointerType): string =
  result = "[GENNIM:CsPointerType]"

  echo "--> in  genNim*(c: var CsPointerType)"

  todoimplGen()
proc newCs*(t: typedesc[CsPostfixUnaryExpression]): CsPostfixUnaryExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsPostfixUnaryExpression]; info: Info): CsPostfixUnaryExpression =
  echo info
  result = newCs(CsPostfixUnaryExpression)

method genCs*(c: CsPostfixUnaryExpression): string =
  result = "[GENCS:CsPostfixUnaryExpression]"

  echo "--> in genCs*(c: var CsPostfixUnaryExpression): string ="
  todoimplGen()
method genNim*(c: CsPostfixUnaryExpression): string =
  result = "[GENNIM:CsPostfixUnaryExpression]"
  echo "--> in  genNim*(c: var CsPostfixUnaryExpression)"
  assert not c.actingOn.isNil
  let obj = c.actingOn.genNim()
  result = obj & c.postfix
  result = "(" & obj & ")" & c.postfix
  # todoimplGen()
  echo "<-- end of genNim*(c: var CsPostfixUnaryExpression)"

proc newCs*(t: typedesc[CsPredefinedType]; name: string): CsPredefinedType =
  new result
  result.typ = $typeof(t)
  result.name = name

proc extract*(t: typedesc[CsPredefinedType]; info: Info; data: AllNeededData): CsPredefinedType =
  let tbl = colonsToTable(info.essentials)
  let name = tbl["keyword"]
  result = newCs(CsPredefinedType, name)

method genCs*(c: CsPredefinedType): string =
  result = "[GENCS:CsPredefinedType]"
  echo "--> in genCs*(c: var CsPredefinedType): string ="
  todoimplGen()

method genNim*(c: CsPredefinedType): string =
  result = "[GENNIM:CsPredefinedType]"
  echo "--> in  genNim*(c: var CsPredefinedType)"
  result = c.keyword.toNimType()
  echo "<-- end of  genNim*(c: var CsPredefinedType)"

proc newCs*(t: typedesc[CsPrefixUnaryExpression]): CsPrefixUnaryExpression =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsPrefixUnaryExpression]; info: Info): CsPrefixUnaryExpression =
  result = newCs(t)
  let tbl = colonsToTable(info.essentials)
  result.prefix = tbl["optoken"]
  result.expectedActingOn = tbl["operand"]

method genCs*(c: CsPrefixUnaryExpression): string =
  result = "[GENCS:CsPrefixUnaryExpression]"

  echo "--> in genCs*(c: CsPrefixUnaryExpression): string ="
  todoimplGen()

method genNim*(c: CsPrefixUnaryExpression): string =
  result = "[GENNIM:CsPrefixUnaryExpression]"
  echo "--> in  genNim*(c: CsPrefixUnaryExpression)"
  assert c.actingOn != nil or c.expectedActingOn.len > 0
  let act = if not c.actingOn.isNil: c.actingOn.genNim() else: c.expectedActingOn
  result = c.prefix & act
  echo "<-- end of genNim*(c: CsPrefixUnaryExpression)"

proc newCs*(t: typedesc[CsProperty]; name: string): CsProperty =
  new result
  result.typ = $typeof(t)
  result.name = name

proc extract*(t: typedesc[CsProperty]; info: Info): CsProperty =
  echo info
  let tbl2 = colonsToTable(info.extras)
  let tbl1 = colonsToTable(info.essentials)
  ## NOTE: very strange, no type from CsDisplay.
  let name = tbl1["name"]
  result = newCs(CsProperty, name)
  # assert false
  let cnt = info.extras.len # how many
                            # let cnt = info.essentials[1].parseInt # how many
  if cnt > 0:
    let acc1 = tbl2["accessor1"]
    case acc1
    of "get": result.hasGet = true
    of "set": result.hasSet = true
    if cnt > 1:
      let acc2 = tbl2["accessor2"]
      case acc2
      of "get": result.hasGet = true
      of "set": result.hasSet = true

method add*(parent: CsProperty; a: CsPredefinedType) =
  parent.retType = a.name

proc newCs*(t: typedesc[CsQueryBody]): CsQueryBody =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsQueryBody]; info: Info): CsQueryBody =
  echo info
  result = newCs(CsQueryBody)

method genCs*(c: CsQueryBody): string =
  result = "[GENCS:CsQueryBody]"

  echo "--> in genCs*(c: var CsQueryBody): string ="
  todoimplGen()

# TODO: figure out how to convert linq to nim. is there a macro? if not, functional style mapIt, filterIt etc?
# maybe convert linq to normal c# code first? I think best would be a nim macro. less bugs on my part, logic in a library.
# check out functional-zero. probably what we want here, efficiency & perf wise (yields etc).
method genNim*(c: CsQueryBody): string =
  result = "[GENNIM:CsQueryBody]"

  echo "--> in  genNim*(c: var CsQueryBody)"

  todoimplGen()
proc newCs*(t: typedesc[CsQueryContinuation]): CsQueryContinuation =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsQueryContinuation]; info: Info): CsQueryContinuation =
  echo info
  result = newCs(CsQueryContinuation)

method genCs*(c: CsQueryContinuation): string =
  result = "[GENCS:CsQueryContinuation]"

  echo "--> in genCs*(c: var CsQueryContinuation): string ="
  todoimplGen()
method genNim*(c: CsQueryContinuation): string =
  result = "[GENNIM:CsQueryContinuation]"

  echo "--> in  genNim*(c: var CsQueryContinuation)"

  todoimplGen()
proc newCs*(t: typedesc[CsQueryExpression]): CsQueryExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsQueryExpression]; info: Info): CsQueryExpression =
  echo info
  result = newCs(CsQueryExpression)

method genCs*(c: CsQueryExpression): string =
  result = "[GENCS:CsQueryExpression]"

  echo "--> in genCs*(c: var CsQueryExpression): string ="
  todoimplGen()
method genNim*(c: CsQueryExpression): string =
  result = "[GENNIM:CsQueryExpression]"
  echo "--> in  genNim*(c: var CsQueryExpression)"
  todoimplGen()
  echo "<-- end of genNim*(c: var CsQueryExpression)"

proc newCs*(t: typedesc[CsRefExpression]): CsRefExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsRefExpression]; info: Info): CsRefExpression =
  echo info
  result = newCs(CsRefExpression)

method genCs*(c: CsRefExpression): string =
  result = "[GENCS:CsRefExpression]"

  echo "--> in genCs*(c: var CsRefExpression): string ="
  todoimplGen()
method genNim*(c: CsRefExpression): string =
  result = "[GENNIM:CsRefExpression]"

  echo "--> in  genNim*(c: var CsRefExpression)"

  todoimplGen()
proc newCs*(t: typedesc[CsRefTypeExpression]): CsRefTypeExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsRefTypeExpression]; info: Info): CsRefTypeExpression =
  echo info
  result = newCs(CsRefTypeExpression)

method genCs*(c: CsRefTypeExpression): string =
  result = "[GENCS:CsRefTypeExpression]"

  echo "--> in genCs*(c: var CsRefTypeExpression): string ="
  todoimplGen()
method genNim*(c: CsRefTypeExpression): string =
  result = "[GENNIM:CsRefTypeExpression]"

  echo "--> in  genNim*(c: var CsRefTypeExpression)"

  todoimplGen()
proc newCs*(t: typedesc[CsRefType]): CsRefType =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsRefType]; info: Info): CsRefType =
  echo info
  result = newCs(CsRefType)

method genCs*(c: CsRefType): string =
  result = "[GENCS:CsRefType]"

  echo "--> in genCs*(c: var CsRefType): string ="
  todoimplGen()
method genNim*(c: CsRefType): string =
  result = "[GENNIM:CsRefType]"

  echo "--> in  genNim*(c: var CsRefType)"

  todoimplGen()
proc newCs*(t: typedesc[CsRefValueExpression]): CsRefValueExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsRefValueExpression]; info: Info): CsRefValueExpression =
  echo info
  result = newCs(CsRefValueExpression)

method genCs*(c: CsRefValueExpression): string =
  result = "[GENCS:CsRefValueExpression]"

  echo "--> in genCs*(c: var CsRefValueExpression): string ="
  todoimplGen()
method genNim*(c: CsRefValueExpression): string =
  result = "[GENNIM:CsRefValueExpression]"

  echo "--> in  genNim*(c: var CsRefValueExpression)"

  todoimplGen()
proc newCs*(t: typedesc[CsReturnStatement]): CsReturnStatement =
  new result
  result.typ = $typeof(t)
  result.ttype = "CsReturnStatement"

proc extract*(t: typedesc[CsReturnStatement]; info: Info): CsReturnStatement =
  result = newCs(CsReturnStatement)
  let tbl = colonsToTable(info.essentials)
  result.value = tbl.getOrDefault("expression")
  # echo "From C# side -- expected to follow after return: " & expectedFollowupAsString

# method add*(parent: BodyExpr; item: CsObject) =
#   raise newException(Exception, "likely parent  " & parent.ttype & " doesn't implement the correct add method? for item " & item.typ)

method add*(parent: CsReturnStatement; item: CsArgumentList) =
  parent.args = item

method add*(parent: CsReturnStatement; item: BodyExpr) =
  if parent.isComplete:
    assert false, "already complete with bodyExpr:" & $(not parent.expr.isNil)
  parent.expr = item; parent.isComplete = true

method genCs*(c: CsReturnStatement): string =
  result = "[GENCS:CsReturnStatement]"

  echo "--> in genCs*(c: CsReturnStatement): string ="
  result = "return"
  if c.expr.isNil:
    if not c.value.isEmptyOrWhitespace:
      result &= " " & c.value
  else:
    result &= " " & c.expr.genCs()
  result &= ";"
method genNim*(c: CsReturnStatement): string =
  result = "[GENNIM:CsReturnStatement]"

  echo "--> in  genNim*(c: CsReturnStatement)"
  echo "generating CsReturnStatement:"
  if not c.expr.isNil:
    echo "!!!!!!", c.expr.typ, " ", c.expr.ttype
  result = "return"
  if c.expr.isNil:
    if not c.value.isEmptyOrWhitespace:
      result &= " " & c.value
  else:
    echo c.expr.ttype
    result &= " " & c.expr.genNim()
    # if not c.args.isNil:
    #   result &= "(" & c.args.genNim() & ")"
  echo "result was:" & result

proc newCs*(t: typedesc[CsSelectClause]): CsSelectClause =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsSelectClause]; info: Info): CsSelectClause =
  echo info
  result = newCs(CsSelectClause)

method genCs*(c: CsSelectClause): string =
  result = "[GENCS:CsSelectClause]"

  echo "--> in genCs*(c: var CsSelectClause): string ="
  todoimplGen()
method genNim*(c: CsSelectClause): string =
  result = "[GENNIM:CsSelectClause]"

  echo "--> in  genNim*(c: var CsSelectClause)"

  todoimplGen()
proc newCs*(t: typedesc[CsSimpleBaseType]): CsSimpleBaseType =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsSimpleBaseType]; info: Info): CsSimpleBaseType =
  result = newCs(t)
  let tbl = colonsToTable(info.essentials)

  let name = tbl["type"]
  result.name = name

method genCs*(c: CsSimpleBaseType): string =
  result = "[GENCS:CsSimpleBaseType]"

  echo "--> in genCs*(c: var CsSimpleBaseType): string ="
  todoimplGen()
method genNim*(c: CsSimpleBaseType): string =
  result = "[GENNIM:CsSimpleBaseType]"

  echo "--> in  genNim*(c: var CsSimpleBaseType)"

  todoimplGen()
proc newCs*(t: typedesc[CsSimpleLambdaExpression]): CsSimpleLambdaExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsSimpleLambdaExpression]; info: Info): CsSimpleLambdaExpression =
  echo info
  result = newCs(CsSimpleLambdaExpression)

method genCs*(c: CsSimpleLambdaExpression): string =
  result = "[GENCS:CsSimpleLambdaExpression]"

  echo "--> in genCs*(c: var CsSimpleLambdaExpression): string ="
  todoimplGen()
method genNim*(c: CsSimpleLambdaExpression): string =
  result = "[GENNIM:CsSimpleLambdaExpression]"

  echo "--> in  genNim*(c: var CsSimpleLambdaExpression)"

  todoimplGen()
proc newCs*(t: typedesc[CsSingleVariableDesignation]): CsSingleVariableDesignation =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsSingleVariableDesignation]; info: Info): CsSingleVariableDesignation =
  echo info
  result = newCs(CsSingleVariableDesignation)

method genCs*(c: CsSingleVariableDesignation): string =
  result = "[GENCS:CsSingleVariableDesignation]"

  echo "--> in genCs*(c: var CsSingleVariableDesignation): string ="
  todoimplGen()
method genNim*(c: CsSingleVariableDesignation): string =
  result = "[GENNIM:CsSingleVariableDesignation]"

  echo "--> in  genNim*(c: var CsSingleVariableDesignation)"

  todoimplGen()
proc newCs*(t: typedesc[CsSizeOfExpression]): CsSizeOfExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsSizeOfExpression]; info: Info): CsSizeOfExpression =
  echo info
  result = newCs(CsSizeOfExpression)

method genCs*(c: CsSizeOfExpression): string =
  result = "[GENCS:CsSizeOfExpression]"
  echo "--> in genCs*(c: var CsSizeOfExpression): string ="
  todoimplGen()

method genNim*(c: CsSizeOfExpression): string =
  result = "[GENNIM:CsSizeOfExpression]"
  echo "--> in  genNim*(c: var CsSizeOfExpression)"
  result = "sizeof(" & c.gotType.genNim() & ")"
  # todoimplGen()

proc newCs*(t: typedesc[CsStackAllocArrayCreationExpression]): CsStackAllocArrayCreationExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsStackAllocArrayCreationExpression]; info: Info): CsStackAllocArrayCreationExpression =
  echo info
  result = newCs(CsStackAllocArrayCreationExpression)

method genCs*(c: CsStackAllocArrayCreationExpression): string =
  result = "[GENCS:CsStackAllocArrayCreationExpression]"

  echo "--> in genCs*(c: var CsStackAllocArrayCreationExpression): string ="
  todoimplGen()
method genNim*(c: CsStackAllocArrayCreationExpression): string =
  result = "[GENNIM:CsStackAllocArrayCreationExpression]"

  echo "--> in  genNim*(c: var CsStackAllocArrayCreationExpression)"

  todoimplGen()
proc newCs*(t: typedesc[CsStruct]): CsStruct =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsStruct]; info: Info): CsStruct =
  echo info
  result = newCs(CsStruct)

method genCs*(c: CsStruct): string =
  result = "[GENCS:CsStruct]"

  echo "--> in genCs*(c: var CsStruct): string ="
  todoimplGen()
method genNim*(c: CsStruct): string =
  result = "[GENNIM:CsStruct]"

  echo "--> in  genNim*(c: var CsStruct)"

  todoimplGen()
proc newCs*(t: typedesc[CsSwitchSection]): CsSwitchSection =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsSwitchSection]; info: Info): CsSwitchSection =
  echo info
  result = newCs(CsSwitchSection)

method genCs*(c: CsSwitchSection): string =
  result = "[GENCS:CsSwitchSection]"

  echo "--> in genCs*(c: var CsSwitchSection): string ="
  todoimplGen()
method genNim*(c: CsSwitchSection): string =
  result = "[GENNIM:CsSwitchSection]"

  echo "--> in  genNim*(c: var CsSwitchSection)"

  todoimplGen()
proc newCs*(t: typedesc[CsSwitchStatement]): CsSwitchStatement =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsSwitchStatement]; info: Info): CsSwitchStatement =
  echo info
  result = newCs(CsSwitchStatement)

method genCs*(c: CsSwitchStatement): string =
  result = "[GENCS:CsSwitchStatement]"

  echo "--> in genCs*(c: var CsSwitchStatement): string ="
  todoimplGen()
method genNim*(c: CsSwitchStatement): string =
  result = "[GENNIM:CsSwitchStatement]"

  echo "--> in  genNim*(c: var CsSwitchStatement)"

  todoimplGen()
proc newCs*(t: typedesc[CsThisExpression]): CsThisExpression =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsThisExpression];
    info: Info): CsThisExpression =
  echo info
  result = newCs(CsThisExpression)

method genCs*(c: CsThisExpression): string =
  result = "[GENCS:CsThisExpression]"

  echo "--> in genCs*(c: var CsThisExpression): string ="
  todoimplGen()
method genNim*(c: CsThisExpression): string =
  result = "[GENNIM:CsThisExpression]"
  echo "--> in  genNim*(c: var CsThisExpression)"
  result = "this"
  # todoimplGen()
proc newCs*(t: typedesc[CsThrowExpression]): CsThrowExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsThrowExpression]; info: Info): CsThrowExpression =
  echo info
  result = newCs(CsThrowExpression)

method genCs*(c: CsThrowExpression): string =
  result = "[GENCS:CsThrowExpression]"

  echo "--> in genCs*(c: var CsThrowExpression): string ="
  todoimplGen()
method genNim*(c: CsThrowExpression): string =
  result = "[GENNIM:CsThrowExpression]"

  echo "--> in  genNim*(c: var CsThrowExpression)"

  todoimplGen()
proc newCs*(t: typedesc[CsThrowStatement]): CsThrowStatement =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsThrowStatement]; info: Info): CsThrowStatement =
  echo info
  result = newCs(CsThrowStatement)

method genCs*(c: CsThrowStatement): string =
  result = "[GENCS:CsThrowStatement]"

  echo "--> in genCs*(c: var CsThrowStatement): string ="
  todoimplGen()

method genNim*(c: CsThrowStatement): string =
  result = "[GENNIM:CsThrowStatement]"
  echo "--> in  genNim*(c: var CsThrowStatement)"
  # hmm, do we always have just one throw statement?
  assert c.body.len <= 1
  result = "raise"
  if c.body.len > 0: result &= " "

  for b in c.body:
    let g = b.genNim()
    echo g
    result &= g & "\n"

  # todoimplGen()
proc newCs*(t: typedesc[CsTryStatement]): CsTryStatement =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsTryStatement]; info: Info): CsTryStatement =
  echo info
  let tbl = colonsToTable(info.essentials)
  result = newCs(CsTryStatement)
  result.mfinallyTxt = if tbl.hasKey("finally"): tbl["finally"] else:""
  result.catchesTxt = if tbl.hasKey("catches"): tbl["catches"] else:""

method genCs*(c: CsTryStatement): string =
  result = "[GENCS:CsTryStatement]"

  echo "--> in genCs*(c: var CsTryStatement): string ="
  todoimplGen()

proc nl(s:var string) =
  s &= "\n"
method genNim*(c: CsTryStatement): string =
  result = "[GENNIM:CsTryStatement]"
  echo "--> in  genNim*(c: var CsTryStatement)"
  result = "try:\n"
  startBlock()
  if c.body.len > 0:
    result &= c.body.genBody()
  endBlock()
  if c.catches.len > 0:
    for c in c.catches:
      result &= c.genNim()
  result.nl()
  if not c.mfinally.isNil:
    result &= c.mfinally.genNim()
  echo "<-- end of  genNim*(c: var CsTryStatement)"

proc newCs*(t: typedesc[CsTupleElement]): CsTupleElement =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsTupleElement]; info: Info): CsTupleElement =
  echo info
  result = newCs(CsTupleElement)

method genCs*(c: CsTupleElement): string =
  result = "[GENCS:CsTupleElement]"

  echo "--> in genCs*(c: var CsTupleElement): string ="
  todoimplGen()
method genNim*(c: CsTupleElement): string =
  result = "[GENNIM:CsTupleElement]"

  echo "--> in  genNim*(c: var CsTupleElement)"

  todoimplGen()
proc newCs*(t: typedesc[CsTupleExpression]): CsTupleExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsTupleExpression]; info: Info): CsTupleExpression =
  echo info
  result = newCs(CsTupleExpression)

method genCs*(c: CsTupleExpression): string =
  result = "[GENCS:CsTupleExpression]"

  echo "--> in genCs*(c: var CsTupleExpression): string ="
  todoimplGen()
method genNim*(c: CsTupleExpression): string =
  result = "[GENNIM:CsTupleExpression]"

  echo "--> in  genNim*(c: var CsTupleExpression)"

  todoimplGen()
proc newCs*(t: typedesc[CsTupleType]): CsTupleType =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsTupleType]; info: Info): CsTupleType =
  echo info
  result = newCs(CsTupleType) #todo

method genCs*(c: CsTupleType): string =
  result = "[GENCS:CsTupleType]"

  echo "--> in genCs*(c: var CsTupleType): string ="
  todoimplGen()
method genNim*(c: CsTupleType): string =
  result = "[GENNIM:CsTupleType]"

  echo "--> in  genNim*(c: var CsTupleType)"

  todoimplGen()
proc newCs*(t: typedesc[CsTypeArgumentList]): CsTypeArgumentList =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsTypeArgumentList]; info: Info): CsTypeArgumentList =
  result = newCs(CsTypeArgumentList)
  let tbl = colonsToTable(info.essentials)
  result.types = tbl.getOrDefault("arguments").split(",").mapIt(it.strip)

method genCs*(c: CsTypeArgumentList): string =
  result = "[GENCS:CsTypeArgumentList]"

  echo "--> in genCs*(c: var CsTypeArgumentList): string ="
  todoimplGen()
method genNim*(c: CsTypeArgumentList): string =
  result = "[GENNIM:CsTypeArgumentList]"
  echo "--> in  genNim*(c: var CsTypeArgumentList)"
  if c.gotTypes.len > 0:
    var tmp:seq[string]
    for t in c.gotTypes:
      tmp.add t.genNim()
    result = tmp.join("; ")
  else:
    result = ""
    if c.types.len > 0:
      result = c.types.join("; ").replacementGenericTypes()
  echo "<-- end of genNim*(c: var CsTypeArgumentList)"

proc newCs*(t: typedesc[CsTypeConstraint]): CsTypeConstraint =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsTypeConstraint]; info: Info): CsTypeConstraint =
  result = newCs(CsTypeConstraint)
  echo info

method genCs*(c: CsTypeConstraint): string =
  result = "[GENCS:CsTypeConstraint]"

  echo "--> in genCs*(c: var CsTypeConstraint): string ="
  todoimplGen()
method genNim*(c: CsTypeConstraint): string =
  result = "[GENNIM:CsTypeConstraint]"

  echo "--> in  genNim*(c: var CsTypeConstraint)"

  todoimplGen()
proc newCs*(t: typedesc[CsTypeOfExpression]): CsTypeOfExpression =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsTypeOfExpression]; info: Info): CsTypeOfExpression =
  echo info
  result = newCs(CsTypeOfExpression)

method genCs*(c: CsTypeOfExpression): string =
  result = "[GENCS:CsTypeOfExpression]"

  echo "--> in genCs*(c: var CsTypeOfExpression): string ="
  todoimplGen()
method genNim*(c: CsTypeOfExpression): string =
  result = "[GENNIM:CsTypeOfExpression]"

  echo "--> in  genNim*(c: var CsTypeOfExpression)"

  todoimplGen()
proc newCs*(t: typedesc[CsTypeParameterConstraintClause]): CsTypeParameterConstraintClause =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsTypeParameterConstraintClause]; info: Info): CsTypeParameterConstraintClause =
  result = newCs(CsTypeParameterConstraintClause)
  echo info

method genCs*(c: CsTypeParameterConstraintClause): string =
  result = "[GENCS:CsTypeParameterConstraintClause]"

  echo "--> in genCs*(c: var CsTypeParameterConstraintClause): string ="
  todoimplGen()
method genNim*(c: CsTypeParameterConstraintClause): string =
  result = "[GENNIM:CsTypeParameterConstraintClause]"

  echo "--> in  genNim*(c: var CsTypeParameterConstraintClause)"

  todoimplGen()
proc newCs*(t: typedesc[CsTypeParameterList]): CsTypeParameterList =
  new result
  result.theTypes = @[]
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsTypeParameterList]; info: Info): CsTypeParameterList =
  echo info
  result = newCs(CsTypeParameterList)
  # let ts =  info.essentials[0].strip(chars = { '<' }).strip(chars = { '>' }).split(",").mapIt(it.strip)
  # echo ts
  # result.theTypes = ts

method genCs*(c: CsTypeParameterList): string =
  result = "[GENCS:CsTypeParameterList]"

  echo "--> in genCs*(c: var CsTypeParameterList): string ="
  todoimplGen()
method genNim*(c: CsTypeParameterList): string =
  result = "[GENNIM:CsTypeParameterList]"
  echo "--> in  genNim*(c: var CsTypeParameterList)"
  result = ""
  var tmp:seq[string]
  for t in c.theTypes:
    let gen = t.genNim()
    tmp.add gen
  result &= "[" & tmp.join(", ") & "]"
  echo "<-- end of genNim*(c: var CsTypeParameterList)"

proc newCs*(t: typedesc[CsTypeParameter]): CsTypeParameter =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsTypeParameter]; info: Info): CsTypeParameter =
  echo info
  result = newCs(CsTypeParameter)
  let tbl = colonsToTable(info.essentials)
  result.param = tbl["varianceKeyword"]
  result.name = tbl["identifier"]

method genCs*(c: CsTypeParameter): string =
  result = "[GENCS:CsTypeParameter]"

  echo "--> in genCs*(c: var CsTypeParameter): string ="
  todoimplGen()

method genNim*(c: CsTypeParameter): string =
  result = "[GENNIM:CsTypeParameter]"
  echo "--> in  genNim*(c: var CsTypeParameter)"
  result = ""
  if c.param.len > 0:
    result &= c.param & " "
  result &= c.name
  echo "<-- end of  genNim*(c: var CsTypeParameter)"

proc newCs*(t: typedesc[CsUnsafeStatement]): CsUnsafeStatement =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsUnsafeStatement]; info: Info): CsUnsafeStatement =
  echo info
  result = newCs(CsUnsafeStatement)

method genCs*(c: CsUnsafeStatement): string =
  result = "[GENCS:CsUnsafeStatement]"

  echo "--> in genCs*(c: var CsUnsafeStatement): string ="
  todoimplGen()
method genNim*(c: CsUnsafeStatement): string =
  result = "[GENNIM:CsUnsafeStatement]"

  echo "--> in  genNim*(c: var CsUnsafeStatement)"

  todoimplGen()
proc newCs*(t: typedesc[CsUsingDirective]): CsUsingDirective =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsUsingDirective]; info: Info): CsUsingDirective =
  result = newCs(CsUsingDirective)
  echo info
  let tbl = colonsToTable(info.essentials)
  let name = tbl["name"]
  let staticKeyword = tbl.getOrDefault("staticKeyword")
  result.name = name
  echo staticKeyword # should it be "static"?
  result.hasStaticKeyword = staticKeyword == "static"

proc newCs*(t: typedesc[CsUsingStatement]): CsUsingStatement =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsUsingStatement]; info: Info): CsUsingStatement =
  echo info
  result = newCs(CsUsingStatement)

method genCs*(c: CsUsingStatement): string =
  result = "[GENCS:CsUsingStatement]"

  echo "--> in genCs*(c: var CsUsingStatement): string ="
  todoimplGen()
method genNim*(c: CsUsingStatement): string =
  result = "[GENNIM:CsUsingStatement]"

  echo "--> in  genNim*(c: var CsUsingStatement)"

  todoimplGen()
proc newCs*(t: typedesc[CsWhenClause]): CsWhenClause =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsWhenClause]; info: Info): CsWhenClause =
  echo info
  result = newCs(CsWhenClause)

method genCs*(c: CsWhenClause): string =
  result = "[GENCS:CsWhenClause]"

  echo "--> in genCs*(c: var CsWhenClause): string ="
  todoimplGen()
method genNim*(c: CsWhenClause): string =
  result = "[GENNIM:CsWhenClause]"

  echo "--> in  genNim*(c: var CsWhenClause)"

  todoimplGen()
proc newCs*(t: typedesc[CsWhereClause]): CsWhereClause =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsWhereClause]; info: Info): CsWhereClause =
  echo info
  result = newCs(CsWhereClause)

method genCs*(c: CsWhereClause): string =
  result = "[GENCS:CsWhereClause]"

  echo "--> in genCs*(c: var CsWhereClause): string ="
  todoimplGen()
method genNim*(c: CsWhereClause): string =
  result = "[GENNIM:CsWhereClause]"

  echo "--> in  genNim*(c: var CsWhereClause)"

  todoimplGen()
proc newCs*(t: typedesc[CsWhileStatement]): CsWhileStatement =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsWhileStatement]; info: Info): CsWhileStatement =
  echo info
  result = newCs(CsWhileStatement)

method genCs*(c: CsWhileStatement): string =
  result = "[GENCS:CsWhileStatement]"

  echo "--> in genCs*(c: var CsWhileStatement): string ="
  todoimplGen()
method genNim*(c: CsWhileStatement): string =
  result = "[GENNIM:CsWhileStatement]"
  echo "--> in  genNim*(c: var CsWhileStatement)"
  assert not c.hasNoPredicate
  result = "while "
  result &= genPred(c)
  result &= ":\n"
  for b in c.body:
    result &= "  " & b.genNim()
    # TODO: need to track indent levels, globally!!
  # todoimplGen()
proc newCs*(t: typedesc[CsYieldStatement]): CsYieldStatement =
  new result
  result.typ = $typeof(t)


proc extract*(t: typedesc[CsYieldStatement]; info: Info): CsYieldStatement =
  echo info
  result = newCs(CsYieldStatement)

method genCs*(c: CsYieldStatement): string =
  result = "[GENCS:CsYieldStatement]"

  echo "--> in genCs*(c: var CsYieldStatement): string ="
  todoimplGen()
method genNim*(c: CsYieldStatement): string =
  result = "[GENNIM:CsYieldStatement]"

  echo "--> in  genNim*(c: var CsYieldStatement)"

  todoimplGen()
proc newCs*(t: typedesc[CsBlock]): CsBlock =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsBlock], info: Info, data: AllNeededData): CsBlock =
  result = newCs(t)

method genCs*(c: CsBlock): string =
  result = "[GENCS:CsBlock]"

  echo "--> in genCs*(c: CsBlock): string"
  todoimplGen()
method genNim*(c: CsBlock): string =
  result = "[GENNIM:CsBlock]"

  todoimplGen()

proc newCs*(t: typedesc[CsVariable]): CsVariable =
  new result
  result.typ = $typeof(t)

proc newCs*(t: typedesc[CsLocalDeclarationStatement]): CsLocalDeclarationStatement =
  new result
  result.typ = $typeof(t)
  result.ttype = "CsLocalDeclarationStatement"

proc extract*(t: typedesc[CsLocalDeclarationStatement]; info: Info; data: AllNeededData): CsLocalDeclarationStatement =
  result = newCs(CsLocalDeclarationStatement)
  let tbl = colonsToTable(info.essentials)
  result.vartype = tbl["type"]
  result.names =tbl["names"].split(",").mapIt(it.strip)

method add*(parent: CsVariable, item: CsGenericName) =
  parent.genericName = item

method genCs*(c: CsLocalDeclarationStatement): string =
  result = "[GENCS:CsLocalDeclarationStatement]"

  echo "--> in genCs*(c: CsLocalDeclarationStatement): string ="
  todoimplGen()
method genNim*(c: CsLocalDeclarationStatement): string =
  result = "[GENNIM:CsLocalDeclarationStatement]"
  result = ""

  echo "--> in  genNim*(c:  CsLocalDeclarationStatement)"
  # echo "first genNim attempt!!!", c.names.join(", ") & " : " & c.vartype
  # result = "var " & $c.names.join(", ")
  # if c.vartype != "var":
  #   result &= " : " & c.vartype
  echo "START OF genNim CsLocalDeclarationStatement:"
  echo "left hand side"
  result &= c.lhs.genNim()
  echo "genNim result so far: " & result
  echo "right hand side: "
  if not c.rhs.isNil:
    echo "rhs type" & c.rhs.typ
    result &= c.rhs.genNim()
  else:
    echo "c.rhs was nil"
  echo "genNim result so far: " & result
  echo "END OF genNim CsLocalDeclarationStatement."

method add*(parent: CsMethod; t: CsLocalDeclarationStatement) =
  parent.body.add t

method add*(parent: CsLocalDeclarationStatement; item: CsVariable) =
  parent.lhs = item

method add*(parent: CsLocalDeclarationStatement; item: CsGenericName) =
  parent.lhs.genericName = item

method add*(parent: CsLocalDeclarationStatement; item: CsTypeArgumentList) =
  parent.lhs.genericName.typearglist = item
  # TODO: can also be the rhs. so we should forward to last construct that fits instead of a high parent.

method add*(parent: CsLocalDeclarationStatement;
    item: CsVariableDeclarator) =
  parent.rhs = item

method add*(parent: CsVariableDeclarator; item: CsLiteralExpression) =
  if parent.rhs.isNil:
    parent.rhs = item
method add*(parent: CsVariableDeclarator; item: CsArgumentList) =
  parent.arglist = item # FIXME!

method add*(parent: CsLocalDeclarationStatement;
    item: CsLiteralExpression) =
  parent.rhs.add item

method add*(parent: CsLocalDeclarationStatement; item: CsArgumentList) =
  parent.rhs.add item

method add*(parent: CsVariable; item: CsVariableDeclarator) =
  parent.declarator = item

method add*(parent: CsVariable; item: CsPredefinedType) =
  # echo item.name
  # echo parent.thetype
  if parent.thetype.isEmptyOrWhitespace:
    parent.thetype = item.name

method add*(parent: CsVariableDeclarator; item: CsEqualsValueClause) =
  parent.ev = item

proc newCs*(t: typedesc[CsVariableDeclarator]): CsVariableDeclarator =
  new result
  result.typ = $typeof(t)

method add*(parent: CsVariableDeclarator; item: CsMemberAccessExpression) =
  if parent.rhs.isNil:
    parent.rhs = item

method add*(parent: CsVariableDeclarator; item: CsBinaryExpression) =
  if parent.rhs.isNil:
    parent.rhs = item

method add*(parent: CsVariableDeclarator;
    item: CsObjectCreationExpression) =
  if parent.rhs.isNil:
    parent.rhs = item
  # assert parent.bexpr.isNil
  # parent.bexpr = item

proc extract*(_: typedesc[CsVariableDeclarator];
    info: Info): CsVariableDeclarator =
  result = newCs(CsVariableDeclarator)
  result.name = info.essentials[0]

proc extract*(t: typedesc[CsVariable], info: Info, data: AllNeededData): CsVariable =
  result = newCs(CsVariable)
  let tbl = colonsToTable(info.essentials)
  result.thetype = tbl["type"]
  result.name = tbl["name"]

method genCs*(c: CsVariable): string =
  result = "[GENCS:CsVariable]"

  echo "--> in genCs*(c: CsVariable): string ="
  todoimplGen()
method genNim*(c: CsVariable): string =
  result = "[GENNIM:CsVariable]"

  result = "var " & c.name
  if c.thetype != "var":
    result &= " : " & c.thetype.replacementGenericTypes()
  if not c.declarator.isNil:
    let gendecl = c.declarator.genNim()
    result &= " = " & gendecl

proc newCs*(t: typedesc[CsBinaryPattern]): CsBinaryPattern =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsBinaryPattern], info: Info, data: AllNeededData): CsBinaryPattern =
  echo info
  result = newCs(CsBinaryPattern)

method genCs*(c: CsBinaryPattern): string =
  result = "[GENCS:CsBinaryPattern]"

  echo "--> in genCs*(c: CsBinaryPattern): string"
  todoimplGen()

method genNim*(c: CsBinaryPattern): string =
  result = "[GENNIM:CsBinaryPattern]"

  todoimplGen()

proc newCs*(t: typedesc[CsDiscardPattern]): CsDiscardPattern =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsDiscardPattern], info: Info, data: AllNeededData): CsDiscardPattern =
  echo info
  result = newCs(CsDiscardPattern)

method genCs*(c: CsDiscardPattern): string =
  result = "[GENCS:CsDiscardPattern]"

  echo "--> in genCs*(c: CsDiscardPattern): string"
  todoimplGen()
method genNim*(c: CsDiscardPattern): string =
  result = "[GENNIM:CsDiscardPattern]"

  todoimplGen()

proc newCs*(t: typedesc[CsFunctionPointerType]): CsFunctionPointerType =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsFunctionPointerType], info: Info, data: AllNeededData): CsFunctionPointerType =
  echo info
  result = newCs(CsFunctionPointerType)

method genCs*(c: CsFunctionPointerType): string =
  result = "[GENCS:CsFunctionPointerType]"

  echo "--> in genCs*(c: CsFunctionPointerType): string"
  todoimplGen()
method genNim*(c: CsFunctionPointerType): string =
  result = "[GENNIM:CsFunctionPointerType]"

  todoimplGen()

proc newCs*(t: typedesc[CsImplicitObjectCreationExpression]): CsImplicitObjectCreationExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsImplicitObjectCreationExpression], info: Info): CsImplicitObjectCreationExpression =
  echo info
  result = newCs(CsImplicitObjectCreationExpression)

method genCs*(c: CsImplicitObjectCreationExpression): string =
  result = "[GENCS:CsImplicitObjectCreationExpression]"

  echo "--> in genCs*(c: CsImplicitObjectCreationExpression): string"
  todoimplGen()

method genNim*(c: CsImplicitObjectCreationExpression): string =
  result = "[GENNIM:CsImplicitObjectCreationExpression]"

  todoimplGen()

proc newCs*(t: typedesc[CsMemberAccessExpression]): CsMemberAccessExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsMemberAccessExpression], info: Info, data: AllNeededData): CsMemberAccessExpression =
  result = newCs(CsMemberAccessExpression)
  echo info
  let tbl = colonsToTable(info.essentials)
  result.member = tbl["name"]
  result.optoken = tbl.getOrDefault "optoken"
  result.fromPart = tbl["expression"]

method genCs*(c: CsMemberAccessExpression): string =
  result = "[GENCS:CsMemberAccessExpression]"

  echo "--> in genCs*(c: CsMemberAccessExpression): string ="
  todoimplGen()
method genNim*(c: CsMemberAccessExpression): string =
  result = "[GENNIM:CsMemberAccessExpression]"

  echo "in genNim*(c: CsMemberAccessExpression)"
  result = c.fromPart & "." & c.member.lowerFirst
proc newCs*(t: typedesc[CsParenthesizedPattern]): CsParenthesizedPattern =
  new result
  result.typ = $typeof(t)
proc extract*(t: typedesc[CsParenthesizedPattern], info: Info, data: AllNeededData): CsParenthesizedPattern =
  echo info
  result = newCs(CsParenthesizedPattern)

method genCs*(c: CsParenthesizedPattern): string =
  result = "[GENCS:CsParenthesizedPattern]"

  echo "--> in genCs*(c: CsParenthesizedPattern): string"
  todoimplGen()
method genNim*(c: CsParenthesizedPattern): string =
  result = "[GENNIM:CsParenthesizedPattern]"

  todoimplGen()

proc newCs*(t: typedesc[CsPositionalPatternClause]): CsPositionalPatternClause =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsPositionalPatternClause], info: Info, data: AllNeededData): CsPositionalPatternClause =
  echo info
  result = newCs(CsPositionalPatternClause)

method genCs*(c: CsPositionalPatternClause): string =
  result = "[GENCS:CsPositionalPatternClause]"

  echo "--> in genCs*(c: CsPositionalPatternClause): string"
  todoimplGen()
method genNim*(c: CsPositionalPatternClause): string =
  result = "[GENNIM:CsPositionalPatternClause]"

  todoimplGen()

proc newCs*(t: typedesc[CsPrimaryConstructorBaseType]): CsPrimaryConstructorBaseType =
  new result
  result.typ = $typeof(t)
proc extract*(t: typedesc[CsPrimaryConstructorBaseType], info: Info, data: AllNeededData): CsPrimaryConstructorBaseType =
  echo info
  result = newCs(CsPrimaryConstructorBaseType)

method genCs*(c: CsPrimaryConstructorBaseType): string =
  result = "[GENCS:CsPrimaryConstructorBaseType]"


  echo "--> in genCs*(c: CsPrimaryConstructorBaseType): string"
  todoimplGen()
method genNim*(c: CsPrimaryConstructorBaseType): string =
  result = "[GENNIM:CsPrimaryConstructorBaseType]"

  todoimplGen()

proc newCs*(t: typedesc[CsPropertyPatternClause]): CsPropertyPatternClause =
  new result
  result.typ = $typeof(t)
proc extract*(t: typedesc[CsPropertyPatternClause], info: Info, data: AllNeededData): CsPropertyPatternClause =
  echo info
  result = newCs(CsPropertyPatternClause)

method genCs*(c: CsPropertyPatternClause): string =
  result = "[GENCS:CsPropertyPatternClause]"


  echo "--> in genCs*(c: CsPropertyPatternClause): string"
  todoimplGen()
method genNim*(c: CsPropertyPatternClause): string =
  result = "[GENNIM:CsPropertyPatternClause]"

  todoimplGen()

proc newCs*(t: typedesc[CsRangeExpression]): CsRangeExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsRangeExpression], info: Info, data: AllNeededData): CsRangeExpression =
  echo info
  result = newCs(CsRangeExpression)

method genCs*(c: CsRangeExpression): string =
  result = "[GENCS:CsRangeExpression]"


  echo "--> in genCs*(c: CsRangeExpression): string"
  todoimplGen()
method genNim*(c: CsRangeExpression): string =
  result = "[GENNIM:CsRangeExpression]"

  todoimplGen()

proc newCs*(t: typedesc[CsRecord]): CsRecord =
  new result
  result.typ = $typeof(t)
proc extract*(t: typedesc[CsRecord], info: Info, data: AllNeededData): CsRecord =
  echo info
  result = newCs(CsRecord)

method genCs*(c: CsRecord): string =
  result = "[GENCS:CsRecord]"


  echo "--> in genCs*(c: CsRecord): string"
  todoimplGen()
method genNim*(c: CsRecord): string =
  result = "[GENNIM:CsRecord]"

  todoimplGen()

proc newCs*(t: typedesc[CsRecursivePattern]): CsRecursivePattern =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsRecursivePattern], info: Info, data: AllNeededData): CsRecursivePattern =
  echo info
  result = newCs(CsRecursivePattern)

method genCs*(c: CsRecursivePattern): string =
  result = "[GENCS:CsRecursivePattern]"


  echo "--> in genCs*(c: CsRecursivePattern): string"
  todoimplGen()
method genNim*(c: CsRecursivePattern): string =
  result = "[GENNIM:CsRecursivePattern]"

  todoimplGen()

proc newCs*(t: typedesc[CsRelationalPattern]): CsRelationalPattern =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsRelationalPattern], info: Info, data: AllNeededData): CsRelationalPattern =
  echo info
  result = newCs(CsRelationalPattern)

method genCs*(c: CsRelationalPattern): string =
  result = "[GENCS:CsRelationalPattern]"


  echo "--> in genCs*(c: CsRelationalPattern): string"
  todoimplGen()
method genNim*(c: CsRelationalPattern): string =
  result = "[GENNIM:CsRelationalPattern]"

  todoimplGen()

proc newCs*(t: typedesc[CsSubpattern]): CsSubpattern =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsSubpattern], info: Info, data: AllNeededData): CsSubpattern =
  echo info
  result = newCs(CsSubpattern)

method genCs*(c: CsSubpattern): string =
  result = "[GENCS:CsSubpattern]"


  echo "--> in genCs*(c: CsSubpattern): string"
  todoimplGen()
method genNim*(c: CsSubpattern): string =
  result = "[GENNIM:CsSubpattern]"

  todoimplGen()

proc newCs*(t: typedesc[CsSwitchExpression]): CsSwitchExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsSwitchExpression], info: Info, data: AllNeededData): CsSwitchExpression =
  echo info
  result = newCs(CsSwitchExpression)

method genCs*(c: CsSwitchExpression): string =
  result = "[GENCS:CsSwitchExpression]"


  echo "--> in genCs*(c: CsSwitchExpression): string"
  todoimplGen()
method genNim*(c: CsSwitchExpression): string =
  result = "[GENNIM:CsSwitchExpression]"

  todoimplGen()

proc newCs*(t: typedesc[CsSwitchExpressionArm]): CsSwitchExpressionArm =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsSwitchExpressionArm], info: Info, data: AllNeededData): CsSwitchExpressionArm =
  echo info
  result = newCs(CsSwitchExpressionArm)

method genCs*(c: CsSwitchExpressionArm): string =
  result = "[GENCS:CsSwitchExpressionArm]"


  echo "--> in genCs*(c: CsSwitchExpressionArm): string"
  todoimplGen()
method genNim*(c: CsSwitchExpressionArm): string =
  result = "[GENNIM:CsSwitchExpressionArm]"

  todoimplGen()

proc newCs*(t: typedesc[CsTypePattern]): CsTypePattern =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsTypePattern], info: Info, data: AllNeededData): CsTypePattern =
  echo info
  result = newCs(CsTypePattern)

method genCs*(c: CsTypePattern): string =
  result = "[GENCS:CsTypePattern]"


  echo "--> in genCs*(c: CsTypePattern): string"
  todoimplGen()
method genNim*(c: CsTypePattern): string =
  result = "[GENNIM:CsTypePattern]"

  todoimplGen()

proc newCs*(t: typedesc[CsUnaryPattern]): CsUnaryPattern =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsUnaryPattern], info: Info, data: AllNeededData): CsUnaryPattern =
  echo info
  result = newCs(CsUnaryPattern)

method genCs*(c: CsUnaryPattern): string =
  result = "[GENCS:CsUnaryPattern]"


  echo "--> in genCs*(c: CsUnaryPattern): string"
  todoimplGen()
method genNim*(c: CsUnaryPattern): string =
  result = "[GENNIM:CsUnaryPattern]"

  todoimplGen()

proc newCs*(t: typedesc[CsVarPattern]): CsVarPattern =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsVarPattern], info: Info, data: AllNeededData): CsVarPattern =
  echo info
  result = newCs(CsVarPattern)

method genCs*(c: CsVarPattern): string =
  result = "[GENCS:CsVarPattern]"


  echo "--> in genCs*(c: CsVarPattern): string"
  todoimplGen()
method genNim*(c: CsVarPattern): string =
  result = "[GENNIM:CsVarPattern]"

  todoimplGen()

proc newCs*(t: typedesc[CsWithExpression]): CsWithExpression =
  new result
  result.typ = $typeof(t)

proc extract*(t: typedesc[CsWithExpression], info: Info, data: AllNeededData): CsWithExpression =
  echo info
  result = newCs(CsWithExpression)

method genCs*(c: CsWithExpression): string =
  result = "[GENCS:CsWithExpression]"


  echo "--> in genCs*(c: CsWithExpression): string"
  todoimplGen()
method genNim*(c: CsWithExpression): string =
  result = "[GENNIM:CsWithExpression]"

  todoimplGen()

proc extract*(t: typedesc[CsImplicitStackAllocArrayCreationExpression], info: Info): CsImplicitStackAllocArrayCreationExpression =
  todoimpl("extract")
method genCs*(c: CsImplicitStackAllocArrayCreationExpression): string =
  result = "[GENCS:CsImplicitStackAllocArrayCreationExpression]"

  echo "--> in genCs*(c: CsImplicitStackAllocArrayCreationExpression): string"
  todoimplGen()
method genNim*(c: CsImplicitStackAllocArrayCreationExpression): string =
  result = "[GENNIM:CsImplicitStackAllocArrayCreationExpression]"

  todoimplGen()

method add*(parent: CsParameter; item: CsEqualsValueClause) =
  echo "in method add*(parent: CsParameter; item: CsEqualsValueClause)"
  parent.initValueExpr = item

method add*(parent: CsEqualsValueClause; item: CsInvocationExpression) =
  echo "in method add*(parent: CsEqualsValueClause; item: CsInvocationExpression)"
  parent.rhsValue = item

method add*(parent: CsArgument; item: CsPrefixUnaryExpression) =
  echo "in method add*(parent: CsArgument; item: CsPrefixUnaryExpression)"
  parent.expr = item

method add*(parent: CsArgument; item: CsObjectCreationExpression) =
  echo "in method add*(parent: CsArgument; item: CsObjectCreationExpression)"
  parent.expr = item

method add*(parent: CsArgument; item: CsMemberAccessExpression) =
  echo "in method add*(parent: CsArgument; item: CsMemberAccessExpression)"
  parent.expr = item

method add*(parent: CsArgument; item: CsInvocationExpression) =
  echo "in method add*(parent: CsArgument; item: CsInvocationExpression)"
  parent.expr = item

method add*(parent: CsArgument; item: CsBinaryExpression) =
  echo "in method add*(parent: CsArgument; item: CsBinaryExpression)"
  parent.expr = item

method add*(parent: CsArgument; item: CsAssignmentExpression) =
  echo "in method add*(parent: CsArgument; item: CsAssignmentExpression)"
  parent.expr = item

method add*(parent: CsTypeArgumentList; item: CsGenericName) =
  echo "in method add*(parent: CsTypeArgumentList; item: CsGenericName)"
  parent.gotTypes.add item

method add*(parent: CsBaseList; item: CsMemberAccessExpression) =
  echo "in method add*(parent: CsBaseList; item: CsMemberAccessExpression)"
  todoimplAdd()# TODO(add:CsBaseList, CsMemberAccessExpression)

method add*(parent: CsBaseList; item: CsConstructorInitializer) =
  echo "in method add*(parent: CsBaseList; item: CsConstructorInitializer)"
  todoimplAdd()# TODO(add:CsBaseList, CsConstructorInitializer)

method add*(parent: CsMemberAccessExpression; item: CsMemberAccessExpression) =
  echo "in method add*(parent: CsMemberAccessExpression; item: CsMemberAccessExpression)"
  parent.left = item

method add*(parent: CsBinaryExpression; item: CsMemberAccessExpression) =
  echo "in method add*(parent: CsBinaryExpression; item: CsMemberAccessExpression)"
  # assert false, parent.left.name & ":" & parent.right.name
  parent.addBinExp(item)




method add*(parent: CsBinaryExpression; item: CsLiteralExpression) =
  echo "in method add*(parent: CsBinaryExpression; item: CsLiteralExpression)"
  parent.addBinExp(item)

method add*(parent: CsBinaryExpression; item: CsBinaryExpression) =
  echo "in method add*(parent: CsBinaryExpression; item: CsBinaryExpression)"
  parent.addBinExp(item)
  # parent.left = item

method add*(parent: CsTypeParameterList; item: CsTypeParameter) =
  echo "in method add*(parent: CsTypeParameterList, item: CsTypeParameter)"
  parent.theTypes.add item

method add*(parent: CsClass; item: CsTypeParameterConstraintClause) =
  echo "in method add*(parent: CsClass; item: CsTypeParameterConstraintClause)"
  parent.typeParamConstraints = item

method add*(parent: CsTypeParameterConstraintClause; item: CsTypeConstraint) =
  echo "in method add*(parent: CsTypeParameterConstraintClause; item: CsTypeConstraint)"
  parent.constraints.add item

method add*(parent: CsTypeConstraint; item: CsGenericName) =
  echo "in method add*(parent: CsTypeConstraint; item: CsGenericName)"
  parent.gotType = item

method add*(parent: CsInvocationExpression; item: CsGenericName) =
  echo "in method add*(parent: CsInvocationExpression; item: CsGenericName)"
  parent.gotType = item

method add*(parent: CsIfStatement; item: CsBinaryExpression) =
  echo "in method add*(parent: CsIfStatement; item: CsBinaryExpression)"
  parent.predicate = item

method add*(parent: CsBinaryExpression; item: CsTypeOfExpression) =
  echo "in method add*(parent: CsBinaryExpression; item: CsTypeOfExpression)"
  parent.addBinExp item

method add*(parent: CsAssignmentExpression; item: CsCastExpression) =
  echo "in method add*(parent: CsAssignmentExpression; item: CsCastExpression)"
  parent.right = item

method add*(parent: CsCastExpression; item: CsThisExpression) =
  echo "in method add*(parent: CsCastExpression; item: CsThisExpression)"
  parent.expr = item

method add*(parent: CsParameter; item: CsArrayType) =
  echo "in method add*(parent: CsParameter; item: CsArrayType)"
  parent.gotType = item

method add*(parent: CsArrayType; item: CsPredefinedType) =
  echo "in method add*(parent: CsArrayType; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsArrayType; item: CsArrayRankSpecifier) =
  echo "in method add*(parent: CsArrayType; item: CsArrayRankSpecifier)"
  parent.rankSpecifier = item

method add*(parent: CsArrayRankSpecifier; item: CsOmittedArraySizeExpression) =
  echo "in method add*(parent: CsArrayRankSpecifier; item: CsOmittedArraySizeExpression)"
  parent.omitted = item

method add*(parent: CsMemberAccessExpression; item: CsInvocationExpression) =
  echo "in method add*(parent: CsMemberAccessExpression; item: CsInvocationExpression)"
  if parent.left.isNil:
    parent.left = item
  elif parent.right.isNil:
    parent.right = item
  else: assert false
method add*(parent: CsMethod; item: CsArrowExpressionClause) =
  echo "in method add*(parent: CsMethod; item: CsArrowExpressionClause)"
  parent.body.add item

method add*(parent: CsArrowExpressionClause; item: CsInvocationExpression) =
  echo "in method add*(parent: CsArrowExpressionClause; item: CsInvocationExpression)"
  parent.body.add item

method add*(parent: CsArgument; item: CsSimpleLambdaExpression) =
  echo "in method add*(parent: CsArgument; item: CsSimpleLambdaExpression)"
  parent.expr = item

method add*(parent: CsSimpleLambdaExpression; item: CsParameter) =
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsParameter)"
  parent.params.add item

method add*(parent: CsMemberAccessExpression; item: CsGenericName) =
  echo "in method add*(parent: CsMemberAccessExpression; item: CsGenericName)"
  parent.genericName = item

method add*(parent: CsIfStatement; item: CsInvocationExpression) =
  echo "in method add*(parent: CsIfStatement; item: CsInvocationExpression)"
  parent.exprThatLeadsToBoolean = item

method add*(parent: CsMethod; item: CsForStatement) =
  echo "in method add*(parent: CsMethod; item: CsForStatement)"
  parent.body.add item

method add*(parent: CsForStatement; item: CsVariable) =
  echo "in method add*(parent: CsForStatement; item: CsVariable)"
  parent.forPart1var = item

method add*(parent: CsVariable; item: CsArrayType) =
  echo "in method add*(parent: CsVariable; item: CsArrayType)"
  parent.gotType = item

method add*(parent: CsEqualsValueClause; item: CsInitializerExpression) =
  echo "in method add*(parent: CsEqualsValueClause; item: CsInitializerExpression)"
  parent.rhsValue = item # TODO(add:CsEqualsValueClause, CsInitializerExpression)

method add*(parent: CsMethod; item: CsDoStatement) =
  echo "in method add*(parent: CsMethod; item: CsDoStatement)"
  parent.body.add item

method add*(parent: CsForStatement; item: CsBinaryExpression) =
  echo "in method add*(parent: CsForStatement; item: CsBinaryExpression)"
  parent.forPart2 = item

method add*(parent: CsForStatement; item: CsPostfixUnaryExpression) =
  echo "in method add*(parent: CsForStatement; item: CsPostfixUnaryExpression)"
  parent.forPart3 = item

method add*(parent: CsMemberAccessExpression; item: CsElementAccessExpression) =
  echo "in method add*(parent: CsMemberAccessExpression; item: CsElementAccessExpression)"
  if parent.left.isNil and parent.leftAsType.isNil:
    parent.left = item
  else:
    assert false # verify this is actually a usecase and not just imagined.
    # parent.right = item

method add*(parent: CsElementAccessExpression; item: CsBracketedArgumentList) =
  echo "in method add*(parent: CsElementAccessExpression; item: CsBracketedArgumentList)"
  parent.value = item
   # TODO(add:CsElementAccessExpression, CsBracketedArgumentList)

method add*(parent: CsBracketedArgumentList; item: CsArgument) =
  echo "in method add*(parent: CsBracketedArgumentList; item: CsArgument)"
  parent.args.add item

method add*(parent: CsBinaryExpression; item: CsInvocationExpression) =
  echo "in method add*(parent: CsBinaryExpression; item: CsInvocationExpression)"
  parent.left = item #TODO: why left and not right? check for nil first?

method add*(parent: CsSimpleBaseType; item: CsGenericName) =
  echo "in method add*(parent: CsSimpleBaseType; item: CsGenericName)"
  parent.genericName = item

method add*(parent: CsNameEquals; item: CsPrefixUnaryExpression) =
  echo "in method add*(parent: CsNameEquals; item: CsPrefixUnaryExpression)"
  # rhs can have such a thing.
  todoimplAdd()# TODO(add:CsNameEquals, CsPrefixUnaryExpression)

method add*(parent: CsAssignmentExpression; item: CsMemberAccessExpression) =
  echo "in method add*(parent: CsAssignmentExpression; item: CsMemberAccessExpression)"
  parent.left = item

method add*(parent: CsMemberAccessExpression; item: CsThisExpression) =
  echo "in method add*(parent: CsMemberAccessExpression; item: CsThisExpression)"
  parent.fromPart = "this"

method add*(parent: CsAssignmentExpression; item: CsLiteralExpression) =
  echo "in method add*(parent: CsAssignmentExpression; item: CsLiteralExpression)"
  parent.right = item

method add*(parent: CsMethod; item: CsWhileStatement) =
  echo "in method add*(parent: CsMethod; item: CsWhileStatement)"
  parent.body.add item

method add*(parent: CsWhileStatement; item: CsBinaryExpression) =
  echo "in method add*(parent: CsWhileStatement; item: CsBinaryExpression)"
  parent.predicate = item

method add*(parent: CsExpressionStatement; item: CsPostfixUnaryExpression) =
  echo "in method add*(parent: CsExpressionStatement; item: CsPostfixUnaryExpression)"
  parent.expr = item

# if (!b)
method add*(parent: CsIfStatement; item: CsPrefixUnaryExpression) =
  echo "in method add*(parent: CsIfStatement; item: CsPrefixUnaryExpression)"
  # in this example, it's in the predicate part (could it be in the body part as well?)
  if parent.predicate.isNil:
    parent.predicate = item
  else: assert false # add or fix based on other examples.

method add*(parent: CsPrefixUnaryExpression; item: CsInvocationExpression) =
  echo "in method add*(parent: CsPrefixUnaryExpression; item: CsInvocationExpression)"
  parent.actingOn = item

method add*(parent: CsBinaryExpression; item: CsParenthesizedExpression) =
  echo "in method add*(parent: CsBinaryExpression; item: CsParenthesizedExpression)"
  parent.left = item # TODO: check, maybe on the right sometimes? find by nil parts?

method add*(parent: CsParenthesizedExpression; item: CsBinaryExpression) =
  echo "in method add*(parent: CsParenthesizedExpression; item: CsBinaryExpression)"
  parent.body.add item

method add*(parent: CsArgument; item: CsInterpolatedStringExpression) =
  echo "in method add*(parent: CsArgument; item: CsInterpolatedStringExpression)"
  parent.expr = item

method add*(parent: CsMethod; item: CsArrayType) =
  echo "in method add*(parent: CsMethod; item: CsArrayType)"
  parent.gotType = item

method add*(parent: CsIfStatement; item: CsThrowStatement) =
  echo "in method add*(parent: CsIfStatement; item: CsThrowStatement)"
  parent.body.add item


method add*(parent: CsThrowStatement; item: CsObjectCreationExpression) =
  echo "in method add*(parent: CsThrowStatement; item: CsObjectCreationExpression)"
  parent.body.add item

method add*(parent: CsArgument; item: CsConditionalExpression) =
  echo "in method add*(parent: CsArgument; item: CsConditionalExpression)"
  parent.expr = item

method add*(parent: CsConditionalExpression; item: CsParenthesizedExpression) =
  echo "in method add*(parent: CsConditionalExpression; item: CsParenthesizedExpression)"
  if parent.hasNoPredicate:
    parent.exprThatLeadsToBoolean = item
  else:
    parent.addConditional(item)

method add*(parent: CsConditionalExpression; item: CsLiteralExpression) =
  echo "in method add*(parent: CsConditionalExpression; item: CsLiteralExpression)"
  if parent.hasNoPredicate:
    parent.predicatePartLit = item

method add*(parent: CsConditionalExpression; item: CsMemberAccessExpression) =
  echo "in method add*(parent: CsConditionalExpression; item: CsMemberAccessExpression)"
  if parent.hasNoPredicate:
    parent.exprThatLeadsToBoolean = item
  else:
    parent.addConditional item

method add*(parent: CsMemberAccessExpression; item: CsPredefinedType) =
  echo "in method add*(parent: CsMemberAccessExpression; item: CsPredefinedType)"
  parent.leftAsType = item

method add*(parent: CsEqualsValueClause; item: CsArrayCreationExpression) =
  echo "in method add*(parent: CsEqualsValueClause; item: CsArrayCreationExpression)"
  parent.rhsValue = item # TODO(add:CsEqualsValueClause, CsArrayCreationExpression)

method add*(parent: CsArrayCreationExpression; item: CsArrayType) =
  echo "in method add*(parent: CsArrayCreationExpression; item: CsArrayType)"
  parent.theType = item

method add*(parent: CsIfStatement; item: CsExpressionStatement) =
  echo "in method add*(parent: CsIfStatement; item: CsExpressionStatement)"
  parent.body.add item

method add*(parent: CsArrayCreationExpression; item: CsInitializerExpression) =
  echo "in method add*(parent: CsArrayCreationExpression; item: CsInitializerExpression)"
  parent.initializer = item

method add*(parent: CsInitializerExpression; item: CsArrayCreationExpression) =
  echo "in method add*(parent: CsInitializerExpression; item: CsArrayCreationExpression)"
  parent.bexprs.add item

method add*(parent: CsMethod; item: CsUsingStatement) =
  echo "in method add*(parent: CsMethod; item: CsUsingStatement)"
  parent.body.add item

method add*(parent: CsUsingStatement; item: CsVariable) =
  echo "in method add*(parent: CsUsingStatement; item: CsVariable)"
  parent.variable = item

method add*(parent: CsUsingStatement; item: CsUsingStatement) =
  echo "in method add*(parent: CsUsingStatement; item: CsUsingStatement)"
  parent.body.add item

method add*(parent: CsUsingStatement; item: CsExpressionStatement) =
  echo "in method add*(parent: CsUsingStatement; item: CsExpressionStatement)"
  parent.addToUsing item

# key = key.ToUpperInvariant();
method add*(parent: CsAssignmentExpression; item: CsInvocationExpression) =
  echo "in method add*(parent: CsAssignmentExpression; item: CsInvocationExpression)"
  parent.right = item

method add*(parent: CsArgument; item: CsParenthesizedLambdaExpression) =
  echo "in method add*(parent: CsArgument; item: CsParenthesizedLambdaExpression)"
  parent.expr = item

method add*(parent: CsParenthesizedLambdaExpression; item: CsParameterList) =
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsParameterList)"
  parent.paramList = item

method add*(parent: CsMethod; item: CsTryStatement) =
  echo "in method add*(parent: CsMethod; item: CsTryStatement)"
  parent.body.add item

method add*(parent: CsTryStatement; item: CsCatchClause) =
  echo "in method add*(parent: CsTryStatement; item: CsCatchClause)"
  parent.catches.add item

method add*(parent: CsCatchClause; item: CsCatch) =
  echo "in method add*(parent: CsCatchClause; item: CsCatch)"
  parent.what = item

# treeRootReference = treeRoot = null;
method add*(parent: CsAssignmentExpression; item: CsAssignmentExpression) =
  echo "in method add*(parent: CsAssignmentExpression; item: CsAssignmentExpression)"
  # what happens here is that we assign a few variables, according to the rightmost statement.
  parent.right = item
  # I don't think Nim supports that or probably the syntax is different. so needs special handling here, but that's an issue for gen part.

method add*(parent: CsInterpolatedStringExpression; item: CsInterpolatedStringText) =
  echo "in method add*(parent: CsInterpolatedStringExpression; item: CsInterpolatedStringText)"
  parent.textPart = item

method add*(parent: CsAccessor; item: CsReturnStatement) =
  echo "in method add*(parent: CsAccessor; item: CsReturnStatement)"
  parent.body.add item

method add*(parent: CsReturnStatement; item: CsElementAccessExpression) =
  echo "in method add*(parent: CsReturnStatement; item: CsElementAccessExpression)"
  parent.expr = item

method add*(parent: CsMethod; item: CsThrowStatement) =
  echo "in method add*(parent: CsMethod; item: CsThrowStatement)"
  parent.body.add item

method add*(parent: CsMethod; item: CsTypeParameterList) =
  echo "in method add*(parent: CsMethod; item: CsTypeParameterList)"
  parent.tpl = item

method add*(parent: CsReturnStatement; item: CsCastExpression) =
  echo "in method add*(parent: CsReturnStatement; item: CsCastExpression)"
  parent.expr = item

method add*(parent: CsReturnStatement; item: CsConditionalExpression) =
  echo "in method add*(parent: CsReturnStatement; item: CsConditionalExpression)"
  parent.expr = item

method add*(parent: CsProperty; item: CsArrayType) =
  echo "in method add*(parent: CsProperty; item: CsArrayType)"
  parent.gotType = item

method add*(parent: CsProperty; item: CsArrowExpressionClause) =
  echo "in method add*(parent: CsProperty; item: CsArrowExpressionClause)"
  parent.expressionBody = item

method add*(parent: CsProperty; item: CsEqualsValueClause) =
  echo "in method add*(parent: CsProperty; item: CsEqualsValueClause)"
  parent.initializer = item

method add*(parent: CsProperty; item: CsExplicitInterfaceSpecifier) =
  echo "in method add*(parent: CsProperty; item: CsExplicitInterfaceSpecifier)"
  parent.expl = item

method add*(parent: CsProperty; item: CsGenericName) =
  echo "in method add*(parent: CsProperty; item: CsGenericName)"
  parent.gotType = item

method add*(parent: CsProperty; item: CsLocalDeclarationStatement) =
  echo "in method add*(parent: CsProperty; item: CsLocalDeclarationStatement)"
  todoimplAdd()# TODO(add:CsProperty, CsLocalDeclarationStatement)

method add*(parent: CsAssignmentExpression; item: CsBinaryExpression) =
  echo "in method add*(parent: CsAssignmentExpression; item: CsBinaryExpression)"
  parent.right = item

method add*(parent: CsAssignmentExpression; item: CsInitializerExpression) =
  echo "in method add*(parent: CsAssignmentExpression; item: CsInitializerExpression)"
  parent.right = item

method add*(parent: CsAssignmentExpression; item: CsParenthesizedLambdaExpression) =
  echo "in method add*(parent: CsAssignmentExpression; item: CsParenthesizedLambdaExpression)"
  parent.addAssign(item)

method add*(parent: CsAssignmentExpression; item: CsSimpleLambdaExpression) =
  echo "in method add*(parent: CsAssignmentExpression; item: CsSimpleLambdaExpression)"
  parent.right = item

method add*(parent: CsAssignmentExpression; item: CsThisExpression) =
  echo "in method add*(parent: CsAssignmentExpression; item: CsThisExpression)"
  if parent.left.isNil: parent.left = item
  elif parent.right.isNil: parent.right = item
  else: assert false, "both sides are occupied, how can that be?"

method add*(parent: CsInitializerExpression; item: CsParenthesizedLambdaExpression) =
  echo "in method add*(parent: CsInitializerExpression; item: CsParenthesizedLambdaExpression)"
  parent.bexprs.add item

method add*(parent: CsEqualsValueClause; item: CsParenthesizedLambdaExpression) =
  echo "in method add*(parent: CsEqualsValueClause; item: CsParenthesizedLambdaExpression)"
  parent.rhsValue = item # TODO(add:CsEqualsValueClause, CsParenthesizedLambdaExpression)

method add*(parent: CsArgument; item: CsCastExpression) =
  echo "in method add*(parent: CsArgument; item: CsCastExpression)"
  parent.expr = item

method add*(parent: CsArgument; item: CsThisExpression) =
  echo "in method add*(parent: CsArgument; item: CsThisExpression)"
  parent.expr = item

method add*(parent: CsArgument; item: CsTypeOfExpression) =
  echo "in method add*(parent: CsArgument; item: CsTypeOfExpression)"
  parent.expr = item

method add*(parent: CsTypeArgumentList; item: CsArrayType) =
  echo "in method add*(parent: CsTypeArgumentList; item: CsArrayType)"
  parent.gotTypes.add item

method add*(parent: CsPrefixUnaryExpression; item: CsObjectCreationExpression) =
  echo "in method add*(parent: CsPrefixUnaryExpression; item: CsObjectCreationExpression)"
  parent.actingOn = item

method add*(parent: CsMemberAccessExpression; item: CsObjectCreationExpression) =
  echo "in method add*(parent: CsMemberAccessExpression; item: CsObjectCreationExpression)"
  parent.left = item

method add*(parent: CsMemberAccessExpression; item: CsParenthesizedExpression) =
  echo "in method add*(parent: CsMemberAccessExpression; item: CsParenthesizedExpression)"
  parent.left = item

method add*(parent: CsMemberAccessExpression; item: CsTypeOfExpression) =
  echo "in method add*(parent: CsMemberAccessExpression; item: CsTypeOfExpression)"
  parent.left = item

method add*(parent: CsBinaryExpression; item: CsCastExpression) =
  echo "in method add*(parent: CsBinaryExpression; item: CsCastExpression)"
  parent.left = item # TODO: by source was left, but why left? probably need to store where nil

# if (a ["s"] != 2)
method add*(parent: CsBinaryExpression; item: CsElementAccessExpression) =
  echo "in method add*(parent: CsBinaryExpression; item: CsElementAccessExpression)"
  parent.addBinExp(item)

method add*(parent: CsIfStatement; item: CsMemberAccessExpression) =
  echo "in method add*(parent: CsIfStatement; item: CsMemberAccessExpression)"
  parent.exprThatLeadsToBoolean = item

method add*(parent: CsIfStatement; item: CsReturnStatement) =
  echo "in method add*(parent: CsIfStatement; item: CsReturnStatement)"
  parent.body.add item

method add*(parent: CsCastExpression; item: CsParenthesizedExpression) =
  echo "in method add*(parent: CsCastExpression; item: CsParenthesizedExpression)"
  parent.expr = item

method add*(parent: CsArrowExpressionClause; item: CsBinaryExpression) =
  echo "in method add*(parent: CsArrowExpressionClause; item: CsBinaryExpression)"
  parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsAssignmentExpression) =
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsAssignmentExpression)"
  parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsBinaryExpression) =
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsBinaryExpression)"
  parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsInvocationExpression) =
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsInvocationExpression)"
  parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsMemberAccessExpression) =
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsMemberAccessExpression)"
  parent.body.add item

method add*(parent: CsForStatement; item: CsForStatement) =
  echo "in method add*(parent: CsForStatement; item: CsForStatement)"
  parent.body.add item

method add*(parent: CsForStatement; item: CsPrefixUnaryExpression) =
  echo "in method add*(parent: CsForStatement; item: CsPrefixUnaryExpression)"
  parent.forPart3prefix = item

method add*(parent: CsWhileStatement; item: CsExpressionStatement) =
  echo "in method add*(parent: CsWhileStatement; item: CsExpressionStatement)"
  parent.body.add item

method add*(parent: CsInterpolatedStringExpression; item: CsInterpolation) =
  echo "in method add*(parent: CsInterpolatedStringExpression; item: CsInterpolation)"
  parent.interpolated = item

method add*(parent: CsUsingStatement; item: CsMemberAccessExpression) =
  echo "in method add*(parent: CsUsingStatement; item: CsMemberAccessExpression)"
  parent.addToUsing item

method add*(parent: CsParenthesizedLambdaExpression; item: CsAssignmentExpression) =
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsAssignmentExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedLambdaExpression; item: CsConditionalExpression) =
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsConditionalExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedLambdaExpression; item: CsMemberAccessExpression) =
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsMemberAccessExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedLambdaExpression; item: CsObjectCreationExpression) =
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsObjectCreationExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedLambdaExpression; item: CsPostfixUnaryExpression) =
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsPostfixUnaryExpression)"
  parent.body.add item

method add*(parent: CsAccessor; item: CsArrowExpressionClause) =
  echo "in method add*(parent: CsAccessor; item: CsArrowExpressionClause)"
  parent.expressionBody = item

method add*(parent: CsAssignmentExpression; item: CsPrefixUnaryExpression) =
  echo "in method add*(parent: CsAssignmentExpression; item: CsPrefixUnaryExpression)"
  parent.right = item

method add*(parent: CsAssignmentExpression; item: CsArrayCreationExpression) =
  echo "in method add*(parent: CsAssignmentExpression; item: CsArrayCreationExpression)"
  parent.right = item

method add*(parent: CsInitializerExpression; item: CsInvocationExpression) =
  echo "in method add*(parent: CsInitializerExpression; item: CsInvocationExpression)"
  parent.bexprs.add item

method add*(parent: CsInvocationExpression; item: CsElementAccessExpression) =
  echo "in method add*(parent: CsInvocationExpression; item: CsElementAccessExpression)"
  if parent.invoker.isNil:
    parent.invoker = item
  else:
    parent.rhs = item

method add*(parent: CsEqualsValueClause; item: CsConditionalExpression) =
  echo "in method add*(parent: CsEqualsValueClause; item: CsConditionalExpression)"
  parent.rhsValue = item # TODO(add:CsEqualsValueClause, CsConditionalExpression)

method add*(parent: CsArgument; item: CsElementAccessExpression) =
  echo "in method add*(parent: CsArgument; item: CsElementAccessExpression)"
  parent.expr = item

method add*(parent: CsArgument; item: CsArrayCreationExpression) =
  echo "in method add*(parent: CsArgument; item: CsArrayCreationExpression)"
  parent.expr = item

method addBinExp(parent: CsBinaryExpression; item: BodyExpr) =
  echo "in addBinExp"
  # var stored:bool
  if parent.left.isNil:
    echo "storing in left side"
    parent.left = item
  elif parent.right.isNil:
    echo "storing in right side"
    parent.right = item
  else:
    echo "left and right were both occupied"

method add*(parent: CsBinaryExpression; item: CsPrefixUnaryExpression) =
  echo "in method add*(parent: CsBinaryExpression; item: CsPrefixUnaryExpression)"
  parent.addBinExp(item)

method add*(parent: CsBinaryExpression; item: CsObjectCreationExpression) =
  echo "in method add*(parent: CsBinaryExpression; item: CsObjectCreationExpression)"
  parent.addBinExp(item)

method add*(parent: CsCastExpression; item: CsPredefinedType) =
  echo "in method add*(parent: CsCastExpression; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsArrowExpressionClause; item: CsCastExpression) =
  echo "in method add*(parent: CsArrowExpressionClause; item: CsCastExpression)"
  parent.body.add item

method add*(parent: CsArrowExpressionClause; item: CsLiteralExpression) =
  echo "in method add*(parent: CsArrowExpressionClause; item: CsLiteralExpression)"
  parent.body.add  item

method add*(parent: CsForStatement; item: CsExpressionStatement) =
  echo "in method add*(parent: CsForStatement; item: CsExpressionStatement)"
  parent.body.add item

method add*(parent: CsElementAccessExpression; item: CsInvocationExpression) =
  echo "in method add*(parent: CsElementAccessExpression; item: CsInvocationExpression)"
  parent.lhs = item

method add*(parent: CsElementAccessExpression; item: CsMemberAccessExpression) =
  echo "in method add*(parent: CsElementAccessExpression; item: CsMemberAccessExpression)"
  if parent.lhs.isNil:
    parent.lhs = item
  # elif parent.rhs.isnil:
  #   parent.rhs = item
  else: assert false

method add*(parent: CsParenthesizedExpression; item: CsCastExpression) =
  echo "in method add*(parent: CsParenthesizedExpression; item: CsCastExpression)"
  parent.body.add item

method add*(parent: CsConditionalExpression; item: CsBinaryExpression) =
  echo "in method add*(parent: CsConditionalExpression; item: CsBinaryExpression)"
  parent.predicate = item

method add*(parent: CsParenthesizedLambdaExpression; item: CsInvocationExpression) =
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsInvocationExpression)"
  parent.body.add item

method add*(parent: CsConstructorInitializer; item: CsArgumentList) =
  echo "in method add*(parent: CsConstructorInitializer; item: CsArgumentList)"
  parent.args = item

method add*(parent: CsEqualsValueClause; item: CsPrefixUnaryExpression) =
  echo "in method add*(parent: CsEqualsValueClause; item: CsPrefixUnaryExpression)"
  parent.rhsValue = item # TODO(add:CsEqualsValueClause, CsPrefixUnaryExpression)

method add*(parent: CsEqualsValueClause; item: CsCastExpression) =
  echo "in method add*(parent: CsEqualsValueClause; item: CsCastExpression)"
  parent.rhsValue = item # TODO(add:CsEqualsValueClause, CsCastExpression)

method add*(parent: CsPrefixUnaryExpression; item: CsMemberAccessExpression) =
  echo "in method add*(parent: CsPrefixUnaryExpression; item: CsMemberAccessExpression)"
  parent.actingOn = item

method add*(parent: CsCastExpression; item: CsMemberAccessExpression) =
  echo "in method add*(parent: CsCastExpression; item: CsMemberAccessExpression)"
  parent.expr = item

method add*(parent: CsArrowExpressionClause; item: CsInterpolatedStringExpression) =
  echo "in method add*(parent: CsArrowExpressionClause; item: CsInterpolatedStringExpression)"
  parent.body.add item

method add*(parent: CsForStatement; item: CsAssignmentExpression) =
  echo "in method add*(parent: CsForStatement; item: CsAssignmentExpression)"
  parent.forPart1 = item

method add*(parent: CsParenthesizedExpression; item: CsConditionalExpression) =
  echo "in method add*(parent: CsParenthesizedExpression; item: CsConditionalExpression)"
  parent.body.add item

method add*(parent: CsConditionalExpression; item: CsCastExpression) =
  echo "in method add*(parent: CsConditionalExpression; item: CsCastExpression)"
  # cast is not a boolean expression, unless has a converter.
  # how do i know if in the true clause or false clause, or even in the predicate?
  # what is roslyn's order of operation here?
  if parent.hasNoPredicate:
    parent.exprThatLeadsToBoolean = item
  else: parent.addConditional(item)

method add*(parent: CsInterpolation; item: CsMemberAccessExpression) =
  echo "in method add*(parent: CsInterpolation; item: CsMemberAccessExpression)"
  parent.expr = item

method add*(parent: CsNamespace; item: CsMethod) =
  echo "in method add*(parent: CsNamespace; item: CsMethod)"
  todoimplAdd()# TODO(add:CsNamespace, CsMethod)

method add*(parent: CsMethod; item: CsExplicitInterfaceSpecifier) =
  echo "in method add*(parent: CsMethod; item: CsExplicitInterfaceSpecifier)"
  parent.explSpecifier = item

method add*(parent: CsMethod; item: CsTypeParameterConstraintClause) =
  echo "in method add*(parent: CsMethod; item: CsTypeParameterConstraintClause)"
  parent.typeParamConstraints = item

method add*(parent: CsEnum; item: CsBaseList) =
  echo "in method add*(parent: CsEnum; item: CsBaseList)"
  parent.underlyingType = item

method add*(parent: CsReturnStatement; item: CsTypeOfExpression) =
  echo "in method add*(parent: CsReturnStatement; item: CsTypeOfExpression)"
  parent.expr = item

method add*(parent: CsReturnStatement; item: CsThisExpression) =
  echo "in method add*(parent: CsReturnStatement; item: CsThisExpression)"
  parent.expr = item

method add*(parent: CsReturnStatement; item: CsSimpleLambdaExpression) =
  echo "in method add*(parent: CsReturnStatement; item: CsSimpleLambdaExpression)"
  parent.expr = item

method add*(parent: CsReturnStatement; item: CsPrefixUnaryExpression) =
  echo "in method add*(parent: CsReturnStatement; item: CsPrefixUnaryExpression)"
  parent.expr = item

method add*(parent: CsReturnStatement; item: CsParenthesizedLambdaExpression) =
  echo "in method add*(parent: CsReturnStatement; item: CsParenthesizedLambdaExpression)"
  parent.expr = item

method add*(parent: CsReturnStatement; item: CsParenthesizedExpression) =
  echo "in method add*(parent: CsReturnStatement; item: CsParenthesizedExpression)"
  parent.expr = item

method add*(parent: CsReturnStatement; item: CsArrayCreationExpression) =
  echo "in method add*(parent: CsReturnStatement; item: CsArrayCreationExpression)"
  parent.expr = item

method add*(parent: CsExpressionStatement; item: CsObjectCreationExpression) =
  echo "in method add*(parent: CsExpressionStatement; item: CsObjectCreationExpression)"
  parent.oce = item

method add*(parent: CsExpressionStatement; item: CsPrefixUnaryExpression) =
  echo "in method add*(parent: CsExpressionStatement; item: CsPrefixUnaryExpression)"
  parent.body.add item

method add*(parent: CsAssignmentExpression; item: CsConditionalExpression) =
  echo "in method add*(parent: CsAssignmentExpression; item: CsConditionalExpression)"
  parent.right = item

method addAssign(parent: CsAssignmentExpression; item: BodyExpr) =
  var stored:bool
  if parent.left.isNil:
    parent.left = item
    stored = true
  elif parent.right.isNil:
    parent.right = item # TODO: check can it be right side? store based on empty spot?
    stored = true
  assert stored

method add*(parent: CsAssignmentExpression; item: CsElementAccessExpression) =
  echo "in method add*(parent: CsAssignmentExpression; item: CsElementAccessExpression)"
  parent.addAssign(item)

method add*(parent: CsInitializerExpression; item: CsCastExpression) =
  echo "in method add*(parent: CsInitializerExpression; item: CsCastExpression)"
  parent.bexprs.add item

method add*(parent: CsEqualsValueClause; item: CsElementAccessExpression) =
  echo "in method add*(parent: CsEqualsValueClause; item: CsElementAccessExpression)"
  parent.rhsValue = item # TODO(add:CsEqualsValueClause, CsElementAccessExpression)

method add*(parent: CsEqualsValueClause; item: CsTypeOfExpression) =
  echo "in method add*(parent: CsEqualsValueClause; item: CsTypeOfExpression)"
  parent.rhsValue = item # TODO(add:CsEqualsValueClause, CsTypeOfExpression)

method add*(parent: CsEqualsValueClause; item: CsInterpolatedStringExpression) =
  echo "in method add*(parent: CsEqualsValueClause; item: CsInterpolatedStringExpression)"
  parent.rhsValue = item # TODO(add:CsEqualsValueClause, CsInterpolatedStringExpression)

method add*(parent: CsEqualsValueClause; item: CsSimpleLambdaExpression) =
  echo "in method add*(parent: CsEqualsValueClause; item: CsSimpleLambdaExpression)"
  parent.rhsValue = item # TODO(add:CsEqualsValueClause, CsSimpleLambdaExpression)

method add*(parent: CsArgument; item: CsParenthesizedExpression) =
  echo "in method add*(parent: CsArgument; item: CsParenthesizedExpression)"
  parent.expr = item

method add*(parent: CsPrefixUnaryExpression; item: CsParenthesizedExpression) =
  echo "in method add*(parent: CsPrefixUnaryExpression; item: CsParenthesizedExpression)"
  parent.actingOn = item

method add*(parent: CsBinaryExpression; item: CsGenericName) =
  echo "in method add*(parent: CsBinaryExpression; item: CsGenericName)"
  parent.right = item

method add*(parent: CsBinaryExpression; item: CsPredefinedType) =
  echo "in method add*(parent: CsBinaryExpression; item: CsPredefinedType)"
  parent.right = item

method add*(parent: CsIfStatement; item: CsBreakStatement) =
  echo "in method add*(parent: CsIfStatement; item: CsBreakStatement)"
  parent.body.add item

method add*(parent: CsCastExpression; item: CsArrayType) =
  echo "in method add*(parent: CsCastExpression; item: CsArrayType)"
  parent.gotType = item

method add*(parent: CsCastExpression; item: CsInvocationExpression) =
  echo "in method add*(parent: CsCastExpression; item: CsInvocationExpression)"
  parent.expr = item

method add*(parent: CsCastExpression; item: CsGenericName) =
  echo "in method add*(parent: CsCastExpression; item: CsGenericName)"
  parent.gotType = item

method add*(parent: CsCastExpression; item: CsLiteralExpression) =
  echo "in method add*(parent: CsCastExpression; item: CsLiteralExpression)"
  parent.expr = item

method add*(parent: CsArrayType; item: CsGenericName) =
  echo "in method add*(parent: CsArrayType; item: CsGenericName)"
  parent.gotType = item

method add*(parent: CsArrayRankSpecifier; item: CsBinaryExpression) =
  echo "in method add*(parent: CsArrayRankSpecifier; item: CsBinaryExpression)"
  parent.theRankValue = item

method add*(parent: CsArrayRankSpecifier; item: CsLiteralExpression) =
  echo "in method add*(parent: CsArrayRankSpecifier; item: CsLiteralExpression)"
  parent.theRankValue = item

method add*(parent: CsArrowExpressionClause; item: CsTypeOfExpression) =
  echo "in method add*(parent: CsArrowExpressionClause; item: CsTypeOfExpression)"
  parent.body.add item

method add*(parent: CsArrowExpressionClause; item: CsObjectCreationExpression) =
  echo "in method add*(parent: CsArrowExpressionClause; item: CsObjectCreationExpression)"
  parent.body.add item

method add*(parent: CsArrowExpressionClause; item: CsMemberAccessExpression) =
  echo "in method add*(parent: CsArrowExpressionClause; item: CsMemberAccessExpression)"
  parent.body.add item

method add*(parent: CsArrowExpressionClause; item: CsAssignmentExpression) =
  echo "in method add*(parent: CsArrowExpressionClause; item: CsAssignmentExpression)"
  parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsObjectCreationExpression) =
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsObjectCreationExpression)"
  parent.body.add item

# symbols[symbols.Count - 1][name] = value;
method add*(parent: CsElementAccessExpression; item: CsElementAccessExpression) =
  echo "in method add*(parent: CsElementAccessExpression; item: CsElementAccessExpression)"
  assert parent.lhs.isNil # TODO: always on the left?
  parent.lhs = item

method add*(parent: CsWhileStatement; item: CsInvocationExpression) =
  echo "in method add*(parent: CsWhileStatement; item: CsInvocationExpression)"
  if parent.hasNoPredicate:
    parent.exprThatLeadsToBoolean = item
  else: parent.body.add item

method add*(parent: CsParenthesizedExpression; item: CsPrefixUnaryExpression) =
  echo "in method add*(parent: CsParenthesizedExpression; item: CsPrefixUnaryExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedExpression; item: CsPostfixUnaryExpression) =
  echo "in method add*(parent: CsParenthesizedExpression; item: CsPostfixUnaryExpression)"
  todoimplAdd()# TODO(add:CsParenthesizedExpression, CsPostfixUnaryExpression)

method add*(parent: CsParenthesizedExpression; item: CsParenthesizedLambdaExpression) =
  echo "in method add*(parent: CsParenthesizedExpression; item: CsParenthesizedLambdaExpression)"
  todoimplAdd()# TODO(add:CsParenthesizedExpression, CsParenthesizedLambdaExpression)

method add*(parent: CsParenthesizedExpression; item: CsMemberAccessExpression) =
  echo "in method add*(parent: CsParenthesizedExpression; item: CsMemberAccessExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedExpression; item: CsInvocationExpression) =
  echo "in method add*(parent: CsParenthesizedExpression; item: CsInvocationExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedExpression; item: BodyExpr) =
  echo "in general add for CsParenthesizedExpression"
  parent.body.add item

method add*(parent: CsParenthesizedExpression; item: CsAssignmentExpression) =
  echo "in method add*(parent: CsParenthesizedExpression; item: CsAssignmentExpression)"
  parent.body.add item

method add*(parent: CsConditionalExpression; item: CsInvocationExpression) =
  echo "in method add*(parent: CsConditionalExpression; item: CsInvocationExpression)"
  echo "pcond",parent.condTxt
  echo "itemsrc",item.src
  # assert false
  if parent.condTxt.contains item.src:
    parent.exprThatLeadsToBoolean = item
  else:
    parent.addConditional(item)

method add*(parent: CsAssignmentExpression; item: CsInterpolatedStringExpression) =
  echo "in method add*(parent: CsAssignmentExpression; item: CsInterpolatedStringExpression)"
  parent.right = item

method add*(parent: CsInitializerExpression; item: CsTypeOfExpression) =
  echo "in method add*(parent: CsInitializerExpression; item: CsTypeOfExpression)"
  parent.bexprs.add item

method add*(parent: CsLiteralExpression; item: CsBinaryExpression) =
  echo "in method add*(parent: CsLiteralExpression; item: CsBinaryExpression)"
  todoimplAdd()# TODO(add: CsLiteralExpression, CsBinaryExpression)

method add*(parent: CsEqualsValueClause; item: CsParenthesizedExpression) =
  echo "in method add*(parent: CsEqualsValueClause; item: CsParenthesizedExpression)"
  parent.rhsValue = item # TODO(add: CsEqualsValueClause, CsParenthesizedExpression)

method add*(parent: CsMemberAccessExpression; item: CsLiteralExpression) =
  echo "in method add*(parent: CsMemberAccessExpression; item: CsLiteralExpression)"
  parent.left = item

method add*(parent: CsCastExpression; item: CsObjectCreationExpression) =
  echo "in method add*(parent: CsCastExpression; item: CsObjectCreationExpression)"
  parent.expr = item

method add*(parent: CsCastExpression; item: CsElementAccessExpression) =
  echo "in method add*(parent: CsCastExpression; item: CsElementAccessExpression)"
  parent.expr = item

method add*(parent: CsCastExpression; item: CsCastExpression) =
  echo "in method add*(parent: CsCastExpression; item: CsCastExpression)"
  parent.expr = item

method add*(parent: CsArrayRankSpecifier; item: CsMemberAccessExpression) =
  echo "in method add*(parent: CsArrayRankSpecifier; item: CsMemberAccessExpression)"
  parent.theRankValue = item

method add*(parent: CsSimpleLambdaExpression; item: CsConditionalExpression) =
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsConditionalExpression)"
  parent.body.add item

method add*(parent: CsWhileStatement; item: CsLiteralExpression) =
  echo "in method add*(parent: CsWhileStatement; item: CsLiteralExpression)"
  # if the literal expression is true or false
  assert item.value in ["true","false"]
  parent.predicatePartLit = item

method add*(parent: CsConditionalExpression; item: CsObjectCreationExpression) =
  echo "in method add*(parent: CsConditionalExpression; item: CsObjectCreationExpression)"
  parent.addConditional(item)

method add*(parent: CsConditionalExpression; item: CsPrefixUnaryExpression) =
  echo "in method add*(parent: CsConditionalExpression; item: CsPrefixUnaryExpression)"
  if parent.hasNoPredicate:
    parent.predicate = item
  else:
    parent.addConditional(item)

method add*(parent: CsParenthesizedLambdaExpression; item: CsBinaryExpression) =
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsBinaryExpression)"
  parent.body.add item

method add*(parent: CsNamespace; item: CsExternAliasDirective) =
  echo "in method add*(parent: CsNamespace; item: CsExternAliasDirective)"
  todoimplAdd()# TODO(add: CsNamespace, CsExternAliasDirective)

method add*(parent: CsMethod; item: CsCastExpression) =
  echo "in method add*(parent: CsMethod; item: CsCastExpression)"
  todoimplAdd()# TODO(add: CsMethod, CsCastExpression)

method add*(parent: CsReturnStatement; item: CsPostfixUnaryExpression) =
  echo "in method add*(parent: CsReturnStatement; item: CsPostfixUnaryExpression)"
  parent.expr = item

method add*(parent: CsConstructor; item: CsArrowExpressionClause) =
  echo "in method add*(parent: CsConstructor; item: CsArrowExpressionClause)"
  parent.body.add item

method add*(parent: CsAssignmentExpression; item: CsParenthesizedExpression) =
  echo "in method add*(parent: CsAssignmentExpression; item: CsParenthesizedExpression)"
  parent.right = item

method add*(parent: CsInitializerExpression; item: CsBinaryExpression) =
  echo "in method add*(parent: CsInitializerExpression; item: CsBinaryExpression)"
  parent.bexprs.add item

method add*(parent: CsInvocationExpression; item: CsInvocationExpression) =
  echo "in method add*(parent: CsInvocationExpression; item: CsInvocationExpression)"
  parent.rhs = item

method add*(parent: CsInvocationExpression; item: CsLiteralExpression) =
  echo "in method add*(parent: CsInvocationExpression; item: CsLiteralExpression)"
  parent.rhs = item #?? not sure here.

method add*(parent: CsEqualsValueClause; item: CsAssignmentExpression) =
  echo "in method add*(parent: CsEqualsValueClause; item: CsAssignmentExpression)"
  parent.rhsValue = item # TODO(add: CsEqualsValueClause, CsAssignmentExpression)

method add*(parent: CsArgument; item: CsPostfixUnaryExpression) =
  echo "in method add*(parent: CsArgument; item: CsPostfixUnaryExpression)"
  parent.expr = item

method add*(parent: CsPrefixUnaryExpression; item: CsCastExpression) =
  echo "in method add*(parent: CsPrefixUnaryExpression; item: CsCastExpression)"
  parent.actingOn = item

method add*(parent: CsMemberAccessExpression; item: CsArrayCreationExpression) =
  echo "in method add*(parent: CsMemberAccessExpression; item: CsArrayCreationExpression)"
  parent.left = item

method add*(parent: CsBinaryExpression; item: CsArrayType) =
  echo "in method add*(parent: CsBinaryExpression; item: CsArrayType)"
  parent.right = item #TODO: is it always this way?

# => "p" + _count++;
method add*(parent: CsBinaryExpression; item: CsPostfixUnaryExpression) =
  echo "in method add*(parent: CsBinaryExpression; item: CsPostfixUnaryExpression)"
  parent.addBinExp(item)

method add*(parent: CsBinaryExpression; item: CsThisExpression) =
  echo "in method add*(parent: CsBinaryExpression; item: CsThisExpression)"
  parent.addBinExp(item)

method add*(parent: CsIfStatement; item: CsConditionalExpression) =
  echo "in method add*(parent: CsIfStatement; item: CsConditionalExpression)"
  parent.exprThatLeadsToBoolean = item

method add*(parent: CsIfStatement; item: CsIfStatement) =
  echo "in method add*(parent: CsIfStatement; item: CsIfStatement)"
  parent.body.add item

method add*(parent: CsIfStatement; item: CsLiteralExpression) =
  echo "in method add*(parent: CsIfStatement; item: CsLiteralExpression)"
  assert item.value in ["true","false"]
  parent.predicatePartLit = item

method add*(parent: CsIfStatement; item: CsParenthesizedExpression) =
  echo "in method add*(parent: CsIfStatement; item: CsParenthesizedExpression)"
  if parent.hasNoPredicate:
    parent.exprThatLeadsToBoolean = item
  else: parent.body.add item

method add*(parent: CsCastExpression; item: CsPrefixUnaryExpression) =
  echo "in method add*(parent: CsCastExpression; item: CsPrefixUnaryExpression)"
  parent.expr = item

method add*(parent: CsArrowExpressionClause; item: CsParenthesizedLambdaExpression) =
  echo "in method add*(parent: CsArrowExpressionClause; item: CsParenthesizedLambdaExpression)"
  parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsLiteralExpression) =
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsLiteralExpression)"
  parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsParenthesizedExpression) =
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsParenthesizedExpression)"
  parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsPrefixUnaryExpression) =
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsPrefixUnaryExpression)"
  parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsSimpleLambdaExpression) =
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsSimpleLambdaExpression)"
  parent.body.add item

method add*(parent: CsForStatement; item: CsIfStatement) =
  echo "in method add*(parent: CsForStatement; item: CsIfStatement)"
  parent.body.add item

method add*(parent: CsElementAccessExpression; item: CsObjectCreationExpression) =
  echo "in method add*(parent: CsElementAccessExpression; item: CsObjectCreationExpression)"
  parent.lhs = item

method add*(parent: CsElementAccessExpression; item: CsThisExpression) =
  echo "in method add*(parent: CsElementAccessExpression; item: CsThisExpression)"
  parent.lhs = item

method add*(parent: CsSimpleBaseType; item: CsPredefinedType) =
  echo "in method add*(parent: CsSimpleBaseType; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsParenthesizedExpression; item: CsArrayCreationExpression) =
  echo "in method add*(parent: CsParenthesizedExpression; item: CsArrayCreationExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedExpression; item: CsLiteralExpression) =
  echo "in method add*(parent: CsParenthesizedExpression; item: CsLiteralExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedExpression; item: CsObjectCreationExpression) =
  echo "in method add*(parent: CsParenthesizedExpression; item: CsObjectCreationExpression)"
  parent.body.add item

method add*(parent: CsThrowStatement; item: CsLiteralExpression) =
  echo "in method add*(parent: CsThrowStatement; item: CsLiteralExpression)"
  parent.body.add item


method add*(parent: CsConditionalExpression; item: CsInterpolatedStringExpression) =
  echo "in method add*(parent: CsConditionalExpression; item: CsInterpolatedStringExpression)"
  parent.addConditional(item)

method add*(parent: CsConditionalExpression; item: CsTypeOfExpression) =
  echo "in method add*(parent: CsConditionalExpression; item: CsTypeOfExpression)"
  parent.addConditional(item)

method add*(parent: CsUsingStatement; item: CsCastExpression) =
  echo "in method add*(parent: CsUsingStatement; item: CsCastExpression)"
  parent.addToUsing item

method add*(parent: CsUsingStatement; item: CsAssignmentExpression) =
  echo "in method add*(parent: CsUsingStatement; item: CsAssignmentExpression)"
  parent.addToUsing item

method add*(parent: CsUsingStatement; item: CsIfStatement) =
  echo "in method add*(parent: CsUsingStatement; item: CsIfStatement)"
  parent.body.add item

method add*(parent: CsParenthesizedLambdaExpression; item: CsParenthesizedLambdaExpression) =
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsParenthesizedLambdaExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedLambdaExpression; item: CsLiteralExpression) =
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsLiteralExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedLambdaExpression; item: CsCastExpression) =
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsCastExpression)"
  parent.body.add item

method add*(parent: CsInterpolation; item: CsPrefixUnaryExpression) =
  echo "in method add*(parent: CsInterpolation; item: CsPrefixUnaryExpression)"
  parent.expr = item

method add*(parent: CsInterpolation; item: CsLiteralExpression) =
  echo "in method add*(parent: CsInterpolation; item: CsLiteralExpression)"
  parent.expr = item

method add*(parent: CsInterpolation; item: CsBinaryExpression) =
  echo "in method add*(parent: CsInterpolation; item: CsBinaryExpression)"
  parent.expr = item

method add*(parent: CsPostfixUnaryExpression; item: CsMemberAccessExpression) =
  echo "in method add*(parent: CsPostfixUnaryExpression; item: CsMemberAccessExpression)"
  parent.actingOn = item

method add*(parent: CsTypeOfExpression; item: CsPredefinedType) =
  echo "in method add*(parent: CsTypeOfExpression; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsTypeOfExpression; item: CsGenericName) =
  echo "in method add*(parent: CsTypeOfExpression; item: CsGenericName)"
  parent.gotType = item

method add*(parent: CsTypeOfExpression; item: CsArrayType) =
  echo "in method add*(parent: CsTypeOfExpression; item: CsArrayType)"
  parent.gotType = item

method add*(parent: CsParenthesizedExpression; item: CsSimpleLambdaExpression) =
  echo "in method add*(parent: CsParenthesizedExpression; item: CsSimpleLambdaExpression)"
  todoimplAdd()# TODO(add: CsParenthesizedExpression, CsSimpleLambdaExpression)

method add*(parent: CsExplicitInterfaceSpecifier; item: CsGenericName) =
  echo "in method add*(parent: CsExplicitInterfaceSpecifier; item: CsGenericName)"
  parent.genericName = item

method add*(parent: CsPredefinedType; item: CsGenericName) =
  echo "in method add*(parent: CsPredefinedType; item: CsGenericName)"
  todoimplAdd()# TODO(add: CsPredefinedType, CsGenericName)

method add*(parent: CsInitializerExpression; item: CsSimpleLambdaExpression) =
  echo "in method add*(parent: CsInitializerExpression; item: CsSimpleLambdaExpression)"
  parent.bexprs.add item

method add*(parent: CsIfStatement; item: CsElementAccessExpression) =
  echo "in method add*(parent: CsIfStatement; item: CsElementAccessExpression)"
  if parent.hasNoPredicate:
    parent.exprThatLeadsToBoolean = item
  else:
    parent.body.add item

method add*(parent: CsElementAccessExpression; item: CsParenthesizedExpression) =
  echo "in method add*(parent: CsElementAccessExpression; item: CsParenthesizedExpression)"
  parent.lhs = item

method add*(parent: CsParenthesizedLambdaExpression; item: CsTypeOfExpression) =
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsTypeOfExpression)"
  parent.body.add item

method add*(parent: CsPostfixUnaryExpression; item: CsElementAccessExpression) =
  echo "in method add*(parent: CsPostfixUnaryExpression; item: CsElementAccessExpression)"
  parent.actingOn = item

method add*(parent: CsPostfixUnaryExpression; item: CsInvocationExpression) =
  echo "in method add*(parent: CsPostfixUnaryExpression; item: CsInvocationExpression)"
  parent.actingOn = item

method add*(parent: CsReturnStatement; item: CsInterpolatedStringExpression) =
  echo "in method add*(parent: CsReturnStatement; item: CsInterpolatedStringExpression)"
  parent.expr = item

method add*(parent: CsConstructor; item: CsReturnStatement) =
  echo "in method add*(parent: CsConstructor; item: CsReturnStatement)"
  parent.body.add item

method add*(parent: CsExpressionStatement; item: CsLiteralExpression) =
  echo "in method add*(parent: CsExpressionStatement; item: CsLiteralExpression)"
  # I think it's a roslyn mistake, encountered with go2cs converted examples. not sure that code even compiles. maybe a newer roslyn version would know better.
  # assert false # how should that work?? is there an example? is it a literal argument?
  # todoimplAdd()# TODO(add: CsExpressionStatement, CsLiteralExpression)
  parent.expr = item
  echo "Possible bug here, please review the C# source - does it compile?"


method add*(parent: CsInitializerExpression; item: CsConditionalExpression) =
  echo "in method add*(parent: CsInitializerExpression; item: CsConditionalExpression)"
  todoimplAdd()# TODO(add: CsInitializerExpression, CsConditionalExpression)

method add*(parent: CsMemberAccessExpression; item: CsInterpolatedStringExpression) =
  echo "in method add*(parent: CsMemberAccessExpression; item: CsInterpolatedStringExpression)"
  todoimplAdd()# TODO(add: CsMemberAccessExpression, CsInterpolatedStringExpression)

method add*(parent: CsArrowExpressionClause; item: CsArrayCreationExpression) =
  echo "in method add*(parent: CsArrowExpressionClause; item: CsArrayCreationExpression)"
  parent.body.add item

method add*(parent: CsArrowExpressionClause; item: CsConditionalExpression) =
  echo "in method add*(parent: CsArrowExpressionClause; item: CsConditionalExpression)"
  parent.body.add item

method add*(parent: CsWhileStatement; item: CsPrefixUnaryExpression) =
  echo "in method add*(parent: CsWhileStatement; item: CsPrefixUnaryExpression)"
  if parent.hasNoPredicate:
    parent.exprThatLeadsToBoolean = item
  else: #add to body
    parent.body.add item

method add*(parent: CsConditionalExpression; item: CsThisExpression) =
  echo "in method add*(parent: CsConditionalExpression; item: CsThisExpression)"
  parent.addConditional(item)

method add*(parent: CsUsingStatement; item: CsInvocationExpression) =
  echo "in method add*(parent: CsUsingStatement; item: CsInvocationExpression)"
  parent.addToUsing item

method add*(parent: CsParenthesizedLambdaExpression; item: CsPrefixUnaryExpression) =
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsPrefixUnaryExpression)"
  parent.body.add item

method add*(parent: CsInterpolation; item: CsInvocationExpression) =
  echo "in method add*(parent: CsInterpolation; item: CsInvocationExpression)"
  parent.expr = item

method add*(parent: CsNamespace; item: CsDelegate) =
  echo "in method add*(parent: CsNamespace; item: CsDelegate)"
  parent.delegates.add item
  item.ns = parent

method add*(parent: CsExpressionStatement; item: CsBinaryExpression) = # BE
  echo "in method add*(parent: CsExpressionStatement; item: CsBinaryExpression)"
  parent.expr = item

method add*(parent: CsAssignmentExpression; item: CsTypeOfExpression) = # TOE
  echo "in method add*(parent: CsAssignmentExpression; item: CsTypeOfExpression)"
  parent.right = item

method add*(parent: CsInitializerExpression; item: CsInterpolatedStringExpression) = # ISE
  echo "in method add*(parent: CsInitializerExpression; item: CsInterpolatedStringExpression)"
  parent.bexprs.add item

method add*(parent: CsCastExpression; item: CsArrayCreationExpression) = # ACE
  echo "in method add*(parent: CsCastExpression; item: CsArrayCreationExpression)"
  parent.expr = item

method add*(parent: CsArrowExpressionClause; item: CsSimpleLambdaExpression) = # SLE
  echo "in method add*(parent: CsArrowExpressionClause; item: CsSimpleLambdaExpression)"
  parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsCastExpression) = # CE
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsCastExpression)"
  parent.body.add item

method add*(parent: CsThrowStatement; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsThrowStatement; item: CsInvocationExpression)"
  parent.body.add item

method add*(parent: CsConditionalExpression; item: CsAssignmentExpression) = # AE
  echo "in method add*(parent: CsConditionalExpression; item: CsAssignmentExpression)"
  parent.addConditional(item)

method add*(parent: CsUsingStatement; item: CsObjectCreationExpression) = # OCE
  echo "in method add*(parent: CsUsingStatement; item: CsObjectCreationExpression)"
  parent.addToUsing item

method add*(parent: CsParenthesizedLambdaExpression; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsElementAccessExpression)"
  parent.body.add item

method add*(parent: CsNamespace; item: CsInterface) =
  echo "in method add*(parent: CsNamespace; item: CsInterface)"
  parent.interfaces.add item
  item.ns = parent


method add*(parent: CsNamespace; item: CsProperty) =
  echo "in method add*(parent: CsNamespace; item: CsProperty)"
  todoimplAdd() # TODO(add: CsNamespace, CsProperty)

method add*(parent: CsNamespace; item: CsStruct) =
  echo "in method add*(parent: CsNamespace; item: CsStruct)"
  parent.structs.add item
  item.ns = parent

method add*(parent: CsClass; item: CsInterface) =
  echo "in method add*(parent: CsClass; item: CsInterface)"
  # forwarding to namespace
  forward(parent,item) # takes care of setting a namespace (the default/global one) if there isn't any.

method add*(parent: CsClass; item: CsStruct) = #Forwards to NS but changes the struct name
  echo "in method add*(parent: CsClass; item: CsStruct)"
  item.name = parent.name & "." & item.name
  if parent.ns.isnil:
    parent.ns = currentRoot.global
  assert not parent.ns.isnil
  parent.ns.add item

method add*(parent: CsMethod; item: CsYieldStatement) = # YS
  echo "in method add*(parent: CsMethod; item: CsYieldStatement)"
  parent.body.add item

method add*(parent: CsMethod; item: CsTupleType) = # TT
  echo "in method add*(parent: CsMethod; item: CsTupleType)"
  parent.gotType = item

method add*(parent: CsMethod; item: CsSwitchStatement) = # SS
  echo "in method add*(parent: CsMethod; item: CsSwitchStatement)"
  parent.body.add item

method add*(parent: CsMethod; item: CsNullableType) = # NT
  echo "in method add*(parent: CsMethod; item: CsNullableType)"
  parent.gotType = item

method add*(parent: CsMethod; item: CsLockStatement) = # LS
  echo "in method add*(parent: CsMethod; item: CsLockStatement)"
  parent.body.add item

method add*(parent: CsMethod; item: CsForEachStatement) = # FES
  echo "in method add*(parent: CsMethod; item: CsForEachStatement)"
  parent.body.add item

method add*(parent: CsReturnStatement; item: CsImplicitArrayCreationExpression) = # IACE
  echo "in method add*(parent: CsReturnStatement; item: CsImplicitArrayCreationExpression)"
  parent.expr = item

method add*(parent: CsProperty; item: CsNullableType) = # NT
  echo "in method add*(parent: CsProperty; item: CsNullableType)"
  parent.nulType = item

method add*(parent: CsExpressionStatement; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsExpressionStatement; item: CsAwaitExpression)"
  parent.expr = item

method add*(parent: CsExpressionStatement; item: CsConditionalAccessExpression) = # CAE
  echo "in method add*(parent: CsExpressionStatement; item: CsConditionalAccessExpression)"
  parent.expr = item

method add*(parent: CsAssignmentExpression; item: CsConditionalAccessExpression) = # CAE
  echo "in method add*(parent: CsAssignmentExpression; item: CsConditionalAccessExpression)"
  parent.right = item

method add*(parent: CsAssignmentExpression; item: CsDeclarationExpression) = # DE
  echo "in method add*(parent: CsAssignmentExpression; item: CsDeclarationExpression)"
  parent.left = item

method add*(parent: CsAssignmentExpression; item: CsImplicitElementAccess) = # IEA
  echo "in method add*(parent: CsAssignmentExpression; item: CsImplicitElementAccess)"
  addAssign(parent,item)

method add*(parent: CsVariable; item: CsNullableType) = # NT
  echo "in method add*(parent: CsVariable; item: CsNullableType)"
  parent.gotType = item

method add*(parent: CsVariable; item: CsPointerType) = # PT
  echo "in method add*(parent: CsVariable; item: CsPointerType)"
  parent.gotType = item


method add*(parent: CsVariable; item: CsRefType) = # RT
  echo "in method add*(parent: CsVariable; item: CsRefType)"
  parent.gotType = item

method add*(parent: CsParameter; item: CsNullableType) = # NT
  echo "in method add*(parent: CsParameter; item: CsNullableType)"
  parent.gotType = item

method add*(parent: CsEqualsValueClause; item: CsImplicitArrayCreationExpression) = # IACE
  echo "in method add*(parent: CsEqualsValueClause; item: CsImplicitArrayCreationExpression)"
  parent.rhsValue = item

method add*(parent: CsEqualsValueClause; item: CsConditionalAccessExpression) = # CAE
  echo "in method add*(parent: CsEqualsValueClause; item: CsConditionalAccessExpression)"
  parent.rhsValue = item

method add*(parent: CsEqualsValueClause; item: CsCheckedExpression) = # CE
  echo "in method add*(parent: CsEqualsValueClause; item: CsCheckedExpression)"
  parent.rhsValue = item

method add*(parent: CsEqualsValueClause; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsEqualsValueClause; item: CsAwaitExpression)"
  parent.rhsValue = item

method add*(parent: CsEqualsValueClause; item: CsAnonymousMethodExpression) = # AME
  echo "in method add*(parent: CsEqualsValueClause; item: CsAnonymousMethodExpression)"
  parent.rhsValue = item

method add*(parent: CsArgument; item: CsNameColon) = # NC
  echo "in method add*(parent: CsArgument; item: CsNameColon)"
  parent.expr = item

method add*(parent: CsArgument; item: CsImplicitArrayCreationExpression) = # IACE
  echo "in method add*(parent: CsArgument; item: CsImplicitArrayCreationExpression)"
  parent.expr = item

method add*(parent: CsArgument; item: CsDefaultExpression) = # DE
  echo "in method add*(parent: CsArgument; item: CsDefaultExpression)"
  parent.expr = item

method add*(parent: CsArgument; item: CsDeclarationExpression) = # DE
  echo "in method add*(parent: CsArgument; item: CsDeclarationExpression)"
  parent.expr = item

method add*(parent: CsArgument; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsArgument; item: CsAwaitExpression)"
  parent.expr = item

method add*(parent: CsArgument; item: CsAnonymousObjectCreationExpression) = # AOCE
  echo "in method add*(parent: CsArgument; item: CsAnonymousObjectCreationExpression)"
  parent.expr = item

# method add*(parent: CsTypeArgumentList; item: CsTupleType) = # TT
#   echo "in method add*(parent: CsTypeArgumentList; item: CsTupleType)"
#   parent.gotTypes.add item

method add*(parent: CsMemberAccessExpression; item: CsBaseExpression) = # BE
  echo "in method add*(parent: CsMemberAccessExpression; item: CsBaseExpression)"
  parent.left = item

method add*(parent: CsBinaryExpression; item: CsCheckedExpression) = # CE
  echo "in method add*(parent: CsBinaryExpression; item: CsCheckedExpression)"
  parent.addBinExp(item)

method add*(parent: CsBinaryExpression; item: CsConditionalAccessExpression) = # CAE
  echo "in method add*(parent: CsBinaryExpression; item: CsConditionalAccessExpression)"
  parent.left = item  # TODO: check this.

method add*(parent: CsIfStatement; item: CsThrowExpression) = # TE
  echo "in method add*(parent: CsIfStatement; item: CsThrowExpression)"
  todoimplAdd() # TODO(add: CsIfStatement, CsThrowExpression)

method add*(parent: CsIfStatement; item: CsElseClause) = # EC
  echo "in method add*(parent: CsIfStatement; item: CsElseClause)"
  parent.melse = item

method add*(parent: CsIfStatement; item: CsIsPatternExpression) = # IPE
  echo "in method add*(parent: CsIfStatement; item: CsIsPatternExpression)"
  parent.predicate = item

method add*(parent: CsIfStatement; item: CsYieldStatement) = # YS
  echo "in method add*(parent: CsIfStatement; item: CsYieldStatement)"
  parent.body.add item

method add*(parent: CsCastExpression; item: CsNullableType) = # NT
  echo "in method add*(parent: CsCastExpression; item: CsNullableType)"
  parent.gotType = item

method add*(parent: CsArrowExpressionClause; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsArrowExpressionClause; item: CsElementAccessExpression)"
  parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsAnonymousObjectCreationExpression) = # AOCE
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsAnonymousObjectCreationExpression)"
  parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsQueryExpression) = # QE
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsQueryExpression)"
  parent.body.add item

method add*(parent: CsElementAccessExpression; item: CsBaseExpression) = # BE
  echo "in method add*(parent: CsElementAccessExpression; item: CsBaseExpression)"
  parent.lhs = item

method add*(parent: CsParenthesizedExpression; item: CsIsPatternExpression) = # IPE
  echo "in method add*(parent: CsParenthesizedExpression; item: CsIsPatternExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedExpression; item: CsQueryExpression) = # QE
  echo "in method add*(parent: CsParenthesizedExpression; item: CsQueryExpression)"
  parent.body.add item

method add*(parent: CsTryStatement; item: CsFinallyClause) = # FC
  echo "in method add*(parent: CsTryStatement; item: CsFinallyClause)"
  parent.mfinally = item

method add*(parent: CsInterpolation; item: CsCastExpression) = # CE
  echo "in method add*(parent: CsInterpolation; item: CsCastExpression)"
  parent.expr = item

method add*(parent: CsDoStatement; item: CsBinaryExpression) = # BE
  echo "in method add*(parent: CsDoStatement; item: CsBinaryExpression)"
  parent.predicate = item

method add*(parent: CsQueryExpression; item: CsQueryBody) = # QB
  echo "in method add*(parent: CsQueryExpression; item: CsQueryBody)"
  parent.queryBody = item

method add*(parent: CsBinaryExpression; item: CsIsPatternExpression) = # IPE
  echo "in method add*(parent: CsBinaryExpression; item: CsIsPatternExpression)"
  parent.addBinExp item

method add*(parent: CsBinaryExpression; item: CsThrowExpression) = # TE
  echo "in method add*(parent: CsBinaryExpression; item: CsThrowExpression)"
  parent.right = item

method add*(parent: CsInterface; item: CsBaseList) = # BL
  echo "in method add*(parent: CsInterface; item: CsBaseList)"
  parent.extends = item

method add*(parent: CsInterface; item: CsMethod) =
  echo "in method add*(parent: CsInterface; item: CsMethod)"
  parent.methods.add item

method add*(parent: CsInterface; item: CsTypeParameterList) = # TPL
  echo "in method add*(parent: CsInterface; item: CsTypeParameterList)"
  parent.typeParams = item

method add*(parent: CsInterpolation; item: CsInterpolationFormatClause) = # IFC
  echo "in method add*(parent: CsInterpolation; item: CsInterpolationFormatClause)"
  parent.format = item

method add*(parent: CsPostfixUnaryExpression; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsPostfixUnaryExpression; item: CsLiteralExpression)"
  parent.actingOn = item

method add*(parent: CsParameter; item: CsPointerType) = # PT
  echo "in method add*(parent: CsParameter; item: CsPointerType)"
  parent.gotType = item

method add*(parent: CsDeclarationExpression; item: CsSingleVariableDesignation) = # SVD
  echo "in method add*(parent: CsDeclarationExpression; item: CsSingleVariableDesignation)"
  parent.svd = item

method add*(parent: CsIsPatternExpression; item: CsConstantPattern) = # CP
  echo "in method add*(parent: CsIsPatternExpression; item: CsConstantPattern)"
  parent.rhs = item

method add*(parent: CsIsPatternExpression; item: CsDeclarationPattern) = # DP
  echo "in method add*(parent: CsIsPatternExpression; item: CsDeclarationPattern)"
  parent.rhs = item

method add*(parent: CsIsPatternExpression; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsIsPatternExpression; item: CsMemberAccessExpression)"
  if parent.lhs.isNil:
    parent.lhs = item
  elif parent.rhsExpr.isNil:
    parent.rhsExpr = item
  else: assert false

method add*(parent: CsAssignmentExpression; item: CsDefaultExpression) = # DE
  echo "in method add*(parent: CsAssignmentExpression; item: CsDefaultExpression)"
  parent.right = item

method add*(parent: CsAssignmentExpression; item: CsImplicitArrayCreationExpression) = # IACE
  echo "in method add*(parent: CsAssignmentExpression; item: CsImplicitArrayCreationExpression)"
  parent.right = item

method add*(parent: CsMethod; item: CsContinueStatement) = # CS
  echo "in method add*(parent: CsMethod; item: CsContinueStatement)"
  todoimplAdd() # TODO(add: CsMethod, CsContinueStatement)

method add*(parent: CsMethod; item: CsRefType) = # RT
  echo "in method add*(parent: CsMethod; item: CsRefType)"
  parent.gotType = item

method add*(parent: CsNullableType; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsNullableType; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsEqualsValueClause; item: CsAnonymousObjectCreationExpression) = # AOCE
  echo "in method add*(parent: CsEqualsValueClause; item: CsAnonymousObjectCreationExpression)"
  parent.rhsValue = item

method add*(parent: CsEqualsValueClause; item: CsPostfixUnaryExpression) = # PUE
  echo "in method add*(parent: CsEqualsValueClause; item: CsPostfixUnaryExpression)"
  parent.rhsValue = item

method add*(parent: CsEqualsValueClause; item: CsQueryExpression) = # QE
  echo "in method add*(parent: CsEqualsValueClause; item: CsQueryExpression)"
  parent.rhsValue = item

method add*(parent: CsYieldStatement; item: CsArrayCreationExpression) = # ACE
  echo "in method add*(parent: CsYieldStatement; item: CsArrayCreationExpression)"
  parent.expr = item

method add*(parent: CsNamespace; item: CsIncompleteMember) = # IM
  echo "in method add*(parent: CsNamespace; item: CsIncompleteMember)"
  todoimplAdd() # TODO(add: CsNamespace, CsIncompleteMember)

method add*(parent: CsUsingStatement; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsUsingStatement; item: CsAwaitExpression)"
  parent.addToUsing item


#  Action?.Invoke();
method add*(parent: CsConditionalAccessExpression; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsConditionalAccessExpression; item: CsInvocationExpression)"
  if parent.lhs.isNil:
    parent.lhs = item # TODO: check this!
  elif parent.rhs.isNil:
    parent.rhs = item

method add*(parent: CsConditionalAccessExpression; item: CsMemberBindingExpression) = # MBE
  echo "in method add*(parent: CsConditionalAccessExpression; item: CsMemberBindingExpression)"
  parent.rhs = item # TODO: check against more examples/ or spec.

method add*(parent: CsStruct; item: CsBaseList) = # BL
  echo "in method add*(parent: CsStruct; item: CsBaseList)"
  parent.baseList = item

method add*(parent: CsStruct; item: CsConstructor) =
  echo "in method add*(parent: CsStruct; item: CsConstructor)"
  parent.ctors.add item

method add*(parent: CsStruct; item: CsField) =
  echo "in method add*(parent: CsStruct; item: CsField)"
  parent.fields.add item

method add*(parent: CsStruct; item: CsIncompleteMember) = # IM
  echo "in method add*(parent: CsStruct; item: CsIncompleteMember)"
  todoimplAdd() # TODO(add: CsStruct, CsIncompleteMember)

method add*(parent: CsStruct; item: CsProperty) =
  echo "in method add*(parent: CsStruct; item: CsProperty)"
  parent.properties.add item

method add*(parent: CsStruct; item: CsTypeParameterList) = # TPL
  echo "in method add*(parent: CsStruct; item: CsTypeParameterList)"
  parent.typeParams = item


method add*(parent: CsIfStatement; item: CsCastExpression) = # CE
  echo "in method add*(parent: CsIfStatement; item: CsCastExpression)"
  if parent.hasNoPredicate:
    parent.exprThatLeadsToBoolean = item
  else:
    parent.body.add item

method add*(parent: CsIfStatement; item: CsContinueStatement) = # CS
  echo "in method add*(parent: CsIfStatement; item: CsContinueStatement)"
  parent.body.add item

method add*(parent: CsIfStatement; item: CsEmptyStatement) = # ES
  echo "in method add*(parent: CsIfStatement; item: CsEmptyStatement)"
  parent.body.add item

method add*(parent: CsAwaitExpression; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsAwaitExpression; item: CsInvocationExpression)"
  parent.body.add item

method add*(parent: CsAwaitExpression; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsAwaitExpression; item: CsParenthesizedExpression)"
  parent.body.add item

method add*(parent: CsArrowExpressionClause; item: CsConditionalAccessExpression) = # CAE
  echo "in method add*(parent: CsArrowExpressionClause; item: CsConditionalAccessExpression)"
  parent.body.add item

method add*(parent: CsArrowExpressionClause; item: CsThrowExpression) = # TE
  echo "in method add*(parent: CsArrowExpressionClause; item: CsThrowExpression)"
  parent.body.add item

method add*(parent: CsElseClause; item: CsExpressionStatement) = # ES
  echo "in method add*(parent: CsElseClause; item: CsExpressionStatement)"
  parent.body.add item

method add*(parent: CsElseClause; item: CsIfStatement) = # IS
  echo "in method add*(parent: CsElseClause; item: CsIfStatement)"
  parent.body.add item

method add*(parent: CsElseClause; item: CsReturnStatement) = # RS
  echo "in method add*(parent: CsElseClause; item: CsReturnStatement)"
  parent.body.add item

method add*(parent: CsTupleType; item: CsTupleElement) = # TE
  echo "in method add*(parent: CsTupleType; item: CsTupleElement)"
  parent.elems.add item

method add*(parent: CsConditionalExpression; item: CsConditionalExpression) = # CE
  echo "in method add*(parent: CsConditionalExpression; item: CsConditionalExpression)"
  parent.addConditional(item)

method add*(parent: CsConditionalExpression; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsConditionalExpression; item: CsElementAccessExpression)"
  parent.addConditional(item)

method add*(parent: CsAnonymousMethodExpression; item: CsParameterList) = # PL
  echo "in method add*(parent: CsAnonymousMethodExpression; item: CsParameterList)"
  parent.paramList = item

method add*(parent: CsTypeParameterConstraintClause; item: CsClassOrStructConstraint) = # COSC
  echo "in method add*(parent: CsTypeParameterConstraintClause; item: CsClassOrStructConstraint)"
  parent.constraints.add item

method add*(parent: CsArgument; item: CsConditionalAccessExpression) = # CAE
  echo "in method add*(parent: CsArgument; item: CsConditionalAccessExpression)"
  parent.expr = item

method add*(parent: CsArgument; item: CsTupleExpression) = # TE
  echo "in method add*(parent: CsArgument; item: CsTupleExpression)"
  parent.expr = item

method add*(parent: CsPrefixUnaryExpression; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsPrefixUnaryExpression; item: CsElementAccessExpression)"
  parent.actingOn = item

method add*(parent: CsImplicitArrayCreationExpression; item: CsInitializerExpression) = # IE
  echo "in method add*(parent: CsImplicitArrayCreationExpression; item: CsInitializerExpression)"
  parent.initExpr = item

method add*(parent: CsReturnStatement; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsReturnStatement; item: CsAwaitExpression)"
  parent.expr = item

method add*(parent: CsImplicitElementAccess; item: CsBracketedArgumentList) = # BAL
  echo "in method add*(parent: CsImplicitElementAccess; item: CsBracketedArgumentList)"
  parent.args = item

method add*(parent: CsClass; item: CsDelegate) =
  echo "in method add*(parent: CsClass; item: CsDelegate)"
  parent.delegates.add item

method add*(parent: CsDelegate; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsDelegate; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsDelegate; item: CsTypeParameterList) = # TPL
  echo "in method add*(parent: CsDelegate; item: CsTypeParameterList)"
  parent.tplist = item

method add*(parent: CsForEachStatement; item: CsExpressionStatement) = # ES
  echo "in method add*(parent: CsForEachStatement; item: CsExpressionStatement)"
  parent.body.add item

method add*(parent: CsForEachStatement; item: CsGenericName) = # GN
  echo "in method add*(parent: CsForEachStatement; item: CsGenericName)"
  parent.gotType = item

method add*(parent: CsForEachStatement; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsForEachStatement; item: CsInvocationExpression)"
  if parent.listPart.isNil:
    parent.listPart = item
  else:
    parent.body.add item

method add*(parent: CsForEachStatement; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsForEachStatement; item: CsMemberAccessExpression)"
  if parent.listPart.isNil:
    parent.listPart = item
  else:
    parent.body.add item

method add*(parent: CsForEachStatement; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsForEachStatement; item: CsPredefinedType)"
  parent.gotType = item


method add*(parent: CsSwitchStatement; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsSwitchStatement; item: CsMemberAccessExpression)"
  parent.on = item

method add*(parent: CsSwitchStatement; item: CsSwitchSection) = # SS
  echo "in method add*(parent: CsSwitchStatement; item: CsSwitchSection)"
  parent.sections.add item

method add*(parent: CsArrayRankSpecifier; item: CsCastExpression) = # CE
  echo "in method add*(parent: CsArrayRankSpecifier; item: CsCastExpression)"
  parent.theRankValue = item

method add*(parent: CsArrayRankSpecifier; item: CsConditionalExpression) = # CE
  echo "in method add*(parent: CsArrayRankSpecifier; item: CsConditionalExpression)"
  parent.theRankValue = item

method add*(parent: CsArrayRankSpecifier; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsArrayRankSpecifier; item: CsInvocationExpression)"
  todoimplAdd() # TODO(add: CsArrayRankSpecifier, CsInvocationExpression)

method add*(parent: CsArrayRankSpecifier; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsArrayRankSpecifier; item: CsParenthesizedExpression)"
  todoimplAdd() # TODO(add: CsArrayRankSpecifier, CsParenthesizedExpression)

method add*(parent: CsArrayRankSpecifier; item: CsPrefixUnaryExpression) = # PUE
  echo "in method add*(parent: CsArrayRankSpecifier; item: CsPrefixUnaryExpression)"
  todoimplAdd() # TODO(add: CsArrayRankSpecifier, CsPrefixUnaryExpression)

method add*(parent: CsInterpolation; item: CsAssignmentExpression) = # AE
  echo "in method add*(parent: CsInterpolation; item: CsAssignmentExpression)"
  todoimplAdd() # TODO(add: CsInterpolation, CsAssignmentExpression)

method add*(parent: CsInterpolation; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsInterpolation; item: CsElementAccessExpression)"
  todoimplAdd() # TODO(add: CsInterpolation, CsElementAccessExpression)

method add*(parent: CsInterpolation; item: CsObjectCreationExpression) = # OCE
  echo "in method add*(parent: CsInterpolation; item: CsObjectCreationExpression)"
  todoimplAdd() # TODO(add: CsInterpolation, CsObjectCreationExpression)

method add*(parent: CsInterpolation; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsInterpolation; item: CsParenthesizedExpression)"

  todoimplAdd() # TODO(add: CsInterpolation, CsParenthesizedExpression)

method add*(parent: CsInterpolation; item: CsPostfixUnaryExpression) = # PUE
  echo "in method add*(parent: CsInterpolation; item: CsPostfixUnaryExpression)"
  todoimplAdd() # TODO(add: CsInterpolation, CsPostfixUnaryExpression)

method add*(parent: CsInterpolation; item: CsTypeOfExpression) = # TOE
  echo "in method add*(parent: CsInterpolation; item: CsTypeOfExpression)"
  parent.expr = item

method add*(parent: CsCatch; item: CsArrayType) = # AT
  echo "in method add*(parent: CsCatch; item: CsArrayType)"
  parent.gotType = item


method add*(parent: CsCatch; item: CsGenericName) = # GN
  echo "in method add*(parent: CsCatch; item: CsGenericName)"
  todoimplAdd() # TODO(add: CsCatch, CsGenericName)

method add*(parent: CsCatch; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsCatch; item: CsPredefinedType)"
  parent.gotType = item


method add*(parent: CsPointerType; item: CsPointerType) = # PT
  echo "in method add*(parent: CsPointerType; item: CsPointerType)"
  parent.gotType = item


method add*(parent: CsPointerType; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsPointerType; item: CsPredefinedType)"
  parent.gotType = item


method add*(parent: CsDeclarationExpression; item: CsDiscardDesignation) = # DD
  echo "in method add*(parent: CsDeclarationExpression; item: CsDiscardDesignation)"
  todoimplAdd() # TODO(add: CsDeclarationExpression, CsDiscardDesignation)

method add*(parent: CsDeclarationExpression; item: CsGenericName) = # GN
  echo "in method add*(parent: CsDeclarationExpression; item: CsGenericName)"
  parent.gotType = item

method add*(parent: CsDeclarationExpression; item: CsNullableType) = # NT
  echo "in method add*(parent: CsDeclarationExpression; item: CsNullableType)"
  parent.gotType = item


method add*(parent: CsDeclarationExpression; item: CsParenthesizedVariableDesignation) = # PVD
  echo "in method add*(parent: CsDeclarationExpression; item: CsParenthesizedVariableDesignation)"
  parent.pvd = item

method add*(parent: CsDeclarationExpression; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsDeclarationExpression; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsIsPatternExpression; item: CsConditionalAccessExpression) = # CAE
  echo "in method add*(parent: CsIsPatternExpression; item: CsConditionalAccessExpression)"
  todoimplAdd() # TODO(add: CsIsPatternExpression, CsConditionalAccessExpression)

method add*(parent: CsIsPatternExpression; item: CsUnaryPattern) = # UP
  echo "in method add*(parent: CsIsPatternExpression; item: CsUnaryPattern)"
  parent.rhs = item

method add*(parent: CsEqualsValueClause; item: CsDefaultExpression) = # DE
  echo "in method add*(parent: CsEqualsValueClause; item: CsDefaultExpression)"
  parent.rhsValue = item

method add*(parent: CsEqualsValueClause; item: CsImplicitObjectCreationExpression) = # IOCE
  echo "in method add*(parent: CsEqualsValueClause; item: CsImplicitObjectCreationExpression)"
  parent.rhsValue = item

method add*(parent: CsEqualsValueClause; item: CsIsPatternExpression) = # IPE
  echo "in method add*(parent: CsEqualsValueClause; item: CsIsPatternExpression)"
  parent.rhsValue = item

method add*(parent: CsEqualsValueClause; item: CsMakeRefExpression) = # MRE
  echo "in method add*(parent: CsEqualsValueClause; item: CsMakeRefExpression)"
  parent.rhsValue = item

method add*(parent: CsEqualsValueClause; item: CsRefExpression) = # RE
  echo "in method add*(parent: CsEqualsValueClause; item: CsRefExpression)"
  parent.rhsValue = item

method add*(parent: CsEqualsValueClause; item: CsStackAllocArrayCreationExpression) = # SAACE
  echo "in method add*(parent: CsEqualsValueClause; item: CsStackAllocArrayCreationExpression)"
  parent.rhsValue = item

method add*(parent: CsEqualsValueClause; item: CsSwitchExpression) = # SE
  echo "in method add*(parent: CsEqualsValueClause; item: CsSwitchExpression)"
  parent.rhsValue = item

method add*(parent: CsEqualsValueClause; item: CsThisExpression) = # TE
  echo "in method add*(parent: CsEqualsValueClause; item: CsThisExpression)"
  parent.rhsValue = item

method add*(parent: CsEqualsValueClause; item: CsTupleExpression) = # TE
  echo "in method add*(parent: CsEqualsValueClause; item: CsTupleExpression)"
  parent.rhsValue = item

method add*(parent: CsParenthesizedLambdaExpression; item: CsAnonymousObjectCreationExpression) = # AOCE
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsAnonymousObjectCreationExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedLambdaExpression; item: CsArrayCreationExpression) = # ACE
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsArrayCreationExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedLambdaExpression; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsAwaitExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedLambdaExpression; item: CsConditionalAccessExpression) = # CAE
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsConditionalAccessExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedLambdaExpression; item: CsInterpolatedStringExpression) = # ISE
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsInterpolatedStringExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedLambdaExpression; item: CsRefExpression) = # RE
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsRefExpression)"
  todoimplAdd() # TODO(add: CsParenthesizedLambdaExpression, CsRefExpression)

method add*(parent: CsParenthesizedLambdaExpression; item: CsThrowExpression) = # TE
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsThrowExpression)"
  parent.body.add item

method add*(parent: CsYieldStatement; item: CsBinaryExpression) = # BE
  echo "in method add*(parent: CsYieldStatement; item: CsBinaryExpression)"
  parent.expr = item

method add*(parent: CsYieldStatement; item: CsInterpolatedStringExpression) = # ISE
  echo "in method add*(parent: CsYieldStatement; item: CsInterpolatedStringExpression)"
  parent.expr = item

method add*(parent: CsYieldStatement; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsYieldStatement; item: CsInvocationExpression)"
  parent.expr = item

method add*(parent: CsYieldStatement; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsYieldStatement; item: CsLiteralExpression)"
  parent.expr = item

method add*(parent: CsYieldStatement; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsYieldStatement; item: CsMemberAccessExpression)"
  parent.expr = item

method add*(parent: CsYieldStatement; item: CsObjectCreationExpression) = # OCE
  echo "in method add*(parent: CsYieldStatement; item: CsObjectCreationExpression)"
  parent.expr = item

method add*(parent: CsElementAccessExpression; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsElementAccessExpression; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsElementAccessExpression, CsLiteralExpression)

method add*(parent: CsElementAccessExpression; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsElementAccessExpression; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsArrayType; item: CsNullableType) = # NT
  echo "in method add*(parent: CsArrayType; item: CsNullableType)"
  parent.gotType = item

method add*(parent: CsArrayType; item: CsTupleType) = # TT
  echo "in method add*(parent: CsArrayType; item: CsTupleType)"
  parent.gotType = item

method add*(parent: CsDoStatement; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsDoStatement; item: CsInvocationExpression)"
  if parent.hasNoPredicate:
    parent.exprThatLeadsToBoolean = item
  else:
    parent.body.add item

method add*(parent: CsDoStatement; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsDoStatement; item: CsLiteralExpression)"
  parent.predicatePartLit = item

method add*(parent: CsDoStatement; item: CsPrefixUnaryExpression) = # PUE
  echo "in method add*(parent: CsDoStatement; item: CsPrefixUnaryExpression)"
  parent.predicate = item
  # exprThatLeadsToBoolean = item

method add*(parent: CsAwaitExpression; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsAwaitExpression; item: CsMemberAccessExpression)"
  parent.body.add item

method add*(parent: CsCatchClause; item: CsCatchFilterClause) = # CFC
  echo "in method add*(parent: CsCatchClause; item: CsCatchFilterClause)"
  parent.filter = item

method add*(parent: CsArrowExpressionClause; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsArrowExpressionClause; item: CsAwaitExpression)"
  parent.body.add item

method add*(parent: CsArrowExpressionClause; item: CsImplicitArrayCreationExpression) = # IACE
  echo "in method add*(parent: CsArrowExpressionClause; item: CsImplicitArrayCreationExpression)"
  parent.body.add item

method add*(parent: CsArrowExpressionClause; item: CsIsPatternExpression) = # IPE
  echo "in method add*(parent: CsArrowExpressionClause; item: CsIsPatternExpression)"
  parent.body.add item

method add*(parent: CsArrowExpressionClause; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsArrowExpressionClause; item: CsParenthesizedExpression)"
  parent.body.add item

method add*(parent: CsArrowExpressionClause; item: CsPostfixUnaryExpression) = # PUE
  echo "in method add*(parent: CsArrowExpressionClause; item: CsPostfixUnaryExpression)"
  parent.body.add item

method add*(parent: CsArrowExpressionClause; item: CsPrefixUnaryExpression) = # PUE
  echo "in method add*(parent: CsArrowExpressionClause; item: CsPrefixUnaryExpression)"
  parent.body.add item

method add*(parent: CsArrowExpressionClause; item: CsQueryExpression) = # QE
  echo "in method add*(parent: CsArrowExpressionClause; item: CsQueryExpression)"
  parent.body.add item

method add*(parent: CsArrowExpressionClause; item: CsSwitchExpression) = # SE
  echo "in method add*(parent: CsArrowExpressionClause; item: CsSwitchExpression)"
  parent.body.add item

method add*(parent: CsArrowExpressionClause; item: CsThisExpression) = # TE
  echo "in method add*(parent: CsArrowExpressionClause; item: CsThisExpression)"
  parent.body.add item

method add*(parent: CsMemberAccessExpression; item: CsAliasQualifiedName) = # AQN
  echo "in method add*(parent: CsMemberAccessExpression; item: CsAliasQualifiedName)"
  todoimplAdd() # TODO(add: CsMemberAccessExpression, CsAliasQualifiedName)

method add*(parent: CsMemberAccessExpression; item: CsAnonymousObjectCreationExpression) = # AOCE
  echo "in method add*(parent: CsMemberAccessExpression; item: CsAnonymousObjectCreationExpression)"
  todoimplAdd() # TODO(add: CsMemberAccessExpression, CsAnonymousObjectCreationExpression)

method add*(parent: CsMemberAccessExpression; item: CsImplicitArrayCreationExpression) = # IACE
  parent.left = item

method add*(parent: CsMemberAccessExpression; item: CsPostfixUnaryExpression) = # PUE
  echo "in method add*(parent: CsMemberAccessExpression; item: CsPostfixUnaryExpression)"
  parent.right = item

method add*(parent: CsInitializerExpression; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsInitializerExpression; item: CsAwaitExpression)"
  todoimplAdd() # TODO(add: CsInitializerExpression, CsAwaitExpression)

method add*(parent: CsInitializerExpression; item: CsCheckedExpression) = # CE
  echo "in method add*(parent: CsInitializerExpression; item: CsCheckedExpression)"
  parent.bexprs.add item

method add*(parent: CsInitializerExpression; item: CsDefaultExpression) = # DE
  echo "in method add*(parent: CsInitializerExpression; item: CsDefaultExpression)"
  parent.bexprs.add item

method add*(parent: CsInitializerExpression; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsInitializerExpression; item: CsElementAccessExpression)"
  parent.bexprs.add item

method add*(parent: CsInitializerExpression; item: CsImplicitArrayCreationExpression) = # IACE
  echo "in method add*(parent: CsInitializerExpression; item: CsImplicitArrayCreationExpression)"
  parent.bexprs.add item


method add*(parent: CsInitializerExpression; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsInitializerExpression; item: CsParenthesizedExpression)"

method add*(parent: CsInitializerExpression; item: CsPostfixUnaryExpression) = # PUE
  echo "in method add*(parent: CsInitializerExpression; item: CsPostfixUnaryExpression)"
  parent.bexprs.add item

method add*(parent: CsInitializerExpression; item: CsThisExpression) = # TE
  echo "in method add*(parent: CsInitializerExpression; item: CsThisExpression)"
  parent.bexprs.add item

method add*(parent: CsPrefixUnaryExpression; item: CsPrefixUnaryExpression) = # PUE
  echo "in method add*(parent: CsPrefixUnaryExpression; item: CsPrefixUnaryExpression)"
  parent.actingOn = item

method add*(parent: CsTypeOfExpression; item: CsNullableType) = # NT
  echo "in method add*(parent: CsTypeOfExpression; item: CsNullableType)"
  parent.gotType = item

method add*(parent: CsTypeOfExpression; item: CsPointerType) = # PT
  echo "in method add*(parent: CsTypeOfExpression; item: CsPointerType)"
  parent.gotType = item

method add*(parent: CsExpressionStatement; item: CsCastExpression) = # CE
  echo "in method add*(parent: CsExpressionStatement; item: CsCastExpression)"
  todoimplAdd() # TODO(add: CsExpressionStatement, CsCastExpression)

method add*(parent: CsExpressionStatement; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsExpressionStatement; item: CsElementAccessExpression)"
  todoimplAdd() # TODO(add: CsExpressionStatement, CsElementAccessExpression)

method add*(parent: CsExpressionStatement; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsExpressionStatement; item: CsMemberAccessExpression)"
  todoimplAdd() # TODO(add: CsExpressionStatement, CsMemberAccessExpression)

method add*(parent: CsExpressionStatement; item: CsThisExpression) = # TE
  echo "in method add*(parent: CsExpressionStatement; item: CsThisExpression)"
  todoimplAdd() # TODO(add: CsExpressionStatement, CsThisExpression)

method add*(parent: CsLockStatement; item: CsLockStatement) = # LS
  echo "in method add*(parent: CsLockStatement; item: CsLockStatement)"
  parent.body.add item

method add*(parent: CsLockStatement; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsLockStatement; item: CsMemberAccessExpression)"
  if parent.locker.isNil:
    parent.locker = item
  else:
    parent.body.add item

method add*(parent: CsLockStatement; item: CsThisExpression) = # TE
  echo "in method add*(parent: CsLockStatement; item: CsThisExpression)"
  parent.locker = item

method add*(parent: CsLockStatement; item: CsTypeOfExpression) = # TOE
  echo "in method add*(parent: CsLockStatement; item: CsTypeOfExpression)"
  parent.locker = item

method add*(parent: CsClass; item: CsGenericName) = # GN
  echo "in method add*(parent: CsClass; item: CsGenericName)"
  todoimplAdd() # TODO(add: CsClass, CsGenericName)

method add*(parent: CsClass; item: CsIncompleteMember) = # IM
  echo "in method add*(parent: CsClass; item: CsIncompleteMember)"
  # I think it's a roslyn mistake. it should be added to csmethod, if at all.
  # not really sure what is incomplete member.
  todoimplAdd() # TODO(add: CsClass, CsIncompleteMember)

method add*(parent: CsSwitchStatement; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsSwitchStatement; item: CsAwaitExpression)"
  parent.on = item

method add*(parent: CsSwitchStatement; item: CsBinaryExpression) = # BE
  echo "in method add*(parent: CsSwitchStatement; item: CsBinaryExpression)"
  parent.on = item

method add*(parent: CsSwitchStatement; item: CsCastExpression) = # CE
  echo "in method add*(parent: CsSwitchStatement; item: CsCastExpression)"
  parent.on = item

method add*(parent: CsSwitchStatement; item: CsConditionalAccessExpression) = # CAE
  echo "in method add*(parent: CsSwitchStatement; item: CsConditionalAccessExpression)"
  parent.on = item

method add*(parent: CsSwitchStatement; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsSwitchStatement; item: CsElementAccessExpression)"
  parent.on = item

method add*(parent: CsSwitchStatement; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsSwitchStatement; item: CsInvocationExpression)"
  parent.on = item

method add*(parent: CsSwitchStatement; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsSwitchStatement; item: CsLiteralExpression)"
  parent.on = item

method add*(parent: CsSwitchStatement; item: CsPrefixUnaryExpression) = # PUE
  echo "in method add*(parent: CsSwitchStatement; item: CsPrefixUnaryExpression)"
  parent.on = item

method add*(parent: CsParenthesizedExpression; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsParenthesizedExpression; item: CsAwaitExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedExpression; item: CsCheckedExpression) = # CE
  echo "in method add*(parent: CsParenthesizedExpression; item: CsCheckedExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedExpression; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsParenthesizedExpression; item: CsElementAccessExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedExpression; item: CsImplicitArrayCreationExpression) = # IACE
  echo "in method add*(parent: CsParenthesizedExpression; item: CsImplicitArrayCreationExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedExpression; item: CsInterpolatedStringExpression) = # ISE
  echo "in method add*(parent: CsParenthesizedExpression; item: CsInterpolatedStringExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedExpression; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsParenthesizedExpression; item: CsParenthesizedExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedExpression; item: CsTypeOfExpression) = # TOE
  echo "in method add*(parent: CsParenthesizedExpression; item: CsTypeOfExpression)"
  parent.body.add item

method add*(parent: CsCastExpression; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsCastExpression; item: CsAwaitExpression)"
  parent.expr = item

method add*(parent: CsCastExpression; item: CsConditionalAccessExpression) = # CAE
  echo "in method add*(parent: CsCastExpression; item: CsConditionalAccessExpression)"
  parent.expr = item

method add*(parent: CsCastExpression; item: CsPointerType) = # PT
  echo "in method add*(parent: CsCastExpression; item: CsPointerType)"
  parent.gotType = item

method add*(parent: CsCastExpression; item: CsPostfixUnaryExpression) = # PUE
  echo "in method add*(parent: CsCastExpression; item: CsPostfixUnaryExpression)"
  parent.expr = item

method add*(parent: CsBinaryExpression; item: CsArrayCreationExpression) = # ACE
  echo "in method add*(parent: CsBinaryExpression; item: CsArrayCreationExpression)"
  parent.addBinExp item

method add*(parent: CsBinaryExpression; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsBinaryExpression; item: CsAwaitExpression)"
  parent.addBinExp item

method add*(parent: CsBinaryExpression; item: CsDefaultExpression) = # DE
  echo "in method add*(parent: CsBinaryExpression; item: CsDefaultExpression)"
  parent.addBinExp item

method add*(parent: CsBinaryExpression; item: CsInterpolatedStringExpression) = # ISE
  echo "in method add*(parent: CsBinaryExpression; item: CsInterpolatedStringExpression)"
  parent.addBinExp(item)

method add*(parent: CsBinaryExpression; item: CsNullableType) = # NT
  echo "in method add*(parent: CsBinaryExpression; item: CsNullableType)"
  parent.gotType = item

method add*(parent: CsSimpleBaseType; item: CsAliasQualifiedName) = # AQN
  echo "in method add*(parent: CsSimpleBaseType; item: CsAliasQualifiedName)"
  todoimplAdd() # TODO(add: CsSimpleBaseType, CsAliasQualifiedName)

method add*(parent: CsSimpleBaseType; item: CsArrayType) = # AT
  echo "in method add*(parent: CsSimpleBaseType; item: CsArrayType)"
  parent.gotType = item

method add*(parent: CsInterface; item: CsField) =
  echo "in method add*(parent: CsInterface; item: CsField)"
  parent.fields.add item

method add*(parent: CsInterface; item: CsIndexer) =
  echo "in method add*(parent: CsInterface; item: CsIndexer)"
  parent.indexers.add item

method add*(parent: CsPostfixUnaryExpression; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsPostfixUnaryExpression; item: CsParenthesizedExpression)"
  parent.actingOn = item

method add*(parent: CsAssignmentExpression; item: CsAnonymousMethodExpression) = # AME
  echo "in method add*(parent: CsAssignmentExpression; item: CsAnonymousMethodExpression)"
  parent.right = item

method add*(parent: CsAssignmentExpression; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsAssignmentExpression; item: CsAwaitExpression)"
  parent.right = item

method add*(parent: CsAssignmentExpression; item: CsCheckedExpression) = # CE
  echo "in method add*(parent: CsAssignmentExpression; item: CsCheckedExpression)"
  parent.right = item

method add*(parent: CsAssignmentExpression; item: CsImplicitObjectCreationExpression) = # IOCE
  echo "in method add*(parent: CsAssignmentExpression; item: CsImplicitObjectCreationExpression)"
  todoimplAdd() # TODO(add: CsAssignmentExpression, CsImplicitObjectCreationExpression)

method add*(parent: CsAssignmentExpression; item: CsPostfixUnaryExpression) = # PUE
  echo "in method add*(parent: CsAssignmentExpression; item: CsPostfixUnaryExpression)"
  parent.right = item

method add*(parent: CsAssignmentExpression; item: CsTupleExpression) = # TE
  echo "in method add*(parent: CsAssignmentExpression; item: CsTupleExpression)"
  parent.left = item

method add*(parent: CsMethod; item: CsGotoStatement) = # GS
  echo "in method add*(parent: CsMethod; item: CsGotoStatement)"
  parent.body.add item


method add*(parent: CsMethod; item: CsPointerType) = # PT
  echo "in method add*(parent: CsMethod; item: CsPointerType)"
  parent.gotType = item

method add*(parent: CsNullableType; item: CsArrayType) = # AT
  echo "in method add*(parent: CsNullableType; item: CsArrayType)"
  parent.gotType = item

method add*(parent: CsNullableType; item: CsGenericName) = # GN
  echo "in method add*(parent: CsNullableType; item: CsGenericName)"
  parent.gotType = item

method add*(parent: CsVariable; item: CsAliasQualifiedName) = # AQN
  echo "in method add*(parent: CsVariable; item: CsAliasQualifiedName)"
  parent.aliasQualifiedName = item

method add*(parent: CsUsingDirective; item: CsAliasQualifiedName) = # AQN
  echo "in method add*(parent: CsUsingDirective; item: CsAliasQualifiedName)"
  parent.aliasQualifiedName = item

method add*(parent: CsNamespace; item: CsConstructor) =
  echo "in method add*(parent: CsNamespace; item: CsConstructor)"
  todoimplAdd() # TODO(add: CsNamespace, CsConstructor)

method add*(parent: CsNamespace; item: CsField) =
  echo "in method add*(parent: CsNamespace; item: CsField)"
  todoimplAdd() # TODO(add: CsNamespace, CsField)



method add*(parent: CsUsingStatement; item: CsBinaryExpression) = # BE
  echo "in method add*(parent: CsUsingStatement; item: CsBinaryExpression)"
  parent.addToUsing item

method add*(parent: CsUsingStatement; item: CsConditionalAccessExpression) = # CAE
  echo "in method add*(parent: CsUsingStatement; item: CsConditionalAccessExpression)"
  parent.addToUsing item

method add*(parent: CsUsingStatement; item: CsConditionalExpression) = # CE
  echo "in method add*(parent: CsUsingStatement; item: CsConditionalExpression)"
  parent.addToUsing item

method add*(parent: CsUsingStatement; item: CsEmptyStatement) = # ES
  echo "in method add*(parent: CsUsingStatement; item: CsEmptyStatement)"
  parent.body.add item

method add*(parent: CsUsingStatement; item: CsReturnStatement) = # RS
  echo "in method add*(parent: CsUsingStatement; item: CsReturnStatement)"
  parent.body.add item

method add*(parent: CsUsingStatement; item: CsWhileStatement) = # WS
  echo "in method add*(parent: CsUsingStatement; item: CsWhileStatement)"
  parent.body.add item

method add*(parent: CsConditionalAccessExpression; item: CsConditionalAccessExpression) = # CAE
  echo "in method add*(parent: CsConditionalAccessExpression; item: CsConditionalAccessExpression)"
  parent.rhs = item

method add*(parent: CsConditionalAccessExpression; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsConditionalAccessExpression; item: CsMemberAccessExpression)"
  parent.lhs = item

method add*(parent: CsConditionalAccessExpression; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsConditionalAccessExpression; item: CsParenthesizedExpression)"
  if parent.lhs.isNil: parent.lhs = item
  elif parent.rhs.isNil: parent.rhs = item
  else: assert false

method add*(parent: CsDefaultExpression; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsDefaultExpression; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsStruct; item: CsDelegate) =
  echo "in method add*(parent: CsStruct; item: CsDelegate)"
  parent.delegates.add item

method add*(parent: CsStruct; item: CsEnum) =
  echo "in method add*(parent: CsStruct; item: CsEnum)"
  # forwarding to namespace, enums will be global.
  parent.ns.enums.add item


method add*(parent: CsStruct; item: CsMethod) =
  echo "in method add*(parent: CsStruct; item: CsMethod)"
  parent.methods.add item

method add*(parent: CsIfStatement; item: CsAssignmentExpression) = # AE
  echo "in method add*(parent: CsIfStatement; item: CsAssignmentExpression)"
  todoimplAdd() # TODO(add: CsIfStatement, CsAssignmentExpression)

method add*(parent: CsIfStatement; item: CsForEachStatement) = # FES
  echo "in method add*(parent: CsIfStatement; item: CsForEachStatement)"
  parent.body.add item

method add*(parent: CsIfStatement; item: CsForStatement) = # FS
  echo "in method add*(parent: CsIfStatement; item: CsForStatement)"
  parent.body.add item

method add*(parent: CsIfStatement; item: CsGotoStatement) = # GS
  echo "in method add*(parent: CsIfStatement; item: CsGotoStatement)"
  parent.body.add item

method add*(parent: CsIfStatement; item: CsLocalDeclarationStatement) = # LDS
  echo "in method add*(parent: CsIfStatement; item: CsLocalDeclarationStatement)"
  parent.body.add item

method add*(parent: CsIfStatement; item: CsTryStatement) = # TS
  echo "in method add*(parent: CsIfStatement; item: CsTryStatement)"
  parent.body.add item

method add*(parent: CsIfStatement; item: CsUsingStatement) = # US
  echo "in method add*(parent: CsIfStatement; item: CsUsingStatement)"
  parent.body.add item

method add*(parent: CsForStatement; item: CsEmptyStatement) = # ES
  echo "in method add*(parent: CsForStatement; item: CsEmptyStatement)"
  parent.body.add item

method add*(parent: CsForStatement; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsForStatement; item: CsInvocationExpression)"
  assert parent.forPart1.isNil
  parent.forPart1 = item

method add*(parent: CsForStatement; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsForStatement; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsForStatement, CsLiteralExpression)

method add*(parent: CsForStatement; item: CsLocalDeclarationStatement) = # LDS
  echo "in method add*(parent: CsForStatement; item: CsLocalDeclarationStatement)"
  parent.body.add item

method add*(parent: CsForStatement; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsForStatement; item: CsMemberAccessExpression)"
  todoimplAdd() # TODO(add: CsForStatement, CsMemberAccessExpression)

method add*(parent: CsForStatement; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsForStatement; item: CsParenthesizedExpression)"
  todoimplAdd() # TODO(add: CsForStatement, CsParenthesizedExpression)

method add*(parent: CsForStatement; item: CsYieldStatement) = # YS
  echo "in method add*(parent: CsForStatement; item: CsYieldStatement)"
  parent.body.add item

method add*(parent: CsElseClause; item: CsThrowStatement) = # TS
  echo "in method add*(parent: CsElseClause; item: CsThrowStatement)"
  parent.body.add item

method add*(parent: CsInvocationExpression; item: CsCheckedExpression) = # CE
  echo "in method add*(parent: CsInvocationExpression; item: CsCheckedExpression)"
  parent.invoker = item # TODO: not entirely sure. checked wraps the invocation.. see what is generated.

method add*(parent: CsInvocationExpression; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsInvocationExpression; item: CsParenthesizedExpression)"
  parent.invoker = item

method add*(parent: CsInvocationExpression; item: CsParenthesizedLambdaExpression) = # PLE
  echo "in method add*(parent: CsInvocationExpression; item: CsParenthesizedLambdaExpression)"
  todoimplAdd() # TODO(add: CsInvocationExpression, CsParenthesizedLambdaExpression)

method add*(parent: CsInvocationExpression; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsInvocationExpression; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsWhileStatement; item: CsConditionalExpression) = # CE
  echo "in method add*(parent: CsWhileStatement; item: CsConditionalExpression)"
  todoimplAdd() # TODO(add: CsWhileStatement, CsConditionalExpression)

method add*(parent: CsWhileStatement; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsWhileStatement; item: CsElementAccessExpression)"
  todoimplAdd() # TODO(add: CsWhileStatement, CsElementAccessExpression)

method add*(parent: CsWhileStatement; item: CsEmptyStatement) = # ES
  echo "in method add*(parent: CsWhileStatement; item: CsEmptyStatement)"
  todoimplAdd() # TODO(add: CsWhileStatement, CsEmptyStatement)

method add*(parent: CsWhileStatement; item: CsForStatement) = # FS
  echo "in method add*(parent: CsWhileStatement; item: CsForStatement)"
  parent.body.add item

method add*(parent: CsWhileStatement; item: CsIfStatement) = # IS
  echo "in method add*(parent: CsWhileStatement; item: CsIfStatement)"
  parent.body.add item

method add*(parent: CsWhileStatement; item: CsIsPatternExpression) = # IPE
  echo "in method add*(parent: CsWhileStatement; item: CsIsPatternExpression)"
  parent.predicate = item

method add*(parent: CsWhileStatement; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsWhileStatement; item: CsMemberAccessExpression)"
  parent.exprThatLeadsToBoolean = item

method add*(parent: CsThrowStatement; item: CsCastExpression) = # CE
  echo "in method add*(parent: CsThrowStatement; item: CsCastExpression)"
  parent.body.add item

method add*(parent: CsThrowStatement; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsThrowStatement; item: CsMemberAccessExpression)"
  parent.body.add item

method add*(parent: CsThrowStatement; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsThrowStatement; item: CsParenthesizedExpression)"
  parent.body.add item

method add*(parent: CsIndexer; item: CsArrowExpressionClause) = # AEC
  echo "in method add*(parent: CsIndexer; item: CsArrowExpressionClause)"
  parent.body.add item

method add*(parent: CsIndexer; item: CsGenericName) = # GN
  echo "in method add*(parent: CsIndexer; item: CsGenericName)"
  parent.gotType = item

method add*(parent: CsIndexer; item: CsNullableType) = # NT
  echo "in method add*(parent: CsIndexer; item: CsNullableType)"
  parent.gotType = item

method add*(parent: CsIndexer; item: CsRefType) = # RT
  echo "in method add*(parent: CsIndexer; item: CsRefType)"
  parent.gotType = item

method add*(parent: CsConditionalExpression; item: CsArrayCreationExpression) = # ACE
  echo "in method add*(parent: CsConditionalExpression; item: CsArrayCreationExpression)"
  parent.addConditional(item)

method add*(parent: CsConditionalExpression; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsConditionalExpression; item: CsAwaitExpression)"
  parent.addConditional(item)

method add*(parent: CsConditionalExpression; item: CsConditionalAccessExpression) = # CAE
  echo "in method add*(parent: CsConditionalExpression; item: CsConditionalAccessExpression)"
  parent.addConditional(item)

method add*(parent: CsConditionalExpression; item: CsDefaultExpression) = # DE
  echo "in method add*(parent: CsConditionalExpression; item: CsDefaultExpression)"
  parent.addConditional(item)

method add*(parent: CsConditionalExpression; item: CsImplicitArrayCreationExpression) = # IACE
  echo "in method add*(parent: CsConditionalExpression; item: CsImplicitArrayCreationExpression)"
  parent.addConditional(item)

method add*(parent: CsConditionalExpression; item: CsIsPatternExpression) = # IPE
  echo "in method add*(parent: CsConditionalExpression; item: CsIsPatternExpression)"
  parent.predicate =item

method add*(parent: CsConditionalExpression; item: CsParenthesizedLambdaExpression) = # PLE
  echo "in method add*(parent: CsConditionalExpression; item: CsParenthesizedLambdaExpression)"
  parent.addConditional(item)

method add*(parent: CsVariableDeclarator; item: CsBracketedArgumentList) = # BAL
  echo "in method add*(parent: CsVariableDeclarator; item: CsBracketedArgumentList)"
  parent.bracketedArgumentList = item

method add*(parent: CsSimpleLambdaExpression; item: CsArrayCreationExpression) = # ACE
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsArrayCreationExpression)"
  parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsElementAccessExpression)"
  parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsImplicitArrayCreationExpression) = # IACE
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsImplicitArrayCreationExpression)"
  parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsInterpolatedStringExpression) = # ISE
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsInterpolatedStringExpression)"
  parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsPostfixUnaryExpression) = # PUE
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsPostfixUnaryExpression)"
  parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsThrowExpression) = # TE
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsThrowExpression)"
  parent.body.add item

method add*(parent: CsArgument; item: CsAliasQualifiedName) = # AQN
  echo "in method add*(parent: CsArgument; item: CsAliasQualifiedName)"
  todoimplAdd() # TODO(add: CsArgument, CsAliasQualifiedName)

method add*(parent: CsArgument; item: CsAnonymousMethodExpression) = # AME
  echo "in method add*(parent: CsArgument; item: CsAnonymousMethodExpression)"
  parent.expr = item

method add*(parent: CsArgument; item: CsBaseExpression) = # BE
  echo "in method add*(parent: CsArgument; item: CsBaseExpression)"
  parent.expr = item

method add*(parent: CsArgument; item: CsCheckedExpression) = # CE
  echo "in method add*(parent: CsArgument; item: CsCheckedExpression)"
  parent.expr = item

method add*(parent: CsArgument; item: CsGenericName) = # GN
  echo "in method add*(parent: CsArgument; item: CsGenericName)"
  todoimplAdd() # TODO(add: CsArgument, CsGenericName)

method add*(parent: CsArgument; item: CsImplicitObjectCreationExpression) = # IOCE
  echo "in method add*(parent: CsArgument; item: CsImplicitObjectCreationExpression)"
  todoimplAdd() # TODO(add: CsArgument, CsImplicitObjectCreationExpression)

method add*(parent: CsArgument; item: CsIsPatternExpression) = # IPE
  echo "in method add*(parent: CsArgument; item: CsIsPatternExpression)"
  parent.expr = item

method add*(parent: CsArgument; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsArgument; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsArgument; item: CsQueryExpression) = # QE
  echo "in method add*(parent: CsArgument; item: CsQueryExpression)"
  todoimplAdd() # TODO(add: CsArgument, CsQueryExpression)

method add*(parent: CsArgument; item: CsRangeExpression) = # RE
  echo "in method add*(parent: CsArgument; item: CsRangeExpression)"
  parent.expr = item

method add*(parent: CsReturnStatement; item: CsAnonymousObjectCreationExpression) = # AOCE
  echo "in method add*(parent: CsReturnStatement; item: CsAnonymousObjectCreationExpression)"
  parent.expr = item

method add*(parent: CsReturnStatement; item: CsCheckedExpression) = # CE
  echo "in method add*(parent: CsReturnStatement; item: CsCheckedExpression)"
  parent.expr = item

method add*(parent: CsReturnStatement; item: CsConditionalAccessExpression) = # CAE
  echo "in method add*(parent: CsReturnStatement; item: CsConditionalAccessExpression)"
  parent.expr = item

method add*(parent: CsReturnStatement; item: CsDefaultExpression) = # DE
  echo "in method add*(parent: CsReturnStatement; item: CsDefaultExpression)"
  parent.expr = item

method add*(parent: CsReturnStatement; item: CsQueryExpression) = # QE
  echo "in method add*(parent: CsReturnStatement; item: CsQueryExpression)"
  parent.expr = item

method add*(parent: CsReturnStatement; item: CsSwitchExpression) = # SE
  echo "in method add*(parent: CsReturnStatement; item: CsSwitchExpression)"
  parent.expr = item

method add*(parent: CsCheckedExpression; item: CsBinaryExpression) = # BE
  echo "in method add*(parent: CsCheckedExpression; item: CsBinaryExpression)"
  parent.body.add item

method add*(parent: CsCheckedExpression; item: CsCastExpression) = # CE
  echo "in method add*(parent: CsCheckedExpression; item: CsCastExpression)"
  parent.body.add item

method add*(parent: CsAnonymousObjectCreationExpression; item: CsAnonymousObjectMemberDeclarator) = # AOMD
  echo "in method add*(parent: CsAnonymousObjectCreationExpression; item: CsAnonymousObjectMemberDeclarator)"
  parent.members.add item

method add*(parent: CsDelegate; item: CsGenericName) = # GN
  echo "in method add*(parent: CsDelegate; item: CsGenericName)"
  parent.gotType = item

method add*(parent: CsDelegate; item: CsParameterList) = # PL
  echo "in method add*(parent: CsDelegate; item: CsParameterList)"
  parent.paramList = item

method add*(parent: CsForEachStatement; item: CsArrayCreationExpression) = # ACE
  echo "in method add*(parent: CsForEachStatement; item: CsArrayCreationExpression)"
  if parent.listPart.isNil: parent.listPart = item
  else:
    parent.body.add item

method add*(parent: CsForEachStatement; item: CsArrayType) = # AT
  echo "in method add*(parent: CsForEachStatement; item: CsArrayType)"
  parent.gotType = item

method add*(parent: CsForEachStatement; item: CsCastExpression) = # CE
  echo "in method add*(parent: CsForEachStatement; item: CsCastExpression)"
  todoimplAdd() # TODO(add: CsForEachStatement, CsCastExpression)

method add*(parent: CsForEachStatement; item: CsIfStatement) = # IS
  echo "in method add*(parent: CsForEachStatement; item: CsIfStatement)"
  parent.body.add item

method add*(parent: CsForEachStatement; item: CsImplicitArrayCreationExpression) = # IACE
  echo "in method add*(parent: CsForEachStatement; item: CsImplicitArrayCreationExpression)"
  todoimplAdd() # TODO(add: CsForEachStatement, CsImplicitArrayCreationExpression)

method add*(parent: CsForEachStatement; item: CsObjectCreationExpression) = # OCE
  echo "in method add*(parent: CsForEachStatement; item: CsObjectCreationExpression)"
  if parent.listPart.isNil: parent.listPart = item
  else: parent.body.add item

method add*(parent: CsForEachStatement; item: CsPostfixUnaryExpression) = # PUE
  echo "in method add*(parent: CsForEachStatement; item: CsPostfixUnaryExpression)"
  todoimplAdd() # TODO(add: CsForEachStatement, CsPostfixUnaryExpression)

method add*(parent: CsForEachStatement; item: CsThisExpression) = # TE
  echo "in method add*(parent: CsForEachStatement; item: CsThisExpression)"
  parent.listPart = item

method add*(parent: CsForEachStatement; item: CsYieldStatement) = # YS
  echo "in method add*(parent: CsForEachStatement; item: CsYieldStatement)"
  parent.body.add item

method add*(parent: CsInterpolation; item: CsInterpolationAlignmentClause) = # IAC
  echo "in method add*(parent: CsInterpolation; item: CsInterpolationAlignmentClause)"
  parent.align = item

method add*(parent: CsIsPatternExpression; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsIsPatternExpression; item: CsInvocationExpression)"
  parent.lhs = item

# method add*(parent: CsTypeArgumentList; item: CsPointerType) = # PT
#   echo "in method add*(parent: CsTypeArgumentList; item: CsPointerType)"
#   parent.gotType = item

method add*(parent: CsYieldStatement; item: CsThisExpression) = # TE
  echo "in method add*(parent: CsYieldStatement; item: CsThisExpression)"
  parent.expr = item

method add*(parent: CsTupleElement; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsTupleElement; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsTupleExpression; item: CsArgument) =
  echo "in method add*(parent: CsTupleExpression; item: CsArgument)"
  parent.args.add item

method add*(parent: CsElementAccessExpression; item: CsDefaultExpression) = # DE
  echo "in method add*(parent: CsElementAccessExpression; item: CsDefaultExpression)"
  assert parent.lhs.isNil # todo: can it be in either side?
  parent.lhs = item

method add*(parent: CsElementAccessExpression; item: CsImplicitArrayCreationExpression) = # IACE
  echo "in method add*(parent: CsElementAccessExpression; item: CsImplicitArrayCreationExpression)"
  todoimplAdd() # TODO(add: CsElementAccessExpression, CsImplicitArrayCreationExpression)

method add*(parent: CsArrayType; item: CsPointerType) = # PT
  echo "in method add*(parent: CsArrayType; item: CsPointerType)"
  parent.gotType = item

method add*(parent: CsAwaitExpression; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsAwaitExpression; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsAwaitExpression, CsLiteralExpression)

method add*(parent: CsMemberAccessExpression; item: CsDefaultExpression) = # DE
  echo "in method add*(parent: CsMemberAccessExpression; item: CsDefaultExpression)"
  parent.left = item

method add*(parent: CsInitializerExpression; item: CsAnonymousMethodExpression) = # AME
  echo "in method add*(parent: CsInitializerExpression; item: CsAnonymousMethodExpression)"
  parent.bexprs.add item

method add*(parent: CsInitializerExpression; item: CsTupleExpression) = # TE
  echo "in method add*(parent: CsInitializerExpression; item: CsTupleExpression)"
  parent.bexprs.add item

method add*(parent: CsExpressionStatement; item: CsQueryExpression) = # QE
  echo "in method add*(parent: CsExpressionStatement; item: CsQueryExpression)"
  parent.expr = item

method add*(parent: CsLockStatement; item: CsEmptyStatement) = # ES
  echo "in method add*(parent: CsLockStatement; item: CsEmptyStatement)"
  parent.body.add item

method add*(parent: CsLockStatement; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsLockStatement; item: CsLiteralExpression)"
  parent.locker = item

method add*(parent: CsSwitchSection; item: CsCaseSwitchLabel) = # CSL
  echo "in method add*(parent: CsSwitchSection; item: CsCaseSwitchLabel)"
  parent.caseName = item

method add*(parent: CsProperty; item: CsPointerType) = # PT
  echo "in method add*(parent: CsProperty; item: CsPointerType)"
  parent.gotType = item

method add*(parent: CsProperty; item: CsRefType) = # RT
  echo "in method add*(parent: CsProperty; item: CsRefType)"
  parent.gotType = item

method add*(parent: CsBinaryExpression; item: CsAnonymousMethodExpression) = # AME
  echo "in method add*(parent: CsBinaryExpression; item: CsAnonymousMethodExpression)"
  parent.right = item

method add*(parent: CsBinaryExpression; item: CsTupleExpression) = # TE
  echo "in method add*(parent: CsBinaryExpression; item: CsTupleExpression)"
  todoimplAdd() # TODO(add: CsBinaryExpression, CsTupleExpression)

method add*(parent: CsInterface; item: CsTypeParameterConstraintClause) = # TPCC
  echo "in method add*(parent: CsInterface; item: CsTypeParameterConstraintClause)"
  parent.typeParamsConstraint = item

method add*(parent: CsObjectCreationExpression; item: CsNullableType) = # NT
  echo "in method add*(parent: CsObjectCreationExpression; item: CsNullableType)"
  parent.gotType = item

method add*(parent: CsObjectCreationExpression; item: CsTupleType) = # TT
  echo "in method add*(parent: CsObjectCreationExpression; item: CsTupleType)"
  parent.gotType = item

method add*(parent: CsParameter; item: CsTupleType) = # TT
  echo "in method add*(parent: CsParameter; item: CsTupleType)"
  parent.gotType = item

# proc addAssignment(parent: CsAssignmentExpression;it:BodyExpr) =
#   if parent.left.isNil: parent.left = it
#   elif parent.right.isNil: parent.right = it
#   else: assert false

method add*(parent: CsAssignmentExpression; item: CsBaseExpression) = # BE
  echo "in method add*(parent: CsAssignmentExpression; item: CsBaseExpression)"
  parent.addAssign(item)

method add*(parent: CsVariable; item: CsTupleType) = # TT
  echo "in method add*(parent: CsVariable; item: CsTupleType)"
  parent.gotType = item

method add*(parent: CsNamespace; item: CsAliasQualifiedName) = # AQN
  echo "in method add*(parent: CsNamespace; item: CsAliasQualifiedName)"
  todoimplAdd() # TODO(add: CsNamespace, CsAliasQualifiedName)

method add*(parent: CsConditionalAccessExpression; item: CsElementBindingExpression) = # EBE
  echo "in method add*(parent: CsConditionalAccessExpression; item: CsElementBindingExpression)"
  parent.rhs = item

method add*(parent: CsConditionalAccessExpression; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsConditionalAccessExpression; item: CsLiteralExpression)"
  parent.lhs = item

method add*(parent: CsConditionalAccessExpression; item: CsThisExpression) = # TE
  echo "in method add*(parent: CsConditionalAccessExpression; item: CsThisExpression)"
  parent.lhs = item

method add*(parent: CsDefaultExpression; item: CsGenericName) = # GN
  echo "in method add*(parent: CsDefaultExpression; item: CsGenericName)"
  parent.gotType = item

method add*(parent: CsStruct; item: CsStruct) = #forward to NS
  echo "in method add*(parent: CsStruct; item: CsStruct)"
  item.name = parent.name & "." & item.name
  parent.ns.add item # storing in the common namespace.
  # note: we prefer a shallow hierarchy, but the names retain uniqueness (more or less)
  # and in fact, probably nim only supports the simple shallow case (for simpler code).
method add*(parent: CsElseClause; item: CsBreakStatement) = # BS
  echo "in method add*(parent: CsElseClause; item: CsBreakStatement)"
  parent.body.add item

method add*(parent: CsInvocationExpression; item: CsAliasQualifiedName) = # AQN
  echo "in method add*(parent: CsInvocationExpression; item: CsAliasQualifiedName)"
  todoimplAdd() # TODO(add: CsInvocationExpression, CsAliasQualifiedName)

method add*(parent: CsInvocationExpression; item: CsMemberBindingExpression) = # MBE
  echo "in method add*(parent: CsInvocationExpression; item: CsMemberBindingExpression)"
  parent.rhs = item

method add*(parent: CsIndexer; item: CsPointerType) = # PT
  echo "in method add*(parent: CsIndexer; item: CsPointerType)"
  parent.gotType = item

method add*(parent: CsConditionalExpression; item: CsThrowExpression) = # TE
  echo "in method add*(parent: CsConditionalExpression; item: CsThrowExpression)"
  parent.addConditional(item)

method add*(parent: CsTypeParameterConstraintClause; item: CsConstructorConstraint) = # CC
  echo "in method add*(parent: CsTypeParameterConstraintClause; item: CsConstructorConstraint)"
  parent.constraints.add item

method add*(parent: CsTypeConstraint; item: CsArrayType) = # AT
  echo "in method add*(parent: CsTypeConstraint; item: CsArrayType)"
  parent.gotType = item

method add*(parent: CsTypeConstraint; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsTypeConstraint; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsRefType; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsRefType; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsReturnStatement; item: CsIsPatternExpression) = # IPE
  echo "in method add*(parent: CsReturnStatement; item: CsIsPatternExpression)"
  parent.expr = item

method add*(parent: CsReturnStatement; item: CsRefExpression) = # RE
  echo "in method add*(parent: CsReturnStatement; item: CsRefExpression)"
  parent.expr = item

method add*(parent: CsThrowExpression; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsThrowExpression; item: CsLiteralExpression)"
  parent.expr = item

method add*(parent: CsForEachStatement; item: CsAnonymousMethodExpression) = # AME
  echo "in method add*(parent: CsForEachStatement; item: CsAnonymousMethodExpression)"
  todoimplAdd() # TODO(add: CsForEachStatement, CsAnonymousMethodExpression)

method add*(parent: CsForEachStatement; item: CsEmptyStatement) = # ES
  echo "in method add*(parent: CsForEachStatement; item: CsEmptyStatement)"
  parent.body.add item

method add*(parent: CsForEachStatement; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsForEachStatement; item: CsLiteralExpression)"
  if parent.listPart.isNil: parent.listPart = item
  else: parent.body.add item

method add*(parent: CsDeclarationPattern; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsDeclarationPattern; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsDeclarationPattern; item: CsSingleVariableDesignation) = # SVD
  echo "in method add*(parent: CsDeclarationPattern; item: CsSingleVariableDesignation)"
  parent.svd = item

method add*(parent: CsIsPatternExpression; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsIsPatternExpression; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsIsPatternExpression, CsLiteralExpression)

method add*(parent: CsGotoStatement; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsGotoStatement; item: CsLiteralExpression)"
  parent.gotoCase = item

method add*(parent: CsParenthesizedLambdaExpression; item: CsAnonymousMethodExpression) = # AME
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsAnonymousMethodExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedLambdaExpression; item: CsIsPatternExpression) = # IPE
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsIsPatternExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedLambdaExpression; item: CsTupleExpression) = # TE
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsTupleExpression)"
  todoimplAdd() # TODO(add: CsParenthesizedLambdaExpression, CsTupleExpression)

method add*(parent: CsYieldStatement; item: CsCastExpression) = # CE
  echo "in method add*(parent: CsYieldStatement; item: CsCastExpression)"
  parent.expr = item

method add*(parent: CsYieldStatement; item: CsPrefixUnaryExpression) = # PUE
  echo "in method add*(parent: CsYieldStatement; item: CsPrefixUnaryExpression)"
  parent.expr = item

method add*(parent: CsTupleElement; item: CsNullableType) = # NT
  echo "in method add*(parent: CsTupleElement; item: CsNullableType)"
  parent.gotType = item

method add*(parent: CsTupleElement; item: CsTupleType) = # TT
  echo "in method add*(parent: CsTupleElement; item: CsTupleType)"
  parent.gotType = item

method add*(parent: CsAwaitExpression; item: CsObjectCreationExpression) = # OCE
  echo "in method add*(parent: CsAwaitExpression; item: CsObjectCreationExpression)"
  todoimplAdd() # TODO(add: CsAwaitExpression, CsObjectCreationExpression)

method add*(parent: CsArrowExpressionClause; item: CsRefExpression) = # RE
  echo "in method add*(parent: CsArrowExpressionClause; item: CsRefExpression)"
  parent.body.add item

method add*(parent: CsMemberAccessExpression; item: CsElementBindingExpression) = # EBE
  echo "in method add*(parent: CsMemberAccessExpression; item: CsElementBindingExpression)"
  parent.right = item

method add*(parent: CsInitializerExpression; item: CsAnonymousObjectCreationExpression) = # AOCE
  echo "in method add*(parent: CsInitializerExpression; item: CsAnonymousObjectCreationExpression)"
  parent.bexprs.add item

method add*(parent: CsParenthesizedVariableDesignation; item: CsSingleVariableDesignation) = # SVD
  echo "in method add*(parent: CsParenthesizedVariableDesignation; item: CsSingleVariableDesignation)"
  parent.val = item

method add*(parent: CsConstantPattern; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsConstantPattern; item: CsLiteralExpression)"
  parent.lit = item

method add*(parent: CsPrefixUnaryExpression; item: CsThisExpression) = # TE
  echo "in method add*(parent: CsPrefixUnaryExpression; item: CsThisExpression)"
  parent.actingOn = item

method add*(parent: CsLockStatement; item: CsAssignmentExpression) = # AE
  echo "in method add*(parent: CsLockStatement; item: CsAssignmentExpression)"
  if parent.locker.isNil:
    parent.locker = item
  else: assert false # todo(maybe): add cases here after seeing an example

method add*(parent: CsLockStatement; item: CsObjectCreationExpression) = # OCE
  echo "in method add*(parent: CsLockStatement; item: CsObjectCreationExpression)"
  todoimplAdd() # TODO(add: CsLockStatement, CsObjectCreationExpression)

method add*(parent: CsParenthesizedExpression; item: CsAnonymousMethodExpression) = # AME
  echo "in method add*(parent: CsParenthesizedExpression; item: CsAnonymousMethodExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedExpression; item: CsConditionalAccessExpression) = # CAE
  echo "in method add*(parent: CsParenthesizedExpression; item: CsConditionalAccessExpression)"
  parent.body.add item

method add*(parent: CsSwitchSection; item: CsCasePatternSwitchLabel) = # CPSL
  echo "in method add*(parent: CsSwitchSection; item: CsCasePatternSwitchLabel)"
  parent.casePattern = item

method add*(parent: CsSwitchSection; item: CsDefaultSwitchLabel) = # DSL
  echo "in method add*(parent: CsSwitchSection; item: CsDefaultSwitchLabel)"
  parent.default = item

method add*(parent: CsProperty; item: CsTupleType) = # TT
  echo "in method add*(parent: CsProperty; item: CsTupleType)"
  parent.gotType = item

method add*(parent: CsCastExpression; item: CsAnonymousMethodExpression) = # AME
  echo "in method add*(parent: CsCastExpression; item: CsAnonymousMethodExpression)"
  parent.expr = item

method add*(parent: CsCastExpression; item: CsBaseExpression) = # BE
  echo "in method add*(parent: CsCastExpression; item: CsBaseExpression)"
  parent.expr = item

method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsNameEquals) = # NE
  echo "in method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsNameEquals)"
  parent.memberName = item

method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsObjectCreationExpression) = # OCE
  echo "in method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsObjectCreationExpression)"
  parent.value = item

method add*(parent: CsObjectCreationExpression; item: CsAliasQualifiedName) = # AQN
  echo "in method add*(parent: CsObjectCreationExpression; item: CsAliasQualifiedName)"
  todoimplAdd() # TODO(add: CsObjectCreationExpression, CsAliasQualifiedName)

method add*(parent: CsCatchFilterClause; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsCatchFilterClause; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsCatchFilterClause, CsLiteralExpression)

method add*(parent: CsMethod; item: CsAliasQualifiedName) = # AQN
  echo "in method add*(parent: CsMethod; item: CsAliasQualifiedName)"
  todoimplAdd() # TODO(add: CsMethod, CsAliasQualifiedName)

method add*(parent: CsDefaultExpression; item: CsNullableType) = # NT
  echo "in method add*(parent: CsDefaultExpression; item: CsNullableType)"
  parent.gotType = item

method add*(parent: CsStruct; item: CsIndexer) =
  echo "in method add*(parent: CsStruct; item: CsIndexer)"
  parent.indexers.add item

method add*(parent: CsForStatement; item: CsIsPatternExpression) = # IPE
  echo "in method add*(parent: CsForStatement; item: CsIsPatternExpression)"
  parent.forPart2AsPattern = item

method add*(parent: CsElseClause; item: CsEmptyStatement) = # ES
  echo "in method add*(parent: CsElseClause; item: CsEmptyStatement)"
  parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsAwaitExpression)"
  parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsConditionalAccessExpression) = # CAE
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsConditionalAccessExpression)"
  parent.body.add item

method add*(parent: CsStackAllocArrayCreationExpression; item: CsArrayType) = # AT
  echo "in method add*(parent: CsStackAllocArrayCreationExpression; item: CsArrayType)"
  parent.gotType = item

method add*(parent: CsStackAllocArrayCreationExpression; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsStackAllocArrayCreationExpression; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsIncompleteMember; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsIncompleteMember; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsIncompleteMember; item: CsTupleType) = # TT
  echo "in method add*(parent: CsIncompleteMember; item: CsTupleType)"
  parent.gotType = item

method add*(parent: CsArgument; item: CsOmittedArraySizeExpression) = # OASE
  echo "in method add*(parent: CsArgument; item: CsOmittedArraySizeExpression)"
  parent.expr = item

method add*(parent: CsRefType; item: CsGenericName) = # GN
  echo "in method add*(parent: CsRefType; item: CsGenericName)"
  parent.gotType = item

method add*(parent: CsReturnStatement; item: CsAnonymousMethodExpression) = # AME
  echo "in method add*(parent: CsReturnStatement; item: CsAnonymousMethodExpression)"
  parent.expr = item

method add*(parent: CsReturnStatement; item: CsTupleExpression) = # TE
  echo "in method add*(parent: CsReturnStatement; item: CsTupleExpression)"
  parent.expr = item

method add*(parent: CsThrowExpression; item: CsObjectCreationExpression) = # OCE
  echo "in method add*(parent: CsThrowExpression; item: CsObjectCreationExpression)"
  parent.expr = item

method add*(parent: CsDelegate; item: CsArrayType) = # AT
  echo "in method add*(parent: CsDelegate; item: CsArrayType)"
  parent.gotType = item

method add*(parent: CsDelegate; item: CsPointerType) = # PT
  echo "in method add*(parent: CsDelegate; item: CsPointerType)"
  parent.gotType = item

method add*(parent: CsDelegate; item: CsRefType) = # RT
  echo "in method add*(parent: CsDelegate; item: CsRefType)"
  parent.gotType = item

method add*(parent: CsDelegate; item: CsTypeParameterConstraintClause) = # TPCC
  echo "in method add*(parent: CsDelegate; item: CsTypeParameterConstraintClause)"
  parent.typeParamsConstraint = item

method add*(parent: CsDeclarationPattern; item: CsGenericName) = # GN
  echo "in method add*(parent: CsDeclarationPattern; item: CsGenericName)"
  parent.gotType = item

method add*(parent: CsRefExpression; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsRefExpression; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsRefExpression, CsLiteralExpression)

method add*(parent: CsCaseSwitchLabel; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsCaseSwitchLabel; item: CsLiteralExpression)"
  parent.caseName = item

method add*(parent: CsSwitchSection; item: CsBreakStatement) = # BS
  echo "in method add*(parent: CsSwitchSection; item: CsBreakStatement)"
  parent.body.add item

method add*(parent: CsInterpolationAlignmentClause; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsInterpolationAlignmentClause; item: CsLiteralExpression)"
  parent.number = item

method add*(parent: CsElementBindingExpression; item: CsBracketedArgumentList) = # BAL
  echo "in method add*(parent: CsElementBindingExpression; item: CsBracketedArgumentList)"
  parent.val = item

method add*(parent: CsRefExpression; item: CsConditionalExpression) = # CE
  echo "in method add*(parent: CsRefExpression; item: CsConditionalExpression)"
  parent.expr = item

method add*(parent: CsAliasQualifiedName; item: CsGenericName) = # GN
  echo "in method add*(parent: CsAliasQualifiedName; item: CsGenericName)"
  todoimplAdd() # TODO(add: CsAliasQualifiedName, CsGenericName)

method add*(parent: CsConstantPattern; item: CsPrefixUnaryExpression) = # PUE
  echo "in method add*(parent: CsConstantPattern; item: CsPrefixUnaryExpression)"
  parent.val = item

method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsLiteralExpression)"
  parent.value = item

method add*(parent: CsCatchFilterClause; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsCatchFilterClause; item: CsAwaitExpression)"
  todoimplAdd() # TODO(add: CsCatchFilterClause, CsAwaitExpression)

method add*(parent: CsCatchFilterClause; item: CsBinaryExpression) = # BE
  echo "in method add*(parent: CsCatchFilterClause; item: CsBinaryExpression)"
  parent.predicate = item

method add*(parent: CsInterpolationAlignmentClause; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsInterpolationAlignmentClause; item: CsInvocationExpression)"
  todoimplAdd() # TODO(add: CsInterpolationAlignmentClause, CsInvocationExpression)

method add*(parent: CsInterpolationAlignmentClause; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsInterpolationAlignmentClause; item: CsMemberAccessExpression)"
  todoimplAdd() # TODO(add: CsInterpolationAlignmentClause, CsMemberAccessExpression)

method add*(parent: CsCaseSwitchLabel; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsCaseSwitchLabel; item: CsMemberAccessExpression)"
  parent.other = item

method add*(parent: CsCheckedExpression; item: CsAnonymousMethodExpression) = # AME
  echo "in method add*(parent: CsCheckedExpression; item: CsAnonymousMethodExpression)"
  todoimplAdd() # TODO(add: CsCheckedExpression, CsAnonymousMethodExpression)

method add*(parent: CsRefExpression; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsRefExpression; item: CsMemberAccessExpression)"
  parent.expr = item

method add*(parent: CsConstantPattern; item: CsBinaryExpression) = # BE
  echo "in method add*(parent: CsConstantPattern; item: CsBinaryExpression)"
  parent.valExpr = item

method add*(parent: CsSwitchSection; item: CsExpressionStatement) = # ES
  echo "in method add*(parent: CsSwitchSection; item: CsExpressionStatement)"
  parent.body.add item

method add*(parent: CsSwitchSection; item: CsGotoStatement) = # GS
  echo "in method add*(parent: CsSwitchSection; item: CsGotoStatement)"
  parent.body.add item

method add*(parent: CsSwitchSection; item: CsLabeledStatement) = # LS
  echo "in method add*(parent: CsSwitchSection; item: CsLabeledStatement)"
  parent.body.add item

method add*(parent: CsSwitchSection; item: CsReturnStatement) = # RS
  echo "in method add*(parent: CsSwitchSection; item: CsReturnStatement)"
  parent.body.add item

method add*(parent: CsSwitchSection; item: CsThrowStatement) = # TS
  echo "in method add*(parent: CsSwitchSection; item: CsThrowStatement)"
  parent.body.add item

method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsAnonymousMethodExpression) = # AME
  echo "in method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsAnonymousMethodExpression)"
  todoimplAdd() # TODO(add: CsAnonymousObjectMemberDeclarator, CsAnonymousMethodExpression)

method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsInvocationExpression)"
  parent.value = item

method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsSimpleLambdaExpression) = # SLE
  echo "in method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsSimpleLambdaExpression)"
  todoimplAdd() # TODO(add: CsAnonymousObjectMemberDeclarator, CsSimpleLambdaExpression)

method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsTupleExpression) = # TE
  echo "in method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsTupleExpression)"
  todoimplAdd() # TODO(add: CsAnonymousObjectMemberDeclarator, CsTupleExpression)

method add*(parent: CsSwitchSection; item: CsLocalDeclarationStatement) = # LDS
  echo "in method add*(parent: CsSwitchSection; item: CsLocalDeclarationStatement)"
  parent.body.add item

method add*(parent: CsConditionalExpression; item: CsRefExpression) = # RE
  echo "in method add*(parent: CsConditionalExpression; item: CsRefExpression)"
  parent.addConditional(item)

method add*(parent: CsLabeledStatement; item: CsBreakStatement) = # BS
  echo "in method add*(parent: CsLabeledStatement; item: CsBreakStatement)"
  parent.body.add item

method add*(parent: CsInterpolation; item: CsConditionalAccessExpression) = # CAE
  echo "in method add*(parent: CsInterpolation; item: CsConditionalAccessExpression)"
  parent.expr = item

method add*(parent: CsIsPatternExpression; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsIsPatternExpression; item: CsElementAccessExpression)"
  if parent.lhs.isNil:
    parent.lhs = item
  # elif parent.rhs.isNil:
  #   parent.rhs = item
  else: assert false

method add*(parent: CsRefExpression; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsRefExpression; item: CsElementAccessExpression)"
  parent.expr = item

method add*(parent: CsTupleElement; item: CsGenericName) = # GN
  echo "in method add*(parent: CsTupleElement; item: CsGenericName)"
  parent.gotType = item

method add*(parent: CsMemberAccessExpression; item: CsMemberBindingExpression) = # MBE
  echo "in method add*(parent: CsMemberAccessExpression; item: CsMemberBindingExpression)"
  parent.right = item

method add*(parent: CsLockStatement; item: CsExpressionStatement) = # ES
  echo "in method add*(parent: CsLockStatement; item: CsExpressionStatement)"
  parent.body.add item

method add*(parent: CsQueryBody; item: CsLetClause) = # LC
  echo "in method add*(parent: CsQueryBody; item: CsLetClause)"
  parent.letClause = item

method add*(parent: CsConditionalAccessExpression; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsConditionalAccessExpression; item: CsElementAccessExpression)"
  if parent.lhs.isNil:
    parent.lhs  = item
  elif parent.rhs.isNil:
    parent.rhs = item
  else: assert false

method add*(parent: CsRefExpression; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsRefExpression; item: CsInvocationExpression)"
  parent.expr = item

method add*(parent: CsTupleElement; item: CsArrayType) = # AT
  echo "in method add*(parent: CsTupleElement; item: CsArrayType)"
  parent.gotType = item

method add*(parent: CsPrefixUnaryExpression; item: CsConditionalAccessExpression) = # CAE
  echo "in method add*(parent: CsPrefixUnaryExpression; item: CsConditionalAccessExpression)"
  todoimplAdd() # TODO(add: CsPrefixUnaryExpression, CsConditionalAccessExpression)

method add*(parent: CsCasePatternSwitchLabel; item: CsDeclarationPattern) = # DP
  echo "in method add*(parent: CsCasePatternSwitchLabel; item: CsDeclarationPattern)"
  parent.pattern = item

method add*(parent: CsSwitchSection; item: CsIfStatement) = # IS
  echo "in method add*(parent: CsSwitchSection; item: CsIfStatement)"
  parent.body.add item

method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsMemberAccessExpression)"
  parent.value = item

method add*(parent: CsAssignmentExpression; item: CsAnonymousObjectCreationExpression) = # AOCE
  echo "in method add*(parent: CsAssignmentExpression; item: CsAnonymousObjectCreationExpression)"
  todoimplAdd() # TODO(add: CsAssignmentExpression, CsAnonymousObjectCreationExpression)

method add*(parent: CsUnaryPattern; item: CsConstantPattern) = # CP
  echo "in method add*(parent: CsUnaryPattern; item: CsConstantPattern)"
  parent.pattern = item

method add*(parent: CsIncompleteMember; item: CsGenericName) = # GN
  echo "in method add*(parent: CsIncompleteMember; item: CsGenericName)"
  todoimplAdd() # TODO(add: CsIncompleteMember, CsGenericName)

method add*(parent: CsCheckedExpression; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsCheckedExpression; item: CsParenthesizedExpression)"
  todoimplAdd() # TODO(add: CsCheckedExpression, CsParenthesizedExpression)

method add*(parent: CsForEachStatement; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsForEachStatement; item: CsAwaitExpression)"
  todoimplAdd() # TODO(add: CsForEachStatement, CsAwaitExpression)

method add*(parent: CsForEachStatement; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsForEachStatement; item: CsElementAccessExpression)"
  todoimplAdd() # TODO(add: CsForEachStatement, CsElementAccessExpression)

method add*(parent: CsArrayRankSpecifier; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsArrayRankSpecifier; item: CsElementAccessExpression)"
  todoimplAdd() # TODO(add: CsArrayRankSpecifier, CsElementAccessExpression)

method add*(parent: CsYieldStatement; item: CsTupleExpression) = # TE
  echo "in method add*(parent: CsYieldStatement; item: CsTupleExpression)"
  parent.expr = item

method add*(parent: CsSwitchExpression; item: CsSwitchExpressionArm) = # SEA
  echo "in method add*(parent: CsSwitchExpression; item: CsSwitchExpressionArm)"
  parent.arm = item

method add*(parent: CsParenthesizedVariableDesignation; item: CsDiscardDesignation) = # DD
  echo "in method add*(parent: CsParenthesizedVariableDesignation; item: CsDiscardDesignation)"
  parent.dis = item

method add*(parent: CsSwitchSection; item: CsForEachStatement) = # FES
  echo "in method add*(parent: CsSwitchSection; item: CsForEachStatement)"
  parent.body.add item

method add*(parent: CsSwitchSection; item: CsSwitchStatement) = # SS
  echo "in method add*(parent: CsSwitchSection; item: CsSwitchStatement)"
  parent.body.add item

method add*(parent: CsAssignmentExpression; item: CsQueryExpression) = # QE
  echo "in method add*(parent: CsAssignmentExpression; item: CsQueryExpression)"
  parent.right = item

method add*(parent: CsMemberBindingExpression; item: CsGenericName) = # GN
  echo "in method add*(parent: CsMemberBindingExpression; item: CsGenericName)"
  parent.genericName = item

method add*(parent: CsStruct; item: CsTypeParameterConstraintClause) = # TPCC
  echo "in method add*(parent: CsStruct; item: CsTypeParameterConstraintClause)"
  parent.typeParamsConstraint = item

method add*(parent: CsIfStatement; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsIfStatement; item: CsAwaitExpression)"
  if parent.hasNoPredicate:
    parent.exprThatLeadsToBoolean = item
  else:
    parent.body.add item

method add*(parent: CsElseClause; item: CsContinueStatement) = # CS
  echo "in method add*(parent: CsElseClause; item: CsContinueStatement)"
  parent.body.add item

method add*(parent: CsElseClause; item: CsYieldStatement) = # YS
  echo "in method add*(parent: CsElseClause; item: CsYieldStatement)"
  parent.body.add item

method add*(parent: CsForEachStatement; item: CsBinaryExpression) = # BE
  echo "in method add*(parent: CsForEachStatement; item: CsBinaryExpression)"
  todoimplAdd() # TODO(add: CsForEachStatement, CsBinaryExpression)

method add*(parent: CsForEachStatement; item: CsForEachStatement) = # FES
  echo "in method add*(parent: CsForEachStatement; item: CsForEachStatement)"
  parent.body.add item

method add*(parent: CsRangeExpression; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsRangeExpression; item: CsElementAccessExpression)"
  todoimplAdd() # TODO(add: CsRangeExpression, CsElementAccessExpression)

method add*(parent: CsSwitchStatement; item: CsThisExpression) = # TE
  echo "in method add*(parent: CsSwitchStatement; item: CsThisExpression)"
  parent.on = item

method add*(parent: CsForStatement; item: CsWhileStatement) = # WS
  echo "in method add*(parent: CsForStatement; item: CsWhileStatement)"
  parent.body.add item

method add*(parent: CsInvocationExpression; item: CsBaseExpression) = # BE
  echo "in method add*(parent: CsInvocationExpression; item: CsBaseExpression)"
  todoimplAdd() # TODO(add: CsInvocationExpression, CsBaseExpression)

method add*(parent: CsWhileStatement; item: CsYieldStatement) = # YS
  echo "in method add*(parent: CsWhileStatement; item: CsYieldStatement)"
  todoimplAdd() # TODO(add: CsWhileStatement, CsYieldStatement)

method add*(parent: CsDeclarationPattern; item: CsDiscardDesignation) = # DD
  echo "in method add*(parent: CsDeclarationPattern; item: CsDiscardDesignation)"
  todoimplAdd() # TODO(add: CsDeclarationPattern, CsDiscardDesignation)

method add*(parent: CsImplicitObjectCreationExpression; item: CsArgumentList) = # AL
  echo "in method add*(parent: CsImplicitObjectCreationExpression; item: CsArgumentList)"
  parent.args = item

method add*(parent: CsSwitchExpressionArm; item: CsConstantPattern) = # CP
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsConstantPattern)"
  parent.pat = item

method add*(parent: CsLockStatement; item: CsReturnStatement) = # RS
  echo "in method add*(parent: CsLockStatement; item: CsReturnStatement)"
  parent.body.add item

method add*(parent: CsBinaryExpression; item: CsRangeExpression) = # RE
  echo "in method add*(parent: CsBinaryExpression; item: CsRangeExpression)"
  todoimplAdd() # TODO(add: CsBinaryExpression, CsRangeExpression)

method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsAnonymousObjectCreationExpression) = # AOCE
  echo "in method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsAnonymousObjectCreationExpression)"
  parent.value = item

method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsImplicitArrayCreationExpression) = # IACE
  echo "in method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsImplicitArrayCreationExpression)"
  todoimplAdd() # TODO(add: CsAnonymousObjectMemberDeclarator, CsImplicitArrayCreationExpression)

method add*(parent: CsIfStatement; item: CsLockStatement) = # LS
  echo "in method add*(parent: CsIfStatement; item: CsLockStatement)"
  parent.body.add item

method add*(parent: CsConditionalExpression; item: CsPostfixUnaryExpression) = # PUE
  echo "in method add*(parent: CsConditionalExpression; item: CsPostfixUnaryExpression)"
  parent.addConditional(item)

method add*(parent: CsSimpleLambdaExpression; item: CsDefaultExpression) = # DE
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsDefaultExpression)"
  parent.body.add item

method add*(parent: CsForEachStatement; item: CsQueryExpression) = # QE
  echo "in method add*(parent: CsForEachStatement; item: CsQueryExpression)"
  todoimplAdd() # TODO(add: CsForEachStatement, CsQueryExpression)

method add*(parent: CsRangeExpression; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsRangeExpression; item: CsLiteralExpression)"
  # hmm, cannot know if it's the from or the to. better get this from the extract portion.
  parent.items.add item # just two (or one), but we don't know their order, so we can probably sort it later.
  #examples:  2.. ..3 ..-1 0..seq.len-1 some.Value..other.Val, 2..7



method add*(parent: CsYieldStatement; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsYieldStatement; item: CsElementAccessExpression)"
  parent.expr = item

method add*(parent: CsArrowExpressionClause; item: CsTupleExpression) = # TE
  echo "in method add*(parent: CsArrowExpressionClause; item: CsTupleExpression)"
  parent.body.add item

method add*(parent: CsArgumentList; item: CsGenericName) = # GN
  echo "in method add*(parent: CsArgumentList; item: CsGenericName)"
  parent.genericName = item

method add*(parent: CsCastExpression; item: CsCheckedExpression) = # CE
  echo "in method add*(parent: CsCastExpression; item: CsCheckedExpression)"
  parent.expr = item

method add*(parent: CsCaseSwitchLabel; item: CsCastExpression) = # CE
  echo "in method add*(parent: CsCaseSwitchLabel; item: CsCastExpression)"
  parent.other = item

method add*(parent: CsThrowExpression; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsThrowExpression; item: CsInvocationExpression)"
  parent.expr = item

method add*(parent: CsParenthesizedLambdaExpression; item: CsQueryExpression) = # QE
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsQueryExpression)"
  parent.body.add item

method add*(parent: CsSwitchSection; item: CsContinueStatement) = # CS
  echo "in method add*(parent: CsSwitchSection; item: CsContinueStatement)"
  parent.body.add item

method add*(parent: CsProperty; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsProperty; item: CsInvocationExpression)"
  todoimplAdd() # TODO(add: CsProperty, CsInvocationExpression)

method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsBinaryExpression) = # BE
  echo "in method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsBinaryExpression)"
  parent.value  = item

method add*(parent: CsInterface; item: CsInterface) =
  echo "in method add*(parent: CsInterface; item: CsInterface)"
  todoimplAdd() # TODO(add: CsInterface, CsInterface)

method add*(parent: CsWhileStatement; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsWhileStatement; item: CsAwaitExpression)"
  todoimplAdd() # TODO(add: CsWhileStatement, CsAwaitExpression)

method add*(parent: CsSimpleLambdaExpression; item: CsIsPatternExpression) = # IPE
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsIsPatternExpression)"
  parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsTupleExpression) = # TE
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsTupleExpression)"
  parent.body.add item

method add*(parent: CsLetClause; item: CsQueryExpression) = # QE
  echo "in method add*(parent: CsLetClause; item: CsQueryExpression)"
  parent.value = item

method add*(parent: CsParenthesizedLambdaExpression; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsParenthesizedExpression)"
  parent.body.add item

method add*(parent: CsYieldStatement; item: CsImplicitArrayCreationExpression) = # IACE
  echo "in method add*(parent: CsYieldStatement; item: CsImplicitArrayCreationExpression)"
  parent.expr = item

method add*(parent: CsConstantPattern; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsConstantPattern; item: CsMemberAccessExpression)"
  if parent.keyExpr.isNil:
    parent.keyExpr = item
  else: assert false, "need to see an example"

method add*(parent: CsCasePatternSwitchLabel; item: CsConstantPattern) = # CP
  echo "in method add*(parent: CsCasePatternSwitchLabel; item: CsConstantPattern)"
  todoimplAdd() # TODO(add: CsCasePatternSwitchLabel, CsConstantPattern)

method add*(parent: CsBinaryExpression; item: CsBaseExpression) = # BE
  echo "in method add*(parent: CsBinaryExpression; item: CsBaseExpression)"
  todoimplAdd() # TODO(add: CsBinaryExpression, CsBaseExpression)

method add*(parent: CsNullableType; item: CsTupleType) = # TT
  echo "in method add*(parent: CsNullableType; item: CsTupleType)"
  parent.gotType = item

method add*(parent: CsIfStatement; item: CsSwitchStatement) = # SS
  echo "in method add*(parent: CsIfStatement; item: CsSwitchStatement)"
  parent.body.add item

method add*(parent: CsForStatement; item: CsSwitchStatement) = # SS
  echo "in method add*(parent: CsForStatement; item: CsSwitchStatement)"
  parent.body.add item

method add*(parent: CsElseClause; item: CsSwitchStatement) = # SS
  echo "in method add*(parent: CsElseClause; item: CsSwitchStatement)"
  parent.body.add item

method add*(parent: CsForEachStatement; item: CsSwitchStatement) = # SS
  echo "in method add*(parent: CsForEachStatement; item: CsSwitchStatement)"
  parent.body.add item

method add*(parent: CsInterface; item: CsClass) =
  echo "in method add*(parent: CsInterface; item: CsClass)"
  todoimplAdd() # TODO(add: CsInterface, CsClass)

method add*(parent: CsPointerType; item: CsGenericName) = # GN
  echo "in method add*(parent: CsPointerType; item: CsGenericName)"
  todoimplAdd() # TODO(add: CsPointerType, CsGenericName)

method add*(parent: CsRefExpression; item: CsThisExpression) = # TE
  echo "in method add*(parent: CsRefExpression; item: CsThisExpression)"
  todoimplAdd() # TODO(add: CsRefExpression, CsThisExpression)

method add*(parent: CsCastExpression; item: CsDefaultExpression) = # DE
  echo "in method add*(parent: CsCastExpression; item: CsDefaultExpression)"
  todoimplAdd() # TODO(add: CsCastExpression, CsDefaultExpression)

method add*(parent: CsSimpleBaseType; item: CsNullableType) = # NT
  echo "in method add*(parent: CsSimpleBaseType; item: CsNullableType)"
  parent.gotType = item

method add*(parent: CsSimpleBaseType; item: CsPointerType) = # PT
  echo "in method add*(parent: CsSimpleBaseType; item: CsPointerType)"
  parent.gotType = item

method add*(parent: CsInterface; item: CsConstructor) =
  echo "in method add*(parent: CsInterface; item: CsConstructor)"
  todoimplAdd() # TODO(add: CsInterface, CsConstructor)

method add*(parent: CsInterface; item: CsDelegate) =
  echo "in method add*(parent: CsInterface; item: CsDelegate)"
  todoimplAdd() # TODO(add: CsInterface, CsDelegate)

method add*(parent: CsInterface; item: CsEnum) =
  echo "in method add*(parent: CsInterface; item: CsEnum)"
  todoimplAdd() # TODO(add: CsInterface, CsEnum)

method add*(parent: CsInterface; item: CsStruct) =
  echo "in method add*(parent: CsInterface; item: CsStruct)"
  todoimplAdd() # TODO(add: CsInterface, CsStruct)

method add*(parent: CsLockStatement; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsLockStatement; item: CsInvocationExpression)"
  parent.body.add item

method add*(parent: CsCatchFilterClause; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsCatchFilterClause; item: CsInvocationExpression)"
  # if parent.hasNoPredicate:
  parent.exprThatLeadsToBoolean = item

method add*(parent: CsSwitchSection; item: CsTryStatement) = # TS
  echo "in method add*(parent: CsSwitchSection; item: CsTryStatement)"
  parent.body.add item

method add*(parent: CsStruct; item: CsClass) =
  echo "in method add*(parent: CsStruct; item: CsClass)"
  # forward to ns parent.
  forward(parent,item)
  # todoimplAdd() # TODO(add: CsStruct, CsClass)

method add*(parent: CsForEachStatement; item: CsNullableType) = # NT
  echo "in method add*(parent: CsForEachStatement; item: CsNullableType)"
  parent.gotType = item

method add*(parent: CsInterpolation; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsInterpolation; item: CsAwaitExpression)"
  todoimplAdd() # TODO(add: CsInterpolation, CsAwaitExpression)

method add*(parent: CsIsPatternExpression; item: CsRecursivePattern) = # RP
  echo "in method add*(parent: CsIsPatternExpression; item: CsRecursivePattern)"
  parent.rhs = item

method add*(parent: CsLetClause; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsLetClause; item: CsInvocationExpression)"
  parent.value = item

method add*(parent: CsEqualsValueClause; item: CsRefValueExpression) = # RVE
  echo "in method add*(parent: CsEqualsValueClause; item: CsRefValueExpression)"
  parent.rhsValue = item

method add*(parent: CsRefExpression; item: CsBinaryExpression) = # BE
  echo "in method add*(parent: CsRefExpression; item: CsBinaryExpression)"

  todoimplAdd() # TODO(add: CsRefExpression, CsBinaryExpression)

method add*(parent: CsParenthesizedLambdaExpression; item: CsDefaultExpression) = # DE
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsDefaultExpression)"
  parent.body.add item

method add*(parent: CsSwitchExpressionArm; item: CsBinaryPattern) = # BP
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsBinaryPattern)"
  todoimplAdd() # TODO(add: CsSwitchExpressionArm, CsBinaryPattern)

method add*(parent: CsTypeArgumentList; item: CsAliasQualifiedName) = # AQN
  echo "in method add*(parent: CsTypeArgumentList; item: CsAliasQualifiedName)"
  todoimplAdd() # TODO(add: CsTypeArgumentList, CsAliasQualifiedName)

method add*(parent: CsYieldStatement; item: CsConditionalExpression) = # CE
  echo "in method add*(parent: CsYieldStatement; item: CsConditionalExpression)"
  parent.expr = item

method add*(parent: CsYieldStatement; item: CsDefaultExpression) = # DE
  echo "in method add*(parent: CsYieldStatement; item: CsDefaultExpression)"
  parent.expr = item

method add*(parent: CsYieldStatement; item: CsPostfixUnaryExpression) = # PUE
  echo "in method add*(parent: CsYieldStatement; item: CsPostfixUnaryExpression)"
  parent.expr = item

method add*(parent: CsYieldStatement; item: CsTypeOfExpression) = # TOE
  echo "in method add*(parent: CsYieldStatement; item: CsTypeOfExpression)"
  parent.expr = item

method add*(parent: CsSwitchExpression; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsSwitchExpression; item: CsMemberAccessExpression)"
  todoimplAdd() # TODO(add: CsSwitchExpression, CsMemberAccessExpression)

method add*(parent: CsElementAccessExpression; item: CsArrayCreationExpression) = # ACE
  echo "in method add*(parent: CsElementAccessExpression; item: CsArrayCreationExpression)"
  todoimplAdd() # TODO(add: CsElementAccessExpression, CsArrayCreationExpression)

method add*(parent: CsDoStatement; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsDoStatement; item: CsMemberAccessExpression)"
  todoimplAdd() # TODO(add: CsDoStatement, CsMemberAccessExpression)

method add*(parent: CsAwaitExpression; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsAwaitExpression; item: CsAwaitExpression)"
  todoimplAdd() # TODO(add: CsAwaitExpression, CsAwaitExpression)

method add*(parent: CsAwaitExpression; item: CsCheckedExpression) = # CE
  echo "in method add*(parent: CsAwaitExpression; item: CsCheckedExpression)"
  todoimplAdd() # TODO(add: CsAwaitExpression, CsCheckedExpression)

method add*(parent: CsAwaitExpression; item: CsConditionalAccessExpression) = # CAE
  echo "in method add*(parent: CsAwaitExpression; item: CsConditionalAccessExpression)"
  todoimplAdd() # TODO(add: CsAwaitExpression, CsConditionalAccessExpression)

method add*(parent: CsAwaitExpression; item: CsPostfixUnaryExpression) = # PUE
  echo "in method add*(parent: CsAwaitExpression; item: CsPostfixUnaryExpression)"
  todoimplAdd() # TODO(add: CsAwaitExpression, CsPostfixUnaryExpression)

method add*(parent: CsArrowExpressionClause; item: CsCheckedExpression) = # CE
  echo "in method add*(parent: CsArrowExpressionClause; item: CsCheckedExpression)"
  parent.body.add item

method add*(parent: CsMemberAccessExpression; item: CsRefValueExpression) = # RVE
  echo "in method add*(parent: CsMemberAccessExpression; item: CsRefValueExpression)"
  todoimplAdd() # TODO(add: CsMemberAccessExpression, CsRefValueExpression)

method add*(parent: CsMemberAccessExpression; item: CsTupleExpression) = # TE
  echo "in method add*(parent: CsMemberAccessExpression; item: CsTupleExpression)"
  todoimplAdd() # TODO(add: CsMemberAccessExpression, CsTupleExpression)

method add*(parent: CsInitializerExpression; item: CsConditionalAccessExpression) = # CAE
  echo "in method add*(parent: CsInitializerExpression; item: CsConditionalAccessExpression)"
  parent.bexprs.add item

method add*(parent: CsInitializerExpression; item: CsThrowExpression) = # TE
  echo "in method add*(parent: CsInitializerExpression; item: CsThrowExpression)"
  parent.bexprs.add item

method add*(parent: CsPrefixUnaryExpression; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsPrefixUnaryExpression; item: CsAwaitExpression)"
  parent.actingOn = item

method add*(parent: CsLabeledStatement; item: CsGotoStatement) = # GS
  echo "in method add*(parent: CsLabeledStatement; item: CsGotoStatement)"
  parent.body.add item

method add*(parent: CsLockStatement; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsLockStatement; item: CsElementAccessExpression)"
  todoimplAdd() # TODO(add: CsLockStatement, CsElementAccessExpression)

method add*(parent: CsSwitchSection; item: CsForStatement) = # FS
  echo "in method add*(parent: CsSwitchSection; item: CsForStatement)"
  parent.body.add item

method add*(parent: CsSwitchSection; item: CsUsingStatement) = # US
  echo "in method add*(parent: CsSwitchSection; item: CsUsingStatement)"
  parent.body.add item

method add*(parent: CsSwitchSection; item: CsYieldStatement) = # YS
  echo "in method add*(parent: CsSwitchSection; item: CsYieldStatement)"
  parent.body.add item

method add*(parent: CsCastExpression; item: CsImplicitArrayCreationExpression) = # IACE
  echo "in method add*(parent: CsCastExpression; item: CsImplicitArrayCreationExpression)"
  parent.expr = item

method add*(parent: CsBinaryExpression; item: CsImplicitArrayCreationExpression) = # IACE
  echo "in method add*(parent: CsBinaryExpression; item: CsImplicitArrayCreationExpression)"
  todoimplAdd() # TODO(add: CsBinaryExpression, CsImplicitArrayCreationExpression)

method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsCastExpression) = # CE
  echo "in method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsCastExpression)"
  todoimplAdd() # TODO(add: CsAnonymousObjectMemberDeclarator, CsCastExpression)

method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsDefaultExpression) = # DE
  echo "in method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsDefaultExpression)"
  parent.value = item

method add*(parent: CsInterface; item: CsIncompleteMember) = # IM
  echo "in method add*(parent: CsInterface; item: CsIncompleteMember)"
  todoimplAdd() # TODO(add: CsInterface, CsIncompleteMember)

method add*(parent: CsCatchFilterClause; item: CsPrefixUnaryExpression) = # PUE
  echo "in method add*(parent: CsCatchFilterClause; item: CsPrefixUnaryExpression)"
  todoimplAdd() # TODO(add: CsCatchFilterClause, CsPrefixUnaryExpression)

method add*(parent: CsPostfixUnaryExpression; item: CsDefaultExpression) = # DE
  echo "in method add*(parent: CsPostfixUnaryExpression; item: CsDefaultExpression)"
  todoimplAdd() # TODO(add: CsPostfixUnaryExpression, CsDefaultExpression)

method add*(parent: CsParameter; item: CsAliasQualifiedName) = # AQN
  echo "in method add*(parent: CsParameter; item: CsAliasQualifiedName)"
  todoimplAdd() # TODO(add: CsParameter, CsAliasQualifiedName)

method add*(parent: CsAssignmentExpression; item: CsSwitchExpression) = # SE
  echo "in method add*(parent: CsAssignmentExpression; item: CsSwitchExpression)"
  todoimplAdd() # TODO(add: CsAssignmentExpression, CsSwitchExpression)

method add*(parent: CsUsingStatement; item: CsFixedStatement) = # FS
  echo "in method add*(parent: CsUsingStatement; item: CsFixedStatement)"
  parent.addToUsing item

method add*(parent: CsUsingStatement; item: CsTryStatement) = # TS
  echo "in method add*(parent: CsUsingStatement; item: CsTryStatement)"
  parent.body.add item

method add*(parent: CsForStatement; item: CsCheckedStatement) = # CS
  echo "in method add*(parent: CsForStatement; item: CsCheckedStatement)"
  todoimplAdd() # TODO(add: CsForStatement, CsCheckedStatement)

method add*(parent: CsForStatement; item: CsLockStatement) = # LS
  echo "in method add*(parent: CsForStatement; item: CsLockStatement)"
  parent.body.add item

method add*(parent: CsIndexer; item: CsArrayType) = # AT
  echo "in method add*(parent: CsIndexer; item: CsArrayType)"
  parent.gotType = item

method add*(parent: CsCaseSwitchLabel; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsCaseSwitchLabel; item: CsInvocationExpression)"
  parent.other = item

method add*(parent: CsCaseSwitchLabel; item: CsPrefixUnaryExpression) = # PUE
  echo "in method add*(parent: CsCaseSwitchLabel; item: CsPrefixUnaryExpression)"
  parent.other = item

method add*(parent: CsConditionalExpression; item: CsCheckedExpression) = # CE
  echo "in method add*(parent: CsConditionalExpression; item: CsCheckedExpression)"
  parent.addConditional(item)

method add*(parent: CsConditionalExpression; item: CsSimpleLambdaExpression) = # SLE
  echo "in method add*(parent: CsConditionalExpression; item: CsSimpleLambdaExpression)"
  parent.addConditional(item)

method add*(parent: CsSimpleLambdaExpression; item: CsImplicitObjectCreationExpression) = # IOCE
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsImplicitObjectCreationExpression)"
  parent.body.add item


method add*(parent: CsSimpleLambdaExpression; item: CsSwitchExpression) = # SE
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsSwitchExpression)"
  parent.body.add item

method add*(parent: CsIncompleteMember; item: CsArrayType) = # AT
  echo "in method add*(parent: CsIncompleteMember; item: CsArrayType)"
  parent.gotType = item

method add*(parent: CsIncompleteMember; item: CsPointerType) = # PT
  echo "in method add*(parent: CsIncompleteMember; item: CsPointerType)"
  parent.gotType = item

method add*(parent: CsArgument; item: CsRefValueExpression) = # RVE
  echo "in method add*(parent: CsArgument; item: CsRefValueExpression)"
  parent.mref = item

method add*(parent: CsArgument; item: CsWithExpression) = # WE
  echo "in method add*(parent: CsArgument; item: CsWithExpression)"
  todoimplAdd() # TODO(add: CsArgument, CsWithExpression)

method add*(parent: CsDelegate; item: CsNullableType) = # NT
  echo "in method add*(parent: CsDelegate; item: CsNullableType)"
  parent.gotType = item

method add*(parent: CsForEachStatement; item: CsConditionalAccessExpression) = # CAE
  echo "in method add*(parent: CsForEachStatement; item: CsConditionalAccessExpression)"
  todoimplAdd() # TODO(add: CsForEachStatement, CsConditionalAccessExpression)

method add*(parent: CsForEachStatement; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsForEachStatement; item: CsParenthesizedExpression)"
  todoimplAdd() # TODO(add: CsForEachStatement, CsParenthesizedExpression)

method add*(parent: CsForEachStatement; item: CsReturnStatement) = # RS
  echo "in method add*(parent: CsForEachStatement; item: CsReturnStatement)"
  parent.body.add item

method add*(parent: CsForEachStatement; item: CsUsingStatement) = # US
  echo "in method add*(parent: CsForEachStatement; item: CsUsingStatement)"
  parent.body.add item

method add*(parent: CsDeclarationPattern; item: CsArrayType) = # AT
  echo "in method add*(parent: CsDeclarationPattern; item: CsArrayType)"
  parent.gotType = item

method add*(parent: CsDeclarationExpression; item: CsArrayType) = # AT
  echo "in method add*(parent: CsDeclarationExpression; item: CsArrayType)"
  parent.gotType = item

method add*(parent: CsSwitchExpressionArm; item: CsDeclarationPattern) = # DP
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsDeclarationPattern)"
  parent.pat = item

method add*(parent: CsSwitchExpressionArm; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsLiteralExpression)"
  parent.body.add item

method add*(parent: CsSwitchExpressionArm; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsMemberAccessExpression)"
  parent.assignable = item

method add*(parent: CsPrefixUnaryExpression; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsPrefixUnaryExpression; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsCasePatternSwitchLabel; item: CsWhenClause) = # WC
  echo "in method add*(parent: CsCasePatternSwitchLabel; item: CsWhenClause)"
  todoimplAdd() # TODO(add: CsCasePatternSwitchLabel, CsWhenClause)

method add*(parent: CsSwitchSection; item: CsWhileStatement) = # WS
  echo "in method add*(parent: CsSwitchSection; item: CsWhileStatement)"
  parent.body.add item

method add*(parent: CsCaseSwitchLabel; item: CsBinaryExpression) = # BE
  echo "in method add*(parent: CsCaseSwitchLabel; item: CsBinaryExpression)"
  parent.other = item

method add*(parent: CsCaseSwitchLabel; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsCaseSwitchLabel; item: CsParenthesizedExpression)"
  parent.other = item

method add*(parent: CsRangeExpression; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsRangeExpression; item: CsInvocationExpression)"
  todoimplAdd() # TODO(add: CsRangeExpression, CsInvocationExpression)

method add*(parent: CsOmittedTypeArgument; item: CsGenericName) = # GN
  echo "in method add*(parent: CsOmittedTypeArgument; item: CsGenericName)"
  todoimplAdd() # TODO(add: CsOmittedTypeArgument, CsGenericName)

method add*(parent: CsGotoStatement; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsGotoStatement; item: CsMemberAccessExpression)"
  todoimplAdd() # TODO(add: CsGotoStatement, CsMemberAccessExpression)

method add*(parent: CsEqualsValueClause; item: CsGenericName) = # GN
  echo "in method add*(parent: CsEqualsValueClause; item: CsGenericName)"
  todoimplAdd()

method add*(parent: CsEqualsValueClause; item: CsRefTypeExpression) = # RTE
  echo "in method add*(parent: CsEqualsValueClause; item: CsRefTypeExpression)"
  parent.rhsValue = item

method add*(parent: CsSwitchExpressionArm; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsInvocationExpression)"
  parent.body.add item

method add*(parent: CsArrowExpressionClause; item: CsDefaultExpression) = # DE
  echo "in method add*(parent: CsArrowExpressionClause; item: CsDefaultExpression)"
  parent.body.add item

method add*(parent: CsLabeledStatement; item: CsExpressionStatement) = # ES
  echo "in method add*(parent: CsLabeledStatement; item: CsExpressionStatement)"
  parent.body.add item

method add*(parent: CsSwitchStatement; item: CsDefaultExpression) = # DE
  echo "in method add*(parent: CsSwitchStatement; item: CsDefaultExpression)"
  parent.on = item

method add*(parent: CsCastExpression; item: CsTupleExpression) = # TE
  echo "in method add*(parent: CsCastExpression; item: CsTupleExpression)"
  todoimplAdd() # TODO(add: CsCastExpression, CsTupleExpression)

method add*(parent: CsNamespace; item: CsIndexer) =
  echo "in method add*(parent: CsNamespace; item: CsIndexer)"
  todoimplAdd() # TODO(add: CsNamespace, CsIndexer)

method add*(parent: CsElseClause; item: CsGotoStatement) = # GS
  echo "in method add*(parent: CsElseClause; item: CsGotoStatement)"
  parent.body.add item

method add*(parent: CsConditionalExpression; item: CsStackAllocArrayCreationExpression) = # SAACE
  echo "in method add*(parent: CsConditionalExpression; item: CsStackAllocArrayCreationExpression)"
  parent.addConditional(item)

method add*(parent: CsIncompleteMember; item: CsRefType) = # RT
  echo "in method add*(parent: CsIncompleteMember; item: CsRefType)"
  parent.gotType = item

method add*(parent: CsRefType; item: CsPointerType) = # PT
  echo "in method add*(parent: CsRefType; item: CsPointerType)"
  parent.gotType = item

method add*(parent: CsExplicitInterfaceSpecifier; item: CsAliasQualifiedName) = # AQN
  echo "in method add*(parent: CsExplicitInterfaceSpecifier; item: CsAliasQualifiedName)"
  todoimplAdd() # TODO(add: CsExplicitInterfaceSpecifier, CsAliasQualifiedName)

method add*(parent: CsArrayRankSpecifier; item: CsCheckedExpression) = # CE
  echo "in method add*(parent: CsArrayRankSpecifier; item: CsCheckedExpression)"
  parent.theRankValue = item

method add*(parent: CsSwitchExpressionArm; item: CsDiscardPattern) = # DP
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsDiscardPattern)"
  parent.pat = item

method add*(parent: CsSwitchExpression; item: CsTupleExpression) = # TE
  echo "in method add*(parent: CsSwitchExpression; item: CsTupleExpression)"
  todoimplAdd() # TODO(add: CsSwitchExpression, CsTupleExpression)

method add*(parent: CsCastExpression; item: CsTypeOfExpression) = # TOE
  echo "in method add*(parent: CsCastExpression; item: CsTypeOfExpression)"
  parent.expr = item

method add*(parent: CsCaseSwitchLabel; item: CsCheckedExpression) = # CE
  echo "in method add*(parent: CsCaseSwitchLabel; item: CsCheckedExpression)"
  parent.other = item

method add*(parent: CsStackAllocArrayCreationExpression; item: CsInitializerExpression) = # IE
  echo "in method add*(parent: CsStackAllocArrayCreationExpression; item: CsInitializerExpression)"
  todoimplAdd() # TODO(add: CsStackAllocArrayCreationExpression, CsInitializerExpression)

method add*(parent: CsCheckedExpression; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsCheckedExpression; item: CsInvocationExpression)"
  todoimplAdd() # TODO(add: CsCheckedExpression, CsInvocationExpression)

method add*(parent: CsInterpolation; item: CsInterpolatedStringExpression) = # ISE
  echo "in method add*(parent: CsInterpolation; item: CsInterpolatedStringExpression)"
  parent.expr = item

method add*(parent: CsLetClause; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsLetClause; item: CsMemberAccessExpression)"
  parent.value = item

method add*(parent: CsSwitchExpressionArm; item: CsCastExpression) = # CE
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsCastExpression)"
  parent.body.add item

method add*(parent: CsSwitchExpressionArm; item: CsInterpolatedStringExpression) = # ISE
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsInterpolatedStringExpression)"
  todoimplAdd() # TODO(add: CsSwitchExpressionArm, CsInterpolatedStringExpression)

method add*(parent: CsSwitchExpressionArm; item: CsThrowExpression) = # TE
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsThrowExpression)"
  parent.body.add item

method add*(parent: CsRefValueExpression; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsRefValueExpression; item: CsInvocationExpression)"
  parent.invokeExpr = item

method add*(parent: CsRefValueExpression; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsRefValueExpression; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsLockStatement; item: CsIfStatement) = # IS
  echo "in method add*(parent: CsLockStatement; item: CsIfStatement)"
  parent.body.add item

method add*(parent: CsRecursivePattern; item: CsPositionalPatternClause) = # PPC
  echo "in method add*(parent: CsRecursivePattern; item: CsPositionalPatternClause)"
  parent.pat = item

method add*(parent: CsRecursivePattern; item: CsPropertyPatternClause) = # PPC
  echo "in method add*(parent: CsRecursivePattern; item: CsPropertyPatternClause)"
  parent.pat = item

method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsArrayCreationExpression) = # ACE
  echo "in method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsArrayCreationExpression)"
  todoimplAdd() # TODO(add: CsAnonymousObjectMemberDeclarator, CsArrayCreationExpression)

method add*(parent: CsPostfixUnaryExpression; item: CsConditionalAccessExpression) = # CAE
  echo "in method add*(parent: CsPostfixUnaryExpression; item: CsConditionalAccessExpression)"
  todoimplAdd() # TODO(add: CsPostfixUnaryExpression, CsConditionalAccessExpression)

method add*(parent: CsDefaultExpression; item: CsArrayType) = # AT
  echo "in method add*(parent: CsDefaultExpression; item: CsArrayType)"
  parent.gotType = item

method add*(parent: CsCheckedExpression; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsCheckedExpression; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsCheckedExpression, CsLiteralExpression)

method add*(parent: CsForEachStatement; item: CsTupleType) = # TT
  echo "in method add*(parent: CsForEachStatement; item: CsTupleType)"
  parent.gotType = item

method add*(parent: CsRangeExpression; item: CsCastExpression) = # CE
  echo "in method add*(parent: CsRangeExpression; item: CsCastExpression)"
  todoimplAdd() # TODO(add: CsRangeExpression, CsCastExpression)

method add*(parent: CsFixedStatement; item: CsVariable) =
  echo "in method add*(parent: CsFixedStatement; item: CsVariable)"
  if parent.expr.isNil:
    parent.expr = item
  else:
    parent.body.add item

method add*(parent: CsRefExpression; item: CsPrefixUnaryExpression) = # PUE
  echo "in method add*(parent: CsRefExpression; item: CsPrefixUnaryExpression)"
  todoimplAdd() # TODO(add: CsRefExpression, CsPrefixUnaryExpression)

method add*(parent: CsSwitchExpressionArm; item: CsRecursivePattern) = # RP
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsRecursivePattern)"
  todoimplAdd() # TODO(add: CsSwitchExpressionArm, CsRecursivePattern)

method add*(parent: CsConstantPattern; item: CsDefaultExpression) = # DE
  echo "in method add*(parent: CsConstantPattern; item: CsDefaultExpression)"
  parent.valExpr = item

method add*(parent: CsTypeOfExpression; item: CsAliasQualifiedName) = # AQN
  echo "in method add*(parent: CsTypeOfExpression; item: CsAliasQualifiedName)"
  todoimplAdd() # TODO(add: CsTypeOfExpression, CsAliasQualifiedName)

method add*(parent: CsIfStatement; item: CsCheckedExpression) = # CE
  echo "in method add*(parent: CsIfStatement; item: CsCheckedExpression)"
  todoimplAdd() # TODO(add: CsIfStatement, CsCheckedExpression)

method add*(parent: CsElseClause; item: CsLocalDeclarationStatement) = # LDS
  echo "in method add*(parent: CsElseClause; item: CsLocalDeclarationStatement)"
  parent.body.add item

method add*(parent: CsThrowStatement; item: CsConditionalExpression) = # CE
  echo "in method add*(parent: CsThrowStatement; item: CsConditionalExpression)"
  parent.body.add item

method add*(parent: CsWithExpression; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsWithExpression; item: CsMemberAccessExpression)"
  todoimplAdd() # TODO(add: CsWithExpression, CsMemberAccessExpression)

method add*(parent: CsCheckedExpression; item: CsConditionalExpression) = # CE
  echo "in method add*(parent: CsCheckedExpression; item: CsConditionalExpression)"
  todoimplAdd() # TODO(add: CsCheckedExpression, CsConditionalExpression)

method add*(parent: CsWhenClause; item: CsBinaryExpression) = # BE
  echo "in method add*(parent: CsWhenClause; item: CsBinaryExpression)"
  todoimplAdd() # TODO(add: CsWhenClause, CsBinaryExpression)

method add*(parent: CsSwitchExpressionArm; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsParenthesizedExpression)"
  todoimplAdd() # TODO(add: CsSwitchExpressionArm, CsParenthesizedExpression)

method add*(parent: CsYieldStatement; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsYieldStatement; item: CsParenthesizedExpression)"
  parent.expr = item

method add*(parent: CsWhileStatement; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsWhileStatement; item: CsParenthesizedExpression)"
  todoimplAdd() # TODO(add: CsWhileStatement, CsParenthesizedExpression)

method add*(parent: CsPositionalPatternClause; item: CsSubpattern) =
  echo "in method add*(parent: CsPositionalPatternClause; item: CsSubpattern)"
  parent.subs.add item

method add*(parent: CsSwitchExpressionArm; item: CsConditionalExpression) = # CE
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsConditionalExpression)"
  todoimplAdd() # TODO(add: CsSwitchExpressionArm, CsConditionalExpression)

method add*(parent: CsSwitchExpressionArm; item: CsObjectCreationExpression) = # OCE
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsObjectCreationExpression)"
  parent.body.add item

method add*(parent: CsSwitchExpression; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsSwitchExpression; item: CsElementAccessExpression)"
  todoimplAdd() # TODO(add: CsSwitchExpression, CsElementAccessExpression)

method add*(parent: CsElementAccessExpression; item: CsMemberBindingExpression) = # MBE
  echo "in method add*(parent: CsElementAccessExpression; item: CsMemberBindingExpression)"
  todoimplAdd() # TODO(add: CsElementAccessExpression, CsMemberBindingExpression)

method add*(parent: CsMemberAccessExpression; item: CsRefTypeExpression) = # RTE
  echo "in method add*(parent: CsMemberAccessExpression; item: CsRefTypeExpression)"
  todoimplAdd() # TODO(add: CsMemberAccessExpression, CsRefTypeExpression)

method add*(parent: CsPrefixUnaryExpression; item: CsPostfixUnaryExpression) = # PUE
  echo "in method add*(parent: CsPrefixUnaryExpression; item: CsPostfixUnaryExpression)"
  parent.actingOn = item

method add*(parent: CsParenthesizedExpression; item: CsThisExpression) = # TE
  echo "in method add*(parent: CsParenthesizedExpression; item: CsThisExpression)"
  parent.body.add item

method add*(parent: CsSwitchSection; item: CsEmptyStatement) = # ES
  echo "in method add*(parent: CsSwitchSection; item: CsEmptyStatement)"
  parent.body.add item

method add*(parent: CsAssignmentExpression; item: CsRefValueExpression) = # RVE
  echo "in method add*(parent: CsAssignmentExpression; item: CsRefValueExpression)"
  parent.right = item

method add*(parent: CsBinaryPattern; item: CsBinaryPattern) = # BP
  echo "in method add*(parent: CsBinaryPattern; item: CsBinaryPattern)"
  todoimplAdd() # TODO(add: CsBinaryPattern, CsBinaryPattern)

method add*(parent: CsPropertyPatternClause; item: CsSubpattern) =
  echo "in method add*(parent: CsPropertyPatternClause; item: CsSubpattern)"
  parent.subs.add item

method add*(parent: CsWithExpression; item: CsInitializerExpression) = # IE
  echo "in method add*(parent: CsWithExpression; item: CsInitializerExpression)"
  todoimplAdd() # TODO(add: CsWithExpression, CsInitializerExpression)

method add*(parent: CsWhenClause; item: CsIsPatternExpression) = # IPE
  echo "in method add*(parent: CsWhenClause; item: CsIsPatternExpression)"
  todoimplAdd() # TODO(add: CsWhenClause, CsIsPatternExpression)

method add*(parent: CsElementAccessExpression; item: CsPostfixUnaryExpression) = # PUE
  echo "in method add*(parent: CsElementAccessExpression; item: CsPostfixUnaryExpression)"
  todoimplAdd() # TODO(add: CsElementAccessExpression, CsPostfixUnaryExpression)

method add*(parent: CsSubpattern; item: CsConstantPattern) = # CP
  echo "in method add*(parent: CsSubpattern; item: CsConstantPattern)"
  parent.pat = item

method add*(parent: CsNameEquals; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsNameEquals; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsNameEquals, CsLiteralExpression)

method add*(parent: CsExpressionStatement; item: CsExpressionStatement) = # ES
  echo "in method add*(parent: CsExpressionStatement; item: CsExpressionStatement)"
  todoimplAdd() # TODO(add: CsExpressionStatement, CsExpressionStatement)

method add*(parent: CsClass; item: CsEvent) =
  echo "in method add*(parent: CsClass; item: CsEvent)"
  parent.events.add item

method add*(parent: CsClass; item: CsEventField) = # EF
  echo "in method add*(parent: CsClass; item: CsEventField)"
  parent.eventFields.add item

method add*(parent: CsClass; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsClass; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsClass, CsLiteralExpression)

method add*(parent: CsInterface; item: CsEventField) = # EF
  echo "in method add*(parent: CsInterface; item: CsEventField)"
  parent.events.add item

method add*(parent: CsInterface; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsInterface; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsInterface, CsLiteralExpression)

method add*(parent: CsAccessor; item: CsIfStatement) = # IS
  echo "in method add*(parent: CsAccessor; item: CsIfStatement)"
  parent.body.add item

method add*(parent: CsAccessor; item: CsLockStatement) = # LS
  echo "in method add*(parent: CsAccessor; item: CsLockStatement)"
  parent.body.add item

method add*(parent: CsAccessor; item: CsThrowStatement) = # TS
  echo "in method add*(parent: CsAccessor; item: CsThrowStatement)"
  parent.body.add item

method add*(parent: CsAccessor; item: CsYieldStatement) = # YS
  echo "in method add*(parent: CsAccessor; item: CsYieldStatement)"
  parent.body.add item

method add*(parent: CsParameter; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsParameter; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsParameter, CsLiteralExpression)

method add*(parent: CsMethod; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsMethod; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsMethod, CsLiteralExpression)

method add*(parent: CsUsingDirective; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsUsingDirective; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsUsingDirective, CsLiteralExpression)

method add*(parent: CsConstructor; item: CsForEachStatement) = # FES
  echo "in method add*(parent: CsConstructor; item: CsForEachStatement)"
  parent.body.add item

method add*(parent: CsConstructor; item: CsIfStatement) = # IS
  echo "in method add*(parent: CsConstructor; item: CsIfStatement)"
  parent.body.add item

method add*(parent: CsConstructor; item: CsThrowStatement) = # TS
  echo "in method add*(parent: CsConstructor; item: CsThrowStatement)"
  parent.body.add item

method add*(parent: CsConstructor; item: CsTryStatement) = # TS
  echo "in method add*(parent: CsConstructor; item: CsTryStatement)"
  parent.body.add item

method add*(parent: CsConstructor; item: CsUsingStatement) = # US
  echo "in method add*(parent: CsConstructor; item: CsUsingStatement)"
  parent.body.add item

method add*(parent: CsPostfixUnaryExpression; item: CsTupleExpression) = # TE
  echo "in method add*(parent: CsPostfixUnaryExpression; item: CsTupleExpression)"
  todoimplAdd() # TODO(add: CsPostfixUnaryExpression, CsTupleExpression)

method add*(parent: CsProperty; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsProperty; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsProperty, CsLiteralExpression)

method add*(parent: CsAccessor; item: CsWhileStatement) = # WS
  echo "in method add*(parent: CsAccessor; item: CsWhileStatement)"
  parent.body.add item

method add*(parent: CsEvent; item: CsAccessorList) = # AL
  echo "in method add*(parent: CsEvent; item: CsAccessorList)"
  parent.accList = item

method add*(parent: CsEventField; item: CsVariable) =
  echo "in method add*(parent: CsEventField; item: CsVariable)"
  parent.thevar = item

method add*(parent: CsPredefinedType; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsPredefinedType; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsPredefinedType, CsLiteralExpression)

method add*(parent: CsSubpattern; item: CsDiscardPattern) = # DP
  echo "in method add*(parent: CsSubpattern; item: CsDiscardPattern)"
  todoimplAdd() # TODO(add: CsSubpattern, CsDiscardPattern)

method add*(parent: CsConstructor; item: CsForStatement) = # FS
  echo "in method add*(parent: CsConstructor; item: CsForStatement)"
  parent.body.add item

method add*(parent: CsConstructor; item: CsWhileStatement) = # WS
  echo "in method add*(parent: CsConstructor; item: CsWhileStatement)"
  parent.body.add item

method add*(parent: CsInterpolation; item: CsThisExpression) = # TE
  echo "in method add*(parent: CsInterpolation; item: CsThisExpression)"
  parent.expr = item

method add*(parent: CsIsPatternExpression; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsIsPatternExpression; item: CsParenthesizedExpression)"
  todoimplAdd() # TODO(add: CsIsPatternExpression, CsParenthesizedExpression)

method add*(parent: CsDoStatement; item: CsIsPatternExpression) = # IPE
  echo "in method add*(parent: CsDoStatement; item: CsIsPatternExpression)"
  todoimplAdd() # TODO(add: CsDoStatement, CsIsPatternExpression)

method add*(parent: CsField; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsField; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsField, CsLiteralExpression)

method add*(parent: CsSwitchExpressionArm; item: CsBinaryExpression) = # BE
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsBinaryExpression)"
  todoimplAdd() # TODO(add: CsSwitchExpressionArm, CsBinaryExpression)

method add*(parent: CsAccessor; item: CsForEachStatement) = # FES
  echo "in method add*(parent: CsAccessor; item: CsForEachStatement)"
  parent.body.add item

method add*(parent: CsEvent; item: CsGenericName) = # GN
  echo "in method add*(parent: CsEvent; item: CsGenericName)"
  parent.gotType = item

method add*(parent: CsEvent; item: CsNullableType) = # NT
  echo "in method add*(parent: CsEvent; item: CsNullableType)"
  parent.gotType = item

method add*(parent: CsCheckedExpression; item: CsArrayCreationExpression) = # ACE
  echo "in method add*(parent: CsCheckedExpression; item: CsArrayCreationExpression)"
  todoimplAdd() # TODO(add: CsCheckedExpression, CsArrayCreationExpression)

method add*(parent: CsAccessor; item: CsTryStatement) = # TS
  echo "in method add*(parent: CsAccessor; item: CsTryStatement)"
  parent.body.add item

method add*(parent: CsConstructor; item: CsContinueStatement) = # CS
  echo "in method add*(parent: CsConstructor; item: CsContinueStatement)"
  parent.body.add item

method add*(parent: CsEvent; item: CsExplicitInterfaceSpecifier) = # EIS
  echo "in method add*(parent: CsEvent; item: CsExplicitInterfaceSpecifier)"
  parent.explInterface = item

method add*(parent: CsClass; item: CsConversionOperator) = # CO
  echo "in method add*(parent: CsClass; item: CsConversionOperator)"
  parent.convOps.add item

method add*(parent: CsClass; item: CsDestructor) =
  echo "in method add*(parent: CsClass; item: CsDestructor)"
  parent.dtors.add item

method add*(parent: CsClass; item: CsOperator) =
  echo "in method add*(parent: CsClass; item: CsOperator)"
  parent.operators.add item

method add*(parent: CsStruct; item: CsOperator) =
  echo "in method add*(parent: CsStruct; item: CsOperator)"
  parent.operators.add item

method add*(parent: CsSwitchExpression; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsSwitchExpression; item: CsParenthesizedExpression)"
  todoimplAdd() # TODO(add: CsSwitchExpression, CsParenthesizedExpression)

method add*(parent: CsDoStatement; item: CsExpressionStatement) = # ES
  echo "in method add*(parent: CsDoStatement; item: CsExpressionStatement)"
  todoimplAdd() # TODO(add: CsDoStatement, CsExpressionStatement)

method add*(parent: CsAwaitExpression; item: CsDefaultExpression) = # DE
  echo "in method add*(parent: CsAwaitExpression; item: CsDefaultExpression)"
  todoimplAdd() # TODO(add: CsAwaitExpression, CsDefaultExpression)

method add*(parent: CsArrowExpressionClause; item: CsWithExpression) = # WE
  echo "in method add*(parent: CsArrowExpressionClause; item: CsWithExpression)"
  parent.body.add item

method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsConditionalExpression) = # CE
  echo "in method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsConditionalExpression)"
  parent.value = item

method add*(parent: CsAccessor; item: CsForStatement) = # FS
  echo "in method add*(parent: CsAccessor; item: CsForStatement)"
  parent.body.add item

method add*(parent: CsAccessor; item: CsUsingStatement) = # US
  echo "in method add*(parent: CsAccessor; item: CsUsingStatement)"
  parent.body.add item

method add*(parent: CsAssignmentExpression; item: CsIsPatternExpression) = # IPE
  echo "in method add*(parent: CsAssignmentExpression; item: CsIsPatternExpression)"
  parent.right = item

method add*(parent: CsStruct; item: CsEventField) = # EF
  echo "in method add*(parent: CsStruct; item: CsEventField)"
  parent.eventFields.add item

method add*(parent: CsConstructor; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsConstructor; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsConstructor, CsLiteralExpression)

method add*(parent: CsConstructor; item: CsLockStatement) = # LS
  echo "in method add*(parent: CsConstructor; item: CsLockStatement)"
  parent.body.add item

method add*(parent: CsArgument; item: CsMakeRefExpression) = # MRE
  echo "in method add*(parent: CsArgument; item: CsMakeRefExpression)"
  todoimplAdd() # TODO(add: CsArgument, CsMakeRefExpression)

method add*(parent: CsThrowExpression; item: CsBinaryExpression) = # BE
  echo "in method add*(parent: CsThrowExpression; item: CsBinaryExpression)"
  todoimplAdd() # TODO(add: CsThrowExpression, CsBinaryExpression)

method add*(parent: CsRangeExpression; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsRangeExpression; item: CsMemberAccessExpression)"
  todoimplAdd() # TODO(add: CsRangeExpression, CsMemberAccessExpression)

method add*(parent: CsDestructor; item: CsParameterList) = # PL
  echo "in method add*(parent: CsDestructor; item: CsParameterList)"
  parent.paramList = item

method add*(parent: CsConversionOperator; item: CsParameterList) = # PL
  echo "in method add*(parent: CsConversionOperator; item: CsParameterList)"
  parent.paramList = item

method add*(parent: CsOperator; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsOperator; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsConstructor; item: CsDoStatement) = # DS
  echo "in method add*(parent: CsConstructor; item: CsDoStatement)"
  parent.body.add item

method add*(parent: CsDelegate; item: CsTupleType) = # TT
  echo "in method add*(parent: CsDelegate; item: CsTupleType)"
  parent.gotType = item

method add*(parent: CsOperator; item: CsParameterList) = # PL
  echo "in method add*(parent: CsOperator; item: CsParameterList)"
  parent.paramList = item

method add*(parent: CsStruct; item: CsConversionOperator) = # CO
  echo "in method add*(parent: CsStruct; item: CsConversionOperator)"
  parent.convOps.add item

method add*(parent: CsInvocationExpression; item: CsPostfixUnaryExpression) = # PUE
  echo "in method add*(parent: CsInvocationExpression; item: CsPostfixUnaryExpression)"
  todoimplAdd() # TODO(add: CsInvocationExpression, CsPostfixUnaryExpression)

method add*(parent: CsOperator; item: CsArrowExpressionClause) = # AEC
  echo "in method add*(parent: CsOperator; item: CsArrowExpressionClause)"
  parent.body.add item

method add*(parent: CsConversionOperator; item: CsArrowExpressionClause) = # AEC
  echo "in method add*(parent: CsConversionOperator; item: CsArrowExpressionClause)"
  parent.body.add item

method add*(parent: CsBinaryExpression; item: CsSizeOfExpression) = # SOE
  echo "in method add*(parent: CsBinaryExpression; item: CsSizeOfExpression)"
  parent.addBinExp(item)

method add*(parent: CsWhenClause; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsWhenClause; item: CsInvocationExpression)"
  todoimplAdd() # TODO(add: CsWhenClause, CsInvocationExpression)

method add*(parent: CsSizeOfExpression; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsSizeOfExpression; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsConversionOperator; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsConversionOperator; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsConversionOperator; item: CsArrayType) = # AT
  echo "in method add*(parent: CsConversionOperator; item: CsArrayType)"
  parent.gotType = item

method add*(parent: CsEnum; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsEnum; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsEnum, CsLiteralExpression)

method add*(parent: CsAssignmentExpression; item: CsSizeOfExpression) = # SOE
  echo "in method add*(parent: CsAssignmentExpression; item: CsSizeOfExpression)"
  parent.right = item

method add*(parent: CsConversionOperator; item: CsGenericName) = # GN
  echo "in method add*(parent: CsConversionOperator; item: CsGenericName)"
  parent.gotType = item

method add*(parent: CsOperator; item: CsReturnStatement) = # RS
  echo "in method add*(parent: CsOperator; item: CsReturnStatement)"
  parent.body.add item

method add*(parent: CsEqualsValueClause; item: CsSizeOfExpression) = # SOE
  echo "in method add*(parent: CsEqualsValueClause; item: CsSizeOfExpression)"
  parent.rhsValue = item

method add*(parent: CsDestructor; item: CsArrowExpressionClause) = # AEC
  echo "in method add*(parent: CsDestructor; item: CsArrowExpressionClause)"
  parent.body.add item

method add*(parent: CsConversionOperator; item: CsReturnStatement) = # RS
  echo "in method add*(parent: CsConversionOperator; item: CsReturnStatement)"
  parent.body.add item

method add*(parent: CsTypeParameter; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsTypeParameter; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsTypeParameter, CsLiteralExpression)

method add*(parent: CsConversionOperator; item: CsNullableType) = # NT
  echo "in method add*(parent: CsConversionOperator; item: CsNullableType)"
  parent.gotType = item

method add*(parent: CsIfStatement; item: CsObjectCreationExpression) = # OCE
  echo "in method add*(parent: CsIfStatement; item: CsObjectCreationExpression)"
  # ambiguous. can be in body or can sometimes if has a conversion operator, serve as the predicate.
  if parent.predicate.isNil or parent.predicatePartLit.isNil:
    parent.exprThatLeadsToBoolean = item
  else:
    parent.body.add item

method add*(parent: CsArgument; item: CsSizeOfExpression) = # SOE
  echo "in method add*(parent: CsArgument; item: CsSizeOfExpression)"
  parent.expr = item

method add*(parent: CsSwitchExpressionArm; item: CsImplicitArrayCreationExpression) = # IACE
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsImplicitArrayCreationExpression)"
  todoimplAdd() # TODO(add: CsSwitchExpressionArm, CsImplicitArrayCreationExpression)

method add*(parent: CsSwitchStatement; item: CsObjectCreationExpression) = # OCE
  echo "in method add*(parent: CsSwitchStatement; item: CsObjectCreationExpression)"
  parent.on = item

method add*(parent: CsCastExpression; item: CsSizeOfExpression) = # SOE
  echo "in method add*(parent: CsCastExpression; item: CsSizeOfExpression)"
  parent.expr = item

method add*(parent: CsStruct; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsStruct; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsStruct, CsLiteralExpression)

method add*(parent: CsPostfixUnaryExpression; item: CsThisExpression) = # TE
  echo "in method add*(parent: CsPostfixUnaryExpression; item: CsThisExpression)"
  todoimplAdd() # TODO(add: CsPostfixUnaryExpression, CsThisExpression)

method add*(parent: CsAssignmentExpression; item: CsRefExpression) = # RE
  echo "in method add*(parent: CsAssignmentExpression; item: CsRefExpression)"
  todoimplAdd() # TODO(add: CsAssignmentExpression, CsRefExpression)

method add*(parent: CsSwitchExpressionArm; item: CsArrayCreationExpression) = # ACE
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsArrayCreationExpression)"
  todoimplAdd() # TODO(add: CsSwitchExpressionArm, CsArrayCreationExpression)

method add*(parent: CsPrefixUnaryExpression; item: CsCheckedExpression) = # CE
  echo "in method add*(parent: CsPrefixUnaryExpression; item: CsCheckedExpression)"
  todoimplAdd() # TODO(add: CsPrefixUnaryExpression, CsCheckedExpression)

method add*(parent: CsOperator; item: CsGenericName) = # GN
  echo "in method add*(parent: CsOperator; item: CsGenericName)"
  todoimplAdd() # TODO(add: CsOperator, CsGenericName)

method add*(parent: CsOperator; item: CsNullableType) = # NT
  echo "in method add*(parent: CsOperator; item: CsNullableType)"
  parent.gotType = item

method add*(parent: CsReturnStatement; item: CsSizeOfExpression) = # SOE
  echo "in method add*(parent: CsReturnStatement; item: CsSizeOfExpression)"
  parent.expr = item

method add*(parent: CsSwitchExpressionArm; item: CsPrefixUnaryExpression) = # PUE
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsPrefixUnaryExpression)"
  todoimplAdd() # TODO(add: CsSwitchExpressionArm, CsPrefixUnaryExpression)

method add*(parent: CsSwitchExpression; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsSwitchExpression; item: CsInvocationExpression)"
  todoimplAdd() # TODO(add: CsSwitchExpression, CsInvocationExpression)

method add*(parent: CsTypeOfExpression; item: CsTupleType) = # TT
  echo "in method add*(parent: CsTypeOfExpression; item: CsTupleType)"
  parent.gotType = item

method add*(parent: CsSizeOfExpression; item: CsPointerType) = # PT
  echo "in method add*(parent: CsSizeOfExpression; item: CsPointerType)"
  parent.gotType = item

method add*(parent: CsSubpattern; item: CsNameColon) = # NC
  echo "in method add*(parent: CsSubpattern; item: CsNameColon)"
  parent.namecolon = item

method add*(parent: CsArrayRankSpecifier; item: CsSizeOfExpression) = # SOE
  echo "in method add*(parent: CsArrayRankSpecifier; item: CsSizeOfExpression)"
  todoimplAdd() # TODO(add: CsArrayRankSpecifier, CsSizeOfExpression)

method add*(parent: CsArrowExpressionClause; item: CsSizeOfExpression) = # SOE
  echo "in method add*(parent: CsArrowExpressionClause; item: CsSizeOfExpression)"
  parent.body.add item

method add*(parent: CsConditionalAccessExpression; item: CsTypeOfExpression) = # TOE
  echo "in method add*(parent: CsConditionalAccessExpression; item: CsTypeOfExpression)"
  todoimplAdd() # TODO(add: CsConditionalAccessExpression, CsTypeOfExpression)

method add*(parent: CsEventField; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsEventField; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsEventField, CsLiteralExpression)

method add*(parent: CsForStatement; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsForStatement; item: CsAwaitExpression)"
  todoimplAdd() # TODO(add: CsForStatement, CsAwaitExpression)

method add*(parent: CsIncompleteMember; item: CsNullableType) = # NT
  echo "in method add*(parent: CsIncompleteMember; item: CsNullableType)"
  parent.gotType = item

method add*(parent: CsSubpattern; item: CsDeclarationPattern) = # DP
  echo "in method add*(parent: CsSubpattern; item: CsDeclarationPattern)"
  todoimplAdd() # TODO(add: CsSubpattern, CsDeclarationPattern)

method add*(parent: CsConditionalExpression; item: CsTupleExpression) = # TE
  echo "in method add*(parent: CsConditionalExpression; item: CsTupleExpression)"
  parent.addConditional(item)

method add*(parent: CsBinaryExpression; item: CsSwitchExpression) = # SE
  echo "in method add*(parent: CsBinaryExpression; item: CsSwitchExpression)"
  todoimplAdd() # TODO(add: CsBinaryExpression, CsSwitchExpression)

method add*(parent: CsInterpolation; item: CsSizeOfExpression) = # SOE
  echo "in method add*(parent: CsInterpolation; item: CsSizeOfExpression)"
  todoimplAdd() # TODO(add: CsInterpolation, CsSizeOfExpression)

method add*(parent: CsDeclarationExpression; item: CsPointerType) = # PT
  echo "in method add*(parent: CsDeclarationExpression; item: CsPointerType)"
  parent.gotType = item

method add*(parent: CsIsPatternExpression; item: CsBinaryExpression) = # BE
  echo "in method add*(parent: CsIsPatternExpression; item: CsBinaryExpression)"
  todoimplAdd() # TODO(add: CsIsPatternExpression, CsBinaryExpression)

method add*(parent: CsIsPatternExpression; item: CsCastExpression) = # CE
  echo "in method add*(parent: CsIsPatternExpression; item: CsCastExpression)"
  todoimplAdd() # TODO(add: CsIsPatternExpression, CsCastExpression)

method add*(parent: CsIsPatternExpression; item: CsThisExpression) = # TE
  echo "in method add*(parent: CsIsPatternExpression; item: CsThisExpression)"
  todoimplAdd() # TODO(add: CsIsPatternExpression, CsThisExpression)

method add*(parent: CsLetClause; item: CsConditionalExpression) = # CE
  echo "in method add*(parent: CsLetClause; item: CsConditionalExpression)"
  todoimplAdd() # TODO(add: CsLetClause, CsConditionalExpression)

method add*(parent: CsParenthesizedLambdaExpression; item: CsImplicitArrayCreationExpression) = # IACE
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsImplicitArrayCreationExpression)"
  parent.body.add item

method add*(parent: CsYieldStatement; item: CsParenthesizedLambdaExpression) = # PLE
  echo "in method add*(parent: CsYieldStatement; item: CsParenthesizedLambdaExpression)"
  parent.expr = item

method add*(parent: CsAwaitExpression; item: CsCastExpression) = # CE
  echo "in method add*(parent: CsAwaitExpression; item: CsCastExpression)"
  todoimplAdd() # TODO(add: CsAwaitExpression, CsCastExpression)

method add*(parent: CsArrowExpressionClause; item: CsImplicitObjectCreationExpression) = # IOCE
  echo "in method add*(parent: CsArrowExpressionClause; item: CsImplicitObjectCreationExpression)"
  parent.body.add item

method add*(parent: CsInitializerExpression; item: CsImplicitObjectCreationExpression) = # IOCE
  echo "in method add*(parent: CsInitializerExpression; item: CsImplicitObjectCreationExpression)"
  parent.bexprs.add item

method add*(parent: CsConstantPattern; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsConstantPattern; item: CsInvocationExpression)"
  todoimplAdd() # TODO(add: CsConstantPattern, CsInvocationExpression)

method add*(parent: CsConversionOperator; item: CsPointerType) = # PT
  echo "in method add*(parent: CsConversionOperator; item: CsPointerType)"
  parent.gotType = item

method add*(parent: CsCasePatternSwitchLabel; item: CsVarPattern) = # VP
  echo "in method add*(parent: CsCasePatternSwitchLabel; item: CsVarPattern)"
  todoimplAdd() # TODO(add: CsCasePatternSwitchLabel, CsVarPattern)

method add*(parent: CsSwitchSection; item: CsDoStatement) = # DS
  echo "in method add*(parent: CsSwitchSection; item: CsDoStatement)"
  parent.body.add item

method add*(parent: CsSwitchSection; item: CsForEachVariableStatement) = # FEVS
  echo "in method add*(parent: CsSwitchSection; item: CsForEachVariableStatement)"
  parent.body.add item

method add*(parent: CsSwitchSection; item: CsLockStatement) = # LS
  echo "in method add*(parent: CsSwitchSection; item: CsLockStatement)"
  parent.body.add item

method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsElementAccessExpression)"
  parent.value = item

method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsInterpolatedStringExpression) = # ISE
  echo "in method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsInterpolatedStringExpression)"
  todoimplAdd() # TODO(add: CsAnonymousObjectMemberDeclarator, CsInterpolatedStringExpression)

method add*(parent: CsAccessor; item: CsCastExpression) = # CE
  echo "in method add*(parent: CsAccessor; item: CsCastExpression)"
  parent.body.add item

method add*(parent: CsAccessor; item: CsContinueStatement) = # CS
  echo "in method add*(parent: CsAccessor; item: CsContinueStatement)"
  parent.body.add item

method add*(parent: CsAccessor; item: CsDoStatement) = # DS
  echo "in method add*(parent: CsAccessor; item: CsDoStatement)"
  parent.body.add item

method add*(parent: CsPostfixUnaryExpression; item: CsPostfixUnaryExpression) = # PUE
  echo "in method add*(parent: CsPostfixUnaryExpression; item: CsPostfixUnaryExpression)"
  todoimplAdd() # TODO(add: CsPostfixUnaryExpression, CsPostfixUnaryExpression)

method add*(parent: CsUnaryPattern; item: CsDeclarationPattern) = # DP
  echo "in method add*(parent: CsUnaryPattern; item: CsDeclarationPattern)"
  todoimplAdd() # TODO(add: CsUnaryPattern, CsDeclarationPattern)

method add*(parent: CsEvent; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsEvent; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsEvent, CsLiteralExpression)

method add*(parent: CsUsingStatement; item: CsForStatement) = # FS
  echo "in method add*(parent: CsUsingStatement; item: CsForStatement)"
  parent.body.add item

method add*(parent: CsInterpolationAlignmentClause; item: CsPrefixUnaryExpression) = # PUE
  echo "in method add*(parent: CsInterpolationAlignmentClause; item: CsPrefixUnaryExpression)"
  todoimplAdd() # TODO(add: CsInterpolationAlignmentClause, CsPrefixUnaryExpression)

method add*(parent: CsIfStatement; item: CsWhileStatement) = # WS
  echo "in method add*(parent: CsIfStatement; item: CsWhileStatement)"
  parent.body.add item

method add*(parent: CsForStatement; item: CsContinueStatement) = # CS
  echo "in method add*(parent: CsForStatement; item: CsContinueStatement)"
  parent.body.add item

method add*(parent: CsForStatement; item: CsForEachStatement) = # FES
  echo "in method add*(parent: CsForStatement; item: CsForEachStatement)"
  parent.body.add item

method add*(parent: CsForStatement; item: CsThrowStatement) = # TS
  echo "in method add*(parent: CsForStatement; item: CsThrowStatement)"
  parent.body.add item

method add*(parent: CsForStatement; item: CsUsingStatement) = # US
  echo "in method add*(parent: CsForStatement; item: CsUsingStatement)"
  todoimplAdd() # TODO(add: CsForStatement, CsUsingStatement)

method add*(parent: CsElseClause; item: CsForStatement) = # FS
  echo "in method add*(parent: CsElseClause; item: CsForStatement)"
  parent.body.add item

method add*(parent: CsElseClause; item: CsWhileStatement) = # WS
  echo "in method add*(parent: CsElseClause; item: CsWhileStatement)"
  parent.body.add item

method add*(parent: CsInvocationExpression; item: CsObjectCreationExpression) = # OCE
  echo "in method add*(parent: CsInvocationExpression; item: CsObjectCreationExpression)"
  todoimplAdd() # TODO(add: CsInvocationExpression, CsObjectCreationExpression)

method add*(parent: CsWhileStatement; item: CsAssignmentExpression) = # AE
  echo "in method add*(parent: CsWhileStatement; item: CsAssignmentExpression)"
  todoimplAdd() # TODO(add: CsWhileStatement, CsAssignmentExpression)

method add*(parent: CsThrowStatement; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsThrowStatement; item: CsElementAccessExpression)"
  parent.body.add item

method add*(parent: CsThrowStatement; item: CsThisExpression) = # TE
  echo "in method add*(parent: CsThrowStatement; item: CsThisExpression)"
  parent.body.add item

method add*(parent: CsSubpattern; item: CsUnaryPattern) = # UP
  echo "in method add*(parent: CsSubpattern; item: CsUnaryPattern)"
  todoimplAdd() # TODO(add: CsSubpattern, CsUnaryPattern)

method add*(parent: CsArgument; item: CsSwitchExpression) = # SE
  echo "in method add*(parent: CsArgument; item: CsSwitchExpression)"
  todoimplAdd() # TODO(add: CsArgument, CsSwitchExpression)

method add*(parent: CsArgument; item: CsThrowExpression) = # TE
  echo "in method add*(parent: CsArgument; item: CsThrowExpression)"
  todoimplAdd() # TODO(add: CsArgument, CsThrowExpression)

method add*(parent: CsCheckedExpression; item: CsPrefixUnaryExpression) = # PUE
  echo "in method add*(parent: CsCheckedExpression; item: CsPrefixUnaryExpression)"
  todoimplAdd() # TODO(add: CsCheckedExpression, CsPrefixUnaryExpression)

method add*(parent: CsThrowExpression; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsThrowExpression; item: CsParenthesizedExpression)"
  todoimplAdd() # TODO(add: CsThrowExpression, CsParenthesizedExpression)

method add*(parent: CsRangeExpression; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsRangeExpression; item: CsParenthesizedExpression)"
  todoimplAdd() # TODO(add: CsRangeExpression, CsParenthesizedExpression)

method add*(parent: CsWhenClause; item: CsPrefixUnaryExpression) = # PUE
  echo "in method add*(parent: CsWhenClause; item: CsPrefixUnaryExpression)"
  todoimplAdd() # TODO(add: CsWhenClause, CsPrefixUnaryExpression)

method add*(parent: CsIsPatternExpression; item: CsVarPattern) = # VP
  echo "in method add*(parent: CsIsPatternExpression; item: CsVarPattern)"
  todoimplAdd() # TODO(add: CsIsPatternExpression, CsVarPattern)

method add*(parent: CsCatchFilterClause; item: CsIsPatternExpression) = # IPE
  echo "in method add*(parent: CsCatchFilterClause; item: CsIsPatternExpression)"
  todoimplAdd() # TODO(add: CsCatchFilterClause, CsIsPatternExpression)

method add*(parent: CsSimpleLambdaExpression; item: CsParenthesizedLambdaExpression) = # PLE
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsParenthesizedLambdaExpression)"
  todoimplAdd() # TODO(add: CsSimpleLambdaExpression, CsParenthesizedLambdaExpression)

method add*(parent: CsTypeArgumentList; item: TypeNameDef) =
  #item: CsRefType|CsPointerType|CsTupleType|CsNullableType|CsOmittedTypeArgument) = # RT
  echo "in method add*(parent: CsTypeArgumentList; item: CsRefType)"
  parent.gotTypes.add item

method add*(parent: CsForEachStatement; item: CsRefType) = # RT
  echo "in method add*(parent: CsForEachStatement; item: CsRefType)"
  parent.gotType = item

method add*(parent: CsVarPattern; item: CsSingleVariableDesignation) = # SVD
  echo "in method add*(parent: CsVarPattern; item: CsSingleVariableDesignation)"
  todoimplAdd() # TODO(add: CsVarPattern, CsSingleVariableDesignation)

method add*(parent: CsSubpattern; item: CsRecursivePattern) = # RP
  echo "in method add*(parent: CsSubpattern; item: CsRecursivePattern)"
  parent.pat = item

method add*(parent: CsSubpattern; item: Pattern) = # RP
  echo "in method add*(parent: CsSubpattern; item: CsRecursivePattern)"
  parent.pat = item

method add*(parent: CsArgument; item: CsStackAllocArrayCreationExpression) = # SAACE
  echo "in method add*(parent: CsArgument; item: CsStackAllocArrayCreationExpression)"
  todoimplAdd() # TODO(add: CsArgument, CsStackAllocArrayCreationExpression)

method add*(parent: CsAccessor; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsAccessor; item: CsLiteralExpression)"
  parent.body.add item

method add*(parent: CsRefType; item: CsArrayType) = # AT
  echo "in method add*(parent: CsRefType; item: CsArrayType)"
  parent.gotType = item

method add*(parent: CsAwaitExpression; item: CsThisExpression) = # TE
  echo "in method add*(parent: CsAwaitExpression; item: CsThisExpression)"
  todoimplAdd() # TODO(add: CsAwaitExpression, CsThisExpression)

method add*(parent: CsIfStatement; item: CsCheckedStatement) = # CS
  echo "in method add*(parent: CsIfStatement; item: CsCheckedStatement)"
  todoimplAdd() # TODO(add: CsIfStatement, CsCheckedStatement)

method add*(parent: CsSubpattern; item: CsRelationalPattern) = # RP
  echo "in method add*(parent: CsSubpattern; item: CsRelationalPattern)"
  todoimplAdd() # TODO(add: CsSubpattern, CsRelationalPattern)

method add*(parent: CsIsPatternExpression; item: CsDefaultExpression) = # DE
  echo "in method add*(parent: CsIsPatternExpression; item: CsDefaultExpression)"
  todoimplAdd() # TODO(add: CsIsPatternExpression, CsDefaultExpression)

method add*(parent: CsConstantPattern; item: CsIsPatternExpression) = # IPE
  echo "in method add*(parent: CsConstantPattern; item: CsIsPatternExpression)"
  parent.patExpr = item

method add*(parent: CsArrayRankSpecifier; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsArrayRankSpecifier; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsDeclarationExpression; item: CsTupleType) = # TT
  echo "in method add*(parent: CsDeclarationExpression; item: CsTupleType)"
  parent.gotType = item

method add*(parent: CsImplicitObjectCreationExpression; item: CsInitializerExpression) = # IE
  echo "in method add*(parent: CsImplicitObjectCreationExpression; item: CsInitializerExpression)"
  todoimplAdd() # TODO(add: CsImplicitObjectCreationExpression, CsInitializerExpression)

method add*(parent: CsLetClause; item: CsBinaryExpression) = # BE
  echo "in method add*(parent: CsLetClause; item: CsBinaryExpression)"
  todoimplAdd() # TODO(add: CsLetClause, CsBinaryExpression)

method add*(parent: CsLetClause; item: CsCastExpression) = # CE
  echo "in method add*(parent: CsLetClause; item: CsCastExpression)"
  todoimplAdd() # TODO(add: CsLetClause, CsCastExpression)

method add*(parent: CsLetClause; item: CsImplicitArrayCreationExpression) = # IACE
  echo "in method add*(parent: CsLetClause; item: CsImplicitArrayCreationExpression)"
  todoimplAdd() # TODO(add: CsLetClause, CsImplicitArrayCreationExpression)

method add*(parent: CsParenthesizedLambdaExpression; item: CsSimpleLambdaExpression) = # SLE
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsSimpleLambdaExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedLambdaExpression; item: CsThisExpression) = # TE
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsThisExpression)"
  todoimplAdd() # TODO(add: CsParenthesizedLambdaExpression, CsThisExpression)

method add*(parent: CsSwitchExpressionArm; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsAwaitExpression)"
  todoimplAdd() # TODO(add: CsSwitchExpressionArm, CsAwaitExpression)

method add*(parent: CsSwitchExpressionArm; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsElementAccessExpression)"
  todoimplAdd() # TODO(add: CsSwitchExpressionArm, CsElementAccessExpression)

method add*(parent: CsSwitchExpressionArm; item: CsIsPatternExpression) = # IPE
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsIsPatternExpression)"
  todoimplAdd() # TODO(add: CsSwitchExpressionArm, CsIsPatternExpression)

method add*(parent: CsSwitchExpressionArm; item: CsRelationalPattern) = # RP
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsRelationalPattern)"
  todoimplAdd() # TODO(add: CsSwitchExpressionArm, CsRelationalPattern)

method add*(parent: CsSwitchExpressionArm; item: CsTypeOfExpression) = # TOE
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsTypeOfExpression)"
  todoimplAdd() # TODO(add: CsSwitchExpressionArm, CsTypeOfExpression)

method add*(parent: CsSwitchExpressionArm; item: CsVarPattern) = # VP
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsVarPattern)"
  todoimplAdd() # TODO(add: CsSwitchExpressionArm, CsVarPattern)

method add*(parent: CsSwitchExpressionArm; item: CsWhenClause) = # WC
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsWhenClause)"
  todoimplAdd() # TODO(add: CsSwitchExpressionArm, CsWhenClause)

method add*(parent: CsYieldStatement; item: CsAssignmentExpression) = # AE
  echo "in method add*(parent: CsYieldStatement; item: CsAssignmentExpression)"
  parent.expr = item

method add*(parent: CsSwitchExpression; item: CsConditionalAccessExpression) = # CAE
  echo "in method add*(parent: CsSwitchExpression; item: CsConditionalAccessExpression)"
  parent.on = item

method add*(parent: CsSwitchExpression; item: CsThisExpression) = # TE
  echo "in method add*(parent: CsSwitchExpression; item: CsThisExpression)"
  todoimplAdd() # TODO(add: CsSwitchExpression, CsThisExpression)

method add*(parent: CsSwitchExpression; item: CsTypeOfExpression) = # TOE
  echo "in method add*(parent: CsSwitchExpression; item: CsTypeOfExpression)"
  todoimplAdd() # TODO(add: CsSwitchExpression, CsTypeOfExpression)

method add*(parent: CsAwaitExpression; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsAwaitExpression; item: CsElementAccessExpression)"
  todoimplAdd() # TODO(add: CsAwaitExpression, CsElementAccessExpression)

method add*(parent: CsAwaitExpression; item: CsInterpolatedStringExpression) = # ISE
  echo "in method add*(parent: CsAwaitExpression; item: CsInterpolatedStringExpression)"
  todoimplAdd() # TODO(add: CsAwaitExpression, CsInterpolatedStringExpression)

method add*(parent: CsMemberAccessExpression; item: CsStackAllocArrayCreationExpression) = # SAACE
  echo "in method add*(parent: CsMemberAccessExpression; item: CsStackAllocArrayCreationExpression)"
  todoimplAdd() # TODO(add: CsMemberAccessExpression, CsStackAllocArrayCreationExpression)

method add*(parent: CsInitializerExpression; item: CsGenericName) = # GN
  echo "in method add*(parent: CsInitializerExpression; item: CsGenericName)"
  parent.gotType = item

method add*(parent: CsInitializerExpression; item: CsSizeOfExpression) = # SOE
  echo "in method add*(parent: CsInitializerExpression; item: CsSizeOfExpression)"
  parent.bexprs.add item


method add*(parent: CsParenthesizedVariableDesignation; item: CsParenthesizedVariableDesignation) = # PVD
  echo "in method add*(parent: CsParenthesizedVariableDesignation; item: CsParenthesizedVariableDesignation)"
  todoimplAdd() # TODO(add: CsParenthesizedVariableDesignation, CsParenthesizedVariableDesignation)

method add*(parent: CsConstantPattern; item: CsCastExpression) = # CE
  echo "in method add*(parent: CsConstantPattern; item: CsCastExpression)"
  parent.valExpr = item

method add*(parent: CsConstantPattern; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsConstantPattern; item: CsElementAccessExpression)"
  todoimplAdd() # TODO(add: CsConstantPattern, CsElementAccessExpression)

method add*(parent: CsLabeledStatement; item: CsEmptyStatement) = # ES
  echo "in method add*(parent: CsLabeledStatement; item: CsEmptyStatement)"
  # ignore?
  # todoimplAdd() # TODO(add: CsLabeledStatement, CsEmptyStatement)

method add*(parent: CsExpressionStatement; item: CsIsPatternExpression) = # IPE
  echo "in method add*(parent: CsExpressionStatement; item: CsIsPatternExpression)"
  todoimplAdd() # TODO(add: CsExpressionStatement, CsIsPatternExpression)

method add*(parent: CsExpressionStatement; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsExpressionStatement; item: CsParenthesizedExpression)"
  todoimplAdd() # TODO(add: CsExpressionStatement, CsParenthesizedExpression)

method add*(parent: CsExpressionStatement; item: CsTupleExpression) = # TE
  echo "in method add*(parent: CsExpressionStatement; item: CsTupleExpression)"
  todoimplAdd() # TODO(add: CsExpressionStatement, CsTupleExpression)

method add*(parent: CsRecursivePattern; item: CsSingleVariableDesignation) = # SVD
  echo "in method add*(parent: CsRecursivePattern; item: CsSingleVariableDesignation)"
  todoimplAdd() # TODO(add: CsRecursivePattern, CsSingleVariableDesignation)

method add*(parent: CsConversionOperator; item: CsTupleType) = # TT
  echo "in method add*(parent: CsConversionOperator; item: CsTupleType)"
  parent.gotType = item

method add*(parent: CsSwitchStatement; item: CsAssignmentExpression) = # AE
  echo "in method add*(parent: CsSwitchStatement; item: CsAssignmentExpression)"
  parent.on = item

method add*(parent: CsSwitchStatement; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsSwitchStatement; item: CsParenthesizedExpression)"
  parent.on = item

method add*(parent: CsSwitchStatement; item: CsPostfixUnaryExpression) = # PUE
  echo "in method add*(parent: CsSwitchStatement; item: CsPostfixUnaryExpression)"
  parent.on = item

method add*(parent: CsParenthesizedExpression; item: CsSizeOfExpression) = # SOE
  echo "in method add*(parent: CsParenthesizedExpression; item: CsSizeOfExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedExpression; item: CsSwitchExpression) = # SE
  echo "in method add*(parent: CsParenthesizedExpression; item: CsSwitchExpression)"
  parent.body.add item

method add*(parent: CsCasePatternSwitchLabel; item: CsRecursivePattern) = # RP
  echo "in method add*(parent: CsCasePatternSwitchLabel; item: CsRecursivePattern)"
  todoimplAdd() # TODO(add: CsCasePatternSwitchLabel, CsRecursivePattern)

method add*(parent: CsSwitchSection; item: CsCheckedStatement) = # CS
  echo "in method add*(parent: CsSwitchSection; item: CsCheckedStatement)"
  parent.body.add item

method add*(parent: CsCastExpression; item: CsTupleType) = # TT
  echo "in method add*(parent: CsCastExpression; item: CsTupleType)"
  parent.gotType = item

method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsConditionalAccessExpression) = # CAE
  echo "in method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsConditionalAccessExpression)"
  todoimplAdd() # TODO(add: CsAnonymousObjectMemberDeclarator, CsConditionalAccessExpression)

method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsPrefixUnaryExpression) = # PUE
  echo "in method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsPrefixUnaryExpression)"
  todoimplAdd() # TODO(add: CsAnonymousObjectMemberDeclarator, CsPrefixUnaryExpression)

method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsTypeOfExpression) = # TOE
  echo "in method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsTypeOfExpression)"
  todoimplAdd() # TODO(add: CsAnonymousObjectMemberDeclarator, CsTypeOfExpression)

method add*(parent: CsAccessor; item: CsGotoStatement) = # GS
  echo "in method add*(parent: CsAccessor; item: CsGotoStatement)"
  parent.body.add item

method add*(parent: CsCatchFilterClause; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsCatchFilterClause; item: CsMemberAccessExpression)"
  todoimplAdd() # TODO(add: CsCatchFilterClause, CsMemberAccessExpression)

method add*(parent: CsNamespace; item: CsEventField) = # EF
  echo "in method add*(parent: CsNamespace; item: CsEventField)"
  todoimplAdd() # TODO(add: CsNamespace, CsEventField)

method add*(parent: CsUsingStatement; item: CsUnsafeStatement) = # US
  echo "in method add*(parent: CsUsingStatement; item: CsUnsafeStatement)"
  parent.body.add item

method add*(parent: CsBinaryPattern; item: CsTypePattern) = # TP
  echo "in method add*(parent: CsBinaryPattern; item: CsTypePattern)"
  todoimplAdd() # TODO(add: CsBinaryPattern, CsTypePattern)

method add*(parent: CsDefaultExpression; item: CsTupleType) = # TT
  echo "in method add*(parent: CsDefaultExpression; item: CsTupleType)"
  parent.gotType = item

method add*(parent: CsStruct; item: CsEvent) =
  echo "in method add*(parent: CsStruct; item: CsEvent)"
  todoimplAdd() # TODO(add: CsStruct, CsEvent)

method add*(parent: CsStruct; item: CsInterface) =
  echo "in method add*(parent: CsStruct; item: CsInterface)"
  todoimplAdd() # TODO(add: CsStruct, CsInterface)

method add*(parent: CsOmittedArraySizeExpression; item: CsGenericName) = # GN
  echo "in method add*(parent: CsOmittedArraySizeExpression; item: CsGenericName)"
  todoimplAdd() # TODO(add: CsOmittedArraySizeExpression, CsGenericName)

method add*(parent: CsForStatement; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsForStatement; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsForStatement; item: CsTryStatement) = # TS
  echo "in method add*(parent: CsForStatement; item: CsTryStatement)"
  parent.body.add item

method add*(parent: CsForStatement; item: CsUnsafeStatement) = # US
  echo "in method add*(parent: CsForStatement; item: CsUnsafeStatement)"
  todoimplAdd() # TODO(add: CsForStatement, CsUnsafeStatement)

method add*(parent: CsElseClause; item: CsForEachStatement) = # FES
  echo "in method add*(parent: CsElseClause; item: CsForEachStatement)"
  parent.body.add item

method add*(parent: CsThrowStatement; item: CsBinaryExpression) = # BE
  echo "in method add*(parent: CsThrowStatement; item: CsBinaryExpression)"
  parent.body.add item

method add*(parent: CsIndexer; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsIndexer; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsIndexer, CsLiteralExpression)

method add*(parent: CsIndexer; item: CsTupleType) = # TT
  echo "in method add*(parent: CsIndexer; item: CsTupleType)"
  parent.gotType = item

method add*(parent: CsCaseSwitchLabel; item: CsSizeOfExpression) = # SOE
  echo "in method add*(parent: CsCaseSwitchLabel; item: CsSizeOfExpression)"
  parent.other = item

method add*(parent: CsWithExpression; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsWithExpression; item: CsInvocationExpression)"
  todoimplAdd() # TODO(add: CsWithExpression, CsInvocationExpression)

method add*(parent: CsConditionalExpression; item: CsAnonymousMethodExpression) = # AME
  echo "in method add*(parent: CsConditionalExpression; item: CsAnonymousMethodExpression)"
  parent.addConditional(item)

method add*(parent: CsConditionalExpression; item: CsGenericName) = # GN
  echo "in method add*(parent: CsConditionalExpression; item: CsGenericName)"
  todoimplAdd() # TODO(add: CsConditionalExpression, CsGenericName)

method add*(parent: CsConditionalExpression; item: CsSizeOfExpression) = # SOE
  echo "in method add*(parent: CsConditionalExpression; item: CsSizeOfExpression)"
  parent.addConditional(item)

method add*(parent: CsConditionalExpression; item: CsSwitchExpression) = # SE
  echo "in method add*(parent: CsConditionalExpression; item: CsSwitchExpression)"
  parent.addConditional(item)

method add*(parent: CsRelationalPattern; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsRelationalPattern; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsRelationalPattern, CsLiteralExpression)

method add*(parent: CsConstructor; item: CsCastExpression) = # CE
  echo "in method add*(parent: CsConstructor; item: CsCastExpression)"
  todoimplAdd() # TODO(add: CsConstructor, CsCastExpression)

method add*(parent: CsConstructor; item: CsGotoStatement) = # GS
  echo "in method add*(parent: CsConstructor; item: CsGotoStatement)"
  parent.body.add item

method add*(parent: CsTypeConstraint; item: CsNullableType) = # NT
  echo "in method add*(parent: CsTypeConstraint; item: CsNullableType)"
  parent.gotType = item

method add*(parent: CsSimpleLambdaExpression; item: CsTypeOfExpression) = # TOE
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsTypeOfExpression)"
  parent.body.add item

method add*(parent: CsRefType; item: CsNullableType) = # NT
  echo "in method add*(parent: CsRefType; item: CsNullableType)"
  parent.gotType = item

method add*(parent: CsReturnStatement; item: CsImplicitObjectCreationExpression) = # IOCE
  echo "in method add*(parent: CsReturnStatement; item: CsImplicitObjectCreationExpression)"
  parent.expr = item

method add*(parent: CsCheckedExpression; item: CsPostfixUnaryExpression) = # PUE
  echo "in method add*(parent: CsCheckedExpression; item: CsPostfixUnaryExpression)"
  todoimplAdd() # TODO(add: CsCheckedExpression, CsPostfixUnaryExpression)

method add*(parent: CsThrowExpression; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsThrowExpression; item: CsMemberAccessExpression)"
  todoimplAdd() # TODO(add: CsThrowExpression, CsMemberAccessExpression)

method add*(parent: CsDelegate; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsDelegate; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsDelegate, CsLiteralExpression)

method add*(parent: CsForEachStatement; item: CsConditionalExpression) = # CE
  echo "in method add*(parent: CsForEachStatement; item: CsConditionalExpression)"
  todoimplAdd() # TODO(add: CsForEachStatement, CsConditionalExpression)

method add*(parent: CsForEachStatement; item: CsTryStatement) = # TS
  echo "in method add*(parent: CsForEachStatement; item: CsTryStatement)"
  parent.body.add item

method add*(parent: CsRangeExpression; item: CsPrefixUnaryExpression) = # PUE
  echo "in method add*(parent: CsRangeExpression; item: CsPrefixUnaryExpression)"
  todoimplAdd() # TODO(add: CsRangeExpression, CsPrefixUnaryExpression)

method add*(parent: CsTryStatement; item: CsBreakStatement) = # BS
  echo "in method add*(parent: CsTryStatement; item: CsBreakStatement)"
  parent.body.add item

method add*(parent: CsConversionOperator; item: CsLocalDeclarationStatement) = # LDS
  echo "in method add*(parent: CsConversionOperator; item: CsLocalDeclarationStatement)"
  parent.body.add item

method add*(parent: CsWhileStatement; item: CsBreakStatement) = # BS
  echo "in method add*(parent: CsWhileStatement; item: CsBreakStatement)"
  parent.body.add item

method add*(parent: CsAccessor; item: CsLocalDeclarationStatement) = # LDS
  echo "in method add*(parent: CsAccessor; item: CsLocalDeclarationStatement)"
  parent.body.add item

method add*(parent: CsSubpattern; item: CsBinaryPattern) = # BP
  echo "in method add*(parent: CsSubpattern; item: CsBinaryPattern)"
  todoimplAdd() # TODO(add: CsSubpattern, CsBinaryPattern)

method add*(parent: CsMethod; item: CsBreakStatement) = # BS
  echo "in method add*(parent: CsMethod; item: CsBreakStatement)"
  todoimplAdd() # TODO(add: CsMethod, CsBreakStatement)

method add*(parent: CsQueryExpression; item: CsFromClause) = # FC
  echo "in method add*(parent: CsQueryExpression; item: CsFromClause)"
  parent.fromClause = item

method add*(parent: CsBinaryPattern; item: CsRecursivePattern) = # RP
  echo "in method add*(parent: CsBinaryPattern; item: CsRecursivePattern)"
  todoimplAdd() # TODO(add: CsBinaryPattern, CsRecursivePattern)

method add*(parent: CsFromClause; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsFromClause; item: CsAwaitExpression)"
  todoimplAdd() # TODO(add: CsFromClause, CsAwaitExpression)

method add*(parent: CsFromClause; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsFromClause; item: CsInvocationExpression)"
  parent.inPart = item

method add*(parent: CsFromClause; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsFromClause; item: CsLiteralExpression)"
  parent.inPart = item # TODO: logically literal would be how we define the alias.
  # so maybe other cases here? according to the current example, it's in the inpart:
  # from item in "abcd"    ... treating the string as a char array.

method add*(parent: CsFromClause; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsFromClause; item: CsMemberAccessExpression)"
  parent.withMember =item

method add*(parent: CsQueryBody; item: CsSelectClause) = # SC
  echo "in method add*(parent: CsQueryBody; item: CsSelectClause)"
  parent.selectClause = item

method add*(parent: CsQueryBody; item: CsJoinClause) = # JC
  echo "in method add*(parent: CsQueryBody; item: CsJoinClause)"
  parent.join = item

method add*(parent: CsSelectClause; item: CsAnonymousObjectCreationExpression) = # AOCE
  echo "in method add*(parent: CsSelectClause; item: CsAnonymousObjectCreationExpression)"
  parent.expr = item

method add*(parent: CsSelectClause; item: CsArrayCreationExpression) = # ACE
  echo "in method add*(parent: CsSelectClause; item: CsArrayCreationExpression)"
  parent.expr = item

method add*(parent: CsSelectClause; item: CsConditionalExpression) = # CE
  echo "in method add*(parent: CsSelectClause; item: CsConditionalExpression)"
  parent.expr = item

method add*(parent: CsSelectClause; item: CsTupleExpression) = # TE
  echo "in method add*(parent: CsSelectClause; item: CsTupleExpression)"
  parent.expr = item

method add*(parent: CsJoinClause; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsJoinClause; item: CsInvocationExpression)"
  if parent.inPart.isNil:
    parent.inPart = item
  else: assert false # possibly onPart. but wait for an example.

method add*(parent: CsQueryBody; item: CsFromClause) = # FC
  echo "in method add*(parent: CsQueryBody; item: CsFromClause)"
  parent.fromClause = item

method add*(parent: CsQueryBody; item: CsOrderByClause) = # OBC
  echo "in method add*(parent: CsQueryBody; item: CsOrderByClause)"
  parent.orderBy = item

method add*(parent: CsQueryBody; item: CsWhereClause) = # WC
  echo "in method add*(parent: CsQueryBody; item: CsWhereClause)"
  parent.where = item

method add*(parent: CsSelectClause; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsSelectClause; item: CsMemberAccessExpression)"
  parent.withMember = item

method add*(parent: CsOrderByClause; item: CsOrdering) =
  echo "in method add*(parent: CsOrderByClause; item: CsOrdering)"
  parent.ordering = item

method add*(parent: CsWhereClause; item: CsBinaryExpression) = # BE
  echo "in method add*(parent: CsWhereClause; item: CsBinaryExpression)"
  parent.predicate = item

method add*(parent: CsWhereClause; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsWhereClause; item: CsInvocationExpression)"
  parent.expr = item

method add*(parent: CsSelectClause; item: CsCastExpression) = # CE
  echo "in method add*(parent: CsSelectClause; item: CsCastExpression)"
  parent.expr = item

method add*(parent: CsSelectClause; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsSelectClause; item: CsInvocationExpression)"
  parent.expr = item

method add*(parent: CsFromClause; item: CsArrayCreationExpression) = # ACE
  echo "in method add*(parent: CsFromClause; item: CsArrayCreationExpression)"
  parent.inPart = item

method add*(parent: CsFromClause; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsFromClause; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsQueryBody; item: CsGroupClause) = # GC
  echo "in method add*(parent: CsQueryBody; item: CsGroupClause)"
  parent.group = item

method add*(parent: CsSelectClause; item: CsBinaryExpression) = # BE
  echo "in method add*(parent: CsSelectClause; item: CsBinaryExpression)"
  parent.expr = item

method add*(parent: CsSelectClause; item: CsInterpolatedStringExpression) = # ISE
  echo "in method add*(parent: CsSelectClause; item: CsInterpolatedStringExpression)"
  todoimplAdd() # TODO(add: CsSelectClause, CsInterpolatedStringExpression)

method add*(parent: CsGroupClause; item: CsAnonymousObjectCreationExpression) = # AOCE
  echo "in method add*(parent: CsGroupClause; item: CsAnonymousObjectCreationExpression)"
  todoimplAdd() # TODO(add: CsGroupClause, CsAnonymousObjectCreationExpression)

method add*(parent: CsGroupClause; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsGroupClause; item: CsMemberAccessExpression)"
  parent.withMember = item

method add*(parent: CsFromClause; item: CsImplicitArrayCreationExpression) = # IACE
  echo "in method add*(parent: CsFromClause; item: CsImplicitArrayCreationExpression)"
  parent.inPart = item

method add*(parent: CsQueryBody; item: CsQueryContinuation) = # QC
  echo "in method add*(parent: CsQueryBody; item: CsQueryContinuation)"
  parent.cont = item

method add*(parent: CsSelectClause; item: CsObjectCreationExpression) = # OCE
  echo "in method add*(parent: CsSelectClause; item: CsObjectCreationExpression)"
  todoimplAdd() # TODO(add: CsSelectClause, CsObjectCreationExpression)

method add*(parent: CsQueryContinuation; item: CsQueryBody) = # QB
  echo "in method add*(parent: CsQueryContinuation; item: CsQueryBody)"
  parent.queryBody = item

method add*(parent: CsGroupClause; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsGroupClause; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsGroupClause, CsLiteralExpression)

method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsQueryExpression) = # QE
  echo "in method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsQueryExpression)"
  parent.value = item

method add*(parent: CsWhereClause; item: CsPrefixUnaryExpression) = # PUE
  echo "in method add*(parent: CsWhereClause; item: CsPrefixUnaryExpression)"
  todoimplAdd() # TODO(add: CsWhereClause, CsPrefixUnaryExpression)

method add*(parent: CsSelectClause; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsSelectClause; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsSelectClause, CsLiteralExpression)

method add*(parent: CsOrdering; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsOrdering; item: CsMemberAccessExpression)"
  parent.value = item

method add*(parent: CsGroupClause; item: CsBinaryExpression) = # BE
  echo "in method add*(parent: CsGroupClause; item: CsBinaryExpression)"
  todoimplAdd() # TODO(add: CsGroupClause, CsBinaryExpression)

method add*(parent: CsFromClause; item: CsThisExpression) = # TE
  echo "in method add*(parent: CsFromClause; item: CsThisExpression)"
  todoimplAdd() # TODO(add: CsFromClause, CsThisExpression)

method add*(parent: CsWhereClause; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsWhereClause; item: CsMemberAccessExpression)"
  todoimplAdd() # TODO(add: CsWhereClause, CsMemberAccessExpression)

method add*(parent: CsWhereClause; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsWhereClause; item: CsParenthesizedExpression)"
  parent.exprThatLeadsToBoolean = item

method add*(parent: CsSelectClause; item: CsQueryExpression) = # QE
  echo "in method add*(parent: CsSelectClause; item: CsQueryExpression)"
  parent.newQuery = item

method add*(parent: CsOrdering; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsOrdering; item: CsElementAccessExpression)"
  todoimplAdd() # TODO(add: CsOrdering, CsElementAccessExpression)

method add*(parent: CsGroupClause; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsGroupClause; item: CsInvocationExpression)"
  todoimplAdd() # TODO(add: CsGroupClause, CsInvocationExpression)

method add*(parent: CsOperator; item: CsPointerType) = # PT
  echo "in method add*(parent: CsOperator; item: CsPointerType)"
  parent.gotType = item

method add*(parent: CsJoinClause; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsJoinClause; item: CsMemberAccessExpression)"
  parent.onPart = item

method add*(parent: CsLetClause; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsLetClause; item: CsLiteralExpression)"
  parent.value = item

method add*(parent: CsOrdering; item: CsBinaryExpression) = # BE
  echo "in method add*(parent: CsOrdering; item: CsBinaryExpression)"
  todoimplAdd() # TODO(add: CsOrdering, CsBinaryExpression)

method add*(parent: CsJoinClause; item: CsJoinIntoClause) = # JIC
  echo "in method add*(parent: CsJoinClause; item: CsJoinIntoClause)"
  parent.into = item

method add*(parent: CsTypePattern; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsTypePattern; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsArrayRankSpecifier; item: CsAssignmentExpression) = # AE
  echo "in method add*(parent: CsArrayRankSpecifier; item: CsAssignmentExpression)"
  todoimplAdd() # TODO(add: CsArrayRankSpecifier, CsAssignmentExpression)

method add*(parent: CsArrayRankSpecifier; item: CsRangeExpression) = # RE
  echo "in method add*(parent: CsArrayRankSpecifier; item: CsRangeExpression)"
  todoimplAdd() # TODO(add: CsArrayRankSpecifier, CsRangeExpression)

method add*(parent: CsIsPatternExpression; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsIsPatternExpression; item: CsAwaitExpression)"
  todoimplAdd() # TODO(add: CsIsPatternExpression, CsAwaitExpression)

method add*(parent: CsYieldStatement; item: CsSimpleLambdaExpression) = # SLE
  echo "in method add*(parent: CsYieldStatement; item: CsSimpleLambdaExpression)"
  parent.expr = item

method add*(parent: CsDoStatement; item: CsAwaitExpression) = # AE
  echo "in method add*(parent: CsDoStatement; item: CsAwaitExpression)"
  todoimplAdd() # TODO(add: CsDoStatement, CsAwaitExpression)

method add*(parent: CsInitializerExpression; item: CsBaseExpression) = # BE
  echo "in method add*(parent: CsInitializerExpression; item: CsBaseExpression)"
  todoimplAdd() # TODO(add: CsInitializerExpression, CsBaseExpression)

method add*(parent: CsExpressionStatement; item: CsConditionalExpression) = # CE
  echo "in method add*(parent: CsExpressionStatement; item: CsConditionalExpression)"
  todoimplAdd() # TODO(add: CsExpressionStatement, CsConditionalExpression)

method add*(parent: CsSwitchStatement; item: CsBaseExpression) = # BE
  echo "in method add*(parent: CsSwitchStatement; item: CsBaseExpression)"
  parent.on = item

method add*(parent: CsParenthesizedExpression; item: CsDefaultExpression) = # DE
  echo "in method add*(parent: CsParenthesizedExpression; item: CsDefaultExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedExpression; item: CsRangeExpression) = # RE
  echo "in method add*(parent: CsParenthesizedExpression; item: CsRangeExpression)"
  parent.body.add item

method add*(parent: CsForEachVariableStatement; item: CsDeclarationExpression) = # DE
  echo "in method add*(parent: CsForEachVariableStatement; item: CsDeclarationExpression)"
  parent.varDecl = item

method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsParenthesizedExpression)"
  todoimplAdd() # TODO(add: CsAnonymousObjectMemberDeclarator, CsParenthesizedExpression)

method add*(parent: CsAssignmentExpression; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsAssignmentExpression; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsUsingStatement; item: CsLockStatement) = # LS
  echo "in method add*(parent: CsUsingStatement; item: CsLockStatement)"
  parent.body.add item

method add*(parent: CsUsingStatement; item: CsThrowStatement) = # TS
  echo "in method add*(parent: CsUsingStatement; item: CsThrowStatement)"
  parent.body.add item

method add*(parent: CsElseClause; item: CsTryStatement) = # TS
  echo "in method add*(parent: CsElseClause; item: CsTryStatement)"
  parent.body.add item

method add*(parent: CsElseClause; item: CsUsingStatement) = # US
  echo "in method add*(parent: CsElseClause; item: CsUsingStatement)"
  parent.body.add item

method add*(parent: CsInvocationExpression; item: CsSimpleLambdaExpression) = # SLE
  echo "in method add*(parent: CsInvocationExpression; item: CsSimpleLambdaExpression)"
  todoimplAdd() # TODO(add: CsInvocationExpression, CsSimpleLambdaExpression)

method add*(parent: CsWhileStatement; item: CsCheckedStatement) = # CS
  echo "in method add*(parent: CsWhileStatement; item: CsCheckedStatement)"
  todoimplAdd() # TODO(add: CsWhileStatement, CsCheckedStatement)

method add*(parent: CsWhileStatement; item: CsTryStatement) = # TS
  echo "in method add*(parent: CsWhileStatement; item: CsTryStatement)"
  todoimplAdd() # TODO(add: CsWhileStatement, CsTryStatement)

method add*(parent: CsThrowStatement; item: CsSwitchExpression) = # SE
  echo "in method add*(parent: CsThrowStatement; item: CsSwitchExpression)"
  parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsCheckedExpression) = # CE
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsCheckedExpression)"
  parent.body.add item

method add*(parent: CsCheckedExpression; item: CsImplicitArrayCreationExpression) = # IACE
  echo "in method add*(parent: CsCheckedExpression; item: CsImplicitArrayCreationExpression)"
  todoimplAdd() # TODO(add: CsCheckedExpression, CsImplicitArrayCreationExpression)

method add*(parent: CsForEachStatement; item: CsForStatement) = # FS
  echo "in method add*(parent: CsForEachStatement; item: CsForStatement)"
  parent.body.add item

method add*(parent: CsForEachStatement; item: CsThrowStatement) = # TS
  echo "in method add*(parent: CsForEachStatement; item: CsThrowStatement)"
  todoimplAdd() # TODO(add: CsForEachStatement, CsThrowStatement)

method add*(parent: CsWhenClause; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsWhenClause; item: CsMemberAccessExpression)"
  todoimplAdd() # TODO(add: CsWhenClause, CsMemberAccessExpression)

method add*(parent: CsWhenClause; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsWhenClause; item: CsParenthesizedExpression)"
  todoimplAdd() # TODO(add: CsWhenClause, CsParenthesizedExpression)

method add*(parent: CsFromClause; item: CsQueryExpression) = # QE
  echo "in method add*(parent: CsFromClause; item: CsQueryExpression)"
  todoimplAdd() # TODO(add: CsFromClause, CsQueryExpression)

method add*(parent: CsLetClause; item: CsObjectCreationExpression) = # OCE
  echo "in method add*(parent: CsLetClause; item: CsObjectCreationExpression)"
  todoimplAdd() # TODO(add: CsLetClause, CsObjectCreationExpression)

method add*(parent: CsFromClause; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsFromClause; item: CsParenthesizedExpression)"
  todoimplAdd() # TODO(add: CsFromClause, CsParenthesizedExpression)

method add*(parent: CsDestructor; item: CsLocalDeclarationStatement) = # LDS
  echo "in method add*(parent: CsDestructor; item: CsLocalDeclarationStatement)"
  parent.body.add item

method add*(parent: CsAnonymousMethodExpression; item: CsLocalDeclarationStatement) = # LDS
  echo "in method add*(parent: CsAnonymousMethodExpression; item: CsLocalDeclarationStatement)"
  parent.body.add item

method add*(parent: CsAnonymousMethodExpression; item: CsReturnStatement) = # RS
  echo "in method add*(parent: CsAnonymousMethodExpression; item: CsReturnStatement)"
  parent.body.add item


method add*(parent: CsConversionOperator; item: CsThrowStatement) = # TS
  echo "in method add*(parent: CsConversionOperator; item: CsThrowStatement)"
  parent.body.add item

method add*(parent: CsAccessor; item: CsSwitchStatement) = # SS
  echo "in method add*(parent: CsAccessor; item: CsSwitchStatement)"
  parent.body.add item

method add*(parent: CsParenthesizedLambdaExpression; item: CsIfStatement) = # IS
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsIfStatement)"
  parent.body.add item

method add*(parent: CsParenthesizedLambdaExpression; item: CsLocalDeclarationStatement) = # LDS
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsLocalDeclarationStatement)"
  parent.body.add item

method add*(parent: CsDestructor; item: CsThrowStatement) = # TS
  echo "in method add*(parent: CsDestructor; item: CsThrowStatement)"
  todoimplAdd() # TODO(add: CsDestructor, CsThrowStatement)

method add*(parent: CsParenthesizedLambdaExpression; item: CsTryStatement) = # TS
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsTryStatement)"
  parent.body.add item

method add*(parent: CsTryStatement; item: CsReturnStatement) = # RS
  echo "in method add*(parent: CsTryStatement; item: CsReturnStatement)"
  parent.body.add item

method add*(parent: CsConversionOperator; item: CsYieldStatement) = # YS
  echo "in method add*(parent: CsConversionOperator; item: CsYieldStatement)"
  todoimplAdd() # TODO(add: CsConversionOperator, CsYieldStatement)

method add*(parent: CsConstructor; item: CsSwitchStatement) = # SS
  echo "in method add*(parent: CsConstructor; item: CsSwitchStatement)"
  parent.body.add item

method add*(parent: CsParenthesizedLambdaExpression; item: CsReturnStatement) = # RS
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsReturnStatement)"
  parent.body.add item

method add*(parent: CsGlobalStatement; item: CsLocalDeclarationStatement) = # LDS
  echo "in method add*(parent: CsGlobalStatement; item: CsLocalDeclarationStatement)"
  todoimplAdd() # TODO(add: CsGlobalStatement, CsLocalDeclarationStatement)

method add*(parent: CsMethod; item: CsCheckedStatement) = # CS
  echo "in method add*(parent: CsMethod; item: CsCheckedStatement)"
  parent.body.add item

method add*(parent: CsMethod; item: CsLabeledStatement) = # LS
  echo "in method add*(parent: CsMethod; item: CsLabeledStatement)"
  parent.body.add item

method add*(parent: CsGlobalStatement; item: CsExpressionStatement) = # ES
  echo "in method add*(parent: CsGlobalStatement; item: CsExpressionStatement)"
  todoimplAdd() # TODO(add: CsGlobalStatement, CsExpressionStatement)

method add*(parent: CsLabeledStatement; item: CsReturnStatement) = # RS
  echo "in method add*(parent: CsLabeledStatement; item: CsReturnStatement)"
  parent.body.add item

method add*(parent: CsParenthesizedExpression; item: CsGenericName) = # GN
  echo "in method add*(parent: CsParenthesizedExpression; item: CsGenericName)"
  todoimplAdd() # TODO(add: CsParenthesizedExpression, CsGenericName)

method add*(parent: CsParenthesizedLambdaExpression; item: CsLabeledStatement) = # LS
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsLabeledStatement)"
  parent.body.add item

method add*(parent: CsParenthesizedLambdaExpression; item: CsUsingStatement) = # US
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsUsingStatement)"
  parent.body.add item

method add*(parent: CsAnonymousMethodExpression; item: CsGotoStatement) = # GS
  echo "in method add*(parent: CsAnonymousMethodExpression; item: CsGotoStatement)"
  parent.body.add item

method add*(parent: CsLabeledStatement; item: CsIfStatement) = # IS
  echo "in method add*(parent: CsLabeledStatement; item: CsIfStatement)"
  parent.body.add item

method add*(parent: CsExpressionStatement; item: CsArrayCreationExpression) = # ACE
  echo "in method add*(parent: CsExpressionStatement; item: CsArrayCreationExpression)"
  todoimplAdd() # TODO(add: CsExpressionStatement, CsArrayCreationExpression)

method add*(parent: CsExpressionStatement; item: CsParenthesizedLambdaExpression) = # PLE
  echo "in method add*(parent: CsExpressionStatement; item: CsParenthesizedLambdaExpression)"
  todoimplAdd() # TODO(add: CsExpressionStatement, CsParenthesizedLambdaExpression)

method add*(parent: CsGlobalStatement; item: CsEmptyStatement) = # ES
  echo "in method add*(parent: CsGlobalStatement; item: CsEmptyStatement)"
  todoimplAdd() # TODO(add: CsGlobalStatement, CsEmptyStatement)

method add*(parent: CsGlobalStatement; item: CsLabeledStatement) = # LS
  echo "in method add*(parent: CsGlobalStatement; item: CsLabeledStatement)"
  todoimplAdd() # TODO(add: CsGlobalStatement, CsLabeledStatement)

method add*(parent: CsGlobalStatement; item: CsLocalFunctionStatement) = # LFS
  echo "in method add*(parent: CsGlobalStatement; item: CsLocalFunctionStatement)"
  todoimplAdd() # TODO(add: CsGlobalStatement, CsLocalFunctionStatement)

method add*(parent: CsGlobalStatement; item: CsTryStatement) = # TS
  echo "in method add*(parent: CsGlobalStatement; item: CsTryStatement)"
  todoimplAdd() # TODO(add: CsGlobalStatement, CsTryStatement)

method add*(parent: CsGlobalStatement; item: CsUsingStatement) = # US
  echo "in method add*(parent: CsGlobalStatement; item: CsUsingStatement)"
  todoimplAdd() # TODO(add: CsGlobalStatement, CsUsingStatement)

method add*(parent: CsParenthesizedExpression; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsParenthesizedExpression; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsTryStatement; item: CsTryStatement) = # TS
  echo "in method add*(parent: CsTryStatement; item: CsTryStatement)"
  parent.body.add item

method add*(parent: CsIfStatement; item: CsDoStatement) = # DS
  echo "in method add*(parent: CsIfStatement; item: CsDoStatement)"
  parent.body.add item

method add*(parent: CsIfStatement; item: CsLabeledStatement) = # LS
  echo "in method add*(parent: CsIfStatement; item: CsLabeledStatement)"
  parent.body.add item

method add*(parent: CsForStatement; item: CsGotoStatement) = # GS
  echo "in method add*(parent: CsForStatement; item: CsGotoStatement)"
  parent.body.add item

method add*(parent: CsForStatement; item: CsReturnStatement) = # RS
  echo "in method add*(parent: CsForStatement; item: CsReturnStatement)"
  parent.body.add item

method add*(parent: CsForEachStatement; item: CsCheckedStatement) = # CS
  echo "in method add*(parent: CsForEachStatement; item: CsCheckedStatement)"
  todoimplAdd() # TODO(add: CsForEachStatement, CsCheckedStatement)

method add*(parent: CsForEachStatement; item: CsLocalDeclarationStatement) = # LDS
  echo "in method add*(parent: CsForEachStatement; item: CsLocalDeclarationStatement)"
  parent.body.add item

method add*(parent: CsGlobalStatement; item: CsReturnStatement) = # RS
  echo "in method add*(parent: CsGlobalStatement; item: CsReturnStatement)"
  todoimplAdd() # TODO(add: CsGlobalStatement, CsReturnStatement)

method add*(parent: CsParenthesizedLambdaExpression; item: CsSwitchStatement) = # SS
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsSwitchStatement)"
  parent.body.add item

method add*(parent: CsAnonymousMethodExpression; item: CsLabeledStatement) = # LS
  echo "in method add*(parent: CsAnonymousMethodExpression; item: CsLabeledStatement)"
  parent.body.add item

method add*(parent: CsAnonymousMethodExpression; item: CsSwitchStatement) = # SS
  echo "in method add*(parent: CsAnonymousMethodExpression; item: CsSwitchStatement)"
  parent.body.add item

method add*(parent: CsLabeledStatement; item: CsLocalDeclarationStatement) = # LDS
  echo "in method add*(parent: CsLabeledStatement; item: CsLocalDeclarationStatement)"
  parent.body.add item

method add*(parent: CsLabeledStatement; item: CsSwitchStatement) = # SS
  echo "in method add*(parent: CsLabeledStatement; item: CsSwitchStatement)"
  parent.body.add item

method add*(parent: CsLabeledStatement; item: CsThrowStatement) = # TS
  echo "in method add*(parent: CsLabeledStatement; item: CsThrowStatement)"
  parent.body.add item

method add*(parent: CsDestructor; item: CsLockStatement) = # LS
  echo "in method add*(parent: CsDestructor; item: CsLockStatement)"
  todoimplAdd() # TODO(add: CsDestructor, CsLockStatement)

method add*(parent: CsGlobalStatement; item: CsIfStatement) = # IS
  echo "in method add*(parent: CsGlobalStatement; item: CsIfStatement)"
  todoimplAdd() # TODO(add: CsGlobalStatement, CsIfStatement)

method add*(parent: CsLocalFunctionStatement; item: CsParameterList) = # PL
  echo "in method add*(parent: CsLocalFunctionStatement; item: CsParameterList)"
  parent.paramList = item

method add*(parent: CsLocalFunctionStatement; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsLocalFunctionStatement; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsLocalFunctionStatement; item: CsTupleType) = # TT
  echo "in method add*(parent: CsLocalFunctionStatement; item: CsTupleType)"
  parent.gotType = item

method add*(parent: CsAccessor; item: CsCheckedStatement) = # CS
  echo "in method add*(parent: CsAccessor; item: CsCheckedStatement)"
  parent.body.add item

method add*(parent: CsOperator; item: CsLocalDeclarationStatement) = # LDS
  echo "in method add*(parent: CsOperator; item: CsLocalDeclarationStatement)"
  parent.body.add  item

method add*(parent: CsTryStatement; item: CsCheckedStatement) = # CS
  echo "in method add*(parent: CsTryStatement; item: CsCheckedStatement)"
  parent.body.add item

method add*(parent: CsTryStatement; item: CsGotoStatement) = # GS
  echo "in method add*(parent: CsTryStatement; item: CsGotoStatement)"
  parent.body.add item

method add*(parent: CsTryStatement; item: CsLocalDeclarationStatement) = # LDS
  echo "in method add*(parent: CsTryStatement; item: CsLocalDeclarationStatement)"
  parent.body.add item

method add*(parent: CsTryStatement; item: CsUsingStatement) = # US
  echo "in method add*(parent: CsTryStatement; item: CsUsingStatement)"
  parent.body.add item

method add*(parent: CsElseClause; item: CsLabeledStatement) = # LS
  echo "in method add*(parent: CsElseClause; item: CsLabeledStatement)"
  parent.body.add item

method add*(parent: CsConstructor; item: CsCheckedStatement) = # CS
  echo "in method add*(parent: CsConstructor; item: CsCheckedStatement)"
  parent.body.add item

method add*(parent: CsLetClause; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsLetClause; item: CsElementAccessExpression)"
  todoimplAdd() # TODO(add: CsLetClause, CsElementAccessExpression)

method add*(parent: CsLetClause; item: CsTypeOfExpression) = # TOE
  echo "in method add*(parent: CsLetClause; item: CsTypeOfExpression)"
  todoimplAdd() # TODO(add: CsLetClause, CsTypeOfExpression)

method add*(parent: CsRefExpression; item: CsPostfixUnaryExpression) = # PUE
  echo "in method add*(parent: CsRefExpression; item: CsPostfixUnaryExpression)"
  todoimplAdd() # TODO(add: CsRefExpression, CsPostfixUnaryExpression)

method add*(parent: CsParenthesizedLambdaExpression; item: CsWhileStatement) = # WS
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsWhileStatement)"
  parent.body.add item

method add*(parent: CsParenthesizedExpression; item: CsAnonymousObjectCreationExpression) = # AOCE
  echo "in method add*(parent: CsParenthesizedExpression; item: CsAnonymousObjectCreationExpression)"
  parent.body.add item

method add*(parent: CsFromClause; item: CsNullableType) = # NT
  echo "in method add*(parent: CsFromClause; item: CsNullableType)"
  parent.gotType = item

method add*(parent: CsWhereClause; item: CsIsPatternExpression) = # IPE
  echo "in method add*(parent: CsWhereClause; item: CsIsPatternExpression)"
  todoimplAdd() # TODO(add: CsWhereClause, CsIsPatternExpression)

method add*(parent: CsElseClause; item: CsCheckedStatement) = # CS
  echo "in method add*(parent: CsElseClause; item: CsCheckedStatement)"
  parent.body.add item

method add*(parent: CsOrdering; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsOrdering; item: CsInvocationExpression)"
  todoimplAdd() # TODO(add: CsOrdering, CsInvocationExpression)

method add*(parent: CsLetClause; item: CsAnonymousObjectCreationExpression) = # AOCE
  echo "in method add*(parent: CsLetClause; item: CsAnonymousObjectCreationExpression)"
  todoimplAdd() # TODO(add: CsLetClause, CsAnonymousObjectCreationExpression)

method add*(parent: CsLabeledStatement; item: CsForEachVariableStatement) = # FEVS
  echo "in method add*(parent: CsLabeledStatement; item: CsForEachVariableStatement)"
  parent.body.add item

method add*(parent: CsLabeledStatement; item: CsLabeledStatement) = # LS
  echo "in method add*(parent: CsLabeledStatement; item: CsLabeledStatement)"
  parent.body.add item

method add*(parent: CsLabeledStatement; item: CsTryStatement) = # TS
  echo "in method add*(parent: CsLabeledStatement; item: CsTryStatement)"
  parent.body.add item

method add*(parent: CsLabeledStatement; item: CsWhileStatement) = # WS
  echo "in method add*(parent: CsLabeledStatement; item: CsWhileStatement)"
  parent.body.add item

method add*(parent: CsConversionOperator; item: CsSwitchStatement) = # SS
  echo "in method add*(parent: CsConversionOperator; item: CsSwitchStatement)"
  todoimplAdd() # TODO(add: CsConversionOperator, CsSwitchStatement)

method add*(parent: CsForEachVariableStatement; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsForEachVariableStatement; item: CsMemberAccessExpression)"
  parent.listPart = item

method add*(parent: CsLocalFunctionStatement; item: CsArrowExpressionClause) = # AEC
  echo "in method add*(parent: CsLocalFunctionStatement; item: CsArrowExpressionClause)"
  parent.body.add item

method add*(parent: CsLocalFunctionStatement; item: CsGenericName) = # GN
  echo "in method add*(parent: CsLocalFunctionStatement; item: CsGenericName)"
  parent.gotType = item

method add*(parent: CsTryStatement; item: CsLabeledStatement) = # LS
  echo "in method add*(parent: CsTryStatement; item: CsLabeledStatement)"
  parent.body.add item

method add*(parent: CsTryStatement; item: CsSwitchStatement) = # SS
  echo "in method add*(parent: CsTryStatement; item: CsSwitchStatement)"
  parent.body.add item

method add*(parent: CsTryStatement; item: CsWhileStatement) = # WS
  echo "in method add*(parent: CsTryStatement; item: CsWhileStatement)"
  parent.body.add item

method add*(parent: CsForStatement; item: CsDoStatement) = # DS
  echo "in method add*(parent: CsForStatement; item: CsDoStatement)"
  parent.body.add item

method add*(parent: CsForStatement; item: CsLabeledStatement) = # LS
  echo "in method add*(parent: CsForStatement; item: CsLabeledStatement)"
  parent.body.add item

method add*(parent: CsElseClause; item: CsDoStatement) = # DS
  echo "in method add*(parent: CsElseClause; item: CsDoStatement)"
  parent.body.add item

method add*(parent: CsCheckedExpression; item: CsAnonymousObjectCreationExpression) = # AOCE
  echo "in method add*(parent: CsCheckedExpression; item: CsAnonymousObjectCreationExpression)"
  todoimplAdd() # TODO(add: CsCheckedExpression, CsAnonymousObjectCreationExpression)

method add*(parent: CsForEachStatement; item: CsDoStatement) = # DS
  echo "in method add*(parent: CsForEachStatement; item: CsDoStatement)"
  todoimplAdd() # TODO(add: CsForEachStatement, CsDoStatement)

method add*(parent: CsJoinClause; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsJoinClause; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsParenthesizedLambdaExpression; item: CsLockStatement) = # LS
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsLockStatement)"
  parent.body.add item

method add*(parent: CsLabeledStatement; item: CsForStatement) = # FS
  echo "in method add*(parent: CsLabeledStatement; item: CsForStatement)"
  parent.body.add item

method add*(parent: CsGlobalStatement; item: CsBreakStatement) = # BS
  echo "in method add*(parent: CsGlobalStatement; item: CsBreakStatement)"
  todoimplAdd() # TODO(add: CsGlobalStatement, CsBreakStatement)

method add*(parent: CsGlobalStatement; item: CsForEachStatement) = # FES
  echo "in method add*(parent: CsGlobalStatement; item: CsForEachStatement)"
  todoimplAdd() # TODO(add: CsGlobalStatement, CsForEachStatement)

method add*(parent: CsProperty; item: CsAliasQualifiedName) = # AQN
  echo "in method add*(parent: CsProperty; item: CsAliasQualifiedName)"
  todoimplAdd() # TODO(add: CsProperty, CsAliasQualifiedName)

method add*(parent: CsCastExpression; item: CsInterpolatedStringExpression) = # ISE
  echo "in method add*(parent: CsCastExpression; item: CsInterpolatedStringExpression)"
  parent.expr = item

method add*(parent: CsOperator; item: CsCheckedStatement) = # CS
  echo "in method add*(parent: CsOperator; item: CsCheckedStatement)"
  todoimplAdd() # TODO(add: CsOperator, CsCheckedStatement)

method add*(parent: CsTryStatement; item: CsLockStatement) = # LS
  echo "in method add*(parent: CsTryStatement; item: CsLockStatement)"
  parent.body.add item

method add*(parent: CsBinaryPattern; item: CsConstantPattern) = # CP
  echo "in method add*(parent: CsBinaryPattern; item: CsConstantPattern)"
  todoimplAdd() # TODO(add: CsBinaryPattern, CsConstantPattern)

method add*(parent: CsElseClause; item: CsLockStatement) = # LS
  echo "in method add*(parent: CsElseClause; item: CsLockStatement)"
  parent.body.add item

method add*(parent: CsRefType; item: CsTupleType) = # TT
  echo "in method add*(parent: CsRefType; item: CsTupleType)"
  parent.gotType = item

method add*(parent: CsForEachStatement; item: CsWhileStatement) = # WS
  echo "in method add*(parent: CsForEachStatement; item: CsWhileStatement)"
  todoimplAdd() # TODO(add: CsForEachStatement, CsWhileStatement)

method add*(parent: CsExpressionStatement; item: CsRangeExpression) = # RE
  echo "in method add*(parent: CsExpressionStatement; item: CsRangeExpression)"
  todoimplAdd() # TODO(add: CsExpressionStatement, CsRangeExpression)

method add*(parent: CsGlobalStatement; item: CsForEachVariableStatement) = # FEVS
  echo "in method add*(parent: CsGlobalStatement; item: CsForEachVariableStatement)"
  todoimplAdd() # TODO(add: CsGlobalStatement, CsForEachVariableStatement)

method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsCheckedExpression) = # CE
  echo "in method add*(parent: CsAnonymousObjectMemberDeclarator; item: CsCheckedExpression)"
  todoimplAdd() # TODO(add: CsAnonymousObjectMemberDeclarator, CsCheckedExpression)

method add*(parent: CsParenthesizedLambdaExpression; item: CsCheckedExpression) = # CE
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsCheckedExpression)"
  parent.body.add item

method add*(parent: CsParenthesizedLambdaExpression; item: CsDoStatement) = # DS
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsDoStatement)"
  parent.body.add item

method add*(parent: CsArrayType; item: CsAliasQualifiedName) = # AQN
  echo "in method add*(parent: CsArrayType; item: CsAliasQualifiedName)"
  todoimplAdd() # TODO(add: CsArrayType, CsAliasQualifiedName)

method add*(parent: CsTryStatement; item: CsDoStatement) = # DS
  echo "in method add*(parent: CsTryStatement; item: CsDoStatement)"
  parent.body.add item

method add*(parent: CsConstructor; item: CsLabeledStatement) = # LS
  echo "in method add*(parent: CsConstructor; item: CsLabeledStatement)"
  parent.body.add item

method add*(parent: CsForEachStatement; item: CsLockStatement) = # LS
  echo "in method add*(parent: CsForEachStatement; item: CsLockStatement)"
  todoimplAdd() # TODO(add: CsForEachStatement, CsLockStatement)

method add*(parent: CsJoinClause; item: CsAnonymousObjectCreationExpression) = # AOCE
  echo "in method add*(parent: CsJoinClause; item: CsAnonymousObjectCreationExpression)"
  todoimplAdd() # TODO(add: CsJoinClause, CsAnonymousObjectCreationExpression)

method add*(parent: CsArrowExpressionClause; item: CsAnonymousMethodExpression) = # AME
  echo "in method add*(parent: CsArrowExpressionClause; item: CsAnonymousMethodExpression)"
  parent.body.add item

method add*(parent: CsParameter; item: CsFunctionPointerType) = # FPT
  echo "in method add*(parent: CsParameter; item: CsFunctionPointerType)"
  parent.gotType = item

method add*(parent: CsJoinClause; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsJoinClause; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsJoinClause, CsLiteralExpression)

method add*(parent: CsExpressionStatement; item: CsBaseExpression) = # BE
  echo "in method add*(parent: CsExpressionStatement; item: CsBaseExpression)"
  todoimplAdd() # TODO(add: CsExpressionStatement, CsBaseExpression)

method add*(parent: CsGlobalStatement; item: CsForStatement) = # FS
  echo "in method add*(parent: CsGlobalStatement; item: CsForStatement)"
  todoimplAdd() # TODO(add: CsGlobalStatement, CsForStatement)

method add*(parent: CsRefValueExpression; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsRefValueExpression; item: CsParenthesizedExpression)"
  todoimplAdd() # TODO(add: CsRefValueExpression, CsParenthesizedExpression)

method add*(parent: CsElementAccessExpression; item: CsRefValueExpression) = # RVE
  echo "in method add*(parent: CsElementAccessExpression; item: CsRefValueExpression)"
  todoimplAdd() # TODO(add: CsElementAccessExpression, CsRefValueExpression)

method add*(parent: CsAnonymousMethodExpression; item: CsWhileStatement) = # WS
  echo "in method add*(parent: CsAnonymousMethodExpression; item: CsWhileStatement)"
  parent.body.add item

method add*(parent: CsBinaryExpression; item: CsRefTypeExpression) = # RTE
  echo "in method add*(parent: CsBinaryExpression; item: CsRefTypeExpression)"
  todoimplAdd() # TODO(add: CsBinaryExpression, CsRefTypeExpression)

method add*(parent: CsUsingStatement; item: CsLocalDeclarationStatement) = # LDS
  echo "in method add*(parent: CsUsingStatement; item: CsLocalDeclarationStatement)"
  parent.addToUsing item

method add*(parent: CsStruct; item: CsDestructor) =
  echo "in method add*(parent: CsStruct; item: CsDestructor)"
  parent.dtors.add item

method add*(parent: CsForStatement; item: CsCastExpression) = # CE
  echo "in method add*(parent: CsForStatement; item: CsCastExpression)"
  todoimplAdd() # TODO(add: CsForStatement, CsCastExpression)

method add*(parent: CsForStatement; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsForStatement; item: CsElementAccessExpression)"
  todoimplAdd() # TODO(add: CsForStatement, CsElementAccessExpression)

method add*(parent: CsWhileStatement; item: CsCastExpression) = # CE
  echo "in method add*(parent: CsWhileStatement; item: CsCastExpression)"
  todoimplAdd() # TODO(add: CsWhileStatement, CsCastExpression)

method add*(parent: CsWhileStatement; item: CsCheckedExpression) = # CE
  echo "in method add*(parent: CsWhileStatement; item: CsCheckedExpression)"
  todoimplAdd() # TODO(add: CsWhileStatement, CsCheckedExpression)

method add*(parent: CsWhileStatement; item: CsReturnStatement) = # RS
  echo "in method add*(parent: CsWhileStatement; item: CsReturnStatement)"
  todoimplAdd() # TODO(add: CsWhileStatement, CsReturnStatement)

method add*(parent: CsWhileStatement; item: CsWhileStatement) = # WS
  echo "in method add*(parent: CsWhileStatement; item: CsWhileStatement)"
  todoimplAdd() # TODO(add: CsWhileStatement, CsWhileStatement)

method add*(parent: CsConditionalExpression; item: CsMakeRefExpression) = # MRE
  echo "in method add*(parent: CsConditionalExpression; item: CsMakeRefExpression)"
  parent.addConditional(item)

method add*(parent: CsRefValueExpression; item: CsMakeRefExpression) = # MRE
  echo "in method add*(parent: CsRefValueExpression; item: CsMakeRefExpression)"
  todoimplAdd() # TODO(add: CsRefValueExpression, CsMakeRefExpression)

method add*(parent: CsDoStatement; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsDoStatement; item: CsElementAccessExpression)"
  todoimplAdd() # TODO(add: CsDoStatement, CsElementAccessExpression)

method add*(parent: CsExpressionStatement; item: CsImplicitArrayCreationExpression) = # IACE
  echo "in method add*(parent: CsExpressionStatement; item: CsImplicitArrayCreationExpression)"
  todoimplAdd() # TODO(add: CsExpressionStatement, CsImplicitArrayCreationExpression)

method add*(parent: CsSelectClause; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsSelectClause; item: CsElementAccessExpression)"
  parent.expr = item

method add*(parent: CsAssignmentExpression; item: CsMakeRefExpression) = # MRE
  echo "in method add*(parent: CsAssignmentExpression; item: CsMakeRefExpression)"
  todoimplAdd() # TODO(add: CsAssignmentExpression, CsMakeRefExpression)

method add*(parent: CsFunctionPointerType; item: CsParameter) =
  echo "in method add*(parent: CsFunctionPointerType; item: CsParameter)"
  todoimplAdd() # TODO(add: CsFunctionPointerType, CsParameter)

method add*(parent: CsMakeRefExpression; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsMakeRefExpression; item: CsElementAccessExpression)"
  todoimplAdd() # TODO(add: CsMakeRefExpression, CsElementAccessExpression)

method add*(parent: CsWhileStatement; item: CsThrowStatement) = # TS
  echo "in method add*(parent: CsWhileStatement; item: CsThrowStatement)"
  todoimplAdd() # TODO(add: CsWhileStatement, CsThrowStatement)

method add*(parent: CsInterpolation; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsInterpolation; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsIsPatternExpression; item: CsBinaryPattern) = # BP
  echo "in method add*(parent: CsIsPatternExpression; item: CsBinaryPattern)"
  todoimplAdd() # TODO(add: CsIsPatternExpression, CsBinaryPattern)

method add*(parent: CsRefValueExpression; item: CsArrayType) = # AT
  echo "in method add*(parent: CsRefValueExpression; item: CsArrayType)"
  parent.gotType = item

method add*(parent: CsDoStatement; item: CsCastExpression) = # CE
  echo "in method add*(parent: CsDoStatement; item: CsCastExpression)"
  todoimplAdd() # TODO(add: CsDoStatement, CsCastExpression)

method add*(parent: CsDoStatement; item: CsCheckedExpression) = # CE
  echo "in method add*(parent: CsDoStatement; item: CsCheckedExpression)"
  todoimplAdd() # TODO(add: CsDoStatement, CsCheckedExpression)

method add*(parent: CsDoStatement; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsDoStatement; item: CsParenthesizedExpression)"
  todoimplAdd() # TODO(add: CsDoStatement, CsParenthesizedExpression)

method add*(parent: CsAnonymousMethodExpression; item: CsUsingStatement) = # US
  echo "in method add*(parent: CsAnonymousMethodExpression; item: CsUsingStatement)"
  parent.body.add item

method add*(parent: CsBinaryExpression; item: CsRefValueExpression) = # RVE
  echo "in method add*(parent: CsBinaryExpression; item: CsRefValueExpression)"
  todoimplAdd() # TODO(add: CsBinaryExpression, CsRefValueExpression)

method add*(parent: CsUsingStatement; item: CsForEachStatement) = # FES
  echo "in method add*(parent: CsUsingStatement; item: CsForEachStatement)"
  parent.body.add item

method add*(parent: CsForStatement; item: CsObjectCreationExpression) = # OCE
  echo "in method add*(parent: CsForStatement; item: CsObjectCreationExpression)"
  todoimplAdd() # TODO(add: CsForStatement, CsObjectCreationExpression)

method add*(parent: CsMakeRefExpression; item: CsMemberAccessExpression) = # MAE
  echo "in method add*(parent: CsMakeRefExpression; item: CsMemberAccessExpression)"
  todoimplAdd() # TODO(add: CsMakeRefExpression, CsMemberAccessExpression)

method add*(parent: CsSwitchExpressionArm; item: CsPostfixUnaryExpression) = # PUE
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsPostfixUnaryExpression)"
  todoimplAdd() # TODO(add: CsSwitchExpressionArm, CsPostfixUnaryExpression)

method add*(parent: CsSwitchExpressionArm; item: CsSimpleLambdaExpression) = # SLE
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsSimpleLambdaExpression)"
  parent.body.add item

method add*(parent: CsAnonymousMethodExpression; item: CsLockStatement) = # LS
  echo "in method add*(parent: CsAnonymousMethodExpression; item: CsLockStatement)"
  parent.body.add item

method add*(parent: CsSwitchStatement; item: CsTupleExpression) = # TE
  echo "in method add*(parent: CsSwitchStatement; item: CsTupleExpression)"
  parent.on = item

method add*(parent: CsFromClause; item: CsConditionalAccessExpression) = # CAE
  echo "in method add*(parent: CsFromClause; item: CsConditionalAccessExpression)"
  todoimplAdd() # TODO(add: CsFromClause, CsConditionalAccessExpression)

method add*(parent: CsAssignmentExpression; item: CsStackAllocArrayCreationExpression) = # SAACE
  echo "in method add*(parent: CsAssignmentExpression; item: CsStackAllocArrayCreationExpression)"
  todoimplAdd() # TODO(add: CsAssignmentExpression, CsStackAllocArrayCreationExpression)

method add*(parent: CsCaseSwitchLabel; item: CsDefaultExpression) = # DE
  echo "in method add*(parent: CsCaseSwitchLabel; item: CsDefaultExpression)"
  parent.other = item

method add*(parent: CsConditionalExpression; item: CsRefValueExpression) = # RVE
  echo "in method add*(parent: CsConditionalExpression; item: CsRefValueExpression)"
  parent.addConditional(item)

method add*(parent: CsThrowExpression; item: CsPostfixUnaryExpression) = # PUE
  echo "in method add*(parent: CsThrowExpression; item: CsPostfixUnaryExpression)"
  todoimplAdd() # TODO(add: CsThrowExpression, CsPostfixUnaryExpression)

method add*(parent: CsSwitchExpressionArm; item: CsCheckedExpression) = # CE
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsCheckedExpression)"
  todoimplAdd() # TODO(add: CsSwitchExpressionArm, CsCheckedExpression)

method add*(parent: CsSwitchExpressionArm; item: CsSwitchExpression) = # SE
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsSwitchExpression)"
  todoimplAdd() # TODO(add: CsSwitchExpressionArm, CsSwitchExpression)

method add*(parent: CsGroupClause; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsGroupClause; item: CsParenthesizedExpression)"
  todoimplAdd() # TODO(add: CsGroupClause, CsParenthesizedExpression)

method add*(parent: CsProperty; item: CsReturnStatement) = # RS
  echo "in method add*(parent: CsProperty; item: CsReturnStatement)"
  todoimplAdd() # TODO(add: CsProperty, CsReturnStatement)

method add*(parent: CsUnaryPattern; item: CsRecursivePattern) = # RP
  echo "in method add*(parent: CsUnaryPattern; item: CsRecursivePattern)"
  todoimplAdd() # TODO(add: CsUnaryPattern, CsRecursivePattern)

method add*(parent: CsBinaryPattern; item: CsRelationalPattern) = # RP
  echo "in method add*(parent: CsBinaryPattern; item: CsRelationalPattern)"
  todoimplAdd() # TODO(add: CsBinaryPattern, CsRelationalPattern)

method add*(parent: CsBinaryPattern; item: CsUnaryPattern) = # UP
  echo "in method add*(parent: CsBinaryPattern; item: CsUnaryPattern)"
  todoimplAdd() # TODO(add: CsBinaryPattern, CsUnaryPattern)

method add*(parent: CsIndexer; item: CsLockStatement) = # LS
  echo "in method add*(parent: CsIndexer; item: CsLockStatement)"
  todoimplAdd() # TODO(add: CsIndexer, CsLockStatement)

method add*(parent: CsParenthesizedLambdaExpression; item: CsThrowStatement) = # TS
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsThrowStatement)"
  parent.body.add item

method add*(parent: CsGlobalStatement; item: CsThrowStatement) = # TS
  echo "in method add*(parent: CsGlobalStatement; item: CsThrowStatement)"
  todoimplAdd() # TODO(add: CsGlobalStatement, CsThrowStatement)

method add*(parent: CsArrowExpressionClause; item: CsAnonymousObjectCreationExpression) = # AOCE
  echo "in method add*(parent: CsArrowExpressionClause; item: CsAnonymousObjectCreationExpression)"
  parent.body.add item

method add*(parent: CsTryStatement; item: CsThrowStatement) = # TS
  echo "in method add*(parent: CsTryStatement; item: CsThrowStatement)"
  parent.body.add item

method add*(parent: CsVariable; item: CsFunctionPointerType) = # FPT
  echo "in method add*(parent: CsVariable; item: CsFunctionPointerType)"
  parent.gotType = item

method add*(parent: CsInitializerExpression; item: CsPredefinedType) = # PT
  echo "in method add*(parent: CsInitializerExpression; item: CsPredefinedType)"
  parent.gotType = item

method add*(parent: CsCastExpression; item: CsFunctionPointerType) = # FPT
  echo "in method add*(parent: CsCastExpression; item: CsFunctionPointerType)"
  parent.gotType = item

method add*(parent: CsLabeledStatement; item: CsForEachStatement) = # FES
  echo "in method add*(parent: CsLabeledStatement; item: CsForEachStatement)"
  parent.body.add item

method add*(parent: CsForEachStatement; item: CsContinueStatement) = # CS
  echo "in method add*(parent: CsForEachStatement; item: CsContinueStatement)"
  todoimplAdd() # TODO(add: CsForEachStatement, CsContinueStatement)

method add*(parent: CsForStatement; item: CsRangeExpression) = # RE
  echo "in method add*(parent: CsForStatement; item: CsRangeExpression)"
  todoimplAdd() # TODO(add: CsForStatement, CsRangeExpression)

method add*(parent: CsForStatement; item: CsImplicitArrayCreationExpression) = # IACE
  echo "in method add*(parent: CsForStatement; item: CsImplicitArrayCreationExpression)"
  todoimplAdd() # TODO(add: CsForStatement, CsImplicitArrayCreationExpression)

method add*(parent: CsProperty; item: CsForStatement) = # FS
  echo "in method add*(parent: CsProperty; item: CsForStatement)"
  todoimplAdd() # TODO(add: CsProperty, CsForStatement)

method add*(parent: CsOperator; item: CsThrowStatement) = # TS
  echo "in method add*(parent: CsOperator; item: CsThrowStatement)"
  parent.body.add item

method add*(parent: CsDestructor; item: CsIfStatement) = # IS
  echo "in method add*(parent: CsDestructor; item: CsIfStatement)"
  parent.body.add item

method add*(parent: CsDestructor; item: CsTryStatement) = # TS
  echo "in method add*(parent: CsDestructor; item: CsTryStatement)"
  parent.body.add item

method add*(parent: CsConversionOperator; item: CsIfStatement) = # IS
  echo "in method add*(parent: CsConversionOperator; item: CsIfStatement)"
  parent.body.add item

method add*(parent: CsProperty; item: CsForEachStatement) = # FES
  echo "in method add*(parent: CsProperty; item: CsForEachStatement)"
  todoimplAdd() # TODO(add: CsProperty, CsForEachStatement)

method add*(parent: CsProperty; item: CsIfStatement) = # IS
  echo "in method add*(parent: CsProperty; item: CsIfStatement)"
  todoimplAdd() # TODO(add: CsProperty, CsIfStatement)

method add*(parent: CsProperty; item: CsThrowStatement) = # TS
  echo "in method add*(parent: CsProperty; item: CsThrowStatement)"
  todoimplAdd() # TODO(add: CsProperty, CsThrowStatement)

method add*(parent: CsProperty; item: CsTryStatement) = # TS
  echo "in method add*(parent: CsProperty; item: CsTryStatement)"
  todoimplAdd() # TODO(add: CsProperty, CsTryStatement)

method add*(parent: CsProperty; item: CsWhileStatement) = # WS
  echo "in method add*(parent: CsProperty; item: CsWhileStatement)"
  todoimplAdd() # TODO(add: CsProperty, CsWhileStatement)

method add*(parent: CsProperty; item: CsDoStatement) = # DS
  echo "in method add*(parent: CsProperty; item: CsDoStatement)"
  todoimplAdd() # TODO(add: CsProperty, CsDoStatement)

method add*(parent: CsOperator; item: CsIfStatement) = # IS
  echo "in method add*(parent: CsOperator; item: CsIfStatement)"
  parent.body.add item

method add*(parent: CsIndexer; item: CsReturnStatement) = # RS
  echo "in method add*(parent: CsIndexer; item: CsReturnStatement)"
  todoimplAdd() # TODO(add: CsIndexer, CsReturnStatement)

method add*(parent: CsParenthesizedLambdaExpression; item: CsForEachStatement) = # FES
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsForEachStatement)"
  parent.body.add item

method add*(parent: CsAnonymousMethodExpression; item: CsIfStatement) = # IS
  echo "in method add*(parent: CsAnonymousMethodExpression; item: CsIfStatement)"
  parent.body.add item

method add*(parent: CsProperty; item: CsCheckedStatement) = # CS
  echo "in method add*(parent: CsProperty; item: CsCheckedStatement)"
  todoimplAdd() # TODO(add: CsProperty, CsCheckedStatement)

method add*(parent: CsProperty; item: CsLockStatement) = # LS
  echo "in method add*(parent: CsProperty; item: CsLockStatement)"
  todoimplAdd() # TODO(add: CsProperty, CsLockStatement)

method add*(parent: CsProperty; item: CsSwitchStatement) = # SS
  echo "in method add*(parent: CsProperty; item: CsSwitchStatement)"
  todoimplAdd() # TODO(add: CsProperty, CsSwitchStatement)

method add*(parent: CsProperty; item: CsUsingStatement) = # US
  echo "in method add*(parent: CsProperty; item: CsUsingStatement)"
  todoimplAdd() # TODO(add: CsProperty, CsUsingStatement)

method add*(parent: CsIndexer; item: CsForEachStatement) = # FES
  echo "in method add*(parent: CsIndexer; item: CsForEachStatement)"
  todoimplAdd() # TODO(add: CsIndexer, CsForEachStatement)

method add*(parent: CsIndexer; item: CsIfStatement) = # IS
  echo "in method add*(parent: CsIndexer; item: CsIfStatement)"
  todoimplAdd() # TODO(add: CsIndexer, CsIfStatement)

method add*(parent: CsIndexer; item: CsLocalDeclarationStatement) = # LDS
  echo "in method add*(parent: CsIndexer; item: CsLocalDeclarationStatement)"
  todoimplAdd() # TODO(add: CsIndexer, CsLocalDeclarationStatement)

method add*(parent: CsIndexer; item: CsSwitchStatement) = # SS
  echo "in method add*(parent: CsIndexer; item: CsSwitchStatement)"
  todoimplAdd() # TODO(add: CsIndexer, CsSwitchStatement)

method add*(parent: CsDestructor; item: CsForStatement) = # FS
  echo "in method add*(parent: CsDestructor; item: CsForStatement)"
  todoimplAdd() # TODO(add: CsDestructor, CsForStatement)

method add*(parent: CsDestructor; item: CsReturnStatement) = # RS
  echo "in method add*(parent: CsDestructor; item: CsReturnStatement)"
  todoimplAdd() # TODO(add: CsDestructor, CsReturnStatement)

method add*(parent: CsIndexer; item: CsThrowStatement) = # TS
  echo "in method add*(parent: CsIndexer; item: CsThrowStatement)"
  todoimplAdd() # TODO(add: CsIndexer, CsThrowStatement)

method add*(parent: CsIndexer; item: CsForStatement) = # FS
  echo "in method add*(parent: CsIndexer; item: CsForStatement)"
  todoimplAdd() # TODO(add: CsIndexer, CsForStatement)

method add*(parent: CsTryStatement; item: CsIfStatement) = # IS
  echo "in method add*(parent: CsTryStatement; item: CsIfStatement)"
  parent.body.add item

method add*(parent: CsParenthesizedLambdaExpression; item: CsForStatement) = # FS
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsForStatement)"
  parent.body.add item

method add*(parent: CsProperty; item: CsLabeledStatement) = # LS
  echo "in method add*(parent: CsProperty; item: CsLabeledStatement)"
  todoimplAdd() # TODO(add: CsProperty, CsLabeledStatement)

method add*(parent: CsDestructor; item: CsUsingStatement) = # US
  echo "in method add*(parent: CsDestructor; item: CsUsingStatement)"
  todoimplAdd() # TODO(add: CsDestructor, CsUsingStatement)

method add*(parent: CsYieldStatement; item: CsAnonymousObjectCreationExpression) = # AOCE
  echo "in method add*(parent: CsYieldStatement; item: CsAnonymousObjectCreationExpression)"
  parent.expr = item

method add*(parent: CsProperty; item: CsGotoStatement) = # GS
  echo "in method add*(parent: CsProperty; item: CsGotoStatement)"
  todoimplAdd() # TODO(add: CsProperty, CsGotoStatement)

method add*(parent: CsInvocationExpression; item: CsThisExpression) = # TE
  echo "in method add*(parent: CsInvocationExpression; item: CsThisExpression)"
  todoimplAdd() # TODO(add: CsInvocationExpression, CsThisExpression)

method add*(parent: CsAnonymousMethodExpression; item: CsTryStatement) = # TS
  echo "in method add*(parent: CsAnonymousMethodExpression; item: CsTryStatement)"
  parent.body.add item

method add*(parent: CsAnonymousMethodExpression; item: CsForEachStatement) = # FES
  echo "in method add*(parent: CsAnonymousMethodExpression; item: CsForEachStatement)"
  parent.body.add item

method add*(parent: CsAnonymousMethodExpression; item: CsThrowStatement) = # TS
  echo "in method add*(parent: CsAnonymousMethodExpression; item: CsThrowStatement)"
  parent.body.add item

method add*(parent: CsGlobalStatement; item: CsSwitchStatement) = # SS
  echo "in method add*(parent: CsGlobalStatement; item: CsSwitchStatement)"
  todoimplAdd() # TODO(add: CsGlobalStatement, CsSwitchStatement)

method add*(parent: CsConversionOperator; item: CsTryStatement) = # TS
  echo "in method add*(parent: CsConversionOperator; item: CsTryStatement)"
  todoimplAdd() # TODO(add: CsConversionOperator, CsTryStatement)

method add*(parent: CsNamespace; item: CsOperator) =
  echo "in method add*(parent: CsNamespace; item: CsOperator)"
  todoimplAdd() # TODO(add: CsNamespace, CsOperator)

method add*(parent: CsConversionOperator; item: CsUnsafeStatement) = # US
  echo "in method add*(parent: CsConversionOperator; item: CsUnsafeStatement)"
  todoimplAdd() # TODO(add: CsConversionOperator, CsUnsafeStatement)

method add*(parent: CsMethod; item: CsFixedStatement) = # FS
  echo "in method add*(parent: CsMethod; item: CsFixedStatement)"
  parent.body.add item


method add*(parent: CsMethod; item: CsUnsafeStatement) = # US
  echo "in method add*(parent: CsMethod; item: CsUnsafeStatement)"
  parent.body.add item

method add*(parent: CsConstructor; item: CsFixedStatement) = # FS
  echo "in method add*(parent: CsConstructor; item: CsFixedStatement)"
  parent.body.add item

method add*(parent: CsConstructor; item: CsUnsafeStatement) = # US
  echo "in method add*(parent: CsConstructor; item: CsUnsafeStatement)"
  parent.body.add item

method add*(parent: CsConstructor; item: CsYieldStatement) = # YS
  echo "in method add*(parent: CsConstructor; item: CsYieldStatement)"
  parent.body.add item

method add*(parent: CsFixedStatement; item: CsExpressionStatement) = # ES
  echo "in method add*(parent: CsFixedStatement; item: CsExpressionStatement)"
  parent.body.add item

method add*(parent: CsProperty; item: CsYieldStatement) = # YS
  echo "in method add*(parent: CsProperty; item: CsYieldStatement)"
  todoimplAdd() # TODO(add: CsProperty, CsYieldStatement)

method add*(parent: CsLocalFunctionStatement; item: CsReturnStatement) = # RS
  echo "in method add*(parent: CsLocalFunctionStatement; item: CsReturnStatement)"
  parent.body.add item

method add*(parent: CsDefaultExpression; item: CsPointerType) = # PT
  echo "in method add*(parent: CsDefaultExpression; item: CsPointerType)"
  parent.gotType = item

method add*(parent: CsMethod; item: CsForEachVariableStatement) = # FEVS
  echo "in method add*(parent: CsMethod; item: CsForEachVariableStatement)"
  parent.body.add item

method add*(parent: CsFixedStatement; item: CsFixedStatement) = # FS
  echo "in method add*(parent: CsFixedStatement; item: CsFixedStatement)"
  parent.body.add item

method add*(parent: CsClass; item: CsLocalDeclarationStatement) = # LDS
  echo "in method add*(parent: CsClass; item: CsLocalDeclarationStatement)"
  todoimplAdd() # TODO(add: CsClass, CsLocalDeclarationStatement)

method add*(parent: CsOperator; item: CsUnsafeStatement) = # US
  echo "in method add*(parent: CsOperator; item: CsUnsafeStatement)"
  todoimplAdd() # TODO(add: CsOperator, CsUnsafeStatement)

method add*(parent: CsLabeledStatement; item: CsYieldStatement) = # YS
  echo "in method add*(parent: CsLabeledStatement; item: CsYieldStatement)"
  parent.body.add item

method add*(parent: CsForEachVariableStatement; item: CsExpressionStatement) = # ES
  echo "in method add*(parent: CsForEachVariableStatement; item: CsExpressionStatement)"
  todoimplAdd() # TODO(add: CsForEachVariableStatement, CsExpressionStatement)

method add*(parent: CsForEachVariableStatement; item: CsTupleExpression) = # TE
  echo "in method add*(parent: CsForEachVariableStatement; item: CsTupleExpression)"
  todoimplAdd() # TODO(add: CsForEachVariableStatement, CsTupleExpression)

method add*(parent: CsLocalDeclarationStatement; item: CsLocalFunctionStatement) = # LFS
  echo "in method add*(parent: CsLocalDeclarationStatement; item: CsLocalFunctionStatement)"
  todoimplAdd() # TODO(add: CsLocalDeclarationStatement, CsLocalFunctionStatement)

method add*(parent: CsDestructor; item: CsForEachStatement) = # FES
  echo "in method add*(parent: CsDestructor; item: CsForEachStatement)"
  todoimplAdd() # TODO(add: CsDestructor, CsForEachStatement)

method add*(parent: CsConversionOperator; item: CsForEachStatement) = # FES
  echo "in method add*(parent: CsConversionOperator; item: CsForEachStatement)"

  todoimplAdd() # TODO(add: CsConversionOperator, CsForEachStatement)

method add*(parent: CsMethod; item: CsLocalFunctionStatement) = # LFS
  echo "in method add*(parent: CsMethod; item: CsLocalFunctionStatement)"
  parent.localFunctions.add item

method add*(parent: CsFixedStatement; item: CsReturnStatement) = # RS
  echo "in method add*(parent: CsFixedStatement; item: CsReturnStatement)"
  parent.body.add item

method add*(parent: CsProperty; item: CsFixedStatement) = # FS
  echo "in method add*(parent: CsProperty; item: CsFixedStatement)"
  todoimplAdd() # TODO(add: CsProperty, CsFixedStatement)

method add*(parent: CsProperty; item: CsUnsafeStatement) = # US
  echo "in method add*(parent: CsProperty; item: CsUnsafeStatement)"
  todoimplAdd() # TODO(add: CsProperty, CsUnsafeStatement)

method add*(parent: CsForEachVariableStatement; item: CsInvocationExpression) = # IE
  echo "in method add*(parent: CsForEachVariableStatement; item: CsInvocationExpression)"
  if parent.listPart.isNil:
    parent.listPart = item
  else:
    parent.body.add item

method add*(parent: CsForEachVariableStatement; item: CsObjectCreationExpression) = # OCE
  echo "in method add*(parent: CsForEachVariableStatement; item: CsObjectCreationExpression)"
  todoimplAdd() # TODO(add: CsForEachVariableStatement, CsObjectCreationExpression)

method add*(parent: CsIndexer; item: CsFixedStatement) = # FS
  echo "in method add*(parent: CsIndexer; item: CsFixedStatement)"
  todoimplAdd() # TODO(add: CsIndexer, CsFixedStatement)

method add*(parent: CsLocalFunctionStatement; item: CsIfStatement) = # IS
  echo "in method add*(parent: CsLocalFunctionStatement; item: CsIfStatement)"
  parent.body.add item

method add*(parent: CsIfStatement; item: CsFixedStatement) = # FS
  echo "in method add*(parent: CsIfStatement; item: CsFixedStatement)"
  parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsIfStatement) = # IS
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsIfStatement)"
  parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsReturnStatement) = # RS
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsReturnStatement)"
  parent.body.add item

method add*(parent: CsLocalFunctionStatement; item: CsForStatement) = # FS
  echo "in method add*(parent: CsLocalFunctionStatement; item: CsForStatement)"
  parent.body.add item

method add*(parent: CsLocalFunctionStatement; item: CsTypeParameterList) = # TPL
  echo "in method add*(parent: CsLocalFunctionStatement; item: CsTypeParameterList)"
  todoimplAdd() # TODO(add: CsLocalFunctionStatement, CsTypeParameterList)

method add*(parent: CsAccessor; item: CsLocalFunctionStatement) = # LFS
  echo "in method add*(parent: CsAccessor; item: CsLocalFunctionStatement)"
  parent.body.add item

method add*(parent: CsConstructor; item: CsForEachVariableStatement) = # FEVS
  echo "in method add*(parent: CsConstructor; item: CsForEachVariableStatement)"
  parent.body.add item

method add*(parent: CsConstructor; item: CsLocalFunctionStatement) = # LFS
  echo "in method add*(parent: CsConstructor; item: CsLocalFunctionStatement)"
  parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsForEachStatement) = # FES
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsForEachStatement)"
  parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsThrowStatement) = # TS
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsThrowStatement)"
  parent.body.add item

method add*(parent: CsLocalFunctionStatement; item: CsTypeParameterConstraintClause) = # TPCC
  echo "in method add*(parent: CsLocalFunctionStatement; item: CsTypeParameterConstraintClause)"
  todoimplAdd() # TODO(add: CsLocalFunctionStatement, CsTypeParameterConstraintClause)

method add*(parent: CsProperty; item: CsForEachVariableStatement) = # FEVS
  echo "in method add*(parent: CsProperty; item: CsForEachVariableStatement)"
  todoimplAdd() # TODO(add: CsProperty, CsForEachVariableStatement)

method add*(parent: CsSimpleLambdaExpression; item: CsUsingStatement) = # US
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsUsingStatement)"
  parent.body.add item

method add*(parent: CsConversionOperator; item: CsForStatement) = # FS
  echo "in method add*(parent: CsConversionOperator; item: CsForStatement)"
  todoimplAdd() # TODO(add: CsConversionOperator, CsForStatement)

method add*(parent: CsIndexer; item: CsWhileStatement) = # WS
  echo "in method add*(parent: CsIndexer; item: CsWhileStatement)"
  todoimplAdd() # TODO(add: CsIndexer, CsWhileStatement)

method add*(parent: CsFixedStatement; item: CsForStatement) = # FS
  echo "in method add*(parent: CsFixedStatement; item: CsForStatement)"
  parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsTryStatement) = # TS
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsTryStatement)"
  parent.body.add item

method add*(parent: CsFixedStatement; item: CsIfStatement) = # IS
  echo "in method add*(parent: CsFixedStatement; item: CsIfStatement)"
  parent.body.add item

method add*(parent: CsForEachVariableStatement; item: CsElementAccessExpression) = # EAE
  echo "in method add*(parent: CsForEachVariableStatement; item: CsElementAccessExpression)"
  todoimplAdd() # TODO(add: CsForEachVariableStatement, CsElementAccessExpression)

method add*(parent: CsReturnStatement; item: CsBaseExpression) = # BE
  echo "in method add*(parent: CsReturnStatement; item: CsBaseExpression)"
  parent.expr = item

method add*(parent: CsParenthesizedLambdaExpression; item: CsCheckedStatement) = # CS
  echo "in method add*(parent: CsParenthesizedLambdaExpression; item: CsCheckedStatement)"
  parent.body.add item

method add*(parent: CsCatchClause; item: CsContinueStatement) = # CS
  echo "in method add*(parent: CsCatchClause; item: CsContinueStatement)"
  parent.body.add item

method add*(parent: CsLocalFunctionStatement; item: CsArrayType) = # AT
  echo "in method add*(parent: CsLocalFunctionStatement; item: CsArrayType)"
  parent.gotType = item

method add*(parent: CsDoStatement; item: CsContinueStatement) = # CS
  echo "in method add*(parent: CsDoStatement; item: CsContinueStatement)"
  todoimplAdd() # TODO(add: CsDoStatement, CsContinueStatement)

method add*(parent: CsWhileStatement; item: CsContinueStatement) = # CS
  echo "in method add*(parent: CsWhileStatement; item: CsContinueStatement)"
  parent.body.add item

method add*(parent: CsThrowStatement; item: CsPostfixUnaryExpression) = # PUE
  echo "in method add*(parent: CsThrowStatement; item: CsPostfixUnaryExpression)"
  parent.body.add item

method add*(parent: CsReturnStatement; item: CsRefValueExpression) = # RVE
  echo "in method add*(parent: CsReturnStatement; item: CsRefValueExpression)"
  parent.expr = item

method add*(parent: CsLocalFunctionStatement; item: CsNullableType) = # NT
  echo "in method add*(parent: CsLocalFunctionStatement; item: CsNullableType)"
  parent.gotType = item

method add*(parent: CsLocalFunctionStatement; item: CsRefType) = # RT
  echo "in method add*(parent: CsLocalFunctionStatement; item: CsRefType)"
  parent.gotType = item

method add*(parent: CsSelectClause; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsSelectClause; item: CsParenthesizedExpression)"
  todoimplAdd() # TODO(add: CsSelectClause, CsParenthesizedExpression)

method add*(parent: CsUnaryPattern; item: CsParenthesizedPattern) = # PP
  echo "in method add*(parent: CsUnaryPattern; item: CsParenthesizedPattern)"
  todoimplAdd() # TODO(add: CsUnaryPattern, CsParenthesizedPattern)

method add*(parent: CsRelationalPattern; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsRelationalPattern; item: CsParenthesizedExpression)"
  todoimplAdd() # TODO(add: CsRelationalPattern, CsParenthesizedExpression)

method add*(parent: CsSwitchExpression; item: CsCheckedExpression) = # CE
  echo "in method add*(parent: CsSwitchExpression; item: CsCheckedExpression)"
  todoimplAdd() # TODO(add: CsSwitchExpression, CsCheckedExpression)

method add*(parent: CsSwitchSection; item: CsLocalFunctionStatement) = # LFS
  echo "in method add*(parent: CsSwitchSection; item: CsLocalFunctionStatement)"
  parent.body.add item

method add*(parent: CsFromClause; item: CsArrayType) = # AT
  echo "in method add*(parent: CsFromClause; item: CsArrayType)"
  parent.gotType = item

method add*(parent: CsVarPattern; item: CsDiscardDesignation) = # DD
  echo "in method add*(parent: CsVarPattern; item: CsDiscardDesignation)"
  todoimplAdd() # TODO(add: CsVarPattern, CsDiscardDesignation)

method add*(parent: CsArrayRankSpecifier; item: CsObjectCreationExpression) = # OCE
  echo "in method add*(parent: CsArrayRankSpecifier; item: CsObjectCreationExpression)"
  todoimplAdd() # TODO(add: CsArrayRankSpecifier, CsObjectCreationExpression)

method add*(parent: CsJoinClause; item: CsParenthesizedExpression) = # PE
  echo "in method add*(parent: CsJoinClause; item: CsParenthesizedExpression)"
  todoimplAdd() # TODO(add: CsJoinClause, CsParenthesizedExpression)

method add*(parent: CsParenthesizedPattern; item: CsBinaryPattern) = # BP
  echo "in method add*(parent: CsParenthesizedPattern; item: CsBinaryPattern)"
  todoimplAdd() # TODO(add: CsParenthesizedPattern, CsBinaryPattern)

method add*(parent: CsLockStatement; item: CsPostfixUnaryExpression) = # PUE
  echo "in method add*(parent: CsLockStatement; item: CsPostfixUnaryExpression)"
  if parent.locker.isNil:
    parent.locker = item
  else: parent.body.add item

method add*(parent: CsSimpleLambdaExpression; item: CsForStatement) = # FS
  echo "in method add*(parent: CsSimpleLambdaExpression; item: CsForStatement)"
  parent.body.add item

method add*(parent: CsSwitchExpressionArm; item: CsConditionalAccessExpression) = # CAE
  echo "in method add*(parent: CsSwitchExpressionArm; item: CsConditionalAccessExpression)"
  todoimplAdd() # TODO(add: CsSwitchExpressionArm, CsConditionalAccessExpression)

method add*(parent: CsForEachVariableStatement; item: CsLiteralExpression) = # LE
  echo "in method add*(parent: CsForEachVariableStatement; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsForEachVariableStatement, CsLiteralExpression)

method add*(parent: CsForEachVariableStatement; item: CsIfStatement) =
  echo "in method add*(parent: CsForEachVariableStatement; item: CsIfStatement)"
  todoimplAdd() # TODO(add: CsForEachVariableStatement, CsIfStatement)

method add*(parent: var CsAccessor; item: CsUnsafeStatement) =
  echo "in method add*(parent: var CsAccessor; item: CsUnsafeStatement)"
  parent.body.add item

method add*(parent: var CsAccessor; item: CsFixedStatement) =
  echo "in method add*(parent: var CsAccessor; item: CsFixedStatement)"
  todoimplAdd() # TODO(add: CsAccessor, CsFixedStatement)

method add*(parent: var CsIndexer; item: CsYieldStatement) =
  echo "in method add*(parent: var CsIndexer; item: CsYieldStatement)"
  todoimplAdd() # TODO(add: CsIndexer, CsYieldStatement)

method add*(parent: var CsRefExpression; item: CsDefaultExpression) =
  echo "in method add*(parent: var CsRefExpression; item: CsDefaultExpression)"
  todoimplAdd() # TODO(add: CsRefExpression, CsDefaultExpression)

method add*(parent: var CsCheckedExpression; item: CsAwaitExpression) =
  echo "in method add*(parent: var CsCheckedExpression; item: CsAwaitExpression)"
  todoimplAdd() # TODO(add: CsCheckedExpression, CsAwaitExpression)

method add*(parent: var CsRefExpression; item: CsParenthesizedExpression) =
  echo "in method add*(parent: var CsRefExpression; item: CsParenthesizedExpression)"
  todoimplAdd() # TODO(add: CsRefExpression, CsParenthesizedExpression)

method add*(parent: var CsOperator; item: CsYieldStatement) =
  echo "in method add*(parent: var CsOperator; item: CsYieldStatement)"
  todoimplAdd() # TODO(add: CsOperator, CsYieldStatement)

method add*(parent: var CsExpressionStatement, item:CsAnonymousMethodExpression) =
  echo "in method add*(parent: var CsExpressionStatement, item:CsAnonymousMethodExpression)"
  todoimplAdd() # TODO(add:CsExpressionStatement, CsAnonymousMethodExpression)
method add*(parent: var CsOperator; item: CsForEachStatement) =
  echo "in method add*(parent: var CsOperator; item: CsForEachStatement)"
  todoimplAdd() # TODO(add: CsOperator, CsForEachStatement)

method add*(parent: var CsAnonymousMethodExpression; item: CsExpressionStatement) =
  echo "in method add*(parent: var CsAnonymousMethodExpression; item: CsExpressionStatement)"
  parent.body.add item

method add*(parent: var CsAccessor; item: CsExpressionStatement) =
  echo "in method add*(parent: var CsAccessor; item: CsExpressionStatement)"
  parent.body.add item

method add*(parent: var CsTryStatement; item: CsExpressionStatement) =
  echo "in method add*(parent: var CsTryStatement; item: CsExpressionStatement)"
  parent.body.add item

method add*(parent: var CsDestructor; item: CsExpressionStatement) =
  echo "in method add*(parent: var CsDestructor; item: CsExpressionStatement)"
  parent.body.add item

method add*(parent: var CsParenthesizedLambdaExpression; item: CsExpressionStatement) =
  echo "in method add*(parent: var CsParenthesizedLambdaExpression; item: CsExpressionStatement)"
  parent.body.add item

method add*(parent: var CsParenthesizedLambdaExpression; item: CsSizeOfExpression) =
  echo "in method add*(parent: var CsParenthesizedLambdaExpression; item: CsSizeOfExpression)"
  parent.body.add item

method add*(parent: var CsSimpleLambdaExpression; item: CsExpressionStatement) =
  echo "in method add*(parent: var CsSimpleLambdaExpression; item: CsExpressionStatement)"
  parent.body.add item

method add*(parent: var CsAliasQualifiedName; item: CsLiteralExpression) =
  echo "in method add*(parent: var CsAliasQualifiedName; item: CsLiteralExpression)"
  todoimplAdd() # TODO(add: CsAliasQualifiedName, CsLiteralExpression)

method add*(parent: var CsLocalFunctionStatement; item: CsExpressionStatement) =
  echo "in method add*(parent: var CsLocalFunctionStatement; item: CsExpressionStatement)"
  parent.body.add item

method add*(parent: var CsLocalFunctionStatement; item: CsLocalDeclarationStatement) =
  echo "in method add*(parent: var CsLocalFunctionStatement; item: CsLocalDeclarationStatement)"
  parent.locals.add item

method add*(parent: var CsOperator; item: CsExpressionStatement) =
  echo "in method add*(parent: var CsOperator; item: CsExpressionStatement)"
  parent.body.add item

method add*(parent: var CsForStatement; item: CsFixedStatement) =
  echo "in method add*(parent: var CsForStatement; item: CsFixedStatement)"
  todoimplAdd() # TODO(add: CsForStatement, CsFixedStatement)

method add*(parent: var CsIfStatement; item: CsUnsafeStatement) =
  echo "in method add*(parent: var CsIfStatement; item: CsUnsafeStatement)"
  todoimplAdd() # TODO(add: CsIfStatement, CsUnsafeStatement)

method add*(parent: var CsSimpleLambdaExpression; item: CsLockStatement) =
  echo "in method add*(parent: var CsSimpleLambdaExpression; item: CsLockStatement)"
  todoimplAdd() # TODO(add: CsSimpleLambdaExpression, CsLockStatement)

method add*(parent: var CsFixedStatement; item: CsUsingStatement) =
  echo "in method add*(parent: var CsFixedStatement; item: CsUsingStatement)"
  todoimplAdd() # TODO(add: CsFixedStatement, CsUsingStatement)

method add*(parent: var CsPointerType; item: CsTupleType) =
  echo "in method add*(parent: var CsPointerType; item: CsTupleType)"
  todoimplAdd() # TODO(add: CsPointerType, CsTupleType)

method add*(parent: var CsJoinClause; item: CsArrayCreationExpression) =
  echo "in method add*(parent: var CsJoinClause; item: CsArrayCreationExpression)"
  todoimplAdd() # TODO(add: CsJoinClause, CsArrayCreationExpression)

method add*(parent: var CsGotoStatement; item: CsCastExpression) =
  echo "in method add*(parent: var CsGotoStatement; item: CsCastExpression)"
  todoimplAdd() # TODO(add: CsGotoStatement, CsCastExpression)

method add*(parent: var CsLetClause; item: CsArrayCreationExpression) =
  echo "in method add*(parent: var CsLetClause; item: CsArrayCreationExpression)"
  todoimplAdd() # TODO(add: CsLetClause, CsArrayCreationExpression)

method add*(parent: var CsLetClause; item: CsConditionalAccessExpression) =
  echo "in method add*(parent: var CsLetClause; item: CsConditionalAccessExpression)"
  todoimplAdd() # TODO(add: CsLetClause, CsConditionalAccessExpression)

method add*(parent: var CsParenthesizedLambdaExpression; item: CsForEachVariableStatement) =
  echo "in method add*(parent: var CsParenthesizedLambdaExpression; item: CsForEachVariableStatement)"
  parent.body.add item

method add*(parent: var CsSwitchExpressionArm; item: CsTupleExpression) =
  echo "in method add*(parent: var CsSwitchExpressionArm; item: CsTupleExpression)"
  todoimplAdd() # TODO(add: CsSwitchExpressionArm, CsTupleExpression)

method add*(parent: var CsDoStatement; item: CsConditionalExpression) =
  echo "in method add*(parent: var CsDoStatement; item: CsConditionalExpression)"
  todoimplAdd() # TODO(add: CsDoStatement, CsConditionalExpression)

method add*(parent: var CsGroupClause; item: CsCastExpression) =
  echo "in method add*(parent: var CsGroupClause; item: CsCastExpression)"
  todoimplAdd() # TODO(add: CsGroupClause, CsCastExpression)

method add*(parent: var CsLockStatement; item: CsForEachStatement) =
  echo "in method add*(parent: var CsLockStatement; item: CsForEachStatement)"
  parent.body.add item

method add*(parent: var CsForEachVariableStatement; item: CsBinaryExpression) =
  echo "in method add*(parent: var CsForEachVariableStatement; item: CsBinaryExpression)"
  todoimplAdd() # TODO(add: CsForEachVariableStatement, CsBinaryExpression)

method add*(parent: var CsFromClause; item: CsConditionalExpression) =
  echo "in method add*(parent: var CsFromClause; item: CsConditionalExpression)"
  todoimplAdd() # TODO(add: CsFromClause, CsConditionalExpression)

method add*(parent: var CsFromClause; item: CsElementAccessExpression) =
  echo "in method add*(parent: var CsFromClause; item: CsElementAccessExpression)"
  todoimplAdd() # TODO(add: CsFromClause, CsElementAccessExpression)

method add*(parent: var CsLocalFunctionStatement; item: CsUsingStatement) =
  echo "in method add*(parent: var CsLocalFunctionStatement; item: CsUsingStatement)"
  todoimplAdd() # TODO(add: CsLocalFunctionStatement, CsUsingStatement)

method add*(parent: var CsLocalFunctionStatement; item: CsYieldStatement) =
  echo "in method add*(parent: var CsLocalFunctionStatement; item: CsYieldStatement)"
  todoimplAdd() # TODO(add: CsLocalFunctionStatement, CsYieldStatement)

method add*(parent: var CsAccessor; item: CsLabeledStatement) =
  echo "in method add*(parent: var CsAccessor; item: CsLabeledStatement)"
  todoimplAdd() # TODO(add: CsAccessor, CsLabeledStatement)

method add*(parent: var CsSelectClause; item: CsImplicitArrayCreationExpression) =
  echo "in method add*(parent: var CsSelectClause; item: CsImplicitArrayCreationExpression)"
  todoimplAdd() # TODO(add: CsSelectClause, CsImplicitArrayCreationExpression)

method add*(parent: var CsTryStatement; item: CsFixedStatement) =
  echo "in method add*(parent: var CsTryStatement; item: CsFixedStatement)"
  parent.body.add item

method add*(parent: var CsEvent; item: CsTupleType) =
  echo "in method add*(parent: var CsEvent; item: CsTupleType)"
  todoimplAdd() # TODO(add: CsEvent, CsTupleType)

method add*(parent: var CsNamespace; item: CsConversionOperator) =
  echo "in method add*(parent: var CsNamespace; item: CsConversionOperator)"
  todoimplAdd() # TODO(add: CsNamespace, CsConversionOperator)

method add*(parent: var CsNamespace; item: CsEvent) =
  echo "in method add*(parent: var CsNamespace; item: CsEvent)"
  todoimplAdd() # TODO(add: CsNamespace, CsEvent)

method add*(parent: var CsConstructor; item: CsInvocationExpression) =
  echo "in method add*(parent: var CsConstructor; item: CsInvocationExpression)"
  todoimplAdd() # TODO(add: CsConstructor, CsInvocationExpression)

method add*(parent: var CsOrdering; item: CsParenthesizedExpression) =
  echo "in method add*(parent: var CsOrdering; item: CsParenthesizedExpression)"
  todoimplAdd() # TODO(add: CsOrdering, CsParenthesizedExpression)

method add*(parent: var CsConversionOperator; item: CsExpressionStatement) =
  echo "in method add*(parent: var CsConversionOperator; item: CsExpressionStatement)"
  parent.body.add item

method add*(parent: var CsSwitchSection; item: CsFixedStatement) =
  echo "in method add*(parent: var CsSwitchSection; item: CsFixedStatement)"
  todoImplAdd() # TODO(add: CsSwitchSection, CsFixedStatement)

method add*(parent: var CsLocalFunctionStatement; item: CsWhileStatement) =
  echo "in method add*(parent: var CsLocalFunctionStatement; item: CsWhileStatement)"
  todoImplAdd() # TODO(add: CsLocalFunctionStatement, CsWhileStatement)

method add*(parent: var CsIfStatement; item: CsForEachVariableStatement) =
  echo "in method add*(parent: var CsIfStatement; item: CsForEachVariableStatement)"
  parent.body.add item

method add*(parent: var CsForStatement; item: CsForEachVariableStatement) =
  echo "in method add*(parent: var CsForStatement; item: CsForEachVariableStatement)"
  parent.body.add item

method add*(parent: var CsElseClause; item: CsFixedStatement) =
  echo "in method add*(parent: var CsElseClause; item: CsFixedStatement)"
  todoImplAdd() # TODO(add: CsElseClause, CsFixedStatement)

method add*(parent: var CsElseClause; item: CsUnsafeStatement) =
  echo "in method add*(parent: var CsElseClause; item: CsUnsafeStatement)"
  todoImplAdd() # TODO(add: CsElseClause, CsUnsafeStatement)

method add*(parent: var CsSimpleLambdaExpression; item: CsSwitchStatement) =
  echo "in method add*(parent: var CsSimpleLambdaExpression; item: CsSwitchStatement)"
  todoImplAdd() # TODO(add: CsSimpleLambdaExpression, CsSwitchStatement)

method add*(parent: var CsSimpleLambdaExpression; item: CsWhileStatement) =
  echo "in method add*(parent: var CsSimpleLambdaExpression; item: CsWhileStatement)"
  todoImplAdd() # TODO(add: CsSimpleLambdaExpression, CsWhileStatement)

method add*(parent: var CsCheckedExpression; item: CsCheckedExpression) =
  echo "in method add*(parent: var CsCheckedExpression; item: CsCheckedExpression)"
  todoImplAdd() # TODO(add: CsCheckedExpression, CsCheckedExpression)

method add*(parent: var CsEqualsValueClause; item: CsRangeExpression) =
  echo "in method add*(parent: var CsEqualsValueClause; item: CsRangeExpression)"
  todoImplAdd() # TODO(add: CsEqualsValueClause, CsRangeExpression)

method add*(parent: var CsParenthesizedLambdaExpression; item: CsFixedStatement) =
  echo "in method add*(parent: var CsParenthesizedLambdaExpression; item: CsFixedStatement)"
  todoImplAdd() # TODO(add: CsParenthesizedLambdaExpression, CsFixedStatement)

method add*(parent: var CsFinallyClause; item: CsExpressionStatement) =
  echo "in method add*(parent: var CsFinallyClause; item: CsExpressionStatement)"
  parent.body.add item

method add*(parent: var CsFinallyClause; item: CsIfStatement) =
  echo "in method add*(parent: var CsFinallyClause; item: CsIfStatement)"
  parent.body.add item

method add*(parent: var CsLabeledStatement; item: CsDoStatement) =
  echo "in method add*(parent: var CsLabeledStatement; item: CsDoStatement)"
  todoImplAdd() # TODO(add: CsLabeledStatement, CsDoStatement)

method add*(parent: var CsExpressionStatement; item: CsSimpleLambdaExpression) =
  echo "in method add*(parent: var CsExpressionStatement; item: CsSimpleLambdaExpression)"
  todoImplAdd() # TODO(add: CsExpressionStatement, CsSimpleLambdaExpression)

method add*(parent: var CsSwitchSection; item: CsUnsafeStatement) =
  echo "in method add*(parent: var CsSwitchSection; item: CsUnsafeStatement)"
  todoImplAdd() # TODO(add: CsSwitchSection, CsUnsafeStatement)

method add*(parent: var CsOperator; item: CsArrayType) =
  echo "in method add*(parent: var CsOperator; item: CsArrayType)"
  parent.gotType = item

method add*(parent: var CsAssignmentExpression; item: CsRangeExpression) =
  echo "in method add*(parent: var CsAssignmentExpression; item: CsRangeExpression)"
  todoImplAdd() # TODO(add: CsAssignmentExpression, CsRangeExpression)

method add*(parent: var CsTryStatement; item: CsForEachStatement) =
  echo "in method add*(parent: var CsTryStatement; item: CsForEachStatement)"
  parent.body.add item

method add*(parent: var CsTryStatement; item: CsForStatement) =
  echo "in method add*(parent: var CsTryStatement; item: CsForStatement)"
  parent.body.add item

method add*(parent: var CsTryStatement; item: CsUnsafeStatement) =
  echo "in method add*(parent: var CsTryStatement; item: CsUnsafeStatement)"
  parent.body.add item

method add*(parent: var CsSimpleLambdaExpression; item: CsForEachVariableStatement) =
  echo "in method add*(parent: var CsSimpleLambdaExpression; item: CsForEachVariableStatement)"
  todoImplAdd() # TODO(add: CsSimpleLambdaExpression, CsForEachVariableStatement)

method add*(parent: var CsForEachStatement; item: CsUnsafeStatement) =
  echo "in method add*(parent: var CsForEachStatement; item: CsUnsafeStatement)"
  parent.body.add item

method add*(parent: var CsArrayRankSpecifier; item: CsParenthesizedLambdaExpression) =
  echo "in method add*(parent: var CsArrayRankSpecifier; item: CsParenthesizedLambdaExpression)"
  todoimplAdd() # TODO(add: CsArrayRankSpecifier, CsParenthesizedLambdaExpression)

method add*(parent: var CsInitializerExpression; item: CsRangeExpression) =
  echo "in method add*(parent: var CsInitializerExpression; item: CsRangeExpression)"
  todoimplAdd() # TODO(add: CsInitializerExpression, CsRangeExpression)

method add*(parent: var CsSwitchStatement; item: CsCheckedExpression) =
  echo "in method add*(parent: var CsSwitchStatement; item: CsCheckedExpression)"
  todoimplAdd() # TODO(add: CsSwitchStatement, CsCheckedExpression)

method add*(parent: var CsForEachVariableStatement; item: CsThisExpression) =
  echo "in method add*(parent: var CsForEachVariableStatement; item: CsThisExpression)"
  todoimplAdd() # TODO(add: CsForEachVariableStatement, CsThisExpression)

method add*(parent: var CsLocalFunctionStatement; item: CsFixedStatement) =
  echo "in method add*(parent: var CsLocalFunctionStatement; item: CsFixedStatement)"
  todoimplAdd() # TODO(add: CsLocalFunctionStatement, CsFixedStatement)

method add*(parent: var CsLocalFunctionStatement; item: CsSwitchStatement) =
  echo "in method add*(parent: var CsLocalFunctionStatement; item: CsSwitchStatement)"
  todoimplAdd() # TODO(add: CsLocalFunctionStatement, CsSwitchStatement)

method add*(parent: var CsPostfixUnaryExpression; item: CsObjectCreationExpression) =
  echo "in method add*(parent: var CsPostfixUnaryExpression; item: CsObjectCreationExpression)"
  todoimplAdd() # TODO(add: CsPostfixUnaryExpression, CsObjectCreationExpression)

method add*(parent: var CsLiteralExpression; item: CsGenericName) =
  echo "in method add*(parent: var CsLiteralExpression; item: CsGenericName)"
  todoimplAdd() # TODO(add: CsLiteralExpression, CsGenericName)

method add*(parent: var CsTryStatement; item: CsYieldStatement) =
  echo "in method add*(parent: var CsTryStatement; item: CsYieldStatement)"
  parent.body.add item

method add*(parent: var CsForStatement; item: CsTupleExpression) =
  echo "in method add*(parent: var CsForStatement; item: CsTupleExpression)"
  todoimplAdd() # TODO(add: CsForStatement, CsTupleExpression)

method add*(parent: var CsElseClause; item: CsForEachVariableStatement) =
  echo "in method add*(parent: var CsElseClause; item: CsForEachVariableStatement)"
  parent.body.add item

method add*(parent: var CsForEachStatement; item: CsFixedStatement) =
  echo "in method add*(parent: var CsForEachStatement; item: CsFixedStatement)"
  parent.body.add item

method add*(parent: var CsForEachStatement; item: CsLabeledStatement) =
  echo "in method add*(parent: var CsForEachStatement; item: CsLabeledStatement)"
  parent.body.add item

method add*(parent: var CsAnonymousMethodExpression; item: CsFixedStatement) =
  echo "in method add*(parent: var CsAnonymousMethodExpression; item: CsFixedStatement)"
  parent.body.add item

method add*(parent: var CsForEachStatement; item: CsForEachVariableStatement) =
  echo "in method add*(parent: var CsForEachStatement; item: CsForEachVariableStatement)"
  parent.body.add item

method add*(parent: var CsIsPatternExpression; item: CsObjectCreationExpression) =
  echo "in method add*(parent: var CsIsPatternExpression; item: CsObjectCreationExpression)"
  todoimplAdd() # TODO(add: CsIsPatternExpression, CsObjectCreationExpression)

method add*(parent: var CsParenthesizedLambdaExpression; item: CsSwitchExpression) =
  echo "in method add*(parent: var CsParenthesizedLambdaExpression; item: CsSwitchExpression)"
  todoimplAdd() # TODO(add: CsParenthesizedLambdaExpression, CsSwitchExpression)

method add*(parent: var CsParenthesizedLambdaExpression; item: CsUnsafeStatement) =
  echo "in method add*(parent: var CsParenthesizedLambdaExpression; item: CsUnsafeStatement)"
  todoimplAdd() # TODO(add: CsParenthesizedLambdaExpression, CsUnsafeStatement)

method add*(parent: var CsFinallyClause; item: CsDoStatement) =
  echo "in method add*(parent: var CsFinallyClause; item: CsDoStatement)"
  parent.body.add item

method add*(parent: var CsFinallyClause; item: CsForEachStatement) =
  echo "in method add*(parent: var CsFinallyClause; item: CsForEachStatement)"
  parent.body.add item

method add*(parent: var CsFinallyClause; item: CsForStatement) =
  echo "in method add*(parent: var CsFinallyClause; item: CsForStatement)"
  parent.body.add item

method add*(parent: var CsFinallyClause; item: CsSwitchStatement) =
  echo "in method add*(parent: var CsFinallyClause; item: CsSwitchStatement)"
  parent.body.add item

method add*(parent: var CsFinallyClause; item: CsThrowStatement) =
  echo "in method add*(parent: var CsFinallyClause; item: CsThrowStatement)"
  parent.body.add item

method add*(parent: var CsFinallyClause; item: CsTryStatement) =
  echo "in method add*(parent: var CsFinallyClause; item: CsTryStatement)"
  todoimplAdd() # TODO(add: CsFinallyClause, CsTryStatement)

method add*(parent: var CsFinallyClause; item: CsUsingStatement) =
  echo "in method add*(parent: var CsFinallyClause; item: CsUsingStatement)"
  todoimplAdd() # TODO(add: CsFinallyClause, CsUsingStatement)

method add*(parent: var CsFinallyClause; item: CsWhileStatement) =
  echo "in method add*(parent: var CsFinallyClause; item: CsWhileStatement)"
  parent.body.add item

method add*(parent: var CsSwitchExpression; item: CsCastExpression) =
  echo "in method add*(parent: var CsSwitchExpression; item: CsCastExpression)"
  todoimplAdd() # TODO(add: CsSwitchExpression, CsCastExpression)

method add*(parent: var CsAnonymousMethodExpression; item: CsForStatement) =
  echo "in method add*(parent: var CsAnonymousMethodExpression; item: CsForStatement)"
  todoimplAdd() # TODO(add: CsAnonymousMethodExpression, CsForStatement)

method add*(parent: var CsLockStatement; item: CsTryStatement) =
  echo "in method add*(parent: var CsLockStatement; item: CsTryStatement)"
  parent.body.add item

method add*(parent: var CsLockStatement; item: CsYieldStatement) =
  echo "in method add*(parent: var CsLockStatement; item: CsYieldStatement)"
  parent.body.add item

method add*(parent: var CsSwitchStatement; item: CsConditionalExpression) =
  echo "in method add*(parent: var CsSwitchStatement; item: CsConditionalExpression)"
  todoimplAdd() # TODO(add: CsSwitchStatement, CsConditionalExpression)

method add*(parent: var CsForEachVariableStatement; item: CsYieldStatement) =
  echo "in method add*(parent: var CsForEachVariableStatement; item: CsYieldStatement)"
  todoimplAdd() # TODO(add: CsForEachVariableStatement, CsYieldStatement)

method add*(parent: var CsFromClause; item: CsBinaryExpression) =
  echo "in method add*(parent: var CsFromClause; item: CsBinaryExpression)"
  todoimplAdd() # TODO(add: CsFromClause, CsBinaryExpression)

method add*(parent: var CsLocalFunctionStatement; item: CsDoStatement) =
  echo "in method add*(parent: var CsLocalFunctionStatement; item: CsDoStatement)"
  todoimplAdd() # TODO(add: CsLocalFunctionStatement, CsDoStatement)

method add*(parent: var CsLocalFunctionStatement; item: CsForEachStatement) =
  echo "in method add*(parent: var CsLocalFunctionStatement; item: CsForEachStatement)"
  todoimplAdd() # TODO(add: CsLocalFunctionStatement, CsForEachStatement)

method add*(parent: var CsLocalFunctionStatement; item: CsLockStatement) =
  echo "in method add*(parent: var CsLocalFunctionStatement; item: CsLockStatement)"
  todoimplAdd() # TODO(add: CsLocalFunctionStatement, CsLockStatement)

method add*(parent: var CsLocalFunctionStatement; item: CsThrowStatement) =
  echo "in method add*(parent: var CsLocalFunctionStatement; item: CsThrowStatement)"
  todoimplAdd() # TODO(add: CsLocalFunctionStatement, CsThrowStatement)

method add*(parent: var CsTryStatement; item: CsForEachVariableStatement) =
  echo "in method add*(parent: var CsTryStatement; item: CsForEachVariableStatement)"
  parent.body.add item

method add*(parent: var CsUsingStatement; item: CsDefaultExpression) =
  echo "in method add*(parent: var CsUsingStatement; item: CsDefaultExpression)"
  todoimplAdd() # TODO(add: CsUsingStatement, CsDefaultExpression)

method add*(parent: var CsForEachStatement; item: CsGotoStatement) =
  echo "in method add*(parent: var CsForEachStatement; item: CsGotoStatement)"
  parent.body.add item

method add*(parent: var CsFinallyClause; item: CsLabeledStatement) =
  echo "in method add*(parent: var CsFinallyClause; item: CsLabeledStatement)"
  todoimplAdd() # TODO(add: CsFinallyClause, CsLabeledStatement)

method add*(parent: var CsFinallyClause; item: CsLockStatement) =
  echo "in method add*(parent: var CsFinallyClause; item: CsLockStatement)"
  parent.body.add item

method add*(parent: var CsLockStatement; item: CsForStatement) =
  echo "in method add*(parent: var CsLockStatement; item: CsForStatement)"
  parent.body.add item

method add*(parent: var CsLockStatement; item: CsWhileStatement) =
  echo "in method add*(parent: var CsLockStatement; item: CsWhileStatement)"
  parent.body.add item

method add*(parent: var CsLockStatement; item: CsUsingStatement) =
  echo "in method add*(parent: var CsLockStatement; item: CsUsingStatement)"
  parent.body.add item

method add*(parent: var CsForEachStatement; item: CsBreakStatement) =
  echo "in method add*(parent: var CsForEachStatement; item: CsBreakStatement)"
  parent.body.add item

method add*(parent: var CsLockStatement; item: CsCheckedStatement) =
  echo "in method add*(parent: var CsLockStatement; item: CsCheckedStatement)"
  parent.body.add item

method add*(parent: var CsLockStatement; item: CsDoStatement) =
  echo "in method add*(parent: var CsLockStatement; item: CsDoStatement)"
  parent.body.add item

method add*(parent: var CsLockStatement; item: CsFixedStatement) =
  echo "in method add*(parent: var CsLockStatement; item: CsFixedStatement)"
  parent.body.add item

method add*(parent: var CsLockStatement; item: CsForEachVariableStatement) =
  echo "in method add*(parent: var CsLockStatement; item: CsForEachVariableStatement)"
  parent.body.add item

method add*(parent: var CsLockStatement; item: CsSwitchStatement) =
  echo "in method add*(parent: var CsLockStatement; item: CsSwitchStatement)"
  parent.body.add item

method add*(parent: var CsConversionOperator; item: CsLockStatement) =
  echo "in method add*(parent: var CsConversionOperator; item: CsLockStatement)"
  parent.body.add item

method add*(parent: var CsLockStatement; item: CsThrowStatement) =
  echo "in method add*(parent: var CsLockStatement; item: CsThrowStatement)"
  parent.body.add item

method add*(parent: var CsForStatement; item: CsBreakStatement) =
  echo "in method add*(parent: var CsForStatement; item: CsBreakStatement)"
  parent.body.add item

method add*(parent: var CsLockStatement; item: CsLabeledStatement) =
  echo "in method add*(parent: var CsLockStatement; item: CsLabeledStatement)"
  parent.body.add item

method add*(parent: var CsOperator; item: CsSwitchStatement) =
  echo "in method add*(parent: var CsOperator; item: CsSwitchStatement)"
  parent.body.add item

method add*(parent: var CsDestructor; item: CsWhileStatement) =
  echo "in method add*(parent: var CsDestructor; item: CsWhileStatement)"
  parent.body.add item

method add*(parent: var CsAccessor; item: CsForEachVariableStatement) =
  echo "in method add*(parent: var CsAccessor; item: CsForEachVariableStatement)"
  parent.body.add item

method add*(parent: var CsWhileStatement; item: CsSwitchStatement) =
  echo "in method add*(parent: var CsWhileStatement; item: CsSwitchStatement)"
  parent.body.add item

method add*(parent: var CsAnonymousObjectMemberDeclarator; item: CsAwaitExpression) =
  echo "in method add*(parent: var CsAnonymousObjectMemberDeclarator; item: CsAwaitExpression)"
  todoimplAdd() # TODO(add: CsAnonymousObjectMemberDeclarator, CsAwaitExpression)
method add*(parent: var CsLabeledStatement; item: CsUsingStatement) =
  echo "in method add*(parent: var CsLabeledStatement; item: CsUsingStatement)"
  todoimplAdd() # TODO(add: CsLabeledStatement, CsUsingStatement)

method add*(parent: var CsLocalFunctionStatement; item: CsTryStatement) =
  echo "in method add*(parent: var CsLocalFunctionStatement; item: CsTryStatement)"
  todoimplAdd() # TODO(add: CsLocalFunctionStatement, CsTryStatement)
