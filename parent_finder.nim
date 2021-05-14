<<<<<<< HEAD
import options, sequtils, sets, uuids, sugar, tables, cfits
import common_utils, state, all_needed_data, block_utils, state_utils
import types, constructs/[cs_all_constructs, justtypes]
# import constructs/cs_root

type FindParentResult = object
  discarded*:bool
  parentId*:Option[UUID]

proc handleLiteralExpression(data: AllNeededData, childId:UUID): Option[UUID] =
  echo "obj is LiteralExpression"
  let last = state.getLastType((c) => c.name notin ["IdentifierName", "LiteralExpression"], childId)
=======
import options, sequtils, sets, uuids, sugar, tables
import common_utils, state, all_needed_data, block_utils, info_center, state_utils
import types, construct, constructs/[cs_all_constructs, justtypes]
import constructs/cs_root

proc handleLiteralExpression(data: AllNeededData): Option[UUID] =
  echo "obj is LiteralExpression"
  let last = state.getLastType((c) => c.name notin ["IdentifierName", "PrefixUnaryExpression", "LiteralExpression"])
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
  result = last.get.id.some

proc parentHint(parentRawKind: int): Option[string] =
  let key = parentRawKind
  if parentTable.hasKey(key):
    result = some(parentTable[key])
    echo "found: " & result.get
  else:
    result = none(string)

proc parentHint(c: Construct): Option[string] =
  result = parentHint(c.parentRawKind)
# inconsistent results, maybe overwritten in hashtable??

<<<<<<< HEAD
proc someInfo(data:AllNeededData, irrelevant:HashSet[string]) =
=======
proc determineParentId(obj: Construct; data: AllNeededData): (bool, Option[UUID]) =
  var discarded = false
  let irrelevant = ["PredefinedType", "IdentifierName", "QualifiedName", "GenericName"].toHashSet()
  var res: Option[UUID]
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
  echo "blocks: ", blocks
  echo "all received constructs: ", currentConstruct
  echo "all received constructs: ", currentConstruct.filterIt(it.name notin irrelevant).mapIt(it.name)
  echo "source code was: " & data.sourceCode
  if data.lastMethod != nil:
    echo data.lastMethod.name
    echo data.lastMethod.body.mapIt(it.ttype)

<<<<<<< HEAD
=======
  let ignoredConstructs = ["IdentifierName", "QualifiedName", "BlockStarts", "AliasQualifiedName"]
  if obj.parentId.isSome:
    echo "obj already has parent id, returning that."
    return (false, obj.parentId)

  let phint = parentHint(obj)
  # try numerical first.
  let tryMatch = getLastType(b=>b.info.rawKind == obj.parentRawKind)
  if tryMatch.isSome:
    echo "found the parent in blocks via object's numeric rawkind"
    let id = tryMatch.get.id.some
    let kind = tryMatch.get.info.rawkind
    if parentTable.hasKey(kind) and parentTable[kind] notin ignoredConstructs:
      return (false, id)

  elif phint.isSome():
    if phint.get notin ignoredConstructs:
      let lastMatch = getLastType(phint.get)
      if lastMatch.isSome:
        echo "found parent ID thru Roslyn's parent Kind (string type)."
        let id = lastMatch.get.id.some
        return (false, id)
      else: assert false, "couldn't find it (`" & phint.get & "`) in last blocks even though we should have"
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3

proc determineParentSpecific(obj: Construct; data: AllNeededData): FindParentResult =
  var res: Option[UUID]
  var discarded = false
  echo "trying to determine parent based on structure, and previous constructs"
  echo data.sourceCode
  case obj.kind
<<<<<<< HEAD
  of ckIdentifier:
    echo "got an identifier"
    assert false, "TODO" #TODO!

=======
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
  of ckClass:
    echo "obj is a class, returning the current namespace id"
    res = data.currentNamespace.id
    assert res.isSome and not res.get.isZero
  of ckNamespace:
    echo "obj is a namespace, returning None"
    res = none(UUID) # namespaces don't have a parentID, since we have just one root.
  of ckMethod:
    echo "object is a method"
<<<<<<< HEAD
    let m = getLastBlocks(@[ckClass, ckStruct], obj.id.get)
=======
    let m = getLastBlocks(@[ckClass, ckStruct])
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
    assert m.isSome
    res = m.get.id.some
    # echo "last added in namespace: ", data.nsLastAdded
    # assert data.nsLastAdded != NamespaceParts.Unset
    # assert data.nsLastAdded == NamespaceParts.Classes # methods are in classes.
    # assert data.lastClass != nil
    # echo "last class has id:", data.lastClass.id
    # return (discarded, data.lastClass.id)

  of ckPredefinedType:

    # return (discarded, none(UUID))

    echo "object is a predefined type"
    echo data.previousConstruct.get.name

    case data.previousConstruct.get.name
    of "MethodDeclaration":
      echo data.lastClass.name
      echo data.lastClass.methods.mapIt(it.name)
      assert not data.lastMethod.isNil
      assert data.lastMethod.id.isSome
      res = data.lastMethod.id
    of "PropertyDeclaration":
      res = data.lastProp.id
    of "IndexerDeclaration":
      assert data.lastClass.hasIndexer
      res = data.lastClass.indexer.id
    # of ["VariableDeclaration", "Parameter", "IdentifierName", "TypeArgumentList"]:
    #   discarded = true
    else:
      echo "in ckPredefinedType: not all cases were matched"
      if discarded == false:
        assert false
      return FindParentResult(discarded:discarded,parentId: none(UUID))
  of ckParameter:
    echo "object is Parameter"
    case data.classLastAdded:
    of ClassParts.Methods:
      res = data.lastMethod.parameterList.id
    of ClassParts.Ctors:
      res = data.lastCtor.parameterList.id
    of ClassParts.Indexer:
      assert data.lastClass.hasIndexer
      res = data.lastClass.indexer.id
    else: assert false, "not implemented " & $data.classLastAdded

  of ckUsingDirective:
    echo "object is UsingDirective"
    res = data.currentNamespace.id

  of ckEnum:
    echo "object is EnumDeclaration"
    res = data.currentNamespace.id
  of ckEnumMember:
    echo "object is EnumMemberDeclaration"
    res = data.lastEnum.id

  of ckArgumentList:
    echo "object is ArgumentList"
    echo "we assume we're in method or ctor, or property, but if there are more options change that."
    assert data.classLastAdded in [ClassParts.Methods, ClassParts.Properties,
        ClassParts.Ctors]
    echo data.classLastAdded
    if data.classLastAdded == Ctors and data.lastCtor.body.isEmpty and
        data.lastCtor.initializer != nil:
      # then it could belong to initializer -- hmmm... we depend here on order (first ctor, then ctor init). a little fishy.
      res = data.lastCtor.id
    else:
      res = data.lastBodyExprId

<<<<<<< HEAD
=======
  of ckExpressionStatement:
    echo "obj is ExpressionStatement"
    # echo "we assume we're in method or ctor, but if there are more options change that."
    let last = state.getLastType((c) => c.name notin ["IdentifierName"]) # FIXME: add more according to cases.
    res = last.get.id.some

>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
  of ckAssignmentExpression:
    echo "obj is AssignmentExpression"
    assert data.classLastAdded in [ClassParts.Methods, ClassParts.Ctors],
        $data.classLastAdded
    res = data.idLastClassPart

  of ckIndexer:
    echo "obj is IndexerDeclaration"
    let p = @[ckClass, ckStruct]
<<<<<<< HEAD
    let m = getLastBlocks(p, obj.id.get)
=======
    let m = getLastBlocks(p)
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
    assert m.isSome
    res = m.get.id.some

  of ckParameterList:
    echo "obj is ParameterList"
    # last method or ctor
    assert data.classLastAdded in [ClassParts.Ctors, ClassParts.Methods]
    res = data.idLastClassPart

  of ckConstructor:
    echo "obj is Constructor"
    res = data.lastClass.id

  of ckProperty:
    echo "obj is property"
    # can be interfaces or classes
    let parents = @[ckClass, ckInterface, ckStruct, ckNamespace]
<<<<<<< HEAD
    let match = getLastBlocks(parents, obj.id.get)
=======
    let match = getLastBlocks(parents)
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
    assert match.isSome
    res = match.get.id.some

    # assert data.nsLastAdded in [NamespaceParts.Interfaces, NamespaceParts.Classes]
    # res = data.idLastNsPart()

  of ckInvocationExpression:
    echo "obj is InvocationExpression" #TODO: can also be in class as initializing instance var.
    # res = data.lastMethod.id
    if data.classLastAdded == Methods:
      if data.lastMethod.body.len == 0:
        res = data.lastMethod.id
      else:
        res = data.lastMethod.lastBodyExprId
    else: res = data.idLastClassPart

  of ckArgument:
    echo "obj is Argument, older code was discarding -- TODO?"
    # here we add to possibly many types. first: expression
    case data.classLastAdded
    of Methods:
      res = data.lastBodyExprId
    else: assert false, $data.classLastAdded
  of ckLiteralExpression:
    res = handleLiteralExpression(data, obj.id.get)
    if res.isNone: discarded = true
    # NOTE: make sure not inside annotation. we should remove those, as we don't support them at all!

  of ckExplicitInterfaceSpecifier:
    echo "obj is ExplicitInterfaceSpecifier"
    if data.previousPreviousConstruct.get.name == "IndexerDeclaration":
      if data.lastClass.hasIndexer:
        res = data.lastClass.indexer.id
      else: res = none(UUID)
  of ckEqualsValueClause:
    echo "obj is EqualsValueClause"
    # the parent is the previous construct. TODO: some checks needed?
    assert data.previousConstruct.isSome
    echo data.previousConstruct
    res = some(data.previousConstruct.get.id)
    assert data.previousconstruct.get.name in ["EnumMemberDeclaration",
        "VariableDeclarator"], data.previousconstruct.get.name
    # currentRoot.previousConstructObj()
  of ckBaseList, ckSimpleBaseType: # interfaces, classes or structs can have a baselist to extend
    assert data.nsLastAdded in [Classes, Interfaces] #, Structs ]
    res = data.idLastNsPart
  of ckBracketedParameterList: # for now, I assume only for indexer.
    assert data.classLastAdded == ClassParts.Indexer
    res = data.idLastClassPart

  of ckAccessorList: # for properties and indexer, others? both are in class.
    assert data.classLastAdded in [ClassParts.Properties, ClassParts.Indexer]
    res = data.idLastClassPart
  of ckAccessor: # find its parent:AccessorList
<<<<<<< HEAD
    let lastMatch = getLastType("AccessorList", obj.id.get)
=======
    let lastMatch = getLastType("AccessorList")
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
    assert lastMatch.isSome
    res = lastMatch.get.id.some
    # assert data.classLastAdded in [ClassParts.Properties, ClassParts.Indexer]
    # case data.classLastAdded
    # of Properties:
    #   res = data.lastProp.acclist.id
    # of Indexer:
    #   assert data.lastClass.hasIndexer
    #   assert data.lastClass.indexer.aclist != nil
    #   res = data.lastClass.indexer.aclist.id
    # else: assert false, " where else? " & $data.classLastAdded
  of ckMemberAccessExpression: # NOTE!! make sure this isn't another annotation: check source code. if it is, run CsDisplay again to remove annotation.
    res = data.lastBlockType(@["VariableDeclarator", "InvocationExpression"])
    if res.isNone: # add more? sometimes fails because of C# annotation meta data so ignore in such cases.
      echo "ckMemberAccessExpression !! GOT NONE. Setting discarded to true, to ignore."
      discarded = true

  of ckConstructorInitializer:
    # parent is ckConstructor.
    assert data.classLastAdded == ClassParts.Ctors
    res = data.lastCtor.id
  of ckVariable:
    # can be in a method, can be in a class (as instance var)
    # if it is a variable declaration, add the actual declaration to this wrapper.
    # echo data.inBlock
    # echo data.prevBlock
    # echo data.currentConstruct
    case data.previousConstruct.get.name
    of "LocalDeclarationStatement":
      # we're in a method, get the last body id.
      assert data.classLastAdded == Methods, $data.classLastAdded
      res = data.lastBodyExprId # "hopefully" this is the local declaration.
    of "FieldDeclaration":
      res = data.lastBlockType("FieldDeclaration")
      assert res.isSome
    else: assert false, "please add more: " & data.previousConstruct.get.name


  of ckGenericName:
    # just return the last construct.
    let b = getLastType((c) => c.name notin ["GenericName", "BlockStarts",
<<<<<<< HEAD
        "IdentifierName", "QualifiedName"], obj.id.get)
    if b.isNone: discarded = true
    echo b.get.name
    res = b.get.id.some
=======
        "IdentifierName", "QualifiedName"])
    if b.isNone: discarded = true
    echo b.get.name
    res = b.get.id.some
    # when false: # previous impl. do we pass unit tests?
    #   case data.previousConstruct.get.name
    #   of ["IdentifierName"]: discarded = true
    #   of ["VariableDeclaration", "ObjectCreationExpression",
    #       "MethodDeclaration", "Parameter", "SimpleBaseType"]:
    #     assert data.classLastAdded == Methods, $data.classLastAdded
    #     res = data.lastBodyExprId
    #     if res.get != data.previousConstruct.get.id:
    #       let btype = if not data.lastBodyExpr.get.typ.isEmptyOrWhitespace: data.lastBodyExpr.get.typ else: data.lastBodyExpr.get.ttype
    #       echo btype, " <=> ", data.previousConstruct.get.name
    #   else: assert false, data.previousConstruct.get.name
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3


  of ckTypeArgumentList:
    case data.previousConstruct.get.name
    of "GenericName":
      let b = data.lastBlockType("GenericName")
      assert b.isSome
      res = b
      # assert data.classLastAdded == Methods, $data.classLastAdded
      # res = data.lastBodyExprId
    else: assert false, data.previousConstruct.get.name

  of ckVariableDeclarator: # for now assume we're in method, add more later.
    assert data.classLastAdded == Methods, $data.classLastAdded
    # res = data.lastBodyExprId # this will create a few chained adds but we don't care.
    res = data.lastBlockType(@["FieldDeclaration", "LocalDeclarationStatement",
        "MethodDeclaration"])
    # res = data.idLastClassPart
    # res = data.lastMethod.id

  of ckObjectCreationExpression: # store in assignment expression # not variable declarator.
    case data.previousPreviousConstruct.get.name & ", " &
        data.previousConstruct.get.name
    of "VariableDeclarator, EqualsValueClause":
      # based on last 2 constructs: variableDeclarator equalsvalueclause ...
      res = data.previousPreviousConstruct.get.id.some
    of "AssignmentExpression, IdentifierName":
      res = data.previousPreviousConstruct.get.id.some
    of "ParameterList, ReturnStatement":
      res = data.previousConstruct.get.id.some

    else: assert false, data.previousPreviousConstruct.get.name & ", " &
        data.previousConstruct.get.name

  of ckInitializerExpression: # find your parent: the last object creation expression
<<<<<<< HEAD
    let m = getLastTypes([ckObjectCreationExpression], obj.id.get)
=======
    let m = getLastTypes([ckObjectCreationExpression])
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
    assert m.isSome
    res = m.get.id.some

  of ckPrefixUnaryExpression: # hmm, not the previous but the next one. so just add it.
    let fitting = getLastType(c=>c.name in [
<<<<<<< HEAD
        "InitializerExpression", "NameEquals"], obj.id.get) # TODO: add others as needed.
=======
        "InitializerExpression", "NameEquals"]) # TODO: add others as needed.
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
    assert fitting.isSome, $data.simplified
    res = fitting.get.id.some
  of ckBinaryExpression:
    let b = state.getLastType(c=>c.name in [
<<<<<<< HEAD
        "VariableDeclarator", "LiteralExpression"], obj.id.get) # TODO: add others as needed.
=======
        "VariableDeclarator", "LiteralExpression"]) # TODO: add others as needed.
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
    assert b.isSome, $data.simplified
    res = b.get.id.some
  of ckField: # classes, or interfaces
    # assert data.nsLastAdded in [Classes, Interfaces] # more?
    # res = data.idLastNsPart

    let parents = @["ClassDeclaration", "StructDeclaration", "InterfaceDeclaration"]
<<<<<<< HEAD
    let lastMatch = getLastBlocks(parents, obj.id.get)
    assert lastMatch.isSome
    res = lastMatch.get.id.some
  of ckNameEquals: # so far only saw it with a using line (import)
=======
    let lastMatch = getLastBlocks(parents)
    assert lastMatch.isSome
    res = lastMatch.get.id.some
  of ckNameEquals:
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
    res = data.lastUsing.id # could be related to inner annotation not being removed by CsDisplay, check cs source code first.

  of ckExternAliasDirective:
    # ignore, unsupported.
    discarded = true
    echo "got " & $ckExternAliasDirective & " which we don't support (doesn't make sense for nim modules)"

  of [ckInterface, ckDelegate, ckStruct, ckEvent]:
<<<<<<< HEAD
    res = if data.currentNamespace.isNil:
      currentRoot.global.id
    else:
      data.currentNamespace.id
=======
    res = data.currentNamespace.id
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3

  of ckCaseSwitchLabel:
    assert false, "got: " & $obj.kind & data.sourceCode

  of ckSwitchSection:
    let parents = @["SwitchStatement"]
<<<<<<< HEAD
    let lastMatch = getLastBlocks(parents, obj.id.get)
    assert lastMatch.isSome
    res = lastMatch.get.id.some

  of ckContinueStatement:
    let lastMatch = getLastBlocks(@["ForStatement", "TryStatement", "ForEachStatement", "WhileStatement", "IfStatement", "SwitchSection", "CatchClause", "DoStatement"], obj.id.get)
    assert lastMatch.isSome
    res = lastMatch.get.id.some
=======
    let lastMatch = getLastBlocks(parents)
    assert lastMatch.isSome
    res = lastMatch.get.id.some

  of ckPostfixUnaryExpression:
    assert false, "got: " & $obj.kind & data.sourceCode
  of ckCatchClause:
    assert false, "got: " & $obj.kind & data.sourceCode
  of ckCatch:
    assert false, "got: " & $obj.kind & data.sourceCode
  of ckContinueStatement:
    let lastMatch = getLastBlocks(@["ForStatement", "ForEachStatement", "WhileStatement", "IfStatement", "SwitchSection", "CatchClause", "DoStatement"])
    assert lastMatch.isSome
    res = lastMatch.get.id.some
  of ckFinallyClause:
    assert false, "got: " & $obj.kind & data.sourceCode
  of ckDefaultSwitchLabel:
    assert false, "got: " & $obj.kind & data.sourceCode

  of ckThrowExpression:
    assert false, "got: " & $obj.kind & data.sourceCode

>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
  # general body constructs
  of [
    ckGotoStatement, ckLabeledStatement, ckUnsafeStatement, ckFixedStatement,
    ckSwitchStatement, ckReturnStatement, ckIfStatement, ckElseClause,
    ckForStatement, ckDoStatement, ckCastExpression, ckWhileStatement,
    ckForEachStatement, ckForEachVariableStatement, ckUsingStatement, ckLockStatement, ckCheckedStatement,
<<<<<<< HEAD
    ckTryStatement, ckThrowStatement, ckYieldStatement, ckExpressionStatement
=======
    ckTryStatement, ckThrowStatement, ckYieldStatement
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
    ]:
    echo "got " & $obj.kind
    let parents = @[
    "DestructorDeclaration", "AccessorDeclaration", "ConversionOperatorDeclaration", "ParenthesizedLambdaExpression",
      "MethodDeclaration", "ForStatement", "ForEachStatement", "ElseClause",
<<<<<<< HEAD
      "SwitchSection", "IndexerDeclaration", "LockStatement","FinallyClause",
      "ConstructorDeclaration", "OperatorDeclaration", "LocalFunctionStatement",
      "AnonymousMethodExpression", "IfStatement", "TryStatement", "SimpleLambdaExpression" ]
      # "PropertyDeclaration",
    echo "and looking for its parent in:", parents
    let lastMatch = getLastBlocks(parents, obj.id.get)
=======
      "SwitchSection", "IndexerDeclaration",
      "ConstructorDeclaration", "OperatorDeclaration", "LocalFunctionStatement",
      "AnonymousMethodExpression", "IfStatement", "TryStatement", "SimpleLambdaExpression"
    ]
      # "PropertyDeclaration",
    echo "and looking for its parent in:", parents
    let lastMatch = getLastBlocks(parents)
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
    assert lastMatch.isSome
    res = lastMatch.get.id.some

  of ckLocalDeclarationStatement:
    let parents = @[ckClass, ckMethod, ckConstructor, ckProperty, ckForStatement, ckIfStatement, ckSwitchSection, ckElseClause,
    ckUsingStatement, ckConversionOperator, ckAccessor, ckDestructor, ckAnonymousMethodExpression, ckParenthesizedLambdaExpression, ckGlobalStatement,
<<<<<<< HEAD
    ckForEachStatement, ckIndexer, ckTryStatement, ckOperator, ckLabeledStatement, ckLocalFunctionStatement]

    let lastMatch = getLastBlocks(parents, obj.id.get)
    assert lastMatch.isSome
    res = lastMatch.get.id.some
  of ckBreakStatement: # if, case, else, while, do, ...others?
    let lastMatch = getLastBlocks(@[ckForEachStatement, ckForEachVariableStatement  , ckForStatement, ckCaseSwitchLabel, ckDefaultSwitchLabel, ckIfStatement, ckTryStatement, ckElseClause, ckSwitchSection, ckWhileStatement, ckMethod],obj.id.get)
    assert lastMatch.isSome
    res = lastMatch.get.id.some
    # assert false # plz add more cases above.
  of ckNameColon:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    let p = @[ckArgument] # TODO: add more, as needed.
    let m = getLastTypes(p, obj.id.get)
    assert m.isSome
    res = m.get.id.some
  of ckEventField:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    let p = @[ckClass, ckNamespace]
    let m = getLastBlocks(p, obj.id.get)
    assert m.isSome
    res = m.get.id.some

  of ckGlobalStatement: # ignored.
    discarded = true # not sure what to do here. for example got a file with just a few strings.
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    # assert false
  of ckIncompleteMember: #ignore
    # TODO: don't know what this means, for now, ignore it.
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    discarded = true
    # assert false
  of ckSwitchExpression:
    let parents = @[ckSwitchExpressionArm]
    let lastMatch = getLastTypes(parents, obj.id.get)
    assert lastMatch.isSome
    res = lastMatch.get.id.some
  of ckLocalFunctionStatement: #
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    let parents = @[ ckMethod, ckConstructor, ckDestructor, ckAccessor]
    let lastMatch = getLastTypes(parents, obj.id.get)
    assert lastMatch.isSome
    res = lastMatch.get.id.some




  of ckPostfixUnaryExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckCatchClause:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckCatch:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckFinallyClause:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckDefaultSwitchLabel:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckThrowExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckThisExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckBracketedArgumentList:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckElementAccessExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckParenthesizedExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckArrayRankSpecifier:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckArrayType:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckOmittedArraySizeExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckTypeOfExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode

  of ckSimpleLambdaExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckArrayCreationExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckArrowExpressionClause:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
=======
    ckForEachStatement, ckIndexer, ckTryStatement, ckOperator, ckLabeledStatement]
    let lastMatch = getLastBlocks(parents)
    assert lastMatch.isSome
    res = lastMatch.get.id.some
  of ckBreakStatement: # if, case, else, while, do, ...others?
    let lastMatch = getLastBlocks(@[ ckIfStatement, ckTryStatement, ckElseClause, ckSwitchSection, ckWhileStatement, ckMethod])
    assert lastMatch.isSome
    res = lastMatch.get.id.some
    # assert false # plz add more cases above.

  of ckThisExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckBracketedArgumentList:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckElementAccessExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckParenthesizedExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckArrayRankSpecifier:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckArrayType:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckOmittedArraySizeExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckTypeOfExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false

  of ckSimpleLambdaExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckArrayCreationExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckArrowExpressionClause:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
  of ckAliasQualifiedName:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    discarded = true
    # assert false
  of ckTypeParameter:
<<<<<<< HEAD
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckAwaitExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckConditionalExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckTypeParameterList:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode

  of ckInterpolatedStringText:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckParenthesizedLambdaExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckNullableType:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckBaseExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckInterpolation:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode

  of ckTypeParameterConstraintClause:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckTypeConstraint:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode

  of ckSingleVariableDesignation:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckInterpolatedStringExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckImplicitArrayCreationExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckDeclarationExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckConditionalAccessExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckMemberBindingExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode

  of ckDefaultExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckPointerType:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckAnonymousObjectMemberDeclarator:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckCheckedExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckIsPatternExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckDeclarationPattern:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckConstantPattern:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckRefType:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckRefExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode

  of ckClassOrStructConstraint:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckOmittedTypeArgument:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckTupleElement:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckOperator:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckImplicitElementAccess:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckAnonymousMethodExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckTupleExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode

  of ckAnonymousObjectCreationExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode

  of ckConversionOperator:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckTupleType:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
=======
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckAwaitExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckConditionalExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckTypeParameterList:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false

  of ckInterpolatedStringText:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckParenthesizedLambdaExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckNullableType:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckBaseExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckInterpolation:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckNameColon:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckTypeParameterConstraintClause:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckTypeConstraint:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false

  of ckSingleVariableDesignation:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckInterpolatedStringExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckImplicitArrayCreationExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckDeclarationExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckConditionalAccessExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckMemberBindingExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false

  of ckDefaultExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckPointerType:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckAnonymousObjectMemberDeclarator:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckCheckedExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckIsPatternExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckDeclarationPattern:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckConstantPattern:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckRefType:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckRefExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false

  of ckClassOrStructConstraint:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckOmittedTypeArgument:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckTupleElement:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckOperator:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckEventField:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    let p = @[ckClass, ckNamespace]
    let m = getLastBlocks(p)
    assert m.isSome
    res = m.get.id.some

  of ckImplicitElementAccess:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckAnonymousMethodExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckTupleExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false

  of ckAnonymousObjectCreationExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckGlobalStatement: # ignored.
    discarded = true # not sure what to do here. for example got a file with just a few strings.
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    # assert false
  of ckIncompleteMember: #ignore
    # TODO: don't know what this means, for now, ignore it.
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    discarded = true
    # assert false

  of ckLocalFunctionStatement: #
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    let parents = @[ ckMethod, ckConstructor, ckDestructor, ckAccessor]
    let lastMatch = getLastTypes(parents)
    assert lastMatch.isSome
    res = lastMatch.get.id.some

  of ckConversionOperator:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckTupleType:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
  of ckEmptyStatement: # ignore
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    discarded = true
    # assert false
  of ckSizeOfExpression:
<<<<<<< HEAD
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode

  of ckQueryBody:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckQueryExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckCasePatternSwitchLabel:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode

  of ckConstructorConstraint:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckParenthesizedVariableDesignation:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode

  of ckInterpolationFormatClause:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckDestructor:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckDiscardDesignation:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckStackAllocArrayCreationExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckWhenClause:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckLetClause:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckElementBindingExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode

  of ckCatchFilterClause:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckOrdering:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckInterpolationAlignmentClause:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckQueryContinuation:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckMakeRefExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckRefValueExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckRefTypeExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckBlock:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckBinaryPattern:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckDiscardPattern:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode

  of ckFunctionPointerType:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckImplicitObjectCreationExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckParenthesizedPattern:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckPositionalPatternClause:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckPrimaryConstructorBaseType:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckPropertyPatternClause:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckRangeExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckRecord:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode

  of ckRecursivePattern:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckRelationalPattern:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckSubpattern:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode


  of ckSwitchExpressionArm:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckTypePattern:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckUnaryPattern:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckVarPattern:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckWithExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode

  of ckImplicitStackAllocArrayCreationExpression:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckOrderByClause:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckGroupClause:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckJoinClause:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckFromClause:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckSelectClause:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckWhereClause:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode
  of ckJoinIntoClause:
    assert false,"got: " & $obj.kind & "\nsource: " & data.sourceCode


  result = FindParentResult(discarded: discarded, parentId: res)
=======
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false

  of ckQueryBody:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckQueryExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckCasePatternSwitchLabel:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false

  of ckConstructorConstraint:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckParenthesizedVariableDesignation:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false

  of ckInterpolationFormatClause:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckDestructor:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckDiscardDesignation:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckStackAllocArrayCreationExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckWhenClause:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckLetClause:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckElementBindingExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false

  of ckCatchFilterClause:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckOrdering:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckInterpolationAlignmentClause:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckQueryContinuation:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckMakeRefExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckRefValueExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckRefTypeExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckBlock:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckBinaryPattern:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckDiscardPattern:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false

  of ckFunctionPointerType:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckImplicitObjectCreationExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckParenthesizedPattern:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckPositionalPatternClause:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckPrimaryConstructorBaseType:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckPropertyPatternClause:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckRangeExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckRecord:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false

  of ckRecursivePattern:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckRelationalPattern:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckSubpattern:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckSwitchExpression:
    let parents = @[ckSwitchExpressionArm]
    let lastMatch = getLastTypes(parents)
    assert lastMatch.isSome
    res = lastMatch.get.id.some

  of ckSwitchExpressionArm:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckTypePattern:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckUnaryPattern:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckVarPattern:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckWithExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false

  of ckImplicitStackAllocArrayCreationExpression:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckOrderByClause:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckGroupClause:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckJoinClause:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckFromClause:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckSelectClause:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckWhereClause:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false
  of ckJoinIntoClause:
    echo "got: " & $obj.kind & "\nsource: " & data.sourceCode
    assert false


  result = (discarded, res)
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
  if res.isNone: assert discarded == true
  assert (not discarded and res.isSome) or (discarded and res.isNone), "dis: " &
      $discarded & ", res: " & $res


proc determineByHint(obj:Construct) : FindParentResult =
  var discarded = false
  var ignoredConstructs = @[ "QualifiedName", "BlockStarts", "AliasQualifiedName","GlobalStatement","IncompleteMember"] # had here also "IdentifierName",
  var ckIgnoredConstructs = @[ ckAliasQualifiedName,ckGlobalStatement,ckIncompleteMember]
  let phint = parentHint(obj)
  # try numerical first. # possibly it's the same?
  let tryMatch = getLastType(b=>b.info.rawKind == obj.parentRawKind, obj.id.get)
  # we don't do this for ignoredConstructs, so we go to its specific impl below.
  echo obj.kind
  if obj.kind notin ckIgnoredConstructs:
    if tryMatch.isSome:
      echo "found the parent in blocks via object's numeric rawkind"
      let id = tryMatch.get.id.some
      let kind = tryMatch.get.info.rawkind
      if parentTable.hasKey(kind) and parentTable[kind] notin ignoredConstructs:
        discarded = false
        result = FindParentResult(discarded: false, parentId: id)
    elif phint.isSome():
      if phint.get notin ignoredConstructs:
        let lastMatch = getLastType(phint.get, obj.id.get)
        if lastMatch.isSome:
          echo "found parent ID thru Roslyn's parent Kind (string type)."
          let id = lastMatch.get.id.some
          discarded = false
          result = FindParentResult(discarded:false, parentId: id)
        else: assert false, "couldn't find it (`" & phint.get & "`) in last blocks even though we should have"

proc determineBySetID (obj:Construct): FindParentResult =
  assert obj.parentId.isSome
  echo "obj already has parent id, if it fits, returning that."
  result = FindParentResult(discarded: false, parentId: obj.parentId)

proc determineParentId(root: var CsRoot; obj: Construct; data: AllNeededData): FindParentResult =
  echo "in determineParentId"
  # var discarded = false
  let irrelevant = ["PredefinedType","IdentifierName", "QualifiedName", "GenericName","IncompleteMember"].toHashSet()
  # var res: Option[UUID]
  someInfo(data,irrelevant)
  if obj.parentId.isSome:
    result = determineBySetID(obj)
  else:
    result = determineByHint(obj)
  echo "No parent set from C# side"
  # result can still be none.

  # in both cases, if doesn't fit, have to forget that result and do a specific match.
  # get the actual parent:
  if result.parentId.isNone:
    result = determineParentSpecific(obj,data)
  if result.parentId.isSome:
    let p = root.infoCenter.fetch(result.parentId.get)
    let fits = cfits(p.get,obj,data)
    if not fits:
      result = determineParentSpecific(obj,data)

proc getParent*(root: var CsRoot; newobj: Construct; allData: AllNeededData): (bool, Option[Construct]) =
  var res: Option[Construct]
  echo "in getParent"
  echo "newobj: ", newobj.kind
  let parentRes = determineParentId(root,newobj, allData)
  let
    pid = parentRes.parentId
    dis = parentRes.discarded

  echo "discarded: ", dis, " object kind: ", newobj.kind, " parentID: ", pid

  # some validations
  if parentRes.parentId.isNone:
    assert parentRes.discarded,"both no parent id, and not discarded"

  if newobj.kind != ckNamespace and not parentRes.discarded and parentRes.parentId.isSome: # because namespace has no parent. root is explicit.
    # the happy case
    assert not pid.get.isZero
    echo "parent id found: ", $pid
    res = root.infoCenter.fetch(pid.get)
    if res.isNone:
<<<<<<< HEAD
      echo "!!! couldn't find registered object for this id" ### NOTE: can happen for IdentifierName since we don't register it. it means the parent was wrongly identified as IdentifierName.
=======
      echo "--- couldn't find registered object for this id" ### NOTE: can happen for IdentifierName since we don't register it. it means the parent was wrongly identified as IdentifierName.
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
      # assert false

    assert cfits(res.get,newobj,allData) # check again that parent fits, if not: likely cfits mapping is wrong or the specific matching needs tweaking

  # more validations after fetching the parent object construct.
  assert (not dis and res.isSome) or (dis and res.isNone),
    "dis: " & $dis & ", res: " & (if res.isSome: $res.get.kind else: "none")

  result = (dis, res)