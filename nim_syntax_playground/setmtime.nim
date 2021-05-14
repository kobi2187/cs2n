import os,times
let file = "/home/kobi7/currentWork/CsDisplay/bin/Release/netcoreapp2.2/CsDisplay.dll"
let time = initDateTime(11,mMar,2021,0,0,0).toTime

setLastModificationTime(file,time)