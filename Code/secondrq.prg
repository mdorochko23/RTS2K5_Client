PROCEDURE SecondRQ

*  Called by Subp_PA
*  Calls EscDisab, EscKey
*/  deponent selection for second request / reprint request
*/
*/  Program History:
*/ -----------------------------------------------------------
*/  11/21/05 - EF -
*/  11/07/05 - EF - Swithed to Sql
*/  10/20/99 - Y2K Use DTOS for dates in popup
*/  09/11/97 - initial release (Mark Rizzo)
*/
PARAMETERS tag2req
PRIVATE c_mailid, c_TimesheetID
c_TimesheetID=.NULL.
**c_mailid = Record.MailID_No
**mID = c_mailID
*/ RTS backward compatibility
*/    bSelect, mID,
ON KEY LABEL "Ctrl+W"
ON KEY LABEL "ESC"
ON KEY LABEL "Ctrl+Enter"
bSelect = .F.
c_code=oMed.cleanstring(MASTER.cl_code)
SELECT 0
WAIT WINDOW "Getting a request's instructions" NOWAIT NOCLEAR 

l_ViewSpec=oMed.sqlexecute("exec dbo.GetViewRequest " + c_code +",'" + STR(tag2req) + "'", "Spec_ins")

IF l_ViewSpec
	SELECT spec_ins
	IF NOT EOF()
		c_TimesheetID=ListSubp()
	ENDIF
	*ELSE
		*RETURN
		*WAIT WINDOW "No Special Instruction data found." NOWAIT
	*ENDIF
ELSE	
	gfmessage("No Special Instruction data.")
	RETURN
ENDIF
DO ListSubp &&WITH szCl_Code

*SELECT f
*set order to cl_code
ON KEY LABEL "Ctrl+W" KEYBOARD ""
ON KEY LABEL "ESC" KEYBOARD ""
ON KEY LABEL "Ctrl+Enter" KEYBOARD ""
*/ end backward compatibility
WAIT CLEAR 
RETURN c_TimesheetID

*******************************************************************************
