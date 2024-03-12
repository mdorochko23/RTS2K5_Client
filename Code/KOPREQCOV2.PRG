************************************************************************
**8/7/09 - Separate KOP Cover page from the rest of a request
**CALLS getmaildate.prg
*************************************************************************
PROCEDURE KOPReqCov2
PARAMETERS lc_IssType, ll_Reprint,ld_txndate,ll_autocov, lc_dept, ln_tag, lc_dname, l_fakeprint, useHITechForm

PRIVATE ldWork, ldtxn11, lcOfc, llUserCtrl, lc_HView, lc_WebAdd, lc_HipaaNote
PRIVATE c_alias AS STRING, lnComply  AS INTEGER, ldBusOnly  AS DATE, l_BaycolFR AS Boolean, ;
	l_PropSubp  AS Boolean, d_Maildate AS DATE, duedate AS DATE, mv_1 AS MEMO, m_gr AS MEMO, c_addition AS STRING

c_alias= SELECT()
STORE "" TO  m_gr, c_addition
mv_1=MV

*--- 01/02/2020 MD #156662
LOCAL lcCourtSafety
lcCourtSafety=SET("safety")
SET SAFETY OFF
*--- 01/02/2020
IF NOT pl_ofcHous
	SELECT court
	INDEX ON court TAG court
	SET ORDER TO court
	lnComply = IIF( SEEK( pc_Court1), gnHold + comply, 10)

	*11/17/2021 WY #255663 (hijack lnComply replace with tblcourt.financialHold)
	*lnComply could be tblcourt.comply + tblcourt.hold (SEEK should always be true) or tblcourt.financialHold
	*qcissue.issuefirst already calls QC_UpdateTagRequest to save tblRequest.reqDueDate,
	*kopReqCov2.StoreDueDate calls StoreRequestDueDate which overwrites tblRequest.reqDueDate 
	IF IsPureTx(pc_Court1) AND c_isstype ="S"
		*LOCAL lnTxFinHold
		*lnTxFinHold = GetFinancialHold(pn_lrsno, ln_tag, pc_Court1)
		*IF lnTxFinHold <> 0
		*	lnComply = lnTxFinHold
		*ENDIF 
		*#255675
		LOCAL lnTxHoldVar
		lnTxHoldDays = GetTxHoldDays (pn_lrsno, ln_tag, pc_Court1)
		IF lnTxHoldDays <> 0
			lnComply = lnTxHoldDays
		ENDIF 
	ENDIF 

ELSE
	SELECT TXCOURT
ENDIF
INDEX ON court TAG court
*--- 01/02/2020 MD #156662
SET SAFETY &lcCourtSafety
*--- 01/02/2020

IF pl_autofax
	ll_Reprint = .F.
ENDIF

IF NOT pl_ofcHous
**  remove holding period for reissues
	IF pl_Reissue OR (lc_IssType = "A" AND pc_Litcode == "3  ")
		gnHold = 0
	ENDIF
	ldBusOnly=d_today
ELSE
	IF NOT pl_1st_Req &&-autofax
		ldtxn11=CTOD(timesheet.Txn_date)
	ENDIF
***texas office calculations
	ldBusOnly = gfDtSkip( IIF( pl_1st_Req, d_today, ldtxn11), IIF( pc_TxCtTyp = "FED", 16, 20))
ENDIF

SELECT (c_alias)
SELECT MASTER

IF TYPE( "lc_IssType")<>"C"
	lc_IssType = "S"
ENDIF

llFromRev=pl_FromRev


IF NOT pl_ofcHous
	IF pl_MichCrt
		ldBusOnly = MIDueDat( IIF( ll_Reprint, ld_txndate + 1, d_today + 1))
	ENDIF

	IF pl_NJSub OR pl_cambAsb OR pl_RisPCCP &&OR pl_ILcook

		ldBusOnly = IIF(ll_Reprint, ld_txndate, d_today)
&&6/29/2011- add NJ 14 bus days

		DO CASE
**#49176 use 18 calendar days for Il-Cook
*CASE pl_ILcook
*ln_Count=17 && 1/16/2013 added IL Cook County subps
		CASE pl_RisPCCP  &&01/15/16- Edited count to 4 for the RISPPPCP
			ln_Count=4
		CASE pl_cambAsb
			ln_Count=8
		OTHERWISE &&pl_NJSub
			ln_Count=13
		ENDCASE
		IF  pl_NJSub &&3/11/14- use calendar days insteda of busness per Liz
			ldBusOnly = ldBusOnly + 14
			ldBusOnly = gfChkDat( ldBusOnly, .F., .F.)

		ELSE

			FOR i =0 TO ln_Count
				ldBusOnly = ldBusOnly + 1
				ldBusOnly = gfChkDat( ldBusOnly, .F., .F.)

			NEXT
		ENDIF


	ENDIF


ENDIF
IF  pl_ofcHous
**texas
	IF lc_IssType = "S"
		d_Maildate = ldBusOnly
		duedate = gfChkDat( ldBusOnly + 20, .F., .F.)
	ELSE
		d_Maildate = CTOD(timesheet.Txn_date)
*duedate = ldBusOnly
		duedate = IIF( lc_IssType="A", ldBusOnly, duedate)
	ENDIF
ENDIF

pd_RpsPrint=d_null

IF NOT pl_ofcHous
	d_Maildate=getmaildate(pd_ReqMail, ldBusOnly, d_today, gnHold, ld_txndate,llFromRev, lc_IssType ,pl_1st_Req, ll_Reprint)
	duedate=getduedate(d_Maildate,  d_today ,lc_IssType, ldBusOnly, lnComply, gnHold, ll_Reprint, pl_1st_Req)
ENDIF
** remove holding period for Reissues
IF pl_Reissue AND pl_1st_Req
	d_Maildate = d_today
	duedate = gfChkDat( d_today +10, .F., .F.)
	dduedate = duedate
ENDIF
pd_ReqMail=d_Maildate
**07/11/2013- use new release date (21)
**03/12/2013- added for RPS
* : "HoldPrint" Project.
IF  pl_1st_Req AND  gnHold<>0  && 07/18/13

	IF PC_ISSTYPE ='S'  OR ( PC_ISSTYPE='A'  AND pl_RisPCCP )

		IF TYPE('pd_RpsPrint')="U" OR EMPTY(NVL(pd_RpsPrint,''))
			DO CASE
			CASE TYPE("d_Maildate")="D"
				pd_RpsPrint =gfChkDat(d_Maildate+1, .F., .F.)
			CASE TYPE("d_Maildate")="T"
				pd_RpsPrint =TTOD(gfChkDat(d_Maildate+1, .F., .F.) )
			OTHERWISE
				pd_RpsPrint=CTOD(gfChkDat(d_Maildate+1, .F., .F.) )
			ENDCASE
		ENDIF

	ENDIF
ENDIF
*!*	**03/12/2013- added for RPS

ldWork = duedate
pd_DueDate = ldWork

* --  01/06/2020 #156721 MD Added hitech Check
* --  IF NOT ll_autocov AND NOT  pl_StopPrtIss
IF NOT ll_autocov AND NOT  pl_StopPrtIss AND NVL(useHITechForm,.F.)=.F.
	duedate  =goApp.OpenForm("request.frmDueDate", "M", pd_DueDate, pd_DueDate, "Due Date")

ENDIF
IF NOT pl_1st_Req
	pd_DueDate= GetReqDueDate(pc_clcode, ln_tag, IIF(TYPE("duedate")="T", TTOD(duedate),duedate))
ENDIF

IF ldWork <> duedate                            && Has been changed by a user
	ldDueDate = duedate
	pd_DueDate=duedate
ENDIF
** store due date for 1st req only or retriev a stored one for all other requests
IF pl_1st_Req
	DO StoreDueDate WITH  pd_DueDate, pc_clcode, ln_tag
ENDIF

IF TYPE('pc_deptype') <>'C'
	pc_deptype= UPPER( LEFT( pc_MailID, 1))
	IF NOT INLIST( pc_deptype, "H", "E", "A", "D")
		pc_deptype = "D"
	ENDIF
ENDIF

******************************** Non-programmed subps #51529  use a special cover page- a holder page***
IF  pl_noSform AND courtdtl(pc_Court1)
	STORE "" TO mv2
	mv2=NoRqLtr(1)
	mv_1=mv_1+mv2
	RETURN  mv_1
ENDIF
********************************Non-programmed subps


IF pc_deptype = "H"
	c_attn=""
	IF NOT EMPTY(lc_dept)
** This is filled in only if hospital!!
		DO CASE
		CASE lc_dept == "E"
			c_attn = "ECHOCARDIOGRAM"
			STORE  "ECHO" TO TheInfo, TheInfo2
		CASE lc_dept == "R"
			c_attn = "RADIOLOGY"
			STORE  "RAD" TO TheInfo, TheInfo2
		CASE lc_dept == "P"
			c_attn = "PATHOLOGY"
			STORE  "PATH" TO TheInfo, TheInfo2
		CASE lc_dept == "B"
			c_attn =  "BILLING"
			STORE  "BILLS" TO TheInfo, TheInfo2
		CASE lc_dept == "C"
			c_attn =  "CARDIAC CATHS"
			STORE  "CATH" TO TheInfo, TheInfo2
		OTHERWISE
			c_attn = "MEDICAL RECORDS"
			STORE  "MED" TO TheInfo, TheInfo2
		ENDCASE
		szattn = "ATTN: " + c_attn + " DEPARTMENT"
	ELSE
		szattn = ""
		STORE  "MED" TO TheInfo, TheInfo2
	ENDIF                                        && not empty lc_dept
ELSE
	TheInfo = "OTHER"
	TheInfo2 = "MED"
	szattn = ""
ENDIF                                           && pc_deptype = H
&&07/17/2012 -added rolodex's attn line
szattn=IIF(EMPTY(ALLTRIM(pc_MAttn)),szattn , ALLTRIM(UPPER(pc_MAttn)))

IF NOT EMPTY(pc_maiden1)                        && AND UPPER(a.Litigation) == "I  "
	szAKA = "A.K.A.: " + TRIM( pc_maiden1)
ELSE
	szAKA = ""
ENDIF

&&only for dd2 hipaa-start
STORE "" TO lc_HipaaNote, lc_HView, lc_WebAdd
IF pl_DDrug2
	lc_HView = "** This order can be viewed at:"
	lc_WebAdd = " http:/" + "/www.fenphen.verilaw.com/pto/PTO2390.pdf."
	lc_HipaaNote = " approved by the US District Court for the Eastern District "     +  ;
		"of PA, MDL Docket No. 1203, Civil Action #99-20593, Pretrial Order #2930** "   +  ;
		"(Para.2)"
ENDIF
&& dd2 hipaa -end

&&EF 12/14/01 Phila-Texas authorizations vs. Texas-Texas authorizations.

IF pl_TxAbex AND lc_IssType <> "S" AND NOT pl_ofcHous
	DO PrintGroup WITH mv_1, "TX_AuthoCov"         &&Phila-TX Autho cases
ELSE
	IF pl_ofcHous AND lc_IssType = "S"
		DO PrintGroup WITH mv_1, "TX_SubpCov"       &&TX Subp
	ENDIF
	IF pl_ofcHous AND lc_IssType = "A"
		DO PrintGroup WITH mv_1, "TX_AuthCovT"      && TX Autho
	ENDIF

	IF NOT pl_ofcHous AND NOT pl_TxAbex

		IF TYPE('pd_IssDte')<>'D'
			pd_IssDte=DATE()
		ENDIF
		dIssue=IIF(pl_zicam, pd_IssDte, ld_txndate)
		sAddition = IIF( (d_Maildate>d_today OR dIssue>d_today), "H", "")

*--	12/13/2019 #146658 MD print hitech form
*!*			DO PrintGroup WITH mv_1, ;
*!*				IIF( dIssue >= {10/19/2000}, ;
*!*				sAddition + "RequestCover", "RequestCovold")

		IF NVL(useHITechForm,.F.)=.T.
			DO PrintGroup WITH mv_1,"HiTechCovP"
		ELSE
			DO PrintGroup WITH mv_1,IIF( dIssue >= {10/19/2000}, sAddition + "RequestCover", "RequestCovold")
		ENDIF 
		
	ENDIF
ENDIF

c_mark=""

*!*	DO CASE

*!*	CASE pl_ofcMD OR pl_ofcPgh OR pl_OfcKop

*!*		l_GetRps= Acdamnumber (pc_amgr_id)
*!*		IF l_GetRps
*!*			c_offlocation=IIF(ISNULL(LitRps.RpsOffCode), 'P', LitRps.RpsOffCode)
*!*			IF EMPTY(ALLTRIM(c_offlocation))
*!*				c_offlocation=pc_Offcode
*!*			ENDIF
*!*		ENDIF
c_mark=ALLTRIM(UPPER(NVL(pc_Litcode,"")))+"."+ALLTRIM(UPPER(NVL(pc_Initials,"")))
*!*	OTHERWISE
*!*		c_offlocation=pc_Offcode
*!*	ENDCASE

**08/22/2017: New ACD Lines #67249
c_offlocation=RpsLoc()
IF EMPTY(ALLTRIM(c_offlocation))
	c_offlocation=pc_Offcode
ENDIF

DO PrintField WITH mv_1, "SpecMark", c_mark
**EF 07/29/2011 - ADDED COURTCODE TO A COVER LETTER
c_court= IIF((!EMPTY(ALLTRIM(pc_c1name)) AND PC_ISSTYPE="S"), ALLTRIM(pc_c1name), "")
DO PrintField WITH mv_1, "CourtCode", c_court
**MRC phone # 2/15/14
&&07/19/17 - Arizona subps for CA office
&&03/10/17 -#58943
IF (pc_Litcode = "A" AND pc_area    = "WEITZ CAL") OR  (pl_CAinKOP AND PC_ISSTYPE="S")
	DO PrintField WITH mv_1, "Loc", "M"
ELSE
	DO PrintField WITH mv_1, "Loc", IIF(pc_Litcode="ZOL", "G", c_offlocation)
ENDIF

IF pl_ofcHous
	DO PrintField WITH mv_1, "DueDate", DTOC( duedate)
ELSE

**USE pd_DueDate 8/20/09
	DO PrintField WITH mv_1, "DueDate",	DTOC(pd_DueDate)
ENDIF

IF EMPTY(szEdtReq)
	szEdtReq= GetSpecInsForTag(IIF( pl_autofax, tag2req, ln_tag))
ENDIF


DO PrintField WITH mv_1, "Info", TheInfo
DO PrintField WITH mv_1, "RequestCode", IIF(lc_IssType="S", "SUBP", "AUTH")
**10/03/2011 -added "UsedVerb"
DO PrintField WITH mv_1, "UsedVerb", IIF(lc_IssType="S", "SUBP", "AUTH")

*DO PrintField WITH mv_1, "InfoText",szEdtReq
DO PrintField WITH mv_1, "InfoText", ;
	STRTRAN( STRTRAN( szEdtReq, CHR(13), " "), CHR(10), "")
* 01/30/04 additions for K O P dietdrug2's req cover pages
IF NOT pl_ofcHous
	DO PrintField WITH mv_1, "HipaaNote", lc_HipaaNote
	DO PrintField WITH mv_1, "HView", lc_HView
	DO PrintField WITH mv_1, "WebAdd", lc_WebAdd
ENDIF


IF NOT pl_1st_Req AND NOT l_fakeprint
	IF pl_autofax OR l_Prt2Req OR l_Fax2Req
&&11/16/09 REMOVE FROM A COVER PAGE PER ALEC
		DO PrintField WITH mv_1, "SecondRequest", "0"
		DO PrintField WITH mv_1, "SecRequest", "0"
		IF pl_KOPVer
			m_gr=PrtGroup()
			mv_1=mv_1 + m_gr
		ENDIF
	ELSE
		DO PrintField WITH mv_1, "SecondRequest", "0"
		DO PrintField WITH mv_1, "SecRequest", "0"
		IF pl_KOPVer
			m_gr=PrtGroup()
			mv_1=mv_1 + m_gr
		ENDIF
	ENDIF
ELSE
	DO PrintField WITH mv_1, "SecondRequest", "0"
	DO PrintField WITH mv_1, "SecRequest", "0"
	IF pl_KOPVer
		m_gr=PrtGroup()
		mv_1=mv_1 + m_gr
	ENDIF
ENDIF

DO PrintGroup WITH mv_1, "Control"
mdate=d_Maildate

**07/11/2013 - added new release daet for KOP Hold Requests
DO newreleasedt WITH d_Maildate, gnHold
**07/11/2013 - added new reelase daet for KOP Hold Requests

IF ( pc_c1name = "MD-BaltimoCity" AND lc_IssType="S" AND  pl_1st_Req)				  &&4/16/15- add one date to MD Balt cases per Liz/Alec


	IF TYPE('pd_RpsPrint')="T"
		dthisdate =TTOD(pd_RpsPrint)
	ENDIF
	IF TYPE('pd_RpsPrint')="C"
		dthisdate =CTOD(pd_RpsPrint)
	ENDIF
	IF TYPE('pd_RpsPrint')="U"
		dthisdate=DATE()
	ENDIF
	IF TYPE('pd_RpsPrint')="D"
		dthisdate=pd_RpsPrint
	ENDIF
	dthisdate = gfChkDat(dthisdate + 1, .F., .F.)
	DO PrintField WITH mv_1, "Date", DTOC(dthisdate)

ELSE
    * --- 08/16/2018 MD #98879 added USDC subpoena for Abilify
    IF ALLTRIM(UPPER(pc_litcode))=="ABL" AND ALLTRIM(UPPER(pc_area))=="MDL" AND lc_IssType="S"
  	 * do not print controlDate for the ABL
  	 DO PrintField WITH mv_1, "Date", ""
	ELSE 
    	DO PrintField WITH mv_1, "Date", DTOC( pd_RpsPrint)
	ENDIF 
	
ENDIF

*DO PrintField WITH mv_1, "Date", DTOC( d_Maildate)
DO PrintField WITH mv_1, "LrsNo", pc_lrsno
DO PrintField WITH mv_1, "Tag", STR( IIF( pl_autofax, tag2req, ln_tag))


DO PrintGroup WITH mv_1, "Deponent"


**05/21/2012- print deponent's name on a KOP cover page insted of txn 11 line ( per Alec)

*----------------- Check the dept code data -can be in any columns below--------------------------------
LOCAL lnXXX, lcField
lcField=""
SELECT pc_depofile
=AFIELDS(laDeptFlds)
FOR lnXXX=1 TO ALEN(laDeptFlds,1)
	IF ALLTRIM(UPPER(laDeptFlds[lnXXX,1]))=="DEPT_CODE"
		lcField="DEPT_CODE"
	ENDIF
	IF ALLTRIM(UPPER(laDeptFlds[lnXXX,1]))=="DEPTCODE"
		lcField="DEPTCODE"
	ENDIF
	IF ALLTRIM(UPPER(laDeptFlds[lnXXX,1]))=="CODE"
		lcField="CODE"
	ENDIF
NEXT

c_addition= getdescript(NVL(&lcField,'Z'))

c_dep=DepToPrint (ALLTRIM(NVL(pc_depofile.NAME,lc_dname)))

DO PrintField WITH mv_1, "Name", c_dep  + IIF(pc_deptype = "H"  ,"",c_addition) &&lc_dname
**05/07/2012- print deponent's name on a KOP cover page insted of txn 11 line ( per Alec)
DO PrintField WITH mv_1, "Addr", ;
	IIF(EMPTY(ALLTRIM(pc_depofile.add2)), ALLTRIM(pc_depofile.add1), ALLTRIM(pc_depofile.add1) + CHR(13) + ALLTRIM(pc_depofile.add2))
DO PrintField WITH mv_1, "City", ALLTRIM(pc_depofile.city)
DO PrintField WITH mv_1, "State", ALLTRIM(pc_depofile.state)
DO PrintField WITH mv_1, "Zip", IIF(ALLTRIM(pc_depofile.zip)='00000','', ALLTRIM(pc_depofile.zip))
DO PrintField WITH mv_1, "Extra", IIF(ISNULL(szattn),"",szattn)
DO PrintGroup WITH mv_1, "Plaintiff"

DO PrintField WITH mv_1, "FirstName", pc_plnam
DO PrintField WITH mv_1, "MidInitial", ""
DO PrintField WITH mv_1, "LastName", ""
DO PrintField WITH mv_1, "Addr1", pc_pladdr1
DO PrintField WITH mv_1, "Addr2", pc_pladdr2
IF TYPE('pd_pldob')<>"C"
	pd_pldob=DTOC(pd_pldob)
ENDIF
IF TYPE('pd_pldod')<>"C"
	pd_pldod=DTOC(pd_pldod)
ENDIF

DO PrintField WITH mv_1, "BirthDate", LEFT(pd_pldob,10)
DO PrintField WITH mv_1, "SSN", ALLT( pc_plssn)
DO PrintField WITH mv_1, "DeathDate",  LEFT(pd_pldod,10)
DO PrintField WITH mv_1, "Extra", szAKA
IF NOT EMPTY(c_alias)
	SELECT (c_alias)
ENDIF
RETURN mv_1



**********************************************************************************
**8/20/09 ** Store request's due date
**********************************************************************************
PROCEDURE StoreDueDate
PARAMETERS d_Due, c_cl, n_tag
LOCAL o_med AS OBJECT, c_sql AS STRING, l_recupdt AS Boolean
o_med = CREATEOBJ("generic.medgeneric")
l_recupdt=.F.
c_sql = " exec dbo.StoreRequestDueDate '" +fixquote(c_cl) +"','" + STR(n_tag) + "','" +DTOC(d_Due) + "'"

l_recupdt= o_med.sqlexecute (c_sql,"")
IF NOT l_recupdt
	gfmessage("Note: The Request's Due Date was not stored.")
ENDIF
RELEASE o_med
RETURN
**********************************************************************************
