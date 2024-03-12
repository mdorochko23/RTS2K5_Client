PROCEDURE PrintCov
* Prints cover letter and related documents for a single deponent's records
PARAMETER l_UseNew, l_PrintAll, l_Print1st, l_Softcopycall
*   Calling parameters:
*        l_UseNew   -- .T. for new-style (category-based) cover letters
*                      .F. for old-style (admission-based) cover letters
*                              and for Berry & Berry single-category letters
*        l_PrintAll -- .T. for printing of all documents
*                      .F. for printing only cover letter (when
*                          called by PrtCovP)
*        l_Print1st -- .T. if first-look documents are required
*                      .F. if no first-look documents are required

*  Called from screens Covlet, BBCovLet, and NewCover
*     (when "Print Cover Letter" button is pressed),
*     and from module CovLet during auto-processing.
*  Called from PrtCovP program to do quick-printing of only the cover page
*     for a specific case and tag.
*   Internal routine lfCoverHdr is called from Fltitlpg procedure in Flprint.prg
*     to generate cover pages for first-look record-review shipments
*   Internal routines lfPrnOrder and lfPrnBar are called from FLProc.prg
*
*   gfGetCas and gfGetDep must have been called in advance.
*     Area A must have tamaster open and positioned to the plaintiff
*     Area F must have correct entryN table open for the plaintiff

*  Internal Routine lfPrnBar also called directly by Orders program.
*    (In this situation, gfGetCas will be called.)

*  Calls AtShare, BillCovr, gfInvNam, Print41, NoticeTX,
*     gfGetCas, gfAtName, gfUse, gfUseRO, gfLookup, gfUnUse, gfMsg, gfAtType,
*     gfChkDat, flprint.prg
*  Uses Report form AmRevSht
*
* History :
* Date      Name  Comment
**03/23/10  - do not print a bar code for CREDIT HOLD attys
**09/18/07 - added Claim Number to a Record Order Summary Sheet page
*-- 1/29/13 - Soft copy system order summary and bar codes now longer printed. Now sent out of SC system via email
* ---------------------------------------------------------------------------

IF TYPE("l_Print1st") = "U"
	l_Print1st = .F.                             && do not print 1st-look documents
ENDIF
IF PCOUNT()>4
	l_Softcopycall = .F.
ENDIF

DECLARE _fpreset IN MSVCRT

PUBLIC c_lookFirm, c_lookName, c_lookAdd1, c_lookAdd2, c_lookAdd3
PRIVATE l_makesoftcopy,l_printerdefaultset, l_deptbill,l_incoming,l_Sccall
l_deptbill=.F.
l_Sccall = l_Softcopycall

STORE "" TO c_recvcats, c_nrscats, c_inccats, c_recvcats1
STORE 0 TO n_recvcats, n_nrscats, n_inccats,n_recvcats1
STORE .F. TO l_recvblnk, l_nrsblnk, l_incblnk, llnetwork, l_makesoftcopy, l_printerdefaultset

lnCurArea=SELECT()

IF TYPE("oGen")!="O"
	oGen=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

PUBLIC ARRAY arAtty[1]
arAtty = ""
l_pacsrecd = .F.

l_incoming = .F.

=ASTACKINFO(a_Stack)
FOR n_cnt = 1 TO ALEN(a_Stack,1)
	IF UPPER("frmrecorddisposition.PRINT_COV") $ UPPER(a_Stack[n_cnt,3])
		l_incoming = .T.
		EXIT
	ENDIF
ENDFOR
*!*	FOR n_cnt = 1 TO 32
*!*	   IF "INCOMING" $ UPPER(PROGRAM( n_cnt))
*!*	      l_incoming = .T.
*!*	      EXIT
*!*	   ENDIF
*!*	ENDFOR

IF NOT pl_autosc
	l_makesoftcopy=IIF(pl_Softimg AND NVL(pc_Status,'R')='N' AND ;
		(NVL(pl_HasNRS,.F.) AND (INLIST(UPPER(NVL(pc_NRSType,'A')),'B','C','D','F') OR (UPPER(NVL(pc_NRSType,'A'))='E' AND NOT NVL(pl_autosc,.F.)))),;
		.T.,.F.)
ELSE
	l_makesoftcopy=.F.
ENDIF
pl_softflg=.F.

IF NVL(pl_Softimg,.F.) AND NOT NVL(pl_autosc,.F.) AND NOT l_makesoftcopy
	IF oGen.bringmessage('Are the records contained in soft-image files?',1)=.F.
		pl_Softimg = .F.
	ELSE
		lcSQLLine="update tblRequest set is_softimg=1 where cl_code='"+;
			ALLTRIM(pc_clcode)+"' and tag='"+ALLTRIM(STR(pn_tag))+"' AND active=1"
		oCdcnt.sqlpassthrough(lcSQLLine)
		pl_softflg = .T.
		DO lfupRimg										&& internal to printcov
	ENDIF
ENDIF

pl_Softimg=IIF(NVL(pl_autosc,.F.),.T.,pl_Softimg)

IF NVL(pl_Softimg,.F.)
	lcSQLLine="update tblRequest set is_softimg=1 where cl_code='"+;
		ALLTRIM(pc_clcode)+"' and tag='"+ALLTRIM(STR(pn_tag))+"' AND active=1"
	oCdcnt.sqlpassthrough(lcSQLLine)
	pl_softflg = .T.
ENDIF

loForm=CREATEOBJECT("transactions.frmPStatus")
loForm.SHOW

*  If one or more attorneys has Handling = "R" in Orders file,
*  generate special-handling sheet so physical record goes directly
*  to the client representative for additional processing.
*  (Typically used when Philly att'y wants first-look review.)
IF l_PrintAll
	loForm.Label3.CAPTION="Checking review status"
	n_revcount = 0
	lcSQLLine="select dbo.fn_GetOrderCnt('"+pc_clcode+"', '"+ALLTRIM(STR(pn_tag))+"', 'R')"
	oCdcnt.sqlpassthrough(lcSQLLine,"viewOrder")
	SELECT viewOrder
	IF RECCOUNT()>0
		n_revcount=viewOrder.EXP
	ENDIF
** #1 Account Mgr Review Page
	IF n_revcount > 0
		oGen.bringmessage("This record must be reviewed by the Client Representative.",2)
*--11/18/19: block all printing of Acct Mgr Revieww sheet [149919]
*!*			loForm.Label3.CAPTION="Client Rep. review sheet"
*!*			REPORT FORM AmRevSht TO PRINTER NOCONSOLE
	ENDIF
	SELECT viewOrder
	USE
ENDIF

* first look documents
* add status check to prevent page printing when NRS.
* change first-look page order
IF (l_Print1st AND pc_Status = "F")
	DO lfFlAlert  							&& internal to printcov
ENDIF

*  Perform all general printing tasks that occur when a record
*  arrives or a cover letter is being re-printed.
DO lfDoPrint 								&& internal to printcov

loForm.RELEASE
IF lloGen=.T.
	RELEASE oGen
ENDIF
SELECT (lnCurArea)

RETURN

* --------------------------------------------------------------------------
*  Master Print Routine -- handles all calls to subroutines for most
*    individual forms
*  Prints Cover Letter, order summary, bar code, and NRS
* --------------------------------------------------------------------------
PROCEDURE lfDoPrint
LOCAL ldOrder, lDecline, llFound, lnCopy, llFedEx, lcSQLLine, lloGen, lnCurArea, lloForm,l_HasNRS,lc_Tflatty

IF NVL(pl_CAVer,.F.)
	LOCAL lcCAPlt
ENDIF

STORE {01/01/1990} TO ldOrder, ldDecline, ldCancel
STORE 0 TO lnCopy, lnTotal
STORE .F. TO llFound, llFedEx
l_HasNRS=pl_HasNRS

lnCurArea=SELECT()

IF TYPE("oGen")!="O"
	oGen=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

IF TYPE("loForm")!="O"
	loForm=CREATEOBJECT("transactions.frmPStatus")
	loForm.SHOW
	lloForm=.T.
ENDIF


IF PRINTSTATUS()
*  If new category data will be needed for either cover letter or
*  NRS letter, gather and prepare it in advance

	IF NVL(l_UseNew,.F.) OR NVL(pl_HasNRS,.F.)
		DO lfCatInfo								&& internal to printcov
	ENDIF
*  Print the Cover Letter for King of Prussia/Maryland/Pittsburgh cases
*     (one copy/case)
	IF l_PrintAll
*
*  Print Order Summary Sheets for each ordering attorney
*     (skipped when Berry & Berry is requesting attorney)
*
** #1 Page in document set
* prvent printing of
* order summary sheet if first look review package

*-- 1/29/13 block printing of order summary from soft copy system: system now sends order summary via email
		IF NOT (NVL(pl_Frstlook,.F.) AND pc_Status = "F") AND NOT pl_suppressprint AND NOT l_Sccall
			loForm.Label3.CAPTION="Order summary sheets"
&& order summary sheet
			DO lfPrnOrder                             && internal to printcov
		ENDIF
	ENDIF
*
*  Produce the Standard Cover Letter for Texas/California
*  and Scanning Bar Code sheet for Texas only (one copy/case)
*
*  print cover letter for Oakland if in Test Mode
	IF NVL(pl_OfcHous,.F.) OR NVL(pl_OfcPas,.F.) OR (NVL(pl_OfcOak,.F.) AND NVL(pl_CvrTest,.F.))
		IF l_PrintAll AND NVL(pl_OfcHous,.F.)
			loForm.Label3.CAPTION="Scanning bar code sheet"
			DO lfBarCode							&& internal to printcov
		ENDIF

		loForm.Label3.CAPTION="Cover letter"
&&EF  remove that page per Liz D. requests ( meeting about moving Pasdaena ofice work on 4/23/08)
** DO lfPrnCover								&& internal to printcov
	ENDIF

	IF l_PrintAll
*
*  Page #2 - Print Attorney Bar Code sheets for Philadelphia and Pittsburgh cases
*

		IF NVL(pl_ofcPgh,.F.) OR NVL(pl_ofcKoP,.F.) OR NVL(pl_ofcMD,.F.) OR  NVL(pl_OfcOak,.F.)
*call first look bar code print procedure if
*the ship method is CD (C) or hard copy (H)
			IF NVL(pl_Frstlook,.F.) AND pc_Status = "F"
				IF INLIST(pc_Flship, "C", "H")
					loForm.Label3.CAPTION="First-look attorney bar code sheet"
&& internal to printcov
					*--save original fl atcode because it is sometimes altered in the barcode prointing process
					lc_Tflatty = pc_Tflatty
					DO lfPrintBarCodes WITH ;
						pc_Tflatty,  ALLTRIM(pc_Tflatty), pc_Tflatty, ;
						PADL(ALLTRIM(STR(pn_lrsno)),8,"0")+"."+PADL(ALLTRIM(STR(pn_tag)),3,"0") , ;
						LEFT( pc_plfname, 1) + ". "+pc_pllname, " (FL) "
					pc_Tflatty = lc_Tflatty
				ENDIF
			ELSE
*-- 1/29/13 block printing of bar code sheets: system now sends via email
				IF NOT l_Sccall
					loForm.Label3.CAPTION="Attorney bar code sheets"
&& Attorney Bar Code sheet
					DO lfPrnBar                         && internal to printcov
				ENDIF

			ENDIF
		ENDIF
** Page #3
		IF  NVL(pl_ofcKoP,.F.) OR NVL(pl_ofcMD,.F.) OR NVL(pl_ofcPgh,.F.)
			loForm.Label3.CAPTION="Scanning bar code sheet"
*soft  images - suppress bar code sheet if soft images
			IF NOT NVL(pl_softflg,.F.)
&& print bar code sheet
				DO lfBarCode                       && internal to printcov
			ENDIF
		ENDIF
	ENDIF                                        &&Print all
*suppress all documents from here on if soft image reprint
	IF NVL(pl_softflg,.F.) AND NOT NVL(pl_Softimg,.F.)
		RETURN
	ENDIF

**Page # 4

*soft images - set temp file storage directory
	IF NVL(pl_Softimg,.F.)
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
	ENDIF

	IF (l_Print1st AND pc_Status = "F")
		loForm.Label3.CAPTION="First-look documents"

*--08/25/21 kdl: added pl_Oak_FL_Type - flag to identify Oakland fist-look login path [247599]		
		IF NVL(pl_Oak_FL_Type ,.F.)=.T.
		*--IF NVL(pl_OfcOak,.F.)
			n_Tag=pn_tag
			n_lrsno=pn_lrsno
			DO OakFlook IN Flproc WITH n_lrsno,n_Tag
		ELSE
			DO fldocprt IN FLPRINT				&& external to printcov
		ENDIF
	ENDIF

	IF  NVL(pl_ofcKoP,.F.) OR NVL(pl_ofcMD,.F.) OR NVL(pl_ofcPgh,.F.)
*soft images - set printer to temp files at beginning of each
*of the following programs

*!*	      IF (l_Print1st AND pc_Status = "F")
*!*	         loForm.Label3.Caption="First-look documents"
*!*	       	DO fldocprt IN FLPRINT				&& external to printcov
*!*	      ENDIF

		loForm.Label3.CAPTION="Cover letter"
		IF NVL(pl_Softimg,.F.)
			DO lfPrnCover	WITH (pc_softdir + "4_covrpg")	&& internal to printcov
		ELSE
			DO lfPrnCover
		ENDIF
	ENDIF

	IF ALLTRIM(UPPER(pc_litcode))=='EFF'
		SELECT 0
		c_sql="exec dbo.getrequestbylrsno &pc_lrsno.,&pc_tag"
		oCdcnt.sqlpassthrough(c_sql,'curQR')
		IF RECCOUNT('curQR')> 0
			IF "(QR)" $ curQR.createdby
				IF NVL(pl_Softimg,.F.)
					IF NOT FILE(pc_softdir + "3q_covrpg.tif")
						COPY FILE("\\sanstor\image\release\documents\PPR_insert_page.tif") TO (pc_softdir + "5_covrpg.tif")
					ENDIF
				ELSE
					SET CLASSLIB TO depdisposition ADDIT
					o_tif=CREATEOBJECT("DEPDISPOSITION.frmtiffprinter","\\sanstor\image\release\documents\PPR_insert_page.tif")
					RELEASE o_tif
				ENDIF
			ENDIF
		ENDIF
	ENDIF

**Page #5
	IF INLIST( pc_litcode, "D  ", "E  ", "F  ", "G  ", "Q  ") ;
			OR ( pc_litcode == "A  " AND pc_area = "DistOfColumbia") OR NVL(pl_IRGFl,.F.)
		loForm.Label3.CAPTION="Location summary sheet"
		DO LocSumm WITH pn_lrsno 		&& external to printcov
	ENDIF

*  For California offices, generate a CA-style Billing Cover Letter
*      for each ordering attorney.
*  (If Berry & Berry is requesting attorney, use gfAtType and atShare
*   functions to only include unbilled attorneys currently on shares list.)
*
	IF l_PrintAll
		IF NVL(pl_OfcOak,.F.) OR NVL(pl_OfcPas,.F.)
			IF EMPTY(arAtty[1])
				IF pc_rqatcod == "BEBE  3C"
					**10/01/18 SL #109598
					*lcSQLLine="select * from tblBill with (nolock,INDEX(ix_tblBills_2)) where cl_code='"+
					lcSQLLine="select * from tblBill with (nolock) where cl_code='"+;
						ALLTRIM(pc_clcode)+"' and active=1"
					oCdcnt.sqlpassthrough(lcSQLLine,"viewTaBills")
					SELECT viewTaBills
					SCAN FOR EMPTY(NVL(invoice_no,0))
&& internal to printcov
						llFound = lfOrdStatus( at_code, ;
							@ldOrder, @ldDecline, @lnCopy, @llFedEx, @ldCancel)
						IF EMPTY(oGen.checkDate(ldOrder)) AND ;
								(!EMPTY(oGen.checkDate(ldDecline)) OR ;
								!EMPTY(oGen.checkDate(ldCancel))) && Declined
							LOOP
						ENDIF
						lcCAPlt = gfAtType(at_code)		&& external to printcov
						IF at_code <> pc_rqatcod
							IF NVL(pl_BBAsb,.F.)
								IF lcCAPlt <> "P"
									IF NOT AtShare( at_code, pc_BBRound, pc_plBBAsb, pc_BBDock) && internal to printcov
										LOOP
									ENDIF
								ENDIF
							ENDIF
						ENDIF
&& internal to printcov
						IF NOT lfOrdStatus( at_code, ;
								@ldOrder, @ldDecline, @lnCopy, @llFedEx, @ldCancel)
							LOOP
						ENDIF
						IF EMPTY(oGen.checkDate(ldOrder)) OR ;
								NOT EMPTY(oGen.checkDate(ldDecline)) OR ;
								INLIST(viewTaBills.Response, "F", "C")
							LOOP
						ENDIF
						IF NOT EMPTY(arAtty[1])
							DIMENSION arAtty[ALEN(aratty)+1]
						ENDIF
						arAtty[ALEN(aratty)]=at_code
					ENDSCAN
					SELECT viewTaBills
					USE
				ELSE
					
					*--3/9/18: ignore at_codes with no shipment type set. Needed to print billing cover sheet. [80877]					
					lcSQLLine="select * from tblBill with (nolock) "+;
						" where cl_code= '" +ALLTRIM(pc_clcode) + "' and active=1 "+; 
						" and [dbo].[getattyshiptypecnt] ('" +ALLTRIM(pc_clcode) + "'," + ALLTRIM(STR(pn_tag)) + ", tblbill.at_code) > 0 "+;
						" order by at_Code"
					
*!*						lcSQLLine="select * from tblBill with (nolock,INDEX(ix_tblBills_2)) where cl_code='"+;
*!*							ALLTRIM(pc_clcode)+"' and active=1 order by cl_code, at_code"

					oCdcnt.sqlpassthrough(lcSQLLine,"viewTaBills")
					SELECT viewTaBills
					IF RECCOUNT()>0
&& internal to printcov
						IF lfOrdStatus( at_code, ;
								@ldOrder, @ldDecline, @lnCopy, @llFedEx, @ldCancel)
							IF NOT EMPTY(arAtty[1])
								DIMENSION arAtty[ALEN(aratty)+1]
							ENDIF
							arAtty[ALEN(aratty)]=at_code
						ENDIF
					ENDIF
					SELECT viewTaBills
					USE
				ENDIF
			ENDIF
			IF NOT EMPTY(arAtty[1])
				loForm.Label3.CAPTION="CA Billing cover letter"
				DO BillCovr WITH pc_clcode, pn_tag    && external to printcov
			ELSE
				GFMESSAGE("No ordering attorney(s) with shipment types found for tag. Billing cover letter will not be generated.")
				*--GFMESSAGE("No ordering attorney(s) for tag. Billing cover letter will not be generated.")
			ENDIF
		ENDIF
	ENDIF

*
*   Reprint a copy of the notice if this is a Texas case.
*
	IF NVL(pl_OfcHous,.F.)
		loForm.Label3.CAPTION="Reprint of notice"
		DO NoticeTX								&& external to printcov
	ENDIF
*
*   Scanning bar code page for Phila/MD/Pittsburgh
*

	IF (NVL(pl_ofcKoP,.F.) OR NVL(pl_ofcMD,.F.) OR NVL(pl_ofcPgh,.F.)) ;
			AND NOT ALLTRIM(pc_litcode)=='RLA'
**page #6
*		IF NOT ALLTRIM(pc_litcode)=='AV1'
*// 8/24 DEACTIVATE OPTION TO ADD REQUEST COVER PAVE IF AUTO SOFT COPY
		IF NOT pl_autosc AND NOT pl_addcasetag AND oGen.bringmessage( "Do you want to re-print a Request Cover Letter?", 1)=.T.
			loForm.Label3.CAPTION="Reprint of Request Cover Letter"
			DO Reprqcov WITH pn_lrsno, pn_tag, .T.		&& external to printcov
		ENDIF
*!*			ELSE
*!*				IF GFMESSAGE( "Do you want to insert a copy of the Request Cover Letter?", .T.)
*!*					LOCAL o_req
*!*					o_req=CREATEOBJECT("depdisposition.frmaddrequestpg")
*!*					o_req.addpage
*!*					RELEASE o_req
*!*				ENDIF
*!*			ENDIF
	ENDIF

ELSE
	oGen.bringmessage( "Printer is not ready. Please fix it and try again.",2)
ENDIF
**06/11/03 #page 7
IF NVL(l_HasNRS,.F.)
	loForm.Label3.CAPTION="No record statement"
	DO Print41 WITH l_UseNew, c_nrscats				&& external to printcov
ENDIF

*!*	IF NVL(pl_Softimg,.F.) AND NOT NVL(pl_autosc,.F.) AND NOT l_makesoftcopy
*!*		c_String = pc_lrsno + " "+ pc_Tag
*!*		lsOriginalErrorHandler = ON("ERROR")
*!*		IF NVL(pl_OfcOak,.F.)
*!*			RUN /N C:\rtsimges.EXE &c_String
*!*		ELSE
*!*			RUN /N C:\vfp\rtsimges.EXE &c_String
*!*		ENDIF
*!*	*--RUN /N C:\vfp\rtsimges.EXE &c_String
*!*		ON ERROR &lsOriginalErrorHandler
*!*	ENDIF

*--make soft copy job for nrs-c images

IF l_makesoftcopy
	o_tif=CREATEOBJECT("frmsoftimages",pn_lrsno,pn_tag,goApp.CurrentUser.ntlogin)
	o_tif.imageprocess
	oGen.bringmessage( "Verbal NRS sent to Soft Copy image processor.",2)
ENDIF

pl_Softimg = .F.

IF lloGen=.T.
	RELEASE oGen
ENDIF
IF lloForm=.T.
	RELEASE loForm
ENDIF
SELECT (lnCurArea)
RETURN

* --------------------------------------------------------------------------
* Print Cover Letter
* --------------------------------------------------------------------------
PROCEDURE lfPrnCover
PARAMETERS outputfile
LOCAL lcTmp,lnall, c_admit, c_recv, lcSQLLine, lloGen, lnCurArea, lloForm,crptform
STORE "" TO lcCover, lcCov2, lcCov1, lcFooter
STORE "" TO lcClaim, lcFileNo, lcReqAtty, lcAdjClaim
STORE "" TO lcPltName, lcPltFirm, lcPltAdd1, lcPltAdd2, lcPltCity
STORE "" TO lcPltAtty, lcPltPhone, lcAddress
STORE .F. TO lbClaimRq
lcFirstLook="NF"
IF INLIST(TYPE("outputfile"),"U","L")
	outputfile=""
ENDIF

lnCurArea=SELECT()
IF TYPE("oGen")!="O"
	oGen=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

IF TYPE("loForm")!="O"
	loForm=CREATEOBJECT("transactions.frmPStatus")
	loForm.SHOW
	lloForm=.T.
ENDIF

*IIF(used('curprovider'),'MED PROVIDER:       ' + IIF(( ALLTRIM(NVL(curprovider.char_fld,''))='Med Provider Id' AND NOT NVL(curprovider.num_fld,0)=0),alltrim(str(curprovider.num_fld)),''),'')


cfindate='  /  /    '
crptform="printcover"

IF ALLTRIM(UPPER(pc_litcode))=='AVA' AND ALLTRIM(UPPER(pc_area))=='PLAINTIFF'
	SELECT 0
	c_sql="exec dbo.getrequestbylrsno &pc_lrsno.,&pc_tag"
	oCdcnt.sqlpassthrough(c_sql,'curprovider')
ENDIF

IF ALLTRIM(UPPER(pc_litcode))=='AV1'
	SELECT 0
	c_sql="exec dbo.getrequestbylrsno &pc_lrsno.,&pc_tag"
	oCdcnt.sqlpassthrough(c_sql,'curfindate')
	cfindate=IIF(ISNULL(curfindate.fin_date),'  /  /    ',DTOC(curfindate.fin_date))
ENDIF

SELECT 0
CREATE CURSOR temprep (textline C(80), textline2 C(80),groupcode C(1))

lcAddress=""
DO lfPrtAddr
lcDOBInfo="D.O.B.: "+DTOC(oGen.checkDate(pd_pldob))+;
	IIF( NOT EMPTY(oGen.checkDate(pd_pldod)), "  D.O.D.: " + ;
	DTOC(oGen.checkDate(pd_pldod)), "")
loForm.Label3.CAPTION="Cover letter" +CHR(13)+;
	"Attorney Information"
lcPltAtty=gfAtName(pc_platcod)						&& external
lcCover = lfCovLetDescript()						&& internal to printcov
loForm.Label3.CAPTION="Cover letter" +CHR(13)+;
	"Header Information"
DO lfCoverHdr WITH lcCover, lcFirstLook				&& internal to printcov

loForm.Label3.CAPTION="Cover letter" +CHR(13)+;
	"Special Instructions"

IF l_UseNew AND NOT ALLTRIM(UPPER(pc_litcode))=='AV1'
	DO addSpecIns WITH pc_clcode, pn_tag				&& internal to printcov
ENDIF
*
IF pc_rqatcod = "BEBE  3C"
	loForm.Label3.CAPTION="Cover letter" +CHR(13)+;
		"Bery Style"
	DO addBeryAdm
ELSE
	IF l_UseNew
		DO addNewStyle
		loForm.Label3.CAPTION="Cover letter" +CHR(13)+;
			"New Style"
	ELSE
		DO addOldStyle
		loForm.Label3.CAPTION="Cover letter" +CHR(13)+;
			"Old Style"
	ENDIF
ENDIF

*--suppress SC cover letter data/fields for billing plan 'HF'[63871]
*--not the use a new private variable in the called reporot
PRIVATE lSuppress1
lSuppress1 = .F.
c_Sql = "select [dbo].[check4BillPlan]('&pc_clcode.', 'HF')"
oCdcnt.sqlpassthrough(c_sql,'curChkit')
IF USED('curChkit')
	lSuppress1=NVL(curChkit.exp,.F.)
	USE IN curChkit
endif

SELECT temprep
IF RECCOUNT()=0
	APPEND BLANK
ENDIF
GO TOP
IF !EMPTY(ALLTRIM(outputfile))
*	_ASCIIROWS=58
*	REPORT FORM PRINTCOVERtxt TO FILE(outputfile) ASCII

	IF FILE(outputfile+".tif")
		ERASE (outputfile+".tif")
	ENDIF
*--1/11/17: new process for SC cover letters #51372

*--5/31/22 kdl: add resolution parameter [271273]
	DO tiff_covletter WITH ;
		(crptform + 'txt.frx'), (outputfile), 300
*!*		DO tiff_covletter WITH ;
*!*			(crptform + 'txt.frx'), (outputfile)

*!*		DO tiff_filemaker WITH ;
*!*			(crptform + 'txt.frx'), (outputfile)

ELSE
	REPORT FORM (crptform) TO PRINTER NOCONSOLE
ENDIF
SELECT temprep
USE

IF USED('curfindate')
	USE IN curfindate
ENDIF

IF USED('curprovider')
	USE IN curprovider
ENDIF

IF lloGen=.T.
	RELEASE oGen
ENDIF
IF lloForm=.T.
	RELEASE loForm
ENDIF
SELECT (lnCurArea)
RETURN

* --------------------------------------------------------------------------
* Print cover letter header
* --------------------------------------------------------------------------
PROCEDURE lfCoverHdr
* NOTE This routine is called directly by routine FlTitlPg (within Procedure
* File FLPrint.prg), in addition to its use from within PrintCov
PARAMETER lcCover, c_firstlk
IF INLIST (TYPE('c_firstlk'), "U", "L")
	c_firstlk = "NF"
ENDIF

LOCAL lcAlias, ld2days, lloGen
STORE .F. TO lbRightDef
ln_indent=12
lcAlias = ALIAS()

IF TYPE("oGen")!="O"
	oGen=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

&& Ed Trainor requests to print
&& a claim number only for cases as below
lbClaimRq = ( pc_rqatcod = "A19927P")

*---- For Civil Litigation (Regular Records) cases
*---- and for Texas-office cases
* --- Print plaintiff counsel and requesting paralegal ---
IF pc_litcode == "C  " OR NVL(pl_OfcHous,.F.)
	lcReqAtty=lfPrintReqAtty()	&& internal to printcov

* --- Print Adjuster name and Claim number for civil lit only ---

	lcAdjClaim=lfPrintAdjClaim()	&& internal to printcov
*----
ENDIF
* --- Print Deponent description ---

&& print a long deponent name on two lines
DO lfChkDescript WITH ALLTRIM(lcCover), 1	&& internal to printcov

* Special processing for State Diet Drug Cases

IF (pc_litcode == "G  " AND NOT EMPTY(NVL(pc_rqatcod,""))) OR lbClaimRq
	lfPrintDrugClaim(lbClaimRq) && internal to printcov
ENDIF

#IF 0
	IF LEN(lcTmp) < 63
		lcTmp = PADR(lcTmp, 63)
	ELSE
		lcTmp = LEFT(lcTmp, 62) + " "
	ENDIF
	lcTmp = lcTmp + "Attn:" + ALLTRIM( pc_reqpara)
#ENDIF

IF INLIST( pc_litcode, "D  ", "E  ") AND NOT EMPTY(NVL(pc_platcod,""))
	lfPrintPlatInfo()		&& internal to printcov
ENDIF

IF ! EMPTY(lcAlias)
	SELECT (lcAlias)
ENDIF
RETURN

* --------------------------------------------------------------------------
* Print Record Processing Sheet
* --------------------------------------------------------------------------
PROCEDURE lfPrnRecSh
PRIVATE lcTmp, lnFee, lnPages

SELECT TaMaster
=lfLF(1)

??? pc_f14b
? PADL("Record Processing Sheet", 76)
??? pc_f12

=lfLF(2)

? PADR("CASE NAME: " + pc_plnam, 61) + "DATE: " + c_today AT n_indent

? "COURT & DOCKET: " + ALLTRIM( pc_court1) + " / " + ALLTRIM( pc_docket) AT n_indent

? PADR("Litigation: " + ALLT( pc_litname) + ;
	" [" + SUBS( pc_ofcdesc, 1, 4) + "]", 42) ;
	+ PADL(" Area: " + ALLTRIM( pc_area),26) AT n_indent

? pc_f12 + REPLICATE("_", 68) AT n_indent
??? pc_f12b
? " RT #     Tag     Deponent " AT n_indent
? PADC( pc_lrsno, 9) + " " + STR(pn_tag, 3) + ;
	"     " + ALLTRIM( CovLet.DESCRIPT) AT n_indent
??? pc_f12

? " "
* --- print buyers" info ---
? pc_f12 + REPLICATE("_", 68) AT n_indent
? pc_f12b + "PURCHASING ATTY'S         ATTENTION TO" + pc_f12 AT n_indent

SELECT TABills
SET ORDER TO
SET RELATION TO at_code INTO TAATTY
SCAN FOR cl_code = pc_clcode AND EMPTY(NVL(invoice_no,0)) AND ;
		NOT INLIST( Response, " ", "F", "O")
	IF EMPTY(NVL(at_code,""))
		GFMESSAGE("Invalid attorney code.")
		LOOP
	ENDIF

	? PADR( ALLTRIM( TAATTY.name_first) + " " + ALLTRIM( TAATTY.name_last), 25) ;
		+ " " + ALLTRIM( TAATTY.name_inv) AT n_indent

ENDSCAN
SET RELATION TO
=lfLine()

? " "
? " "
??? pc_f14b
? "                  Number of Copies: _______" AT 0
??? pc_f12
? " "
? "Number of Invoice:      ______                    UPS: ______" AT n_indent
? " "
? "Bind One Copy as Orig:  ______             Pittsburgh: ______" AT n_indent
? " "
? "Do Not Bind One Copy:   ______               CAT Fund: ______" AT n_indent
? " "
? "Do Not Bind Two Copies: ______           REG. Records: ______" AT n_indent
? " "
? "Bind Original as Copy:  ______                  Other: ______" AT n_indent
? " "
? " "
? "Scan (Y/N):             ______" AT n_indent

=lfEject() && internal to printcov
RETURN

* --------------------------------------------------------------------------
* Get order status
* --------------------------------------------------------------------------
FUNCTION lfOrdStatus
PARAMETER lcAtty, ldOrder, ldDecline, lnCopy, llFedEx, ldCancel, lcbillcat, ;
	lcshiptype, l_jobs

LOCAL llFound, lcAlias, c_Ordtypes, lcSQLLine, lloGen
lcAlias = ALIAS()
IF INLIST(TYPE("lcBillcat"), "L", "U")
	lcbillcat = ""
ENDIF
IF INLIST(TYPE("lcshiptype"), "L", "U")
	lcshiptype = ""
ENDIF

IF INLIST(TYPE("l_jobs"), "C", "U")
	l_jobs = .F.
ENDIF

IF TYPE("oGen")!="O"
	oGen=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

**10/01/18 SL #109598
*lcSQLLine="select * from tblOrder with (nolock,INDEX(ix_tblOrder_1)) where cl_code='"+
lcSQLLine="select * from tblOrder with (nolock) where cl_code='"+;
	ALLTRIM(pc_clcode)+"' and tag='"+ALLTRIM(STR(pn_tag))+"' and at_code='"+ALLTRIM(fixquote(lcAtty))+"' and active=1"
oCdcnt.sqlpassthrough(lcSQLLine,"viewOrder")
SELECT viewOrder
IF RECCOUNT()>0
	llFound = .T.
	ldOrder = viewOrder.date_order
	ldDecline = viewOrder.date_decln
	ldCancel = viewOrder.date_cancl
	llFedEx = viewOrder.fedex
	lcbillcat = viewOrder.billcat
	lnCopy = viewOrder.numCopy
	c_Ordtypes = IIF( viewOrder.numCopy > 0 AND ;
		INLIST(viewOrder.shiptype, " ", "P"), "P", "")

	lcSQLLine="Exec dbo.call_dsordertype '"+pc_clcode+"', "+ALLTRIM(STR(pn_tag))+","+ ;
		"'"+fixquote(lcAtty)+"', '"+""+"', '"+viewOrder.shiptype+"', '"+IIF(l_jobs=.T.,"1","0")+"', "+;
		"'"+viewOrder.id_tblOrders+"', '"+goApp.CurrentUser.ntlogin+"', '&c_Ordtypes.',2"
	oCdcnt.sqlpassthrough(lcSQLLine,"viewShipTypes")
	SELECT viewShipTypes
	IF RECCOUNT()>0
		c_Ordtypes=viewShipTypes.ordtypes
	ENDIF
	SELECT viewShipTypes
	USE
	lcshiptype = IIF( EMPTY(c_Ordtypes), "P", c_Ordtypes)
ELSE
	llFound = .F.
ENDIF
SELECT viewOrder
USE
IF lloGen=.T.
	RELEASE oGen
ENDIF

SELECT (lcAlias)

RETURN llFound

* --------------------------------------------------------------------------
* Get TOTAL pages and witness fee for this deponent
* --------------------------------------------------------------------------
PROCEDURE lfFeePages
PARAMETER lnFee, lnPages
LOCAL lcSQLLine, lnCurArea, lloGen
lnCurArea=SELECT()
lnFee = 0.0
lnPages = 0
IF TYPE("oGen")!="O"
	oGen=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

lcSQLLine="exec dbo.GetFeePages '"+ALLTRIM(pc_clcode)+"', '"+ALLTRIM(STR(pn_tag))+"'"
oCdcnt.sqlpassthrough(lcSQLLine,"viewTimeSheet")
SELECT viewTimeSheet
IF RECCOUNT()>0
	lnFee=NVL(viewTimeSheet.WitFee,0.00)
	lnPages=NVL(viewTimeSheet.PAGES,0)
ENDIF
USE
IF lloGen=.T.
	RELEASE oGen
ENDIF
SELECT(lnCurArea)
RETURN
* --------------------------------------------------------------------------
* Return plaintiff attorney name
* --------------------------------------------------------------------------
FUNCTION lfPltAtty
PRIVATE lcName

lcName = gfAtName( pc_platcod)	&& external to printcov
RETURN lcName

********************************************************************************
PROCEDURE lfPrnBar
*  Called within PrintCov
*  Called from Orders.Prg
PARAMETER c_clcode, n_Tag, c_atcode
LOCAL lcTmp, lnFee, lnPages, ldOrder, lDecline, llFound, lnCopy, llFedEx, ;
	lcAlias, llUsed, lcOrder, lnRecNo, l_sendCD, lcshiptype, l_sendmail, ;
	n_Curarea, lcbillcat, l_DSjob, c_Userid, l_SendDs, n_Alen, n_shpcnt, ;
	l_fordsjob, lloGen, lnCurArea,n_dsid,lbarcode, n_onhold

lbarcode=.T.

IF TYPE('l_Sccall') = 'U'
	l_Sccall = .F.
ENDIF

lnCurArea=SELECT()
*set default value for incoming variable to true
IF TYPE("l_incoming") = "U"
	PRIVATE l_incoming
	l_incoming = .T.
ENDIF

IF TYPE("c_atcode") = "U" OR PARAMETERS() < 3
* Occurs when called within Printcov
* and all global data has been collected
	c_atcode = ""
	c_clcode = pc_clcode
	n_Tag = pn_tag
ENDIF

IF TYPE("oGen")!="O"
	oGen=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

IF PARAMETERS() = 3
* When called from Orders.prg, fill in globals for use
* by internal routines
	pn_tag = n_Tag
	lfSetGlobals(c_clcode)
ENDIF
ldOrder = {1/1/1990}
ldDecline = {1/1/1990}
ldCancel = {1/1/1990}
llFound = .F.
lnCopy = 0
llFedEx = .F.
l_sendCD = .F.
lcbillcat = ""
lcshiptype = "P"

DIMENSION a_types[5]
a_types[1] = "P"
a_types[2] = "D"
a_types[3] = "V"
a_types[4] = "C"
a_types[5] = "F"
n_Alen = ALEN(a_types, 1)

**10/01/18 SL #109598
*oCdcnt.sqlpassthrough ("SELECT * FROM tblbill WITH (nolock,INDEX (ix_tblbills_2)) WHERE active =1 and cl_code='&c_clcode.'", 'tabills')
oCdcnt.sqlpassthrough ("SELECT * FROM tblbill WITH (nolock) WHERE active =1 and cl_code='&c_clcode.'", 'tabills')
SELECT TABills

SCAN
	IF NOT EMPTY(NVL(c_atcode,""))
		IF TABills.at_code <> c_atcode
			LOOP
		ENDIF
	ENDIF
	l_sendCD = lfSendCds( TABills.at_code)		&& internal to printcov
	IF l_sendCD
		LOOP
	ENDIF

	IF NVL(pl_Frstlook,.F.) AND ;
			ALLTRIM(UPPER(TABills.at_code)) == ALLTRIM(UPPER(pc_Tflatty)) AND ;
			INLIST(ALLTRIM(UPPER(pc_Status)), "F", "R", "I", "N")
*		lbarcode=.F.
*		LOOP
	ENDIF

	IF NVL(pl_Frstlook,.F.) AND pc_Status = "N" AND pc_Flship = "E" AND NVL(pl_Flnrs,.F.) AND ;
			ALLTRIM(UPPER(TABills.at_code)) == ALLTRIM(UPPER(pc_Tflatty))
		LOOP
	ENDIF
	l_fordsjob = .T.
&& internal to printcov
	llFound = lfOrdStatus( at_code, @ldOrder, ;
		@ldDecline, @lnCopy, @llFedEx, @ldCancel, @lcbillcat, @lcshiptype, l_fordsjob)

	IF NOT llFound
		LOOP
	ENDIF

	IF EMPTY(oGen.checkDate(ldOrder)) OR NOT EMPTY(oGen.checkDate(ldDecline)) ;
			OR NOT EMPTY(oGen.checkDate(ldCancel)) && Not Ordered
		LOOP
	ENDIF

* 05/20/2009 MD Commented/Added to fixed post problem
*!*		IF lnCopy = 0 AND NOT INLIST( ALLTRIM(UPPER(lcshiptype)), "D", "V", "C", "F", "W")
*!*			LOOP
*!*		ENDIF

	IF lnCopy = 0
		llFindShip=.F.
		FOR lnShipCntr=1 TO LEN(ALLTRIM(lcshiptype))
			IF INLIST( UPPER(SUBSTR(ALLTRIM(lcshiptype),lnShipCntr,1)), "D", "V", "C", "F", "W")
				llFindShip=.T.
			ENDIF
		NEXT
		IF llFindShip=.F.
			LOOP
		ENDIF
	ENDIF
*************
**3/23/2010-CREDIT HOLD -EXCLUDE
	n_onhold=0

	n_onhold=ifOnHOLD(TABills.at_code)
	IF n_onhold=1
		LOOP
	ENDIF
**3/23/2010-CREDIT HOLD -EXCLUDE


*--remove DS job creation as part of order bar sheet printing [63871]
*!*		DIMENSION a_types[6]
*!*		a_types[1] = "P"
*!*		a_types[2] = "D"
*!*		a_types[3] = "V"
*!*		a_types[4] = "C"
*!*		a_types[5] = "F"
*!*		a_types[6] = "W"

*!*		n_Alen = ALEN(a_types, 1)
*!*	*opcgen=CREATEOBJECT('medgeneric')
*!*		FOR n_shpcnt = 1 TO n_Alen
*!*			IF a_types[n_shpcnt] $ lcshiptype
*!*				IF INLIST( a_types[n_shpcnt], "D", "V", "C", "F", "W")
*!*	&& external to printcov
*!*					IF gfsendds( TABills.at_code) && AND l_incoming
*!*	&& exnternal to printcov
*!*						n_dsid=gfdsjobid()
*!*						c_sql= "EXEC dbo.dspost '&pc_clcode.',"+STR(pn_tag)+","+;
*!*							oCdcnt.cleanstring(TABills.at_code)+",'"+fixquote(pc_area)+"',0,'"+;
*!*							a_types[n_shpcnt]+"','',6,1,NULL,'&n_dsid.'"
*!*						oCdcnt.sqlpassthrough(c_sql,'disttodo')
*!*						l_posted=.F.
*!*						FOR n_chkjob = 1 TO 10
*!*							lcSQLLine="SELECT * from tblDistToDo with (nolock) WHERE active =1 and lrs_no='"+ALLTRIM(STR(pn_lrsno))+;
*!*								"' and tag="+ALLTRIM(STR(pn_tag))+" and at_code='"+ALLTRIM(fixquote(TABills.at_code))+"'"
*!*							oCdcnt.sqlpassthrough(lcSQLLine,"viewDistToDo")
*!*							SELECT viewDistToDo
*!*							IF RECCOUNT()>0
*!*								l_posted=.T.
*!*								EXIT
*!*							ELSE
*!*	&& external to printcov
*!*								n_dsid=gfdsjobid()
*!*								c_sql= "EXEC dbo.dspost '&pc_clcode.',"+STR(pn_tag)+","+;
*!*									oCdcnt.cleanstring(TABills.at_code)+",'"+fixquote(pc_area)+;
*!*									"',0,'"+a_types[n_shpcnt]+"','',6,1,NULL,'&n_dsid.'"
*!*								oCdcnt.sqlpassthrough(c_sql,'disttodo')

*!*							ENDIF
*!*							SELECT viewDistToDo
*!*							USE
*!*						ENDFOR
*!*						IF NOT l_posted
*!*							oGen.bringmessage("Error posting record " + ALLTRIM(STR(pn_lrsno)) + "." + ALLTRIM(STR(pn_tag)) + " to Distribution Server. Contact IT department.",2)
*!*	&& internal to printcov
*!*							DO lfEmail WITH pn_lrsno, pn_tag, "", TABills.at_code
*!*						ENDIF
*!*					ENDIF
*!*					LOOP
*!*				ENDIF
*!*	*-- 1/29/2013 Soft copy system bar codes now sent via email
*!*				IF a_types[n_shpcnt] = "P" AND lbarcode AND NOT l_Sccall
*!*					DO lfPrintBarCodes WITH ;
*!*						TABills.at_code, ALLTRIM(TABills.at_code), TABills.at_code, ;
*!*						PADL(ALLTRIM(STR(pn_lrsno)),8,"0")+"."+PADL(ALLTRIM(STR(pn_tag)),3,"0") , ;
*!*						LEFT( pc_plfname, 1) + ". " + pc_pllname, " ("+TABills.CODE + ") "
*!*				ENDIF
*!*			ENDIF
*!*		ENDFOR

*--end of #63871
	RELEASE opcgen
ENDSCAN


RELEASE a_types
IF lloGen=.T.
	RELEASE oGen
ENDIF
SELECT (lnCurArea)
RETURN
******************************************************************************
* --------------------------------------------------------------------------
* Print ICU Review Sheet
* --------------------------------------------------------------------------
PROCEDURE lpPrintR2
*  DMA  07/19/01  Unused as of this date per C Broach request
LOCAL lnCurArea, lloGen
lCurArea=SELECT()
IF TYPE("oGen")!="O"
	oGen=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

IF ! PRINTSTATUS()
	oGen.bringmessage("Printer is not ready.  Fix it and try again.",2)
ELSE

	??? pc_f18b

	=lfLF(2)

	? PADL("Review This Record For", 60)

	=lfLF(1)

	? PADL("Additional Deponents Until " + DTOC( pd_revstop), 60)

	=lfLF(2)

	??? pc_f12
	? pc_plnam AT n_indent

	DO PrntBar2 WITH pc_clcode, pn_tag           && print bar code for Lrs/Tag

	??? pc_f14b

	=lfLF(10)

	? "RT #: " + ALLT( TRANSFORM( pn_lrsno, "99999999")) +;
		"       Tag: " + TRANSFORM( pn_tag, "999") AT 22

	=lfLF(5)

	? "Reviewed By____________________________" AT 22

	=lfLF(4)

	? "Number of New Deponents________________" AT 22

	=lfLF(4)

	? "Check By Billing________________________" AT 22
	??? pc_f12

	=lfEject()
	DO lfPrintOff
ENDIF
IF lloGen=.T.
	RELEASE oGen
ENDIF
SELECT (lnCurArea)
RETURN
********************************************
PROCEDURE lfParsePrt
PARAMETER c_String
PRIVATE c_printme, n_break, n_width
LOCAL lsplit
n_width = SET("MEMOWIDTH") - 1
DO WHILE NOT EMPTY( c_String)
	IF LEN( c_String) > n_width
		lsplit=.F.
		FOR n_break = n_width TO 1 STEP -1
			IF SUBS( c_String, n_break, 1) == " "
				INSERT INTO temprep (textline) VALUES(SUBS( c_String, 1, n_break-1))
				c_String = SUBS( c_String, n_break + 1)
				lsplit=.T.
				EXIT
			ENDIF
		ENDFOR
		IF NOT lsplit
			INSERT INTO temprep (textline) VALUES(SUBS( c_String, 1, n_width))
			c_String = SUBS( c_String, n_width + 1)
		ENDIF

	ELSE
		INSERT INTO temprep (textline) VALUES(c_String)
		c_String = ""
	ENDIF
ENDDO
RETURN
***************************************
PROCEDURE lfCatInfo
LOCAL lcSQLLine, lnCurArea, lloGen, iCat, rCat, nCat
lnCurArea=SELECT()
IF TYPE("oGen")!="O"
	oGen=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

lcSQLLine="exec dbo.GetCatInfo '"+pc_clcode+"', '"+ALLTRIM(STR(pn_tag))+"'"
oCdcnt.sqlpassthrough(lcSQLLine,"viewCatInfo")
lcSQLLine="exec dbo.CountAdmissnCodes '"+pc_clcode+"', '"+ALLTRIM(STR(pn_tag))+"'"
oCdcnt.sqlpassthrough(lcSQLLine,"viewCodeCounts")
SELECT viewCatInfo
IF RECCOUNT()>0
	c_inccats=viewCatInfo.i_category
	c_recvcats=viewCatInfo.r_category
	c_nrscats=viewCatInfo.n_category
	l_incblnk=viewCatInfo.i_blank
	l_recvblnk=viewCatInfo.r_blank
	l_nrsblnk=viewCatInfo.n_blank

	IF ","$ALLTRIM(c_inccats) AND l_incblnk=.F.
		c_inccats=SUBSTR(c_inccats,1,RAT(",", c_inccats,1))+" AND "+ALLTRIM(SUBSTR(c_inccats,RAT(",", c_inccats,1)+1,LEN(c_inccats)))
		c_inccats=SUBSTR(c_inccats,1,RAT(",", c_inccats,1)-1)+SUBSTR(c_inccats,RAT(",", c_inccats,1)+1,LEN(c_inccats))
	ENDIF
	IF ","$ALLTRIM(c_recvcats) AND l_recvblnk=.F.
		c_recvcats=SUBSTR(c_recvcats,1,RAT(",", c_recvcats,1))+" AND "+ALLTRIM(SUBSTR(c_recvcats,RAT(",", c_recvcats,1)+1,LEN(c_recvcats)))
		c_recvcats=SUBSTR(c_recvcats,1,RAT(",", c_recvcats,1)-1)+SUBSTR(c_recvcats,RAT(",", c_recvcats,1)+1,LEN(c_recvcats))
	ENDIF
	IF ","$ALLTRIM(c_nrscats) AND l_nrsblnk=.F.
		c_nrscats=SUBSTR(c_nrscats,1,RAT(",", c_nrscats,1))+" AND "+ALLTRIM(SUBSTR(c_nrscats,RAT(",", c_nrscats,1)+1,LEN(c_nrscats)))
		c_nrscats=SUBSTR(c_nrscats,1,RAT(",", c_nrscats,1)-1)+SUBSTR(c_nrscats,RAT(",", c_nrscats,1)+1,LEN(c_nrscats))
	ENDIF
	IF "(PACS)"$ALLTRIM(UPPER(c_recvcats))
		l_pacsrecd=.T.
	ENDIF
ENDIF
USE
SELECT viewCodeCounts

IF RECCOUNT()>0
	n_inccats=viewCodeCounts.i_counts
	n_recvcats=viewCodeCounts.r_counts
	n_nrscats=viewCodeCounts.n_counts
ENDIF
USE
IF lloGen=.T.
	RELEASE oGen
ENDIF
SELECT (lnCurArea)
RETURN

*****************************************************************
** EF 07/05/2002
** Divide a long deponent name into two lines
*****************************************************************
PROCEDURE lfChkDescript
PARAMETERS lcDescript, nPageOrder
PRIVATE lnall, lncnt

lnall = LEN( lcDescript)
IF lnall > 42

	lncnt = RAT(" ", lcDescript, IIF( nPageOrder=1, 2, 1))
	lcCov1 = LEFT( lcDescript, lncnt)
	lcCov2 = RIGHT( lcDescript, lnall-lncnt)
ELSE
	lcCov1 = lcDescript
ENDIF
RETURN

****************************************************************
FUNCTION lfSendCds
PARAMETERS c_atty
LOCAL lSendCD, lnCurArea, lcSQLLine, lloGen
lnCurArea=SELECT()
lSendCD=.F.
IF TYPE("oGen")!="O"
	oGen=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

*lcSQLLine="select SendCds from tblCovrCtrl with (nolock) where at_code='"+ALLTRIM(fixquote(c_atty))+"' and active=1"
lcSQLLine=""
lcSQLLine="exec  [dbo].[GetAtCovrCtrlRecord] '" +ALLTRIM(fixquote(c_atty))+"'"
oCdcnt.sqlpassthrough(lcSQLLine,"viewCovrCtrl")
SELECT viewCovrCtrl
IF RECCOUNT()>0
	lSendCD = viewCovrCtrl.SendCds
ENDIF
USE
IF lloGen=.T.
	RELEASE oGen
ENDIF
SELECT (lnCurArea)
RETURN  lSendCD
****************************************************************
PROCEDURE lfPrtAddr
** Prints office address on billing cover letter
LOCAL lnCurArea, lcSQLLine, lloGen, lcLrs,oGen
lcLrs=""
lnCurArea=SELECT()

oGen=CREATEOBJECT('cntdataconn')
*oGen=CREATEOBJECT("transactions.medrequest")

DO CASE
CASE TYPE("pn_lrsno")="N"
	lcLrs=ALLTRIM(STR(pn_lrsno))
CASE TYPE("pn_lrsno")="C"
	lcLrs=ALLTRIM(pn_lrsno)
OTHERWISE
	GFMESSAGE("Corrupted RT#")
	RETURN
ENDCASE
lcSQLLine="select lrs_nocode from tblMaster with (nolock) where lrs_no='"+lcLrs+"' and active=1"
oGen.sqlpassthrough(lcSQLLine,"viewMaster")
*oGen.sqlexecute(lcSQLLine,"viewMaster")
SELECT viewMaster
DO CASE
CASE ALLTRIM(viewMaster.lrs_nocode) = "T"

	lcAddress="2600 Southwest Freeway, Suite 1001"+CHR(13)+;
		"Houston, TX  77098"+CHR(13)+;
		"Phone #: (713) 655-1800"+CHR(13)+;
		"Fax #:   (713) 655-9109"

CASE ALLTRIM(viewMaster.lrs_nocode)= "S"
**11/19/07 - new Pasadena office address
	lcAddress="711 E. Walnut St, Suite 201"+CHR(13)+;
		"Pasadena, CA  91101"+CHR(13)+;
		"Phone #: (626) 685-2878"+CHR(13)+;
		"Fax #:   (626) 685-2877"

CASE ALLTRIM(viewMaster.lrs_nocode)= "C"

	lcAddress="130 Webster Street, Suite 100"+CHR(13)+;
		"Oakland, CA  94607"+CHR(13)+;
		"Phone #: (510) 465-3200"+CHR(13)+;
		"Fax #:   (510) 465-3652"

OTHERWISE
&&07/20/17  CA ADDRESS ON A KOP CASES  FOR AZ SUBPS
IF (pl_CAinKOP AND PC_ISSTYPE="S")
		lcAddress="130 Webster Street, Suite 100"+CHR(13)+;
		"Oakland, CA  94607"+CHR(13)+;
		"Phone #: (510) 465-3200"+CHR(13)+;
		"Fax #:   (510) 465-3652"
ELSE

	lcAddress="651 Allendale Rd."+CHR(13)+;
		"PO Box 61591" +CHR(13)+;
		"King of Prussia, PA  19406"+CHR(13)+;
		"Phone #: (610) 992-5000"+CHR(13)+;
		"Fax #:   (610) 354-8946"
ENDIF

ENDCASE

lcAddress=lcAddress+CHR(13)+"www.recordtrak.com"

SELECT viewMaster
USE
RELEASE oGen

SELECT(lnCurArea)
RETURN
**************************************************************************************
* Procedure: LFUPRIMG
*
* Abstract: Updates user's copy of RTSIMAGES.EXE
* Called by: local procedures flpost, flreleas
**************************************************************************************
PROCEDURE lfupRimg
PRIVATE n_TxtTiff, d_TxtTiff
*--first check for the txttiff.exe
n_TxtTiff = ADIR(a_txtTiff, "T:\TXTTIFF\RTSIMGES.EXE")
IF n_TxtTiff > 0 AND FILE("C:\VFP\RTSIMGES.EXE")
	d_TxtTiff = a_txtTiff[1, 3]
	n_TxtTiff = ADIR(a_txtTiff, "C:\VFP\RTSIMGES.EXE")
	IF n_TxtTiff > 0
		IF d_TxtTiff > a_txtTiff[1, 3]
			COPY FILE T:\txttiff\rtsimges.EXE TO C:\vfp\rtsimges.EXE
		ENDIF
	ENDIF
ENDIF

***************************************************************************
*-- Procedure: lpEmail
*-- Abstract: send email notification if no email address found for attorney
***************************************************************************
PROCEDURE lfEmail
PARAMETER ln_lrsno, ln_Tag, c_email, lc_atcode
*--check if users copy of email.exe needs to be updated
PRIVATE n_Email, d_Email, c_String, c_Message, c_Sendto, c_CopyTo, ;
	c_Subject, l_Sent, n_cnt,c_emailadr,l_userctrl, lcMail
lcMail=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","EMAIL", "\")))+"email.exe"
n_Email = ADIR(a_Email, lcMail)
IF n_Email > 0 AND FILE("c:\email.exe")
	d_Email = a_Email[1, 3]
	n_Email = ADIR(a_Email, "c:\email.exe")
	IF n_Email > 0
		IF d_Email > a_Email[1, 3]
			COPY FILE &lcMail TO C:\email.EXE
		ENDIF
	ENDIF
ELSE
	COPY FILE &lcMail TO C:\email.EXE
ENDIF
*--now prepare the email data and call the VFP email app
*--get email addresss

c_emailadr="programmers@recordtrak.com"

c_Sendto    = c_emailadr
c_CopyTo    = 	"NONE"
c_FromName  = "DS Job Posting Error Notification"
c_FromEmail = "Distribution_Server@RecordTrak.com"
c_Subject   = "DS Job Posting Error Notification"
c_Message1  = "A distribution Server job was not posted for tag " + ALLTRIM(STR(ln_lrsno)) + "." + PADL(ALLTRIM(STR(ln_Tag)), 3, "0") + ;
	" - Attorney code: " + lc_atcode
c_Message2  = ""
c_file = "c:\" + SYS(3) +".txt"
n_File = FCREATE(c_file)
IF n_File > 0
	= FPUT(n_File, " Distribution Server")
	= FPUT(n_File, c_Sendto)
	= FPUT(n_File, c_CopyTo)
	= FPUT(n_File, c_FromName)
	= FPUT(n_File, c_FromEmail)
	= FPUT(n_File, c_Subject)
	= FPUT(n_File, c_Message1)
	= FPUT(n_File, c_Message2)
	= FCLOSE(n_File)
ENDIF
*--call the VFP email generator
c_String = '"' + c_file + '"'
lsOriginalErrorHandler = ON("ERROR")
RUN /N C:\email.EXE -ct:txttiff\config.fpw &c_file
ON ERROR &lsOriginalErrorHandler
c_email=c_Sendto
RETURN
*****************************************************************************
FUNCTION lfLookCovLetDesc
LOCAL lnCurArea, lcSQLLine,retval, oGen
lnCurArea=SELECT()
retval=""

oGen=CREATEOBJECT('cntdataconn')
*oGen=CREATEOBJECT("transactions.medrequest")
lcSQLLine="select descript from tblCovLet with (nolock) where cl_code='"+ALLTRIM(pc_clcode)+"' and tag='"+ALLTRIM(STR(pn_tag))+"' and active=1"
oGen.sqlpassthrough(lcSQLLine,"viewCovLet")
*oGen.sqlexecute(lcSQLLine,"viewCovLet")
SELECT viewCovLet
IF RECCOUNT()>0
	retval=viewCovLet.DESCRIPT
ENDIF
USE
RELEASE oGen

SELECT(lnCurArea)
RETURN retval
******************************************************************************
FUNCTION lfAtShare
LPARAMETERS lcAtCode, lcRound, lcBBAsb, lcBBDock
LOCAL lcSQLLine, lnCurArea, retval, oGen
retval=.F.
lnCurArea=SELECT()

*!*	IF TYPE("oGen")!="O"
*!*		oGen=CREATEOBJECT("transactions.medrequest")
*!*		lloGen=.T.
*!*	ENDIF
oGen=CREATEOBJECT('cntdataconn')

lcSQLLine="select dbo.fn_GetAtShare('"+ALLTRIM(fixquote(lcAtCode))+"', '"+ALLTRIM(lcRound)+"', '"+ALLTRIM(lcBBAsb)+"', '"+ALLTRIM(lcBBDock)+"')"

oGen.sqlpassthrough(lcSQLLine,"viewShare")
SELECT viewShare
IF RECCOUNT()>0
	retval=viewShare.EXP
ENDIF
USE
*IF lloGen=.T.
RELEASE oGen
*ENDIF
SELECT (lnCurArea)
RETURN retval
********************************************************************************
FUNCTION lfPlanChk
LOCAL lnCurArea, lcSQLLine, retval, lloGen
lnCurArea=SELECT()
retval=.F.
IF TYPE("oGen")!="O"
	oGen=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

lcSQLLine="select dbo.Dep_PlanCheck('"+pc_clcode+"', '"+ALLTRIM(STR(pn_tag))+"')"
*lcSQLLine="select dbo.gfPlanCheck('"+pc_clcode+"', '"+ALLTRIM(STR(pn_tag))+"', 'T')"
oCdcnt.sqlpassthrough(lcSQLLine,"viewPlan")
SELECT viewPlan
IF RECCOUNT()>0
	retval=viewPlan.EXP
ENDIF
USE
IF lloGen=.T.
	RELEASE oGen
ENDIF
SELECT (lnCurArea)
RETURN retval
********************************************************************************
PROCEDURE lfCheckRules
LPARAMETERS lcAtCode
LOCAL lnCurArea, lcSQLLine, retval, lloGen
lnCurArea=SELECT()
retval=.F.
IF TYPE("oGen")!="O"
	oGen=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

*lcSQLLine="select * from tblCovrCtrl with (nolock) where at_code='"+ALLTRIM(fixquote(lcAtCode))+"' and active=1"
lcSQLLine=""
lcSQLLine="exec  [dbo].[GetAtCovrCtrlRecord] '" +ALLTRIM(fixquote(lcAtCode))+"'"
oCdcnt.sqlpassthrough(lcSQLLine,"viewAttyRulz")
SELECT viewAttyRulz
IF RECCOUNT()>0
	retval=.T.
ELSE
	USE
ENDIF
IF lloGen=.T.
	RELEASE oGen
ENDIF
SELECT (lnCurArea)
RETURN retval
***********************************************************************************
FUNCTION lfCovLetDescript
LOCAL lnCurArea, lcSQLLine, retval, lloGen
lnCurArea=SELECT()
retval=""
IF TYPE("oGen")!="O"
	oGen=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

lcSQLLine="select descript from tblCovLet with (nolock) where cl_code='"+ALLTRIM(pc_clcode)+"' and tag='"+ALLTRIM(STR(pn_tag))+"' and active=1"
oCdcnt.sqlpassthrough(lcSQLLine,"viewDescript")
SELECT viewDescript
IF RECCOUNT()>0
	retval=viewDescript.DESCRIPT
ENDIF
USE
IF EMPTY(ALLTRIM(retval))
	oGen.bringmessage("Missing record in CovLet file. Please notify IT Dept.",2)
ENDIF
IF lloGen=.T.
	RELEASE oGen
ENDIF
RETURN retval
**********************************************************************
PROCEDURE lfPrintPurchAtty
LOCAL lnCurArea, lcSQLLine, lloGen
lnCurArea=SELECT()
IF TYPE("oGen")!="O"
	oGen=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

lcSQLLine="exec dbo.getPrintNameDate '"+ALLTRIM(pc_clcode)+"'"
oCdcnt.sqlpassthrough(lcSQLLine,"viewNameDate")
SELECT viewNameDate
GO TOP
*do checkprinter
REPORT FORM PurchAtty TO PRINTER NOCONSOLE
SELECT viewNameDate
USE
IF lloGen=.T.
	RELEASE oGen
ENDIF
SELECT (lnCurArea)
RETURN

**********************************************************************
FUNCTION lfPrintReqAtty
LOCAL lcSQLLine, lnCurArea, lloGen, retval,oGen
retval=""
lnCurArea=SELECT()
STORE "" TO lcFirst, lcLast, lcInit

oGen=CREATEOBJECT('cntdataconn')
*!*		oGen=CREATEOBJECT("transactions.medrequest")
*!*		lloGen=.T.

**10/01/18 SL #109598
*lcSQLLine=" SELECT ACCIDENTDATE FROM tblbill WITH (nolock,INDEX (ix_tblbills_2)) WHERE cl_code='" + fixquote(pc_clcode) + "' AND  AT_CODE = '" +ALLTRIM(fixquote(pc_rqatcod))+"' AND ACTIVE =1"
lcSQLLine=" SELECT ACCIDENTDATE FROM tblbill WITH (nolock) WHERE cl_code='" + fixquote(pc_clcode) + "' AND  AT_CODE = '" +ALLTRIM(fixquote(pc_rqatcod))+"' AND ACTIVE =1"
oGen.sqlpassthrough(lcSQLLine,"viewAccDate")
SELECT viewAccDate
D_ACCDATE=CTOD("")

IF RECCOUNT()>0
	D_ACCDATE=IIF(EMPTY(NVL(viewAccDate.ACCIDENTDATE,'')), '', viewAccDate.ACCIDENTDATE)
ENDIF
lcSQLLine="exec dbo.getReqAttyName '"+ALLTRIM(fixquote(pc_rqatcod))+"'"
oGen.sqlpassthrough(lcSQLLine,"viewReqAttyName")
SELECT viewReqAttyName
IF TYPE('D_ACCDATE')="C"
	D_ACCDATE=CTOD("")
ENDIF
IF RECCOUNT()>0
	retval=ALLTRIM(NewLast) + ", " + ALLTRIM(NewFirst)+ " " + ;
		IIF( NOT EMPTY(NVL(NewInit,"")), ALLTRIM(NewInit) + ".", "") +  IIF(D_ACCDATE={01/01/1900},"", "   ACCIDENT DATE: " + ALLT(DTOC(D_ACCDATE)))

ENDIF
USE
RELEASE oGen
SELECT(lnCurArea)
RETURN retval
***************************************************************************
FUNCTION lfPrintAdjClaim
LOCAL lcSQLLine, lnCurArea, lloGen, retval
retval=""
lnCurArea=SELECT()
IF TYPE("oGen")!="O"
	lloGen=.T.
	oGen=CREATEOBJECT("transactions.medrequest")
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

IF pc_litcode == "C  "
	**10/01/18 SL #109598
	*lcSQLLine="select * from tblBill with (nolock,INDEX(ix_tblBills_2)) where cl_code='"+ALLTRIM(pc_clcode)+
	lcSQLLine="select * from tblBill with (nolock) where cl_code='"+ALLTRIM(pc_clcode)+;
		"' and at_code='"+fixquote(IIF( NOT EMPTY(NVL(pc_rqatcod,"")), pc_rqatcod, pc_platcod))+"' and active=1"
	oCdcnt.sqlpassthrough(lcSQLLine,"viewBills")
	SELECT viewBills
	IF RECCOUNT()>0
		retval= ALLT( NVL(viewBills.Adjuster,''))+"   CLAIM: " + ALLT(NVL(viewBills.Claim_no,"")) + "   FILE: " + ALLT(viewBills.file_no)
	ENDIF
	USE
ENDIF
IF lloGen=.T.
	RELEASE oGen
ENDIF
SELECT (lnCurArea)
RETURN retval
*****************************************************************************
FUNCTION lfPrintDrugClaim
LPARAMETERS  llClaim
LOCAL lcSQLLine, lnCurArea, lloGen
lnCurArea=SELECT()
IF TYPE("oGen")!="O"
	lloGen=.T.
	oGen=CREATEOBJECT("transactions.medrequest")
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

**10/01/18 SL #109598
*lcSQLLine="select * from tblBill with (nolock,INDEX(ix_tblBills_2)) " 
lcSQLLine="select * from tblBill with (nolock) " ;
	+ " where cl_code='"+ALLTRIM(pc_clcode)+"' and at_code='"+ALLTRIM(fixquote(pc_rqatcod))+"' and active=1"
oCdcnt.sqlpassthrough(lcSQLLine,"viewBills")
SELECT viewBills
IF RECCOUNT()>0
	IF llClaim
		IF NOT EMPTY(NVL(viewBills.Claim_no,""))
			lcClaim=ALLT( NVL(viewBills.Claim_no,""))
		ENDIF
	ELSE
		IF NOT EMPTY(NVL(viewBills.file_no,""))
* --- Print File # ---
			lcFileNo=viewBills.file_no
		ENDIF
	ENDIF
ENDIF
USE
IF lloGen=.T.
	RELEASE oGen
ENDIF
SELECT(lnCurArea)
RETURN
*************************************************************************************
PROCEDURE lfPrintPlatInfo
LPARAMETERS lnCntr
LOCAL lcSQLLine, lnCurArea, lloGen
lnCurArea=SELECT()
IF TYPE("oGen")!="O"
	lloGen=.T.
	oGen=CREATEOBJECT("transactions.medrequest")
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

lcSQLLine="exec dbo.GetPrintPlatInfo '"+ALLTRIM(fixquote(pc_platcod))+"'"
oCdcnt.sqlpassthrough(lcSQLLine,"viewPlatInfo")
SELECT viewPlatInfo
IF RECCOUNT()>0
	lcPltName=ALLT(viewPlatInfo.NewLast) + ", " + ;
		ALLT(viewPlatInfo.NewFirst) + IIF(!EMPTY(NVL(viewPlatInfo.NewInit,"")), " " + viewPlatInfo.NewInit + ".", "")
	lcPltFirm=viewPlatInfo.Firm
	IF NOT EMPTY(NVL(viewPlatInfo.add1,""))
		lcPltAdd1=viewPlatInfo.add1
	ENDIF
	IF NOT EMPTY(NVL(viewPlatInfo.add2,""))
		lcPltAdd2=viewPlatInfo.add2
	ENDIF
	lcPltCity=ALLT(viewPlatInfo.city)+ ", " + viewPlatInfo.state + " " + viewPlatInfo.zip
	lcPltPhone=TRANSFORM(viewPlatInfo.phone, pc_fmtphon)
ENDIF
USE
IF lloGen=.T.
	RELEASE oGen
ENDIF
SELECT(lnCurArea)
RETURN
******************************************************************************************
* PROCEDURE: FLALERT
* Abstract: Print account manager alert
**************************************************************************************
PROCEDURE lfFlAlert
LOCAL n_Curarea, n_Fee, n_Pages, lcSQLLinem, lloGen
n_Curarea = SELECT()
IF TYPE("oGen")!="O"
	oGen=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

lcSQLLine="select * from tblAdmPop with (nolock) where active =1"
oCdcnt.sqlpassthrough(lcSQLLine,"AdmPop")
lcSQLLine="exec dbo.GetFlfeePages '"+ALLTRIM(pc_clcode)+"', '"+ALLTRIM(STR(pn_tag))+"'"
oCdcnt.sqlpassthrough(lcSQLLine,"viewFees")
*--get the page count and witness fee summary data
STORE 0 TO n_Fee, n_Pages
SELECT viewFees
IF RECCOUNT()>0
	n_Fee=NVL(viewFees.WitFee,0)
	n_Pages=NVL(viewFees.PAGES,0)
ENDIF
USE

*--11/4/14: force electronic FL delivery for some litigations
lcSQLLine="Exec [dbo].[getchgflshiptype] '"+ALLTRIM(fixquote(pc_litcode))+"'"
oCdcnt.sqlpassthrough(lcSQLLine,"chkFlLit")
SELECT chkFlLit
IF RECCOUNT()>0
	IF NVL(chkFlLit.bChgshp,.F.) = .T.
		pc_Flship = "E"
	ENDIF
ENDIF
IF USED("chkFlLit")
	USE IN chkFlLit
ENDIF

*do checkprinter
SELECT ADMPOP

*--11/18/19 block all printing of the FL review sheet [145919]
*!*	REPORT FORM FLrevSht TO PRINTER NOCONSOLE
*!*	SELECT ADMPOP

USE
IF lloGen=.T.
	RELEASE oGen
ENDIF
SELECT (n_Curarea)
RETURN
* --------------------------------------------------------------
* Print out bar code
* --------------------------------------------------------------
PROCEDURE lfBarCode
LOCAL arblines, szchars, szcode
DIMENSION arbline[8]
EXTERNAL ARRAY artext

WAIT WINDOW "Printing BarCode sheet" NOWAIT NOCLEAR

* Process the text items to be printed as BarCodes!!
&& Bar Code #1 -- dummy tab
arbline[1] = "000"

&& Bar Code #2: LRS_No
arbline[2] = ALLTRIM( STR( pn_lrsno))
&& Check Length of LRS_No
IF LEN( arbline[2]) < 8
	arbline[2] = arbline[2] + REPLICATE( "-", 8 - LEN( arbline[2]))
ENDIF

&& BarCode #3: Tag number!!
IF pn_tag <> 0
	IF pn_tag < 10
		arbline[3] = "00" + ALLTRIM( STR( pn_tag))
	ELSE
		arbline[3] = ALLTRIM( STR( pn_tag))
	ENDIF
	IF LEN(arbline[3]) < 3
		arbline[3] = REPLICATE( "0", 3 - LEN(arbline[3])) + arbline[3]
	ENDIF
ELSE
	arbline[3] = "000"
ENDIF

&& Bar Code #4: Record Provider (deponent)
arbline[4] = ALLTRIM(UPPER(pc_Descrpt))
arbline[4] = STRTRAN( arbline[4], "'")
arbline[4] = STRTRAN( arbline[4], "(")
arbline[4] = STRTRAN( arbline[4], ")")
arbline[4] = STRTRAN( arbline[4], "*")
arbline[4] = STRTRAN( arbline[4], ",")
arbline[4] = STRTRAN( arbline[4], "&")
arbline[4] = STRTRAN( arbline[4], "#")
arbline[4] = STRTRAN( arbline[4], ";")
arbline[4] = STRTRAN( arbline[4], '"')
arbline[4] = STRTRAN( arbline[4], '[')
arbline[4] = STRTRAN( arbline[4], ']')

IF LEN( arbline[4]) > 25
	arbline[4] = ALLTRIM(LEFT(arbline[4], 25))
ENDIF
arbline[4] = STRTRAN(ALLTRIM(arbline[4]), " ", "_")
arbline[4] = LEFT( ALLTRIM( arbline[4]) + REPL( "-", 25), 25)

* -- Barcodes 5-7: Plaintiff First Name, Last Name, Middle Initial --
arbline[5] = ALLTRIM( pc_plfname)
arbline[5] = STRTRAN( arbline[5], "*")
arbline[5] = STRTRAN( arbline[5], ",")
arbline[5] = STRTRAN( arbline[5], "'")
arbline[5] = STRTRAN( arbline[5], "&")
arbline[5] = STRTRAN( arbline[5], "#")
arbline[5] = STRTRAN( arbline[5], " ", "-")
arbline[5] = STRTRAN( arbline[5], '[')
arbline[5] = STRTRAN( arbline[5], ']')
arbline[5] = LEFT( ALLTRIM( arbline[5]) + REPL( "-", 6), 6)

arbline[6] = ALLTRIM(pc_pllname)
arbline[6] = STRTRAN( arbline[6], "*")
arbline[6] = STRTRAN( arbline[6], ",")
arbline[6] = STRTRAN( arbline[6], "'")
arbline[6] = STRTRAN( arbline[6], "&")
arbline[6] = STRTRAN( arbline[6], "#")
arbline[6] = STRTRAN( arbline[6], " ", "-")
arbline[6] = STRTRAN( arbline[6], '[')
arbline[6] = STRTRAN( arbline[6], ']')
arbline[6] = LEFT( ALLTRIM( arbline[6]) + REPL( "-", 13),13)

arbline[7] = ""
IF NOT EMPTY(NVL(pc_plminit,""))
	szchars = "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ-. *$/+%"
	IF AT( pc_plminit, szchars) > 0
		IF pc_plminit <> "*"
			arbline[7] = pc_plminit
		ENDIF
	ENDIF
ENDIF

arbline[7] = LEFT( ALLTRIM( arbline[7]) + REPL( "-", 3),3)
arbline[8] = "---"


DO lfPrtCode WITH arbline

WAIT CLEAR
RETURN
* --------------------------------------------------------------
PROCEDURE lfPrtCode
PARAMETERS artext
LOCAL lnCurArea
lnCurArea=SELECT()
PRIVATE lcFooter, lcInvName, lcAtName

STORE "" TO lcFooter, lcInvName, lcAtName
STORE "" TO c_lookAdd1, c_lookAdd2, c_lookAdd3

SELECT 0
CREATE CURSOR temprep (barcode C(80), batecode C(1))

* -- Do this for each row in the array --
FOR x = 1 TO ALEN( artext)
&& Setup for Code39 using "*" for check digits
	INSERT INTO temprep (barcode,batecode) VALUES ;
		("*" + UPPER( ALLTRIM( artext[x])) + "*",IIF(NVL(pl_bates,.F.) AND x=1 ,"B",""))
NEXT

IF pn_tag <> 0
	lcFooter=ALLTRIM(pc_Descrpt)
ENDIF

*// 6/23/10 added session settings reset before print
*DO Sessionset WITH "SETDEFAULT"
SELECT temprep
IF RECCOUNT()>0
*do checkprinter

	REPORT FORM printBarCode TO PRINTER NOCONSOLE

ENDIF
*DO Sessionset WITH "RESTOREDEF"
SELECT temprep
USE
SELECT (lnCurArea)
RETURN
***********************************************************************************
PROCEDURE lfPrnOrder
PRIVATE c_LitMatShipType

LOCAL lcTmp, lnFee, lnPages, ldOrder, lDecline, llFound, lnCopy, llFedEx, ;
	llAllowedl, lcCov2, l_NoBind, c_atmatch,  l_BindOrig, lcbillcat, ;
	lcshiptype, l_SendDs, n_Alen, n_Linecnt, c_Type, n_Pos, l_prntbto, ;
	lcSQLLine, lnCurArea, lloGen, lloForm

* Skip this document if all ordering attorneys are
* in timesheet billing and want only one copy.

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

STORE .F. TO llFedEx, llFound, l_SendDs
STORE "" TO lcCov1, lcCov2, lcbillcat, lcshiptype
dOrder = {1/1/1990}
ldDecline = {1/1/1990}
ldCancel ={1/1/1990}
lnCopy = 0
lnTotal = 0
l_BindOrig = .F.
ln_indent = 8
m.groupcode=0
m.sumcomments=""
m.Hcomments=""
**9/19/07- ef 70
SELECT 0
CREATE CURSOR temprep ( ONHOLD L, buyer C(90) NULL , ORDER C(15), numcop C(3), ;
	nobind C(1), fdx C(1), plan C(10), billtype C(1), billcatg C(1), groupcode N(3), ;
	sumcomments C(70), Hcomments C(70))

lnCurArea=SELECT()
IF TYPE("oGen")!="O"
	oGen=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF
IF TYPE("loForm")!="O"
	loForm=CREATEOBJECT("transactions.frmPStatus")
	loForm.SHOW
	lloForm=.T.
ENDIF

lcPltAtty=gfAtName(pc_platcod)		&& external

*--received document type
*!*	c_sql="select i.* from tbltagitem i " + ;
*!*		"join tblrequest r on r.cl_code=dbo.getclcodebylrs(i.lrs_no) and r.tag=i.tag " + ;
*!*		"where i.lrs_no="+ALLTRIM(STR(pn_lrsno))+" and i.tag="+ALLTRIM(STR(pn_tag))+" and " + ;
*!*		"i.doc_type in ('R','IR') and " + ;
*!*		"cast(convert(char(10),i.dtrssdone,101) as datetime)=cast(convert(char(10),r.scan_date,101) as datetime) " + ;
*!*		"and r.active=1 and i.deleted is null and i.dtmanual is null"

c_sql="select i.* from tbltagitem i " + ;
	"join tblrequest r on r.cl_code=dbo.getclcodebylrs(i.lrs_no) and r.tag=i.tag " + ;
	"where i.lrs_no="+ALLTRIM(STR(pn_lrsno))+" and i.tag="+ALLTRIM(STR(pn_tag))+" and " + ;
	"i.doc_type in ('R','IR') and " + ;
	"i.deleted is null and i.dtmanual is null " + ;
	"and r.active=1 and i.deleted is null and i.dtmanual is null order by i.softcopy_done desc"
oCdcnt.sqlpassthrough(c_sql,"curitem")
SELECT curitem
c_recmode="Unknown received mode"

IF RECCOUNT("curitem")>0
	DO CASE
	CASE ALLTRIM(UPPER(curitem.rec_mode))=="B"
		c_recmode="Original record from fax w/out barcode"
	CASE ALLTRIM(UPPER(curitem.rec_mode))=="F"
		c_recmode="Original record from fax w/ barcode"
	CASE ALLTRIM(UPPER(curitem.rec_mode))=="I"
		c_recmode="Original record downloaded from site or CD"
	CASE ALLTRIM(UPPER(curitem.rec_mode))=="M"
		c_recmode="Original record from user desktop"
	CASE ALLTRIM(UPPER(curitem.rec_mode))=="S"
		c_recmode="Original record received on Paper"
	ENDCASE
ENDIF

*// check for materials shipment data
IF USED("curmatshp")
	USE IN curmatshp
ENDIF
c_sql="exec [dbo].[litgetmaterialshipdata] '"+pc_clcode+"',"+ALLTRIM(STR(pn_tag))
oCdcnt.sqlpassthrough(c_sql,"curmatshp")
c_LitMatShipType=""
IF RECCOUNT('curmatshp')>0
	c_LitMatShipType=ALLTRIM(curmatshp.shiptype)
ENDIF

* --- print case info ---
loForm.Label3.CAPTION="Order summary sheets"+CHR(13)+;
	"Checking Plan Info"
**2/19/10 EDITED : if at least one atty has "D" plan type then sent a papers to Billing Dept
l_MonBill=lfPlanChk()			&& internal to printcov

l_RefundRequest=lfCheckRefund()

lcBarcode="*"+PADL(ALLTRIM(STR(pn_lrsno)),8,"0")+"."+PADL(ALLTRIM(STR(pn_tag)),3,"0")+"*"

lnFee = 0.00
lnPages = 0
DO lfFeePages WITH lnFee, lnPages		&& internal to printcov
DO lfChkDescript WITH ALLTRIM(lfLookCovLetDesc()), 2

IF NVL(pl_CAVer,.F.)
	LOCAL lcCAPlt
ENDIF

loForm.Label3.CAPTION="Order summary sheets"+CHR(13)+;
	"Pulling Billing Information"

DO lfAddBatesString
DO lfAddWitFees
m.sumcomments=""
m.Hcomments=""
lcSQLLine="exec dbo.GetBills '"+ALLTRIM(pc_clcode)+"'"
oCdcnt.sqlpassthrough(lcSQLLine,"viewBills")
SELECT viewBills

SCAN
	m.ONHOLD=.F.
	STORE "" TO m.buyer, m.order, m.numcop,;
		m.nobind, m.fdx, m.plan, m.billtype, m.billcatg, m.Hcomments
	l_SendDs = .F.
&& internal to printcov
	llFound = lfOrdStatus( at_code, ;
		@ldOrder, @ldDecline, @lnCopy, @llFedEx, @ldCancel, @lcbillcat, @lcshiptype)
	IF NOT EMPTY(oGen.checkDate(ldCancel))
		LOOP
	ENDIF

	IF EMPTY(oGen.checkDate(ldOrder)) AND !EMPTY(oGen.checkDate(ldDecline))    && Declined
		LOOP
	ENDIF

	IF INLIST(viewBills.at_code, "A8835P", "A5831P")
		LOOP
	ENDIF

	IF (NVL(pl_Frstlook,.F.) AND ;
			ALLTRIM(viewBills.at_code) == ALLTRIM(pc_Tflatty) AND ;
			INLIST(pc_Status, "F"))

*			AND NOT NVL(pl_CAVer,.F.)

		LOOP
	ENDIF

*!*	   IF (NVL(pl_FrstLook,.F.) AND ;
*!*	         ALLTRIM(viewBills.at_code) == ALLTRIM(pc_TflAtty) AND ;
*!*	         INLIST(pc_Status, "F", "R", "I")) AND ;
*!*	         NOT NVL(pl_CAVer,.F.)
*!*	      LOOP
*!*	   ENDIF

	llAllowed = .T.

	IF NVL(pl_CAVer,.F.) AND NOT pl_OfcOak
		lcCAPlt = gfAtType(at_code)			&& external to printcov
		IF at_code <> pc_rqatcod
			IF NVL(pl_BBAsb,.F.)
				IF lcCAPlt <> "P"
&& internal to printcov
					llAllowed = AtShare( at_code, pc_BBRound, pc_plBBAsb, pc_BBDock)
				ENDIF
			ENDIF
		ENDIF
&& internal to printcov
		llFound = lfOrdStatus( at_code, ;
			@ldOrder, @ldDecline, @lnCopy, @llFedEx, @ldCancel, @lcbillcat, @lcshiptype )

		IF EMPTY(oGen.checkDate(ldOrder))
			llAllowed=.F.
		ELSE
			IF NOT EMPTY(oGen.checkDate(ldDecline))
				llAllowed=.F.
			ENDIF
		ENDIF

		IF INLIST(viewBills.Response, "F", "C")
			llAllowed = .F.
		ENDIF

		IF llFound AND llAllowed AND NOT EMPTY(oGen.checkDate(ldOrder))
			IF NOT EMPTY(NVL(arAtty[1],""))
				DIMENSION arAtty( ALEN( arAtty) + 1)
			ENDIF
			arAtty[ALEN( aratty)] = at_code
&& external to printcov
			m.buyer="" + NVL(CODE,"")+ "  " + LEFT( NVL(gfAtName( at_code),""), 30)
		ENDIF
	ELSE
&& external to printcov
		m.buyer="" + NVL(CODE,"") + "  " + LEFT( NVL(gfAtName( at_code),""), 30)
	ENDIF

	IF NVL(pl_KoPVer,.F.)
&& internal to printcov
		llFound = lfOrdStatus( at_code, @ldOrder, ;
			@ldDecline, @lnCopy, @llFedEx, @ldCancel, @lcbillcat, @lcshiptype)

	ENDIF

	IF llFound AND (( NVL(pl_CAVer,.F.) AND llAllowed) OR NVL(pl_KoPVer,.F.))

		IF EMPTY(oGen.checkDate(ldOrder))
			lnCopy = 0
			lcTmp = IIF( EMPTY(oGen.checkDate(ldDecline)), "Unknown", "Declined")
		ELSE
			IF EMPTY(oGen.checkDate(ldDecline))
				lcTmp = "Ordered"
			ELSE
				lcTmp = "Cancelled"
				lnCopy = 0
			ENDIF
		ENDIF

		m.order=lcTmp

		l_BindOrig = .F.
		l_NoBind = .F.
		c_atmatch = viewBills.at_code

		IF lfCheckRules(c_atmatch)=.T.		&& internal to printcov
			SELECT viewAttyRulz
			SCAN
				IF NOT EMPTY(NVL(viewAttyRulz.GROUP,0)) AND ;
						viewAttyRulz.GROUP <> pn_group
					LOOP
				ENDIF
				IF NOT EMPTY(NVL(viewAttyRulz.Litigation,"")) AND ;
						viewAttyRulz.Litigation <> pc_litcode
					LOOP
				ENDIF
				IF NOT EMPTY( NVL(viewAttyRulz.Area,"")) AND ;
						UPPER( viewAttyRulz.Area) <> UPPER( pc_area)
					LOOP
				ENDIF

				IF viewAttyRulz.ZeroCopies
					lnCopy = 0
				ENDIF
				l_NoBind = viewAttyRulz.nobind
				l_BindOrig = viewAttyRulz.BindOrig

				l_SendDs =viewAttyRulz.Sendds
				EXIT
			ENDSCAN
			SELECT viewAttyRulz
			USE
		ENDIF
		SELECT viewBills

		IF l_SendDs AND NOT "D" $ lcshiptype
			lcshiptype = lcshiptype + ",D"
		ENDIF

		IF NOT "P" $ lcshiptype
			lnCopy = 0
		ENDIF

		l_prntbto = .F.                           && flag for printed bill to sheet

*--build array of ship types
		DIMENSION a_types[4]
		a_types = ""
		c_Type = LEFT(lcshiptype, 1)
		a_types[1] = gfDstype(c_Type)			&& external to printcov

		FOR n_cnt = 1 TO 3
			n_Pos = AT(",", lcshiptype, n_cnt) + 1
			IF n_Pos > 1
				c_Type = SUBSTR(lcshiptype, n_Pos, 1)
				a_types[n_cnt + 1] = gfDstype(c_Type)	&& external to printcov

			ELSE
				EXIT
			ENDIF
		ENDFOR
		n_Alen = ALEN(a_types, 1)

		n_Linecnt = 0
		FOR n_cnt = 1 TO n_Alen
			l_newline = .F.
			m.numcop=''
			IF LEFT(a_types[n_cnt], 1) $ lcshiptype
				n_Linecnt = n_Linecnt + 1
				IF n_Linecnt = 1
					IF LEFT(a_types[n_cnt], 1) = "P"
&&12/10/2009 - re-calculate number of paper orders
						n_onhold=ifOnHOLD(viewBills.at_code)
						m.ONHOLD=IIF(n_onhold<>0, .T.,.F.)
						m.Hcomments=IIF(n_onhold<>0, UPPER("Atty is on hold, return to Leslie."),"")
						lnCopy=lnCopy-n_onhold
						m.numcop=ALLTRIM(STR(lnCopy,2))

					ELSE
						m.numcop=a_types[n_cnt]

					ENDIF
				ELSE
					m.buyer=''
					l_newline = .T.
					IF LEFT(a_types[n_cnt], 1) = "P"
&&12/10/2009 - re-calculate number of paper orders
						n_onhold=ifOnHOLD(viewBills.at_code)
						m.ONHOLD=IIF(n_onhold<>0, .T.,.F.)
						m.Hcomments=IIF(n_onhold<>0, "-The atty is on hold, return to Leslie.","")
						lnCopy=lnCopy-n_onhold
						m.numcop=ALLTRIM(STR(lnCopy,2))

					ELSE
						m.numcop=a_types[n_cnt]

					ENDIF
				ENDIF
			ENDIF

			IF n_cnt = 1
				IF l_NoBind
					m.nobind="X"
				ENDIF
				m.buyer=NVL(m.buyer,"")
				m.order=NVL(m.order,"")
				m.numcop=NVL(m.numcop,"")
				m.nobind=NVL(m.nobind,"")
				m.fdx=IIF(NVL(llFedEx,.F.), "Y", "N")
				m.plan=NVL(viewBills.plan,"")
				m.billtype=NVL(viewBills.Plan_Type,"")
				m.billcatg=NVL(lcbillcat,"")
				m.groupcode=m.groupcode+1
				INSERT INTO temprep FROM MEMVAR
			ENDIF

			IF n_cnt = 2
				STORE "" TO m.buyer, m.order,;
					m.nobind, m.fdx, m.plan, m.billtype, m.billcatg

				IF NVL(pl_CAVer,.F.)
					IF llFound AND llAllowed AND NOT EMPTY(oGen.checkDate(ldOrder))
&& external to printcov
						m.buyer= SPACE(8)+"(" + NVL(ALLTRIM(at_code),"") + ")  " + ALLTRIM(NVL( gfInvNam( at_code),""))
						INSERT INTO temprep FROM MEMVAR
					ENDIF
				ELSE
					IF n_Linecnt = 2
&& external to printcov
						m.buyer= SPACE(8)+"(" + ALLTRIM(NVL(at_code,"")) + ")  " + ALLTRIM(NVL( gfInvNam( at_code),""))
						INSERT INTO temprep FROM MEMVAR
						IF !EMPTY(NVL(bill_to,"")) AND n_Linecnt = 1
							m.buyer= SPACE(8)+"File #: " + NVL(viewBills.file_no,"")
							INSERT INTO temprep FROM MEMVAR
						ENDIF
					ELSE
&& external to printcov
						m.buyer= SPACE(8)+"(" + ALLTRIM(NVL(at_code,"")) + ")  " + ALLTRIM( NVL(gfInvNam( at_code),"")) ;
							+ IIF( NOT EMPTY(NVL(bill_to,"")), "  File #: " + viewBills.file_no, "")
						INSERT INTO temprep FROM MEMVAR
					ENDIF
&& external to printcov
					IF NOT EMPTY(NVL(bill_to, "")) AND n_Linecnt = 1
						m.numcop=""
						m.buyer= SPACE(8)+"Bill To: (" + ALLTRIM( NVL(bill_to,"")) + ")  " + ;
							LEFT( NVL(gfAtName( bill_to),""), 30)
						INSERT INTO temprep FROM MEMVAR
						l_prntbto = .T.
					ENDIF
				ENDIF
			ENDIF

			IF n_cnt = 3
				IF NOT NVL(pl_CAVer,.F.) AND NOT EMPTY(NVL(bill_to,""))
					IF l_newline
						m.buyer= SPACE(8)+"File #: " + NVL(viewBills.file_no,"")

						INSERT INTO temprep FROM MEMVAR
					ELSE
						m.buyer= SPACE(8)+"File #: " + NVL(viewBills.file_no,"")

						INSERT INTO temprep FROM MEMVAR
					ENDIF
				ELSE
					IF NOT EMPTY(NVL(m.numcop,''))
						INSERT INTO temprep FROM MEMVAR
					ENDIF
				ENDIF
			ENDIF

			IF n_cnt = 4 AND NOT l_prntbto
				IF NOT EMPTY(NVL(bill_to,""))
					IF l_newline
&& external to printcov
						m.numcop=""
						m.buyer= SPACE(8)+"Bill To: (" + ALLTRIM( NVL(bill_to,"")) + ")  " + ;
							LEFT( NVL(gfAtName( bill_to),""), 30)
**9/19/07 EF: added Claim # to all cases
						IF NOT EMPTY(NVL(Claim_no,""))
							m.buyer =ALLTRIM(NVL(m.buyer,'')) +SPACE(1)+"Claim #: " + NVL(viewBills.Claim_no,"")
						ENDIF
**9/19/07
						INSERT INTO temprep FROM MEMVAR
					ELSE
&& external to printcov

**12/07/2011 added atty's name for SF plan per Renee

						IF NVL(viewBills.plan,"")="SF"
							c_nameb=BillToAttyName(NVL(bill_to,""))
						ELSE
							c_nameb=""
						ENDIF



						m.buyer= SPACE(8)+"Bill To: (" + ALLTRIM( NVL(bill_to,"")) + ")  " + ;
							LEFT( gfAtName( NVL(bill_to,"")), 30)  + SPACE(1) + ALLTRIM(c_nameb)




**9/19/07 EF: added Claim # to all cases
						IF NOT EMPTY(NVL(Claim_no,""))
							m.buyer =ALLTRIM(NVL(m.buyer,"")) +SPACE(1)+"Claim #: " + NVL(viewBills.Claim_no,"")
						ENDIF

**9/19/07
						INSERT INTO temprep FROM MEMVAR
					ENDIF
				ELSE
					IF NOT EMPTY(NVL(m.numcop,''))
						INSERT INTO temprep FROM MEMVAR
					ENDIF
				ENDIF
			ENDIF




		ENDFOR


		IF NOT "P" $ lcshiptype
			lnCopy = 0
		ENDIF

		lnTotal = lnTotal + lnCopy



	ELSE
		IF NVL(pl_KoPVer,.F.)
			m.buyer= SPACE(8)+"Error: Order info is unknown."
			INSERT INTO temprep FROM MEMVAR
		ENDIF
	ENDIF


ENDSCAN


#IF 0
* --- Print out 3,1 screen ---

	lfPrintPurchAtty()		&& internal to printcov

#ENDIF

SELECT temprep
IF RECCOUNT()=0
	STORE "" TO m.buyer, m.order, m.numcop,;
		m.nobind, m.fdx, m.plan, m.billtype, m.billcatg, m.sumcomments
	m.groupcode=1
	INSERT INTO temprep FROM MEMVAR 		&& AT LEAST ONE RECORD MUST BE IN THE FILE
ENDIF
GO TOP
*do checkprinter
*// 2-3-2010 kdl add count of images to replace default page number

IF pl_autosc
	lnPages=lfgetpgcnt()
	lnPages=IIF(lnPages<4,4,lnPages)
ENDIF

*= _fpreset()
REPORT FORM PrintOrder TO PRINTER NOCONSOLE
*= _fpreset()

*// if soft copy, check fo and print material delivery form

IF USED('curmatshp')
	DO materialreceiptreport
	USE IN curmatshp
ENDIF

SELECT temprep
USE
SELECT viewBills
USE
IF lloGen=.T.
	RELEASE oGen
	oGen=.NULL.
ENDIF
IF lloForm=.T.
	RELEASE loForm
	loForm=.NULL.
ENDIF

SELECT (lnCurArea)
RETURN
*******************************************************
PROCEDURE addSpecIns
PARAMETERS lcClCode, lnTag
*   After the header (on the first page only), display the original
*   request's special instructions ("request blurb")
LOCAL lcDesc, lnCurArea, lcSQLLine, lloGen
lnCurArea=SELECT()
IF TYPE("oGen")!="O"
	oGen=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

n_memowidth = SET("MEMOWIDTH")
IF NVL(pc_litcode,"###")="AV1"
	SET MEMOWIDTH TO 75
ELSE
	SET MEMOWIDTH TO 63
ENDIF
lcSQLLine="exec dbo.GetSpecInsbyClCodeTag '"+ALLTRIM(lcClCode)+"', '"+ALLTRIM(STR(lnTag))+"'"
oCdcnt.sqlpassthrough(lcSQLLine,"viewSpecIns")
SELECT viewSpecIns

IF RECCOUNT()>0
	lnLines = MEMLINES(viewSpecIns.Spec_inst)

*   Take the stored, pre-formatted special instructions and re-format
*   them for cover-letter printing by removing extra spaces, CR/LF
*   characters, etc.
	c_prntline = ""
	lcHold=""
	FOR i = 1 TO lnLines
		c_templine = ""
		IF NOT EMPTY( ALLT( MLINE(viewSpecIns.Spec_inst, i)))
			c_templine = ALLT( MLINE(viewSpecIns.Spec_inst, i))
		ENDIF
		c_templine=ALLTRIM(lcHold)+" "+c_templine
		lcHold=""
		c_templine = STRTRAN( c_templine, CHR(13), "")
		c_templine = STRTRAN( c_templine, CHR(10), "")
		c_templine = STRTRAN( c_templine, CHR(9), "")
		c_templine = STRTRAN( c_templine, ".", ". ")
		c_templine = STRTRAN( c_templine, "  ", " ")
		IF EMPTY(c_templine)
			LOOP
		ENDIF
&& check if the next paragraph was combined with previous one
		lnStartPos=4		&& 1 - 9
		IF (ISDIGIT(SUBSTR(ALLTRIM(c_templine),2,1)) AND SUBS( c_templine, 3, 1) == ".")
			lnStartPos=5 && 10 - 99
		ENDIF
		FOR lnCharCntr=lnStartPos TO LEN(ALLTRIM(c_templine))		&& skip first three chars
* check for space+number+dot or space+number+number+dot to move it to next line
			IF (ISDIGIT(SUBSTR(ALLTRIM(c_templine),lnCharCntr,1))=.T. AND ;
					SUBSTR(ALLTRIM(c_templine),lnCharCntr+1,1)="." AND ;
					SUBSTR(ALLTRIM(c_templine),lnCharCntr-1,1)=" ") OR ;
					(ISDIGIT(SUBSTR(ALLTRIM(c_templine),lnCharCntr,1))=.T. AND ;
					ISDIGIT(SUBSTR(ALLTRIM(c_templine),lnCharCntr-1,1))=.T. AND ;
					SUBSTR(ALLTRIM(c_templine),lnCharCntr+1,1)="." AND ;
					SUBSTR(ALLTRIM(c_templine),lnCharCntr-2,1)=" ")
				lcHold=SUBSTR(ALLTRIM(c_templine),lnCharCntr,LEN(ALLTRIM(c_templine)))
				c_templine=SUBSTR(ALLTRIM(c_templine),1,lnCharCntr-1)
				EXIT
			ENDIF
		NEXT

		IF (ISDIGIT(SUBSTR(ALLTRIM(c_templine),1,1)) AND SUBS(ALLTRIM(c_templine), 2, 1) == ".") OR ;
				(ISDIGIT(SUBSTR(ALLTRIM(c_templine),2,1)) AND SUBS(ALLTRIM(c_templine), 3, 1) == ".")
			DO lfParsePrt WITH c_prntline				&& internal to printcov
			c_prntline = c_templine
			LOOP
		ELSE
			c_prntline = ALLTRIM(c_prntline) + " " + ALLTRIM(c_templine)
		ENDIF
	NEXT
	IF NOT EMPTY( c_prntline)
		DO lfParsePrt WITH c_prntline				&& internal to printcov
	ENDIF
ELSE
	oGen.bringmessage( "No request blurb was found for this record.",2)
ENDIF
SET MEMOWIDTH TO n_memowidth
SELECT viewSpecIns
USE
IF lloGen=.T.
	RELEASE oGen
ENDIF
SELECT (lnCurArea)
RETURN
*****************************************************************************
PROCEDURE addBeryAdm
** Berry & Berry new-style admission information
LOCAL lcDesc, lnCurArea, lcSQLLine, lloGen
lnCurArea=SELECT()
IF TYPE("oGen")!="O"
	oGen=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

lcSQLLine="exec dbo.GetAdmsnType '"+ALLTRIM(pc_clcode)+"', '"+ALLTRIM(STR(pn_tag))+"'"
oCdcnt.sqlpassthrough(lcSQLLine,"viewAdmit")
SELECT viewAdmit
IF RECCOUNT()>0
	c_admit=viewAdmit.Admit
	l_redacted=viewAdmit.redacted
ELSE
	c_admit=""
	l_redacted=.F.
ENDIF
USE
c_recv = "records"
DO CASE
CASE INLIST(pc_Status,"R","F")
	c_recv = c_recv + IIF(l_redacted, ": REDACTED", "")
CASE pc_Status = "N"
	c_recv = c_recv + ": NO RECORD CERTIFICATE"
CASE pc_Status = "C"
	c_recv = c_recv + ": CLOSED"
ENDCASE
INSERT INTO temprep (textline) VALUES(c_admit + c_recv)
IF lloGen=.T.
	RELEASE oGen
ENDIF
SELECT (lnCurArea)
RETURN

***************************************************************************
PROCEDURE addNewStyle
*******************************************************************
*   New-style cover letter (7/2001) for non-B&B cases             *
*******************************************************************
*   Process new-style blurbs for received records, if any, at this
*   point in the program.
LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

IF INLIST(pc_Status, "R", "F")
&& internal to printcov
*--4/28/14 GET RID OF "are attached" from NRS records
	IF n_recvcats > 0
		lcFooter=UPPER(ALLTRIM(c_recvcats)) + ;
			IIF(NOT l_recvblnk OR n_recvcats > 1, " ARE ATTACHED."+CHR(13), "")
	ELSE
		lcFooter=UPPER(ALLTRIM(c_recvcats))
	ENDIF

	IF l_pacsrecd
&& internal to printcov
		lcFooter=lcFooter+CHR(13)+;
			"NOTE: THE ATTACHED RADIOLOGY MATERIALS ARE DIGITAL FIRST-" + ;
			"GENERATION FILMS, AND ARE NOT 'ORIGINAL' IN THE " + ;
			"TRADITIONAL SENSE."
&& internal to printcov
		lcFooter=lcFooter+CHR(13)+;
			"THEY ARE PRODUCED BY A PAC (PICTURE ARCHIVE " + ;
			"AND COMMUNICATION SYSTEM) AND ARE CONSIDERED " + ;
			"ORIGINAL FILMS."

	ENDIF
ENDIF

**  Process No Record Statement Blurbs for new cover letter

**  NRS Type Meaning
**  A   1   NRS Documented by deponent
**  B   2   Deponent can't be located
**  C   3   Verbal NRS
**  D   4   Inadequate response from att'y on Txn 30 request for info
**  E   5   Verbal "Same as" from deponent
**  F   6   Unresponsive deponent
IF NVL(pl_HasNRS,.F.)
	DO CASE
* Print record-category data from admission file only for A/C/E
	CASE INLIST( pc_NRSType, "A", "C", "E")
&& internal to printcov
		lcFooter=lcFooter+IIF(EMPTY(ALLTRIM(lcFooter)),"",CHR(13))+;
			IIF( l_nrsblnk AND n_nrscats = 1, "", ;
			"A NO RECORD STATEMENT FOR ") + UPPER(ALLTRIM(c_nrscats)) + ;
			IIF( l_nrsblnk AND n_nrscats = 1, "", " IS ATTACHED.")

		IF pc_NRSType = "E"
			lcFooter=lcFooter+CHR(13)+;
				"Please see the attached documentation for specific"
			lcFooter=lcFooter+CHR(13)+;
				"information identifying these records as being the"
			lcFooter=lcFooter+CHR(13)+;
				"same as those from another facility or record custodian."
		ENDIF
	CASE pc_NRSType = "B"
		lcFooter=lcFooter+IIF(EMPTY(ALLTRIM(lcFooter)),"",CHR(13))+;
			"RecordTrak has been unable to procure the above-mentioned"
		lcFooter=lcFooter+CHR(13)+;
			"records because we cannot locate the deponent. Please see"
		lcFooter=lcFooter+CHR(13)+;
			"the attached documentation which specifies the steps we"
		lcFooter=lcFooter+CHR(13)+;
			"have taken to locate the deponent."
	CASE pc_NRSType = "D"
		lcSQLLine="select dbo.GetCode30TxnDate('"+ALLTRIM(pc_clcode)+"', '"+ALLTRIM(STR(pn_tag))+"')"
		oCdcnt.sqlpassthrough(lcSQLLine,"viewDate")
		SELECT viewDate
		IF RECCOUNT()>0
			ldTxnDate=viewDate.EXP
		ELSE
			ldTxnDate={}
		ENDIF
		USE
		lcFooter=lcFooter+IIF(EMPTY(ALLTRIM(lcFooter)),"",CHR(13))+;
			"Counsel was informed on " + DTOC(ldTxnDate) + ;
			" that the above-named"
		lcFooter=lcFooter+CHR(13)+;
			"deponent would not release the requested materials until"
		lcFooter=lcFooter+CHR(13)+;
			"additional requirements were fulfilled. Please see the "
		lcFooter=lcFooter+CHR(13)+;
			"attached documentation for the specifics of these " + ;
			"requirements."
		lcFooter=lcFooter+CHR(13)+;
			"As of this date, RecordTrak has not received a response from"
		lcFooter=lcFooter+CHR(13)+;
			"counsel regarding action(s) to be taken, and is therefore"
		lcFooter=lcFooter+CHR(13)+;
			"discontinuing attempts to obtain the records in question."
	CASE pc_NRSType = "F"
		lcFooter=lcFooter+IIF(EMPTY(ALLTRIM(lcFooter)),"",CHR(13))+;
			"A request was sent to the above-named deponent on " + ;
			DTOC( pd_ReqDate) + "."
		lcFooter=lcFooter+CHR(13)+;
			"The facility has not responded to either this request or to"
		lcFooter=lcFooter+CHR(13)+;
			"our extensive follow-up contacts regarding the request. The"
		lcFooter=lcFooter+CHR(13)+;
			"attached documentation provides details of the follow-up"
		lcFooter=lcFooter+CHR(13)+;
			"activities performed by our staff. Please inform RecordTrak"
		lcFooter=lcFooter+CHR(13)+;
			"if there are additional actions you wish us to take regarding"
		lcFooter=lcFooter+CHR(13)+;
			"this record request. Unless RecordTrak is notified that"
		lcFooter=lcFooter+CHR(13)+;
			"additional actions are required, we will discontinue attempts"
		lcFooter=lcFooter+CHR(13)+;
			"to obtain records from this deponent on your behalf."
	ENDCASE
ENDIF

*   Display information on incomplete/missing items, if any.
*   New-style receipt blurb code is stored in Record.Inc_Code

IF NVL(pl_Incompl,.F.) AND NOT EMPTY(NVL(pc_IncCode,""))  AND !EMPTY(ALLTRIM(c_inccats))
	lcFooter=lcFooter+IIF(EMPTY(ALLTRIM(lcFooter)),"",CHR(13)+CHR(13))+;
		UPPER(ALLTRIM(c_inccats)) + IIF( l_incblnk AND n_inccats = 1, "", ;
		" HAVE NOT YET BEEN RECEIVED AND WILL FOLLOW UNDER SEPARATE " ;
		+ "COVER.")
ENDIF
RETURN

********************************************************************************
PROCEDURE addOldStyle
*******************************************************************
*   Old-style cover letter (7/2001) for non-B&B cases
LOCAL lcDesc, lnCurArea, lcSQLLine, lloGen
lnCurArea=SELECT()
IF TYPE("oGen")!="O"
	oGen=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')


lcFooter=""
**10/01/18 SL #109598
*lcSQLLine="select * from tblAdmissn with (nolock,INDEX(ix_tblAdmissn_1)) where cl_code='"+
lcSQLLine="select * from tblAdmissn with (nolock) where cl_code='"+;
	ALLTRIM(pc_clcode)+"' and tag='"+ALLTRIM(STR(pn_tag))+"'and active=1 order by admnumber"
oCdcnt.sqlpassthrough(lcSQLLine,"viewAdm")
SELECT viewAdm
IF RECCOUNT()>0
	SCAN
		lnLines = MEMLINES(admission)
		INSERT INTO temprep(textline, textline2) VALUES ;
			(MLINE(viewAdm.admission, 1),;
			IIF(viewAdm.admNumber = 0, "  ", STR(viewAdm.admNumber, 2, 2))+"  "+lcCover)
		FOR i = 2 TO lnLines
			INSERT INTO temprep(textline, textline2) VALUES (MLINE(viewAdm.admission, i), "")
		NEXT
	ENDSCAN
ELSE
	oGen.bringmessage( "No admission information found for this record.",2)
ENDIF
SELECT viewAdm
USE
IF lloGen=.T.
	RELEASE oGen
ENDIF
SELECT (lnCurArea)
RETURN
*****************************************************************************
PROCEDURE lfPrintBarCodes
PARAMETERS lcInvCode, lcAtCode, lcFirst, lcSecond, lcFooter, lcSuffix
IF EMPTY(NVL(lcAtCode,""))
	GFMESSAGE("No first-look attorney set for this tag. Bar code sheet printing cancelled.")
	RETURN
ENDIF
LOCAL lnCurArea
lnCurArea=SELECT()

SELECT 0
CREATE CURSOR temprep (barcode C(80), batecode C(1))
lcInvName= ALLTRIM( gfInvNam(lcInvCode))
lcAtName=gfAtName(lcAtCode)+lcSuffix
STORE "" TO c_lookFirm, c_lookName, c_lookAdd1, c_lookAdd2, c_lookAdd3
DO lookAttyInfo WITH lcAtCode, c_lookFirm, c_lookName, c_lookAdd1, c_lookAdd2, c_lookAdd3
lcFooter=""

lcFirst = STRTRAN( lcFirst, "'")
lcFirst = STRTRAN( lcFirst, "(")
lcFirst = STRTRAN( lcFirst, ")")
lcFirst = STRTRAN( lcFirst, "*")
lcFirst = STRTRAN( lcFirst, ",")
lcFirst = STRTRAN( lcFirst, "&")
lcFirst = STRTRAN( lcFirst, "#")
lcFirst = STRTRAN( lcFirst, ";")
lcFirst = STRTRAN( lcFirst, '"')
lcFirst = STRTRAN( lcFirst, " ")
lcFirst = STRTRAN( lcFirst, '[')
lcFirst = STRTRAN( lcFirst, ']')

lcSecond = STRTRAN( lcSecond, "'")
lcSecond = STRTRAN( lcSecond, "(")
lcSecond = STRTRAN( lcSecond, ")")
lcSecond = STRTRAN( lcSecond, "*")
lcSecond = STRTRAN( lcSecond, ",")
lcSecond = STRTRAN( lcSecond, "&")
lcSecond = STRTRAN( lcSecond, "#")
lcSecond = STRTRAN( lcSecond, ";")
lcSecond = STRTRAN( lcSecond, '"')
lcSecond = STRTRAN( lcSecond, " ")
lcSecond = STRTRAN( lcSecond, '[')
lcSecond = STRTRAN( lcSecond, ']')

INSERT INTO temprep (barcode) VALUES ("*" + UPPER( ALLTRIM( lcFirst)) + "*")
INSERT INTO temprep (barcode) VALUES ("*" + UPPER( ALLTRIM( lcSecond)) + "*")

SELECT temprep
IF RECCOUNT()>0
*REPORT FORM printBarCode TO PRINTER NOCONSOLE
*do checkprinter
	REPORT FORM printAttyBarCode TO PRINTER NOCONSOLE
ENDIF
SELECT temprep
USE
SELECT (lnCurArea)
RETURN
******************************************************************************
PROCEDURE lfSetGlobals
LPARAMETERS lcClCode
LOCAL lloGen, lcSQLLine, lnCurArea, llTbl
lnCurArea=SELECT()
IF TYPE("oGen")!="O"
	oGen=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

IF !USED("master")
	lcSQLLine="select * from tblMaster where cl_code='"+;
		ALLTRIM(lcClCode)+"' and active=1"
	oCdcnt.sqlpassthrough(lcSQLLine,"Master")
	llTbl=.T.
ENDIF
STORE .F. TO pl_GotCase
DO gfGetCas
IF llTbl=.T.
	SELECT MASTER
	USE
ENDIF

IF lloGen=.T.
	RELEASE oGen
ENDIF

SELECT (lnCurArea)
RETURN
********************************************************************************
PROCEDURE lookAttyInfo
LPARAMETERS lcSearch, c_lookFirm, c_lookName, c_lookAdd1, c_lookAdd2, c_lookAdd3
LOCAL lloGen, lcSQLLine, lnCurArea
lnCurArea=SELECT()
IF TYPE("oGen")!="O"
	oGen=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

lcSQLLine="exec dbo.GetAttyInfo '"+ALLTRIM(fixquote(lcSearch))+"'"
oCdcnt.sqlpassthrough(lcSQLLine,"LookAtty")
SELECT lookAtty
IF RECCOUNT()>0
	c_lookFirm = lookAtty.Firm
	c_lookName = ALLT(lookAtty.NewFirst) + " " + ;
		IIF(!EMPTY(ALLTRIM(NVL(lookAtty.NewInit,""))), ALLTRIM(lookAtty.NewInit) + ". ", "") + ;
		ALLT(lookAtty.NewLast) + ;
		IIF( NOT EMPTY(ALLTRIM(NVL(lookAtty.TITLE,""))), ", " + ALLTRIM(lookAtty.TITLE), "")
	IF ALLTRIM(UPPER(c_lookName))==","
		c_lookName=""
	ENDIF
	c_lookAdd1 = lookAtty.NewAdd1
	c_lookAdd2 = lookAtty.NewAdd2
	c_lookAdd3 = IIF( NOT EMPTY(NVL(lookAtty.NewCity,"")), ALLTRIM(lookAtty.NewCity) + ", ", "")+;
		IIF( NOT EMPTY(NVL(lookAtty.NewState,"")), ALLTRIM(lookAtty.NewState) + " ", "") + ;
		STRTRAN(ALLTRIM(lookAtty.NewZip),"-","")
ENDIF
SELECT lookAtty
USE
IF lloGen=.T.
	RELEASE oGen
ENDIF

SELECT (lnCurArea)
RETURN
*********************************************************************************
PROCEDURE lfAddBatesString
LOCAL lnCurArea, lcSQLLine, lcBates, lloGen
lnCurArea=SELECT()
STORE "" TO m.buyer, m.order, m.numcop,m.nobind, m.fdx, m.plan, m.billtype, m.billcatg
m.sumcomments=""
m.groupcode=m.groupcode+1
lcSQLLine="select bateslocation1, bateslocation2, bateslocation3, bateslocation4, batesRules "+;
	" from tbllit  with (nolock) where [code]='"+ALLTRIM(pc_litcode)+"' and active=1"
IF TYPE("oGen")!="O"
	oGen=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

oCdcnt.sqlpassthrough(lcSQLLine,"viewLit")
lcBatesFile=locatefile()
IF EMPTY(ALLTRIM(lcBatesFile))
	m.sumcomments="NO SPECIAL BATES"
	INSERT INTO temprep FROM MEMVAR
	USE IN viewLit
	RETURN
ENDIF

lcSQLLine="select * from tblResetBates with (nolock) where litigation='"+;
	ALLTRIM(UPPER(NVL(viewLit.batesRules,"*")))+"' and area='*'"+;
	" and active=1"
oCdcnt.sqlpassthrough(lcSQLLine, "viewResetBates")
SELECT viewResetBates
IF RECCOUNT()=0
	m.sumcomments="NO SPECIAL BATES"
	INSERT INTO temprep FROM MEMVAR
	USE IN viewLit
	USE IN viewResetBates
	RETURN
ENDIF

SELECT 0
CREATE CURSOR textBatesFile (batestext m)
APPEND BLANK
SELECT textBatesFile
APPEND MEMO batestext FROM (lcBatesFile) OVERWRITE
SET MEMOWIDTH TO viewResetBates.MEMOWIDTH
lnLines = MEMLINES(textBatesFile.batestext)
FOR lnii = 1 TO lnLines
	lcLine=MLINE(textBatesFile.batestext, lnii)
	IF lnii>=viewResetBates.firstrow
		IF SUBSTR(ALLTRIM(lcLine),1,3)==PADL(ALLTRIM(STR(pn_tag)),3,"0")
			m.sumcomments=LEFT(ALLTRIM(lcLine),70)
		ENDIF
	ENDIF
	SELECT textBatesFile
NEXT
IF EMPTY(ALLTRIM(m.sumcomments))
	m.sumcomments="NO SPECIAL BATES"
ENDIF
INSERT INTO temprep FROM MEMVAR
USE IN textBatesFile
USE IN viewLit
USE IN viewResetBates
IF lloGen=.T.
	RELEASE oGen
ENDIF
SELECT (lnCurArea)
RETURN

*********************************************************************************
PROCEDURE locatefile
LOCAL lcSQLLine, lnCurArea, lcFile, llLocated, lcAddChar
lnCurArea=SELECT()
llLocated=.F.
lcAddChar=""
IF ALLTRIM(UPPER(pc_litcode))=="O"
	lcAddChar="L"
ENDIF
SELECT viewLit
IF !EMPTY(ALLTRIM(NVL(viewLit.batesLocation1,"")))
	lcFile=ADDBS(ALLTRIM(viewLit.batesLocation1))+ALLTRIM(UPPER(lcAddChar))+ALLTRIM(STR(pn_lrsno))+".txt"
	IF FILE(lcFile)
		llLocated=.T.
	ELSE
		IF !EMPTY(ALLTRIM(NVL(viewLit.batesLocation2,"")))
			lcFile=ADDBS(ALLTRIM(viewLit.batesLocation2))+ALLTRIM(UPPER(lcAddChar))+ALLTRIM(STR(pn_lrsno))+".txt"
			IF FILE(lcFile)
				llLocated=.T.
			ELSE
				IF !EMPTY(ALLTRIM(NVL(viewLit.batesLocation3,"")))
					lcFile=ADDBS(ALLTRIM(viewLit.batesLocation3))+ALLTRIM(UPPER(lcAddChar))+ALLTRIM(STR(pn_lrsno))+".txt"
					IF FILE(lcFile)
						llLocated=.T.
					ENDIF
				ELSE
					IF !EMPTY(ALLTRIM(NVL(viewLit.batesLocation4,"")))
						lcFile=ADDBS(ALLTRIM(viewLit.batesLocation4))+ALLTRIM(UPPER(lcAddChar))+ALLTRIM(STR(pn_lrsno))+".txt"
						IF FILE(lcFile)
							llLocated=.T.
						ENDIF
					ENDIF
				ENDIF
			ENDIF
		ENDIF
	ENDIF
ENDIF
SELECT (lnCurArea)
IF llLocated=.T.
	RETURN lcFile
ELSE
	RETURN ""
ENDIF
************************************************************************************
PROCEDURE lfAddWitFees
LOCAL lnCurArea, lcSQLLine, lcBates, lloGen
lnCurArea=SELECT()
STORE "" TO m.buyer, m.order, m.numcop,m.nobind, m.fdx, m.plan, m.billtype, m.billcatg
m.sumcomments=""
m.groupcode=m.groupcode+1
lcSQLLine="exec dbo.GetWitFeeComments '"+ALLTRIM(pc_clcode)+"', "+ALLTRIM(STR(pn_tag))
IF TYPE("oGen")!="O"
	oGen=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

oCdcnt.sqlpassthrough(lcSQLLine,"viewWFComments")
SELECT viewWFComments
GO TOP
SCAN
	m.sumcomments="Check #:"+ALLTRIM(STR(NVL(COUNT,0)))+;
		"; Posted:"+ALLTRIM(DTOC(txn_Date))+;
		"; Amount:"+ALLTRIM(STR(NVL(wit_fee,0.00),10,2))
	INSERT INTO temprep FROM MEMVAR
	m.sumcomments=ALLTRIM(NVL(COMMENT,""))
	INSERT INTO temprep FROM MEMVAR
	SELECT viewWFComments
ENDSCAN
USE IN viewWFComments
IF lloGen=.T.
	RELEASE oGen
ENDIF
SELECT (lnCurArea)
RETURN

********************************************************************************
PROCEDURE checkPrinter
LOCAL lnCurArea, lnPrints

*!*	RETURN

*!*	IF TYPE("l_printerdefaultset")='U'
*!*		l_printerdefaultset=.f.
*!*	ENDIF
*!*	IF l_printerdefaultset
*!*		return
*!*	ENDIF
*!*	lnCurArea=SELECT()

*!*	IF PRINTSTATUS()=.F.
*!*		gfmessage("Printer is not ready.  Fix it and try again.")
*!*		QUIT
*!*	ENDIF

*!*	*\ 5/13/2009: swith to API call to set default printer
*!*	*!*	IF Setdefprn()<1
*!*	*!*		lcPrinter=GETPRINTER()
*!*	*!*		SET PRINTER TO &lcPrinter
*!*	*!*	ENDIF

*!*	lnPrints=APRINTERS(laPrinters)
*!*	IF lnPrints>0
*!*		SET PRINTER TO DEFAULT
*!*	ELSE
*!*		lcPrinter=GETPRINTER()
*!*		SET PRINTER TO &lcPrinter
*!*	ENDIF

*!*	SELECT (lnCurArea)

*!*	l_printerdefaultset=.t.

*!*	RETURN

*******************************************************************************
FUNCTION Setdefprn
DECLARE INTEGER GetDefaultPrinter IN WINSPOOL.DRV STRING  @ pszBuffer,;
	INTEGER @ pcchBuffer
nBufsize = 250
cPrinter = REPLICATE(CHR(0), nBufsize)
= GetDefaultPrinter(@cPrinter, @nBufsize)
cPrinter = SUBSTR(cPrinter, 1, AT(CHR(0),cPrinter)-1)
DECLARE INTEGER SetDefaultPrinter IN WINSPOOL.DRV STRING
nResult=SetDefaultPrinter(cPrinter)
RETURN (nResult)
*************************************************
**12/10/09 - re-calculate number of Paper copies if a hold credit atty is listed
*************************************************
FUNCTION ifOnHOLD
PARAMETERS cat_code
LOCAL n_hold AS NUMBER

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

n_hold=0
IF  cat_code="BEBE  3C"
	m.ONHOLD=.F.
	m.Hcomments=""
	RETURN n_hold
ENDIF

c_alias=ALIAS()
SELECT 0
l_AttySt=oCdcnt.sqlpassthrough("SELECT dbo.fn_AttyBillStatus('" + cat_code + "')", "AttySt")
l_hold=AttySt.EXP
SELECT AttySt
USE
IF NOT EMPTY(  c_alias)
	SELECT (c_alias)
ENDIF


n_hold= IIF(l_hold, 1, 0)


RETURN n_hold

***************************************************************************************
FUNCTION lfCheckRefund
LOCAL lnCurArea, lcSQLLine, lloGen, llRetVal
lnCurArea=SELECT()
llRetVal=.F.
lcSQLLine="exec dbo.checkRefundRequest '"+ALLTRIM(pc_clcode)+"', "+ALLTRIM(STR(pn_tag))
IF TYPE("oGen")!="O"
	oGen=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

oCdcnt.sqlpassthrough(lcSQLLine,"viewRefund")
SELECT viewRefund
IF txn_code=80
	llRetVal=.T.
ENDIF
USE IN viewRefund
IF lloGen=.T.
	RELEASE oGen
ENDIF
SELECT (lnCurArea)
RETURN llRetVal

***************************************************************************************
FUNCTION lfgetpgcnt
LOCAL cdir,n1,n2
cdir="t:\softimgs\" + "R_" + ADDBS(ALLTRIM(STR(pn_lrsno)))+;
	ADDBS(PADL(ALLTRIM(STR(pn_tag)), 3, "0"))
n1=ADIR(arts,ADDBS(cdir)+'*.tif')
n2=ADIR(arts,ADDBS(cdir)+'*.txt')
pn_imagecnt=pn_imagecnt+n1+n2
RETURN pn_imagecnt

**********************************

PROCEDURE materialreceiptreport
LOCAL c_cql,oMed
PRIVATE cmatdesc,nmatcount,lcBarcode,c_clientrep

*!*	c_sql="exec [dbo].[litgetmaterialshiptype] "+pc_cl_code+","+ALLTRIM(STR(pn_tag))
*!*	THISFORM.MEDgeneric1(c_sql,"curmatshp")
IF NOT USED('curmatshp')
	RETURN
ENDIF

DO CASE
CASE curmatshp.txn_code=10
	cmatdesc="Radiology Materials"
CASE curmatshp.txn_code=16
	cmatdesc="Pathology Materials"
CASE curmatshp.txn_code=20
	cmatdesc="Photographs/Vidios"
ENDCASE


nmatcount=curmatshp.dcount

IF NOT USED('curmatshp')
	RETURN
ENDIF

oMed=CREATEOBJECT('medgeneric')

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

=ASTACKINFO(a_Stack)
FOR n_cnt = 1 TO ALEN(a_Stack,1)
	IF UPPER("frmrecorddisposition.PRINT_COV") $ UPPER(a_Stack[n_cnt,3])
		l_incoming = .T.
		EXIT
	ENDIF
ENDFOR

c_sql="exec [dbo].[getimagepath] 'ROG','W'"
nr=oCdcnt.sqlpassthrough(c_sql,'currog')
ni=1
DIMENSION rogwritepath[1,2]
rogwritepath[1,1] = 'NONE'
rogwritepath[1,2] = 'NONE'
IF RECCOUNT('currog')>0
	SELECT currog
	SCAN
		DIMENSION rogwritepath[ni,2]
		rogwritepath[ni,1] = ALLTRIM(currog.sname)
		rogwritepath[ni,2] = ALLTRIM(currog.spath)
		ni=ni+1
	ENDSCAN

ENDIF

IF USED('currog')
	USE IN currog
ENDIF

*// only one active write path for rogs
crogspath= rogwritepath[1,2]

*// get ship to
*orderall,requesting,plaintiff,lead,other

c_sql = "exec dbo.getAttyAddressByAtCodeAndAddType "+oCdcnt.cleanstring(pc_platcod)+",'M'"
oCdcnt.sqlpassthrough(c_sql,'curplaintiff')

DO CASE
CASE curmatshp.orderall

	c_sql =	"exec dbo.getparticipatingbyclcode '&pc_clcode.'"
	oCdcnt.sqlpassthrough(c_sql,"curall")
	SELECT curall
	SCAN
		lcBarcode="*"+ALLTRIM(curall.at_code)+"*"
		c_sql = "exec dbo.getAttyAddressByAtCodeAndAddType "+oCdcnt.cleanstring(curall.at_code)+",'M'"
		oCdcnt.sqlpassthrough(c_sql,'attyaddress')
		IF RECCOUNT('attyaddress')>0
			SELECT attyaddress
			cadd1=NVL(attyaddress.add1,'')
			cadd2=NVL(attyaddress.add2,'')
			IF EMPTY(cadd2)
				cadd2=ALLTRIM( attyaddress.city) + ", " + attyaddress.state + " " + attyaddress.zip
				cadd3=''
			ELSE
				cadd3=NVL(ALLTRIM( attyaddress.city) + ", " + attyaddress.state + " " + attyaddress.zip,'')
			ENDIF

			REPORT FORM  materialdelrcpt.frx TO PRINTER NOCONSOLE
			REPORT FORM  materialdelrcpt.frx TO PRINTER NOCONSOLE
			DO materialreceipttoRog
		ENDIF

	ENDSCAN

CASE curmatshp.requesting
	lcBarcode="*"+ALLTRIM(pc_rqatcod)+"*"

	c_sql = "exec dbo.getAttyAddressByAtCodeAndAddType "+oCdcnt.cleanstring(pc_rqatcod)+",'M'"
	oCdcnt.sqlpassthrough(c_sql,'attyaddress')
	IF RECCOUNT('attyaddress')>0
		SELECT attyaddress
		cadd1=NVL(attyaddress.add1,'')
		cadd2=NVL(attyaddress.add2,'')
		IF EMPTY(cadd2)
			cadd2=ALLTRIM( attyaddress.city) + ", " + attyaddress.state + " " + attyaddress.zip
			cadd3=''
		ELSE
			cadd3=NVL(ALLTRIM( attyaddress.city) + ", " + attyaddress.state + " " + attyaddress.zip,'')
		ENDIF
		REPORT FORM  materialdelrcpt.frx TO PRINTER NOCONSOLE
		REPORT FORM  materialdelrcpt.frx TO PRINTER NOCONSOLE
		DO materialreceipttoRog

	ENDIF

CASE curmatshp.plaintiff
	lcBarcode="*"+ALLTRIM(pc_platcod)+"*"

	c_sql = "exec dbo.getAttyAddressByAtCodeAndAddType "+oCdcnt.cleanstring(pc_platcod)+",'M'"
	oCdcnt.sqlpassthrough(c_sql,'attyaddress')

	IF RECCOUNT('attyaddress')>0
		SELECT attyaddress
		cadd1=NVL(attyaddress.add1,'')
		cadd2=NVL(attyaddress.add2,'')
		IF EMPTY(cadd2)
			cadd2=ALLTRIM( attyaddress.city) + ", " + attyaddress.state + " " + attyaddress.zip
			cadd3=''
		ELSE
			cadd3=NVL(ALLTRIM( attyaddress.city) + ", " + attyaddress.state + " " + attyaddress.zip,'')
		ENDIF
		REPORT FORM  materialdelrcpt.frx TO PRINTER NOCONSOLE
		REPORT FORM  materialdelrcpt.frx TO PRINTER NOCONSOLE
		DO materialreceipttoRog

	ENDIF

CASE curmatshp.lead
	c_sql="select * from tblbill with (nolock) where cl_Code='&pc_clcode.' and ISNULL(code,'')='L' and active=1"
	oCdcnt.sqlpassthrough(c_sql,'leadcode')
	IF RECCOUNT('leadcode')>0
		lcBarcode="*"+ALLTRIM(leadcode.at_code)+"*"
		c_sql = "exec dbo.getAttyAddressByAtCodeAndAddType "+oCdcnt.cleanstring(leadcode.at_code)+",'M'"
		oCdcnt.sqlpassthrough(c_sql,'attyaddress')
		IF RECCOUNT('attyaddress')>0
			SELECT attyaddress
			cadd1=NVL(attyaddress.add1,'')
			cadd2=NVL(attyaddress.add2,'')
			IF EMPTY(cadd2)
				cadd2=ALLTRIM( attyaddress.city) + ", " + attyaddress.state + " " + attyaddress.zip
				cadd3=''
			ELSE
				cadd3=NVL(ALLTRIM( attyaddress.city) + ", " + attyaddress.state + " " + attyaddress.zip,'')
			ENDIF
			REPORT FORM  materialdelrcpt.frx TO PRINTER NOCONSOLE
			REPORT FORM  materialdelrcpt.frx TO PRINTER NOCONSOLE
			DO materialreceipttoRog

		ENDIF
	ENDIF


CASE curmatshp.OTHER
*????
ENDCASE

RELEASE oMed

IF USED('curall')
	USE IN curall
ENDIF
IF USED('attyaddress')
	USE IN attyaddress
ENDIF
IF USED('attyname')
	USE IN attyname
ENDIF

**********************************

PROCEDURE materialreceipttoRog
LOCAL cfile, oMed

IF NOT l_incoming
	RETURN
ENDIF

oMed=CREATEOBJECT('medgeneric')

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

cfile="c:\temp\matrecptxyz"
crogtag="3"
n_rog=0

IF FILE(cfile+".tif")
	ERASE (cfile+".tif")
ENDIF

DO tiff_filemaker WITH ;
	'materialdelrcpt.frx',("c:\temp\matrecptxyz")

IF FILE(cfile+".tif")
	cfile=cfile+".tif"

	ctag=PADL(ALLTRIM(STR(pn_tag)),3,'0')
	c_sql="SELECT MAX(nTo) AS max_nto FROM chon_rts..tblRog with (nolock) WHERE nRT="+;
		ALLTRIM(STR(pn_lrsno))+" AND nTag=&crogtag. and ninvtag=&ctag. AND bdeleted=0"

	lr=oCdcnt.sqlpassthrough(c_sql,'viewrog')
	SELECT viewrog

	n_start=IIF(RECCOUNT('viewrog')>0,NVL(viewrog.max_nto,0),0)

	c_sql="insert into chon_rts..tblRog "+;
		"(nrt,ntag,ninvtag,dtcreated,nfrom,nto,screatedby) VALUES ("+;
		ALLTRIM(STR(pn_lrsno))+;
		","+crogtag +;
		","+ALLTRIM(STR(pn_tag))+;
		",getdate()"+;
		","+ALLTRIM(STR(n_start+1))+;
		","+ALLTRIM(STR(n_start+1))+;
		",'"+ ALLTRIM(goApp.CurrentUser.orec.login) +"')"
	lr=oCdcnt.sqlpassthrough(c_sql)

	c_topath=ADDBS(crogspath)+ADDBS(PADL(ALLTRIM(STR(pn_lrsno)),8,'0'))+;
		ADDBS(PADL(ALLTRIM(crogtag),3,'0'))+ADDBS(ctag)

	IF NOT DIRECTORY(c_topath)
		MKDIR (c_topath)
	ENDIF

	c_newfile="P"+PADL(ALLTRIM(STR(n_start+1)),7,'0')+'.tif'
	RENAME (cfile) TO (c_topath+c_newfile)

	IF FILE(cfile)
		ERASE (cfile)
	ENDIF
ENDIF

RELEASE oMed
**************************************************************
FUNCTION BillToAttyName
**************************************************************
LPARAMETERS lcAtty
LOCAL lloGen, lcSQLLine, lnCurArea
lnCurArea=SELECT()
IF TYPE("oGen")!="O"
	oGen=CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

LOCAL oCdcnt
oCdcnt=CREATEOBJECT('cntdataconn')

lcSQLLine="exec [dbo].[GetAttyNameForARReports]  '"+ALLTRIM(fixquote(lcAtty))+"'"
oCdcnt.sqlpassthrough(lcSQLLine,"BTAtty")
SELECT BTAtty
IF EOF()
	RETURN=""
ENDIF


c_Name = ALLT(BTAtty.NewFirst) + " " + ;
	IIF(!EMPTY(ALLTRIM(NVL(BTAtty.NewInit,""))), ALLTRIM(BTAtty.NewInit) + ". ", "") + ;
	ALLT(BTAtty.NewLast)
IF ALLTRIM(UPPER(c_Name))==","
	c_Name=""
ENDIF

SELECT BTAtty
USE
IF lloGen=.T.
	RELEASE oGen
ENDIF

SELECT (lnCurArea)
RETURN c_Name
