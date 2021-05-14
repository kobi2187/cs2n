<<<<<<< HEAD
import system, os, osproc, strutils
=======
import system, os, osproc
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
import ../types, uuids, options, ../writer_utils,
    ../constructs/[cs_all_constructs,cs_root,justtypes]
import sugar

proc getMonoTests*():seq[string] =
  let dir= "/home/kobi7/currentWork/cs2nim/tests/samples/monotests/tests"
  for a in walkDirRec(dir):
    if a.endsWith(".cs"):
      result.add a

import sequtils
proc nsToFolders*(namespaces: seq[string],gl:GenLang): seq[string] =
  result = namespaces.mapIt(".".mkModuleFilename(it,gl))

import ../constructs/cs_root
proc handleFiles(files: seq[string];gl:GenLang): string =
  # generates an output string from files processed into tree
  var tree = newCs(CsRoot)
  processFiles(tree, files)
  var ls = tree.gen(gl)
  result = concatModulesOutput(ls)

import strutils,nre

proc normalizeCs(s:string) :string =
  let spaceBeforeChars = re"\s+([{,=:}])"
  let spaceAfterChars = re"([{,=:}])\s+"
  let doubleSpaces = re"\s{2,}"
  result = s
  result = result.replace(doubleSpaces," ")
  # if result.find(spaceAroundChars).isSome:
  result = result.replace(spaceBeforeChars,(m:RegexMatch) => m.captures[0])
  result = result.replace(spaceAfterChars,(m:RegexMatch) => m.captures[0])


# for tests, we assume we will only use one file as output. that is, a correct nim generated file.
# i/o tests have the namespace to files test.
<<<<<<< HEAD


proc genTest*(file: string, hasDir=false, gl:GenLang = glNim): bool =
=======
proc genTest*(file: string, hasDir=false): bool =
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
  var
    filename = ""
    dir = ""
    outp = ""
    src = ""
<<<<<<< HEAD
  let ext = case gl
    of glNim: ".nim"
    of glCSharp: ".precs"
=======
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
  if hasDir:
    dir = file.parentDir()
    filename = file.changeFileExt("")
    src = filename & ".csast"
<<<<<<< HEAD
    outp = filename & ext
  else:
    let pwd = getCurrentDir()
    dir = pwd / "tests/samples"
    filename = file.changeFileExt("")
    # filename = file
=======
    outp = filename & ".nim"
  else:
    let pwd = getCurrentDir()
    dir = pwd / "tests/samples"
    filename = file
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
    src = dir / filename & ".csast"
    outp = dir / filename & ext

  echo dir
  discard execCmd("dotnet /home/kobi7/currentWork/CsDisplay/bin/Release/netcoreapp2.2/CsDisplay.dll " & src.changeFileExt(".cs"))

  if not dirExists(dir):
    echo "directory `" & dir & "` does not exist"
    return false
  if not fileExists(src):
    echo "file `" & src & "` does not exist"
    discard execCmd("dotnet /home/kobi7/currentWork/CsDisplay/bin/Release/netcoreapp2.2/CsDisplay.dll " & src.changeFileExt(".cs"))
    # return false
  if not fileExists(outp):
<<<<<<< HEAD
    echo "file `" & outp & "` does not exist, creating an empty one"
    discard execCmd("mkdir -p " & outp.parentDir)
    discard execCmd("touch " & outp)
    # return false
=======
    echo "file `" & outp & "` does not exist"
    discard execCmd("touch " & outp)
    return false
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
# lkj
  var contents = readFile(outp).strip
  var gen = handleFiles(@[src],gl).strip.replace("\r\n", "\n")
  if gl == glCSharp: # in this case, we are not interested in beauty.
    echo "normalizing outputs"
    contents = normalizeCs(contents)
    gen =normalizeCs(gen)
  if contents != gen:
    echo "expected: `" & contents & "`"
    echo "got: `" & gen & "`"
    writeFile("/tmp/expected", contents)
    writeFile("/tmp/got", gen)
    discard execShellCmd("diff -a -d --color=always /tmp/got /tmp/expected")
  else: echo "got:",gen
  echo outp
  return contents == gen
