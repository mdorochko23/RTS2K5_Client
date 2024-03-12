PROCEDURE ADDTXN21
* Add a 21 [Cancellation] transaction to the timesheet and
* update request status in Record
* Called by DepOpts
* Calls SetRec, GetSSN, GetTxnID, GlobUpd
*
** 01/20/05 DMA Remove use of TAMaster.Worker field in Comment.dbf
** 03/23/04 DMA Reset research flag to .F.
** 03/20/03 EF  Reset Pickup to .f.
** 06/18/02 DMA Replace mlogname with pc_UserID
** 06/04/02 DMA Fill in Comment.CreatedBy; Update Global Record
** 05/09/02 DMA Update comments; fill in EntryX.CreatedBy
** 01/24/02 DMA Replace choice w/n_whichdep

** 5/5/05: MEI/PCL Legacy code, no longer needed.
*!*	SELECT F
*!*	SET ORDER TO cltag

*!*	APPEND BLANK
*!*	FLUSH
*!*	DO WHILE NOT RLOCK()
*!*	ENDDO

* Assign unique ID number to new Timesheet record!!

SET PROCEDURE TO ta_lib
REPLACE Txn_ID WITH GetTxnID()
SET PROCEDURE TO

DO GetSsn

SET CLASSLIB TO timesheet.vcx

o=create("medtimesheet")
o.getitem(.null.)

REPLACE ;
   CreatedBy WITH goApp.CurrentUser.pc_UserID, ;
   Cl_code WITH getPub("pc_clcode"), ;
   Tag WITH record.tag, ;
   Descript WITH m.descript, ;
   Mailid_no WITH record.mailid_no, ;
   Txn_code WITH 21, ;
   Txn_date WITH m.date, ;
   Wit_fee WITH 0, ;
   Count WITH mCount

o.updatedata

**    replace units WITH Mun
** 5/5/05: MEI/PCL Legacy code, no longer needed.
*!*	FLUSH
*!*	UNLOCK ALL
*!*	FLUSH

IF NOT EMPTY(m.comments)
	SET CLASSLIB TO comment.vcx

	o=create("medcomment")
	o.getitem(.null.)

	** 5/5/05: MEI/PCL Legacy code, no longer needed.
	*!*	   SELECT 0
	*!*	   USE (f_comment)
   * 01/20/2005  DMA  Remove use of TAMaster.Worker field in Comment.dbf
   REPLACE ;
      cl_code WITH getPub("pc_clcode"), ;
      descript WITH m.descript, ;
      txn_date WITH m.date, ;
      txn_code WITH 21, ;
      tag WITH request.tag, ;
      count WITH mcount, ;
      mailid_no WITH request.mailid_no, ;
      txn_id WITH f.txn_id, ;
      comment WITH m.comments, ;
      createdby WITH goApp.CurrentUser.pc_UserID
      
	o.updatedata
   	  *      ( cl_code, descript, worker, txn_date, txn_code, tag, ;
      *      count, mailid_no, txn_id, comment, createdby) ;
      *      VALUES ;
      *      ( pc_clcode, m.descript, tamaster.worker, m.date, 21, record.tag, ;
      *      mcount, record.mailid_no, f.txn_id, m.comments, pc_UserID)
	** 5/5/05: MEI/PCL Legacy code, no longer needed.
	*!*	   SELECT Comment
	*!*	   USE
ENDIF

** 5/5/05: MEI/PCL Legacy code, no longer needed.
*!*	SELECT F
*!*	SET ORDER TO cltag
*!*	FLUSH

** Set status of record to Request Cancelled.
SELECT request
IF INLIST( getPub("pc_status"), "W", "I") AND EMPTY(NVL(request.hStatus,''))
	** 5/5/05: MEI/PCL Legacy code, no longer needed.
	*!*	   DO WHILE NOT RLOCK()
	*!*	   ENDDO
   REPLACE request.Status WITH "C"
   setPub("pc_status") = "C"
   REPLACE request.Fin_Date WITH d_today
   * 03/23/04 DMA Turn off research flag
   REPLACE request.Research WITH .F.
   REPLACE request.Pickup WITH .F.               &&Reset Pickup flag
** 5/5/05: MEI/PCL Legacy code, no longer needed.
*!*	   UNLOCK
*!*	   DO GlobUpd WITH "RECORD", RECNO()
ENDIF

DO SetRec WITH n_whichdep, holddays
** 5/5/05: MEI/PCL Legacy code, no longer needed.
*!*	SHOW GETS
*!*	KEYBOARD "{Ctrl+w}"
RETURN
