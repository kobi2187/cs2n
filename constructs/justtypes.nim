{.experimental: "codeReordering".}
import ../types
import ../state

import uuids, options, sets, tables

<<<<<<< HEAD
# import iface
# iface BodyExpr:
#   proc matchesBodyExpr(): bool
=======
import iface
iface GeneralBodyConstruct:
  proc matchesGeneralBodyConstruct(): bool
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3

type ClassParts* {.pure.} = enum
  Methods, Ctors, Properties, Indexer

type PropertyParts* = enum Getter, Setter

type NamespaceParts* {.pure.} = enum
  Unset, Interfaces, Enums, Classes, Using

type IAssignable = ref object of BodyExpr
type Pattern* = ref object of CsObject
type PatternClause = ref object of CsObject
  subs*:seq[CsSubpattern]

type Constraint = ref object of CsObject

type CsAccessor* = ref object of CsObject
  kind*: string # get or set # for events/delegates: add remove
  # statements*: seq[BodyExpr]
  statementsTxt*: string
<<<<<<< HEAD
  body*: seq[BodyExpr]
  modifiers*:seq[string]
  expressionBody*: CsArrowExpressionClause

type CsAccessorList* = ref object of CsObject
  accessors*: seq[CsAccessor]

type CsAliasQualifiedName* = ref object of CsObject

=======
  body*: seq[GeneralBodyConstruct]
type CsAccessorList* = ref object of CsObject
  accessors*: seq[CsAccessor]
  # hasDefaultGet*: bool
  # hasGetBody*: bool
  # hasDefaultSet*: bool
  # hasSetBody*: bool
  # getPart*: CsAccessor
  # setPart*: CsAccessor
type CsAliasQualifiedName* = ref object of CsObject #TODO(type:CsAliasQualifiedName)
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
type CsField* = ref object of CsObject
  thetype*: string
  isPublic*: bool
  isStatic*: bool
<<<<<<< HEAD
  #NOTE: in c# you can assign a field on the spot. we'll probably add them to the default ctor.
  defaultInit*:CsAssignmentExpression # ?
type CsAnonymousMethodExpression* = ref object of BodyExpr
  paramList*:CsParameterList
  body*: seq[BodyExpr]
type CsAnonymousObjectCreationExpression* = ref object of BodyExpr
  members*:seq[CsAnonymousObjectMemberDeclarator]

type CsAnonymousObjectMemberDeclarator* = ref object of CsObject
  memberName*:CsNameEquals
  body*: seq[BodyExpr] # unused?
  value*: BodyExpr
=======
type CsAnonymousMethodExpression* = ref object of CsObject #TODO(type:CsAnonymousMethodExpression)
  body*: seq[GeneralBodyConstruct]
type CsAnonymousObjectCreationExpression*
  = ref object of CsObject #TODO(type:CsAnonymousObjectCreationExpression)
type CsAnonymousObjectMemberDeclarator* = ref object of CsObject #TODO(type:CsAnonymousObjectMemberDeclarator)
  body*: seq[GeneralBodyConstruct]
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3

type CsArgument* = ref object of CsObject
  gotType*:TypeNameDef
  expr*:BodyExpr
  mref*:CsRefValueExpression
  value*: string

type CsArgumentList* = ref object of CsObject
  args*: seq[CsArgument]
<<<<<<< HEAD
  genericName*:CsGenericName
type CsArrayCreationExpression* = ref object of BodyExpr
  theType*:CsArrayType
  initializer*:CsInitializerExpression

type CsArrayRankSpecifier* = ref object of CsObject
  gotType*:TypeNameDef
  omitted*:CsOmittedArraySizeExpression # what does it have?
  theRankValue*:BodyExpr# CsLiteralExpression # others?

type CsArrayType* = ref object of TypeNameDef
  gotType*:TypeNameDef
  rankSpecifier*:CsArrayRankSpecifier

type CsArrowExpressionClause* = ref object of BodyExpr
  body*: seq[BodyExpr]

type CsAssignmentExpression* = ref object of BodyExpr
  gotType*:TypeNameDef
  leftStr*:  string # TODO: should be some variable
  left*:BodyExpr
  op*: string
  right*: BodyExpr
  # body*: seq[BodyExpr]

type CsAttributeArgumentList* = ref object of CsObject
type CsAttributeArgument* = ref object of CsObject
type CsAttributeList* = ref object of CsObject
type CsAttribute* = ref object of CsObject
type CsAttributeTargetSpecifier* = ref object of CsObject
type CsAwaitExpression* = ref object of BodyExpr
  body*: seq[BodyExpr]

type CsBaseExpression* = ref object of BodyExpr
=======

type CsArrayCreationExpression* = ref object of BodyExpr #TODO(type:CsArrayCreationExpression)
type CsArrayRankSpecifier* = ref object of CsObject #TODO(type:CsArrayRankSpecifier)
type CsArrayType* = ref object of CsObject #TODO(type:CsArrayType)
type CsArrowExpressionClause* = ref object of CsObject #TODO(type:CsArrowExpressionClause)
  body*: seq[GeneralBodyConstruct]

type CsAssignmentExpression* = ref object of BodyExpr
  left*: string # TODO: should be some variable
  op*: string
  right*: IAssignable
  body*: seq[GeneralBodyConstruct]
type CsAttributeArgumentList* = ref object of CsObject #TODO(type:CsAttributeArgumentList)
type CsAttributeArgument* = ref object of CsObject #TODO(type:CsAttributeArgument)
type CsAttributeList* = ref object of CsObject #TODO(type:CsAttributeList)
type CsAttribute* = ref object of CsObject #TODO(type:CsAttribute)
type CsAttributeTargetSpecifier* = ref object of CsObject #TODO(type:CsAttributeTargetSpecifier)
type CsAwaitExpression* = ref object of CsObject #TODO(type:CsAwaitExpression)
  body*: seq[GeneralBodyConstruct]

type CsBaseExpression* = ref object of CsObject #TODO(type:CsBaseExpression)
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3

type CsBaseList* = ref object of CsObject
  baseList*: seq[string]
  baseList2*: seq[CsSimpleBaseType]

type BooleanExpr = ref object of IAssignable

type CsBinaryExpression* = ref object of BooleanExpr
  gotType*:TypeNameDef
  left*: BodyExpr
  leftStr*:string
  op*: string
<<<<<<< HEAD
  right*: BodyExpr
  rightStr*:string

type CsBracketedArgumentList* = ref object of BodyExpr
  args*: seq[CsArgument]

type CsBreakStatement* = ref object of BodyExpr
type CsCasePatternSwitchLabel* = ref object of CsObject
  pattern*: Pattern
type CsCaseSwitchLabel* = ref object of CsObject
  caseName*:CsLiteralExpression
  other*:BodyExpr
  # body*: seq[BodyExpr]

type CsCastExpression* = ref object of BodyExpr
  gotType*: TypeNameDef
  expr*:BodyExpr
  theType*: string
  theExpr*:string

type CsCatchClause* = ref object of BodyExpr
  what*:CsCatch
  filter*:CsCatchFilterClause
  body*: seq[BodyExpr]

type CsCatchFilterClause* = ref object of CsObject
  predicate*:BooleanExpr
  exprThatLeadsToBoolean*:BodyExpr
  predicatePartLit*:CsLiteralExpression

type CsCatch* = ref object of CsObject
  gotType*:TypeNameDef

type CsCheckedExpression* = ref object of BodyExpr
  body*: seq[BodyExpr]

type CsCheckedStatement* = ref object of BodyExpr
  checked*:Option[bool]
  body*:seq[BodyExpr]

=======
  right*: string
type CsBracketedArgumentList* = ref object of CsObject #TODO(type:CsBracketedArgumentList)
  args*: seq[CsArgument]

type CsBreakStatement* = ref object of CsObject #TODO(type:CsBreakStatement)
type CsCasePatternSwitchLabel* = ref object of CsObject #TODO(type:CsCasePatternSwitchLabel)
type CsCaseSwitchLabel* = ref object of CsObject #TODO(type:CsCaseSwitchLabel)
  body*: seq[GeneralBodyConstruct]

type CsCastExpression* = ref object of BodyExpr #TODO(type:CsCastExpression)

type CsCatchClause* = ref object of CsObject #TODO(type:CsCatchClause)
type CsCatchFilterClause* = ref object of CsObject #TODO(type:CsCatchFilterClause)
type CsCatch* = ref object of CsObject #TODO(type:CsCatch)
type CsCheckedExpression* = ref object of CsObject #TODO(type:CsCheckedExpression)
  body*: seq[GeneralBodyConstruct]

type CsCheckedStatement* = ref object of CsObject #TODO(type:CsCheckedStatement)

>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
type CsProperty* = ref object of CsObject
  gotType*:TypeNameDef
  retType*: string
  nulType*:CsNullableType # the return type.
  acclist*: CsAccessorList
  expl*:CsExplicitInterfaceSpecifier
  # maybe all the rest are redundant? can we gen with just these two?

  initializer* : BodyExpr #CsEqualsValueClause
  expressionBody*: CsArrowExpressionClause
  body*: seq[BodyExpr]
  lastAddedTo*: PropertyParts
  hasGet*: bool
  hasSet*: bool
  parentClass*: string
  bodySet*: seq[BodyExpr] # dunno. TODO: this should be strongly connected to acclist (maybe extracted from it?). but lastBodyExpr wants to have constructs readily available like in this seq.
  bodyGet*: seq[BodyExpr] # NOTE: don't know yet what type to* put here. maybe something like a method body or a list of expr ?
<<<<<<< HEAD
  # defaultValue*: BodyExpr # CsEqualsValueClause
=======
  body*: seq[GeneralBodyConstruct]
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3

type CsTypeArgumentList* = ref object of CsObject
  types*: seq[string]
  gotTypes*: seq[TypeNameDef]

type CsGenericName* = ref object of TypeNameDef
  typearglist*: CsTypeArgumentList
<<<<<<< HEAD
  arity*:int #how many type params
  tplTxt*:string
  tplArgsTxt*:string

type CsSimpleBaseType* = ref object of TypeNameDef
  gotType*:TypeNameDef
=======
type CsSimpleBaseType* = ref object of CsObject #TODO(type:CsSimpleBaseType)
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
  genericName*: CsGenericName


type CsParameter* = ref object of CsObject
  ptype*: string
  gotType*: TypeNameDef
  genericType*: CsGenericName
  isRef*: bool
  isOut*: bool
  initValueExpr*:CsEqualsValueClause


type CsParameterList* = ref object of CsObject
  parameters*: seq[CsParameter]

type CsBracketedParameterList* = ref object of CsObject
  plist*: string
  # plist*: seq[CsParameter]

type CsMethod* = ref object of CsObject
  isStatic*: bool
  isPublic*:bool
  parentClass*: string
  typeParamConstraints*: CsTypeParameterConstraintClause
  genericName*: CsGenericName
  parameterList*: CsParameterList # seq[CsParameter]
  tpl*:CsTypeParameterList
  gotType*:TypeNameDef
  explSpecifier*:CsExplicitInterfaceSpecifier
  returnType*: string
  localFunctions*:seq[CsLocalFunctionStatement] # nim supports proc within a proc
  # TODO: method body can change to Construct, but limited only to the constructs applicable. (type constraints* with distinct or runtime asserts)
  # TODO: or we check with case ttype string, as before. runtime dispatch etc.
  body*: seq[BodyExpr] # use here inheritance and methods (runtime dispatch). # seq[Expr] expressions, and each should know how to generate their line. ref objects, and methods.
<<<<<<< HEAD
                       # body*: seq[BodyExpr]
=======
  # body*: seq[GeneralBodyConstruct]
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3

type CsConstructorInitializer* = ref object of CsObject
  args*:CsArgumentList
type CsConstructor* = ref object of CsObject
  modifiers*:seq[string]
  parentClass*: string
  parameterList*: CsParameterList        # seq[CsParameter]
  body*: seq[BodyExpr]
<<<<<<< HEAD
  body2*: seq[BodyExpr]
=======
  body2*: seq[GeneralBodyConstruct]

>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
  initializer*: CsConstructorInitializer # for example, when C# ctor passes args to base ctor # don't yet know how to generate in Nim.
  initializerArgList*: CsArgumentList
type CsEnumMember* = ref object of CsObject
  value*: string #Option[int]



type CsIndexer* = ref object of CsObject
  gotType*:TypeNameDef
  body*:seq[BodyExpr]
  paramlist*: CsBracketedParameterList
  aclist*: CsAccessorList
  retType*: string
  varName*: string
  varType*: string
  firstVarType*: string
<<<<<<< HEAD
  exprBody*: string
  pmlist*: string
  acclist*: string
  mods*: string
  explSpecifier*:string
=======
  paramlist* :CsParameterList
  aclist*: CsAccessorList

  pmlist*:string
  acclist*:string
  mods*:string
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
  hasDefaultGet*: bool
  hasDefaultSet*: bool
  hasBody*: bool

type CsTypeParameter* = ref object of CsObject
<<<<<<< HEAD
  param*: string # in, out,cs_allcs_all ref ...
  # name (identifier)

=======
  param*: string # in, out, ref ...
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
type CsClass* = ref object of CsObject
  genericTypeList*: CsTypeParameterList
  typeParamConstraints*: CsTypeParameterConstraintClause
  nsParent*: string
  ns*:CsNamespace
  extends*: string
  implements*: seq[string]
  fields*: seq[CsField]
  properties*: seq[CsProperty]
  methods*: seq[CsMethod]
  ctors*: seq[CsConstructor]
  lastAddedTo*: Option[ClassParts]
  isStatic*: bool
  mods*: HashSet[string]
  indexer*: CsIndexer
  typeParameterList:float64
  delegates*:seq[CsDelegate]
  eventFields*:seq[CsEventField]
  events*:seq[CsEvent]
  dtors*:seq[CsDestructor]
  convOps*:seq[CsConversionOperator]
  operators*:seq[CsOperator]
  genericName:CsGenericName

type CsClassOrStructConstraint* = ref object of Constraint
type CsConditionalAccessExpression* = ref object of BodyExpr
  lhs*,rhs*:BodyExpr
type CsConditionalExpression* = ref object of BodyExpr
  predicate*:BooleanExpr
  exprThatLeadsToBoolean*:BodyExpr
  predicatePartLit*:CsLiteralExpression
  bodyTrue*: BodyExpr
  bodyFalse*:BodyExpr
  trueTxt*,falseTxt*,condTxt*:string
# type MatchesLiteral = ref object of CsObject
# try to refactor with iface, or some other interface library. single inheritence just doesn't cut it.

type CsConstantPattern* = ref object of Pattern
  val*:CsPrefixUnaryExpression
  lit*:CsLiteralExpression
  keyExpr*:BodyExpr
  valExpr*:BodyExpr
  patExpr*:CsIsPatternExpression


type CsConstructorConstraint* = ref object of Constraint
type CsContinueStatement* = ref object of BodyExpr
type CsConversionOperator* = ref object of CsObject
  gotType*:TypeNameDef
  paramList*:CsParameterList
  body*: seq[BodyExpr]

type CsDeclarationExpression* = ref object of BodyExpr
  gotType*:TypeNameDef
  # Test2 (Test (out var x1), x1);
  svd*:CsSingleVariableDesignation # I think it declares the variable within the argument ('out' var x1) and uses it in the argument of the next expression.
  pvd*:CsParenthesizedVariableDesignation
  # very weird naming.
type CsDeclarationPattern* = ref object of Pattern
  gotType*:TypeNameDef
  svd*:CsSingleVariableDesignation

type CsDefaultExpression* = ref object of BodyExpr
  gotType*:TypeNameDef
type CsDefaultSwitchLabel* = ref object of CsObject
type CsDelegate* = ref object of CsObject
  # deleType*:CsPredefinedType
  gotType*:TypeNameDef
  paramList* :CsParameterList
  tplist*: CsTypeParameterList
  typeParamsConstraint*: CsTypeParameterConstraintClause
  ns*:CsNamespace
type CsDestructor* = ref object of CsObject
  body*: seq[BodyExpr]
  paramList*:CsParameterList

type CsDiscardDesignation* = ref object of CsObject
type CsDoStatement* = ref object of BodyExpr
  predicate*:BooleanExpr
  exprThatLeadsToBoolean*:BodyExpr
  predicatePartLit*:CsLiteralExpression
  body*: seq[BodyExpr]
  condTxt*:string

type CsElementAccessExpression* = ref object of BodyExpr
  lhs*:BodyExpr
  value*: CsBracketedArgumentList
  gotType*:TypeNameDef

<<<<<<< HEAD
type CsElementBindingExpression* = ref object of BodyExpr
  val*:BodyExpr
type CsElseClause* = ref object of CsObject
  body*: seq[BodyExpr]

type CsEmptyStatement* = ref object of BodyExpr
type CsEqualsValueClause* = ref object of BodyExpr
  value*: string
  rhsValue*: BodyExpr # IAssignable
  # mrhsValue*: IAssignable

type CsEventField* = ref object of CsObject
  thevar*:CsVariable #lhs

type CsEvent* = ref object of CsObject
  gotType*:TypeNameDef
  accList*:CsAccessorList
  explInterface*:CsExplicitInterfaceSpecifier

type CsExplicitInterfaceSpecifier* = ref object of CsObject
  genericName*: CsGenericName

=======
type CsClassOrStructConstraint* = ref object of CsObject #TODO(type:CsClassOrStructConstraint)
type CsConditionalAccessExpression* = ref object of CsObject #TODO(type:CsConditionalAccessExpression)
type CsConditionalExpression* = ref object of BodyExpr #TODO(type:CsConditionalExpression)
  body*: seq[GeneralBodyConstruct]

type CsConstantPattern* = ref object of CsObject #TODO(type:CsConstantPattern)
type CsConstructorConstraint* = ref object of CsObject #TODO(type:CsConstructorConstraint)
type CsContinueStatement* = ref object of CsObject #TODO(type:CsContinueStatement)
type CsConversionOperator* = ref object of CsObject #TODO(type:CsConversionOperator)
  body*: seq[GeneralBodyConstruct]

type CsDeclarationExpression* = ref object of CsObject #TODO(type:CsDeclarationExpression)
type CsDeclarationPattern* = ref object of CsObject #TODO(type:CsDeclarationPattern)
type CsDefaultExpression* = ref object of CsObject #TODO(type:CsDefaultExpression)
type CsDefaultSwitchLabel* = ref object of CsObject #TODO(type:CsDefaultSwitchLabel)
type CsDelegate* = ref object of CsObject #TODO(type:CsDelegate)
type CsDestructor* = ref object of CsObject #TODO(type:CsDestructor)
  body*: seq[GeneralBodyConstruct]

type CsDiscardDesignation* = ref object of CsObject #TODO(type:CsDiscardDesignation)
type CsDoStatement* = ref object of CsObject #TODO(type:CsDoStatement)

type CsElementAccessExpression* = ref object of BodyExpr #TODO(type:CsElementAccessExpression)
  value*: CsBracketedArgumentList
type CsElementBindingExpression* = ref object of CsObject #TODO(type:CsElementBindingExpression)
type CsElseClause* = ref object of CsObject #TODO(type:CsElseClause)
  body*: seq[GeneralBodyConstruct]

type CsEmptyStatement* = ref object of CsObject #TODO(type:CsEmptyStatement)
type CsEqualsValueClause* = ref object of CsObject
  value*: string
  rhsValue*: BodyExpr #GeneralBodyConstruct
type CsEventField* = ref object of CsObject #TODO(type:CsEventField)
type CsEvent* = ref object of CsObject #TODO(type:CsEvent)
type CsExplicitInterfaceSpecifier* = ref object of CsObject #TODO(type:CsExplicitInterfaceSpecifier)
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
type CsInvocationExpression* = ref object of BodyExpr
  gotType*:TypeNameDef
  callName*: string
  invoker*:BodyExpr
  rhs*:BodyExpr
  args*: CsArgumentList

type CsExpressionStatement* = ref object of BodyExpr
<<<<<<< HEAD
  body*: seq[BodyExpr]
  assign*: CsAssignmentExpression
  call*: CsInvocationExpression
  args*: CsArgumentList
  oce*:CsObjectCreationExpression
  expr*:BodyExpr

type CsFixedStatement* = ref object of BodyExpr
  expr*:BodyExpr # maybe store this first?
  body*: seq[BodyExpr]
type CsForEachStatement* = ref object of BodyExpr
  gotType*:TypeNameDef
  listPart*:BodyExpr
  body*: seq[BodyExpr]

type CsExternAliasDirective* = ref object of CsObject
type CsFinallyClause* = ref object of BodyExpr
  body*:seq[BodyExpr]

type CsForEachVariableStatement* = ref object of BodyExpr
  gotType*:TypeNameDef
  varDecl*:CsDeclarationExpression
  listPart*:BodyExpr
  body*: seq[BodyExpr]

type CsForStatement* = ref object of BodyExpr
  forPart1*: BodyExpr # CsAssignmentExpression or CsInvocationExpression
  forPart1var*:CsVariable
  forPart2*: CsBinaryExpression
  forPart2AsPattern*: CsIsPatternExpression
  forPart3*: CsPostfixUnaryExpression
  forPart3prefix*: CsPrefixUnaryExpression # fix these kinds of things with interfaces.
  gotType*:TypeNameDef
  body*: seq[BodyExpr]

type CsFromClause* = ref object of CsObject
  gotType*:TypeNameDef
  withMember*:CsMemberAccessExpression
  itemsAlias*:string
  inPart*:BodyExpr # in part


type CsGlobalStatement* = ref object of CsObject
type CsGotoStatement* = ref object of BodyExpr
  gotoCase*: CsLiteralExpression

type CsGroupClause* = ref object of CsObject
  withMember*:CsMemberAccessExpression

type CsIfStatement* = ref object of BodyExpr
  predicate*:BooleanExpr
  exprThatLeadsToBoolean*:BodyExpr
  predicatePartLit*:CsLiteralExpression
  body*: seq[BodyExpr]
  melse*: CsElseClause

  condTxt* : string
  statementsTxt* : string
  elseTxt* : string

type CsImplicitArrayCreationExpression* = ref object of BodyExpr
  initExpr*:CsInitializerExpression
type CsImplicitElementAccess* = ref object of BodyExpr
  args*:CsBracketedArgumentList
type CsIncompleteMember* = ref object of CsObject
  gotType*:TypeNameDef
  attributeLists,modifiers:float64
type CsPredefinedType* = ref object of TypeNameDef
  keyword*:string
type CsPrefixUnaryExpression* = ref object of BooleanExpr # because can have the ! (not) operator.
  gotType*:TypeNameDef
  prefix*: string     # convert to Nim's meaning, sometimes the ops are the same, sometimes different. prepend it, without space if literal, and with - otherwise.
  actingOn*: BodyExpr
=======
  body*: seq[GeneralBodyConstruct]

  call*: CsInvocationExpression
  args*: CsArgumentList
type CsExternAliasDirective* = ref object of CsObject #TODO(type:CsExternAliasDirective)
type CsFinallyClause* = ref object of CsObject #TODO(type:CsFinallyClause)
type CsFixedStatement* = ref object of CsObject #TODO(type:CsFixedStatement)
type CsForEachStatement* = ref object of CsObject #TODO(type:CsForEachStatement)
  body*: seq[GeneralBodyConstruct]


type CsForEachVariableStatement* = ref object of CsObject #TODO(type:CsForEachVariableStatement)
type CsForStatement* = ref object of CsObject #TODO(type:CsForStatement)
  body*: seq[GeneralBodyConstruct]

type CsFromClause* = ref object of CsObject #TODO(type:CsFromClause)



type CsGlobalStatement* = ref object of CsObject #TODO(type:CsGlobalStatement)
type CsGotoStatement* = ref object of CsObject #TODO(type:CsGotoStatement)

type CsGroupClause* = ref object of CsObject #TODO(type:CsGroupClause)
type CsIfStatement* = ref object of BodyExpr #TODO(type:CsIfStatement)
  body*: seq[GeneralBodyConstruct]


type CsImplicitArrayCreationExpression*
  = ref object of CsObject #TODO(type:CsImplicitArrayCreationExpression)
type CsImplicitElementAccess* = ref object of CsObject #TODO(type:CsImplicitElementAccess)
type CsIncompleteMember* = ref object of CsObject #TODO(type:CsIncompleteMember)
type CsPredefinedType* = ref object of CsObject
type CsPrefixUnaryExpression* = ref object of BodyExpr
  prefix*: string     # don't handle it in any special way, prepend it, without space if literal, and with - otherwise.
  actingOn*: CsObject # actually: CsLiteral, invocationexpression, objectcreationexpr, memberaccessexpr, parenthesizedexpr, cscastexpr
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
  expectedActingOn*: string
type CsLiteralExpression* = ref object of IAssignable
  value*: string
type CsInitializerExpression* = ref object of BodyExpr
  gotType*:TypeNameDef
  valueReceived*: string
  bexprs*: seq[BodyExpr]
<<<<<<< HEAD
  # body*: seq[BodyExpr]




type CsTypeParameterList* = ref object of CsObject
  theTypes*: seq[CsTypeParameter]

type CsInterface* = ref object of CsObject
  properties*:seq[CsProperty]
  methods*:seq[CsMethod]
  events*:seq[CsEventField]
  fields*:seq[CsField]
  typeParams*:CsTypeParameterList
  typeParamsConstraint*: CsTypeParameterConstraintClause
  extends*:CsBaseList
  ns*:CsNamespace
  indexers*:seq[CsIndexer]

type CsInterpolatedStringText* = ref object of CsObject
type CsInterpolatedStringExpression* = ref object of BodyExpr
  interpolated*:CsInterpolation
  textPart*:CsInterpolatedStringText
type CsInterpolationAlignmentClause* = ref object of CsObject
  number*:CsLiteralExpression
type CsInterpolationFormatClause* = ref object of CsObject
type CsInterpolation* = ref object of CsObject
  gotType*:TypeNameDef
  expr*:BodyExpr
  format*:CsInterpolationFormatClause
  align*:CsInterpolationAlignmentClause

type CsIsPatternExpression* = ref object of BooleanExpr
  lhs*:BodyExpr
  rhs*:Pattern
  rhsExpr*:BodyExpr

type CsJoinClause* = ref object of CsObject
  gotType*:TypeNameDef
  inPart*:BodyExpr # in part
  onPart*:BodyExpr
  into*:CsJoinIntoClause

type CsJoinIntoClause* = ref object of CsObject
type CsLabeledStatement* = ref object of BodyExpr
  body*: seq[BodyExpr]


type CsLetClause* = ref object of BodyExpr
  varName*:string
  value*:BodyExpr

type CsLocalFunctionStatement* = ref object of BodyExpr
  locals*:seq[CsLocalDeclarationStatement]
  gotType*:TypeNameDef
  paramList*:CsParameterList
  body*:seq[BodyExpr]
type CsLockStatement* = ref object of BodyExpr
  locker*:BodyExpr
  body*: seq[BodyExpr]

=======
  body*: seq[GeneralBodyConstruct]

type CsInterface* = ref object of CsObject #TODO(type:CsInterface)
type CsInterpolatedStringExpression* = ref object of BodyExpr #TODO(type:CsInterpolatedStringExpression)
type CsInterpolatedStringText* = ref object of CsObject #TODO(type:CsInterpolatedStringText)
type CsInterpolationAlignmentClause* = ref object of CsObject #TODO(type:CsInterpolationAlignmentClause)
type CsInterpolationFormatClause* = ref object of CsObject #TODO(type:CsInterpolationFormatClause)
type CsInterpolation* = ref object of CsObject #TODO(type:CsInterpolation)
type CsIsPatternExpression* = ref object of CsObject #TODO(type:CsIsPatternExpression)
type CsJoinClause* = ref object of CsObject #TODO(type:CsJoinClause)
type CsJoinIntoClause* = ref object of CsObject #TODO(type:CsJoinIntoClause)
type CsLabeledStatement* = ref object of CsObject #TODO(type:CsLabeledStatement)
  body*: seq[GeneralBodyConstruct]


type CsLetClause* = ref object of CsObject #TODO(type:CsLetClause)
type CsLocalFunctionStatement* = ref object of CsObject #TODO(type:CsLocalFunctionStatement)
type CsLockStatement* = ref object of CsObject #TODO(type:CsLockStatement)
  body*: seq[GeneralBodyConstruct]


type CsMakeRefExpression* = ref object of CsObject #TODO(type:CsMakeRefExpression)
type CsMemberBindingExpression* = ref object of CsObject #TODO(type:CsMemberBindingExpression)
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3

type CsMakeRefExpression* = ref object of BodyExpr
type CsMemberBindingExpression* = ref object of BodyExpr
  genericName*:CsGenericName
type CsObjectCreationExpression* = ref object of IAssignable
  gotType*:TypeNameDef
  typeName*: string           # args*: CsParameterList
  genericName*: CsGenericName # replaces typeName perhaps.
  args*: CsArgumentList
  initExpr*: CsInitializerExpression

type CsVariableDeclarator* = ref object of BodyExpr # I assume this is the right hand side, what the variable is stored with.
  ev*: CsEqualsValueClause                          # so i can get (with its parentid) the expression statement which is the right hand side, afterwards.
  rhs*: IAssignable
  arglist*: CsArgumentList
  bracketedArgumentList*: CsBracketedArgumentList
  binaryExpression,memberAccessExpression,objectCreationExpression : float64
type CsReturnStatement* = ref object of BodyExpr # type:CsReturnStatement
<<<<<<< HEAD
  body*: seq[BodyExpr]
=======
  body*: seq[GeneralBodyConstruct]
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
  args*: CsArgumentList
  expr*: BodyExpr                 # can have one expr that can be nil
  value*: string
type CsNameColon* = ref object of BodyExpr
type CsNameEquals* = ref object of CsObject
  genericName*: CsGenericName
type CsUsingDirective* = ref object of CsObject
  alias*: CsNameEquals
  hasStaticKeyword*:bool
  aliasQualifiedName*:CsAliasQualifiedName
  genericName*:CsGenericName
  literalExpression : float64



type CsNamespace* = ref object of CsObject
  # id*: UUID
  parent*: string
  classes*: seq[CsClass]
  classTable*: TableRef[string, CsClass]
  enums*: seq[CsEnum]
  enumTable*: TableRef[string, CsEnum]
  interfaces*: seq[CsInterface]
  interfaceTable*: TableRef[string, CsInterface]
<<<<<<< HEAD
  lastAddedTo*: Option[NamespaceParts]
=======
  lastAddedTo*: Option[NamespaceParts] # TODO: !!! we actually want here an object variant, so we can simply ask for the object.
                                       # lastAdded: Construct
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
  imports*: seq[CsUsingDirective]

  delegates*:seq[CsDelegate]
  structs*:seq[CsStruct]
  events*:seq[CsEvent]
  operator,conversionOperator:float64

type CsEnum* = ref object of CsObject
  ns*:CsNamespace
  modifiers*: seq[string]
  underlyingType*:CsBaseList
  items*: seq[CsEnumMember]

type AllNeededData* = object
  sourceCode*: string
  upcoming*: seq[string]
  constructDeclName*: string
  simplified*: seq[(string, UUID)]
  currentNamespace*: CsNamespace
  nsLastAdded*: NamespaceParts
  classLastAdded*: ClassParts
  lastUsing*: CsUsingDirective
  lastEnum*: CsEnum
  lastEnumMember*: CsEnumMember
  lastInterface*: CsInterface
  lastClass*: CsClass
  lastMethod*: CsMethod
  lastProp*: CsProperty
  lastCtor*: CsConstructor
  lastMethodBodyExpr*: BodyExpr
  lastBodyExprId*: Option[UUID]
  lastBodyExpr*: Option[BodyExpr]
  inBlock*: Block
  prevBlock*: Block
  currentConstruct*: Option[Block]
  previousConstruct*: Option[Block]
  previousPreviousConstruct*: Option[Block]
<<<<<<< HEAD
type CsNullableType* = ref object of TypeNameDef
  gotType*: TypeNameDef

type CsOmittedArraySizeExpression* = ref object of BodyExpr
type CsOmittedTypeArgument* = ref object of TypeNameDef
type CsOperator* = ref object of CsObject
  gotType*:TypeNameDef
  paramList*:CsParameterList
  body*: seq[BodyExpr]

type CsOrderByClause* = ref object of CsObject
  ordering*:CsOrdering
type CsOrdering* = ref object of CsObject
  value*: CsMemberAccessExpression #BodyExpr ??

type CsParenthesizedExpression* = ref object of BodyExpr
  gotType*:TypeNameDef
  body*: seq[BodyExpr] # usually (always?) just one expr.

type CsParenthesizedLambdaExpression* = ref object of BodyExpr
  paramList*:CsParameterList
  body*: seq[BodyExpr]

type CsParenthesizedVariableDesignation* = ref object of BodyExpr
  val*:CsSingleVariableDesignation
  dis*:CsDiscardDesignation
type CsPointerType* = ref object of TypeNameDef
  gotType*:TypeNameDef
type CsPostfixUnaryExpression* = ref object of BodyExpr
  postfix*: string
  actingOn*: BodyExpr

type CsIdentifier* = ref object of BodyExpr
type CsRefExpression* = ref object of BodyExpr
  expr*:BodyExpr

type CsQueryExpression* = ref object of BodyExpr
  fromClause*:CsFromClause
  queryBody*:CsQueryBody

type CsRefType* = ref object of TypeNameDef
  gotType*:TypeNameDef
type CsRefValueExpression* = ref object of BodyExpr
  invokeExpr*:CsInvocationExpression
  gotType*:TypeNameDef
type CsRefTypeExpression* = ref object of BodyExpr

type CsQueryBody* = ref object of CsObject
  orderBy*:CsOrderByClause
  join*:CsJoinClause
  selectClause*:CsSelectClause
  fromClause*:CsFromClause
  group*:CsGroupClause
  cont*:CsQueryContinuation
  where*:CsWhereClause
  letClause*:CsLetClause

type CsQueryContinuation* = ref object of CsObject
  queryBody*:CsQueryBody
type CsSelectClause* = ref object of CsObject
  withMember*: CsMemberAccessExpression
  expr*:BodyExpr
  newQuery*:CsQueryExpression

type CsSimpleLambdaExpression* = ref object of BodyExpr
  params*:seq[CsParameter]
  body*: seq[BodyExpr]

type CsSingleVariableDesignation* = ref object of CsObject
type CsSizeOfExpression* = ref object of BodyExpr
  gotType*:TypeNameDef
type CsStackAllocArrayCreationExpression*  = ref object of BodyExpr
  gotType*:TypeNameDef

type CsStruct* = ref object of CsObject
  typeParams*: CsTypeParameterList
  typeParamsConstraint*: CsTypeParameterConstraintClause
  baseList*:CsBaseList
  fields*:seq[CsField]
  properties*:seq[CsProperty]
  ctors*:seq[CsConstructor]
  eventFields*:seq[CsEventField]
  methods*:seq[CsMethod]
  operators*:seq[CsOperator]
  convOps*:seq[CsConversionOperator]
  indexers*:seq[CsIndexer]
  delegates*:seq[CsDelegate]
  ns*:CsNamespace
  dtors*:seq[CsDestructor]


type CsSwitchSection* = ref object of CsObject
  caseName*:CsCaseSwitchLabel
  casePattern*:CsCasePatternSwitchLabel
  body*:seq[BodyExpr]
  isDefault:bool
  default*:CsDefaultSwitchLabel

type CsSwitchStatement* = ref object of BodyExpr
  on*:BodyExpr
  sections*:seq[CsSwitchSection]
  # body*: seq[BodyExpr]

type CsThisExpression* = ref object of BodyExpr
type CsThrowExpression* = ref object of BodyExpr
  expr*:BodyExpr
type CsThrowStatement* = ref object of BodyExpr
  body*: seq[BodyExpr]

type CsTryStatement* = ref object of BodyExpr
  body*: seq[BodyExpr]
  mfinally*:CsFinallyClause
  catches*:seq[CsCatchClause]
  mfinallyTxt*, catchesTxt*:string

type CsTupleElement* = ref object of CsObject
  gotType*:TypeNameDef
type CsTupleExpression* = ref object of BodyExpr
  args*:seq[CsArgument]
type CsTupleType* = ref object of TypeNameDef
  elems*:seq[CsTupleElement]
type CsTypeConstraint* = ref object of Constraint
  gotType*:TypeNameDef
type CsTypeOfExpression* = ref object of BodyExpr
  gotType*:TypeNameDef
type CsTypeParameterConstraintClause* = ref object of BodyExpr
  constraints*:seq[Constraint]


type CsUnsafeStatement* = ref object of BodyExpr
type CsUsingStatement* = ref object of BodyExpr
  # variable*:CsVariable
  variable*:BodyExpr
  body*: seq[BodyExpr]


type CsWhenClause* = ref object of CsObject

type ControlFlowExpression = ref object of BodyExpr
  condTxt : string
  # statementsTxt : string
  # elseTxt : string
  predicate*:BooleanExpr
  exprThatLeadsToBoolean*:BodyExpr
  predicatePartLit*:CsLiteralExpression


type CsWhereClause* = ref object of ControlFlowExpression #CsObject
  # predicate*:BooleanExpr
  # exprThatLeadsToBoolean*:BodyExpr
  # predicatePartLit*:CsLiteralExpression
  expr*:BodyExpr
type CsWhileStatement* = ref object of BodyExpr
  body*: seq[BodyExpr]
  predicate*:BooleanExpr
  exprThatLeadsToBoolean*:BodyExpr
  predicatePartLit*:CsLiteralExpression
  condTxt*:string

proc hasNoPredicate*(c:CsWhereClause|CsWhileStatement|CsDoStatement|CsIfStatement|CsConditionalExpression|CsCatchFilterClause):bool =
  result = c.predicate.isNil and c.exprThatLeadsToBoolean.isNil and c.predicatePartLit.isNil #and c.condTxt.len == 0

type CsYieldStatement* = ref object of BodyExpr
  expr*: BodyExpr

=======
type CsNullableType* = ref object of CsObject #TODO(type:CsNullableType)
type CsOmittedArraySizeExpression* = ref object of CsObject #TODO(type:CsOmittedArraySizeExpression)
type CsOmittedTypeArgument* = ref object of CsObject #TODO(type:CsOmittedTypeArgument)
type CsOperator* = ref object of CsObject #TODO(type:CsOperator)
  body*: seq[GeneralBodyConstruct]

type CsOrderByClause* = ref object of CsObject #TODO(type:CsOrderByClause)
type CsOrdering* = ref object of CsObject #TODO(type:CsOrdering)
type CsParenthesizedExpression* = ref object of BodyExpr #TODO(type:CsParenthesizedExpression)
  body*: seq[GeneralBodyConstruct]

type CsParenthesizedLambdaExpression* = ref object of BodyExpr #TODO(type:CsParenthesizedLambdaExpression)
  body*: seq[GeneralBodyConstruct]

type CsParenthesizedVariableDesignation*
  = ref object of CsObject #TODO(type:CsParenthesizedVariableDesignation)
type CsPointerType* = ref object of CsObject #TODO(type:CsPointerType)
type CsPostfixUnaryExpression* = ref object of CsObject #TODO(type:CsPostfixUnaryExpression)
type CsQueryBody* = ref object of CsObject #TODO(type:CsQueryBody)
type CsQueryContinuation* = ref object of CsObject #TODO(type:CsQueryContinuation)
type CsQueryExpression* = ref object of CsObject #TODO(type:CsQueryExpression)
type CsRefExpression* = ref object of CsObject #TODO(type:CsRefExpression)
type CsRefTypeExpression* = ref object of CsObject #TODO(type:CsRefTypeExpression)
type CsRefType* = ref object of CsObject #TODO(type:CsRefType)
type CsRefValueExpression* = ref object of CsObject #TODO(type:CsRefValueExpression)
type CsSelectClause* = ref object of CsObject #TODO(type:CsSelectClause)
                                              # body*:seq[GeneralBodyConstruct]

type CsSimpleLambdaExpression* = ref object of BodyExpr #TODO(type:CsSimpleLambdaExpression)
  body*: seq[BodyExpr]

type CsSingleVariableDesignation* = ref object of CsObject #TODO(type:CsSingleVariableDesignation)
type CsSizeOfExpression* = ref object of CsObject #TODO(type:CsSizeOfExpression)
type CsStackAllocArrayCreationExpression*
  = ref object of CsObject #TODO(type:CsStackAllocArrayCreationExpression)
type CsStruct* = ref object of CsObject #TODO(type:CsStruct)
type CsSwitchSection* = ref object of CsObject #TODO(type:CsSwitchSection)
  body*: seq[GeneralBodyConstruct]

type CsSwitchStatement* = ref object of CsObject #TODO(type:CsSwitchStatement)
  body*: seq[GeneralBodyConstruct]


type CsThisExpression* = ref object of CsObject #TODO(type:CsThisExpression)
type CsThrowExpression* = ref object of CsObject #TODO(type:CsThrowExpression)
type CsThrowStatement* = ref object of CsObject #TODO(type:CsThrowStatement)
  body*: seq[GeneralBodyConstruct]

type CsTryStatement* = ref object of CsObject #TODO(type:CsTryStatement)
  body*: seq[GeneralBodyConstruct]

type CsTupleElement* = ref object of CsObject #TODO(type:CsTupleElement)
type CsTupleExpression* = ref object of CsObject #TODO(type:CsTupleExpression)
type CsTupleType* = ref object of CsObject #TODO(type:CsTupleType)
type CsTypeConstraint* = ref object of CsObject #TODO(type:CsTypeConstraint)
type CsTypeOfExpression* = ref object of BodyExpr #TODO(type:CsTypeOfExpression)
type CsTypeParameterConstraintClause* = ref object of CsObject #TODO(type:CsTypeParameterConstraintClause)

type CsTypeParameterList* = ref object of CsObject
  theTypes*: seq[CsTypeParameter]
type CsUnsafeStatement* = ref object of CsObject #TODO(type:CsUnsafeStatement)
type CsUsingStatement* = ref object of CsObject #TODO(type:CsUsingStatement)
  body*: seq[GeneralBodyConstruct]


type CsWhenClause* = ref object of CsObject #TODO(type:CsWhenClause)
type CsWhereClause* = ref object of CsObject #TODO(type:CsWhereClause)
type CsWhileStatement* = ref object of CsObject #TODO(type:CsWhileStatement)
  body*: seq[GeneralBodyConstruct]


type CsYieldStatement* = ref object of CsObject #TODO(type:CsYieldStatement)
  body*: seq[GeneralBodyConstruct]

>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
type CsBlock* = ref object of CsObject
type CsVariable* = ref object of BodyExpr # self is lhs
  # name*:string
  thetype*: string
  gotType*:TypeNameDef
  # nulType*:CsNullableType #?
  # arrType*:CsArrayType #?
  genericName*: CsGenericName
  declarator*: CsVariableDeclarator # this is the rhs
  # ?? where do all these come from? where do they get stored?
  refType,functionPointerType,pointerType,tupleType,arrayType,nullableType : float64
  aliasQualifiedName*: CsAliasQualifiedName
type CsLocalDeclarationStatement* = ref object of BodyExpr
  names*: seq[string]
  vartype*: string
  lhs*: CsVariable #?           # lhs = left hand side, rhs = right hand side.
  rhs*: CsVariableDeclarator #? # which has what's after the equals-value-clause.
  variable,genericName,typeArgumentList,variableDeclarator,argumentList,literalExpression,localFunctionStatement : float64
  # which parts are always there as part of the structure and which are dynamic values?


type CsBinaryPattern* = ref object of Pattern
type CsDiscardPattern* = ref object of Pattern
type CsFunctionPointerType* = ref object of TypeNameDef
type CsImplicitObjectCreationExpression* = ref object of BodyExpr
  args*:CsArgumentList

<<<<<<< HEAD
=======

type CsBinaryPattern* = ref object of CsObject
type CsDiscardPattern* = ref object of CsObject
type CsFunctionPointerType* = ref object of CsObject
type CsImplicitObjectCreationExpression* = ref object of CsObject
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
type CsMemberAccessExpression* = ref object of IAssignable
  fromPart*: string
  genericName*:CsGenericName
  leftAsType*:TypeNameDef
  left*:BodyExpr
  optoken*:string
  member*: string
  right*:BodyExpr

type CsRangeExpression* = ref object of BodyExpr
  items*: seq[BodyExpr]
  fromStr*, toStr*:string

type CsPrimaryConstructorBaseType* = ref object of TypeNameDef
type CsSwitchExpression* = ref object of BodyExpr
  on*:BodyExpr
  arm*:CsSwitchExpressionArm

type CsParenthesizedPattern* = ref object of Pattern

type CsPositionalPatternClause* = ref object of PatternClause

type CsPropertyPatternClause* = ref object of PatternClause

type CsRecord* = ref object of CsObject
<<<<<<< HEAD

type CsRecursivePattern* = ref object of Pattern
  pat*:PatternClause

type CsRelationalPattern* = ref object of Pattern
type CsSubpattern* = ref object of Pattern
  pat*:Pattern
  namecolon*:CsNameColon
type CsSwitchExpressionArm* = ref object of BodyExpr
  pat*:Pattern
  body*: seq[BodyExpr]
  assignable*:IAssignable

type CsTypePattern* = ref object of Pattern
  gotType*:TypeNameDef
type CsWithExpression* = ref object of BodyExpr

type CsUnaryPattern* = ref object of Pattern
  pattern*:Pattern
type CsVarPattern* = ref object of Pattern
type CsImplicitStackAllocArrayCreationExpression* = ref object of CsObject

include ../info_center_inc
include ../construct_inc
type CsRoot* = object
  global*: CsNamespace
  infoCenter*: InfoCenter
  ns*: HashSet[CsNamespace]
  nsTables*: TableRef[string, CsNamespace]

var currentRoot*: CsRoot
=======
type CsRecursivePattern* = ref object of CsObject
type CsRelationalPattern* = ref object of CsObject
type CsSubpattern* = ref object of CsObject
type CsSwitchExpression* = ref object of CsObject
type CsSwitchExpressionArm* = ref object of CsObject
  body*: seq[GeneralBodyConstruct]

type CsTypePattern* = ref object of CsObject
type CsUnaryPattern* = ref object of CsObject
type CsVarPattern* = ref object of CsObject
type CsWithExpression* = ref object of CsObject
type CsImplicitStackAllocArrayCreationExpression* = ref object of CsObject

proc matchesGeneralBodyConstruct(this: CsBinaryExpression|CsArrayCreationExpression|CsGotoStatement|CsLabeledStatement|CsSwitchStatement|CsReturnStatement|CsIfStatement|CsElseClause|CsForStatement|CsDoStatement|CsCastExpression|CsWhileStatement|CsAssignmentExpression|CsForEachStatement|CsUsingStatement|CsLockStatement|CsCheckedStatement|CsAssignmentExpression|CsLocalDeclarationStatement|CsTryStatement): bool = true
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
