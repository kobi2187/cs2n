type GenLang* = enum glNim, glCSharp

template fail() =
  assert false

# TODO: change code, so eachone has a distinction of real progress.
template todoimplAdd* =
  const pos = instantiationInfo()
  const line = $pos.filename & ":" & $pos.line
  const warningMsg = "unimplemented(" & "add" & "): " & line
  when defined(failFastAdd):
    {.error: warningMsg.}
  elif defined(stopFastAdd):
    {.warning: warningMsg.}
    fail
  else:
    {.warning: warningMsg.}
template todoimplGen* =
  const pos = instantiationInfo()
  const line = $pos.filename & ":" & $pos.line
  const warningMsg = "unimplemented(" & "gen" & "): " & line
  when defined(failFastGen):
    {.error: warningMsg.}
  elif defined(stopFastGen):
    {.warning: warningMsg.}
    fail
  else:
    {.warning: warningMsg.}

template todoimpl*(area:string = "") =
  const pos = instantiationInfo()
  const line = $pos.filename & ":" & $pos.line
  const warningMsg = "unimplemented(" & area & "): " & line
  when defined(failFast):
    {.error: warningMsg.}
  elif defined(stopFast):
    {.warning: warningMsg.}
    fail
  else:
    {.warning: warningMsg.}

import json

type Info* = ref object
  declName*: string
  essentials*: seq[string]
  extras*: seq[string]
  rawKind*, parentRawKind*: int

import strutils
proc `$`*(info: Info): string =
  let x = [info.declName, $info.essentials, $info.extras]
  result = "Info: " & x.join(";; ")

import uuids, options
type CsObject* = ref object of RootRef
  name*: string
  typ*: string
  id*: Option[UUID]
  parentId*: Option[UUID]
  # line*: JsonNode
  src*: string
  isComplete*: bool
  rawKind*, parentRawKind*: int



# type Dummy* = ref object of CsObject

type Module* = object
  name*: string
  output*: string

proc jsonWithoutSource*(n: JsonNode): JsonNode =
  var p = n.deepCopy
  p.delete("Source")
  result = p

# for constructs in a method body.
type CsIdentifier* = ref object of CsObject
type BodyExpr* = ref object of CsObject 
  ident*:CsIdentifier
  ttype*: string


type TypeNameDef* = ref object of BodyExpr # CsObject


method genCs*(e: CsObject): string {.base.} =
  echo "--> in genCs*(e: BodyExpr): string {.base.} ="
  assert false, e.typ & " does not implement genCs() - fix missing impl"

method genNim*(e: CsObject): string {.base.} =
  raise newException(Exception, "Not Implemented for " &
      e.typ) #& " " & e.name)

# # possibly redundant. haven't yet used:
# type CConstruct* = concept T, Parent
#   proc add*(parent: var Parent; item: T; data: AllNeededData)
#   proc add*(parent: var Parent; item: T)
#   proc extract*(t: typedesc[T]; info: Info): T
#   proc newCs*(t: typedesc[T]; a, b, c, d: auto): T
#   # proc handle*(t: typedesc[T]; root: var CsRoot; info: Info)
#   # will it create a circular dependency? maybe. try.

