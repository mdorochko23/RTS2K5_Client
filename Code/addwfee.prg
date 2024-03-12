PROCEDURE AddWFee
*** ADDWFEE.prg - Inserts a new Witness Fee transaction in TIMESHEET file
***               Also inserts an actual Check if Parameter l_RealChk is true
*
**EF 3/13/06 - Added to the vfp app.
*------------------------------------------------------------------------------------------
** Called by Subp_PA
** Calls GetChkNo
**
** kdl 08/23/02 - Linked service center mods
** KDL 07/2/02  - Fix error with uninitiated variable
** DMA 06/19/02 - Replace mlogname with pc_UserID
**                Update CreatedBy fields in check and timesheet files
**                Eliminate unused local variables
** DMA 06/04/02 - Add locking on Record file and update of Global Record file
** HN  12/05/01 - Initial release

PARAMETERS c_FeeType, n_FeeAmt, l_RealChk, c_Office

** c_FeeType   = Type of Witness Fee Account (WF1 = M, WF2 = X, WF3 = Y)
** n_FeeAmt = Dollar Amount of Txn 7
** l_RealChk = Whether or not to Generate a Check number or insert 0 for Chk #
** c_Office = The Office for which Witness Fee is added.

PRIVATE lnCount, lnTxnId, lcChkFile, laEnv, lcCurArea, c_entryname, c_alias

*--8/23/02 kdl start: need to initiat the service center id variable
PRIVATE c_servidno, c_ServDesc
c_servidno = ""      && serv cent id
c_ServDesc = ""      && serv cent key/desc
*--8/23/02 kdl end:
_SCREEN.MOUSEPOINTER=11
** Make sure tables are used and pointed correctly; otherwise, don't add any Wf txn.
DO CASE
	CASE NOT USED( "Request")
		RETURN
	CASE NOT USED( "master")
		RETURN
	CASE NOT INLIST( c_FeeType, "M", "X", "Y")
		RETURN
	CASE MASTER.cl_code <> REQUEST.cl_code
		RETURN
	CASE EMPTY( c_Office)
		RETURN
ENDCASE
c_alias= ALIAS()

lnCount    = IIF( l_RealChk, GetChkNo( c_Office), 0)
*lnTxnId    = getTxnId()        && Generate new Txn ID for this Txn.


**SET CLASSLIB TO timesheet.vcx ADDITIVE

oTS_FILE=CREATE("medtimesheet")
oTS_FILE.getitem(.NULL.)

** 5/5/05: MEI/PCL Legacy code, no longer needed.
*!*	SELECT (c_entryname)
*!*	INSERT INTO (c_entryname) ;
*!*	   (Cl_Code, Tag, Txn_date, Descript, Txn_code, ;
*!*	   Mailid_no, CreatedBy, Count, ;
*!*	   Txn_id, Active, Type, Wit_Fee) ;
*!*	   VALUES ;
*!*	   (TAMaster.Cl_Code, Record.Tag, d_today, Record.Descript, 7, ;
*!*	   Record.Mailid_No, pc_UserID, lnCount, ;
*!*	   lnTxnId, .T., c_FeeType, n_FeeAmt)

REPLACE ;
	cl_code WITH MASTER.cl_code, ;
	ID_tblRequests WITH REQUEST.id_tblRequests, ;
	TAG WITH REQUEST.TAG, ;
	Txn_date WITH DTOC(d_today), ;
	DESCRIPT WITH REQUEST.DESCRIPT, ;
	Txn_code WITH 7, ;
	MailID_No WITH REQUEST.MailID_No, ;
	CreatedBy WITH ALLTRIM(pc_UserID), ;
	COUNT WITH lnCount, ;
	ACTIVE WITH .T., ;
	TYPE WITH c_FeeType, ;
	Wit_fee WITH n_FeeAmt

oTS_FILE.updatedata
l_EntryID= oTS_FILE.sqlexecute("select dbo.fn_GetID_tblTimesheet ('" + fixquote(MASTER.cl_code) + "','" ;
	+ STR(nTag) +"','" + STR(7)+ "','" +DTOC(DATE()) +"')", "EntryId")
IF l_EntryID
	lc_TimesheetID=EntryId.EXP
ENDIF
DO  doIfcancel WITH "IfCancel","tblTimesheet",lc_TimesheetID, "D"

l_Addchk=.t.

IF l_RealChk
	** Insert a Check into the Checks file.
	STORE "" TO madd1, madd2, madd3, madd4, mattn

	*m.Descript = REQUEST.DESCRIPT     && m.Descript Needed by Mailinfo

	*--7/2/02 kdl start: eliminate reference to uninitiated variable
	*!*	   DO MailInfo WITH Request.Mailid_no, .F. IN WitFee    && This fills in address info
	*--kdl out 7/2/02: DO MailInfo WITH lcMailid, .F. IN WitFee    && This fills in address info
	*--7/2/02 kdl end:

	** 5/5/05: MEI/PCL Legacy code, no longer needed.
	*!*	   lcChkFile = IIF( c_Office = "T", f_CheckTx, f_checks)
	*!*	   SELECT 0
	*!*	   USE ( lcChkFile) AGAIN ALIAS ChkFile

	*--8/23/02 kdl start: include the service center ID

	*SET CLASSLIB TO timesheet.SET CLASSLIB TO checks.vcx
	*o=create("medchecks")
	*o.getitem(.null.)

	lc_str=""

	lc_str="Exec dbo.sp_AddChecks '" ;
		+ MASTER.cl_code + "','" ;
		+ ALLTRIM(pc_UserID) + "','" ;
		+ STR(lnCount) + "','" ;
		+ IIF( ALLT(c_servidno) == "", REQUEST.DESCRIPT, c_ServDesc) + "','" ;
		+ REQUEST.DESCRIPT + "','" ;
		+ STR(n_FeeAmt) +  "','" ;
		+ DTOC(d_today) + "','" ;
		+ madd1 + "','" ;
		+ madd2 + "','" ;
		+ madd3 + "','" ;
		+ madd4 + "','" ;
		+ STR(REQUEST.TAG) +"','" ;
		+ c_servidno + "','" ;
		+ REQUEST.MailID_No + "','" ;
		+ mattn + "','" ;
		+ ALLTRIM(pc_UserID) + "','"  ;
		+ lc_TimesheetID + "'"



	*replace cl_code WITH Master.Cl_Code, ;
worker WITH ALLTRIM(pc_UserDpt), ;
check_no WITH lnCount, ;
deponent WITH IIF( ALLT(c_servidno) == "", request.Descript, c_ServDesc), ;
descript WITH Request.Descript, ;
check_amt WITH n_FeeAmt,;
check_date WITH DTOC(d_today),;
add1 WITH madd1,;
add2 WITH madd2,;
add3 WITH madd3,;
add4 WITH madd4,;
tag WITH Request.Tag,;
servid_no WITH c_servidno,;
mailid_no WITH Request.MailID_No,;
attention WITH mattn,;
CreatedBy WITH ALLTRIM(pc_UserID)
	l_Addchk=oTS_FILE.sqlexecute(lc_str,"")

	IF NOT l_Addchk
		gfmessage("No Check has been added. Contact IT. ")
	ELSE
		DO  doIfcancel WITH "IfCancel","tblChecks","lc_TimesheetID", "D"

	ENDIF

	*o.updatedata



	** 5/5/05: MEI/PCL Legacy code, no longer needed.
	*!*	   SELECT ChkFile
	*USE
ENDIF
IF l_Addchk
	SELECT REQUEST
	** 5/5/05: MEI/PCL Legacy code, no longer needed.
	*!*	DO WHILE NOT RLOCK()
	*!*	ENDDO
	REPLACE REQUEST.Wit_fee WITH REQUEST.Wit_fee + n_FeeAmt
	c_sql = "Update tblRequest set Wit_fee =" + STR(n_FeeAmt)  + ;
		" WHERE CL_CODE='" + fixquote(pc_clcode) + "' and tag = '" + ;
		+ STR(nTag) + "'"

	l_recupd= oTS_FILE.sqlexecute (c_sql,"")
	_SCREEN.MOUSEPOINTER=0
	IF NOT l_recupd
		gfmessage("Cannot update the witness fee data in the Request table. Contact IT.")
	ENDIF
ENDIF
*UNLOCK
*!*	DO GlobUpd WITH "RECORD", RECNO()
SELECT (c_alias)

RETURN
