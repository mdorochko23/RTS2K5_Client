*FUNCTION RetrLinkMid
** 06/06/2011: check all (even inactive locatons-dbo.GetDepInf_All)
** 09/16/2010: called from a tag mirror : do not mirror Retired or linked deponents
PARAMETERS lc_Mid
LOCAL oMirr AS OBJECT
LOCAL lc_str AS STRING, c_retval AS STRING
STORE "" TO lc_str, c_retval
oMirr = CREATEOBJ("generic.medgeneric")

lc_str="EXEC dbo.GetDepInf_All '" + lc_Mid + "'"
oMirr.sqlexecute(lc_str, 'Mirrdeponent')

IF Mirrdeponent.retire=.T.
	c_retval ="The Mail ID is retired, tag mirror not permitted."
ENDIF
** a linked mid
oMirr.sqlexecute("SELECT dbo.getlinkedmailid ('" +lc_Mid + "')", "LinkedMirr")
SELECT LinkedMirr
IF NOT EOF()
	IF NOT EMPTY(NVL(ALLTRIM(LinkedMirr.EXP),""))
		c_retval="That deponent has been linked to another location. Please use a linked MailId to mirror a tag."
	ENDIF
ENDIF
RELEASE oMirr
RETURN c_retval
&&09/16/2010- do not mirror retired or linked deponents
