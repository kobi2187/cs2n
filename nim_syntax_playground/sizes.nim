import system, os
<<<<<<< HEAD
import natsort,strutils
import algorithm,sequtils
# find /home/kobi7/More_CS_Libs_and_Apps/ -name *.csast -size -2M > sizes.txt

var ls : seq[(float64,string)]
let file = os.commandLineParams()[0]
for f in file.lines:
  if f.fileExists:
    let s = f.getFileSize.toBiggestFloat
    ls.add((s,f))
    # echo $s & "::" & f
ls.sort(natsort.cmp)
let sorted_files = ls.mapIt(it[1])
echo sorted_files.join("\r\n")
=======
# find /home/kobi7/More_CS_Libs_and_Apps/ -name *.csast -size -2M > sizes.txt

let file = os.commandLineParams()[0]
for f in file.lines:
  if f.fileExists:
    # let fh = open(f)
    let s = f.getFileSize
    echo $s & "::" & f
    # close(fh)
>>>>>>> 54faa57b3a4cbaf076e4f54f43ef779823b548d3
