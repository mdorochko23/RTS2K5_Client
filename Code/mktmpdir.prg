** MkTmpDir.Prg - Makes the temporary directory

private lnTemp

lnTemp = fcreate("c:\Temp\Test.tmp", 0)
if lnTemp = -1                                  && Could not Create because directory DNE
   !md C:\Temp
else
   =fclose(lnTemp)                              && Close the temp file
   delete file c:\temp\test.tmp
endif
