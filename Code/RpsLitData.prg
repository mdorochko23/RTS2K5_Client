
PARAMETERS c_code
LOCAL l_RetVal as Boolean,  C_STR as String
oMed = CREATEOBJECT("generic.medgeneric")

STORE .f. to l_RetVal


c_str=" exec  [dbo].[GetRPSLitData] " + c_Code
l_RetVal=oMed.sqlexecute(C_STR, "LitRps")

RETURN l_RetVal
	



