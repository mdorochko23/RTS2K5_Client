PARAMETERS c_client
LOCAL l_RetVal as Boolean, l_done as Boolean, C_STR as String, oMedBill as Object
oMedBill= CREATEOBJ("generic.medgeneric")
c_Clcode=oMedBill.cleanstring(c_client)

STORE .f. to l_RetVal, l_done
C_STR="exec [dbo].[GetBillsbyClcode] " +  c_Clcode	
 
 
l_done=oMedBill.sqlexecute(C_STR, "Tabills")
IF l_done THEN
	l_RetVal=.T.	
	=CURSORSETPROP("KeyFieldList", "ID_TblBills,Cl_code, AT_code", "Tabills")
	INDEX ON CL_CODE + AT_CODE TAG clac ADDITIVE
	INDEX ON CL_CODE TAG CL_CODE ADDITIVE
ENDIF
RELEASE oMedBill
RETURN l_RetVal
	
