FUNCTION gfAtType
* gfAtType
* returns "P" or "D" for plaintiff or defense
* Called by PrintCov
LPARAMETERS lcAtCode
LOCAL lnCurArea, lcSQLLine, retval, oGen
retval=""
lnCurArea=SELECT()

*oGen=CREATEOBJECT("medgeneric")
oGen=CREATEOBJECT('cntdataconn')

lcSQLLine="select dbo.getAttyName('"+alltrim(fixquote(lcAtCode))+"', 6)"

oGen.sqlpassthrough(lcSQLLine,"viewAtType")

SELECT viewAtType
IF RECCOUNT()>0
   retval=viewAtType.exp
ENDIF
USE 

release oGen
SELECT(lnCurArea)   
RETURN retval