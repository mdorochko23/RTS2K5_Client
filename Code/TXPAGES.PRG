*PROCEDURE  TXPages
PARAMETERS cdoc, ntag, cMID
* Print scanned special documents
Private FILEHAND, I, LCLRS, LCSOURCE, LCDEST, LCSPATH, LCDPATH, LFILEEXT
c_alias =ALIAS()
IF TYPE('pc_deptype')<>"C"
	IF NOT ISDIGIT( LEFT( ALLT( cMID), 1))
		PC_DEPTYPE = LEFT( ALLT( cMID), 1)
	ELSE
		PC_DEPTYPE = "D"
	ENDIF
ENDIF

Set Procedure To subp_pa Additive  
Set Procedure To TA_LIB Additive

Set Safety Off
F_PCX=Iif(PL_OFCOAK, GOAPP.CAPCX ,GOAPP.PCXPATH)
F_PCXARCH=Iif(PL_OFCOAK,GOAPP.CAPCXARCH,GOAPP.PCXARCHPATH)

LCLRS = Allt( PC_LRSNO)
LCSPATH = F_PCX + LCLRS
LCDPATH = F_PCXARCH + Right(LCLRS,1) + "\" + LCLRS

If Not Empty(cdoc)
*--Send pages for this  where cdoc type exists
	For I = 1 To 9
		LCSOURCE = LCSPATH + cdoc + Trans(I, "9") + ;
			"." + Trans(NTAG, "@L 999")
		LCDEST   = LCDPATH + cdoc + Trans(I, "9") + ;
			"." + Trans(NTAG, "@L 999")
		If Not SEND_PG(LCSOURCE, LCDEST)
			Exit
		Endif
	Endfor
ENDIF

*-- Set Safety ON  && 03/10/2021 MD #230210 
IF !EMPTY(c_alias )
SELECT (c_alias )
ENDIF 
Return