PROCEDURE AttCharg
* Called by Orders, CaseFlt2, TABills, OrdCancl;
   * Subroutine Descproc called via Attcharg.spr
* Calls gfOnHold, GetTxnID, gfCanFee, AttCharg.spr
* ---------------------------------------------------------------------------
*** attcharge.prg - Charge to attorney transaction
*** Transaction 77 containing at_code and units.
* 01/20/05 DMA Remove use of TAMaster.Worker field in Comment.dbf
* ---------------------------------------------------------------------------

PARAMETERS mcl, matc, auto, mtag, llComment, lLCharge
** MCL = Client Code for case
** MAtc = Attorney code of attorney who cancelled order for record
** MTag = Deponent Number for record
** If auto <> 0, it adds a 77 txn for a certain type of charge as follows:
**    auto = 1 => Cancel transaction
** llComment = Comments on cancellation, if any, for Comment file
** Assumes that appropriate EntryX file is open in work area F
IF PCOUNT()<6
	llCharge=.T.
ENDIF 
LOCAL c_Descript,n_units,n_witfee,c_comment,l_Checkhold, oCancl as Object, oComm as Object

* Do not generate Txn 77 when the attorney billing is on hold
oCancl=createobj("medtimesheet")
l_Checkhold =oCancl.sqlexecute("select DBO.gfonhold ('&matc.','&mcl.')", "onhold")
IF onhold.exp
*IF gfOnhold( matc, mcl)
	RETURN
ENDIF

c_comment = ""
c_Descript=''
n_units=0.0
n_witfee=0
IF llCharge=.T.	&& 05/14/2015 added per Alec's request
	IF auto = 0
   		n_okbutt = 1
		m.cancbutt = 0
   		o2=CREATEOBJECT('frmaddwitnessfee')
		o2.SHOW
*--   DO attcharg.spr
		c_descrip=o2.txtdescption.value
		n_okbutt=o2.button_num
		c_comment=ALLTRIM(o2.txtcomments.value)
		n_witfee=VAL(o2.txtamount.value)
		n_units=VAL(o2.txtminutes.value)
		o2.release
	ELSE
   		n_okbutt = 1
   		IF auto = 1
      		c_Descript = "CANCEL"
      		n_witfee = gfcanfee( mcl, mtag, matc)
   		ENDIF
	ENDIF
ELSE
	c_Descript = "CANCEL"
	n_okbutt = 1	
ENDIF 
	
IF n_okbutt = 1
   IF n_units > 0
      n_units = n_units / 60
   ENDIF

	c_sql="SELECT * FROM tbltimesheet with (nolock) WHERE 1<>1"

	oCancl.sqlexecute(c_sql,"timesheet")	
	SELECT timesheet
	APPEND BLANK

	*ntxn_id=GetTxnID()
	ntxn_id=0
	REPLACE cl_code WITH mcl, ;
		tag WITH mtag, ;
		txn_date WITH d_today, ;
		txn_code WITH 77, ;
		Mailid_no WITH record.mailid_no,;
		rq_at_code WITH matc, ;
		descript WITH c_descript,;
		txn_id WITH nTxn_id, ;
		CreatedBy WITH pc_UserID, ;
		Active WITH .T.,;
		wit_fee WITH n_witfee,;
		units WITH n_units, ;
		plbilled WITH .F., ;
		billed WITH .F., ;
		locked WITH .F., ;
		suspended WITH .F., ;
		rec_rcv WITH .F., ;
		rcv WITH .F., ;
		rq_at_code WITH matc, ;
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
		status WITH '', ;
		worker WITH '', ;
		litigation WITH '', ;
		miles WITH 0, ;
		type WITH '', ;
		asb_round WITH '', ;
		editedby WITH '', ;
		deletedby WITH '', ;
		retiredby WITH '', ;		
		id_tblrequests WITH record.id_tblrequests			

		oCancl.updatedata
		u_idtimesheet=medtimesheetupdateresults.id_tbltimesheet
	

   IF NOT EMPTY( c_comment)
		oComm=createobject("medcomment")
		oComm.getitem(.null.)



		REPLACE Txn_date WITH d_today, ;
			Descript WITH c_descript,;
			Cl_Code WITH mcl, ;
			Txn_code WITH 77, ;
			Tag WITH mtag, ; 
			Mailid_no WITH record.mailid_no, ;
			Txn_id WITH nTxn_id, ;
			COUNT WITH 0, ;
			Comment WITH c_comment, ;
			txn_num WITH '', ;
			units WITH 0, ;
			wit_fee WITH 0, ;
			billed WITH .F., ;
			plbilled WITH .f.,;
			worker WITH '', ;
			editedby WITH '', ;
			retiredby WITH '', ;
			Created WITH d_today, ;
			CreatedBy WITH pc_UserID, ;
			id_tblTimesheet WITH u_idtimesheet, ; 
			active WITH .T., ;
			retire WITH .F.

		oComm.updatedata    
RELEASE oComm

   ENDIF

ENDIF
RELEASE oCancl
RETURN
**********************************
PROCEDURE DescProc

PRIVATE x, m.billcat
m.billcat = "BATES"
x = getpop( f_billpick, 'billcat + " (" + alltrim( BillDesc) + ")"', ;
   m.billcat, "billcat", "Select Description", 3, 13, m.billcat)
IF NOT EMPTY( x)
   m.descript = ALLTRIM( x)
ENDIF
SHOW GETS
_curobj = MAX( _curobj + 1, 1)
RETURN
