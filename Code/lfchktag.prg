*FUNCTION lfChktag
PARAMETER n_TmpTag
PRIVATE n_CurArea, n_Recno, c_Order
n_CurArea = SELECT()
_SCREEN.MOUSEPOINTER=11
IF USED('SupplRec')
	SELECT SupplRec
	USE
ENDIF
IF TYPE("oMed")<>"O"
	oMed= CREATEOBJECT("generic.medgeneric")
ENDIF
C_STR="Exec DBO.GetSingleMasterRequest '" + fixquote(MASTER.CL_code) + "','" ;
	+ STR(n_TmpTag) + "'"


l_Retval= oMed.sqlexecute(C_STR,"SupplRec")
_SCREEN.MOUSEPOINTER=0
SELECT SupplRec
IF EOF()
	lc_message = "Entered tag does not exist. Try again."
	o_message = CREATEOBJECT('rts_message',lc_message)
	o_message.SHOW

	n_TmpTag = 0
ENDIF

SELECT ( n_CurArea)
RETURN n_TmpTag