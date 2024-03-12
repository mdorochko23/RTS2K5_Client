PARAMETERS d_RunDate
**, c_clcode
LOCAL l_RetVal as Boolean, l_done as Boolean, C_STR as String
oMed = CREATEOBJ("generic.medgeneric")
STORE .f. to l_RetVal, l_done

C_STR="SELECT * FROM tblCrtNotic with (nolock)" ; 
+ " where txn_date ='" + DTOC(d_RunDate) ;
 + "' and active=1 Order by tag "
 &&+ "' and cl_code='" + fixquote(c_clcode)
l_done=oMed.sqlexecute(C_STR, "CrtNotic")
IF l_done THEN
	l_RetVal=.T.	
	=CURSORSETPROP("KeyFieldList", "ID_Tblcrtnotic,Cl_code, TXN_DATE, tag  ", "CrtNotic")
	INDEX ON RQ_AT_CODE TAG RQ_AT_CODE ADDITIVE
	INDEX ON COUNTY TAG COUNTY ADDITIVE
	INDEX ON CL_CODE+DTOC(TXN_DATE) UNIQUE TAG NTCLIST ADDITIVE
	INDEX ON DTOC(TXN_DATE)+COUNTY+CL_CODE UNIQUE FOR .NOT.DELETED().AND..NOT.PRINTED TAG CNTYDATE ADDITIVE
	INDEX ON CL_CODE TAG CL_CODE ADDITIVE

ENDIF
RETURN l_RetVal
	
