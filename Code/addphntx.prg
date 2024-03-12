PROCEDURE AddPhnTx
**EF    12/21/05 - switched to sql
*****************************************************************************
** DMA  01/20/05 Remove use of TAMaster.Worker field in Comment.dbf
** EF   10/24/02 Modified to be used for fax original requests
** DMA  06/19/02 Replace mlogname with pc_UserID; remove ID from gfAddTxn call
** kdl  04/04/02 Added check to fill in value of pc_mailid if there is none
** EF   12/20/01 -
**  Adds txn_code 2 or 8 when an user choose to fax a second request.
**
** Called by: subp_pa.prg.
** Calls: gfaddtxn.prg, gfaddcom.prg, gfcall.prg, gfcallst.prg,
*         gfMailPh, gfCallSt
*****************************************************************************
PARAMETERS nRequest, n_Tag
*--4/4/02 kdl start: make sure there is a value for pcMailID
PRIVATE lc_AreaC AS String
IF TYPE("pc_MailID")="U" OR ALLT( pc_MailID) == ""
	pc_MailID=ALLT( RECORD.Mailid_no)
ENDIF
oMed = CREATE("generic.medgeneric")

*--4/4/02 kdl end:

*nRequest=1 - fax original issues
*nRequest=2 - fax second requests
*nRequest=3 - fax/print original issues
IF nRequest=2
	IF NOT EMPTY( pc_offcode)
		lc_AreaC = gfmailPh( pc_MailID, "A")		  
		lcAreaC=IIF(ISNULL(lc_AreaC),"",lc_AreaC)		
		
		IF LEN( ALLTRIM( lcAreaC)) = 3 
			lnCalltype = gfCall( lcAreaC, pc_offcode, pc_area, pc_litcode)
		ELSE	
			lcState = gfmailPh( pc_MailID, "S")
			IF LEN( ALLTRIM( lcState)) = 2
				lnCalltype = gfCallSt( lcState, pc_offcode)
			ENDIF
		ENDIF
	ENDIF
	lc_text = "Faxed a second request on "

	lnTxnC = IIF( lnCalltype = 1, 8, 2)             && 8 -> LD; 2 -> local

ELSE

	lc_text = IIF( nRequest = 3, ;
		"Faxed/Printed an original request on ", ;
		"Faxed an original request on ")
	lnTxnC = 66
ENDIF 
**3/7/08 -added a memo to the fax 2 req requests/phone txn
IF nRequest=2
	c_memo =ALLTRIM(pc_FaxMemo) 
else
	c_memo = lc_text + DTOC(DATE()) + ".  (" + ALLTRIM(pc_UserID) + ")"

endif

ln_units = getdef( "PHONECALL", "N")
n_defunit = IIF( ln_units > 0, ln_units / 60, 0 )
&&5/6/2010- SOME BATCH ISSUE DO NOT HAVE REQUEST OPEN 
IF USED('REQUEST')
	c_descript = REQUEST.DESCRIPT
ELSE
	s_clcode=pc_clcode
	DO getRequestbyRTtag IN cadissue WITH  s_clcode, n_Tag
	c_descript=REQUEST.DESCRIPT
ENDIF
&&5/6/2010- SOME BATCH ISSUE DO NOT HAVE REQUEST OPEN 
IF pc_deptype == "D"
	c_drname=gfdrformat(c_descript)
	c_descript = IIF(NOT "DR."$c_drname,"DR. "+ALLTRIM(c_drname),c_drname)
ELSE
	c_descript = ALLTRIM(c_descript)
ENDIF

l_investig = REQUEST.investig
c_type=REQUEST.TYPE
c_ReqId=REQUEST.id_tblRequests

lnTxnId = 0
ln_outtxn = 0
ln_count = 0
LOCAL C_STR AS STRING, l_done AS Boolean, l_EntryID AS Boolean
C_STR=""
c_Desc=oMed.cleanstring(c_descript)
ccl_code=oMed.cleanstring(pc_clcode)
C_STR= "Exec dbo.gfAddTxn '" + DTOC(DATE())+  " ', '" ;
	+ LEFT(FIXQUOTE(c_descript) ,50) + "' ," + ccl_code + ",' " ;
	+ ALLTRIM(STR(lnTxnC)) + "','"  + ALLTRIM(STR(n_Tag)) + "','" ;
	+ pc_MailID + "','" + STR(n_defunit) + "','" ;
	+ ALLTRIM(STR(ln_count)) + "','" +  "" + "','" ;
	+ ALLTRIM(STR(0)) + "', '"  + "" + "','" ;
	+ c_type + "','" ;
	+ ALLTRIM(pc_UserID) + "','" ;
	+ c_ReqId +"'"


l_done=oMed.sqlexecute(C_STR,"")
IF l_done
	IF USED('EntryID')
		SELECT EntryID
		USE
	ENDIF	
	l_EntryID= oMed.sqlexecute("select dbo.fn_GetID_tblTimesheet (" + ccl_code + ",'" ;
		+ STR(n_Tag) +"','" + STR(lnTxnC)+ "','" +DTOC(DATE()) +"')", "EntryId")
	IF l_EntryID
	   IF USED("EntryID") AND RECCOUNT("EntryID")>0
		  nTxn=IIF( INLIST( nRequest, 2, 3), 44, lnTxnC)
		  l_Comm=oMed.sqlexecute("Exec dbo.gfAddCom '" + DTOC(DATE())+  " ', '" ;
			+ LEFT(FIXQUOTE(c_descript) ,50) + "'," + ccl_code + ",' " ;
			+ ALLTRIM(STR(nTxn)) + "','"  + ALLTRIM(STR(n_Tag)) + "','" ;
			+ pc_MailID + "','" + STR(ln_count) + "','" ;
			+ fixquote(ALLTRIM(c_Memo))  + "','"  ;
			+ ALLTRIM(STR(0)) + "','"  ;
			+ ALLTRIM(pc_UserID) + "','" + EntryID.EXP +"'")
      ENDIF 


		l_done=l_Comm
	ENDIF
ENDIF

IF  l_done
	l_UpdReq= oMed.sqlexecute("Exec dbo.sp_UpdRequestPhnCnt '" ;
		+ STR(n_Tag) + "','" + pc_clcode + ;
		"','" + STR(lnTxnC) + "','" + ALLTRIM(pc_UserID) + "'", "UpdReq")

	IF NOT l_UpdReq
		gfmessage("Transactions have failed. Contact IT")
	ENDIF
ENDIF
RELEASE oMed
RETURN
