
import osproc, strutils, sets, hashes, nre, sequtils, math, algorithm, random, system, os, streams
import times,tables
import mapper
import os

type FileErr = object
  file*: string
  output*: string

func perc(part, sum: int): string =
  if sum != 0:
    $((100 * part / sum).round(2)) & "%"
  else: "0"

proc shortened(s:string, lastChars = 7200) :string=
  if s.len > lastChars: return s
  else:
    let start = max(s.len-lastChars,0)
    result = s[start..^1]

proc addErrorToFile(parentFolder,line:string; after:bool) =
  let beforePath = parentFolder / "failed_before.txt"
  let afterPath = parentFolder / "failed_after.txt"
  if after:
    let fh = open(afterPath, fmAppend)
    try: fh.writeLine(line)
    finally: fh.close
  else:
    let fh = open(beforePath, fmAppend)
    try: fh.writeLine(line)
    finally: fh.close



proc printStats(count, i, finished, unfinished, cfitsCounter, cfits, storeCounter, missingStore, unsupportedCounter, extractCounter, nullMethodCounter, nilctderef, afterGen, beforeGen, likely, tc, otherErrors: int,genfails:CountTable[string]) =
  let both = i #finished + unfinished
  echo perc(finished, both) & " : " & perc(unfinished, both)
  echo "failed due to missing cfits ", perc(cfitsCounter, both), " (", cfitsCounter, "|" ,cfits ,")"
  echo "failed due to parentStore missing switch case ", perc(storeCounter, both), " (", storeCounter, "|", missingStore, ")"
  echo "failed due to unknown parent, child construct not yet supported ", perc(unsupportedCounter, both), " (", unsupportedCounter, ")"
  echo "failed due to extract not impl ", perc(extractCounter, both), " (", extractCounter, ")"
  echo "failed due to compiletime null ", perc(nilctderef, both), " (", nilctderef, ")"
  echo "failed due to runtime null ", perc(nullMethodCounter, both), " (", nullMethodCounter, ")"
  echo "failed due to likely missed removing annotation ", perc(likely, both), " (", likely, ")"
  echo "failed due to typeCreator missing a switch ", perc(tc, both), " (", tc, ")"
  echo "Other errors: ", perc(otherErrors, both), " (", otherErrors, ")"
  echo "failed after gen ", perc(afterGen, both), " (", afterGen, ")"
  if genfails.len>0: echo "--", largest(genfails)
  echo "failed before gen ", perc(beforeGen, both), " (", beforeGen, ")"
  echo "no errors + passed storing stage ", perc(finished + afterGen, both)
  echo both, "/", count, " = ", perc(both, count)


proc fitsContent(file: string, newfits: string): string =
  var fh: File
  try:
    fh = open(file)
    let lines = fh.readAll.splitLines
    let intro = lines[0..2].join("\n") & "\n"
    let exceptLast = lines[3..^2]
    let output = exceptLast.toHashSet().toSeq().join("\n")
    let last = "\n" & r"""  else: raise newException(Exception, "cfits is missing:  of \"" & $parent.kind & ", " & $item.kind & "\": true")"""
    result &= intro & output & "\n" & newfits & "\n" & last
  finally: fh.close

proc genFits(newFits: string) =
  echo "in genFits"
  let file = "/home/kobi/cs2n/cfits.nim"
  let content = fitsContent(file, newFits)
  var fh2: File
  try:
    let fh2 = open(file, fmWrite)
    fh2.write(content)
  finally:
    fh2.close


proc writeToFileCfits(cfits: HashSet[string]) =
  let newfits = cfits.toSeq.join("\r\n")
  echo "saving cfits.nim"
  genFits(newfits)

proc writeToFileStoreMapping(missingStore: HashSet[string]) =
  let newstores = missingStore.toSeq.sorted.join("\r\n")
  let file = "/home/kobi/cs2n" / "nim_syntax_playground" / "parentKidMapping.txt"
  var fh: File
  try:
    fh = open(file, fmAppend)
    echo "saving parent to kid mapping"
    fh.write("\n" & newstores)
  finally:
    fh.close

proc writeToFileStoreParent() =
  let gen = genStoreInParent()
  let file = "/home/kobi/cs2n" / "storeInParent.nim"
  var fh: File
  try:
    fh = open(file, fmWrite)
    echo "saving generated storeInParent.nim"
    fh.write(gen)
  finally:
    fh.close

proc runAddRunner() =
  echo "trying to run add runner!"
  # let cwd = "/home/kobi/cs2n"
  let res = execCmd("/home/kobi/cs2n/addrunner")
  echo res

proc appendTooLong(parentFolder, line : string) =
  let file = parentFolder / "toolong.txt"
  let fh = file.open(fmAppend)
  try:
    fh.writeLine(line)
  finally:
    fh.close
import sequtils,algorithm, tables
proc printEnding(cfits, missingStore, missingExtract, unsupp, tc: HashSet[string], nilDispatch: seq[string],genfails:CountTable[string]) =
  echo "===cfits=================="
  echo cfits.toSeq.join("\r\n")
  echo "=========parentstore============"
  echo missingStore.toSeq.sorted.reversed.join("\r\n")
  echo "======extract==============="
  echo missingExtract.toSeq.join("\r\n")
  echo "=========find parent for child: (not yet implemented)============"
  echo unsupp.toSeq.join("\r\n")
  echo "=======type creator=============="
  echo tc.toSeq.join("\r\n")
  echo "=== most missing in gen stage: ==="
  let gens = sequtils.toSeq(genfails.keys())
  if gens.len >= 10:
    echo gens[0..<10]
  # echo nilDispatch
proc main(): bool =

  var
    cfits = initHashSet[string]()
    missingStore = initHashSet[string]()
    missingExtract = initHashSet[string]()
    unsupp = initHashSet[string]()
    tc = initHashSet[string]()
    likelyAnnotation = initHashSet[string]()
    nilDispatch = newSeq[string]()
    nilCtDeref = newSeq[string]()


  let cfitsRe = re"cfits is missing:(\s+of .*?: true)" # \[Exception\]$"
  let parentStoreRe = re"Error: unhandled exception: .*storeInParent\.nim\(\d+, \d+\) `false` (\w+ -> \w+) plz impl for (parent|child): ck\w+ \[AssertionDefect\]"
  let extractRe = re"most likely `extract` is not implemented for: \w+"
  let dispatchNilRe = re"Error: unhandled exception: cannot dispatch; dispatcher is nil \[NilAccessDefect\]" # this is when generating or using runtime method that messes with BodyExpr for example.
  let unsupportedRe = re"(\w+) is still unsupported"
  let typeCreatorRe = re"Error: unhandled exception: type_creator\.nim(.*)" #(\d+, \d+) `false` still unsupported: of (.*?)\s+"

  let likelyAnnotationProblemRe = re"Error: unhandled exception: parent_finder.nim(\d+, \d+) `discarded == true`  \[AssertionDefect\]"

  var finished: seq[string] = @[]
  var unfinished: seq[string] = @[]
  # counters:
  var otherErrors, cfitsCounter, storeCounter, unsupportedCounter, extractCounter, nullMethodCounter, afterGen, beforeGen = 0

  # start

  let cwd = "/home/kobi/cs2n"
  # var file = cwd / "nim_syntax_playground" / "sizes_2_smallfirst.txt"
  # var file = cwd / "nim_syntax_playground" / "updated_sizes_smallfirst.txt"

  # created with: find /home/kobi/More_CS_Libs_and_Apps/ -name *.csast -size -2M
  # then run thru sizes.nim, and sort natural in a text editor, and remove (search&replace) ^\d+
  # var file = "/home/kobi/More_CS_Libs_and_Apps/more_updated_sorted.txt"
  var file = "/home/kobi/More_CS_Libs_and_Apps/new_installation_sorted.txt"
  

  if os.commandLineParams().len > 0:
    file = os.commandLineParams()[0]
  let parentFolder = file.splitPath.head # "/home/kobi/More_CS_Libs_and_Apps"
  # let inhuge = parentFolder.contains(file)
  let toobigfile = file.splitPath.head / "toobig.txt" # "/home/kobi/More_CS_Libs_and_Apps/toobig.txt"
  let toolongfile = file.splitPath.head / "toolong.txt"
  let failedAfter = file.splitPath.head / "failed_after.txt"
  let failedBefore = file.splitPath.head / "failed_before.txt"
  let f = file.splitPath.head / "finished.txt"
  let f2 = file.splitPath.head / "aftergen.txt"
  # var toolarge = initHashSet[string]()
  # var toolong = initHashSet[string]()
  var assumedFinish = initHashSet[string]()
  var assumedAfter = initHashSet[string]()
  var genfails = initCountTable[string]()

  if not fileExists(toobigfile) or not fileExists(toolongfile) or not fileExists(failedAfter) or not fileExists(failedBefore) or not fileExists(f) or not fileExists(f2): 
    quit("a file needed for operation does not exist!")

  var toolarge = open(toobigfile, fmRead).readAll.splitLines.toHashSet()
  var toolong = open(toolongfile, fmRead).readAll.splitLines.toHashSet()
  var failAfter = open(failedAfter, fmRead).readAll.splitLines.toHashSet()
  var failBefore = open(failedBefore, fmRead).readAll.splitLines.toHashSet()
  let finToRead = open(f, fmRead)
  var afterGenToRead = open(f2, fmRead)
  if f.getFileSize > 0:
    assumedFinish = finToRead.readAll.splitLines().toHashSet()
  if f2.getFileSize > 0:
    let c = afterGenToRead.readAll
    assumedAfter = c.splitLines().toHashSet()

  finToRead.close
  afterGenToRead.close

  var afterGenToAdd = open(f2, fmAppend)
  var finToAdd = open(f, fmAppend)


  # ============================== PARAMETERS:
  const random = false
  const reverse = false
  const startAfterNum: Option[int] =none(int) #some(151_593)
  const startAfterPercent: Option[float] = none(float) # some((20.0).float) # in percent
  const hasTimeLimit = true
  var timeLimit: int64 = 0.int64 + #sec
    2 * 60 +                       #min
    0 * 60 * 60                    # hours
  const iterLimit = some(12.5) # float in seconds
  const hasCountLimit = false
  const limit = 15
  # just fixing up whatever is needed.
  const earlyBreak = true # TODO: change to true and run with left_report, to quickly fix priority errors (picking libs first fruits).
  const breakAfter = true

  const addTime = false
  const timeToAdd = 10 # seconds
                       # ===========================
  if random: randomize()
  let startTime = times.now()
  var fhandleRead: File
  try:
    fhandleRead = open(file, fmRead)
    let contents = fhandleRead.readAll

    var lines = contents.splitLines()
    let count = lines.len

    # num takes precedence
    if startAfterNum.isSome:
      lines = lines[startAfterNum.get .. ^1]
    elif startAfterPercent.isSome:
      let start = (startAfterPercent.get * lines.len.toFloat / 100).int
      lines = lines[start .. ^1]

    if random:
      lines.shuffle
    if reverse:
      lines.reverse


    var metLimit: bool
    for i, line in lines:

      # echo "Handling file #" & $i
      if not random and not reverse and startAfterNum.isSome and i < startAfterNum.get:
        # echo "skipping#"
        continue
      if not random and not reverse and startAfterPercent.isSome and (100*i)/count < startAfterPercent.get:
        # echo "skipping%"
        continue
      let iterBeginTime = times.now()
      let elapsed = iterBeginTime - startTime
      let p = elapsed.toParts
      if not fileExists(line):
        continue
      if line in toolarge or line in toolong:
        # # echo "skipping, to avoid possible out of memory in big file.";
        # echo "skipping>";
        continue
      if line in assumedFinish:
        finished.add line
        # echo "skipping!done";
        continue
      if line in assumedAfter: # and not earlyBreak and not breakAfter:
        afterGen.inc
        # echo "skipping+";
        continue

      echo "time elapsed: ", p[Hours], ":", p[Minutes], ":", p[Seconds], ":", p[Milliseconds]
      if i > 0:
        printStats(lines.len, i, finished.len, unfinished.len, cfitsCounter, cfits.len, storeCounter,missingStore.len, unsupportedCounter, extractCounter, nullMethodCounter, nilCtDeref.len, afterGen, beforeGen, likelyAnnotation.len, tc.len, otherErrors, genFails)

      # echo line.split("/")[^1]
      echo line
      let metTimeLimit = hasTimeLimit and elapsed.inSeconds > timeLimit
      let countReached = missingExtract.len + cfits.len + missingStore.len
      let metCountLimit = hasCountLimit and countReached >= limit
      if metTimeLimit and (countReached == 0) and addTime:
        timeLimit = elapsed.inSeconds + timeToAdd.int64
      else:
        metLimit = metCountLimit or metTimeLimit
        if metLimit: break

      # GC_fullCollect()
      # echo "file size: " & $line.getFileSize()
      # let res = execProcess("/home/kobi/cs2n/writer", workingDir = cwd, args = [line], options = {poStdErrToStdOut, poUsePath})

      var res =""
      var process :Process
      var iterLimitReached:bool
      var outp :Stream
      var ln = newStringOfCap(1200)
      try:
        # discard execCmd("dotnet /home/kobi/CsDisplay/bin/Release/netcoreapp2.2/CsDisplay.dll " & line.changeFileExt(".cs"))
        process = startProcess("/home/kobi/cs2n/writer", workingDir = cwd, args = [line], options = {poStdErrToStdOut, poUsePath})
        outp= outputStream(process)
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
        while not iterLimitReached and not outp.isNil and outp.readLine(ln):
          res.add(ln)
          res.add("\n")
        echo ""
        if process != nil:
          process.close
        if outp != nil:
          outp.close

      var after: bool = false
      if res.contains("finished:"):
        finished.add line
        finToAdd.writeLine(line)
        # echo "had finish text!"
      else:
        # discard execCmd("dotnet /home/kobi/CsDisplay/bin/Release/netcoreapp2.2/CsDisplay.dll " & line.changeFileExt(".cs"))
        if res.contains("Error:") or res.contains("Segmentation fault") or res.contains("SIGSEGV: Illegal storage access"):

          unfinished.add line
          # echo "had an error."
          if res.contains("=== REACHED GENERATE STAGE ==="):
            after = true
            afterGen.inc
            afterGenToAdd.writeLine(line)
            if earlyBreak and breakAfter and not res.contains("finished:"):
              echo res.shortened
              echo "failure in gen stage"
              echo line.changeFileExt(".cs")
              echo "reached " & $i & " --  Percent:  " & perc(finished.len+unfinished.len, count)
              assert false
          else:
            beforeGen.inc

          if res.contains("cfits is missing:"):
            cfitsCounter.inc
            let matches = res.find(cfitsRe)
            if matches.isSome:
              let c = matches.get.captures
              cfits.incl c[0]
          elif res.contains(parentStoreRe):
            storeCounter.inc
            let matches = res.find(parentStoreRe)
            if matches.isSome:
              let c = matches.get.captures
              missingStore.incl c[0]
          elif res.contains(extractRe):
            extractCounter.inc
            let matches = res.findAll(extractRe)
            for m in matches:
              # echo m
              missingExtract.incl m
          elif res.contains(dispatchNilRe):
            nullMethodCounter.inc
            nilDispatch.add line # add the file that failed.
          elif res.contains(unsupportedRe):
            # assert false # to advance here, we need to know the error that we're seeing.
            unsupportedCounter.inc
            let matches = res.find(unsupportedRe)
            if matches.isSome:
              let c = matches.get.captures
              unsupp.incl c[0]
          elif res.contains(likelyAnnotationProblemRe):
            likelyAnnotation.incl line
          # elif res.contains("`blocks.len == blockCount * 2`") or res.contains("`bs.name == \"BlockStarts\"`") or res.contains("unhandled exception: key not found:"):
            # discard execCmd("dotnet /home/kobi/CsDisplay/bin/Release/netcoreapp2.2/CsDisplay.dll " & line.changeFileExt(".cs"))
            # continue

          elif res.contains(typeCreatorRe):
            let matches = res.find(typeCreatorRe)
            if matches.isSome:
              let c = matches.get.captures
              tc.incl c[0]
          elif res.contains("SIGSEGV: Illegal storage access. (Attempt to read from nil?)"):
            nilCtDeref.add line
            if earlyBreak:
              echo res.shortened
              echo "regular (not runtime dispatch related) null dereference error"
              echo line.changeFileExt(".cs")
              echo "reached " & $i & " --  Percent:  " & perc(finished.len+unfinished.len, count)
              assert false
          elif res.contains("--> in  genNim*"): #(c: var CsSimpleLambdaExpression)
            let idx = res.rfind("--> in  genNim*")
            let matchthis = re"--> in\s+genNim\*\(c: (var)? (\w+)\)"

            if idx != -1:
              let newcontent = res[idx..^1]
              let m = newcontent.find(matchthis)
              if m.isSome:
                let c = m.get.captures
                let what = c[1]
                genFails.inc(what)
          else:
            # assert not res.contains("finished:")
            otherErrors.inc
            if earlyBreak and not after:
              echo res.shortened
              echo "Some other error occured!"
              echo line.changeFileExt(".cs")
              echo "reached " & $i & " --  Percent:  " & perc(finished.len+unfinished.len, count)
              # discard execCmd("dotnet /home/kobi/CsDisplay/bin/Release/netcoreapp2.2/CsDisplay.dll " & line.changeFileExt(".cs"))
              assert false
        if (after and line notin failAfter) or (not after and line notin failBefore):
          addErrorToFile(parentFolder, line,after)


        # finToAdd.writeLine(line)
      # we run them sorted by size, so if the last one was too long, we break, assuming the next ones will be longer.
      # let iterEndTime = times.now()
      # if hasTimeLimit and iterlimit.isSome and (iterEndTime - iterBeginTime).inSeconds > iterLimit.get and not random and not reverse:
      #   break


    echo "FINISHED!"
    genFails.sort()
    printEnding(cfits, missingStore, missingExtract, unsupp, tc, nilDispatch, genFails)
    if cfits.len > 0:
      echo "cfits unique: " & $cfits.len
      writeToFileCfits(cfits)
    if storeCounter > 0:
      echo "missing stores unique: " & $missingStore.len
      writeToFileStoreMapping(missingStore)
      writeToFileStoreParent()
      runAddRunner()
    if likelyAnnotation.len > 0:
      for ln in likelyAnnotation.toSeq:
        discard execCmd("/home/kobi/CsDisplay/bin/Release/net5.0/CsDisplay " & ln)

    result = not metLimit
  finally:
    # fhandleRead.close
    afterGenToAdd.close
    finToAdd.close

when isMainModule:
  var isFinishedSuccessfully: bool = main()
  # let cf = initHashSet[string](0)
  # writeToFileCfits(cf)

