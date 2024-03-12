FUNCTION chkFileAvail
PARAMETER pfilename

LOCAL lnTries, lbFoundFile, lsCheckTable
lnTries = 20
lbFoundFile = .F.
lsCheckTable = ALLTRIM(pfilename)+".dbf"
DO WHILE !lbFoundFile AND lnTries > 0
   lbFoundFile = FILE(lsCheckTable)
   IF !lbFoundFile
      lnTries = lnTries-1
      WAIT WINDOW "Waiting for "+lsCheckTable+".  Tried "+ALLTRIM(STR(20-lnTries))+"/20 times." TIMEOUT 2
   ENDIF
ENDDO 
RETURN lbFoundFile

