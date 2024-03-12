PROCEDURE gfReopen
* Purpose   Handle automated re-open of closed cases
*           Assumes that gfGetCas has been previously called.
*  Calls    MastUpd, MemoTxn, gfChkPln
*  Called By TABills, Orders, AcManOrd, DepStat

PARAMETER l_warning, c_msgtxt
*  l_warning = .F. -> Just issue warning
*  l_warning = .T. -> Reopen case and add Tag 0 memo
*  c_msgtxt: text to include in on-screen warning message or Tag 0 memo
*  02/20/2009 EF Copy Timesheet transaction for closed B & B cases
*  10/07/2007 MD modfied to reopen TS records
*  03/09/2006 DMA Call UpdateCaseHeader.prg after reopening a case
*  11/07/2005 MD modified to replace DOL date with {} not NULL
*  11/03/2005 MD modified to comment 'IF _screen.ActiveForm.ep.get("pl_BBCase")'
*--10/20/05 kdl start: convert to SQL server

LOCAL n_curarea, ll_used

LOCAL oMstr as medMaster OF Master 
LOCAL oMedr as medrequest OF request
* 03/09/06 DMA Moved CreateObject to the point where they're actually needed
oMstr = CREATEOBJECT( "medMaster")
oMedr = CREATEOBJECT( "medrequest")
IF pl_BBCase
   * Treat Berry & Berry cases (any litigation) as an exception,
   * and do not re-open the case.
   **02/20/2009 EF
    lcSQLLine="exec dbo.reOpenCase '"+ALLTRIM(pc_clcode)+"'"
    oMstr.sqlexecute(lcSQLLine)
   **02/20/2009 EF
   RETURN
ENDIF
IF NOT l_warning
	c_msg = "This case is currently closed." + CHR(13) + ;
	      ALLT( c_msgtxt) + CHR(13) + ;
	      "will cause the case to be automatically re-opened." 
	o_message = CREATEOBJECT( 'rts_message', c_msg)
	o_message.SHOW
	RELEASE o_message
ELSE
   n_curarea = SELECT()
   ll_used = .T.
   * 03/09/06 DMA Move CreateObject activity here...
   *oMstr = CREATEOBJECT( "medMaster")
  * oMedr = CREATEOBJECT( "medrequest")
   IF NOT USED( "Master")	   
  	  oMstr.GetItem( oMedr.GetMasterID( pc_clcode))  	      
  	  ll_used = .F.
   ENDIF
   WAIT WINDOW "Re-opening case. Please wait." NOWAIT NOCLEAR 
   SELECT Master
   REPLACE DOL WITH convertField(dol,IIF(TYPE("master.dol")="C","",{}))
   *oMstr.UpdateData()  10/07/2007 MD 
   lcSQLLine="update tblmaster set dol=null where cl_code='"+ALLTRIM(pc_clcode)+"' and active=1"
   oMstr.sqlexecute(lcSQLLine)
   pd_closing = convrtDate(Master.DOL)
   * 03/09/06 DMA Update forms that display case's open/closed status
   DO UpdateCaseHeader WITH oMstr.CaseNumber
   IF ll_used = .F.
	  SELECT Master
	  USE
   ENDIF  
   lcSQLLine="exec dbo.reOpenCase '"+ALLTRIM(pc_clcode)+"'"
   oMstr.sqlexecute(lcSQLLine)
   = MemoTxn( "H", .T.)
   SELECT( n_curarea)
   * Check and report on inactive/missing plans   
   = gfChkPln()	
   SELECT( n_curarea)
ENDIF
WAIT CLEAR 
RETURN
