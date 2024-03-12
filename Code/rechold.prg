*****************************************************************************
*EF  04/18/12-switched to SQl proc
* EF 10/06/05 -switched to SQL, removed timesheet entry selection
*****************************************************************************
*RecHold.Prg - Calculate record on hold flag.
*               Entry table must be opened before calling this function.
*
* History :
* Date      Name  Comment
* ---------------------------------------------------------------------------
* 10/17/97  Hsu   Initial release
*****************************************************************************

PARAMETERS lcRecordId
local lcWork as String
local lnHold as Integer, ln30 as Integer, ln51 as Integer
LOCAL oMed_t As Object

lcWork =ALIAS()
 oMed_t  = CREATEobject("generic.medgeneric")
STORE 0 TO lnHold,ln30,ln51
*l_Entry= oMed.sqlexecute ("Select id_tblTimesheet, cl_code, tag, txn_code "  ;
	+ " from tblTimesheet with (index (ix_tblTimesheet_4))" ;
	+ " where id_tblrequests ='" + lcRecordId + "' and txn_code in (30,51) " ;
	+ " and deleted is null" , "Timesheet")
	
l_Entry=  oMed_t.sqlexecute (" EXEC [dbo].[GetTimesheet_30_51] '" +  lcRecordId +"'", "Timesheet")
IF l_Entry
	SELECT Timesheet
	SCAN
		DO CASE
			CASE txn_code = 30
				ln30 = ln30 + 1
			CASE txn_code = 51
				ln51 = ln51 + 1
		ENDCASE

	ENDSCAN
	IF ln30 > ln51
		lnHold = 1
	ENDIF
ELSE
**no record
	=gfmessage("No Record Found")
*--	=MESSAGEBOX("No Record Found",64, "Set Hold for STCs")
ENDIF
RELEASE  oMed_t 
IF NOT EMPTY(lcWork)
	SELECT (lcWork)
ENDIF
RETURN lnHold
