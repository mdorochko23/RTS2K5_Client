PROCEDURE BillCovr
*****************************************************************************
* California Billing Cover Sheet
* Formerly Procedure CABillCover internal to Printcov
*
*  Called from PrintCov, Orders
*  Assumes that gfGetCas, gfGetDep were already called prior to entry
*  Calls gfDepInf, gfAtty, gfsendds
*
* History :
* EF 11/19/07 - Added l_canceled to identify B & B Closed Pockets tags.
* MD 08/02/07 - modified to include scanning hold status;
*               to print only first page
* EF 04/12/07 - replaced direct sql with the [dbo].[GetOrderbyClAtTag].
* Date      Name  Comment
* ---------------------------------------------------------------------------

PARAMETERS lcCl_Code, lnTag, lccAt_Code, lclfShtype
** lcCl_Code, lnTag: Client code and tag of deponent for which cover
**                   letter is being printed.

nParam = PARAMETERS()

** lccAT_Code: Optional parameter w/an attorney code. If present,
**             cover letter is only produced for this specific attorney.
**             If absent, cover letter is produced for all ordering attys.
**             List of ordering attorneys is in public array ARATTY.

*
*  On entry, TAMaster should be open and positioned at the case's record,
*  Record should be open and positioned at the tag's record,
*  and the appropriate EntryX file should be open in work-area F.
*
LOCAL dbInit, ldOrder, lDecline,  lnCopy, llFedEx, c_Ordtypes, ;
	lnTotal, l_hascaptn, c_mailfile, c_addr2, l_currBB, d_subp, c_admitstr, ;
	n_lcnt, n_Alen, n_indent,l_record,l_Hsftimage,l_softpg, lnArrayLen, l_canceled, ogen

LOCAL lcSQLLine, lloGen, lnCurArea, lcLrs
lcLrs=""
lnCurArea=SELECT()
l_canceled=.F.
*IF TYPE("oGen")!="O"
ogen=CREATEOBJECT("medrequest")
*!*	   lloGen=.T.
*!*	ENDIF
IF USED("temprep")
	USE IN temprep
ENDIF
CREATE CURSOR temprep(textline c(80))

l_softpg=IIF( pl_ofcOak, .T., .F.)   &&flag for a scanning page
l_Hsftimage = pl_softimg
llFound = .F.
pl_GotDepo=.F.
DO gfgetDep WITH lcCl_Code, lnTag

**10/01/18 SL #109598
*lcSQLLine="select status,hStatus from tblRequest with (nolock,INDEX(ix_tblRequests_2)) where cl_code='"+
lcSQLLine="select status,hStatus from tblRequest with (nolock) where cl_code='"+;
	ALLTRIM(lcCl_Code)+"' and tag='"+ALLTRIM(STR(lnTag))+"' and active=1"
ogen.sqlexecute(lcSQLLine,"viewStatus")
SELECT viewStatus
IF RECCOUNT()>0
	pc_Status  = viewStatus.STATUS
* MD Added to include scanning hold status
	IF ALLTRIM(UPPER(viewStatus.STATUS))=="W" AND !EMPTY(ALLTRIM(NVL(viewStatus.hStatus,"")))
**EF 11/19/07 -START
		pc_Status  = viewStatus.hStatus
		IF pl_BBcase
			l_OK=ogen.sqlexecute("SELECT dbo.IFBBCanceledTag ('" + ALLTRIM(lcCl_Code) + "','" + ALLTRIM(STR(lnTag))+"')", "CanceledTag")
			l_canceled=IIF(l_OK,CanceledTag.EXP, .F.)

		ENDIF
		pc_Status=IIF(l_canceled, "C",viewStatus.hStatus)
**EF 11/19/07 -END
	ENDIF
ENDIF
USE

**10/01/18 SL #109598
*lcSQLLine="select txn_Date from tblTimeSheet WITH (nolock,INDEX(ix_tblTimeSheet)) where cl_code='"+
lcSQLLine="select txn_Date from tblTimeSheet WITH (nolock) where cl_code='"+;
	ALLTRIM(lcCl_Code)+"' and tag='"+ALLTRIM(STR(lnTag))+;
	"'and txn_code=11 and active=1 order by created"
ogen.sqlexecute(lcSQLLine,"viewDate")
SELECT viewDate
IF RECCOUNT()>0
	d_subp = viewDate.txn_date
ELSE
	d_subp ={}
ENDIF
USE

l_hascaptn = .F.
l_currBB = .F.
IF nParam < 4
	lclfShtype = ""  					&& passed ship type for one time order printing
ENDIF
IF nParam > 2
	llNetwork = .F.
	aratty = ""
	DIMENSION aratty[1]
	aratty[1] = lccAt_Code
ENDIF

lnArrayLen=ALEN(aratty)
IF lnArrayLen=1 AND EMPTY(ALLTRIM(aratty[1]))
	lnArrayLen=0
ENDIF
**02/01/2010-get dept
LOCAL lcdept AS STRING
lcdept="Z"
lcSQLLine=""
lcSQLLine="select  dbo.getLatestDept ('" +fixquote(ALLTRIM(lcCl_Code))+"','" +ALLTRIM(STR(lnTag))+"')"
ogen.sqlexecute(lcSQLLine,"viewDept")

IF NOT EOF()
	lcdept=viewDept.EXP
ENDIF
**02/01/2010

pl_Mail = .F.
DO gfDepInf WITH lcdept

*--3/9/18: need to make sure at least one page gets printed, so keep trying ountil one page created or no more attorneys. [80877]
bPagePrinted = .F.
FOR nLoop = 1 TO lnArrayLen
*--FOR nLoop = 1 TO 1 &&lnArrayLen -   MD commented to print only one page
*lcSQLLine="select * from tblOrder with (nolock,INDEX(ix_tblOrder_1)) where cl_code='"+;
ALLTRIM(lcCl_Code)+"' and tag='"+ALLTRIM(STR(lnTag))+"' and at_code='"+;
ALLTRIM(fixquote(aratty[nloop]))+"' and active=1 order by created"

	lcSQLLine="Exec [dbo].[GetOrderbyClAtTag] '" + fixquote(ALLTRIM(lcCl_Code))+"','" +ALLTRIM(fixquote(aratty[nloop]))+"','" + ;
		ALLTRIM(STR(lnTag))+"'"

	ogen.sqlexecute(lcSQLLine,"viewBillOrder")

	SELECT viewBillOrder

	lcshiptype = IIF( EMPTY(NVL(lclfShtype,"")), ;
		IIF( EMPTY(NVL(viewBillOrder.shiptype,"")), "P", UPPER(NVL(viewBillOrder.shiptype,""))), lclfShtype)
	c_Ordtypes = IIF( viewBillOrder.NumCopy > 0 AND ;
		INLIST(viewBillOrder.shiptype, " ", "P"), "P", viewBillOrder.shiptype)
	lcSQLLine="Exec dbo.call_dsordertype '"+lcCl_Code+"', "+ALLTRIM(STR(lnTag))+","+ ;
		"'"+fixquote(aratty[nloop])+"', '"+""+"', '"+viewBillOrder.shiptype+"', 0, "+;
		"'"+viewBillOrder.id_tblOrders+"', '"+goApp.CurrentUser.ntlogin+"', '&c_Ordtypes.',2"
	ogen.sqlexecute(lcSQLLine,"viewShipTypes")
	SELECT viewShipTypes
	IF RECCOUNT()>0
		c_Ordtypes=viewShipTypes.ordtypes
	ENDIF
	SELECT viewShipTypes
	USE

	IF viewBillOrder.NumCopy < 1 AND NOT ;
			("D" $ c_Ordtypes OR "V" $ c_Ordtypes OR ;
			"C" $ c_Ordtypes OR "F" $ c_Ordtypes)
		LOOP
	ENDIF
	ldOrder = viewBillOrder.date_order
	SELECT viewBillOrder
	USE
	lcAddress=""
	DO lfPrtAddr IN printCov
	l_hascaptn = (EMPTY(ALLTRIM(NVL(pc_plcaptn,"") + NVL(pc_dfcaptn,""))))
	c_Case=IIF( l_hascaptn,ALLTRIM(NVL(pc_casenam,"")), ;
		ALLTRIM(NVL(pc_plcaptn,"")) + " v. " + ALLTRIM(NVL(pc_dfcaptn,"")))
	n_len =LEN (ALLTRIM(c_Case))
	STORE "" TO lcLine1,lcLine2, lcplNam1, lcplNam2, lcFirm
	IF n_len > 40
		n_cnt = RAT(" ", c_Case,2)
		lcLine1 = LEFT( c_Case, n_cnt)
		lcLine2 = RIGHT( c_Case, n_len-n_cnt)
	ELSE
		lcLine1 = c_Case
	ENDIF
	IF LEN( ALLT(NVL(pc_plnam,""))) > 40
		lcplNam2=ALLTRIM(pc_plnam)
	ELSE
		lcplNam1=ALLTRIM(NVL(pc_plnam,""))
	ENDIF

	lcSQLLine="select dbo.GetFirmName ('"+ALLTRIM(NVL(pc_platcod,""))+"')"
	ogen.sqlexecute(lcSQLLine,"FirmName")
	SELECT FirmName
	IF RECCOUNT()>0
		lcFirm=FirmName.EXP
	ENDIF
	USE
	lcMailPhn=""
	DO CASE
	CASE TYPE("pn_MailPhn")="N"
		lcMailPhn=ALLTRIM(STR(pn_MailPhn))
	CASE TYPE("pn_MailPhn")="C"
		lcMailPhn=ALLTRIM(pn_MailPhn)
	ENDCASE
	IF LEN(ALLTRIM(NVL(lcMailPhn,"")))>0
		lcMailPhn=PADR(ALLTRIM(lcMailPhn),10,"0")
		lcMailPhn="("+LEFT(ALLTRIM(lcMailPhn),3)+") "+;
			SUBSTR(ALLTRIM(lcMailPhn),4,3)+"-"+RIGHT(ALLTRIM(lcMailPhn),4)
	ENDIF
	STORE "" TO c_admitstr, c_admit, c_recv
	IF pl_BBcase
		DO lfaddBB
	ELSE
		DO lfaddAdmissn
	ENDIF

	STORE "" TO lcAttyFirm, lcAttyAdd1, lcAttyAdd2, lcAttyAdd3, lcNewFirst, lcNewLast, lcAttn, lcShipText
	IF NOT l_softpg
		l_currBB = (aratty[nloop] = "BEBE  3C")
		IF l_currBB
			lcAttyFirm="LAW OFFICES OF SPANOS | PRZETAK"
			lcAttyAdd1="2930 LAKESHORE AVENUE"
			lcAttyAdd2=""
			lcAttyAdd3="OAKLAND, CA  94610"
			lcAttn=ALLTRIM(NVL(pc_reqpara,""))
		ELSE
			lcSQLLine="exec dbo.GetAttyInfo '"+ALLTRIM(NVL(aratty[nloop],""))+"'"
			ogen.sqlexecute(lcSQLLine,"AttyInfo")
			SELECT AttyInfo
			IF RECCOUNT()>0
				lcAttyFirm=AttyInfo.Firm
				lcAttyAdd1=AttyInfo.NewAdd1
				lcAttyAdd2=AttyInfo.NewAdd2
				lcAttyAdd3=ALLTRIM(AttyInfo.NewCity)+", "+;
					ALLTRIM(AttyInfo.NewState)+" "+ALLTRIM(AttyInfo.Newzip)
				lcNewFirst=AttyInfo.NewFirst
				lcNewLast=AttyInfo.NewLast
			ENDIF
			USE
			IF aratty[nloop] = pc_rqatcod
				lcAttn=ALLTRIM(NVL(pc_reqpara,""))
			ELSE
				lcOrderBy=""
				**10/01/18 SL #109598
				*lcSQLLine="SELECT Ordered_By FROM tblBill with (nolock,index(ix_tblBills_2)) where "+
				lcSQLLine="SELECT Ordered_By FROM tblBill with (nolock) where "+;
					"cl_code='"+ALLTRIM(lcCl_Code)+"' and at_code='"+ALLTRIM(aratty[nLoop])+"' "+;
					"and active=1"
				ogen.sqlexecute(lcSQLLine,"BillInfo")
				SELECT BillInfo
				IF RECCOUNT()>0
					lcOrderBy=ALLTRIM(BillInfo.ordered_By)
				ENDIF
				USE
				lcAttn=IIF( NOT EMPTY(lcOrderBy), lcOrderBy, ;
					ALLT(lcNewFirst) + " " + ALLT(lcNewLast))
			ENDIF
		ENDIF	&& l_currBB
		IF !pl_BBcase
			ldOrder = {1/1/1990}
			ldDecline = {1/1/1990}
			ldCancel = {1/1/1990}
			llFound = .F.
			lnCopy = 0
			lnTotal = 0
			llFedEx = .F.
			llFound = lfOrdStatus( lcCl_Code, lnTag, pc_rqatcod, ;
				@ldOrder, @ldDecline, @lnCopy, @llFedEx, @ldCancel)
		ENDIF
	ENDIF && IF NOT l_softpg
	DO CASE
	CASE TYPE("pn_lrsno")="N"
		lcLrs=ALLTRIM(STR(pn_lrsno))
	CASE TYPE("pn_lrsno")="C"
		lcLrs=ALLTRIM(pn_lrsno)
	OTHERWISE
		gfmessage("Corrupted RT#")
		RETURN
	ENDCASE

	lcBarCode="*"+PADL(lcLrs,8,"0")+"."+PADL(ALLTRIM(STR(lnTag)),3,"0")+"*"
	IF NOT l_softpg
		DIMENSION a_types[5]
		a_types[1] = "P"
		a_types[2] = "D"
		a_types[3] = "V"
		a_types[4] = "C"
		a_types[5] = "F"
		n_Alen = ALEN(a_types, 1)

		FOR n_lcnt = 1 TO n_Alen
			IF a_types[n_lcnt] $ c_Ordtypes
				IF INLIST( a_types[n_lcnt], "D", "V", "C", "F")
					l_sendDS = gfsendds( aratty[nloop])
					IF l_sendDS AND NOT lfbbdisc(a_types[n_lcnt], lcCl_Code, aratty[nloop], lnTag)
						n_dsid=gfdsjobid()
						c_sql= "EXEC dbo.dspost '"+ALLTRIM(fixquote(lcCl_Code))+"', "+STR(lnTag)+",'"+;
							fixquote(aratty[nloop])+"', '"+fixquote(pc_Area)+;
							"',0,'"+a_types[n_lcnt]+"','',6,1,NULL,'&n_dsid.'"
						ogen.sqlexecute(c_sql,'disttodo')
*!*							DO gfdspost WITH lcCl_Code, lnTag, aratty[nloop], a_types[n_lcnt], "", .T., ldOrder, 0, {}, ;
*!*							IIF( NVL(pl_rushcas,.F.), pn_prty2, pn_prty3)
						DO CASE
						CASE a_types[n_lcnt] = "D"
							lcShipText="* ORDER ITEM SHIPPED VIA DISTRIBUTION SERVER"
						CASE a_types[n_lcnt] = "V"
							lcShipText="* ORDER ITEM SHIPPED VIA VIEWING SERVER"
						CASE a_types[n_lcnt] = "C"
							lcShipText="* ORDER ITEM SHIPPED ON CD"
						CASE a_types[n_lcnt] = "F"
							lcShipText="* ORDER ITEM SHIPPED VIA FTP"
						ENDCASE
					ENDIF
				ENDIF
				IF a_types[n_lcnt] = "P"
					lcShipText="* ORDER ITEM SHIPPED VIA HARD COPY"
				ENDIF
			ENDIF
		ENDFOR
	ENDIF

	SELECT temprep
	FOR lnBarCodeCnts=1 TO 6-RECCOUNT("temprep")
		INSERT INTO temprep VALUES (" ")
	NEXT
	
	IF pl_softimg=.T.
	
		*--5/12/22: magna branding: need to send to TIFF/PDF [271273]
		pc_softdir = "t:\softimgs\" + "R_" + pc_lrsno
		n_cnt = ADIR(a_dir, pc_softdir, "D")
		IF n_cnt = 0
			MD &pc_softdir
		ENDIF
		pc_softdir = pc_softdir + "\" + PADL(ALLTRIM(pc_Tag), 3, "0")
		n_cnt = ADIR(a_dir, pc_softdir, "D")
		IF n_cnt = 0
			MD &pc_softdir
		ENDIF
		pc_softdir = pc_softdir + "\"
		
		DO tiff_covletter WITH ;
			"printBillCover2.frx", (pc_softdir + "6_cabill"), 300 
	
	
*!*			_ASCIIROWS=58
*!*		
*!*		*--5/6/20 kdl: use new report version wih barcode removed and page shortened [170904]	
*!*			REPORT FORM printBillCover2 TO FILE (pc_softdir + "6_cabill.txt") ASCII
*!*			*--REPORT FORM printBillCover TO FILE (pc_softdir + "6_cabill.txt") ASCII

		bPagePrinted = .T.
	ELSE
		REPORT FORM printBillCover TO PRINTER NOCONSOLE
		bPagePrinted = .T.
	ENDIF
	IF l_softpg
		pl_softimg = .F.
		l_softpg = .F.
	ENDIF
	SELECT temprep
	ZAP

	*--3/9/18: need to make sure at least one page gets printed, so keep trying ountil one page created or no more attorneys. [80877]
	IF bPagePrinted = .T.
		EXIT
	ENDIF
NEXT
pl_softimg = l_Hsftimage
pl_Mail = .F.
SELECT (lnCurArea)
RETURN

* --------------------------------------------------------------------------
* Get order status
* --------------------------------------------------------------------------
FUNCTION lfOrdStatus
PARAMETER lcClient, lnTag, lcAtty, ldOrder, ldDecline, lnCopy, ;
	llFedEx, ldCancel
LOCAL lcAlias, lcSQLLine, llFound
lcAlias = ALIAS()
*lcSQLLine="select * from tblOrder WITH (nolock) where cl_code='"+ALLTRIM(lcClient)+"' and tag='"+;
ALLTRIM(STR(lnTag))+"' and at_code='"+ALLTRIM(lcAtty)+"' and active=1"
lcSQLLine="Exec [dbo].[GetOrderbyClAtTag] '"+ALLTRIM(lcClient)+"','" + ALLTRIM(lcAtty)+"','" +ALLTRIM(STR(lnTag))+"'"

ogen.sqlexecute(lcSQLLine, "viewOrder")
SELECT viewOrder
IF RECCOUNT()>0
	llFound = .T.
	ldOrder = date_order
	ldDecline = date_decln
	lnCopy = NumCopy
	llFedEx = fedex
	ldCancel = date_cancl
	lcshiptype = IIF( EMPTY(shiptype), "P", UPPER(shiptype))
ELSE
	llFound = .F.
ENDIF
USE
IF NOT EMPTY(lcAlias)
	SELECT (lcAlias)
ENDIF
RETURN llFound
********************************************
* FUNCTION LFBBDISC
* Date: 06/25/04
* Abstract: check if lrs and tag are in bbdisc
*************************************************
FUNCTION lfbbdisc
PARAMETERS c_type, c_clcode, c_atcode, n_tag
PRIVATE l_bbisc, n_Curarea, l_Inbbdisc
n_Curarea = SELECT()
l_Inbbdisc = .F. 		&& tag in bbdisc table flag
IF c_type = "C" AND c_atcode = "BEBE  3C"
	lcBBDisc=ADDBS(ALLTRIM(lookPath()))+"BBDisc.dbf"
	IF FILE(lcBBDisc)
		USE &lcBBDisc ALIAS bbDisc
		SET ORDER TO cltag IN bbDisc
		IF SEEK( c_clcode + "*" + STR(n_tag), "bbdisc")
			l_Inbbdisc = .T.
		ENDIF
		USE
	ENDIF
ENDIF
SELECT (n_Curarea)
RETURN l_Inbbdisc

*************************************************
PROCEDURE lfaddAdmissn
LOCAL lnCurArea, lcSQLLine, lloGen, n_memowidth, ogen
n_memowidth = SET("MEMOWIDTH")
SET MEMOWIDTH TO 60
lnCurArea=SELECT()
ogen=CREATEOBJECT("medrequest")
**10/01/18 SL #109598
*lcSQLLine="select * from tblAdmissn with (nolock,INDEX(ix_tblAdmissn_1)) where cl_code='"+
lcSQLLine="select * from tblAdmissn with (nolock) where cl_code='"+;
	ALLTRIM(lcCl_Code)+"' and tag='"+ALLTRIM(STR(lnTag))+"'and active=1 order by admnumber"
ogen.sqlexecute(lcSQLLine,"viewAdm")
SELECT viewAdm
IF RECCOUNT()>0
	SCAN
		c_admitstr = MLINE(viewAdm.Admission, 1)
		FOR i = 1 TO MEMLINES(viewAdm.Admission)
			INSERT INTO temprep (textline) VALUES (MLINE(viewAdm.Admission, i))
		NEXT
		SELECT viewAdm
	ENDSCAN
ELSE
	ogen.bringMessage( "No admission information found for this record.",2)
ENDIF
SELECT viewAdm
USE
RELEASE ogen
SET MEMOWIDTH TO n_memowidth
SELECT (lnCurArea)
RETURN

******************************************************************************
PROCEDURE lfaddBB
LOCAL lnCurArea
lnCurArea=SELECT()
STORE "" TO c_admit, c_rec
DO CASE
CASE pc_BBType = "MR"
	c_admit = "MEDICAL "
CASE pc_BBType = "MB"
	c_admit = "MEDICAL & BILLING "
CASE pc_BBType = "BR"
	c_admit = "BILLING "
CASE pc_BBType = "ER"
	c_admit = "EMPLOYMENT "
CASE pc_BBType = "PR"
	c_admit = "PATHOLOGY "
CASE pc_BBType = "XR"
	c_admit = "X-RAY "
CASE pc_BBType = "OT"
	c_admit = ""
OTHERWISE
	c_admit = ""
ENDCASE
DO CASE
CASE pc_Status = "R"
	c_recv = "RECORDS" + IIF(NVL(pl_Redacted,.F.), ": REDACTED", "")
CASE pc_Status = "N"
	c_recv = "RECORDS: NO RECORD CERTIFICATE"
CASE pc_Status = "C"
	c_recv = "RECORDS: CLOSED"
OTHERWISE
	c_recv = "RECORDS"
ENDCASE
c_admitstr = c_admit + c_recv
INSERT INTO temprep (textline) VALUES (c_admit + c_recv)
SELECT (lnCurArea)
RETURN
****************************************************************************
PROCEDURE lookPath
LOCAL lc_GlobalPath
DECLARE INTEGER GetPrivateProfileString IN Win32API AS GetPrivStr ;
	STRING cSec, ;
	STRING cKey, ;
	STRING cDef, ;
	STRING @cBuf, ;
	INTEGER nBufSize, ;
	STRING cINIFile
lc_GlobalPath = SPACE(500)
ln_len=GetPrivStr("Data","GLOBAL","\",@lc_GlobalPath,500,SYS(5)+CURDIR()+"rts.ini")
lc_GlobalPath= LEFT(lc_GlobalPath,ln_len)
RETURN lc_GlobalPath
