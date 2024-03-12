PARAMETERS lcAtty as String, llShow as Boolean
*************************************************************************
**02/01/17 -Check for a bankrupt/credit hold atty  #57300	
*************************************************************************
LOCAL l_Retval
LOCAL oMedatty as Object
oMedatty= CREATEOBJECT("generic.medgeneric")
oMedatty.closealias("CheckH")
l_Retval =.F.

oMedatty.sqlexecute("SELECT dbo.fn_AttyBillStatus('" + lcAtty + "')","CheckH")
IF NVL(CheckH.EXP,.f.)  =.t.
	l_Retval=.T.
ENDIF

IF   llShow AND l_Retval

	lc_message ="The Tag can't be issued due to a credit hold.  Please notify the client representative."
	o_message = CREATEOBJECT('rts_message',lc_message)
	o_message.SHOW
	

ENDIF
	
RELEASE oMedatty

RETURN  l_Retval