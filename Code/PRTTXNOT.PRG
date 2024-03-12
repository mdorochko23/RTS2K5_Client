PROCEDURE PrtTXNot
* For a pre-selected case, locates all requests on a specific date.
* For each request, generates a Notice of Intention to Take Deposition
* by Written Questions, plus all individual question pages.
*********************************************************************************************
**EF 3/15/06 Added to the project.
*********************************************************************************************

* 06/09/04 DMA Extracted from TXNotice (routine PrtNotSet) into this routine

* Called from RunTxNot during end-of-day processing
* Called from TXNotice during reprint and subpoena processing
* Assumes that gfGetCas has already been called
* Calls: PWrQuest, PrtTXQst

PARAMETERS dThisdate
*PARAMETERS lcAtcode, dThisdate
PRIVATE c_descrip, c_mailid, c_quest, c_indquest, c_form, n_quest
_screen.MousePointer=11
dbInit = ALIAS()
 o = CREATE("generic.medgeneric")
SELECT TXNotice
SCAN FOR cl_code = pc_clcode AND txn_date = dThisDate
   *lcEntry = pc_EntryN
   *SELECT( lcEntry)  
   
   **10/01/18 SL #109598
   *c_sql="SELECT * FROM tbltimesheet with (index(IX_tblTIMESHEET)) WHERE cl_code='" + 
   c_sql="SELECT * FROM tbltimesheet WHERE cl_code='" + ;
			fixquote(PC_CLCODE) + "' and txn_code='"+ STR(11) + "' order by tag"	
	o.sqlexecute(c_sql,'Timesheet')
	
	SELECT Timesheet
    INDEX ON CL_CODE+"*"+STR(TAG) TAG CLTAG ADDITIVE 

   SET ORDER TO ClTag
   SEEK ( pc_clcode) + "*" + STR( TXNotice.Tag)
   c_descrip = ALLT( Descript)
   c_mailid = ALLT( MailID_No)
   * Generate notice of intention to take deposition by written question
   DO pWrQuest WITH TXNotice.Tag, c_Descrip, c_mailid

*   * Generate a copy of each set of written questions that will be used
   DO PrtTxQst WITH c_Descrip, c_mailid, Rq_Quest, TXNotice.Tag
   SELECT TXNotice
   gcCl_code = pc_clcode
   gnTag = TXNotice.Tag
   DO prtenqa WITH mv, mclass, "1", ""
ENDSCAN
SELECT (dbInit)
_screen.MousePointer=0
RETURN
