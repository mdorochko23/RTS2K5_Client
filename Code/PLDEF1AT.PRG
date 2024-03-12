PARAMETERS lcClient as String

LOCAL l_Retval
LOCAL oMedatty as Object
oMedatty= CREATEOBJECT("generic.medgeneric")
oMedatty.closealias("IssueContinue")
l_Retval =.F.
**05/02/12 -check for at least 1 plaintiff and 1 defense atty in a case for sub issues
oMedatty.sqlexecute("select dbo.ChkOnePlandDefAtty('" + fixquote(lcClient) + "')","IssueContinue")
IF NVL(IssueContinue.EXP,.f.)=.f.	


	lc_message ="Please edit the case. A case should have at least one plaintiff and one defense attorney."
	o_message = CREATEOBJECT('rts_message',lc_message)
	o_message.SHOW
	l_Retval=.T.

	ENDIF
	
RELEASE oMedatty

RETURN  l_Retval