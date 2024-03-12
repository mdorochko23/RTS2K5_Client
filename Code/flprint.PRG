*************************************************************
* PROGRAM: FLPRINT
* Abstract: first look document printing procedures
*
* Called by: Flproc.prg
* Calls: gfopen.prg, gfclose.prg, global.prg
*
* Modifications:
* Made first-look jobs priority 2
* 05/23/2006 - MD modified printbase procedure to call directly from deponentoptions screen
*
*************************************************************
PARAMETERS d_deliv, d_Return, n_Numdays, c_typeday
IF checkprint(pc_litcode,pc_area) = .f.
	return
ENDIF
LOCAL n_CurArea, c_hospdept, l_used, c_Comm, l_Usecomm, lcSQLLine, lloGen
n_CurArea = SELECT()
c_hospdept=lookDept()
DO Fltitlpg WITH 1
DO CASE
CASE ALLTRIM(pc_litcode) == "G"
*--State diet drug
	dbInit = ALIAS()
	lType = IIF(pc_litcode == "C  ", .F., .T.)
	lcType = ALLTRIM(pc_litcode)
	mv = ""
	mdate = d_Today
	DO FLookPrint IN flook_pa WITH dbInit, pc_clcode, pn_Tag, lcType, d_deliv, n_Numdays
CASE INLIST(ALLTRIM(pc_litcode),"B","I","M")
*--Breast implant
	DO Bimpat1
	DO Bimpat2
CASE ALLTRIM(pc_litcode) == "DGT"
	DO dgtflook
OTHERWISE
*--Default documents
	*ldSentDate=DATE()
	d_Return = gfDtskip( d_Return, 1)
	DO Printbase WITH d_deliv,d_Return, n_Numdays, c_typeday, d_deliv,"", .T.
	*DO Printbase WITH d_deliv, d_Return, n_Numdays, c_typeday, {}, "", .F.
ENDCASE

SELECT (n_CurArea)
RETURN

**************************************************************************************
* PROCEDURE: FLDOCPRT
* ABSTRACT: check if the litigation supresses fl pages
* Called By: printcov.prg
*
**************************************************************************************
FUNCTION CheckPrint
PARAMETERS cLit, cArea

IF PCOUNT() < 1
	RETURN .t.
ENDIF
*--lCheckPrint = .t.
SET CLASSLIB TO dataconnection ADDITIVE
ocon=CREATEOBJECT("dataconnection.cntdataconn")


*--10/13/16: change to table look of for Zoloft type first look
sSql =  "exec [dbo].[GetFlPngValue] '" + ALLTRIM(UPPER(cLit)) + "','" + NVL(ALLTRIM(UPPER(cArea)),'') + "'"
nr=ocon.sqlpassthrough(sSql,'curchecklit')
IF RECCOUNT('curchecklit') >0
	*--if litigation/area found then suppress printing by returning ".F."
	lCheckPrint  = IIF(curchecklit.bresult = .T., .F., .T.)
ENDIF


*--08/25/21 kdl: added pl_Oak_FL_Type - flag to block FL sign-off pages [247599]
IF lCheckPrint=.T.
	n_curarea = SELECT()
	nr=ocon.sqlpassthrough("exec [dbo].[getOakFlLoginType] " + ALLTRIM(STR(pn_lrsno)), 'fltype')
	IF USED("fltype")
		lCheckPrint = NVL(fltype.bresult,.F.)
		USE IN "fltype"
	ENDIF
	SELECT (n_curarea)
ENDIF
	

*!*	sSql = "exec [dbo].[checkflprintbylit] " + gfstrclean(clit,.t.)
*!*	nr=ocon.sqlpassthrough(sSql,'curchecklit')
*!*	IF RECCOUNT('curchecklit') >0
*!*		lCheckPrint = curchecklit.lprint
*!*	ENDIF

IF USED('curchecklit')
	USE IN curchecklit
ENDIF 
RETURN lCheckPrint

**************************************************************************************
*--08/25/21 kdl: fltitpg is not blocked for new FL documents [247599]
FUNCTION CheckPrint2
PARAMETERS cLit, cArea

IF PCOUNT() < 1
	RETURN .t.
ENDIF
*--lCheckPrint = .t.
SET CLASSLIB TO dataconnection ADDITIVE
ocon=CREATEOBJECT("dataconnection.cntdataconn")
sSql =  "exec [dbo].[GetFlPngValue] '" + ALLTRIM(UPPER(cLit)) + "','" + NVL(ALLTRIM(UPPER(cArea)),'') + "'"
nr=ocon.sqlpassthrough(sSql,'curchecklit')
IF RECCOUNT('curchecklit') >0
	*--if litigation/area found then suppress printing by returning ".F."
	lCheckPrint  = IIF(curchecklit.bresult = .T., .F., .T.)
ENDIF
IF USED('curchecklit')
	USE IN curchecklit
ENDIF 
RETURN lCheckPrint

**************************************************************************************
* PROCEDURE: FLDOCPRT
* ABSTRACT: Print first-look record package documents
* Called By: printcov.prg
*
**************************************************************************************
PROCEDURE fldocprt
*--automated generation of 88 transaction
LOCAL l_Has88, d_deliv, n_Numdays, c_typeday, l_Auto
l_Auto = .T.

*--table based check for Zoloft first-look type
SET CLASSLIB TO dataconnection ADDITIVE
ocon=CREATEOBJECT("dataconnection.cntdataconn")
sSql =  "exec [dbo].[GetFlPngValue] '" + ALLTRIM(UPPER(pc_litcode)) + "','" + NVL(ALLTRIM(UPPER(pc_area)),'') + "'"
nr=ocon.sqlpassthrough(sSql,'curchecklit')
lZolType = .F.
IF RECCOUNT('curchecklit') >0
	lZolType  = curchecklit.bresult
ENDIF
IF USED('curchecklit')
	USE IN curchecklit
ENDIF 
 
IF lZolType = .T.
*--IF UPPER(ALLTRIM(pc_litcode)) == "ZOL" OR UPPER(ALLTRIM(pc_litcode)) == "EFF" OR (UPPER(ALLTRIM(pc_litcode))=="ZOF" AND UPPER(ALLTRIM(pc_area))=="GSK")
	*--10/21/14 force effexor/zoloft fl ship type to electronic
	pc_Flship = "E"
	IF NVL(pc_Flship,'E') = "E"
		d_deliv = DATE()
	ELSE
		d_deliv = gfDtskip(DATE(), 2)
	ENDIF
ELSE
	*--7/27/22 kdl: remove 1 day delay for electronic delivery [267860]
	d_deliv = gfDtskip(DATE(), IIF( NVL(pc_Flship,'E') = "E", 0, 2))          && default delivery date to review
	*--d_deliv = gfDtskip(DATE(), IIF( NVL(pc_Flship,'E') = "E", 1, 2))          && default delivery date to review
ENDIF

&&  atty is 3 business days from today
n_Numdays = IIF( EMPTY(NVL(pn_Fldays,0)), 0, pn_Fldays) && Review period in days
c_typeday = IIF( EMPTY(NVL(pc_Fltype,"")), "C", pc_Fltype) && type of days, Buisiness or Calender
l_Has88 = .F.                          && flag for existence of 88 transaction record for the tag
DO Add88txn WITH l_Has88, d_deliv, n_Numdays, c_typeday, l_Auto


*--this call will supress adding FL pages if litigation is stored in the called stored procedure
IF checkprint(pc_litcode,pc_area) = .f. 
	return
ENDIF


CREATE CURSOR temprep(textdate c(80))
APPEND BLANK

StatText = "THIS DOCUMENT HAS NOT BEEN REDACTED"
StatText2=""

IF NVL(pl_Softimg,.F.)
	_ASCIIROWS=58
	REPORT FORM PrintStatText TO FILE (pc_softdir + "2_5flbl1.txt") ASCII
ELSE
	REPORT FORM PrintStatText TO PRINTER NOCONSOLE
ENDIF

StatText = "THIS PAGE INTENTIONALLY LEFT BLANK"
StatText2=""
IF NVL(pl_Softimg,.F.)
	_ASCIIROWS=58
	REPORT FORM PrintStatText TO FILE (pc_softdir + "2_6flbl2.txt") ASCII
ELSE
	REPORT FORM PrintStatText TO PRINTER NOCONSOLE
ENDIF
SELECT temprep
USE
RETURN
**************************************************************************************
* PROCEDURE: PRINTBASE
* Abstract: Print base first look docuemnt
* Called by: procedure Add88txn
* Calls: procedure basedoc
**************************************************************************************
PROCEDURE Printbase
PARAMETERS d_deliv, d_Return, n_Numdays, c_typeday, d_sendlook, c_bates, lcLogo

STORE .F. TO l_civil, l_asbestos, l_ibm
STORE "" TO c_lookfirm, c_lookname, c_lookadd1, c_lookadd2, c_lookadd3
LOCAL c_TflAtty,ogen
c_TflAtty=NVL(pc_TflAtty,'')

*--collect infor for the request
DO CASE
CASE pc_litcode = "C  "                      && Civil Litigation
	l_civil = .T.
CASE pc_litcode = "A  "                      && Asbestos litigation
	l_asbestos = .T.
CASE pc_litcode = "J  "                      && IBM-San Jose litigation
	l_ibm = .T.
OTHERWISE
ENDCASE
IF EMPTY(ALLTRIM(c_typeday))
	c_DayType = ""
ELSE
	c_DayType = IIF(c_typeday=="B","business" ,"calendar")
ENDIF

DO getattny WITH c_lookfirm, c_lookname, c_lookadd1, c_lookadd2, c_lookadd3
** 02/17/16 removed B & B
DO CASE
CASE l_asbestos AND pl_ofcOak
	lcWarning="DO NOT FORWARD THESE RECORDS TO  SPANOS | PRZETAK"+CHR(13)+;
		"OR TO ANY FACILITY OTHER THAN RECORDTRAK AT THIS ADDRESS."
CASE pl_ofcOak AND NOT l_civil
	lcWarning="DO NOT FORWARD THESE RECORDS TO ANY PARTY OF RECORD OR TO ANY"+CHR(13)+;
		"FACILITY OTHER THAN RECORDTRAK AT 127 SECOND STREET, OAKLAND, CA 94607."
OTHERWISE
	lcWarning="DO NOT FORWARD THESE RECORDS TO ANY FACILITY OTHER THAN RECORDTRAK."
ENDCASE

lcAddress=""
DO lfPrtAddr IN printCov
DO CASE
CASE pc_rqatcod="BEBE  3C"
	c_bates=""
	DO tiff_filemaker WITH ;
		'printbasedoctxt2.frx',(ADDBS(pc_softdir)+"F00000001")
	DO tiff_filemaker WITH ;
		'printBaseDoctxt2.frx',(ADDBS(pc_softdir)+"F00000002")
	REPORT FORM printBaseDoc TO PRINTER NOCONSOLE

CASE pc_platcod='GIBR  4C' OR ALLTRIM(UPPER(pc_litcode))=="A"
	c_bates=''
	DO tiff_filemaker WITH ;
		'printbasedoctxt2.frx',(ADDBS(pc_softdir)+"F00000001")
	DO tiff_filemaker WITH ;
		'printBaseDoctxt2.frx',(ADDBS(pc_softdir)+"F00000002")

	REPORT FORM printBaseDoc TO PRINTER NOCONSOLE

CASE ALLTRIM(UPPER(pc_litcode))=="Z"
	STORE "" TO c_reqFirm, c_reqName, c_reqAdd1, c_reqAdd2, c_reqAdd3
	c_reqatty=pc_rqatcod
	c_bates="000001"
	lcWarning="DO NOT FORWARD THESE RECORDS TO ANY FACILITY OTHER THAN RECORDTRAK."
	DO lookAttyInfo IN printCov WITH c_reqatty, c_reqFirm, c_reqName, c_reqAdd1, c_reqAdd2, c_reqAdd3
	IF NOT NVL(pl_Softimg,.F.)
		REPORT FORM printSilicaFL.frx TO PRINTER NOCONSOLE
		c_bates="000002"
		REPORT FORM printSilicaFLpage2.frx TO PRINTER NOCONSOLE
	ELSE
		c_bates=""
		DO tiff_filemaker WITH ;
			'printSilicaFLtif.frx',(ADDBS(pc_softdir)+"F00000001")
		DO tiff_filemaker WITH ;
			'printSilicaFLpage2.frx',(ADDBS(pc_softdir)+"F00000002")
	ENDIF
CASE NVL(pl_Softimg,.F.)
	c_bates=''
	IF pl_ofcOak
	REPORT FORM printbasedoctxt3.frx  TO FILE (ADDBS(pc_softdir)+"2_3FLINST") ASCII NOCONSOLE
	ELSE 
	REPORT FORM kopflook.frx  TO FILE (ADDBS(pc_softdir)+"2_3FLINST") ASCII NOCONSOLE
	ENDIF 
*!*		DO tiff_filemaker WITH ;
*!*			'printbasedoctxt2.frx',(ADDBS(pc_softdir)+"F00000001")
OTHERWISE
	IF pl_ofcOak
	REPORT FORM printBaseDoc TO PRINTER NOCONSOLE
	ELSE 
	REPORT FORM kopflook.frx TO PRINTER NOCONSOLE
	ENDIF 
ENDCASE

pc_TflAtty=c_TflAtty

*!*	IF NVL(pl_Softimg,.F.)
*!*	    _ASCIIROWS=58
*!*		REPORT FORM printBaseDoc TO FILE (pc_softdir + "2_2flbse.txt") ASCII
*!*	ELSE
*!*	   REPORT FORM printBaseDoc TO PRINTER NOCONSOLE
*!*	ENDIF

RETURN

**************************************************************************************
* PROCEDURE: GETATTNY
* Abstract:
* Called by:
* Calls:
**************************************************************************************
PROCEDURE getattny
PARAMETERS c_lookfirm, c_lookname, c_lookadd1, c_lookadd2, c_lookadd3
LOCAL n_CurArea, lcSQLLine
n_CurArea = SELECT()

oGenflpr=CREATEOBJECT("medgeneric")

IF EMPTY(NVL(pc_TflAtty,""))
	lcSQLLine="exec dbo.GetFirmBillCode '"+ALLTRIM(pc_clcode)+"'"
	oGenflpr.sqlexecute(lcSQLLine,"viewFirmBillCode")
	SELECT viewFirmBillCode
	IF RECCOUNT()>0
		loSelForm=CREATEOBJECT("transactions.frmSelFirmBillCode")
		loSelForm.SHOW
		lcSearch=loSelForm.SELECTION
		loSelForm.RELEASE
	ENDIF
	SELECT viewFirmBillCode
	USE
ELSE
	lcSearch=pc_TflAtty
ENDIF
pc_TflAtty=lcSearch
STORE "" TO c_lookfirm, c_lookname, c_lookadd1, c_lookadd2, c_lookadd3
DO lookAttyInfo IN printCov WITH lcSearch, c_lookfirm, c_lookname, c_lookadd1, c_lookadd2, c_lookadd3
lcZipLoc=RAT(" ",c_lookadd3)
c_lookadd3=SUBSTR(c_lookadd3,1,lcZipLoc)+SUBSTR(c_lookadd3,lcZipLoc,6)+;
	IIF(!EMPTY(ALLTRIM(SUBSTR(c_lookadd3,lcZipLoc+6,4))),"-","")+;
	SUBSTR(c_lookadd3,lcZipLoc+6,4)
RELEASE oGenflpr

SELECT (n_CurArea)
RETURN
**************************************************************************************
* PROCEDURE: BIMPAT1
* Abstract: Breast impl attachment 1
* Called by: procedure Add88txn
* Calls:
**************************************************************************************
PROCEDURE Bimpat1

IF NVL(pl_Softimg,.F.)
	_ASCIIROWS=58
	REPORT FORM printBImpAt1 TO FILE (pc_softdir + "2_2flbm1.txt") ASCII
ELSE
	REPORT FORM printBImpAt1 TO PRINTER NOCONSOLE
ENDIF


RETURN

**************************************************************************************
* PROCEDURE: BIMPAT2
* Abstract: Breast impl review attorny form
* Called by: procedure Add88txn
* Calls:
**************************************************************************************
PROCEDURE Bimpat2
STORE "" TO c_lookfirm, c_lookname, c_lookadd1, c_lookadd2, c_lookadd3

DO getattny WITH c_lookfirm, c_lookname, c_lookadd1, c_lookadd2, c_lookadd3

IF NVL(pl_Softimg,.F.)
	_ASCIIROWS=58
	REPORT FORM printBImpAt2 TO FILE(pc_softdir + "2_3flbm2.txt") ASCII
ELSE
	REPORT FORM printBImpAt2 TO PRINTER NOCONSOLE
ENDIF

RETURN

**************************************************************************************
* PROCEDURE: DGTFSTLOOK
* Abstract: DIGITAL FISTLOOK
* Called by: procedure Add88txn
* Calls:
**************************************************************************************
PROCEDURE dgtflook
STORE "" TO c_lookfirm, c_lookname, c_lookadd1, c_lookadd2, c_lookadd3

DO getattny WITH c_lookfirm, c_lookname, c_lookadd1, c_lookadd2, c_lookadd3

IF NVL(pl_Softimg,.F.)
	_ASCIIROWS=58
	REPORT FORM dgtflook TO FILE(pc_softdir + "2_3fldgt.txt") ASCII
ELSE
	REPORT FORM dgtflook TO PRINTER NOCONSOLE
ENDIF

RETURN

**************************************************************************************
* PROCEDURE: FLTITLPG
* Abstract: Print the 1st look package title page
* Called by:
* Calls: lfCoverHdr in printcov.prg, gfuse_ro.prg, gfunuse.prg
**************************************************************************************
PROCEDURE Fltitlpg
PARAMETER n_Status
LOCAL n_CurArea, lloGen
n_CurArea = SELECT()

*--08/25/21 kdl: fltitpg is not blocked for new FL documents [247599]
IF checkprint2(pc_litcode,pc_area) = .f.
*--IF checkprint(pc_litcode,pc_area) = .f.
	return
ENDIF

PRIVATE lcCover, lcCov2, lcCov1;
	lcClaim, lcFileNo, lcReqAtty, lcAdjClaim;
	lcPltName, lcPltFirm, lcPltAdd1, lcPltAdd2, lcPltCity;
	lcPltAtty, lcPltPhone, lcAddress;
	lbClaimRq;

STORE "" TO lcCover, lcCov2, lcCov1
STORE "" TO lcClaim, lcFileNo, lcReqAtty, lcAdjClaim
STORE "" TO lcPltName, lcPltFirm, lcPltAdd1, lcPltAdd2, lcPltCity
STORE "" TO lcPltAtty, lcPltPhone, lcAddress
STORE .F. TO lbClaimRq

IF TYPE("oTrans")!="O"
	oTrans=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

lcCover = ALLTRIM(pc_Descrpt)
lcDOBInfo="D.O.B.: "+DTOC(oTrans.checkdate(pd_pldob))+IIF( NOT EMPTY(oTrans.checkdate(pd_pldod)), "  D.O.D.: " + DTOC(oTrans.checkdate(pd_pldod)), "")
lcPltAtty = gfAtName( pc_platcod)
 
IF PRINTSTATUS()
*--suppress SC cover letter data/fields for billing plan 'HF'[64629,63871]
*--not the use a new private variable in the called reporot
	SET CLASSLIB TO dataconnection ADDITIVE
	osqlconn = CREATEOBJECT('cntdataconn')
	
	PRIVATE lSuppress1
	lSuppress1 = .F.
	c_Sql = "select [dbo].[check4BillPlan]('&pc_clcode.', 'HF')"
	osqlconn.sqlpassthrough(c_sql,'curChkit')
	IF USED('curChkit')
		lSuppress1=NVL(curChkit.exp,.F.)
		USE IN curChkit
	endif

	IF n_Status = 1                     && first-look review package
		DO lfCoverHdr IN printCov WITH lcCover, "FR"
		IF NVL(pl_Softimg,.F.)
			_ASCIIROWS=58
			REPORT FORM printFirstLookCover TO FILE (pc_softdir + "2_1flttl.txt") ASCII
		ELSE
			REPORT FORM printFirstLookCover TO PRINTER NOCONSOLE
		ENDIF
	ELSE     							&& production package
		DO lfCoverHdr IN printCov WITH lcCover, "FF"
		_ASCIIROWS=58
		REPORT FORM printFirstLookCover TO FILE ("c:\temp\cover.txt") ASCII
	ENDIF
ELSE
	gfmessage("Printer not available. Please correct the problem and try again." )
ENDIF

IF lloGen=.T.
	RELEASE ogen
ENDIF
SELECT (n_CurArea)
RETURN

**************************************************************************************
PROCEDURE lookDept
LOCAL lcSQLLine, lloGen, lnCurArea, retval
lnCurArea=SELECT()
retval=""
IF TYPE("oGen")!="O"
	ogen=CREATEOBJECT("medgeneric")
	lloGen=.T.
ENDIF

lcSQLLine="select dbo.GetSpecInsDept('"+ALLTRIM(pc_clcode)+"', '"+ALLTRIM(STR(pn_Tag))+"')"
ogen.sqlexecute(lcSQLLine,"viewSpecInsDept")
SELECT viewSpecInsDept
IF RECCOUNT()>0
	retval = ALLT( viewSpecInsDept.EXP)
ENDIF
USE
IF lloGen=.T.
	RELEASE ogen
ENDIF
SELECT (lnCurArea)
RETURN retval
**********************************************************************************
* PROCEDURE ADD88TXN
* Abstract: add the 1st look 88 transaction to the case's entry table
**********************************************************************************
PROCEDURE Add88txn
PARAMETERS l_Has88, d_deliv, n_Numdays, c_typeday, l_Isauto
*--check and set value for automated  88 transaction
IF PARAMETERS() < 5
	l_Isauto = .F.
ENDIF

LOCAL c_CurOrd, n_CurArea,  ;
	l_used, mv, lType, lcType, mdate, lnTxnId, l_Sendmail, l_fllit, ;
	l_ScrInput, l_scanlook, lcSQLLine, lloGen

l_Sendmail=.T.

IF USED('master')
	pl_GotCase=.F.
	DO gfgetcas
ENDIF

IF TYPE("oTrans")!="O"
	oTrans=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

n_CurArea = SELECT()
*--d_today = DATE()
c_Flatcode = pc_TflAtty
c_Ship = pc_Flship
d_Return = {  /  /    }                         && return date variable for review records
l_ScrInput = NVL(pl_AcctMgr,.F.)

*--08/25/21 kdl: added pl_Oak_FL_Type - flag to identify Oakland fist-look login path [247599]
IF NOT NVL(pl_Oak_FL_Type,.F.) = .T. 
*--IF NOT (NVL(pl_ofcOak,.F.) OR NVL(pl_ofcPas,.F.))
** Automatic re-open is required -- case should not have been closed
** unless all records had previously reached final disposition.
	IF NOT EMPTY(convrtDate(pd_closing))
		WAIT WINDOW "NOTE: Case is being automatically re-opened." NOWAIT NOCLEAR
		DO gfReOpen WITH .T., "processing first-look item(s) for tag " + ;
			ALLT( STR( pn_Tag)) + "."
		WAIT CLEAR
	ENDIF
*--get the delivery date info
	n_Accept = 1
	IF NOT l_Isauto
		lChgshp = .t.
		lcSQLLine="Exec [dbo].[getchgflshiptype] '"+ALLTRIM(fixquote(pc_litcode))+"'"
		oTrans.sqlexecute(lcSQLLine,"chkFlLit")
		SELECT chkFlLit
		IF RECCOUNT()>0
			lChgshp = chkFlLit.bChgshp 
		ENDIF
		IF USED("chkFlLit")
			USE IN chkFlLit
		ENDIF
		oFrmFlCov=CREATEOBJECT("frmFlCov1",c_Flatcode,d_Return,n_Numdays,c_typeday,d_deliv,c_Ship,lChgshp)

		oFrmFlCov.SHOW
		n_Accept=oFrmFlCov.nAccept
		c_Flatcode=oFrmFlCov.c_Flatcode
		d_Return=oFrmFlCov.txtD_return.VALUE
		n_Numdays=oFrmFlCov.n_Numdays
		c_typeday=oFrmFlCov.c_typeday
		c_Ship=oFrmFlCov.c_Ship
		oFrmFlCov.RELEASE
	ELSE
		IF c_typeday = 'C'
*--calendar days
			d_Return = gfChkDat( d_deliv + n_Numdays, .F., .F.)
		ELSE
*--business days
			d_Return = gfDtskip( d_deliv, n_Numdays)
		ENDIF
	ENDIF

	IF n_Accept <> 1
		SELECT (n_CurArea)
		RETURN
	ENDIF

*--if delivery is email (web), then user must pick email
*--address and send job to disttodo
	IF c_Ship="E"
*--   IF pc_Flship = "E"
		IF EMPTY(c_Flatcode)
			gfmessage("No first-look attorney found so distribution server job not posted.")
			RETURN 		
		ENDIF 
		c_ImageDb = ""
		lcSQLLine="select flimagedb from tblFlLit where code='"+ALLTRIM(fixquote(pc_litcode))+"' and office='"+ALLTRIM(fixquote(pc_offcode))+"'"
		oTrans.sqlexecute(lcSQLLine,"viewFlLit")
		SELECT viewFlLit
		IF RECCOUNT()>0
			c_ImageDb = ALLTRIM(viewFlLit.flimagedb)   && 1st look image database
		ENDIF
		USE
		c_ImageDb = IIF( EMPTY(NVL(c_ImageDb,"")), "LOOK", c_ImageDb)
		lcSQLLine="select scan_table from tblScanLook where cl_code='"+ALLTRIM(pc_clcode)+"' and tag='"+ALLTRIM(STR(pn_Tag))+"'"
		oTrans.sqlexecute(lcSQLLine,"ScanLook")
		IF RECCOUNT()>0
			c_ImageDb = ALLTRIM(scanlook.scan_table)
		ELSE
			c_ImageDb = "WEJ1"
		ENDIF
*--make 1st look jobs priority 2
		n_dsid=gfdsjobid()
		lcSQLLine="exec dbo.dsjob '"+ALLTRIM(STR(pn_lrsno))+"', '"+ALLTRIM(STR(pn_Tag))+"', '"+;
			ALLTRIM(fixquote(c_Flatcode))+"', 'KF', '"+IIF(l_Sendmail=.T.,"1","0")+"', '"+;
			ALLTRIM(c_ImageDb)+"', 1, 0, '', '', '', 0"+", '"+ALLTRIM(STR(2))+"'"+",'&n_dsid.'"
		oTrans.sqlexecute(lcSQLLine)
	ENDIF
*-- look Request id
	lc_RequestID=oTrans.getRequestId(pc_clcode, pn_Tag)

*--update record flattny code if it has changed
	IF c_Flatcode <> pc_TflAtty AND ;
			oTrans.bringMessage("Change first-look attorney for this tag?",1)=.T.
		lcSQLLine="update tblRequest set fl_Atty='"+ALLTRIM(c_Flatcode)+;
			"' where id_tblRequest='"+ALLTRIM(lc_RequestID)+"'"
		pc_TflAtty = c_Flatcode
	ENDIF

	lc_timeSheetID=oTrans.addtxnrec("I",d_Today, ;
		"First Look:Deliver " + DTOC(d_deliv) + ",Due back " + DTOC(d_Return), ;
		pc_clcode, 88, pn_Tag, pc_MailID, 0, 0, n_Numdays, ;
		"","",0,0, "FIRSTLOOK2","",goApp.CurrentUser.ntlogin,lc_RequestID,"")

	lcSQLLine="update tblTimeSheet set [type]='"+ALLTRIM(c_typeday)+"', "+;
		"rcv_date='"+ALLTRIM(DTOC(d_deliv))+"', due_Date='"+ALLTRIM(DTOC(d_Return))+"', "+;
		"rq_at_code='"+ALLTRIM(fixquote(c_Flatcode))+"' "+",rec_code='&c_Ship.' "
	IF NVL(pl_ofcOak,.F.) OR NVL(pl_ofcPas,.F.)
		lcSQLLine=lcSQLLine+", RCA_No='"+ALLTRIM(pc_BBNuRCA)+"', ASB_Round='"+ALLTRIM(pc_BBRound)+"' "
	ENDIF
	lcSQLLine=lcSQLLine+" where id_tblTimeSheet='"+ALLTRIM(lc_timeSheetID)+"'"
	oTrans.sqlexecute(lcSQLLine)

	lcSQLLine="update tblRequest set DATEDLV_88='"+ALLTRIM(DTOC(d_deliv))+"', "+;
		"DATEDUE_88='"+ALLTRIM(DTOC(d_Return))+"'"+;
		" where id_tblRequestS='"+ALLTRIM(lc_RequestID)+"'"
	oTrans.sqlexecute(lcSQLLine)

	DO flprint WITH d_deliv, d_Return, n_Numdays, c_typeday
ENDIF

SELECT (n_CurArea)

********************************************************************
PROCEDURE lpnothing
RETURN
