*FUNCTION subform
PARAMETERS nRt, nTg
**09/19/2016 :  added 2nd form for the PA-bucks #48982
LOCAL l_oldform AS Boolean

**Check if old or new form by an issue date
_SCREEN.MOUSEPOINTER=11
PRIVATE oMEDS AS OBJECT
oMEDS=CREATEOBJECT("generic.medgeneric")
SELECT 0
l_oldform=.T. && assume we use an old one

*F CHECKTEST("OLDBUCKS")=.F. && TESTERS ONLY : remove when production
	oMEDS.closealias ('SubForm')
	oMEDS.sqlexecute("SELECT dbo.IfOldBuckSubp('" + STR(nRt)+ "','" + ALLT(STR(nTg)) + "')", "SubForm")
	l_oldform= NVL(subform.EXP, .F.)	
	*DO addlogline  WITH  ntg , IIF(l_oldform,'OldSubp','NewSubp'), "--TestBucks--"
*NDIF

RELEASE oMEDS
	_SCREEN.MOUSEPOINTER=0
RETURN l_oldform
