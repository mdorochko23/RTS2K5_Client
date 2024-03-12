**07/05/2017- #58693 - copy 'G' files to the /pcxarch right away
**3/11/2013- retutr=rn future path for a scanned dubp for a KOP Generic courts (signed subp)
*****************************************************************************************************************************
*FUNCTION FakeSubPcx
*****************************************************************************************************************************
PARAMETERS ntagn
LOCAL lcLrs AS STRING, lcSPath AS STRING, lcDPath AS STRING
lcLrs = ALLT( pc_lrsno)
lcSPath = goApp.pcxpath
lcDPath = goApp.pcxarchpath + RIGHT(lcLrs,1)

lcSource =lcSPath +  lcLrs  + "G1." + TRANS(ntagn, "@L 999")
lcDest   = lcDPath + "\"+ lcLrs  +"G1." + TRANS(ntagn, "@L 999")

IF  NOT FILE(lcDest )
	IF FILE(lcSource)
**07/05/2017: move 'G' from pcx to pcxarch
		DO MoveG WITH lcSource, lcDest 
**07/05/2017: move 'G' from pcx to pcxarch
	ELSE
**DO NOTHING AS WE HAVE NO 'G' FILE YET- JUST STORE A FAKE PATH FOR A FUTURE FILE
*lcDest =lcSource
	ENDIF
ENDIF



RETURN lcDest
*****************************************************************************************************************************
*****************************************************************************************************************************
PROCEDURE MoveG
PARAMETERS c_pcx, c_pcxarch
LOCAL fso_1 AS OBJECT
fso_1 = CREATEOBJECT("Scripting.FileSystemObject")
IF fso_1.FileExists(c_pcx) 
	fso_1.CopyFile( c_pcx,c_pcxarch )
	**make sure it was copied so we can delete 'g' from the PCX
	IF  fso_1.FileExists(c_pcxarch)
		fso_1.DeleteFile (c_pcx)
	ENDIF
ENDIF

RELEASE  fso_1
