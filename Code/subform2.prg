PARAMETERS nRt, nTg, cCourt
**11/02/2016: added 2nd form for LehighCo #52199
**09/19/2016 :  added 2nd form for the PA-bucks #48982
LOCAL l_oldform AS Boolean

**Check if old or new form by an issue date
_SCREEN.MOUSEPOINTER=11
PRIVATE oMEDS AS OBJECT
oMEDS=CREATEOBJECT("generic.medgeneric")
SELECT 0
l_oldform=.T. && assume we use an old one

	oMEDS.closealias ('SubForm')	
	oMEDS.sqlexecute("SELECT dbo.IfOldSubpForm2('" + STR(nRt)+ "','" + ALLT(STR(nTg)) + "','" + alltrim(cCourt )+ "')", "SubForm")
	l_oldform= NVL(subform.EXP, .F.)	
	

RELEASE oMEDS
	_SCREEN.MOUSEPOINTER=0
RETURN l_oldform
