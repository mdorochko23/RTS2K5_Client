*****************************************************************************
* gfAtName.PRG - Get attorney name from at code
*
* History :
* Date      Name  Comment
* ---------------------------------------------------------------------------
FUNCTION gfAtName
PARAMETERS lcAtCode
LOCAL lcSQLLine, lnCurArea, retval, oGen
lnCurArea=SELECT()
retval=""
*!*	IF TYPE("oGen")!="O"
*!*	   oGen=CREATEOBJECT("medgeneric")
*!*	   lloGen=.T.
*!*	ENDIF


*--8/6/20: trap for empty/null atcode values [18587]
lcAtCode=IIF(TYPE("lcAtCode")=="L" OR ISNULL(lcAtCode),"",lcAtCode)


oGen=CREATEOBJECT('cntdataconn')

lcSQLLine="select dbo.gfAtName('"+ALLTRIM(fixQuote(lcAtCode))+"')"
oGen.sqlpassthrough(lcSQLLine,"viewAtName")
*oGen.sqlexecute(lcSQLLine,"viewAtName")
SELECT viewAtName
IF RECCOUNT()>0
	*--8/6/20: trap for empty/null atcode values [186587]
	retval=NVL(viewAtName.EXP,"")
	*--retval=viewAtName.EXP
ENDIF
USE
*IF lloGen=.T.
RELEASE oGen
*ENDIF
SELECT (lnCurArea)
RETURN retval
*********************************************************************************
