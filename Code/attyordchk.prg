PARAMETERS lcClient as String, lnTgnum as Integer
*************************************************************************
**09/26/12 -check for at least 1 ordering atty before we allow to issue
*************************************************************************
LOCAL l_Retval
LOCAL oMedatty as Object
oMedatty= CREATEOBJECT("generic.medgeneric")
oMedatty.closealias("OrdCheck")
l_Retval =.F.

oMedatty.sqlexecute("Select dbo.ChkOrderingAtty('" + fixquote(lcClient) + "','" + STR(lnTgnum) +"')","OrdCheck")
IF NVL(OrdCheck.EXP,0)=0


	lc_message ="Please edit the case. A case should have at least one ordering attorney."
	o_message = CREATEOBJECT('rts_message',lc_message)
	o_message.SHOW
	l_Retval=.T.

	ENDIF
	
RELEASE oMedatty

RETURN  l_Retval