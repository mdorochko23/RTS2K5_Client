PROCEDURE gfAddTxn
*** Insert a new timesheet transaction in the EntryX file
** DMA 06/19/2002 Eliminate login ID as a passed parameter
** DMA 05/29/2002 Fill in CreatedBy field with user's login ID
** DMA 01/18/2001 Eliminate dependency on use of "Select Area F"
**                Instead, assume that the entry file is open, but
**                w/o requiring a specific work area.
** HN  02/13/1998 Original programming
***    Assumes correct Entry file is open in Work Area F
**
** Called by AddPhnTx, AddTxn14, CaseFlt2, Confirm, DepOpts, FLook,
**           Incoming, PhoneTxn, Prt2Rq, RCUWand, Subp_PA, OrdCancl,
**           MemoTxn, MailIDFx
**
** Calls gfEntryN, getTxnID, gfPop, gfPush

PARAMETERS ldTxnDate, lcDescript, lcClient, lcTxnCode, lcTag, lcMailid, ;
   lnUnits, lnCount, lcO, lnTxnId, lcRq_Quest
** ldTxnDate    Date of transaction
** lcDescript   Description (usually deponent name)
** lcClient     Client code
** lnTxnCode    Transaction code
** lnTag        Tag number
** lcMailID     MailID # of deponent
** lnUnits      Number of billing units expended (e.g., fractional hours)
** lnCount      Count of pages received
** lcO          Indicates if we received original/copy/duplicate/etc.
** lnTxnID      Transaction ID # (will be acquired if 0)
** lcRq_Quest   Attorney code of requesting attorney when called by Fax2Rq0
**              "FIRSTLOOK2" when called by Flook
**              Otherwise unused

PRIVATE laEnv
** MEI(PCL) 4/21/05: Legacy Code. No longer needed.
**PRIVATE lcCurArea, c_entryname
DIMENSION laEnv[1,3]
=gfPush( @laEnv)

** MEI(PCL) 4/21/05: Legacy Code. No longer needed.
*!*	c_entryname = gfEntryN( lcClient)

** MEI(PCL) 4/21/05: Legacy Code. No longer needed.
*!*	IF EMPTY( lntxnid)
*!*	   lnTxnId = getTxnId()
*!*	ENDIF

** MEI(PCL) 4/21/05: Legacy Code. No longer needed.
*!*	SELECT ( c_entryname)
SET CLASSLIB TO timesheet.vcx

o=create("medtimesheet")
o.getitem(.null.)

** MEI(PCL) 4/21/05: Legacy Code. No longer needed.
*!*	INSERT INTO ( c_entryname) ;
*!*	   ( Cl_Code, Tag, Txn_date, Txn_code, Descript, ;
*!*	    Units, Count, O, Mailid_no, Rq_Quest, Soc, Txn_id, CreatedBy ) ;
*!*	   VALUES ;
*!*	   ( lcClient, lnTag, ldTxnDate, lnTxnCode, lcDescript, ;
*!*	    lnUnits, lnCount, lcO, lcMailid, lcRq_Quest, pc_UserID, lnTxnId, pc_UserID )

replace timesheet.CL_Code	WITH lcClient;
	,timesheet.Tag			WITH lcTag;
	,timesheet.due_date		WITH ldTxnDate;
	,timesheet.Txn_date		WITH ldTxnDate;
	,timesheet.Txn_code		WITH lcTxnCode;
	,timesheet.Descript		WITH lcDescript;
	,timesheet.Units		WITH lnUnits;
	,timesheet.Count		WITH lnCount;
	,timesheet.O			WITH lcO;
	,timesheet.Mailid_no	WITH lcMailid;
	,timesheet.Rq_Quest		WITH lcRq_Quest;
	,timesheet.Soc			WITH goApp.CurrentUser.pc_UserID;
	,timesheet.Txn_id		WITH lnTxnId;
	,timesheet.CreatedBy 	WITH goApp.CurrentUser.pc_UserID

o.updatedata

=gfPop( @laEnv)

RETURN
