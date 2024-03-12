**FUNCTION TgState
PARAMETERS cMailId

LOCAL c_state as String, c_str AS STRING, omed_n AS OBJECT
c_state=""
omed_n=CREATEOBJECT("medgeneric")
omed_n.closealias("LocSt")
IF !EMPTY(ALLTRIM( cMailId))
	c_str="exec dbo.GetLocState '" + cMailId+"'"
	omed_n.sqlexecute(c_str,"LocSt")

	IF NOT EOF()
		c_state=LocSt.state
	ENDIF
	RELEASE omed_n
ENDIF

RETURN c_state
