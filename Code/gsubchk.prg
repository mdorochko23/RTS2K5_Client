PARAMETERS lcRT as String, lnTgnum as Integer
*************************************************************************
**04/21/15 -check for "G" subp type - reurned from a court 
*************************************************************************

LOCAL oMeda as Object
LOCAL lExists AS Boolean
lExists=.T.
oMeda= CREATEOBJECT("generic.medgeneric")
oMeda.closealias("Subpg")
l_Retval =.F.
c_sql="select  [dbo].[ChkReturnMDSubp] ('" +  lcRT+ "','" +  str(lnTgnum )+ "')"
oMeda.sqlexecute(c_sql,"Subpg")
	IF USED ("Subpg") AND NOT EOF()
		lExists=NVL(Subpg.EXP,.F.)
	ENDIF
	
RELEASE oMeda

RETURN  lExists
