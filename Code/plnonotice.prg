PARAMETERS lcClient as String

LOCAL l_Retval
LOCAL oMedatty as Object
oMedatty= CREATEOBJECT("generic.medgeneric")
oMedatty.closealias("IssueContinue")
l_Retval =.F.
**1/9/2019 -check for at least 1 plaintiff atty not being inhibited in a case for sub issues #121772
oMedatty.sqlexecute("select dbo.checkNoNoticePlAttys('" + fixquote(lcClient) + "')","IssueContinue")
IF NVL(IssueContinue.EXP,.f.)=.f.	


	lc_message ="Counsel notices can't be inhibited. Please update the cases attorney settings to issue a subpoena request."
	o_message = CREATEOBJECT('rts_message',lc_message)
	o_message.SHOW
	l_Retval=.T.

	ENDIF
	
RELEASE oMedatty

RETURN  l_Retval