******************************************************************************
*** PROGRAM:  Attord.prg
*** Abstract: Add order(s) to Order.DBF for a new attorney added to a case.
*** Notes: Set the order status based on TABills.Response (T, O, F, or S)
*** 		  Assumes that any auto-reopen of case is done by calling program.
*** HN 11/19/97
*** Called by: TABills
***
*** Assumes that any auto-reopen of case is done by calling program.
*
*** 04/19/12  EF   use stored procs instead of the direct sqls
*** 01/18/10  EF   Warn users about attys on credit hold
*** 03/22/06  kdl  Set all oakland response='S' records to declined status in order table
*** 07/07/04  kdl  added DS phase 2 modifications
*** 04/13/04  kdl  Add prefered ship type to orders
*** 10/07/03  EF   Non Credit hold atty gets "unk" orders
***                (all tags except those in 'Cancelled' status)
****               but On-hold and 'cancelled" tags get 'decln' orders
*** 07/15/03  DMA  Improve efficiency by taking one-time activity out of SCAN
*** 07/09/03  DMA  Switch to SQL INSERT
*** 04/21/01  DMA  Eliminate parameter mcl_code; replaced w/global vbl.
*** 09/15/00  DMA  If adding an attorney on credit-hold, set
***                status to declined for all tags.
******************************************************************************
PROCEDURE AttOrd
PARAMETERS c_attorney
LOCAL n_CurFile, n_CurrRec, ld_Decln, c_Shiptype, c_sql, c_cleanatcode, lc_BillResponse ;
	,n_esrvcnt, L_credit,lpost, omed_AT AS Object

n_CurFile = SELECT()
IF NOT EMPTY( n_CurFile)
	n_CurrRec = RECNO()
ENDIF
pc_userid=ALLTRIM(NVL(pc_userid,''))

*ogen=CREATEOBJECT('medgeneric')
*c_cleanatcode="'"+GFSTRCLEAN(c_attorney)+"'"   &&ogen.cleanstring(c_attorney)
omed_AT=CREATEOBJECT('medorder')
c_sql=""
c_sql = " exec dbo.GetDefendantRecordbyAtcode '" + FIXQUOTE(c_attorney) + "'"
**04/19/2012 - use stored procs instead of the direct sqls
*!*	c_sql = "SELECT * FROM tbldefendant WITH (nolock,INDEX (ix_tbldefendant_1)) WHERE at_code="+c_cleanatcode+;
*!*		" AND active=1 AND deleted is null"
omed_AT.sqlexecute(c_sql,'taatty')
c_sql=""
*c_sql= "SELECT * FROM tblbill WITH (nolock,INDEX (ix_tblbills_2)) WHERE cl_code='&pc_clcode.' AND at_code="+c_cleanatcode+;
	" AND active=1 AND deleted is null"
	c_sql ="exec [dbo].[GetBillsByClCodeAtCode] '" + fixquote(pc_clcode)+"','" +fixquote(c_attorney) + "'"
omed_AT.sqlexecute(c_sql,'tabills')
SELECT tabills
IF RECCOUNT('tabills') > 0 AND RECCOUNT('taatty') > 0
	lc_BillResponse=ALLTRIM(NVL(tabills.Response,"F"))
	IF EMPTY(ALLTRIM(lc_BillResponse))
		lc_BillResponse="F"
	ENDIF
	L_credit=.F.
**01/18/10- atty's on credit hold - warn a user
	IF INLIST( taatty.billstatus, "H", "B") AND ALLTRIM(lc_BillResponse)="T"

		L_credit=.T.
		gfmessage("Warning: Attorney is on Credit Hold. Contact Accounts Receivable.")

	ENDIF
**01/18/10- atty's on credit hold - warn a user
*!*		c_sql= "SELECT * FROM tblrequest WITH (nolock,INDEX (ix_tblrequests)) WHERE id_tblmaster='"+tabills.id_tblmaster+;
*!*			"' AND active=1 AND deleted is null"
c_sql=""
c_sql=" Exec [dbo].[GetRequestByMasterId] '"+tabills.id_tblmaster+ "'"
	omed_AT.sqlexecute(c_sql,'record')
	SELECT RECORD

	IF RECCOUNT() > 0
		WAIT WINDOW "Adding client's order information to all tags. " + ;
			CHR(13) + "Please wait." NOWAIT NOCLEAR
		n_esrvcnt=1
		SCAN WHILE ALLTRIM( RECORD.Cl_Code) == ALLTRIM( pc_clcode)
			IF ALLTRIM(UPPER(RECORD.login_id))=='ESERVE' 
			   IF ALLTRIM(UPPER(pc_litcode))<>'NEW'		&& 08/09/2011 MD NEW litigaiton falls under regular RTS rules
				DO Esjob WITH c_attorney,pn_lrsno,RECORD.TAG,IIF(n_esrvcnt=1,'A','B')
				n_esrvcnt=n_esrvcnt+1
				LOOP
			 ENDIF 
			ENDIF
*--3/22/06 kdl start: set all oakland response='S' records to declined status in order table
*ld_Decln = IIF( Record.Status = "C" OR ;
INLIST( taatty.billstatus, "H", "B") OR (pl_ofcOak AND tabills.response=='S'), DATE(), {})

*!*				c_sql= "SELECT * FROM tblorder WITH (nolock,INDEX (ix_tblorder_1)) WHERE cl_code='&pc_clcode.' AND at_code="+c_cleanatcode+;
*!*					" and tag="+STR(RECORD.TAG)+" AND active=1 AND deleted is null"
c_sql=""
c_sql ="exec [dbo].[GetOrderbyClAtTag] '" + fixquote(pc_clcode) +"','" + fixquote(c_attorney)+  "','" + STR(RECORD.TAG) + "'" 
			omed_AT.sqlexecute(c_sql,'order')
			SELECT ORDER
			IF RECCOUNT() = 0
				APPEND BLANK
				n_Pcopies = tabills.NumCopy

				SELECT ORDER
				c_OrdResp = "F"
				d_Ordered = NULL
				d_Declined = NULL
				IF ALLTRIM(UPPER(lc_BillResponse))=="T" AND ;
						(INLIST(ALLTRIM(UPPER(NVL(RECORD.STATUS,""))),"W","T") AND EMPTY(NVL(RECORD.hStatus,'')))
					c_OrdResp = "T"
					d_Ordered =d_today
				ELSE
*  For attorney in "No order", "declined to order", or "cancelled"
*  status, decline to order this tag
					d_Declined = d_today
				ENDIF

				REPLACE Cl_Code WITH pc_clcode, ;
					TAG WITH RECORD.TAG, ;
					At_Code WITH c_attorney, ;
					Date_decln WITH d_Declined, ;
					BillCat WITH tabills.BillCat, ;
					NumCopy WITH n_Pcopies, ;
					FedEx WITH tabills.FedEx, ;
					Handling WITH tabills.Handling, ;
					Acct_Mgr WITH tabills.Acct_Mgr, ;
					Sales_Per WITH tabills.Sales_Per, ;
					shiptype WITH IIF( n_Pcopies > 0, "P", ""), ;
					id_tblbills WITH tabills.id_tblbills, ;
					created WITH DTOT(d_today), ;
					createdby WITH pc_userid, ;
					ACTIVE WITH .T. ;
					Response WITH c_OrdResp, date_order WITH d_Ordered,  Cred_Hold  WITH L_credit;
					IN ORDER

				omed_AT.updatedata()

*// add disttodo ship jobs
				lpost=IIF((ISNULL(d_Declined) AND NOT ISNULL(d_Ordered )) and INLIST(NVL(record.status,''),'R','N'),.T.,.F.)
				DO addtypes WITH pc_clcode,c_attorney, ;
					RECORD.TAG,d_null,n_Pcopies,lpost

			ENDIF
			SELECT RECORD
		ENDSCAN
	ELSE
		gfmessage("No tags in this case; orders will not be added." )
	ENDIF
ENDIF
IF USED('tabills')
	USE IN tabills
ENDIF
IF USED('taatty')
	USE IN taatty
ENDIF
IF USED('record')
	USE IN RECORD
ENDIF
IF USED('order')
	USE IN ORDER
ENDIF

RELEASE omed_at
IF NOT EMPTY( n_CurFile)
	SELECT ALIAS( n_CurFile)

	GO n_CurrRec
ENDIF
WAIT CLEAR
RETURN

***********************************************************************
* PROCEDURE: Addtype
* ABSTRACT: Add multiple order shipment types when the tag is issued
*--called by setordtg.prg
***********************************************************************
PROCEDURE addtypes
PARAMETERS c_clcode, c_atcode, n_tag, d_Order, n_Pcopies,l_post
LOCAL c_cleancode,c_date,n_dsid, omed_ship as Object
c_date=DTOC(NVL(d_Order,{}))
c_date=NVL(IIF(EMPTY(CTOD(c_date)),"NULL","'"+c_date+"'"),'')
omed_ship=CREATEOBJECT('medorder')
c_sql="exec [dbo].[GetMasterByclcode] '" + FIXQUOTE(c_clcode) +"'"
omed_ship.sqlexecute(c_sql,"typemaster")

*c_cleancode="'"+GFSTRCLEAN(c_atcode)+"'"
*!*	c_sql= "SELECT * FROM tblship WITH (nolock) WHERE cl_code='&c_clcode.' AND at_code="+c_cleancode+" AND active=1 AND deleted is null"
c_sql="exec [dbo].[GetShipbyClcodeAtcode]  '" + fixquote(c_clcode)+"','" + fixquote(c_atcode) + "'"

omed_ship.sqlexecute(c_sql,'gtaship')

IF RECCOUNT('gtaship') > 0
	n_Pcopies =  gtaship.rpapernum
	IF NVL(gtaship.rcdnum,0) > 0
		c_sql="EXEC dbo.DsInsertitemtype '&c_Clcode.',"+STR(n_tag)+",'" + fixquote(c_atcode) + "'" + ;
			",'CD',1,'"+NVL(gtaship.rcdincrem,"T")+"',0,'"+NVL(gtaship.rcdfile,"")+"',"+c_date+",'&pc_userid.'"
		omed_ship.sqlexecute(c_sql)

		IF l_post
			n_dsid=gfdsjobid()
			c_sql= "EXEC dbo.dspost '&c_clcode.',"+STR(n_TAG)+",'" + fixquote(c_atcode) + "','"+typemaster.area+"',0,'CD','',6,1,NULL,'&n_dsid.'"
			omed_ship.sqlexecute(c_sql)
		ENDIF
	ENDIF
	IF NVL(gtaship.rdsnum,0) > 0
		c_sql="EXEC dbo.DsInsertitemtype '&c_Clcode.',"+STR(n_tag)+",'" + fixquote(c_atcode) + "'" + ;
			",'DS',1,'',0,'',"+c_date+",'&pc_userid.'"
		omed_ship.sqlexecute(c_sql)

		IF l_post
			n_dsid=gfdsjobid()
			c_sql= "EXEC dbo.dspost '&c_clcode.',"+STR(n_TAG)+",'" + fixquote(c_atcode) + "','"+typemaster.area+"',0,'DS','',6,1,NULL,'&n_dsid.'"
			omed_ship.sqlexecute(c_sql)
		ENDIF
	ENDIF
	IF NVL(gtaship.rvsnum,0) > 0
		c_sql="EXEC dbo.DsInsertitemtype '&c_Clcode.',"+STR(n_tag)+",'" + fixquote(c_atcode) + "'" +  ;
			",'VS',1,'',0,'',"+c_date+",'&pc_userid.'"
		omed_ship.sqlexecute(c_sql)

		IF l_post
			n_dsid=gfdsjobid()
			c_sql= "EXEC dbo.dspost '&c_clcode.',"+STR(n_TAG)+",'" + fixquote(c_atcode) + "','"+typemaster.area+"',0,'VS','',6,1,NULL,'&n_dsid.'"
			omed_ship.sqlexecute(c_sql)
		ENDIF
	ENDIF
	IF NVL(gtaship.rshipftp,0)
		c_sql="EXEC dbo.DsInsertitemtype '&c_Clcode.',"+STR(n_tag)+",'" + fixquote(c_atcode) + "'" + ;
			",'FT',1,'',0,'',"+c_date+",'&pc_userid.'"
		omed_ship.sqlexecute(c_sql)

		IF l_post
			n_dsid=gfdsjobid()
			c_sql= "EXEC dbo.dspost '&c_clcode.',"+STR(n_TAG)+",'" + fixquote(c_atcode) + "','"+typemaster.area+"',0,'FT','',6,1,NULL,'&n_dsid.'"
			omed_ship.sqlexecute(c_sql)
		ENDIF
	ENDIF
ENDIF
RELEASE omed_ship
IF USED('gtaship')
	USE IN gtaship
ENDIF

IF USED('typemaster')
	USE IN typemaster
ENDIF
