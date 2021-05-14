import nre, hashes, sets, sequtils, tables, uuids, options #, strutils
import cs_all_constructs, justtypes, ../types
# ============= CsRoot ========
# global.nim




proc newCs*(t: typedesc[CsRoot]): CsRoot =
  # new result
  result.ns = initHashSet[CsNamespace]()
  result.nsTables = newTable[string, CsNamespace]()
  let id = some(genUUID()) # default gets a special assignment here because it is built in and doesn't go thru lineparser.
  let defaultNs = newCs(CsNamespace, "default")
  defaultNs.id = id
  result.global = defaultNs
  # echo $defaultNs.id.get
  result.nsTables["default"] = defaultNs
  result.infoCenter = newInfoCenter()
  result.infoCenter.register(id.get, Construct(kind: ckNamespace, namespace: defaultNs))



proc register*(r: var CsRoot; id: UUID; obj: Construct) =
  assert not id.isZero
  r.infoCenter.register(id, obj)

proc fetch*(r: var CsRoot; id: UUID): Option[Construct] =
  result = r.infoCenter.fetch(id)


proc makeModule*(ns: CsNamespace; gl: GenLang): Module =
  var name: string
  if ns.parent.len > 0:
    name = ns.parent & "." & ns.name
  else:
    name = ns.name
  var output =
    case gl
    of glNim: ns.genNim()
    of glCSharp: ns.genCs()
  output &= "\n\n"
  output = output.replace(re"\n{2,}", "\n\n")

  result = Module(name: name, output: output)

proc isEmpty(c:CsNamespace):bool =
  c.name == "default" and
    c.classes.len == 0 and
    c.enums.len == 0 and
    c.imports.len == 0 and
    c.interfaces.len == 0 and
    c.delegates.len == 0 and
    c.structs.len == 0 and
    c.events.len == 0
proc gen*(r: CsRoot; gl: GenLang): seq[Module] =
  if not r.global.isNil:
    if not r.global.isEmpty:
      result.add makeModule(r.global, gl)

  for n in r.ns:
    echo "in gen(): ns is: " & $n.name
    assert r.nsTables.hasKey(n.name), n.name & "is missing"
    result.add makeModule(n, gl)

proc hash*(it:CsNamespace): Hash =
  hash(it.name)

proc add*(root: var CsRoot; csn: CsNamespace) =
  var name: string
  echo csn.name

  if csn.parent != "":
    name = csn.parent & "." & csn.name
    csn.parent = ""
    csn.name = name
  else: name = csn.name

  if root.ns.allIt(it.name != csn.name):
    root.ns.incl(csn)
    root.nsTables[csn.name] = csn

  echo root.ns.toSeq.mapIt(it.name)
  # assert false
