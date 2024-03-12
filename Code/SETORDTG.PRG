PROCEDURE SetOrdTg
*** EF 09/28/2010- check if the shipment methods are set CALL [dbo].[NeedsShipSetting]
*** EF 12/03/2008-SEE COMMENTS BELOW
*** EF 09/29/08 - check shipment prefernces before adding the orders
*** EF 1/11/06 -Switched to SQL
**************************************************************************
*** Adds orders to Order.dbf for a brand-new tag,
*** based on case-level order information in TABills,
*** when the tag is being added to the system during the issue process.
*** Sets the order status based on F, T, O, or S in TABills.Response
*** plus the attorney's credit-hold status.
*** Called by Subp_PA
*** Previously called by AddRec
**************************************************************************
PARAMETERS n_tagno, lSuppWarning
** pc_clcode = cl_code of case receiving orders
** n_tagno = deponent number for item receiving orders
IF PCOUNT() < 2
	lSuppWarning = .F.
ENDIF

WAIT CLEAR
PRIVATE ordused, tabused, attused, n_CurFile, c_OrdResp, d_Ordered, ;
	d_Declined, l_hold, c_Response, tasused, n_Pcopies , n_Pcopies3   &&c_Shiptype
LOCAL lcSQLLine AS STRING, oMed AS OBJECT

l_hold = .F.
lDSOrd=.F.
n_CurFile = SELECT()
oMed=CREATEOBJECT("generic.medgeneric")

*--3/10/21: trap for missing/empty cl_code [230122]
IF EMPTY(NVL(pc_clcode,"")) AND NOT EMPTY(NVL(pn_lrsno,0))
	lcSQLLine = "SELECT DBO.getClCodeByLrs(" + ALLTRIM(STR(pn_lrsno)) +") AS CL_CODE"
	oMed.sqlexecute(lcSQLLine,"viewlrs")
	IF USED("viewlrs")
		pc_clcode=NVL(viewlrs.cl_code,"")
		USE IN "viewlrs"
	ENDIF
ENDIF

lcSQLLine="exec dbo.getBills '"+ALLTRIM(fixquote(pc_clcode))+"'"
oMed.sqlexecute(lcSQLLine,"viewBills")

SELECT viewBills
IF RECCOUNT()=0 OR EMPTY(ALLTRIM(pc_clcode))
	gfmessage("Setordtg: Attorney list for client code ="+ALLTRIM(UPPER(pc_clcode))+" is empty!"+CHR(13)+;
		"Can't add any orders.  Please notify IT department")
	RETURN
ENDIF
WAIT WINDOW  "Adding orders. Please wait." NOWAIT NOCLEAR
SCAN
	c_Response = UPPER(ALLTRIM(viewBills.Response))
	c_Atty=fixquote(viewBills.at_code)
** check if the shipment methods are set 09.28.2010-start
	oMed.sqlexecute("SELECT [dbo].[NeedsShipSetting] ('" +ALLTRIM(fixquote(pc_clcode)) + "','" +  c_Atty + "')", "ChkShip")
	IF ChkShip.EXP AND lSuppWarning = .F.
		gfmessage("Can not find a proper shipment setting for this attorney("  + ALLTRIM(c_Atty) +  "). Please note the atty code and update it manually." )
	ENDIF
** check if the shipment methods are set 09.28.2010 -end



*  If attorney is ordering all, see if there is a credit-hold in effect.
*  Credit hold will override attorney's request for auto-ordering, but
*  will not block an existing order from being processed.
*  Also check for an attorney who's been deleted from the rolodex.
	l_hold = .F.
	IF c_Response = "T"
		l_AttySt=oMed.sqlexecute("SELECT dbo.fn_AttyBillStatus('" + c_Atty + "')", "AttySt")
		l_hold=AttySt.EXP
	ENDIF
	l_ord=ordersql (pc_clcode, viewBills.at_code, n_tagno)
	SELECT ORDER
	SEEK ALLTRIM(UPPER(pc_clcode))+"*"+ALLTRIM(UPPER(viewBills.at_code))+"*"+ALLTRIM(STR( n_tagno))
	IF FOUND()
		IF ALLTRIM(UPPER(ORDER.cl_code))==ALLTRIM(UPPER(pc_clcode)) AND ;
				ALLTRIM(UPPER(ORDER.at_code))== ALLTRIM(UPPER(viewBills.at_code)) AND ;
				ORDER.TAG == n_tagno
* A record in the Order table already exists for this
* case/tag/attorney combination.
* If status is unknown and attorney has given us an "Order All" or
* "Decline All" request, update the existing order's information
* Also store the credit-hold status in the updated order.
			d_Ordered=convrtDate(ORDER.date_order)
			d_Declined=convrtDate(ORDER.date_decln)
			IF EMPTY(d_Ordered) AND EMPTY(d_Declined) && Unknown status
**EF 06/15/05 -add "S" to the below list
				IF INLIST(ALLTRIM(UPPER(c_Response)), "T", "F", "S","C")

					IF c_Response = "T"
						lcSQLLine="update tblOrder set date_order='"+DTOC(d_today)+"', response='"+;
							ALLTRIM(UPPER(NVL(c_Response,"")))+"', cred_hold="+IIF(l_hold=.T.,"1","0")+;
							" where id_TblOrders='"+ALLTRIM(ORDER.id_TblOrders)+"'"
						oMed.sqlexecute(lcSQLLine)

					ELSE
**02/24/2009 - do not add "C" responses to the Orders
						c_Response= IIF(c_Response="C", "F",c_Response)
						lcSQLLine="update tblOrder set Date_Decln='"+DTOC(d_today)+"', response='"+;
							ALLTRIM(UPPER(NVL(c_Response,"")))+"', cred_hold="+IIF(l_hold=.T.,"1","0")+;
							" where id_TblOrders='"+ALLTRIM(ORDER.id_TblOrders)+"'"
						oMed.sqlexecute(lcSQLLine)

					ENDIF
				ENDIF
			ENDIF

			n_Pcopies = 1

			c_str= "Exec dbo.sp_AddTypes '" +ALLTRIM(fixquote(pc_clcode))+ "','" + c_Atty + "','" ;
				+ ALLTRIM(STR(n_tagno)) + "',"+ IIF(EMPTY(NVL(d_Ordered,{})),"NULL", "'"+DTOC(d_Ordered)+"'") + ",' " ;
				+ ALLTRIM(STR(NVL(n_Pcopies,0))) + "','" + ALLTRIM(NVL(pc_userid,"")) + "'"
			lDSOrd=oMed.sqlexecute(c_str)
**EF 12/05/2008- NEEDS THAT CHECK FOR ALL KIND OF ORDERS.

			lcSQLLine=" Select  dbo.GetPaperCopyShip ('" +ALLTRIM(fixquote(pc_clcode)) + "','" + c_Atty + "')"
			l_ChkPaper=oMed.sqlexecute(lcSQLLine, "PShipCase")
			IF l_ChkPaper AND NOT EOF()
				n_Pcopies =PShipCase.EXP
			ENDIF
**EF end-12/05/2008


			IF n_Pcopies = 0 AND (ORDER.numcopy > 1 OR ALLTRIM(UPPER(ORDER.shiptype)) = "P")
				lcSQLLine="update tblOrder set numcopy=0, shiptype=''"+;
					" where id_TblOrders='"+ALLTRIM(ORDER.id_TblOrders)+"'"
				oMed.sqlexecute(lcSQLLine)

			ENDIF
		ENDIF
	ELSE
** No order recorded yet for this attorney/case/tag.
** Determine appropriate order status and enter it.
** Default is "Unknown" order, which always occurs
** if attorney's response is "S" (order some) or blank.
		c_OrdResp = "F"
		d_Ordered = NULL&&gdBlankDt
		d_Declined = NULL&&gdBlankDt
		DO CASE
*  Always decline if attorney is on credit hold
		CASE l_hold
			d_Declined = d_today
*  For "order all" attorney not on hold, place order for tag
		CASE c_Response = "T"
			c_OrdResp = "T"
			d_Ordered =d_today
*  For attorney in "No order", "declined to order", or "cancelled"
*  status, decline to order this tag
		CASE INLIST(ALLTRIM(UPPER(c_Response)), "O", "F", "C", "S")
			d_Declined = d_today
		ENDCASE
		n_Pcopies = NVL(viewBills.numcopy,0)

**EF 12/05/2008- NEEDS THAT CHCEK FOR ALL KIND OF ORDERS.
		IF n_Pcopies=0
			lcSQLLine=" Select  dbo.GetPaperCopyShip ('" +ALLTRIM(fixquote(pc_clcode)) + "','" + c_Atty + "')"
			l_ChkPaper=oMed.sqlexecute(lcSQLLine, "PShipCase")
			IF l_ChkPaper AND NOT EOF()
				n_Pcopies =PShipCase.EXP
			ENDIF
		ENDIF
**EF end-12/05/2008
*--add line item records for all participating attorneys
		c_str= "Exec dbo.sp_AddTypes '" +ALLTRIM(fixquote(pc_clcode))+ "','"+ c_Atty + "','" ;
			+ STR(n_tagno) + "', "+ IIF(EMPTY(NVL(d_Ordered,{})),"NULL","'"+DTOC(d_Ordered)+"'")+", '" ;
			+ STR(NVL(n_Pcopies,0)) + "','"+ NVL(ALLTRIM(pc_userid),'') + "'"
		lDSOrd=oMed.sqlexecute(c_str)
		IF NOT lDSOrd
			=gfmessage("Can not add proper shiptypes for this Tag! Update the shiptypes manually.")
		ENDIF
&&07/18/17 :  Zofran/Insurance blurb tags need "R" in the hamdling (AM resp hold)#65101
		c_handling=""
		c_handling=ALLTRIM(UPPER(NVL(viewBills.Handling,"")))
&&08/02/17: make sure we have pc_BlurbCodes #67009
		IF TYPE('pc_BlurbCodes')<>"C"
			pc_BlurbCodes=""
		ENDIF

		IF   pc_litcode="ZOF" AND PL_1ST_REQ AND  NVL(pc_rqatcod,'')=NVL( c_Atty,"")   AND "I014" $ ALLTRIM(pc_BlurbCodes)
			c_handling ="R"
		ENDIF



		lcSQLLine="exec dbo.InsertOrderLine '"+ALLTRIM(NVL(viewBills.id_tblbills,""))+"', "+;
			"'"+ALLTRIM(fixquote(pc_clcode))+"', '"+ALLTRIM(fixquote(NVL(viewBills.at_code,"")))+"', "+;
			"'"+ALLTRIM(STR(n_tagno))+"', "+IIF(EMPTY(NVL(d_Ordered,{})),"NULL","'"+DTOC(d_Ordered)+"'")+", "+;
			IIF(EMPTY(NVL(d_Declined,{})),"NULL","'"+DTOC(d_Declined)+"'")+", NULL, "+;
			"'"+ALLTRIM(UPPER(NVL(viewBills.BillCat,"")))+"', '"+ALLTRIM(STR(NVL(n_Pcopies,0)))+"', "+;
			IIF(viewBills.FedEx=.T.,"1","0")+", '"+c_handling+"', 0, "+;
			"'"+IIF( n_Pcopies > 0, "P", "")+"', 0, '"+ALLTRIM(UPPER(NVL(viewBills.Acct_Mgr,"")))+"', "+;
			"'"+ALLTRIM(UPPER(NVL(c_OrdResp,"F")))+"', '"+ALLTRIM(UPPER(NVL(viewBills.Sales_Per,"")))+"', "+;
			"'"+ALLTRIM(UPPER(NVL(pc_userid,"")))+"'"
		oMed.sqlexecute(lcSQLLine)
	ENDIF
	SELECT viewBills
ENDSCAN
**update doifcancel here
WAIT CLEAR
IF NOT EMPTY( n_CurFile)
	SELECT ALIAS( n_CurFile)
ENDIF
RELEASE oMed
RETURN
