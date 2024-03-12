*PROCEDURE GETTXNOTIC
*******************************************************
* NOTICES FOR TX ISSUES BY DATE
PARAMETERS d_RunDate, n_rtnum
LOCAL l_RetVal as Boolean, l_done as Boolean, C_STR as String,  c_date as string
oMed = CREATE("generic.medgeneric")
STORE .f. to l_RetVal, l_done
c_Alias=ALIAS()
c_date=DTOC(d_RunDate)
C_STR=""

IF TYPE( "n_rtnum")="N"
n_rtnum=STR(n_rtnum)
ENDIF 

C_STR="Exec dbo.GetTXNotices '" + c_date + "','" + n_rtnum + "'"
l_done=oMed.sqlexecute(C_STR, "TxNotice")
IF l_done THEN
	l_RetVal=.T.	
	=CURSORSETPROP("KeyFieldList", "Cl_code, TXN_DATE,tag,RQ_AT_CODE", "TxNotice")
	INDEX ON ALLTRIM(user_code)+ALLTRIM(cl_code) FOR .NOT.PRINTED TAG TOPRINT ADDITIVE
	*INDEX ON ALLTRIM(user_code)+ALLTRIM(cl_code) TAG Reprint ADDITIVE
	*INDEX ON cl_code TAG  cl_code UNIQUE ADDITIVE


ENDIF
RELEASE oMed 
IF NOT EMPTY(c_Alias)
SELECT (c_Alias)
ENDIF 
RETURN l_RetVal
	
