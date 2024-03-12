PROCEDURE TXCrtLtr
*
*   Print Texas Court Filing Letters, with accompanying notices and questions
*
**********************************************************************
** EF 03/15/06 - Added to the VFP project.
**--------------------------------------------------------------------
**DMA 06/28/04 Replace bNot with pl_Noticng
**DMA 06/09/04 Move UpdNotFile module here from RunTxNot
**EF  01/03/02 Call this program from 'N-reprint Notice'
**EF  11/27/01 Texas Court Filing Letter with notices
**********************************************************************
* Called from RunTxNot, TxNotice
*
* Calls gfGetCas, gfClrCas, PrtTXCrt, pWrQuest, PrtTXQst, PrtEnqA (in TA_Lib)
*
* For calls from RunTxNot (end-of-day noticing for multiple cases)
*     pl_RepNotc will be .F.
*     lcclCode will be ""
*     gfGetCas will NOT have been previously called, but is called here
*
* For calls from Plaintif -> Reprint -> TxNotice
* (to reprint a single case's notices for a specific date)
*     pl_RepNotc will be .T.
*     lcClCode identifies the case whose notices are being reprinted
*     gfGetCas will have been previously called
*
PARAMETERS dThisDate
&& lcclcode
PRIVATE c_notcdate, l_CrtNot 
c_notcdate = DTOC( dThisDate)

dbInit = ALIAS()

*IF USED( "CrtNotic")
  * SELECT CrtNotic
*ELSE
  * SELECT 0
   *USE ( f_CrtNotice)
*ENDIF
LOCAL oMstr as medMaster OF Master 
oMstr=CREATEOBJECT("medMaster")
IF NOT USED('CrtNotice')
		l_CrtNot=getCrtNotic(dThisDate)
		IF NOT l_CrtNot
			gfmessage( "Cannot get TX CrtNotic file")
			RETURN
		ENDIF
	ENDIF

SELECT CrtNotic
IF _TALLY=0
   gfmessage("No Letters to Printer.")
return
ENDIF
IF pl_RepNotc
   * Reprint a selected case's court letters for a single day
   SET ORDER TO NtcList
   * Unique index -- locates first entry for specific case and date
   *SEEK lcclcode + c_NotcDate
   SEEK PC_clcode + c_NotcDate
   * For reprints, match against both date and case
   lScan = "Txn_date = dThisDate  " &&AND cl_code = lcclcode"
ELSE
   * End-of-day notices -- produce that day's court letters
   SET ORDER TO CntyDate
   * Unique index -- locates first unprinted entry for date/county/client code
   SEEK c_NotcDate
   * For originals, match only against date
   lScan = "Txn_date = dThisDate"
ENDIF




WAIT WINDOW "Printing court letter(s). Please wait." NOWAIT NOCLEAR 

SCAN FOR &lScan
   IF NOT pl_RepNotc
   
   l_gotMasterid=oMed.sqlexecute("SELECT DBO.fn_GetID_tblmaster('" + fixquote(CrtNotic.Cl_Code) + "')", "MasterID")
      IF  NOT l_gotMasterid
      	gfmessage("Data processing error. Try again or contact IT dept." )
      	RETURN 
      ENDIF
      
      oMstr.getitem(Masterid.exp)
       
    SELECT MASTER      
      pl_GotCase = .F.
      DO gfGetCas &&WITH .T.
   ENDIF

   *SELECT (lcEntry)
  * SET ORDER TO Status

   *IF NOT USED( "TXnotice")
    *  USE (F_TXNotice) IN 0
   *ENDIF
   l_TxNot=GetTxNotic(dThisDate)
		IF NOT l_TxNot
			gfmessage("Cannot get TX Notice file")
			RETURN
		ENDIF
   SELECT TXNotice
   SET ORDER TO NtcList
   SEEK pc_ClCode + c_NotcDate


   * Go through the main TX notice file for the selected case and date
   * and print the following items:
   *   1) If requests are filed by subpoena, a single court filing letter
   *      for the case and county.
   *   2) For each individual request, print a notice of intention to take
   *      deposition by written questions PLUS a copy of each set of
   *      questions associated with the individual request.
	o = CREATEOBJ("generic.medgeneric")
    IF TXNotice.Type <> "A"
      * Print Court Filing Letter
      DO PrtTXCrt
      SCAN FOR cl_code = pc_clcode AND txn_date = dThisDate


        * SELECT (lcEntry)
         *SET ORDER TO Status
         *SEEK pc_ClCode + "*" + STR( TXNotice.Tag)
         **10/01/18 SL #109598
		*" FROM tbltimesheet with (index(IX_tblTIMESHEET)) WHERE cl_code='" + 
		c_sql="SELECT cl_code,TAG,descript, " + ;
		  	" mailid_no,Rq_Quest, txn_date, type " + ;
			" FROM tbltimesheet WHERE cl_code='" + ;
			fixquote(PC_CLCODE) + "' and txn_code=11 and tag ='" + STR(	TXNotice.Tag) + "' and active=1"	

		o.sqlexecute(c_sql,'Timesheet')
		
         pl_noticng = .F.
         * Print Notice of Intention to take deposition by written questions
         DO pWrQuest WITH Timesheet.TAG, alltrim(Timesheet.descript), ;
            ALLTRIM(Timesheet.mailid_no)
         * Print out each individual set of questions required for the deposition
         DO PrtTxQst WITH Timesheet.descript, ;
               Timesheet.mailid_no, Timesheet.Rq_Quest, Timesheet.tag
         gcCl_code = pc_ClCode

         DO prtenqa WITH mv, mclass, "1", ""
         SELECT TXNotice
      ENDSCAN
   ENDIF
   SELECT CrtNotic
ENDSCAN
IF NOT pl_RepNotc
   DO gfClrCas
ENDIF
WAIT CLEAR 
** 06/09/04 DMA Move file-update routine internal; only used here.
** 02/18/02 Update both files for printed notices and court letters
**DO UpdNotFile WITH C_NotcDate, "Txnotice"
**DO UpdNotFile WITH C_NotcDate, "CrtNotic"
**ACTIVATE LATER 3/16/06

Return
*******************************************************************************
* 06/09/04 DMA Moved code here from RunTxNot; only used by this module
*              Processing date removed from parameter list and now
*              received by inheritance.
PROCEDURE UpdNotFile
PARAMETERS d_NotcDate, c_FileName
PRIVATE n_File as Number
n_File=IIF(c_FileName="Txnotice", 1,2)
oUP = CREATEObj("generic.medgeneric")

l_UpdTX= oUP.sqlexecute("Exec dbo.sp_UpdTxNotice " ;
				+ STR(n_File) + ",'" + d_NotcDate + "'", "")
			IF NOT l_UpdTX				
				gfmessage("Error in the program. Contact IT.")
			ENDIF


RETURN
