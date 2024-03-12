**************************************************************
FUNCTION oldIssue
**09/19/2017 : Returs if a TX issue  is done before a cut off date or after: new docs released on 9/21/17
**************************************************************
PARAMETERS  c_lrs, ntg
LOCAL l_oldform	 AS Boolean, c_alias  AS STRING
PRIVATE OMED AS OBJECT
OMED=CREATEOBJECT("generic.medgeneric")

l_oldform	=.T. && assume it is an old issue
c_alias =ALIAS()
oMed.closealias ('OldForm')
oMed.sqlexecute("SELECT dbo.IfOldTxSubp('" + STR(c_lrs)+ "','" + ALLT(STR(ntg)) + "')", "OldForm")
l_oldform= NVL(Oldform.EXP, .F.)
IF !EMPTY(c_alias )
	SELECT (c_alias )
ENDIF
RELEASE OMED
RETURN l_oldform