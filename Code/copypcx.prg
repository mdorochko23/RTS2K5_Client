PROCEDURE CopyPCX
* DMA 10/28/05 Adapted from original Fox 2.6 Code
* Key changes: 	RT number is now passed as string; no need to convert it from integer.
*				Paths for pcx file directories are taken from RTS.INI and stored 
*				in goApp properties (no more DataDir).

LPARAMETERS lcLRS AS String

LOCAL 	lcPath		AS String, ;
		lcShell		AS String, ;
		lcMatch		AS String, ;
		lcCopy		AS String, ;
		lcDelete	AS String, ;
		lcSubD		AS String, ;
		lcDest		AS String, ;
		f_archpcx	AS String, ;
		f_pcxarch	AS String
		
DIMENSION a_Ty[3]
a_Ty[1] = 'A'
a_Ty[2] = 'B'
a_Ty[3] = 'S'

f_archpcx = goApp.ArchPCXPath
f_pcxarch = goApp.PCXArchPath

WAIT WINDOW "Restoring PCX files. Please wait." NOWAIT NOCLEAR 

*lcLrs = alltrim(str(lnLrs))
lcSubD = RIGHT( lcLrs, 1) + "\"
lcPath  = SYS(5) + SYS(2003) + "\"                  && Path of default directory
SET DEFAULT TO (f_archpcx) + lcSubD

lcShell = lcLrs + ".PCX"
IF FILE( lcShell)
   lcCopy   = "Copy file " + f_archpcx + lcSubD + lcShell + ;
   				" to " + (f_pcxarch) + lcSubD + lcShell
   lcDelete = "Delete file " + f_archpcx + lcSubD + lcShell
   &lcCopy
   &lcDelete
ENDIF

lcShell = lcLRS + "C*.*"
lcMatch = SYS( 2000, lcShell)                     && Get first file that matches

DO WHILE LEN( lcMatch) > 0
   lcCopy   = "Copy file " + f_archpcx + lcSubD + lcMatch + ;
   				" to " + (f_pcxarch) + lcSubD + lcMatch
   lcDelete = "Delete file " + f_archpcx + lcSubD + lcMatch

   &lcCopy
   &lcDelete

   lcMatch = SYS(2000, lcShell, 1)                  && Find next file name
ENDDO

lcShell = lcLRS + "T*.*"
lcMatch = SYS(2000, lcShell)                     && Get first file that matches

DO WHILE LEN( lcMatch) > 0
   lcCopy   = "Copy file " + f_archpcx + lcSubD + lcMatch + " to " + ;
   				(f_pcxarch) + lcSubD + lcMatch
   lcDelete = "Delete file " + f_archpcx + lcSubD + lcMatch

   &lcCopy
   &lcDelete

   lcMatch = SYS(2000, lcShell, 1)                  && Find next file name
ENDDO

* Transfer documents in additional file formats
lcDest = (f_pcxarch) + lcSubD


* ######.tif
lcShell = lcLrs + ".TIF"
= Lfmove( lcShell, lcDest, lcShell)

* ######a1.pcx, ######b1.pcx, ######s1.pcx
* ######a1.tif, ######b1.tif, ######s1.tif
* ######a1.###, ######b1.###, ######s1.###
FOR n_TyCnt = 1 TO 3                         && a, b, s
   lcShell = lcLRS + a_Ty[ n_TyCnt] + "*.*"
   lcMatch = SYS(2000, lcShell)                     && Get first file that matches
   DO WHILE LEN(lcMatch) > 0
      = Lfmove( lcMatch, lcDest, lcMatch)
      lcMatch = SYS(2000, lcShell, 1)                  && Find next file name
   ENDDO
ENDFOR                                       &&n_TyCnt

* ######a.pcx, ######b.pcx, ######s.pcx,
* ######a.tif, ######b.tif, ######s.tif
FOR n_TyCnt = 1 TO 3                         && a, b, s
   lcShell = lcLRS + a_Ty[n_TyCnt] + ".*"
   lcMatch = SYS( 2000, lcShell)                     && Get first file that matches
   DO WHILE LEN(lcMatch) > 0
      = Lfmove( lcMatch, lcDest, lcMatch)
      lcMatch = SYS(2000, lcShell, 1)                  && Find next file name
   ENDDO
ENDFOR                                       &&n_TyCnt

IF NOT EMPTY( lcPath)
   SET DEFA TO (lcPath)
ENDIF

WAIT CLEAR

**************************************************************
* FUNCTION: LFCOPY
* Abstract: Move passed file to passed location. Return result
**************************************************************
FUNCTION lfMove
LPARAMETER c_File, c_Dest, c_Base
LOCAL 	c_Copy 		AS String, ;
		c_Delete	AS String
IF FILE( c_File)
   c_Copy   = "Copy file " + c_File + " to " + c_Dest + c_Base
   c_Delete = "Delete file " + c_File
   &c_Copy
   &c_Delete
   RETURN .T.
ELSE
   RETURN .F.
ENDIF
