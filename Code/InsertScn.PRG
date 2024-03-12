**FUNCTION InsertScn (Zendesk#24124)
**08/16/2017: EF TX Reissue needs Q
**12/07/2015: EF - adds a record to the tblScandoclog for "G" and "R" when a tag is mirrored. Called from cscandoc.prg
PARAMETERS l_nRT, l_nTg, l_cType, l_cpath, l_corigfile

LOCAL cAlias AS STRING, lexists AS Boolean, l_retval AS Boolean, lnConn AS INTEGER
cAlias= ALIAS()
l_retval=.F.
lexists= .F.
lnConn=0
IF USED("HasRecord")
	SELECT   HasRecord
	USE
ENDIF

IF TYPE('l_nRT') ='N'
	l_nRT=STR(l_nRT)
ENDIF
IF TYPE('l_nTg') ='C'
	l_nTg=VAL(l_nTg)
ENDIF

C_SQL="SELECT [dbo].[ChkStoredSubpImgs]  ('" +l_nRT+ "','" + ALLTRIM(STR(l_nTg) )+ "','" + l_cType + "')"

lnConn= resultsql(C_SQL, "HasRecord")
IF lnConn>0
	IF USED('HasRecord')
		SELECT HasRecord
		IF  !EOF()
			lexists=NVL(HasRecord.EXP,.F.)
		ENDIF
	ENDIF
ENDIF

IF NOT lexists && has no stored 'g/'r' file

	lnConn=0
*!*		C_SQL=" EXEC  dbo.InsertSubpDocs '" + ALLTRIM(l_nRT) + "','" + STR(l_nTg) + "','"  +  ;
*!*			l_cType + "','" +  ALLTRIM(l_cpath)+ "','" + ALLTRIM(l_corigfile) + "','" + ALLTRIM(PC_USERID) + "'"
	C_SQL=" EXEC  dbo.InsertRTScanMirrorDocs '" + ALLTRIM(l_nRT) + "','" + STR(l_nTg) + "','"  +  ;
		l_cType + "','" +  ALLTRIM(l_cpath)+ "','" + ALLTRIM(l_corigfile) + "','" + ALLTRIM(PC_USERID) + "'"

	lnConn= resultsql(C_SQL, "")

	IF lnConn>=1

		l_retval=.T.
	ELSE
		l_retval=.F.
	ENDIF

ENDIF

IF !EMPTY(cAlias)
	SELECT (cAlias)
ENDIF
RETURN l_retval

