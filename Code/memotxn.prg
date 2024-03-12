PROCEDURE MemoTxn

** Enter a memo transaction for a tag or case.
** Called by DepStat, DepOpts, AddRec, DelReq, gfReopen
** Uses screens frmMemoType, frmMemo
** Assumes gfGetCas has been called, but not gfGetDep
**
** 03/22/2010 EF  QC work: C- client rep queue and V review tag memo
** 03/17/2006 MD  Modified to evaluate NULLs
** 11/04/05   MD   Modified for VFP
** 01/20/05  DMA  Remove use of TAMaster.Worker field in Comment.dbf
** 03/10/03  DMA  Skip auto-reopen for Berry & Berry cases (same as gfReopen)
** 11/17/03  DMA  Add automatic reopening when a memo is added to a
**                closed case.
** 11/11/03  kdl  Added selection of original work area before return
** 11/10/03  DMA  Add "H" -- history -- memo to track automated reopening
**                of a case.
** 07/17/03  IZ   Added Required Memo feature for tag deletion - parameter "S"
**                or Deleted Transactions 1,41 - parameter "R"
**                Added new screen REQMEMO
** 06/04/02  DMA  Update Global Record file; fill in Entry.CreatedBy
** 04/02/02  DMA  Fill in Comment.CreatedBy field with login ID of user
** 11/14/01  DMA  Update pl_AMResp global variable
** 08/10/01  DMA  Add memo type-selection screen
** 06/21/01  DMA  Do not get Txn ID until user has accepted data
** 06/13/01  DMA  Add NRS-F "closing memo" capability to screen and code
** 05/30/01  DMA  Updated to use SQL INSERT
**
LPARAMETERS typememo, AUTO
** typememo = "T" for optional tag-level memo
**            "C" for optional case-level memo
**            "R" for required tag-level memo
**            "S" for required case-level memo
**            "H" (history) for automatic reopening of case
**            "V"  QC AIP -review tag's memo
**			  "X"  Specialty Follow Up txn 33
**			  "O" QC client rep
**			  "A" Txn19 -Client Memo
** Auto = .T. when automatically entering new tags (call from addrec)

IF PCOUNT() < 2
	AUTO = .F.
ENDIF

LOCAL n_memotype, ll_return, n_CurArea,  lc_caption, lc_comment,  ntag 
IF TYPE('pn_tag')="C"
pn_tag=VAL(pn_tag)
ENDIF

n_CurArea = SELECT()

ll_return = .T.
n_memotype = 1
m.okcan = 1

LOCAL ots AS medtimesheet OF timesheet
ots = CREATEOBJECT("medtimesheet")

LOCAL oCmts AS medcomment OF COMMENT
oCmts = CREATEOBJECT("medcomment")

LOCAL oMstr as medMaster OF Master 
oMstr=CREATEOBJECT("medMaster")

LOCAL oMedr as medrequest OF request
oMedr=CREATEOBJECT("medrequest")

LOCAL oTrans as medrequest OF Transactions
oTrans=CREATEOBJECT("medrequest")

*  For manually-entered memorandum, initialize variables and
*  present user with the data entry screen.
IF NOT AUTO	
	IF typememo = "T"
		* create the form object
		omemotype = CREATEOBJECT("TRANSACTIONS.frmmemotype")
		* show the form in modal
		omemotype.SHOW			 			
		* when the form returns to code, grab the values
		n_memotype  = omemotype.cboMemoType.LISTINDEX		
		RELEASE omemotype					
	ENDIF
*	IF n_memotype < 5								&& 3/2/2020 ZD #163394, JH
	IF n_memotype < 6								&& 3/2 
		*!*		get the comment mediator to fire up a new record			
	    ots.getitem(NULL)		
		SELECT timesheet
		SCATTER MEMVAR BLANK
		m.txn_date = DATETIME()
		*m.comments = IIF( n_memotype = 2, "CLOSING MEMO: ", "")		&& 10/02/2018 MD #109789

		DO CASE 
		CASE n_memotype = 2
		      m.comments = "CLOSING MEMO: "	
		CASE n_memotype = 3
			  m.comments = "Date RT received the signed subpoena: "
	    	CASE n_memotype = 4
			  m.comments = "Date the subpoena was served on provider OR date authorization was delivered to provider: "	
	    	CASE n_memotype = 5
			  m.comments = "Ordered By: "	
		OTHERWISE
	          m.comments=""
        	ENDCASE 

		m.CreatedBy = goApp.CurrentUser.NtLogin		
		m.created=DATETIME()
		m.active = .T.	
		lc_caption=""	 		
		DO CASE
		**03/02/2016- #33668 add memo when removing hold a
		
		CASE typememo = "L"
				m.txn_code = 4
				m.descript = pc_Descrpt
				m.cl_code = pc_clcode
				m.mailid_no = pc_MailID
				m.tag = pn_tag 
				lc_caption="Deponent-Level Memorandum Entry"
				lc_comment= "Enter text" 
				m.comments = "Hold A Removed by: " + ALLTRIM(goApp.CurrentUser.NtLogin) ;
					+CHR(13)+ m.comments
		
		
		
		**EF (QC cases): C- client rep queue and V review tag memo
		CASE typememo = "O"
				m.txn_code = 4
				m.descript = pc_Descrpt
				m.cl_code = pc_clcode
				m.mailid_no = pc_MailID
				m.tag = pn_tag 
				lc_caption="Deponent-Level Memorandum Entry"
				lc_comment=IIF(n_memotype=2, "QC Process. A tag was sent to a Client Rep QC queue", "Enter text")	
				m.comments =  " Entered by " + goApp.CurrentUser.NtLogin;
					+ " on " + DTOC(DATE()) + "."	+CHR(13)+ m.comments
		
		CASE typememo = "A" &&06/22/12 - txn19 memo
				m.txn_code = 4
				m.descript = pc_Descrpt
				m.cl_code = pc_clcode
				m.mailid_no = pc_MailID
				m.tag = pn_tag 
				lc_caption="Required memo (txn19): Deponent-Level Memorandum Entry"
				lc_comment= "Enter text"
				m.comments =  ""+CHR(13)+ m.comments	
		
		
		CASE typememo = "V"
				m.txn_code = 4
				m.descript = pc_Descrpt
				m.cl_code = pc_clcode
				m.mailid_no = pc_MailID
				m.tag = pn_tag 
				lc_caption="Deponent-Level Memorandum Entry"
				lc_comment=IIF(n_memotype=2, "QC Process. Review Tag Memo", "Enter text")	
				m.comments =  " QC Review tag/ entered by " + goApp.CurrentUser.NtLogin;
					+ " on " + DTOC(DATE()) + "."	+CHR(13)+ m.comments
		CASE typememo = "T"
				m.txn_code = 4
				m.descript = pc_Descrpt
				m.cl_code = pc_clcode
				m.mailid_no = pc_MailID
				m.tag = pn_tag 	
															
*!*					10/02/2018 MD #109789
*!*					DO CASE 
*!*					   CASE n_memotype=1
*!*					        lc_comment="Enter text of memorandum"
*!*					   CASE n_memotype=2
*!*					        lc_comment="Enter text of closing memo for the tag"				   
*!*					ENDCASE 
	
				DO CASE 
				CASE n_memotype = 1
		      			lc_caption="Deponent-Level Memorandum Entry"	
		      			lc_comment="Enter text of memorandum"
				CASE n_memotype = 2
		      			lc_caption="Deponent-Level Memorandum Entry"
		      			lc_comment="Enter text of closing memo for the tag"		
				CASE n_memotype = 3
					lc_caption="Received Subpoena Date Entry"
			  		lc_comment="Enter Date RT received the signed subpoena"
	    			CASE n_memotype = 4
	    				lc_caption="Served Subpoena/Delivered Autho Date Entry"
			  		lc_comment="Enter Date the subpoena was served on provider OR date authorization was delivered to provider: "		    			         
				CASE n_memotype = 5
		      			lc_caption="Deponent-Level Memorandum Entry"	
		      			lc_comment="Enter Ordered By information"
        		ENDCASE 									
			CASE typememo = "C"
				m.descript = SPACE(50)
				m.txn_code = 12
				m.cl_code = pc_clcode
				m.tag = 0
				lc_caption="Case-Level Memorandum Entry"
				lc_comment=IIF(n_memotype=2, "Enter text of closing memo", "Enter text of memorandum")				
			CASE typememo = "R"
				lc_header = "Required memo for a deleted transaction"
				m.txn_code = 4
				m.descript = pc_Descrpt
				m.cl_code = pc_clcode
				m.mailid_no = pc_MailID
				m.tag = pn_tag				
				lc_caption="Required memo for the deleted transaction"
				lc_comment="Enter text of a memo for the deleted transaction"
				m.comments = m.comments + CHR(13) + "Transaction deleted by " + ;
					goApp.currentUser.NtLogin + " on " + DTOC(DATE()) + "."
			CASE typememo = "S"
				lc_header = "Required memo for a deleted tag"
				m.descript = pc_Descrpt
				m.cl_code = pc_clcode
				m.mailid_no = pc_MailID
				m.txn_code = 12
				*m.tag = IIF(pl_QCProc,pn_tag,0)	
				m.tag =0
				lc_caption="Required memo for the deleted tag"
				lc_comment="Enter text of a memo for the deleted tag"
				m.comments = m.comments + CHR(13) + "Tag " + ;
					ALLTRIM(STR(pn_tag)) + " deleted by " + goApp.CurrentUser.NtLogin;
					+ " on " + DTOC(DATE()) + "."
			CASE typememo = "J"
				lc_header = "Required memo for reseting a processed job item"
				m.txn_code = 4
				m.descript = pc_Descrpt
				m.cl_code = pc_clcode
				m.mailid_no = pc_MailID
				m.tag = pn_tag				
				lc_caption="Required memo for the reset job item"
				lc_comment="Enter text of a memo for reset job item"
				m.comments = m.comments + CHR(13) + "tag's processed job item reset by " + ;
					goApp.currentUser.NtLogin + " on " + DTOC(DATE()) + "."
		   CASE typememo = "X"
				m.txn_code = 33
				m.descript = pc_Descrpt
				m.cl_code = pc_clcode
				m.mailid_no = pc_MailID
				m.tag = pn_tag 
				lc_caption="Deponent-Level Specialty Follow Up Entry"				
				lc_comment="Enter text of Specialty Follow Up"	
		   CASE typememo = "F"
				lc_header = "Required memo for Closed STC with No FollowUp Request"
				m.txn_code = 4
				m.descript = pc_Descrpt
				m.cl_code = pc_clcode
				m.mailid_no = pc_MailID
				m.tag = pn_tag				
				lc_caption="Required memo for Closed STC with No FollowUp Request"
				lc_comment="Enter text of a memo for Closed STC with No FollowUp Request"
				m.comments = m.comments + CHR(13) + "No FollowUp Request sent by " + ;
					goApp.currentUser.NtLogin + " on " + DTOC(DATE()) + "."			  
					
			CASE typememo = "P"
				lc_header = "Required memo for a Removed Paralegal Time"
				m.txn_code = 4
				m.descript = pc_Descrpt
				m.cl_code = pc_clcode
				m.mailid_no = pc_MailID
				m.tag = pn_tag				
				lc_caption="Required memo for the removed Paralegal Time [QC]"
				lc_comment="Enter text of a memo for the removed Paralegal Time"
				m.comments = m.comments + CHR(13) + " Paralegal Time removed by " + ;
					goApp.currentUser.NtLogin + " on " + DTOC(DATE()) + "."									
		ENDCASE
		IF !EMPTY(ALLTRIM(lc_caption))		
		   omemform=CREATEOBJECT("Transactions.frmMemo",lc_caption, lc_comment, typememo, m.descript, m.tag, pn_lrsno, pc_plnAM, pc_clcode,m.comments)
		   omemform.show				
		   RELEASE omemoform		
		ENDIF 		
	ELSE
		m.okcan = 2
	ENDIF
ELSE
	* 11/07/03 DMA Handler for memo when case is automatically reopened
	*              Uses c_msgtxt, defined in calling module gfReopen
	IF typememo = "H"	    
		ots.getitem(NULL)
		SELECT timesheet

		SCATTER MEMVAR BLANK
		m.descript = SPACE(50)
		m.txn_code = 12
		m.cl_code = pc_clcode
		m.tag = 0		
		m.comments = "Case was automatically re-opened when " + c_msgtxt
		m.txn_date =DATETIME()
		m.CreatedBy = goApp.CurrentUser.NtLogin
		m.created=DATETIME()
		m.active = .T.		
	ENDIF
ENDIF
IF m.okcan <> 1
	ll_return = .F.		
	WAIT CLEAR 
	SELECT (n_CurArea)	
	RETURN ll_return
ENDIF



IF TYPE ("m.tag")="C"
	ntag=VAL(m.tag)
ELSE
	ntag=M.TAG
ENDIF

IF ntag=0
   m.id_tblRequests=""
ELSE 
   m.id_tblRequests=oMedr.getrequestid(pc_clcode, ntag)
ENDIF    

WAIT WINDOW "Creating Transaction.  Please wait." NOWAIT NOCLEAR 

SELECT timesheet
GATHER MEMO MEMVAR
ots.updatedata
lc_idtimesheet=medtimesheetupdateresults.id_tbltimesheet

IF NOT EMPTY( m.comments)     
    oCmts.getitem(NULL)				
	WAIT WINDOW "Creating Transaction.  Please wait." NOWAIT NOCLEAR 
	SELECT COMMENT
	REPLACE DESCRIPT WITH m.descript, txn_date WITH m.txn_date, ;
	txn_code WITH timesheet.txn_code, TAG WITH timesheet.TAG, ;
	cl_code WITH pc_clcode, mailid_no WITH IIF( typememo = "T", pc_mailid, ""), ;
	txn_id WITH timesheet.txn_id, COMMENT WITH m.comments, ;
	CreatedBy WITH goApp.CurrentUser.NtLogin, ;
	id_tblTimeSheet WITH lc_idtimesheet,;
	created WITH DATETIME(), active WITH .T., retire WITH .F.
	oCmts.updatedata		
ENDIF
*
*  11/10/03 DMA
*  Restore tag-level memvar values if we just did a case-level history memo
*  as a result of tag-level changes to the case.
*
IF NVL(pl_GotDepo,.F.) AND typememo = "H"
	SELECT timesheet
	m.descript = pc_Descrpt
	m.tag = pn_tag
	m.active = .T.
ENDIF
* 03/10/03 DMA Skip reopening for Berry & Berry cases (same as gfReopen)
* 11/17/03 DMA Add Tag 0 memo if this memorandum forced reopening of the case
*     This is handled here in full to avoid recursive calls via gfreopen
IF NOT EMPTY(convrtDate(pd_closing)) AND typememo <> "H" AND NOT NVL(pl_BBCase,.F.)
	ots.getitem(NULL)		
	SELECT timesheet
	SCATTER MEMVAR BLANK
	m.descript = SPACE(50)
	m.txn_code = 12
	m.cl_code = pc_clcode
	m.tag = 0	
	m.txn_date = DATETIME()
	m.CreatedBy = goApp.CurrentUser.NtLogin
	m.created=DATETIME()
	m.active = .T.
	IF m.tag=0
       m.id_tblRequests=""
    ELSE 
       m.id_tblRequests=oMedr.getrequestid(c_clcode, m.tag)
    ENDIF    
    WAIT WINDOW "Creating Transaction.  Please wait." NOWAIT NOCLEAR 	
    GATHER MEMO MEMVAR    	
	ots.updatedata	
	lc_idtimesheet=medtimesheetupdateresults.id_tbltimesheet
		
	oCmts.getitem(NULL)	 	
	SELECT COMMENT
	** 01/20/05 DMA Remove use of TAMaster.Worker field in Comment.dbf
	WAIT WINDOW "Creating Transaction.  Please wait." NOWAIT NOCLEAR 
	REPLACE DESCRIPT WITH SPAC(50), txn_date WITH DATEtime(), txn_code WITH 12, ;
	TAG WITH 0, cl_code WITH pc_clcode, mailid_no WITH "", ;
	CreatedBy WITH goApp.CurrentUser.NtLogin, ;		
	COMMENT WITH "Case was automatically re-opened when a memo was added.", ;
	id_tblTimeSheet WITH lc_idtimesheet, ;
	created WITH DATETIME(), active WITH .T.,  retire WITH .F.		
	oCmts.updatedata				   
	
	sqlLine="update tblMaster set DOL = NULL where id_tblmaster='"+oMedr.getmasterid(pc_clcode)+"'"	
*!*	 	oMstr.getitem(oMedr.getmasterid(pc_clcode))  	        	
  	WAIT WINDOW "Updating Master table.  Please wait." NOWAIT NOCLEAR 
  	oMstr.sqlexecute(sqlLine)
*!*	  	SELECT master
*!*	    replace DOL WITH .NULL.
*!*		oMstr.updatedata()	
	pd_closing = {}
	
	SELECT timesheet
	m.descript = pc_Descrpt
	m.tag = pn_tag
	m.active = .T.
ENDIF

*
*   For NRS-F closing memo only, turn on the Client Rep. Responsibility Flag
*   in the Record file. Note the date and user on the flag change.
*
IF n_memotype = 2
   IF m.tag>0       	     
  	  oMedr.getitem(oMedr.getrequestid(pc_clcode, m.tag))        	  
  	  WAIT WINDOW "Updating Request table.  Please wait." NOWAIT NOCLEAR 
  	  SELECT request
  	  replace descript WITH pc_Descrpt, AM_Resp WITH .T., ID_AM_Resp WITH ;
  	  ALLTRIM(goApp.CurrentUser.NtLogin), DT_AM_Resp WITH DATETIME()
  	  oMedr.updatedata()  	     	
      	  pl_AMResp = .T.
	ENDIF
ENDIF

* 10/02/2018 MD #109789
IF n_memotype = 4
   sqlLine="exec dbo.addABLDueDate '"+ALLTRIM(pc_clcode)+"', "+ALLTRIM(STR(m.tag))+", '"+ALLTRIM(DTOC(m.txn_date))+"', '"+fixquote(ALLTRIM(m.descript))+"','"+;
   fixquote(ALLTRIM(pc_mailid))+"','"+ALLTRIM(goApp.CurrentUser.NtLogin)+"','"+fixquote(ALLTRIM('Subpoena due date.'))+"'"
   oMstr.sqlexecute(sqlLine)
ENDIF 
WAIT CLEAR 
SELECT (n_CurArea)
RETURN ll_return

**************************************************************

