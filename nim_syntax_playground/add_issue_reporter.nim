import system,os, nre, times, osproc, streams, strutils
import random, algorithm, sequtils
# const noerrFile = "/home/kobi/More_CS_Libs_and_Apps/no_add_errors.txt"
# const toolongFile = "/home/kobi/More_CS_Libs_and_Apps/toolong.txt"

var parentFolder = "empty"

proc appendTooLong(parentFolder, line : string) =
  let file = parentFolder / "toolong.txt"
  let fh = file.open(fmAppend)
  try:
    fh.writeLine(line)
  finally:
    fh.close

const iterLimit = none(int) # some(1.5) # float in seconds


proc runWriter(line:string): string =
  let iterBeginTime = times.now()
  var res = ""
  var process :Process
  var outp :Stream
  const cwd = "/home/kobi/cs2n"
  var ln = newStringOfCap(200)
  var iterLimitReached : bool
  try:
    process = startProcess("/home/kobi/cs2n/writer", workingDir = cwd, args = [line], options = {poStdErrToStdOut, poUsePath})
    outp= outputStream(process)
    echo ""

    while running(process):
      let elapsedIterationTime = now() - iterBeginTime
      stdout.write $elapsedIterationTime.inMilliseconds,"ms","\r"
      iterLimitReached = iterLimit.isSome and  elapsedIterationTime.inMilliSeconds >= (iterLimit.get * 1000).int
      if iterLimitReached:
        echo "\nreached iterLimit timeout: " & $iterLimit.get
        appendTooLong(parentFolder, line)
        break #
      if outp.readLine(ln):
        res.add(ln)
        res.add("\n")
  finally:
    while not iterLimitReached and outp.readLine(ln):
      res.add(ln)
      res.add("\n")
    echo ""
    if process != nil:
      process.close
    if outp != nil:
      outp.close
  result = res

proc makeReport(lines:seq[string] ;file,text:string) :string=
  # result = "test report\r\n"
  result &= file & ":\n"
  result &= "==================\n"
  result &= lines.join("\n") & "\n"
  result &= "==================\n"
  result &= text

proc saveReport(filename:string; report:string; time:int64; arrow:string) =
  let dir = getCurrentDir()
  let saveTo = dir / "add_issue_reports" & $time / arrow.replace(" -> ","-")
  createDir(saveTo)
  echo saveTo
  discard existsOrCreateDir(saveTo)
  let saveFile = saveTo / filename.changeFileExt("") & "_add_stopfast.txt"
  var fh:File
  try:
    fh = open(saveFile, fmWrite)
    fh.write(report)
  finally:
    fh.close

proc getRelevantText(output:string):string =
  let idx = output.rfind("in getParent")
  if idx >= 0:
    result = output[idx..^1]

proc getSrcLine(s:string):string =
  let findme ="source code was:"
  let idx = s.find(findme,0)
  let idx2 = s.find("\n",idx+1)
  result = s[idx+findme.len+1 .. idx2-1]
  # echo "result was: " & result

import std/nre
let reArrow = re"ck\w+ -> ck\w+"
proc getArrow(relevant:string) : string =
  let matches = relevant.find(reArrow)
  if matches.isSome:
    result = matches.get.match.strip
    echo result


proc getLines(file, line:string; n:int):seq[string] =
  let fh = open(file,fmRead)
  let lines = fh.readAll.splitLines
  echo n
  echo "*", line & "*"
  echo lines
  var lNum:int
  for i,l in lines:
    if l.contains(line):
      lNum = i
      let start = max(0,lNum - n)
      let last = min(lnum+n,lines.len-1)
      return lines[start..last]
  fh.close()
let add_re = re"storeInParent\.nim\(\d+\) add"
const numLines = 9
const startAfter = 0
const stopAfterFailures = 50.some #none(int) #some(1000)
import hashes,sets

proc main() =
  var firstFailure:int
  echo "Hello there, and welcome!"
  let time = now().toTime.toUnix
  var folder = "/home/kobi/More_CS_Libs_and_Apps"
  var file = folder / "all_of_them_sorted.txt"
  let args = commandLineParams();
  if args.len > 0:
    file = args[0]
    folder = file.parentDir
  
  var contents = (file).readFile.splitLines.toHashSet()
  var toolong =  (folder / "toolong.txt").readFile.splitLines.toHashSet()
  parentFolder = folder
  var toobig =   (folder / "toobig.txt").readFile.splitLines.toHashSet()
  
  var noerrFile = (folder / "no_add_errors.txt")

  var fhAppend = noerrFile.open(fmAppend)
  var i,failures = 0
  let lines = file.open(fmRead).readAll.splitLines()
  let max = lines.len

  for line in lines.reversed:
    echo line
    i.inc
    if i < startAfter: continue
    if not line.fileExists: continue

    let width = 125
    let linePart = line[folder.len+1 .. ^1]
    let showLine = $failures &  ":" & $i & "\t" & alignLeft(linePart[0..min(width,linePart.len-1)],width, ' ')
    # echo showLine
    stdout.write(showLine & "\r")
    if line notin contents: continue
    if line in toolong: continue

    # process file
    let output = runWriter(line)
    if not output.contains("storeInParent"):
      fhAppend.writeLine(line)
      continue
    else:
      failures.inc
      let relevantText = getRelevantText(output)
      let arrow = getArrow(relevantText)
      let srcLine = getSrcLine(relevantText)
      let file = line.changeFileExt(".cs")
      let filename = file.extractFilename
      let relLines = getLines(file,srcLine.changeFileExt(".precs") ,numLines)
      let report :string = makeReport(relLines, file, relevantText)
      saveReport(filename,report,time, arrow)
      if failures == 1:
        firstFailure = i
      if stopAfterFailures.isSome and failures >= stopAfterFailures.get:
        break;


  echo "\nThank you for using this tool!"
  echo "reached " & $firstFailure & "/" & $max

main()