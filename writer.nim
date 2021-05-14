# writer.nim
import system, strutils, os
import writer_utils #, state
import constructs/cs_root
import constructs/justtypes

import types

import argparse
proc main() =

  var p = newParser("cs2nim"):
    help("translates C# to Nim, generates Nim code from csast files. Use with CsDisplay app first.")
    option("-l", "--lang", choices = @["csharp", "nim"])
    arg("input") # the file or directory passed.

  echo "Hello world!"
  let params = commandLineParams()
  let opts = p.parse(params)
  if opts.input.isEmptyOrWhitespace:
    quit("Please pass a file or directory")
  var gl :GenLang
  case opts.lang
    of "nim": gl = glNim
    of "csharp" : gl = glCSharp
  if params.len == 0:
    quit("Please pass a file (*.csast) or directory containing such files")
  else:
    var fi = params[0]
    var files: seq[string] = @[]
    if fileExists(fi) and fi.endsWith(".csast"):
      files.add fi
    elif fi.dirExists():
      # for file in walkFiles(joinPath(fi, "**/*.csast")):
      files = getCsastFiles(fi)
    else: quit("could not find matching or existing file or directory: " & fi)

    echo files.len
    let inputFolder = fi
    if safer:
      for f in files:
        var root = newCs(CsRoot) # new root each time.
        justtypes.currentRoot = root
        handleJustOne(inputfolder, root, f)
        writeAll(inputFolder, root,gl)

    else:
      var root = newCs(CsRoot) # only one root to collect all the namespaces.
      justtypes.currentRoot = root

      handleMany(fi, root, files)
      writeAll(inputFolder, root, gl)
    echo "finished: " & inputFolder

main()
