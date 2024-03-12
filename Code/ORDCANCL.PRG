PROCEDURE OrdCancl
***************************************************************
** 05/05/12 EF  -  Replaced sql with stored procs/functions to speed it up
** 11/01/05 kdl - Initial SQL conversion
** 03/09/05 EF  -  fixed a bug in the line 87-88
** 01/20/05 DMA -  Remove use of Worker field in Comment.dbf and FLComm.dbf
** 12/29/04 EF  -  Add the fourth parameter to the printcan.prg
** 12/01/04 EF  -  Add a call to the gfDepInf to print/fax Cancellation Letters
** 03/11/04 EF  -  Add a check for ordered tags for "F"/"S" attys
** 12/17/03 EF  -  Use Date_Cancl instead of decline
** 07/15/03 DMA -  Receive old TABills status as parameter
** 03/20/03 EF  -  When a tag is cancelled, re-set Pickup flag to .F.
** 01/14/03 EF  -  Fix a bug in cancellation of Not-Issued tags
** 12/12/02 EF  -  Do not add txn 77 for already received or cancelled tags
** 11/19/02 EF  -  Set req. atty to 'F' and remove from Tamaster file
** 11/13/02 EF  -  Original release
** Procedure cancels tag(s) for all outstanding orders if ;
** "C All Orders Cancelled" option was used ;
** on 3 (Buyers and Orders) F6 screen
** Called by: tabills
** Calls: attcharg, gfuse, printcan, gfAddtxn, gfAddCom, gfDepinv
****************************************************************
PARAMETERS lcClCode, lcAtty, llNoOrders, c_OldResp
** lcClCode   -- client code of case being processed
** lcAtty     -- Attorney code of attorney who wants orders cancelled
** llNoOrders -- True if there are no other attorneys ordering records
**               in this case.
** c_OldResp  -- Original TABills.Response setting before cancellation
LOCAL ldOrdDate, ldDeclDate, llCharge, llTagCanl, llAttCanl, ln_Tag, ;
	ln_Rec, llOrd, lcAlias, c_currstat, ldCancDate, ;
	c_clatkey, c_cltgkey, c_Alias, lc_message,c_sql, omed,c_today
LOCAL LTXN19 AS Boolean, l_allowcanl AS Boolean

c_today=DTOC(d_today)
STORE .F. TO llCharge
STORE "" TO lcOrder, lcExact, c_currstat, c_Alias, lcAlias
c_Alias = ALIAS()
** Add txn 77 for cancelled tags
llCharge = gfmessage("Do you want to post a cancellation charge?",.T.)
c_clatkey = lcClCode + lcAtty
omed = CREATEOBJECT("medgeneric")
omed.closealias('ordertag')
c_sql = "exec [dbo].[Chkordertagbeforecanceling] '" + fixquote(lcClCode) + "','" + ALLTRIM(fixquote(lcAtty)) + "',1"

*!*	c_sql = "SELECT * FROM tblorder WITH (NOLOCK, INDEX (ix_tblorder_1)) WHERE "+;
*!*	"cl_code='&lcClCode.' and at_code<>'"+ALLTRIM(fixquote(lcAtty))+"' AND active=1 and deleted IS null"
omed.sqlexecute(c_sql,'ordertag')
SELECT ordertag
INDEX ON cl_code+STR(TAG) TAG cltag
SET ORDER TO cltag
**05/05/12 EF  -  Replaced sql with stored proc
*!*	c_sql = "SELECT * FROM tblorder WITH (NOLOCK, INDEX (ix_tblorder_1)) WHERE "+;
*!*	"cl_code='&lcClCode.' AND at_code='"+ALLTRIM(fixquote(lcAtty))+"' AND active=1 and deleted IS null"
c_sql = "exec [dbo].[Chkordertagbeforecanceling] '" + fixquote(lcClCode) + "','" + ALLTRIM(fixquote(lcAtty)) + "',2"
omed.sqlexecute(c_sql,'order')
SELECT ORDER
plZDontAskPrintQuestion = .F.
plZPrintWasSelected = .F.
SCAN WHILE ORDER.cl_code + ORDER.at_code = c_clatkey
	llAttCanl = .F.
	llTagCanl = .T.
	ln_Tag = ORDER.TAG
	ldOrdDate = NVL(ORDER.Date_Order,{})
	ldDeclDate = NVL(ORDER.Date_Decln,{})
	ldCanlDate = NVL(ORDER.Date_Cancl,{})
	ln_Rec = RECNO()
	c_cltgkey = lcClCode + STR( ORDER.TAG)
	llTagNoOrders=llNoOrders
*--check orders as it may be "F" attorneys with ordered tags
	IF llNoOrders
	SELECT ordertag
		COUNT TO ln_AnyOrd FOR NOT EMPTY( NVL(Date_Order,{})) AND EMPTY( NVL(Date_Decln,{})) ;
			AND EMPTY( NVL(Date_Cancl,{})) AND cl_code = lcClCode ;
			AND TAG = ln_Tag AND at_code <> lcAtty
		llTagNoOrders = IIF( ln_AnyOrd <> 0, .F., llNoOrders)
	ENDIF
	SELECT order
	GOTO ln_Rec
	omed.closealias('record')
**05/05/12 EF  -  Replaced sql with stored procs
*!*		c_sql = "SELECT * FROM tblrequest WITH (INDEX (ix_tblrequests_2)) WHERE cl_code='"+order.cl_code+"' " + ;
*!*			"AND tag="+STR(order.tag)+" AND active=1 and deleted IS null"
	c_sql = "exec dbo.GetRequestRecordbyClcodeTag '" + fixquote(ORDER.cl_code) + "','" + STR(ORDER.TAG) + "'"

	omed.sqlexecute(c_sql,'record')

	SELECT RECORD
	IF NOT INLIST( RECORD.STATUS, "R", "N", "C") AND EMPTY(NVL(RECORD.hStatus,''))
		IF EMPTY( ldDeclDate) AND EMPTY( ldCanlDate)
			SELECT ORDER
			IF INLIST( c_OldResp, "T", "S") OR ;
					( c_OldResp = "F" AND ( EMPTY( ldOrdDate)) OR NOT EMPTY( ldOrdDate))
				c_sql= ""
				c_sql= "exec [dbo].[CancelOrder] '" + ORDER.id_tblorders + "','" + ALLTRIM(pc_UserID) + "'"
**05/05/12 EF  -  Replaced sql with stored procs
*!*					c_sql= "UPDATE tblOrder SET date_cancl='&c_today.',response='F' WHERE id_tblorders='"+order.id_tblorders+"'"
				omed.sqlexecute(c_sql)
				llAttCanl = .T.
			ENDIF
			SELECT RECORD
		ENDIF

		STORE .F. TO LTXN19,  l_allowcanl

		*IF llCharge AND llAttCanl 
		&& 05/14/2015 changed pe Alec's request.  Generate both txns - 77 with 0 amount if the answer is NO and 21 with the regualar amount regardless
		IF llAttCanl
* Apply cancellation charges (if user approved)
* only to tags in "Waiting" status.
			lcAlias = SELECT()

**11/6/14 ALLOW CANCEL FOR TXN 19'S TAGS
			LTXN19=ChkTxn19(RECORD.cl_code ,RECORD.TAG)

			DO CASE

			CASE RECORD.STATUS = "W" AND EMPTY(NVL(RECORD.hStatus,''))
				l_allowcanl=.T.
			CASE LTXN19
				l_allowcanl=.T.

			OTHERWISE
				l_allowcanl=.F.
			ENDCASE

***
			IF  l_allowcanl
*IF Record.Status = "W" AND EMPTY(NVL(record.hStatus,''))
				DO AttCharg WITH lcClCode, lcAtty, 1, ln_Tag,"", llCharge
			ENDIF
			SELECT (lcAlias)
		ENDIF

** check if this was the final attorney with outstanding orders for this tag
		SELECT ordertag
		c_cltgkey = lcClCode + STR( ORDER.TAG)
		SEEK c_cltgkey

		SCAN WHILE ordertag.cl_code + STR( ordertag.TAG) = c_cltgkey AND !EOF()
			IF NOT EMPTY( NVL(ordertag.Date_Order,{})) OR ;
					INLIST( c_OldResp, "T", "S")
				DO CASE
				CASE EMPTY( NVL(ordertag.Date_Decln,{})) AND EMPTY( NVL(ordertag.Date_Cancl,{}))
					llTagCanl = .F.
				ENDCASE
			ENDIF
		ENDSCAN
		llTagCanl = IIF( llTagNoOrders, .T., llTagCanl)

		IF llTagCanl                              && no more ordering attys
			SELECT RECORD
* Print a cancellation letter if request was in "Wait" status
*IF Record.Status = "W" AND EMPTY(NVL(record.hStatus,''))
			IF l_allowcanl
**add transaction 21
				WAIT WINDOW "Adding cancellation (21) transaction for tag " + ;
					ALLTRIM( STR( ln_Tag)) + "." + CHR(13) + "Please wait." NOWAIT NOCLEAR

				lnTxnId = GetTxnId()

				ntxn_id=GetTxnId()
				o=CREATE("medtimesheet")
				o.getitem(.NULL.)

				REPLACE cl_code WITH lcClCode, ;
					TAG WITH ln_Tag, ;
					txn_date WITH DTOC(d_today), ;
					txn_code WITH 21, ;
					rq_at_code WITH lcAtty, ;
					DESCRIPT WITH RECORD.DESCRIPT,;
					txn_id WITH ntxn_id, ;
					CreatedBy WITH pc_UserID, ;
					ACTIVE WITH .T.,;
					wit_fee WITH 0.00,;
					units WITH 0.0, ;
					plbilled WITH .F., ;
					billed WITH .F., ;
					locked WITH .F., ;
					suspended WITH .F., ;
					rec_rcv WITH .F., ;
					rcv WITH .F., ;
					rq_at_code WITH '', ;
					rec_uob WITH .F., ;
					rec_nrs WITH .F., ;
					rec_out WITH .F., ;
					rec_cancel WITH .F., ;
					rec_inc WITH .F., ;
					rec_rush WITH .F., ;
					chk_no WITH 0, ;
					txn_cmnt WITH .F., ;
					tkl_sent WITH .F., ;
					tkl_cnt WITH 0, ;
					voucher WITH 0, ;
					rca_no WITH '', ;
					purch_amt WITH 0.00, ;
					tsbilled WITH .F., ;
					newdivisor WITH 0, ;
					olddivisor WITH 0, ;
					rec_code WITH '', ;
					soc WITH '', ;
					invisible WITH .F., ;
					STATUS WITH '', ;
					worker WITH '', ;
					litigation WITH '', ;
					miles WITH 0, ;
					TYPE WITH '', ;
					asb_round WITH '', ;
					editedby WITH '', ;
					deletedby WITH '', ;
					retiredby WITH '', ;
					id_tblrequests WITH RECORD.id_tblrequests

				o.updatedata
				u_idtimesheet=medtimesheetupdateresults.id_tbltimesheet


				o=CREATE("medcomment")
				o.getitem(.NULL.)


				REPLACE txn_date WITH d_today, ;
					DESCRIPT WITH RECORD.DESCRIPT,;
					cl_code WITH lcClCode, ;
					txn_code WITH 21, ;
					TAG WITH ln_Tag, ;
					Mailid_no WITH RECORD.Mailid_no, ;
					txn_id WITH ntxn_id, ;
					COUNT WITH 0, ;
					COMMENT WITH "All orders were cancelled by " + ;
					ALLT( pc_UserID) + " on " + c_today + ".", ;
					txn_num WITH '', ;
					units WITH 0, ;
					wit_fee WITH 0, ;
					billed WITH .F., ;
					plbilled WITH .F.,;
					worker WITH '', ;
					editedby WITH '', ;
					retiredby WITH '', ;
					Created WITH d_today, ;
					CreatedBy WITH pc_UserID, ;
					id_tbltimesheet WITH u_idtimesheet, ;
					ACTIVE WITH .T., ;
					retire WITH .F.

				o.updatedata

*-----------------------------------------------------------
* 01/27/2010 MD add txn 80
				lcSQLLine="exec dbo.addTxn80ToCancelTag '"+ALLTRIM(DTOC(d_today))+"', '"+ALLTRIM(fixquote(RECORD.DESCRIPT))+"', "+;
					"'"+ALLTRIM(lcClCode)+"', 80,"+ALLTRIM(STR(ln_Tag))+",'"+ALLTRIM(RECORD.Mailid_no)+"', '"+ALLTRIM(fixquote(pc_UserID))+"',"+;
					"'Added txn 80 for Canceled Tag', 'CANCELED TAG'"
				omed.sqlexecute(lcSQLLine)

*-----------------------------------------------------------


				WAIT CLEAR
				pl_GotDepo = .F.
				DO gfgetdep WITH lcClCode, ln_Tag
				DO PrintCan WITH lcClCode, ln_Tag, .T., .T.


			ENDIF
			IF lcAtty = MASTER.rq_at_code
				REPLACE MASTER.rq_at_code WITH SPAC(8) IN MASTER
				omast=CREATEOBJECT('medmaster')
				omast.updatedata
				RELEASE omast
			ENDIF

			SELECT RECORD
			LOCAL l_Statusupd AS Boolean
*IF (Record.Status = "W"  AND EMPTY(NVL(record.hStatus,''))) OR ;
(Record.Status = "T" AND llTagNoOrders)

			DO CASE

			CASE  (RECORD.STATUS = "W"  AND EMPTY(NVL(RECORD.hStatus,'')))
				l_Statusupd=.T.
			CASE LTXN19 AND llTagNoOrders &&llTagCanl
				l_Statusupd=.T.
			CASE 	(RECORD.STATUS = "T" AND llTagNoOrders)
				l_Statusupd=.T.
			OTHERWISE
				l_Statusupd=.F.
			ENDCASE


			IF l_Statusupd
				c_sql=""
				c_sql="exec	[dbo].[CancelTAG] '" + RECORD.id_tblrequests+"','" + ALLTRIM(fixquote(pc_UserID))+"'"
				omed.sqlexecute(c_sql)
			ENDIF

		ENDIF
	ENDIF
	SELECT ORDER
ENDSCAN
SELECT ordertag
USE

RELEASE omed

IF NOT EMPTY(c_Alias)
	SELECT ( c_Alias)
ENDIF
RETURN
