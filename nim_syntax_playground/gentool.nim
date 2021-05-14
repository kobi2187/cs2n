# gentool.nim

import system,os, nre, times, osproc, streams, strutils

const noerrFile = "/home/kobi7/More_CS_Libs_and_Apps/no_gen_errors.txt"

proc runWriter(line:string): string =
  var res = ""
  var process :Process
  var outp :Stream
  const cwd = "/home/kobi7/currentWork/cs2nim"
  var ln = newStringOfCap(200)
  try:
    process = startProcess("/home/kobi7/currentWork/cs2nim/writer", workingDir = cwd, args = [line], options = {poStdErrToStdOut, poUsePath})
    outp= outputStream(process)
    while running(process):
      if outp.readLine(ln):
        res.add(ln)
        res.add("\n")
  finally:
    while outp.readLine(ln):
      res.add(ln)
      res.add("\n")
    if process != nil:
      process.close
    if outp != nil:
      outp.close
  result = res

proc makeReport(file,text:string) :string=
  # result = "test report\r\n"
  result &= file & ":\n"
  result &= "==================\n"
  result &= text

proc saveReport(filename:string; report:string; time:int64) =
  let dir = getCurrentDir()
  let saveTo = dir / "gen_issue_reports" & $time
  createDir(saveTo)
  echo saveTo
  discard existsOrCreateDir(saveTo)
  let saveFile = saveTo / filename.changeFileExt("") & "_gen_stopfast.txt"
  var fh:File
  try:
    fh = open(saveFile, fmWrite)
    fh.write(report)
  finally:
    fh.close

proc getRelevantText(output:string):string =
  let idx = output.rfind("=== REACHED GENERATE STAGE ===")
  if idx >= 0:
    result = output[idx..^1]
  else: result = output

# proc getSrcLine(s:string):string =
#   let findme ="source code was:"
#   let idx = s.find(findme,0)
#   let idx2 = s.find("\n",idx+1)
#   result = s[idx+findme.len+1 .. idx2-1]
#   # echo "result was: " & result

import std/nre
let reArrow = re"ck\w+ -> ck\w+"
proc getArrow(relevant:string) : string =
  let matches = relevant.find(reArrow)
  if matches.isSome:
    result = matches.get.match.strip
    echo result


# proc getLines(file, line:string; n:int):seq[string] =
#   let fh = open(file,fmRead)
#   let lines = fh.readAll.splitLines
#   echo n
#   echo "*", line & "*"
#   echo lines
#   var lNum:int
#   for i,l in lines:
#     if l.contains(line):
#       lNum = i
#       let start = max(0,lNum - n)
#       let last = min(lnum+n,lines.len-1)
#       return lines[start..last]
#   fh.close()
# let add_re = re"XXX" # XXX
# const numLines = 9
const startAfter = 0
const stopAfterFailures = some(1)
import hashes,sets
proc main() =
  var contents = noErrFile.readFile.splitLines.toHashSet()
  var fhAppend = noerrFile.open(fmAppend)
  var firstFailure:int
  echo "Hello there, and welcome!"
  let time = now().toTime.toUnix
  var folder = "/home/kobi7/More_CS_Libs_and_Apps"
  var file = folder / "failed_after.txt" # "aftergen.txt" #"all_of_them_sorted.txt"
  let args = commandLineParams();
  if args.len > 0:
    file = args[0]
    folder = file.parentDir
  var i,failures = 0
  let max = file.open(fmRead).readAll.countLines()
  for line in file.lines:
    # echo line
    i.inc
    if i < startAfter: continue
    if not line.fileExists: continue

    let width = 125
    let linePart = line[folder.len+1 .. ^1]
    let showLine = $failures &  ":" & $i & "\t" & alignLeft(linePart[0..min(width,linePart.len-1)],width, ' ')
    # echo showLine
    stdout.write(showLine & "\r")
    if line in contents: continue

    # process file
    let output = runWriter(line)
    if output.contains("finished:"):
      fhAppend.writeLine(line)
      continue
    else:
      failures.inc
      let relevantText = getRelevantText(output)
      # let arrow = getArrow(relevantText)
      # let srcLine = getSrcLine(relevantText)
      let file = line.changeFileExt(".precs")
      let filename = file.extractFilename
      # let relLines = getLines(file,srcLine,numLines)
      let report :string = makeReport(file, relevantText)
      saveReport(filename,report,time)
      if failures == 1:
        firstFailure = i
      if stopAfterFailures.isSome and failures >= stopAfterFailures.get:
        break;


  echo "\nThank you for using this tool!"
  echo "reached " & $firstFailure & "/" & $max

main()