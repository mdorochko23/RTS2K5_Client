**FUNCTION ValidAuth

**09/12/2018, SL, Zendesk #104106
*PARAMETERS C_LRSNO, N_TAG, L_CONFIRM5
PARAMETERS L_CONFIRM5

LOCAL oMed5 AS OBJECT
oMed5 = CREATEOBJECT("generic.medgeneric")

LOCAL l_Bchk AS BOOLEAN, l_Achk AS BOOLEAN, l_ok5 AS BOOLEAN, l_cancel5 AS BOOLEAN, lc_path, C_SQL
STORE .F. TO l_Bchk, l_Achk, l_ok5, l_cancel5

**09/12/2018, SL, Zendesk #104106
*!*	C_SQL=""
*!*	IF L_CONFIRM5 && BASE SELECTED
*!*		oMed5.CLOSEALIAS("BChk")
*!*		C_SQL="select   [dbo].[ChkScannedBaseBeforeIssue] ('" + C_LRSNO + "','" + STR(N_TAG) + "','"    + DTOC(DATE()) + "')"
*!*		l_ok5 = oMed5.SQLEXECUTE (C_SQL,"BChk")
*!*		IF USED('BChk') AND  l_ok5
*!*			l_Bchk=NVL(BChk.EXP,.F.)
*!*		ENDIF
*!*	ELSE
*!*		oMed5.CLOSEALIAS("AChk")
*!*		C_SQL="select   [dbo].[ChkScannedAuthBeforeIssue] ('" + C_LRSNO + "','" + STR(N_TAG)  + "','" + DTOC(DATE()) + "')"
*!*		l_ok5= oMed5.SQLEXECUTE (C_SQL,"AChk")
*!*		IF USED('AChk') AND  l_ok5
*!*			l_Achk=NVL(AChk.EXP,.F.)
*!*		ENDIF
*!*	ENDIF

**09/12/2018, SL, Zendesk #104106
C_SQL = "exec [dbo].[getsupplemtagbylrs] " + pc_lrsno + ", " + pc_tag
oMed5.SQLEXECUTE(C_SQL, "SupplementalTag")

l_Achk = CheckAuthDocument(pc_tag)

IF (l_Achk = .F. AND SupplementalTag.supplem_to > 0)
	l_Achk = CheckAuthDocument(SupplementalTag.supplem_to)
ENDIF

l_Bchk = CheckBaseDocument()

DO CASE
**09/12/2018, SL, Zendesk #104106
*!*	CASE   !l_Achk AND !L_CONFIRM5 && just autho issue  and no "A" doc

*!*		C_PCX=""
*!*		C_PCX=anyscans	(N_TAG,"A" )
*!*		IF EMPTY(ALLTRIM(C_PCX))
*!*			l_cancel5 =.T.
*!*			GFMESSAGE("Missing  authorization. Check RTS Scan.")
*!*		ELSE
*!*			l_Achk =.T. && found images at pcx folders
*!*		ENDIF


CASE   !l_Achk  AND L_CONFIRM5 AND !l_Bchk &&  not "B" image picked and no "A" - ask for STC
	PL_STOPPRTISS=.T.
	GFMESSAGE("Printing canceled because no documents were found.")
	** YS 05/29/18 RPS No Print Job Logging [#88327]
	lcSQLLine=" exec [dbo].[AddTrackStopPrint]   '" + convertToChar(pc_lrsno,1) + "','" + convertToChar(fixquote(pc_clcode),1) + "','" + convertToChar(PN_TAG,1) + "','";
			+ convertToChar(pc_IssType,1) + "','" + convertToChar(fixquote(PC_USERID),1) + "','validauth.prg(1)',''"
	*lcSQLLine=" exec [dbo].[AddTrackStopPrint]   '" + ALLTRIM(pc_lrsno) + "','" + ALLTRIM(pc_clcode) + "','" + ALLTRIM(STR(PN_TAG)) + "','";
		+ pc_IssType + "','" + ALLTRIM(PC_USERID) + "','validauth.prg(1)',''"
	oMed5.SQLEXECUTE(lcSQLLine,'')

CASE  !l_Achk AND !L_CONFIRM5 && extra check- in case a NNNNa1.tif file was deleted but the record in the tblscandoclog still exists
*!*		C_PCX=""
*!*		C_PCX=anyscans	(N_TAG,"A" )
*!*		IF EMPTY(ALLTRIM(C_PCX))
		l_cancel5 =.T.
		GFMESSAGE("Missing  authorization. Check RTS Scan.")
*!*		ENDIF
ENDCASE
RELEASE oMed5
RETURN l_cancel5
*----------------------------------------------
**09/12/2018, SL, Zendesk #104106
FUNCTION CheckAuthDocument
PARAMETERS c_tag
LOCAL lcPath

lcPath = ADDBS(ALLTRIM(IIF(pl_ofcOak,goApp.capcx, goApp.pcxpath)))
lcPath = lcPath + ALLTRIM(pc_lrsno) + "*." + padl(ALLTRIM(c_tag),3,"0") 

IF (ADIR(laCert, lcPath) > 0)
	RETURN .T.
ENDIF
        
lcPath = ADDBS(ALLTRIM(IIF(pl_ofcOak,goApp.capcxArch, goApp.pcxarchpath)))
lcPath = lcPath + RIGHT(ALLTRIM(pc_lrsno),1) + "\"+  ALLTRIM(pc_lrsno) + "*." + padl(ALLTRIM(c_tag),3,"0") 

IF (ADIR(laCert, lcPath) > 0)
	RETURN .T.
ENDIF

RETURN .F.
*----------------------------------------------
**09/12/2018, SL, Zendesk #104106
FUNCTION CheckBaseDocument
LOCAL lcBasePath, lcPath, lnSubFolders
LOCAL ARRAY laSubFolders[1]

lcBasePath = ADDBS(MLPriPro("R", "RTS.INI", "Data","IMGBASEALL", "\"))
lcPath = lcBasePath + ALLTRIM(pc_lrsno) + "*.tif"

IF (ADIR(laCert, lcPath) > 0)
	RETURN .T.
ENDIF

lnSubFolders = ADIR(laSubFolders, lcBasePath + "*.*", "D")

FOR i = 3 TO lnSubFolders
	IF (ALLTRIM(laSubFolders[i, 5]) = "....D")
		lcPath = lcBasePath + laSubFolders[i, 1] + "\" + ALLTRIM(pc_lrsno) + "*.tif"
    
	    IF (ADIR(laCert, lcPath) > 0)
			RETURN .T.
		ENDIF
	ENDIF
ENDF

RETURN .F.