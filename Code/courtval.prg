
PARAMETERS CourtCode
** Find out if a court is valid
PRIVATE hasit, courtuse, currfile
LOCAL o_court as Object
currfile = ALIAS()
courtuse = .F.



IF USED("court")
	courtuse = .T.
	SELECT court
	hasit = .F.
ELSE
	o_court= CREATEOBJ("generic.medgeneric")
	o_court.sqlexecute("exec dbo.GetAllCourt", "court")
	hasit = .F.
ENDIF

GO TOP
SCAN
	IF ALLTRIM( UPPER(court.court)) == ALLTRIM(NVL(UPPER(CourtCode),""))
		hasit = .T.
		EXIT
	ENDIF
ENDSCAN

IF EMPTY(ALLTRIM(NVL(CourtCode,"")))
	hasit = .F.
ENDIF

IF NOT EMPTY(currfile)
	SELECT (currfile)
ENDIF
RELEASE o_court
IF hasit
	RETURN .T.
ELSE
	RETURN .F.
ENDIF