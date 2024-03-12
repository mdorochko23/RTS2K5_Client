
PARAMETERS c_AmCase
LOCAL l_RetVal as Boolean,  C_STR as String, oMed_acd as Object
oMed_acd = CREATEOBJECT("generic.medgeneric")

STORE .f. to l_RetVal


c_str=" exec  [dbo].[GetACDAMNumber] " + c_AmCase
l_RetVal=oMed_acd.sqlexecute(C_STR, "LitRps")
RELEASE oMed_acd
RETURN l_RetVal
	



