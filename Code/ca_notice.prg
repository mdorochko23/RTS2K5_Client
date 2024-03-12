PROCEDURE CA_Notice
******************************************************************************
* CA_Notice.prg - new Procedures for end-of-day printing of California notices
*
* History :
* Date     Name  Comment
* ---------------------------------------------------------------------------
**EF 03/21/12 - Use new USDC forms for the CA (share forms with KOP) issues
**EF 08/21/09 - Added  a param to defprep
**EF 08/20/09 - The new two POS pages are only for  pl_BBAsb (BB cases)
**EF 08/18/09 - remove a second page (POS)for non BB cases
**EF 08/03/09 - split CA POS into two pages
**EF 06/29/09 - Added subpoena printing for the BB/Non generic
**EF 04/23/08- 	Switch Pasadena Office to Oakland
**EF 08/09/07 -	Split the big def notice jobs into smaller ones.
**EF 09/15/06 -      Synch with the latest FoxPro: added spec data to the BB notices
**EF 3/29/06  -       added to the VFP project
***** conversion******************************************************************
* 03/29/06 EF    changed the direct dial phone to Nick's on the B&B notices per Liz D.
* 12/19/05 EF    Change price on the Pasadena notices.
* 06/15/05 DMA   Recreate and clear the temporary work file before each run
* 10/26/04 EF    Add a "direct mail" text to plaintiff and co-def notices
* 09/21/04 EF    Fix a bug in the "Print Cover for Plaintiff Notice" module
* 08/02/04 DMA   Add titles to all SendMsg windows
* 07/22/04 DMA   Remove GetInfo routine; additional cleanup
* 07/01/04 DMA   Pass parm by value to pDefNotc to prevent error.
* 06/01/04 DMA   During plaintiff notice production, eliminate full duplicate
*                copy of package for B&B Asbestos. Replace with additional
*                copy of Proof of Service documents only. [Per Melissa Ashley]
* 05/25/04 DMA   Check for TAMaster use before setting printed flags
*                Switch to overall use of long plaintiff name
* 05/10/04 DMA   Initial use of global variables
* 05/04/04 DMA   Use new-format RCA Number on notices
* 04/30/04 DMA   Replace PSCases with CANType for add'l efficiency
*                Convert DO WHILE loops to SCAN where possible
* 04/29/04 DMA   Convert CANType.dbf to a permanent file w/DataDir reference
* 03/25/04 DMA   Change hard-coded name of Berry & Berry lead attorney
* 08/01/03 DMA   Correct record-locking while analyzing for codef notices
* 07/30/03 EF    Edit price on Plaintiff's notice for Pasadena GW cases
* 06/06/03 DMA   Additional readability improvements
*                CADepSubp changed to CADepSub; no logic changes
* 04/23/03 DMA   Minor readability changes and comments
* 10/01/01 EF    Add option to reprint only codefendant notices
* 09/12/01 EF    3-char. litigation code
* 07/03/01 EF    Add call of unarnot.prg. ( Un-archive notices)
* 03/01/01 DMA   Remove old glY2K references
* 09/18/00 EF    Added notices for a WCAB subpoena
* 07/12/00 EF    Print 'Berry & Berry' plaintiff notices twice.
* 03/28/00 EF    Release notice for 'C'/'P' subps.
* 10/20/99 DMA   Note: Indexes on PSNotice.DBF which use DTOC( Txn_date)
*                do NOT have to be changed to DTOS for Y2K, because work
*                is always done for a single day's notices. If the program
*                should be changed in future to permit working on a date range
*                of notices, then the index change will be required.
* 06/21/99 TomC  Modified for Y2K compliance
*   /  /   RIZ   Initial release
* ---------------------------------------------------------------------------
*
* PSNotice.DBF
*   indexes required
*
*    ca_count: All unprinted notices for each case on txn_date
*      DTOC( txn_date) + cl_code FOR NOT printed
*
*    ca_hscount: All unprinted hand-serves for each case on txn_date
*      DTOC( txn_date) + cl_code FOR NOT printed AND hs_notice
*
*    ca_cases: One entry/case for cases w/unprinted notices on txn_date
*      DTOC( txn_date) + cl_code UNIQUE FOR NOT printed
*
*    ca_hscases: One entry/case for cases w/unprinted hand-serves on txn_date
*      DTOC( txn_date) + cl_code UNIQUE FOR NOT printed AND hs_notice
*
******************************************************************************
PARAMETERS gcOffLoc, rtReprint, printDate
*-- 11/13/2020 MD added RTreprint #186387
IF PCOUNT()<2
   rtReprint=0
ENDIF 
rtReprint =NVL(rtReprint,0)
IF TYPE("rtReprint")<>"N"
	rtReprint=convertToNum(rtReprint)
ENDIF 
IF PCOUNT()<3
   printDate={01/01/1970}
ENDIF 
*-- 11/13/2020 MD added RTreprint #186387

pl_CANotc = .T.
pl_CAVer =.T.
gfOffice=IIF(gcOffLoc="S", "Pasadena","Oakland")
PUBLIC mv, mclass, mgroup, mdep, mid, mtag, nLitType, c_LitType, l_OnlyCo, PL_HSONLY
mclass = "Notice"
mgroup = "1"
PRIVATE mv_release, dbCANotice, dbTAMaster, dbTAAtty, ldRunDate, llHSOnly, ;
	c_msgline1, l_gotPS
c_msgline1 = ""
IF TYPE( "mv") == "U"
	mv_release = .T.
	PUBLIC mv
ELSE
	mv_release = .F.
ENDIF
bNotcall=.F.
pc_BatchRq=""
pl_SkipBatchPRT=.T.
SET PROCEDURE TO ta_lib ADDITIVE
*ldRunDate = d_today
** nLitType = 1 -> Generate notices for Civil Lit. cases only
** nLitType = 2 -> Generate notices for non-Civil Lit. cases only
** nLitType = 3 -> Generate notices for all litigations
*nLitType = 1
*lnContinue = 1
** lnCoDefNot = 0 -> Reprint all notices
** lnCoDefNot = 1 -> Reprint only Codefendant Notices
*l_OnlyCo = .F.
*DO RunCANot.spr
*-- 11/12/2020 MD added RTreprint/PrintDate
IF NVL(rtReprint,0)>0
	ldRunDate=printDate
	nLitType = 3
ELSE 	
	ldRunDate=.NULL.
	ldRunDate=goApp.OpenForm("case.frmruncanot", "M", gcOffLoc, gcOffLoc)
	l_gotPS=.F.
ENDIF 

IF ISNULL(ldRunDate)
	pl_CANotc = .F.
	RETURN
ENDIF

_SCREEN.MOUSEPOINTER=11
oMed = CREATEOBJECT("generic.medgeneric")
*-- 11/13/2020 MD added RTReprint #186387
l_CANot=GetCANotic(ldRunDate,rtReprint)

IF NOT l_CANot
	gfmessage( "Cannot get CA Notice file")
	RETURN
ENDIF

DO CASE
CASE nLitType = 1
	c_LitType = 'CANotice.litigation == "C  "'

CASE nLitType = 2
	c_LitType = 'CANotice.litigation <> "C  "'

CASE nLitType = 3
	c_LitType = ' canotice.ACTIVE '

ENDCASE
* 10/1/01 Reprint only the Codefendant notices
IF l_OnlyCo
* Reset the "Printed" flag for the notices to be reprinted
** Txn_Date index is by DESCENDING DTOC( Txn_Date)
	SELECT CANotice

	SET ORDER TO Txn_Date
	IF TYPE('ldRunDate')="C"
	ldRunDate =CTOD(ldRunDate)
	ENDIF
	
	IF SEEK( DTOC( ldRunDate))
		SCAN WHILE CANotice.Txn_Date = ldRunDate
			DO WHILE NOT RLOCK()
			ENDDO
			REPLACE CANotice.Printed WITH .F.
			UNLOCK
		ENDSCAN
	ENDIF

ENDIF
_SCREEN.MOUSEPOINTER=0

lc_message = "Hand serve only?"
o_message = CREATEOBJECT('rts_message_yes_no',lc_message)
o_message.SHOW
l_Confirm=IIF(o_message.exit_mode="YES",.T.,.F.)
o_message.RELEASE
PL_HSONLY=.F.
IF  l_Confirm
	PL_HSONLY = l_Confirm
* Choose appropriate non-unique index
	pc_CntNot = IIF( PL_HSONLY, "ca_hscount", "ca_count")
* Choose matching index which is unique for date/case combos
	pc_CaseNot = IIF( PL_HSONLY, "ca_hscases", "ca_cases")
ENDIF

SELECT CANotice
SET ORDER TO (pc_CntNot)
*f_CANType=IIF(gcOffLoc="S",goApp.psdatapath,goApp.cadatapath)	+ "\CANType.dbf"

*-- 11/13/2020 MD added check for rtReprint #186387
IF NVL( rtReprint,0)=0
	f_CANType=IIF(gcOffLoc="S","t:\vfpfree\pasadena\rts\","t:\vfpfree\oakland\rts\")	+ "CANType.dbf"
ELSE 
	f_CANType="c:\temp\CANType.dbf"
ENDIF 
*-- 11/13/2020 MD #186387

SELECT CANotice
SET ORDER TO Txn_Date
* Confirm that there is at least one notice for the specified date.
llReady = .F.
IF TYPE('ldRunDate')="C"
	ldRunDate =CTOD(ldRunDate)
ENDIF
IF SEEK( DTOC( ldRunDate))
	SCAN WHILE Txn_Date = ldRunDate
		llReady = .T.
		EXIT
	ENDSCAN
ENDIF
******************************************************************************
IF llReady
	LOCAL o_message1 AS OBJECT
	lc_message = "Do you want to print notices now?"
	o_message1 = CREATEOBJECT('rts_message_yes_no',lc_message)
	o_message1.SHOW
	l_Confirm=IIF(o_message1.exit_mode="YES",.T.,.F.)
	o_message1.RELEASE
	IF  l_Confirm

		DO NotcLoop WITH rtReprint

	ENDIF
ENDIF
IF USED( "CANType")
	SELECT CANType
	USE
ENDIF
IF USED( "Subpoena")
	SELECT Subpoena
	USE
ENDIF
IF USED( "Notcdata")
	SELECT Notcdata
	USE
ENDIF
SELECT CANotice
USE
IF mv_release
	RELEASE mv
ENDIF

WAIT CLEAR
RETURN

*---------------------------------------------------------------

PROCEDURE NotcLoop
LPARAMETERS lrsNo2Print
*-- 11/13/2020 MD added RTreprint #186387
IF PCOUNT()<1
   lrsNo2Print=0
ENDIF 
lrsNo2Print=NVL(lrsNo2Print,0)
IF TYPE("lrsNo2Print")<>"N"
	lrsNo2Print=convertToNum(lrsNo2Print)
ENDIF 
*-- 11/13/2020 MD added RTreprint #186387

* Primary processing loop for end-of-day noticing
PRIVATE lnMax1, lnCur1
**
* dbCANotice is the open copy of PSNotice indexed non-uniquely for date + case
*********************************************************************
*
* 1) Print "special" notices for civil deposition and personal
*    appearance requests, via CANType routine
*
*********************************************************************
f_subpoena=IIF(gcOffLoc="S",goApp.psdatapath,goApp.cadatapath)	+ "\Subpoena"
f_decl=IIF(gcOffLoc="S",goApp.psdatapath,goApp.cadatapath)	+ "\Decl"
IF  NOT l_OnlyCo

	WAIT WINDOW "Checking for civil deposition/appearance notices." NOWAIT NOCLEAR

	IF NOT USED ('SUBPOENA')
		SELECT 0
		USE ( f_subpoena) ORDER cltag
	ELSE
		SELECT Subpoena
	ENDIF
	llDefault = .T.

	IF USED("CANType")
		SELECT CANType
		USE
	ENDIF
	IF TYPE('ldRunDate')="C"
	ldRunDate =CTOD(ldRunDate)
	ENDIF
	ON ERROR DO GET_Error WITH ERROR()
	COPY STRU TO (f_CANType) WITH CDX
	SELECT DISTINCT CANotice.Cl_Code,CANotice.TAG, ;
	CANotice.Txn_Date,CANotice.due_date, ;
	CANotice.DESCRIPT, ;
	CANotice.Rq_at_code, CANotice.User_code, ;
	CANotice.Mailid_no, CANotice.TYPE, ;
	CANotice.Printed, CANotice.hs_subpoen, ;
	CANotice.hs_notice, CANotice.litigation ;
	FROM CANotice, Subpoena;
	INTO TABLE ( f_CANType) ;
	WHERE Txn_Date = ldRunDate ;
	AND CANotice.TYPE <> "A" ;
	AND NOT Printed ;
	AND Subpoena.Cl_Code = CANotice.Cl_Code ;
	AND Subpoena.TAG = CANotice.TAG ;
	AND &c_LitType.
			
	WAIT CLEAR
	
	IF _TALLY > 0
		WAIT WINDOW "Printing civil deposition/appearance notices." NOWAIT NOCLEAR
		*-- 11/13/2020 MD added second parameter #186387
		DO CACivilN WITH PL_HSONLY, lrsNo2Print
	ELSE
		SELECT CANType
		USE
	ENDIF

	SELECT Subpoena


ENDIF &&1/24/08 - do not print civil with co-def notices
*********************************************************************
*
* 2) Print plaintiff notices
***4/23/08 -treat "S" cases as "C" : Pasadena office closed
*********************************************************************
WAIT WINDOW "Checking for regular notices." NOWAIT NOCLEAR

IF TYPE('ldRunDate')="C"
	ldRunDate =CTOD(ldRunDate)
ENDIF

IF NOT USED ('CANOTICE')
	*--- 01/05/2022 MD #260575 added second parameter
	l_CANot=GetCANotic(ldRunDate,lrsNo2Print)
	IF NOT l_CANot
		gfmessage('Cannot get the Notice file. Try again..or contact the IT dept')
		RETURN

	ENDIF
ENDIF



SELECT * FROM CANotice INTO TABLE (f_CANType) ;
	WHERE Txn_Date = ldRunDate 	AND NOT Printed 	AND LRS_NOCODE<>"P" 	AND &c_LitType. 

SELECT CANType
USE
USE ( f_CANType) IN 0 EXCL
LOCAL oMstr AS OBJECT
oMstr=CREATEOBJECT("medMaster")
SELECT CANType

INDEX ON DTOC( Txn_Date) + Cl_Code ;
	UNIQUE FOR NOT Printed TAG ca_cases
INDEX ON DTOC( Txn_Date) + Cl_Code ;
	UNIQUE FOR NOT Printed AND hs_notice TAG ca_hscases
USE
IF l_OnlyCo
* Print only the codefendant packages
	USE (f_CANType) IN 0
	SELECT CANType
ELSE
* Print both plaintiff notices and codefendant packages
	USE (f_CANType) IN 0
	SELECT CANType
	pc_CaseNot = IIF( PL_HSONLY, "ca_hscases", "ca_cases")
	SET ORDER TO (pc_CaseNot)
* These indexes are unique -- only one record per case/date combo
	IF TYPE('ldRunDate')="C"
	ldRunDate =CTOD(ldRunDate)
	ENDIF
	SEEK DTOC( ldRunDate)
	COUNT FOR Txn_Date = ldRunDate TO lnMax1
	lnCur1 = 0
	SET NEAR ON
	SEEK DTOC( ldRunDate)
* SQL Select above took care of date-matching; don't repeat in SCAN
	SCAN
		gcCl_code = CANType.Cl_Code
		gnTag = CANType.TAG
		pn_Tag=CANType.TAG && 03/25/2021 MD To make sure the public is set correctly
		
		SELECT 0
		l_gotMasterid=oMstr.sqlexecute("SELECT DBO.fn_GetID_tblmaster('" + fixquote(CANType.Cl_Code) + "')", "MasterID")
		IF  NOT l_gotMasterid
			gfmessage( "Data processing error. Try again or contact IT dept.")
			RETURN
		ENDIF
		oMstr.getitem(Masterid.EXP)

		SELECT MASTER
		pl_GotCase = .F.
		DO gfGetCas WITH .T.
		IF USED('Court')
			SELECT Court
			USE
		ENDIF
		DO GetCACourt WITH ALLTRIM(MASTER.court)



		SELECT CANType
		IF ( pc_LitCode = "C  ") AND ( CANType.TYPE = "A") AND gcOffLoc="C"
** Civil Litigation Authorization notices print last
			LOOP
		ENDIF
** Plaintiff notices case by case
		mv = ""
		mclass = "Notice"
		mgroup = "1"
		*-- 01/20/2021 MD #218721 sent reprint notices to RPS16
		IF lrsNo2Print>0
			mclass = "reprintNotice"
		ENDIF		
		*------------------------------------------------ 
		DO PltfNotc WITH CANType.Cl_Code,lrsNo2Print
* 06/01/04 DMA PltfNotc now prints second copy of proofs of service
*              for Berry & Berry Asbestos requests
		*---------------------------------------------
		*----- 01/06/2021 print all docs in one set 
		llDefault = .T.
		mclass = "Notice"
		mgroup = "1"
		*-- 01/20/2021 MD #218721 sent reprint notices to RPS16
		IF lrsNo2Print>0
			mclass = "reprintNotice"
		ENDIF
		*------------------------------------------------ 
		IF NOT EMPTY( mv)
			DO prtenqa WITH mv, mclass, mgroup, ""
		ENDIF
		*---------------------------------------------
		*----- 01/06/2021
		lnCur1 = lnCur1 + 1
		DO gfClrCas
		SELECT court
		USE
		SELECT CANType
	ENDSCAN
ENDIF

*********************************************************************
*
* 3) Print defense notices
*
*********************************************************************
**8/21/09 Add a parameter
DO DefPrep WITH nLitType
*-- 01/21/2022 MD #262708 added at_code to pass to prtenqa2
LOCAL lcDNoticeAtty
pl_ofcOak=.T.  && 01/28/2021 MD
SELECT CANAtty
lnMax1 = RECCOUNT()
lnCur1 = 0
IF RECCOUNT() > 0
	SET ORDER TO atty
	GO TOP
	DO WHILE NOT EOF()
		SELECT CANotice
		C_ORDER=ORDER()
		pc_CntNot = IIF( PL_HSONLY, "ca_hscount", "ca_count")
		SET ORDER TO(pc_CntNot)
		IF TYPE('ldRunDate')="C"
		ldRunDate =CTOD(ldRunDate)
		ENDIF
		SEEK DTOC( ldRunDate) + CANAtty.Cl_Code

**01/30/09 -PLUS RE-OPEN MASTER IF NOT THE SAME CASE IS PROCESSED
*!*			IF NOT USED ('MASTER') OR MASTER.CL_CODE<>CANAtty.Cl_Code 
			&& 03/09/2021 MD #229906 make sure the right table is open and public vars are set correctly
			oMstr.closealias("MasterID")
			oMstr.closealias("MASTER")
			SELECT 0
			l_gotMasterid=oMstr.sqlexecute("SELECT DBO.fn_GetID_tblmaster('" + fixquote(CANAtty.Cl_Code) + "')", "MasterID")
			IF  NOT l_gotMasterid
				gfmessage( "Data processing error. Try again or contact IT dept." )
				RETURN
			ENDIF
			oMstr.getitem(Masterid.EXP)
			SELECT MASTER
			pl_GotCase = .F.
			DO gfGetCas WITH .T.
*!*			ELSE 03/09/2021 MD #229906 
*!*	**RE-ASSIGN IF MASTER IS OPEN
*!*				SELECT MASTER
*!*				pl_GotCase = .F.
*!*				DO gfGetCas WITH .T.

*!*			ENDIF

*!*			IF NOT USED('Court') && 03/09/2021 MD #229906 
			oMstr.closealias("Court")
			DO GetCACourt WITH ALLTRIM(MASTER.court)
*!*			ENDIF
		SELECT CANAtty

		IF (pc_LitCode == "C  ") AND (	CANotice.TYPE= "A")
** General Litigation Authorization notices print last
			SKIP
			LOOP
		ENDIF

** Defense notices case by case for the current attorney in CANAtty
		lnRec = RECNO()
		mv = ""
		mgroup = "1"
		*-- 01/21/2022 MD #262708 added at_code to pass to prtenqa2
		lcDNoticeAtty=CANAtty.at_code
		*-- 02/09/2021 MD added lrsNo2Print as 6th parameter
		DO pDefNotc WITH at_code, Cl_Code, .F., .F.,	(CANotice.TYPE),lrsNo2Print
****9/09/09- FAX NOTICES
		caddress=getfaxaddress ()
		IF LEN(caddress) <10
			mclass= 'Notice'
			pl_CANotc=.T.
		ELSE
			mclass=IIF(pl_BBAsb, 'FaxCoDef', 'Notice') &&mclass= 'Notice'
			pl_CANotc=IIF(mclass='FaxCoDef',.F.,.T.) &&pl_CANotc=.T.

		ENDIF
		*-- 01/20/2021 MD #218721 sent reprint notices to RPS16 
		IF lrsNo2Print>0
			mclass = "reprintNotice"
		ENDIF
		*------------------------------------------------ 
		IF NOT EMPTY( mv)
			DO prtenqa2 WITH mv, mclass, mgroup, caddress,lcDNoticeAtty
		ENDIF
		DO gfClrCas
		SELECT court
		USE
		SELECT CANAtty
		GO lnRec
		SKIP
		lnCur1 = lnCur1 + 1
	ENDDO
**01/30/09- RESTORE ORDER
	SELECT CANOTICE
	IF NOT EMPTY(C_ORDER)
		SET ORDER TO (C_ORDER)
	ENDIF
ENDIF
*********************************************************************
*
* 4) Print order verifications to Requesting attorneys
*
*********************************************************************
SELECT CANType
pc_CaseNot = IIF( PL_HSONLY, "ca_hscases", "ca_cases")
SET ORDER TO (pc_CaseNot)
IF TYPE('ldRunDate')="C"
	ldRunDate =CTOD(ldRunDate)
ENDIF
LOCAL lcOVNoticeAtty
pl_ofcOak=.T. && 01/28/2021 MD
SEEK DTOC( ldRunDate)
COUNT WHILE Txn_Date = ldRunDate AND NOT EOF() TO lnMax1
lnCur1 = 0
SET NEAR ON
SEEK DTOC( ldRunDate)
SCAN  WHILE  convertToDate(Txn_Date) = convertToDate(ldRunDate)

*!*		IF NOT USED( "Master") OR MASTER.CL_CODE <> CANType.CL_CODE
&& 03/09/2021 MD #229906 make sure the right table is open and public vars are set correctly
		oMstr.closealias("MasterID")
		oMstr.closealias("MASTER")
		SELECT 0
		l_gotMasterid=oMstr.sqlexecute("SELECT DBO.fn_GetID_tblmaster('" + fixquote(CANType.Cl_Code) + "')", "MasterID")
		IF  NOT l_gotMasterid
			gfmessage("Data processing error. Try again or contact IT dept.")
			RETURN
		ENDIF
		oMstr.getitem(Masterid.EXP)
		SELECT MASTER
		pl_GotCase = .F.
		DO gfGetCas WITH .T.
		*--01/21/2022 MD #262708 added at_code to pass to prtenqa2
		lcOVNoticeAtty=pc_rqatcod
*!*		ELSE && 03/09/2021 MD #229906 make sure the right table is open and public vars are set correctly
*!*			SELECT MASTER
*!*			pl_GotCase = .F.
*!*			DO gfGetCas WITH .T.

*!*		ENDIF
*!*		IF NOT USED('Court') && 03/09/2021 MD #229906 make sure the right table is open and public vars are set correctly
		oMstr.closealias("Court")
		DO GetCACourt WITH ALLTRIM(MASTER.court)
*!*		ENDIF

	SELECT CANType
	*-- 01/13/2023 MD #301026 Do not print Order Verification for CA Authos
	*IF (pc_LitCode == "C  ") AND (CANType.TYPE = "A") AND gcOffLoc="C"
	IF CANType.TYPE = "A" AND gcOffLoc="C"
** General Litigation Authorization Order Verifications print last
		LOOP
	ENDIF

** Order verifications for the current case
	STORE "" TO mv, caddress
	mgroup = "1"
	*-- 02/09/2021 MD added lrsNo2Print as 6th parameter
	DO pDefNotc WITH " ", Cl_Code, .T., .F., CANType.TYPE,lrsNo2Print
******EF 1/12/09  fax notices
	caddress=getfaxaddress ()
	
*----------------------------------------------------------	
*-- 01/25/2021 MD #218721 email order verifications
	mclass="ordVerNotice"
*!*	*!*	*!*		IF LEN(caddress) <10
*!*	*!*	*!*			mclass= 'Notice'
*!*	*!*	*!*		ELSE
*!*	*!*	*!*			mclass= 'Notice'
*!*	*!*	*!*	*mclass='FaxCoDef'
*!*	*!*	*!*		ENDIF
*----------------------------------------------------------	
******ef 1/12/09  fax notices	
	*-- 01/20/2021 MD #218721 sent reprint notices to RPS16
	IF lrsNo2Print>0
		mclass = "reprintNotice"
	ENDIF
	*------------------------------------------------ 

	IF NOT EMPTY( mv)
		DO prtenqa2 WITH mv, mclass, mgroup,  caddress,lcOVNoticeAtty
	ENDIF
	lnCur1 = lnCur1 + 1
	DO gfClrCas
	SELECT court
	USE
	SELECT CANType
	
		
ENDSCAN


********************************************************************
*
* 5) Print Authorization notices/order verifications for Civil Lit
*
********************************************************************
pl_ofcOak=.T. && 01/28/2021 MD
LOCAL lcANoticeAtty,lcARNoticeAtty  &&01/28/2022 MD #262708
SELECT CAAtList
SET ORDER TO atty
SELECT CANType
SET ORDER TO (pc_CaseNot)
*--SCAN FOR TYPE = "A"  09/14/2023 MD #329792
*-- MD added noScanAutho to not enter scan loop
LOCAL noScanAutho
noScanAutho=.F.
IF noScanAutho=.T.
	SCAN FOR TYPE = "A" 
	*!*		IF NOT USED( "Master")
			&& 03/09/2021 MD #229906 make sure the right table is open and public vars are set correctly
			oMstr.closealias("MasterID")
			oMstr.closealias("MASTER")
			SELECT 0
			l_gotMasterid=oMstr.sqlexecute("SELECT DBO.fn_GetID_tblmaster('" + fixquote(CANType.Cl_Code) + "')", "MasterID")
			IF  NOT l_gotMasterid
				gfmessage( "Data processing error. Try again or contact IT dept.")
				RETURN
			ENDIF
			oMstr.getitem(Masterid.EXP)
			SELECT MASTER
			pl_GotCase = .F.
			DO gfGetCas WITH .T.
			lcARNoticeAtty=pc_rqatcod &&01/28/2022 MD #262708


	*!*		ENDIF

	*!*		IF NOT USED('Court')
			oMstr.closealias("Court")
			DO GetCACourt WITH ALLTRIM(MASTER.court)
	*!*		ENDIF

		IF MASTER.litigation == "C  "

			SELECT CAAtList
			SEEK pc_clcode
			SCAN WHILE (Cl_Code == pc_clcode)
				mv = ""

				mgroup = "1"
	* Generate notices
				lcANoticeAtty=CAAtList.at_Code &&01/28/2022 MD #262708
				*-- 02/09/2021 MD added lrsNo2Print as 6th parameter
				DO pDefNotc WITH at_code, Cl_Code, .F., .T., "A",lrsNo2Print
	****ef 1/12/09- FAX NOTICES
				caddress=getfaxaddress ()
				IF LEN(caddress) <10
					mclass= 'Notice'
				ELSE
					mclass= 'Notice'
	*mclass='FaxCoDef'
				ENDIF
				*-- 01/20/2021 MD #218721 sent reprint notices to RPS16
				IF lrsNo2Print>0
					mclass = "reprintNotice"
				ENDIF
				*------------------------------------------------ 
				IF NOT EMPTY( mv)
					*-- DO prtenqa WITH mv, mclass, mgroup, caddress &&01/28/2022 MD #262708
					DO prtenqa2 WITH mv, mclass, mgroup, caddress,lcANoticeAtty
				ENDIF
				SELECT CAAtList
			ENDSCAN
			mv = ""
			*-- mclass = "Notice"
			mclass="ordVerNotice"  &&01/28/2022 MD #262708
			mgroup = "1"
			*-- 01/20/2021 MD #218721 sent reprint notices to RPS16
			IF lrsNo2Print>0
				mclass = "reprintNotice"
			ENDIF
			*------------------------------------------------ 
	* Generate order verifications
			*-- 02/09/2021 MD added lrsNo2Print as 6th parameter
			*-- DO pDefNotc WITH (pc_rqatcod), pc_clcode, .T., .T., "A",lrsNo2Print &&07/31/2023 MD #322894 do not print OV for Authos
			IF NOT EMPTY( mv)
				*-- DO prtenqa WITH mv, mclass, mgroup, "" &&01/28/2022 MD #262708
				DO prtenqa2 WITH mv, mclass, mgroup, "",lcARNoticeAtty
			ENDIF
			DO gfClrCas
			SELECT court
			USE

		ENDIF
		SELECT CANType
	ENDSCAN
ENDIF

***************************************
*
* 6) clean up
*
***************************************

* Skip the next section if this was just a reprint of codefendant notices.
* Otherwise, update the "Printed" flag for all notices that were produced.
*
WAIT WINDOW "Marking notices as printed." NOWAIT NOCLEAR
IF NOT l_OnlyCo

	IF USED( "CANAtty")
		SELECT CANAtty
		USE
	ENDIF
	IF USED( "CAAtList")
		SELECT CAAtList
		USE
	ENDIF

	SELECT CANotice
	IF TYPE('ldRunDate')="C"
	ldRunDate =CTOD(ldRunDate)
	ENDIF
	SET ORDER TO Txn_Date
	SEEK DTOC( ldRunDate)
	GO TOP
&&5/16/07 -add an office param to the stored proc
	*-- 01/08/2021 MD do not update for reprints
	IF lrsNo2Print=0
		l_upd=oMed.sqlexecute("exec dbo.UpdCANotice " + ;
			STR(nLitType) + "," + IIF(PL_HSONLY,STR(1),STR(0)) + ;
			",'" + DTOC(ldRunDate) + "', '"+ gcOffLoc + "'")

		IF NOT l_upd
			WAIT WINDOW "Error in the update notice program." NOWAIT NOCLEAR
		ENDIF
	ENDIF 
	*-- 01/08/2021 MD 
ENDIF
* Turn off end-of-day noticing flag
pl_CANotc = .F.
RELEASE oMstr
WAIT CLEAR
RETURN
*****************************************************************************

*****************************************************************************
*
* Plaintiff Notice processing
*
* PARAMETERS
*  lcCl_Code    case being noticed
*  llHSOnly     specifies 'Hand Serve' filter
*

PROCEDURE PltfNotc
PARAMETERS lcCl_Code, lrsNo2Print2
*PARAMETERS ldRunDate, lcCl_Code, llHSOnly
IF PCOUNT()<2
   lrsNo2Print2=0
ENDIF 
lrsNo2Print2 =NVL(lrsNo2Print2,0)
IF TYPE("lrsNo2Print2")<>"N"
	lrsNo2Print2=convertToNum(lrsNo2Print2)
ENDIF 
PRIVATE dbInit, dbCANotice, dbTAMaster, dbTABills, dbTAAtty, c_alias
c_alias=""
WAIT WINDOW "Preparing plaintiff notice packages for RT " + pc_lrsno + "." NOWAIT NOCLEAR
IF TYPE('ldRunDate')="C"
	ldRunDate =CTOD(ldRunDate)
ENDIF
llCAAsb = pl_BBAsb

l_Tabill=gettabil(lcCl_Code, .T.)

IF NOT l_Tabill
	gfmessage("Cannot get TAbills file to print Notices.")
	RETURN
ENDIF
*-- 01/21/2022 MD #262708 added at_code to pass to prtenqa2
LOCAL lcPNoticeAtty
SELECT CAtabills


SCAN FOR CODE = "P" ;
		AND INLIST( Response, "T", "S") ;
		AND at_code <> pc_rqatcod ;
		AND NOT NoNotice WHILE ( Cl_Code == lcCl_Code )
** Print Plaintiff Notice (2 copies)
** Title is either "Notice" or "Notice to Consumer's Attorney"
	WAIT WINDOW "Printing plaintiff notices for RT " + pc_lrsno  + "." NOWAIT NOCLEAR
	lcPNoticeAtty=CAtabills.at_code &&&& 01/21/2022 MD #262708 added at_code to pass to prtenqa2
	DO Plt1Notc WITH at_code
	*--- MD #218721 remove second set of documents
	*!*		DO Plt1Notc WITH at_code
	*---
	*---------------------------------------------
	*----- 01/06/2021
*!*		mclass = "Notice"
*!*		mgroup = "1"
*!*		IF NOT EMPTY( mv)
*!*			DO prtenqa WITH mv, mclass, mgroup, ""
*!*		ENDIF
	*---------------------------------------------
	*----- 01/06/2021
	SELECT CANotice
	SET ORDER TO (pc_CntNot)
	SEEK DTOC( convertToDate(ldRunDate)) + lcCl_Code
	pc_ServNam=""



	IF LEFT( ALLTRIM(MASTER.court), 4) <> "USDC"
* For non-USDC courts, generate consumer notice / subpoena pairs for
* all cases, followed by a single consumer proof of service

		cscan="FOR (TYPE <> 'A') " + IIF(PL_HSONLY, " and hs_notice" , " and Not Hs_notice"  ) +  " WHILE Txn_Date =  convertToDate(ldRunDate) AND Cl_Code ==  lcCl_Code "
		SCAN  &cscan
** Print 1 copy of each notice-subpoena pair
** 4/22/2010 - TO GET A DEPARTMENT FOR A RIGHT DEPONENT ADDRESS
			c_alias=ALIAS()
			pl_GotDepo = .F.
			DO gfGetDep WITH CANotice.CL_code,CANotice.TAG
			SELECT (c_alias)
** 4/22/2010 - TO GET A DEPARTMENT FOR A RIGHT DEPONENT ADDRESS

			DO PrntCons WITH 	CANotice.due_date, CANotice.hs_notice, CANotice.DESCRIPT, CANotice.Mailid_no
			*-- 06/21/2022 MD #276861 to make sure the pl_Canotc is set to true
			pl_Canotc=.T.
			DO PrntSubpwNot WITH Cl_Code, TAG, CANotice.due_date, DESCRIPT, Mailid_no, Txn_Date, CANotice.due_date, .T.
			*---------------------------------------------
			*----- 01/06/2021
*!*				mclass = "Notice"
*!*				mgroup = "1"
*!*				IF NOT EMPTY( mv)
*!*					DO prtenqa WITH mv, mclass, mgroup, ""
*!*				ENDIF
			*---------------------------------------------
			*----- 01/06/2021
		ENDSCAN
		*---------------------------------------------
		*----- 01/06/2021
*!*			mclass = "Notice"
*!*			mgroup = "1"
*!*			IF NOT EMPTY( mv)
*!*				DO prtenqa WITH mv, mclass, mgroup, ""
*!*			ENDIF
		*---------------------------------------------
		*----- 01/06/2021
		SET ORDER TO (pc_CntNot)
		IF SEEK (DTOC( convertToDate(ldRunDate)) + lcCl_Code)

*!*				IF  CANotice.TYPE <> "A"
*!*	* EF  print one copy of pos to consumer page for the plaintiff's
*!*	*     full set of notices
*!*					DO CAConPOS IN Subp_CA WITH ldRunDate, CANotice.hs_notice, 	due_date
*!*				ENDIF

*** 02/02/2012 PRINT Proof of Notice for sub when mixed issues are in a batch
			l_SubandAuth=.F.
			IF CANotice.TYPE <> "A"
				DO CAConPOS IN Subp_CA WITH ldRunDate, CANotice.hs_notice, 	due_date
			ELSE
				l_SubandAuth=MixedIssue(lcCl_Code,ldRunDate)

				IF l_SubandAuth
					DO CAConPOS IN Subp_CA WITH ldRunDate, CANotice.hs_notice, 	due_date
				ENDIF
			ENDIF



		ENDIF

	ELSE
* For USDC courts, just generate all subpoenas for the case
		SCAN FOR TYPE <> "A" WHILE (Txn_Date = convertToDate(ldRunDate)) ;
				AND (Cl_Code == lcCl_Code)
				
			DO PrntSubpwNot WITH Cl_Code, TAG, due_date, ;
				DESCRIPT, Mailid_no, Txn_Date, due_date, .T.
		ENDSCAN
	ENDIF
	SELECT CANotice
	SEEK DTOC( convertToDate(ldRunDate)) + lcCl_Code


	IF LEFT( ALLT( Mailid_no), 1)=="D"
		c_drname=gfdrformat(DESCRIPT)
		mdep = IIF(NOT "DR."$c_drname,"DR. "+ALLTRIM(c_drname),c_drname)
	ELSE
		mdep = ALLTRIM(DESCRIPT)
	ENDIF


	IF LEFT( ALLTRIM(MASTER.court), 4) <> "USDC"
**8/20/09 the new POS pages only for BB cases
		IF NOT pl_BBAsb
			DO CAPosNot IN Subp_CA ;
				WITH TAG, CANotice.hs_notice, .T., .F., ldRunDate
		ELSE
			DO CAPOSPage WITH TAG, CANotice.hs_notice, .T., .F., ldRunDate, "P"
			DO CAPOSPage WITH TAG, CANotice.hs_notice, .T., .F., ldRunDate, "D"
		ENDIF
* 06/01/04 DMA For B&B Asbestos, generate an extra set of
*              Proof of Service documents
*!*	*!*	*!*---------------------------------------------------------------------
*!*	*!*	*!*	01/21/2021 MD #218721 remove second set of documents
*!*	*!*	*!*			IF pl_BBAsb
*!*	*!*	*!*	*!*				IF CANotice.TYPE <> "A"
*!*	*!*	*!*	*!*					SELECT CANotice
*!*	*!*	*!*	*!*					DO CAConPOS IN Subp_CA WITH ldRunDate, CANotice.hs_notice, ;
*!*	*!*	*!*	*!*						due_date
*!*	*!*	*!*	*!*				ENDIF
*!*	*!*	*!*	**02/02/2012 - print a proof of notice for sub issues when batch has a mixed tags-'auth' and 'subp' issued in one day
*!*	*!*	*!*				l_SubandAuth=.F.
*!*	*!*	*!*				SELECT CANotice
*!*	*!*	*!*				IF CANotice.TYPE <> "A"
*!*	*!*	*!*					DO CAConPOS IN Subp_CA WITH ldRunDate, CANotice.hs_notice, 	due_date
*!*	*!*	*!*				ELSE
*!*	*!*	*!*					l_SubandAuth=MixedIssue(CANotice.cl_code,ldRunDate)

*!*	*!*	*!*					IF l_SubandAuth
*!*	*!*	*!*						DO CAConPOS IN Subp_CA WITH ldRunDate, CANotice.hs_notice, 	due_date
*!*	*!*	*!*					ENDIF
*!*	*!*	*!*				ENDIF
*!*	*!*	*!*				SELECT CANotice
*!*	*!*	*!*	*DO CAPosNot IN Subp_CA 	WITH TAG, CANotice.hs_notice, .T., .F., ldRunDate
*!*	*!*	*!*	****
*!*	*!*	*!*				DO CAPOSPage WITH TAG, CANotice.hs_notice, .T., .F., ldRunDate, "P"
*!*	*!*	*!*				DO CAPOSPage WITH TAG, CANotice.hs_notice, .T., .F., ldRunDate, "D"

*!*	*!*	*!*	****
*!*	*!*	*!*			ENDIF
*!*	*!*	*!*----------------------------------------------------------------------------------
	ELSE
		DO CAUSPoS IN Subp_CA WITH ldRunDate
	ENDIF
	*---------------------------------------------
	*----- 01/15/2021
	mclass = "Notice"
	mgroup = "1"
	*-- 01/20/2021 MD #218721 sent reprint notices to RPS16
	IF lrsNo2Print2>0
		mclass = "reprintNotice"
	ENDIF
	*------------------------------------------------ 
	IF NOT EMPTY( mv)
		DO prtenqa2 WITH mv, mclass, mgroup, "",lcPNoticeAtty
	ENDIF
	*---------------------------------------------
	*----- 01/15/2021

	SELECT CAtabills
ENDSCAN

IF USED('CATabills')
	SELECT CAtabills
	USE
ENDIF

SELECT MASTER
USE

SELECT CANType
WAIT CLEAR
RETURN

*****************************************************************************
PROCEDURE gettabil
PARAMETERS c_client, l_inhibit
LOCAL l_RetVal AS Boolean, l_done AS Boolean, C_STR AS STRING, oMed6 AS OBJECT
oMed6 = CREATEOBJECT("generic.medgeneric")
c_Clcode=oMed6.cleanstring(c_client)
STORE .F. TO l_RetVal, l_done
C_STR="Exec	[dbo].[GetCATaBillforNotices] '" + IIF(l_inhibit,STR(0),STR(1)) +"'," + c_Clcode
l_done=oMed6.sqlexecute(C_STR, "CATabills")
IF l_done THEN
	l_RetVal=.T.
	=CURSORSETPROP("KeyFieldList", "ID_TblBills,Cl_code, AT_code", "CATabills")
	INDEX ON Cl_Code + at_code TAG clac ADDITIVE
	INDEX ON Cl_Code TAG Cl_Code ADDITIVE
ENDIF
RELEASE oMed6
RETURN l_RetVal

*	----------------------------------------------------------------------------------------------------
PROCEDURE pDefNotc
*
* Defense notice/order verification processing
*
PARAMETERS lcAt_Code, lcCl_Code, llOrdVer, l_CivAutho, lltype, ldfNotLrsNo2print
* PARAMETERS
*  lcAt_Code    Defense attorney being noticed
*  lcCl_Code    Case being noticed
*  llOrdVer     Process this as order verification rather than defense notice
*  l_CivAutho   Processing Civil Lit. Autho notices/order verifications
*  llType       "A" for authorizations; "S" for subpoenas
*
** When llOrdVer = .F., routine generates the defense notice packages
*     for an attorney/case pair.
** When llOrdVer = .T., routine generates the requesting attorney's
*     order verification package for a single case. In this situation,
*     lcAT_Code will be empty on entry, or will be the requesting attorney.

** The Order verification package generates the same pages as the defense
**    notice, with the exception of the cover page.
*
*-- 02/09/2021 MD added lrsNo2Print as 6th parameter
IF PCOUNT()<6
   ldfNotLrsNo2print=0
ENDIF 
ldfNotLrsNo2print =NVL(ldfNotLrsNo2print,0)
IF TYPE("ldfNotLrsNo2print")<>"N"
	ldfNotLrsNo2print=convertToNum(ldfNotLrsNo2print)
ENDIF 

PRIVATE dbInit, dbTAAtty, dbCANotice, dbTAMaster, lcRqAtty,l_complset
l_complset=.F.

* PRIVATE
*  dbInit       initial work area (saved)
*  dbTAAtty     alias for TAAtty.dbf (new instance)
*  dbCANotice   alias for PSNotice.dbf (new instance)
*  dbTAMaster   alias for TAMaster.dbf (new instance)
*  lcRqAtty     Requesting attorney's id code

dbInit = SELECT()

IF NOT llOrdVer
	WAIT WINDOW "Preparing Defense Notices for attorney " + ALLT( lcAt_Code) + ": RT " + pc_lrsno + "." NOWAIT NOCLEAR
ELSE
	WAIT WINDOW "Preparing Order Verifications for RT " + pc_lrsno + "." NOWAIT NOCLEAR
ENDIF
SELECT 0
LOCAL oMstr AS OBJECT
oMstr=CREATEOBJECT("medMaster")
SELECT 0
l_gotMasterid=oMstr.sqlexecute("SELECT DBO.fn_GetID_tblmaster('" + fixquote(lcCl_Code) + "')", "MasterID")
IF  NOT l_gotMasterid
	gfmessage("Data processing error. Try again or contact IT dept.")
	RETURN
ENDIF
oMstr.getitem(Masterid.EXP)
*-- 04/30/2021 MD #235877 make sure all public variables are set
SELECT master
pl_GotCase = .F.
DO gfGetCas WITH .T.
*--
gcCl_code = lcCl_Code
*---02/09/2021 MD #224487 ----------------------
*-- always open case court
*!*	IF NOT USED('Court')
*!*		DO GetCACourt WITH ALLTRIM(MASTER.court)
*!*	ENDIF
oMstr.closeAlias("court")
DO GetCACourt WITH ALLTRIM(MASTER.court)
*---02/09/2021 MD #224487 ----------------------

*-- 11/16/2021 MD
*lcRqAtty = Rq_at_code
SELECT master
lcRqAtty = master.Rq_at_code
*-- 11/16/2021 MD

**04/23/08 - do not print defense notice for Asbestos /LA -Pasadena
IF MASTER.LITIGATION="A  " 	AND  UPPER( ALLTRIM( MASTER.Area)) = "LA-PASADENA"
	RETURN
ENDIF
**1/25/08- do not print defense notice for Silica /Alameda Silica
IF MASTER.LITIGATION="Z  " 	AND  UPPER( ALLTRIM( MASTER.Area)) = "ALAMEDA SILICA"
	RETURN
ENDIF
**end 1/25/08
** Print Defense Notices
IF NOT llOrdVer
	DO DefNotic
ENDIF

IF llOrdVer AND l_CivAutho AND lltype = "A" AND lcAt_Code <> lcRqAtty
	DO CAUSList IN Subp_CA
ENDIF

IF llOrdVer AND NOT pl_BBAsb
	mclass = "Notice"
	*-- 01/20/2021 MD #218721 sent reprint notices to RPS16
	IF ldfNotLrsNo2print>0
		mclass = "reprintNotice"
	ENDIF
	*------------------------------------------------ 
	DO OrderVer	
	*---------------------------------------------
		*----- 01/06/2021 print all docs in one set 
*!*		mgroup = "1"
*!*		IF NOT EMPTY( mv)
*!*			DO prtenqa WITH mv, mclass, mgroup, ""
*!*		ENDIF
	*---------------------------------------------
		*----- 01/06/2021 print all docs in one set 
ENDIF

IF l_CivAutho AND NOT llOrdVer
	DO CAUSList IN Subp_CA
ENDIF
**7/13/09-7/31/09  added pl_NonGBB to a condition below

DO CASE
CASE NOT pl_BBAsb AND NOT l_CivAutho
	l_complset=.T.
CASE pl_NonGBB AND PC_LITCODE="A"
	l_complset=.T.
OTHERWISE
	l_complset=.F.
ENDCASE

IF l_complset &&NOT pl_BBAsb AND NOT l_CivAutho AND pl_NonGBB
** Only for non-B&B cases.
** print 1 copy of each subpoena
** For non-USDC courts, include a Notice to Consumer w/each subpoena
	SELECT 0
	SELECT CANotice
	SET ORDER TO (pc_CntNot)
	SEEK DTOC( convertToDate(ldRunDate)) + lcCl_Code
	SCAN WHILE (convertToDate(Txn_Date) =convertToDate( ldRunDate)) AND (Cl_Code == lcCl_Code)
* save txn date for consumer proof of service
* 07/30/03
		ldtxn_d = Txn_Date
		l_dDate = due_date
		l_cdesc = DESCRIPT
		l_cmid = Mailid_no
		l_lhs = hs_notice
		*--  04/02/2021 MD set up publics
		pc_court1=ALLTRIM(UPPER(caNotice.court))
		pl_ofcoaK=IIF(caNotice.lrs_nocode="C",.T., .F.)
		*--  04/02/2021 MD set up publics		
		DO PrntSubpwNot WITH Cl_Code, TAG, due_date, ;
			DESCRIPT, Mailid_no, Txn_Date, due_date, .T.

		pc_Court1=ALLTRIM(MASTER.court)

		IF LEFT( pc_Court1, 4) <> "USDC" AND l_complset
			DO PrntCons WITH l_dDate, l_lhs, l_cdesc, l_cmid
		ENDIF

	ENDSCAN



**01/31/2012 - when a case has miXed issues 'A'+'S' in one batch- make sure we print a proof of the notice (MixedIssue())
	l_SubandAuth=.F.
	SELECT CANotice
	SET ORDER TO (pc_CntNot)
	SEEK DTOC( convertToDate(ldRunDate)) + lcCl_Code

	IF CANotice.TYPE <> "A" AND LEFT( pc_Court1, 4) <> "USDC"
		DO CAConPOS IN Subp_CA WITH ldtxn_d, CANotice.hs_notice, ldtxn_d
	ELSE
		l_SubandAuth=MixedIssue(lcCl_Code,ldRunDate)

		IF l_SubandAuth AND LEFT( pc_Court1, 4) <> "USDC"
			DO CAConPOS IN Subp_CA WITH ldtxn_d, CANotice.hs_notice, ldtxn_d
		ENDIF
	ENDIF

	SELECT CANotice
	SEEK DTOC( convertToDate(ldRunDate)) + lcCl_Code
	IF LEFT( pc_Court1, 4) <> "USDC"
** 08/20/09 the new POS pages are only for the bb cases -see here

		IF NOT pl_BBAsb
			DO CAPosNot IN Subp_CA WITH TAG, CANotice.hs_notice, .T., .F., ldRunDate
		ELSE
			DO CAPOSPage WITH TAG, CANotice.hs_notice, .T., .F., ldRunDate, "P"
			DO CAPOSPage WITH TAG, CANotice.hs_notice, .T., .F., ldRunDate, "D"
		ENDIF

****
	ELSE
		DO CAUSPoS IN Subp_CA WITH ldRunDate
	ENDIF

ENDIF

SELECT MASTER
USE
RELEASE oMstr
SELECT (dbInit)
WAIT CLEAR
RETURN


****** -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

PROCEDURE DefNotic

** l_CivAutho = .T. for General (i.e., Civil) Litigation Authorization notices
PRIVATE dbInit, dbCANotice, lcEnt, lcRca_no, lcAttyAdd, c_atcsz
dbInit = SELECT()

SELECT 0


SELECT CANotice

pc_CntNot = IIF( PL_HSONLY, "ca_hscount", "ca_count")
SET ORDER TO (pc_CntNot)
IF TYPE('ldRunDate')="C"
	ldRunDate =CTOD(ldRunDate)
ENDIF
SEEK DTOC(ldRunDate) + lcCl_Code


DO PrintGroup WITH mv, "CADefNtc"
DO PrintField WITH mv, "CourtCounty", pc_c1Cnty
DO PrintField WITH mv, "DocDate", DTOC( ldRunDate)
DO PrintField WITH mv, "DepDate", DTOC( CANotice.due_date)
&&2/17/16- removed B & B website

IF ALLTRIM( pc_offcode) = "C"
	lcOrdText = IIF( pc_LitCode = "A  " , "PLEASE FAX OR MAIL ALL ORDERS TO: " ;
		+ CHR(13) + "RECORDTRAK, INC. " + CHR(13) ;
		+  IIF(LEFT( pc_Court1, 4) = "USDC","", "ATTN: CA-ASBESTOS" + CHR(13) )  ;
		+ "651 Allendale Rd." + CHR(13) + "P.O. Box 61591" + CHR(13) + ;
		"King of Prussia, PA 19406 " + CHR(13) + ;
		"Phone: (610) 354-8344   Fax: (610) 992-1416", "")
	DO PrintField WITH mv, "OrdDirect",  lcOrdText
***9/15/06 starts
	c_extrabb="Motions relating to this subpoena are to be filed and served " ;
		+ "electronically pursuant to Amended General Order 158. For a copy of Amended " ;
		+ "General Order 158, please contact LexisNexis at <http://www.lexisnexis.com/fileandserve/> " ;
		+ "or Spanos | Przetak at 510-250-0200 or at its website www.spanos-przetak.com<http://www.spanos-przetak.com/>.  " ;
		+ "Important legal rights could be prejudiced should you fail to follow the provisions contained within " ;
		+ "Amended General Order 158."
		
		
		
		
		
	DO PrintField WITH mv, "ExtraBB", IIF( pl_BBAsb AND pc_Court1="SFSC", c_extrabb, " ")

***9/15/06 extra text

ENDIF
**10/26/04 -end

IF l_CivAutho
	DO PrintField WITH mv, "ExtraSpace", "  "
	DO PrintField WITH mv, "When", "A"
	DO PrintField WITH mv, "When2", "Z"
	DO PrintField WITH mv, "When3", "O"
	DO PrintField WITH mv, "WhenBB", "P"
	DO PrintField WITH mv, "WhenBB2", "X"
	DO PrintField WITH mv, "WhenGA", "Q"
	DO PrintField WITH mv, "Loc", ALLTRIM( pc_offcode)
	DO PrintField WITH mv, "BBText", ""
	DO PrintField WITH mv, "BBText2", ""
ELSE
	DO PrintField WITH mv, "ExtraSpace", ""
	DO PrintField WITH mv, "When", IIF( pl_BBCase, "A", "N")
	DO PrintField WITH mv, "When2", IIF( pl_BBCase, "Y", "Z")
	DO PrintField WITH mv, "When3", IIF( pl_BBCase, "B", "O")
	DO PrintField WITH mv, "WhenBB", IIF( pl_BBCase, "C", "P")
	DO PrintField WITH mv, "WhenBB2", IIF( pl_BBCase, "X", "X")
	DO PrintField WITH mv, "WhenGA", "P"
	DO PrintField WITH mv, "Loc", ALLTRIM( pc_offcode)
	lcBBText = "PURSUANT TO ORDER OF THE COURT, ONLY PARTIES WHICH HAVE " + ;
		"AGREED TO SHARE THE COST OF PROCURING SAID RECORDS ARE ENTITLED TO " + ;
		"OBTAIN COPIES. RECORDTRAK, INC. IS "
	lcBBText2 = "AUTHORIZED TO PROCESS COPY REQUESTS ONLY OF DEFENDANTS WHICH " + ;
		"HAVE PREVIOUSLY REPORTED TO DDC THEIR PARTICIPATION IN THIS FUNCTION."
	DO PrintField WITH mv, "BBText", IIF( pl_BBCase, lcBBText, "")
	DO PrintField WITH mv, "BBText2", IIF( pl_BBCase, lcBBText2, "")
ENDIF

DO PrintGroup WITH mv, "Plaintiff"

DO PrintField WITH mv, "FirstName", pc_plnam
DO PrintField WITH mv, "LastName", ""
DO PrintField WITH mv, "MidInitial", ""
IF pl_BBCase


	OMED.SQLEXECUTE("EXEC DBO.GetSingleRequestRecord '" + FIXQUOTE(LCCL_CODE) + "','" + STR(CANotice.TAG) + "'","Record")


	lcRca_no = pc_plbbASB + "." + ASB_Round

	DO PrintField WITH mv, "Extra", lcRca_no
	SELECT CANotice
ELSE
	DO PrintField WITH mv, "Extra", " "
ENDIF
c_Atty=fixquote(lcAt_Code)
pl_GetAt = .F.
pc_defNotfax =""
DO gfatinfo WITH c_Atty, "M"
pc_defNotfax =pc_AtyFax

DO PrintGroup WITH mv, "Atty"
DO PrintField WITH mv, "Ata1", ALLT( pc_atyFirm)
DO PrintField WITH mv, "Ata2", ALLT( pc_Aty1Ad)
DO PrintField WITH mv, "Ata3", ALLT( pc_Aty2Ad)
DO PrintField WITH mv, "Atacsz", ALLT( pc_Atycsz)

DO PrintGroup WITH mv, "PltAtty"
IF NOT EMPTY( pc_platcod)
	c_Atty=fixquote(pc_platcod)
	pl_GetAt = .F.
	DO gfatinfo WITH c_Atty, "M"

	DO PrintField WITH mv, "Name_inv", ;
		"PLAINTIFF COUNSEL: " + ALLT( pc_atyFirm) + CHR(13)
ELSE
	DO PrintField WITH mv, "Name_inv", ""
ENDIF
 
*-- 11/16/2021 MD #256606
IF USED("dnReqAtty")
	SELECT dnReqAtty
	USE 
ENDIF  	
 
IF TYPE ('oMedDefNot')<>'O'
oMedDefNot= CREATEOBJECT("generic.medgeneric")
ENDIF
oMedDefNot.sqlexecute("exec dbo.tagCaseInfo '" + ALLTRIM(FixQuote(lcCl_Code)) + "', "+ALLTRIM(STR(CANotice.TAG)),"dnReqAtty")
SELECT dnReqAtty
pc_rqatcod=dnReqAtty.rq_At_code
SELECT dnReqAtty
USE
RELEASE oMedDefNot

*-- 11/16/2021 MD #256606

lcAttyAdd = ""
lcAttyAdd= PrintAtyData ( pc_rqatcod)

DO PrintGroup WITH mv, "ReqAtty"
DO PrintField WITH mv, "Ata1", lcAttyAdd

DO PrintGroup WITH mv, "Case"
DO PrintField WITH mv, "Plcap", pc_plcaptn
DO PrintField WITH mv, "Defcap", pc_dfcaptn
DO PrintField WITH mv, "Case", IIF( EMPTY( pc_casenam), " ", pc_casenam)
DO PrintField WITH mv, "Docket", pc_docket
SELECT CANotice
SEEK DTOC( convertToDate(ldRunDate)) + lcCl_Code
SCAN WHILE (Txn_Date = ldRunDate) AND (Cl_Code==lcCl_Code)
**12/7/06 -starts
	DO PrintField WITH mv, "RT", pc_lrsno
**12/7/06 -end
	IF LEFT( ALLT( Mailid_no), 1)="D"
		c_drname=gfdrformat(DESCRIPT)
		c_dep = IIF(NOT "DR."$c_drname,"DR. "+ALLTRIM(c_drname),c_drname)
	ELSE
		c_dep = ALLTRIM(DESCRIPT)

	ENDIF

	DO PrintGroup WITH mv, "Item"
	DO PrintField WITH mv, "Underline", "___"
	DO PrintField WITH mv, "Deponent", c_dep
	DO PrintField WITH mv, "Tag", ALLTRIM( STR( CANotice.TAG))
	DO PrintField WITH mv, "Autho", IIF(CANotice.TYPE=="A", "AUTHO", " ")
	SELECT CANotice
ENDSCAN


SELECT (dbInit)
RETURN

** ---------------------------------------------------------------------

** Order Verification sheet

** ---------------------------------------------------------------------

PROCEDURE OrderVer
* 07/22/04 DMA Receive info by inheritance; remove parms
PRIVATE dbInit, dbCANotice, c_atcsz, lcAttyAdd
dbInit = SELECT()
pc_CntNot = IIF( PL_HSONLY, "ca_hscount", "ca_count")

SELECT CANotice
SET ORDER TO (pc_CntNot)
SEEK DTOC( convertToDate(ldRunDate)) + lcCl_Code
*-- 03/11/2021 MD #224406 added WCAB 
*-- DO PrintGroup WITH mv, "CAOrdVer"
IF INLIST(LEFT(ALLTRIM(UPPER(pc_Court1)), 4),"WCAB")
	DO PrintGroup WITH mv, "CAOrdVerW"
ELSE
	DO PrintGroup WITH mv, "CAOrdVer"
ENDIF 	
*DO PrintField WITH mv, "CourtCounty", pc_c1Cnty
DO PrintField WITH mv, "CourtCounty", IIF(LEFT( pc_Court1, 4) = "USDC", ALLTRIM( pc_c1Desc),ALLTRIM( pc_c1Cnty))
DO PrintField WITH mv, "DocDate", DTOC( convertToDate(ldRunDate))
DO PrintField WITH mv, "DepDate", DTOC( CANotice.due_date)
DO PrintField WITH mv, "Loc", ALLTRIM( pc_offcode)
DO PrintField WITH mv, "SubAuth", IIF( l_CivAutho, "AUTHORIZATION", "SUBPOENA")
DO PrintField WITH mv, "RT", pc_lrsno

DO PrintGroup WITH mv, "Plaintiff"
DO PrintField WITH mv, "FirstName", pc_plnam
DO PrintField WITH mv, "LastName", ""
DO PrintField WITH mv, "MidInitial", ""
IF pl_BBCase

	Med.sqlexecute("EXEC DBO.GetSingleRequestRecord '" + FIXQUOTE(LCCL_CODE) + "','" + STR(CANotice.TAG) + "'","Record")

	lcRca_no = pc_plbbASB + "." + ASB_Round

	DO PrintField WITH mv, "Extra", lcRca_no
	SELECT CANotice
ELSE
	DO PrintField WITH mv, "Extra", " "
ENDIF
 
*-- 11/16/2021 MD #256606
IF USED("dnReqAtty")
	SELECT dnReqAtty
	USE 
ENDIF  	
IF TYPE ('oMedDefNot')<>'O'
oMedDefNot= CREATEOBJECT("generic.medgeneric")
ENDIF
oMedDefNot.sqlexecute("exec dbo.tagCaseInfo '" + ALLTRIM(FixQuote(lcCl_Code)) + "', "+ALLTRIM(STR(CANotice.TAG)),"dnReqAtty")
SELECT dnReqAtty
pc_rqatcod=dnReqAtty.rq_At_code
SELECT dnReqAtty
USE
RELEASE oMedDefNot

*-- 11/16/2021 MD #256606


lcAttyAdd= PrintAtyData ( pc_rqatcod)

DO PrintGroup WITH mv, "ReqAtty"
DO PrintField WITH mv, "Ata1", lcAttyAdd

DO PrintGroup WITH mv, "Case"
DO PrintField WITH mv, "Plcap", pc_plcaptn
DO PrintField WITH mv, "Defcap", pc_dfcaptn
DO PrintField WITH mv, "Case", IIF( EMPTY( pc_casenam), " ", pc_casenam)
DO PrintField WITH mv, "Docket", pc_docket

SELECT CANotice
SEEK DTOC( convertToDate(ldRunDate)) + lcCl_Code
SCAN WHILE (convertToDate(Txn_Date )= convertToDate(ldRunDate)) AND (Cl_Code == lcCl_Code)
**12/08/2017 -keep track of the tag# for rpswork

PN_TAG =CANotice.TAG
GNTAG=CANotice.TAG
**12/08/2017 -keep track of the tag# for rpswork
	IF LEFT( ALLT( Mailid_no), 1)="D"
		c_drname=gfdrformat(DESCRIPT)
		c_dep = IIF(NOT "DR."$c_drname,"DR. "+ALLTRIM(c_drname),c_drname)
	ELSE
		c_dep = ALLTRIM(DESCRIPT)

	ENDIF
	DO PrintGroup WITH mv, "Item"
	DO PrintField WITH mv, "Underline", " "

	DO PrintField WITH mv, "Deponent", c_dep
	DO PrintField WITH mv, "Tag", ALLTRIM( STR( CANotice.TAG))
	DO PrintField WITH mv, "Autho", " "
	SELECT CANotice
ENDSCAN



SELECT (dbInit)
RETURN

** ---------------------------------------------------------------------

PROCEDURE Plt1Notc
** Plaintiff Notice
** For USDC, title is "Notice"
** For non-USDC, title is "Notice to Consumer's Attorney"
PARAMETERS c_ThisAtty
PRIVATE dbInit, dbCANotice, lcAttyAdd, c_atcsz, c_Scan

dbInit = SELECT()

SELECT CANotice
LC_ORDER =ORDER()
pc_CntNot = IIF( PL_HSONLY, "ca_hscount", "ca_count")

***1/28/09
SELECT CANotice
IF NOT PL_HSONLY
	REPLACE ALL PRINTED WITH .T. FOR HS_NOTICE=.T.  AND CL_CODE = lcCl_Code AND  NOT PRINTED
	GO TOP
ENDIF
***1/28/09
SET ORDER TO (pc_CntNot)


SEEK DTOC( convertToDate(ldRunDate)) + lcCl_Code
*-- 03/11/2021 MD #224406 added WCAB 
IF INLIST(LEFT(ALLTRIM(UPPER(pc_Court1)), 4),"WCAB")
	DO PrintGroup WITH mv, "CAPltNtcW"
ELSE 	
	DO PrintGroup WITH mv, "CAPltNtc"
ENDIF 

DO PrintField WITH mv, "Title", IIF( hs_notice, "HAND SERVED", " ")
*-- 03/10/2021 MD #224406 added WCAB 
*--DO PrintField WITH mv, "ExtraCap", IIF( LEFT( pc_Court1, 4) <> "USDC", " TO CONSUMERS ATTORNEY", "")
DO PrintField WITH mv, "ExtraCap", IIF(INLIST(LEFT(ALLTRIM(UPPER(pc_Court1)), 4),"USDC","WCAB"),"", " TO CONSUMERS ATTORNEY")
DO PrintField WITH mv, "DocDate", DTOC( convertToDate(ldRunDate))
DO PrintField WITH mv, "DepDate", DTOC( due_date)
DO PrintField WITH mv, "Loc", ALLTRIM( pc_offcode)
DO PrintField WITH mv, "When", IIF( pl_BBCase, "A", "N")
DO PrintField WITH mv, "When2", IIF( pl_psgwc, "G", ;
	IIF( pl_BBCase, "B", "O"))
DO PrintField WITH mv, "When3", IIF( pl_BBCase, "C", "P")
**EF 12/19/05 - starts: new price for the pasadena office notices
DO PrintField WITH mv, "When4", IIF(pl_OfcPas, "W", "U")

**EF 12/19/05 - end

DO PrintField WITH mv, "RT", pc_lrsno
**EF 10/26/04 - add "direct-mail" text to CA Asbestos notices
**EF 03/29/06 - changed the direct dial phone to Nick's per Liz D.
IF ALLTRIM( pc_offcode) = "C"
	lcOrdText = IIF( pc_LitCode = "A  ", "PLEASE FAX OR MAIL ALL ORDERS TO: " ;
		+ CHR(13) + "RECORDTRAK, INC. " + CHR(13) + ;
		+  IIF(LEFT( pc_Court1, 4) = "USDC","", "ATTN: CA-ASBESTOS" + CHR(13) )   + "651 Allendale Rd." + CHR(13) + ;
		"P.O. Box 61591" + CHR(13) + "King of Prussia, PA 19406 " + ;
		CHR(13) + "Phone: (610) 354-8344  Fax: (610) 992-1416" , "")
	DO PrintField WITH mv, "OrdDirect",  lcOrdText
*EF 10/26/04 -end
***9/15/06 starts
&&2/17/16- removed B & B 
*!*		c_extrabb="Motions relating to this subpoena are to be filed and served " ;
*!*			+ "electronically pursuant to Amended General Order 158. For a copy of Amended " ;
*!*			+ "General Order 158, please contact LexisNexis at <http://www.lexisnexis.com/fileandserve/> " ;
*!*			+ "or Spanos | Przetak at 510-250-0200 or at its website www.spanos-przetak.com<http://www.spanos-przetak.com/>. " ;
*!*			+ "Important legal rights could be prejudiced should you fail to follow the provisions contained within " ;
*!*			+ "Amended General Order 158."
*!*		DO PrintField WITH mv, "ExtraBB", IIF( pl_BBAsb AND pc_Court1="SFSC", c_extrabb, " ")

***9/15/06 extra text
		*-----------------------------------------------------------------------------------------------------------------------
		*-- 04/17/2020 MD #167744
        c_extrabb="Motions relating to this subpoena are to be filed and served " +;
		 "electronically pursuant to San Francisco Local Rule 20.  "+;
		 "For a copy of San Francisco Local Rule 20, please contact LexisNexis at http://www.lexisnexis.com/fileandserve/ "+;
		 "or Spanos | Przetak at 510-250-0200 or its website at www.spanos-przetak.com<http://www.spanos-przetak.com/>."+;
		 "Important legal rights could be prejudiced should you fail to follow the provisions contained within "+;
		 "San Francisco Local Rule 20."
		DO PrintField WITH mv, "ExtraBB", IIF( pl_BBAsb AND pc_Court1="SFSC", c_extrabb, " ")
		*-----------------------------------------------------------------------------------------------------------------------
		*-- 04/17/2020 MD #167744
ENDIF

c_Atty=fixquote(pc_rqatcod)
pl_GetAt = .F.
DO gfatinfo WITH c_Atty, "M"

DO PrintGroup WITH mv, "ReqAtty"
IF pl_BBCase
**06/05/2015- added 3rd BB set 
LOCAL ln_bbset as Integer, c_name as String
c_name="LAURA PRZETAK, ESQ"
IF TYPE ('oMed')<>'O'
oMed= CREATEOBJECT("generic.medgeneric")
ENDIF

oMed.closealias("BBsign")
c_sql="Select dbo.GetBBSignatureSet  ('" + DTOC(convertToDate(ldRunDate)) + "')"
oMed.sqlexecute(c_sql,"BBsign")
LOCAL ln_bbset as Integer, c_rpsdoc as String
ln_bbset=3 && default is a new (latest set)
c_rpsdoc="CA3BBDepSubpoena"
	IF USED("BBsign")
	ln_bbset =NVL(BBsign.exp,3)  
	ENDif

DO case
CASE ln_bbset =1
c_name="LEONARDO J. VACCHINA, ESQ"
CASE  ln_bbset =2
c_name ="PETER GILBERT, ESQ"
OTHERWISE 
c_name ="LAURA PRZETAK, ESQ"
ENDCASE
**06/05/2015- added 3rd BB set  -end




	DO PrintField WITH mv, "Ata1", "LAW OFFICES OF SPANOS | PRZETAK"
	DO PrintField WITH mv, "Name_inv", 		c_name+ "   PHONE NO.: (510) 250-0200"
ELSE
	DO PrintField WITH mv, "Ata1", ALLT( pc_atyFirm)
	DO PrintField WITH mv, "Name_inv", ALLT( pc_Atysign) + ;
		"     PHONE NO.: " + pc_AtyPhn &&TRANSFORM( pc_AtyPhn, pc_fmtphon)
ENDIF

lcAttyAdd = ""
lcAttyAdd= PrintAtyData ( c_ThisAtty)


DO PrintGroup WITH mv, "PltAtty"
DO PrintField WITH mv, "Ata1", lcAttyAdd

* Case Identification Data
DO PrintGroup WITH mv, "Case"
IF EMPTY( ALLT( pc_plcaptn)) AND EMPTY( ALLT( pc_dfcaptn))
	DO PrintField WITH mv, "Case", ALLT( pc_casenam)
ELSE
	DO PrintField WITH mv, "Case", ALLT( pc_plcaptn) + " VS. " + ;
		ALLT( pc_dfcaptn) + IIF( EMPTY( pc_casenam), "", ;
		CHR(13) + ALLT(pc_casenam))
ENDIF
DO PrintField WITH mv, "Docket", ALLT( pc_docket)

* List of requested items
*-- 01/21/2021 MD #218721 added mailid_no to itemList
*-- 04/19/2021 MD added convertToDate function to ldRunDate to ensure that the date is in the right format
SELECT STR( TAG) AS TagStr, DESCRIPT AS Deponent, ;
	IIF( TYPE = "A", "AUTHO", "     ") AS A_Word, hs_notice, mailid_no  ;
	FROM CANotice ;
	INTO CURSOR ItemList ;
	WHERE Txn_Date = convertToDate(ldRunDate) ;
	AND Cl_Code == lcCl_Code ;
	ORDER BY TAG
**EF 09/21/04-start: fixed a bug

IF PL_HSONLY
	c_Scan = " hs_notice AND NOT DELETED()"
ELSE
	c_Scan=" NOT HS_NOTICE AND NOT DELETED()"
ENDIF
**EF 09/21/04-end

SELECT ItemList
IF _TALLY > 0
	SCAN  FOR &c_Scan
**12/06/06 EF - added department's desc to a notice page -start
		l_Spec=oMed.sqlexecute("SELECT dbo.GetSpecInsDept ('" + fixquote(pc_clcode) ;
			+ "','" +ALLT( ItemList.TagStr) + "')", "SpecDept")
		c_dept=""
		IF  NOT l_Spec
			WAIT WINDOW "Error in the getting a department for Plaintiff Notice page." NOWAIT NOCLEAR
		ELSE
			DO CASE
			CASE SpecDept.EXP = "B"
				c_dept = "(BILL)"
			CASE SpecDept.EXP  = "E"
				c_dept = "(ECHO)"
			CASE SpecDept.EXP  = "P"
				c_dept = "(PATH)"
			CASE SpecDept.EXP  = "R"
				c_dept = "(RAD)"
*CASE SpecDept.exp  = "M"
*c_dept = "(MED)"
			OTHERWISE
				c_dept =""
			ENDCASE
**12/06/06 EF - added department's desc to a notice page -end
		ENDIF
		*-- 01/21/2021 MD #218721 added deponent formatting		
			IF LEFT( ALLT(ItemList.Mailid_no), 1)="D"
				c_drname=gfdrformat(ItemList.Deponent)
				c_dep = IIF(NOT "DR."$c_drname,"DR. "+ALLTRIM(c_drname),c_drname)
			ELSE
			c_dep = ALLT( ItemList.Deponent)
		ENDIF
		*-- 01/21/2021 MD #218721 added deponent formatting
		DO PrintGroup WITH mv, "Item"
		DO PrintField WITH mv, "Underline", "___"
		DO PrintField WITH mv, "Deponent", c_dep && ALLT( ItemList.Deponent) 01/21/2021 MD #218721
&&+ c_dept  MD 04/19/2007 now department is adding when issued
		DO PrintField WITH mv, "Tag", ALLT( ItemList.TagStr)
		DO PrintField WITH mv, "Autho", ItemList.A_Word
		SELECT SpecDept
		USE
		SELECT ItemList
	ENDSCAN
	SELECT ItemList
	USE
ENDIF

* Court Location
DO PrintGroup WITH mv, "Court"
** 03/22/12- court's description for the USDC here
DO PrintField WITH mv, "County", IIF(LEFT( pc_Court1, 4) = "USDC", ALLTRIM( pc_c1Desc),ALLTRIM( pc_c1Cnty))

* Plaintiff Identification
DO PrintGroup WITH mv, "Plaintiff"
DO PrintField WITH mv, "FirstName", pc_plnam
DO PrintField WITH mv, "LastName", ""
DO PrintField WITH mv, "MidInitial", ""

SELECT (dbInit)
RETURN
** -----------------------------------------------------------------------------------------------------

PROCEDURE PrntCons
PARAMETERS mdepdate, llHS, mdep, mid
pl_ofcOak=.T.
DO CAConNtc IN Subp_CA WITH ldRunDate, llHS, mdepdate, mdep, mid
RETURN


*****************************************************************************
PROCEDURE GET_Error
PARAMETERS N_ERROR
IF N_ERROR=1705
	MESSAGEBOX("CA Notice Production Error" + CHR(13)  + ;
		"The other user is printing notices at the momemnt." + CHR(13)  + ;
		"Please, try later.  " )

ENDIF


RETURN
*******************************************************
FUNCTION getqclass ()
PRIVATE c_class AS STRING

DO CASE
CASE LEN(pc_defNotfax)=10
*c_class="FaxCodef"
	c_class = "Notice"
OTHERWISE
	c_class = "Notice"

ENDCASE
RETURN c_class
******ef 1/12/09  fax notices***********************************************************************
FUNCTION getfaxaddress ()
PRIVATE c_Addr  AS STRING
STORE "" TO c_Addr, c_temp, c_temp2, c_fax
l_FaxNotice = (NOT EMPTY( pc_defNotfax) )


DO CASE
CASE l_FaxNotice
	c_fax = STRTRAN(pc_defNotfax, " ", "")
	c_temp = STRTRAN( c_fax, "-", "")
	c_temp2 = STRTRAN( c_temp, "(", "")
	lc_FaxNum = "1"+ STRTRAN( c_temp2, ")", "")

	c_Addr=IIF (LEN(ALLTRIM(pc_defNotfax))<10,"",lc_FaxNum)


OTHERWISE

	c_Addr=""
ENDCASE
RETURN c_Addr
******ef 1/12/09  fax notices ************************************************************************

FUNCTION MixedIssue
PARAMETERS c_case, dNotDate
LOCAL l_mixcase AS Boolean
l_mixcase=.F.
c_alias=ALIAS()
n_rec=RECNO()

SELECT CANotice
SCAN FOR cl_code =c_case  AND txn_date =dNotDate AND TYPE ='S'
	l_mixcase=.T.
	EXIT
ENDSCAN
IF NOT EMPTY(c_alias)
	SELECT (c_alias)
ENDIF
GOTO n_rec

RETURN l_mixcase
