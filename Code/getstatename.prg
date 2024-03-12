*3/23/09 - get a court's state name for USDC docs
*FUNCTION GetStateName
PARAMETERS c_StateCode
PRIVATE oTmp as Object, c_retname as String
c_retname=""
oTmp = CREATE("medgeneric")
oTmp.sqlexecute("select dbo.gfState ('" + c_StateCode + "')", "StateName")
c_RetName = ALLTRIM(StateName.exp)
USE IN StateName
RELEASE oTmp
RETURN c_RetName