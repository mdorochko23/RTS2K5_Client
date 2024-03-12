PROCEDURE CANotice 
	******************************************************************************
	**OLD PROCEDURE DO NOT USE AFTER 7/31/09. USE CA_NOTICE.PRG INSTEAD
	******************************************************************************
	* CANotice.prg - Procedures for end-of-day printing of California notices
	*
	* Called By: RTS
	* Screens: RunCANot
	* Calls: CACivilN, UnArNot, Reattch, gfGetCas, gfClrCas
	*
	* Uses the following internal procedures within TA_Lib Procedure file:
	*      PrtEnqA, PrintGroup, PrintField
	*
	* Uses the following internal procedures within Subp_CA:
	*      CADepSub    -- CA Deponent Subpoena
	*      CAPoSNot    -- CA Proof of Service of Notice
	*      CAPoSSub    -- CA Proof of Service of Subpoena
	*      CAConNtc    -- CA Notice to Consumer
	*      CAConPoS    -- CA Proof of Service of Notice to Consumer
	*      CAUSOthr    -- CA US District Court Subpoena for non-CA court
	*      CAUSSubp    -- CA US District Court Subpoena for CA court
	*      CAUSPoS     -- CA US District Court Authorization Proof of Service
	*      CAUSList    -- CA US District Court Service List
	*      SubWCAB     -- CA WCAB Subpoena
	*
	* History :
	* Date     Name  Comment
	* ---------------------------------------------------------------------------
	**EF 07/31/09  - Fixed  a bug , added l_complset
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

	****************************************************************
	** Signal Subp_PA, Subp_CA, gfGetCas that end-of-day noticing is in progress
	PARAMETERS gcOffLoc
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
	ldRunDate=.NULL.
	ldRunDate=goApp.OpenForm("case.frmruncanot", "M", gcOffLoc, gcOffLoc)
	l_gotPS=.F.

	IF ISNULL(ldRunDate)
		pl_CANotc = .F.
		RETURN
	ENDIF
	*************************
	_SCREEN.MOUSEPOINTER=11
	oMed = CREATEOBJECT("generic.medgeneric")

	l_CANot=GetCANotic(ldRunDate)

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

	* 06/15/05 DMA Recreate and clear the temporary work file

	*f_CANType=IIF(gcOffLoc="S",goApp.psdatapath,goApp.cadatapath)	+ "\CANType.dbf"
	f_CANType=IIF(gcOffLoc="S","t:\vfpfree\pasadena\rts\","t:\vfpfree\oakland\rts\")	+ "CANType.dbf"

	SELECT CANotice
	SET ORDER TO Txn_Date
	* Confirm that there is at least one notice for the specified date.
	llReady = .F.
	IF SEEK( DTOC( ldRunDate))
		SCAN WHILE Txn_Date = ldRunDate
			llReady = .T.
			EXIT
		ENDSCAN
	ENDIF
	********************************************
	IF llReady
		lc_message = "Do you want to print notices now?"
		o_message = CREATEOBJECT('rts_message_yes_no',lc_message)
		o_message.SHOW
		l_Confirm=IIF(o_message.exit_mode="YES",.T.,.F.)
		o_message.RELEASE
		IF  l_Confirm

			DO NotcLoop

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
&&1/24/07
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
			DO CACivilN WITH PL_HSONLY
		ELSE
			SELECT CANType
			USE
		ENDIF

		SELECT Subpoena


	ENDIF &&1/24/08 - do not print civil wity co-def notices
	*********************************************************************
	*
	* 2) Print plaintiff notices
	*
	*********************************************************************
	WAIT WINDOW "Checking for regular notices." NOWAIT NOCLEAR


	IF NOT USED ('CANOTICE')
		l_CANot=GetCANotic(ldRunDate)
		IF NOT l_CANot
			gfmessage('Cannot get the Notice file. Try again..or contact the IT dept')
			RETURN

		ENDIF
	ENDIF

	**4/23/08 -treat "S" cases as "C" : Pasadena office closed

	SELECT * FROM CANotice INTO TABLE (f_CANType) ;
	WHERE Txn_Date = ldRunDate ;
	AND NOT Printed ;
	AND LRS_NOCODE<>"P" ; &&AND (RIGHT(ALLTRIM(Cl_Code),1)<>"P") 
	AND &c_LitType.
&&AND RIGHT(ALLTRIM(Cl_Code),1)<>IIF (gcOffLoc="C","S","C"))

	SELECT CANType
	USE
	USE ( f_CANType) IN 0 EXCL

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

		SEEK DTOC( ldRunDate)
		COUNT FOR Txn_Date = ldRunDate TO lnMax1
		lnCur1 = 0
		SET NEAR ON
		SEEK DTOC( ldRunDate)
		* SQL Select above took care of date-matching; don't repeat in SCAN
		SCAN
			gcCl_code = CANType.Cl_Code
			gnTag = CANType.TAG

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
			IF NOT USED('Court')
				DO GetCACourt WITH ALLTRIM(MASTER.court)
			ENDIF

			SELECT CANType

			IF ( pc_LitCode = "C  ") AND ( CANType.TYPE = "A") AND gcOffLoc="C"
				** Civil Litigation Authorization notices print last
				LOOP
			ENDIF

			** Plaintiff notices case by case

			mv = ""
			mclass = "Notice"
			mgroup = "1"
			DO PltfNotc WITH CANType.Cl_Code
			* 06/01/04 DMA PltfNotc now prints second copy of proofs of service
			*              for Berry & Berry Asbestos requests
			llDefault = .T.
			mclass = "Notice"
			mgroup = "1"
			IF NOT EMPTY( mv)
				DO prtenqa WITH mv, mclass, mgroup, ""
			ENDIF
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


	DO DefPrep
	
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
			SEEK DTOC( ldRunDate) + CANAtty.Cl_Code
		
	
			**01/30/09 -PLUS RE-OPEN MASTER IF NOT THE SAME CASE IS PROCESSED
			IF NOT USED ('MASTER') OR MASTER.CL_CODE<>CANAtty.Cl_Code
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
			ELSE
				**RE-ASSIGN IF MASTER IS OPEN
				SELECT MASTER
				pl_GotCase = .F.
				DO gfGetCas WITH .T.


			ENDIF

			IF NOT USED('Court')
				DO GetCACourt WITH ALLTRIM(MASTER.court)
			ENDIF
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
			DO pDefNotc WITH at_code, Cl_Code, .F., .F.,	(CANotice.TYPE)
			****1/12/09- FAX NOTICES
			caddress=getfaxaddress ()
			IF LEN(caddress) <10
				mclass= 'Notice'
				pl_CANotc=.T.
			ELSE
				*mclass='FaxCoDef'
				*pl_CANotc=.F.
				mclass= 'Notice'
				pl_CANotc=.T.
				
			ENDIF
			IF NOT EMPTY( mv)
				DO prtenqa WITH mv, mclass, mgroup, caddress
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
	SEEK DTOC( ldRunDate)
	COUNT WHILE Txn_Date = ldRunDate AND NOT EOF() TO lnMax1
	lnCur1 = 0
	SET NEAR ON
	SEEK DTOC( ldRunDate)
	SCAN WHILE Txn_Date = ldRunDate
		IF NOT USED( "Master") OR MASTER.CL_CODE <> CANType.CL_CODE
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
		ELSE
			SELECT MASTER
			pl_GotCase = .F.
			DO gfGetCas WITH .T.

		ENDIF
		IF NOT USED('Court')
			DO GetCACourt WITH ALLTRIM(MASTER.court)
		ENDIF


		SELECT CANType
		IF (pc_LitCode == "C  ") AND (CANType.TYPE = "A") AND gcOffLoc="C"
			** General Litigation Authorization Order Verifications print last
			LOOP
		ENDIF


		** Order verifications for the current case
		mv = ""
		mgroup = "1"
		DO pDefNotc WITH " ", Cl_Code, .T., .F., CANType.TYPE
		******ef 1/12/09  fax notices

		caddress=getfaxaddress ()
		IF LEN(caddress) <10
			mclass= 'Notice'
		ELSE
		mclass= 'Notice'
			*mclass='FaxCoDef'
		ENDIF
		******ef 1/12/09  fax notices
		IF NOT EMPTY( mv)
			DO prtenqa WITH mv, mclass, mgroup,  caddress
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

	SELECT CAAtList
	SET ORDER TO atty
	SELECT CANType
	SET ORDER TO (pc_CaseNot)
	SCAN FOR TYPE = "A"
		IF NOT USED( "Master")
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

		ENDIF

		IF NOT USED('Court')
			DO GetCACourt WITH ALLTRIM(MASTER.court)
		ENDIF

		IF MASTER.litigation == "C  "

			SELECT CAAtList
			SEEK pc_clcode
			SCAN WHILE (Cl_Code == pc_clcode)
				mv = ""

				mgroup = "1"
				* Generate notices
				DO pDefNotc WITH at_code, Cl_Code, .F., .T., "A"
				****ef 1/12/09- FAX NOTICES
				caddress=getfaxaddress ()
				IF LEN(caddress) <10
					mclass= 'Notice'
				ELSE
				mclass= 'Notice'
					*mclass='FaxCoDef'
				ENDIF
				IF NOT EMPTY( mv)
					DO prtenqa WITH mv, mclass, mgroup, caddress
				ENDIF
				SELECT CAAtList
			ENDSCAN
			mv = ""
			mclass = "Notice"
			mgroup = "1"

			* Generate order verifications
			DO pDefNotc WITH (pc_rqatcod), pc_clcode, .T., .T., "A"
			IF NOT EMPTY( mv)
				DO prtenqa WITH mv, mclass, mgroup, ""
			ENDIF
			DO gfClrCas
			SELECT court
			USE

		ENDIF
		SELECT CANType
	ENDSCAN

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
		SET ORDER TO Txn_Date
		SEEK DTOC( ldRunDate)
		GO TOP

&&5/16/07 -add an office param to the stored proc

		l_upd=oMed.sqlexecute("exec dbo.UpdCANotice " + ;
		STR(nLitType) + "," + IIF(PL_HSONLY,STR(1),STR(0)) + ;
		",'" + DTOC(ldRunDate) + "', '"+ gcOffLoc + "'")

		IF NOT l_upd
			WAIT WINDOW "Error in the update notice program." NOWAIT NOCLEAR
		ENDIF

	ENDIF
	* Turn off end-of-day noticing flag
	pl_CANotc = .F.
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
	* PRIVATE
	*  dbInit       initial work area (saved)
	*  dbCANotice   alias for PSNotice.dbf (new instance)
	*  dbTAMaster   alias for TAMaster.dbf (new instance)
	*  dbTABills    alias for TABills.dbf (new instance)
	*  dbTAAtty     alias for TAAtty.dbf (new instance)
	*
PROCEDURE PltfNotc
	PARAMETERS lcCl_Code
	*PARAMETERS ldRunDate, lcCl_Code, llHSOnly
	PRIVATE dbInit, dbCANotice, dbTAMaster, dbTABills, dbTAAtty

	WAIT WINDOW "Preparing plaintiff notice packages for RT " + pc_lrsno ;
	+ "." NOWAIT NOCLEAR


	llCAAsb = pl_BBAsb


	l_Tabill=gettabil(lcCl_Code, .T.)

	IF NOT l_Tabill
		gfmessage("Cannot get TAbills file to print Notices.")
		RETURN
	ENDIF

	SELECT CAtabills


	SCAN FOR CODE = "P" ;
		AND INLIST( Response, "T", "S") ;
		AND at_code <> pc_rqatcod ;
		AND NOT NoNotice WHILE ( Cl_Code == lcCl_Code )

		** Print Plaintiff Notice (2 copies)
		** Title is either "Notice" or "Notice to Consumer's Attorney"
		WAIT WINDOW "Printing plaintiff notices for RT " + pc_lrsno  + "." NOWAIT NOCLEAR
		DO Plt1Notc WITH at_code
		DO Plt1Notc WITH at_code
		mclass = "Notice"
		mgroup = "1"
		IF NOT EMPTY( mv)
			DO prtenqa WITH mv, mclass, mgroup, ""
		ENDIF

		SELECT CANotice
		SET ORDER TO (pc_CntNot)
		SEEK DTOC( ldRunDate) + lcCl_Code
		IF LEFT( ALLTRIM(MASTER.court), 4) <> "USDC"
			* For non-USDC courts, generate consumer notice / subpoena pairs for
			* all cases, followed by a single consumer proof of service

			cscan="FOR (TYPE <> 'A') " + IIF(PL_HSONLY, " and hs_notice" , " and Not Hs_notice"  ) +  " WHILE Txn_Date =  ldRunDate  AND Cl_Code ==  lcCl_Code "
			SCAN  &cscan
				
				** Print 1 copy of each notice-subpoena pair
				DO PrntCons WITH 	CANotice.due_date, CANotice.hs_notice, CANotice.DESCRIPT, CANotice.Mailid_no

				DO PrntSubpwNot WITH Cl_Code, TAG, due_date, DESCRIPT, Mailid_no, Txn_Date, due_date, .T.

				mclass = "Notice"
				mgroup = "1"
				IF NOT EMPTY( mv)
					DO prtenqa WITH mv, mclass, mgroup, ""
				ENDIF
			ENDSCAN
			mclass = "Notice"
			mgroup = "1"
			IF NOT EMPTY( mv)
				DO prtenqa WITH mv, mclass, mgroup, ""
			ENDIF
*!*				***1/28/09
*!*				SELECT CANotice
*!*				 IF NOT PL_HSONLY 
*!*				 REPLACE ALL PRINTED WITH .T. FOR HS_NOTICE=.T.  AND CL_CODE = lcCl_Code AND  NOT PRINTED
*!*				 GO TOP
*!*				endif
*!*				***1/28/09
			SET ORDER TO (pc_CntNot)
			IF SEEK (DTOC( ldRunDate) + lcCl_Code)
			
				IF  CANotice.TYPE <> "A"
				* EF  print one copy of pos to consumer page for the plaintiff's
				*     full set of notices
					DO CAConPOS IN Subp_CA WITH ldRunDate, CANotice.hs_notice, 	due_date
				ENDIF
			ENDIF
			
		ELSE
			* For USDC courts, just generate all subpoenas for the case
			SCAN FOR TYPE <> "A" WHILE (Txn_Date = ldRunDate) ;
				AND (Cl_Code == lcCl_Code)

				DO PrntSubpwNot WITH Cl_Code, TAG, due_date, ;
				DESCRIPT, Mailid_no, Txn_Date, due_date, .T.
			ENDSCAN
		ENDIF
		SELECT CANotice
		SEEK DTOC( ldRunDate) + lcCl_Code
		**11/06/08 -removed DO PrintField WITH mv, "RT", pc_lrsno
		
		

		IF LEFT( ALLT( Mailid_no), 1)=="D"
			c_drname=gfdrformat(DESCRIPT)
			mdep = IIF(NOT "DR."$c_drname,"DR. "+ALLTRIM(c_drname),c_drname)
		ELSE
			mdep = ALLTRIM(DESCRIPT)

		ENDIF


		IF LEFT( ALLTRIM(MASTER.court), 4) <> "USDC"
			DO CAPosNot IN Subp_CA ;
			WITH TAG, CANotice.hs_notice, .T., .F., ldRunDate

			* 06/01/04 DMA For B&B Asbestos, generate an extra set of
			*              Proof of Service documents
			IF pl_BBAsb
				IF CANotice.TYPE <> "A"
					SELECT CANotice
					DO CAConPOS IN Subp_CA WITH ldRunDate, CANotice.hs_notice, ;
					due_date
				ENDIF
				SELECT CANotice
				DO CAPosNot IN Subp_CA ;
				WITH TAG, CANotice.hs_notice, .T., .F., ldRunDate
			ENDIF
		ELSE
			DO CAUSPoS IN Subp_CA WITH ldRunDate
		ENDIF


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
	LOCAL l_RetVal AS Boolean, l_done AS Boolean, C_STR AS STRING
	oMed = CREATEOBJECT("generic.medgeneric")
	c_Clcode=oMed.cleanstring(c_client)
	STORE .F. TO l_RetVal, l_done

	C_STR="Exec	[dbo].[GetCATaBillforNotices] '" + IIF(l_inhibit,STR(0),STR(1)) +"'," + c_Clcode


	l_done=oMed.sqlexecute(C_STR, "CATabills")
	IF l_done THEN
		l_RetVal=.T.
		=CURSORSETPROP("KeyFieldList", "ID_TblBills,Cl_code, AT_code", "CATabills")
		INDEX ON Cl_Code + at_code TAG clac ADDITIVE
		INDEX ON Cl_Code TAG Cl_Code ADDITIVE
	ENDIF
	RETURN l_RetVal

	*	----------------------------------------------------------------------------------------------------
PROCEDURE pDefNotc

	*
	* Defense notice/order verification processing
	*
	PARAMETERS lcAt_Code, lcCl_Code, llOrdVer, l_CivAutho, lltype
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

	PRIVATE dbInit, dbTAAtty, dbCANotice, dbTAMaster, lcRqAtty, l_complset
	l_complset=.f.
	* PRIVATE
	*  dbInit       initial work area (saved)
	*  dbTAAtty     alias for TAAtty.dbf (new instance)
	*  dbCANotice   alias for PSNotice.dbf (new instance)
	*  dbTAMaster   alias for TAMaster.dbf (new instance)
	*  lcRqAtty     Requesting attorney's id code

	dbInit = SELECT()


	IF NOT llOrdVer
		WAIT WINDOW "Preparing Defense Notices for attorney " + ALLT( lcAt_Code) + ;
		": RT " + pc_lrsno + "." NOWAIT NOCLEAR
	ELSE
		WAIT WINDOW "Preparing Order Verifications for RT " + pc_lrsno + "." NOWAIT NOCLEAR
	ENDIF
	SELECT 0
	
	oMstr=CREATEOBJECT("medMaster")
	SELECT 0
	l_gotMasterid=oMstr.sqlexecute("SELECT DBO.fn_GetID_tblmaster('" + fixquote(lcCl_Code) + "')", "MasterID")
	IF  NOT l_gotMasterid
		gfmessage("Data processing error. Try again or contact IT dept.")
		RETURN
	ENDIF
	oMstr.getitem(Masterid.EXP)

	gcCl_code = lcCl_Code
	IF NOT USED('Court')
		DO GetCACourt WITH ALLTRIM(MASTER.court)
	ENDIF
	lcRqAtty = Rq_at_code

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
		DO OrderVer
		mclass = "Notice"
		mgroup = "1"
		IF NOT EMPTY( mv)
			DO prtenqa WITH mv, mclass, mgroup, ""
		ENDIF
	ENDIF

	IF l_CivAutho AND NOT llOrdVer
		DO CAUSList IN Subp_CA
	ENDIF
**7/13/09 added pl_NonGBB to a condition below
** 7/31/09  l_complset var  = true for non bb civil subpoenas and BB -generic area cases
DO case
 CASE NOT pl_BBAsb AND NOT l_CivAutho
 l_complset=.t.
 CASE pl_NonGBB AND PC_LITCODE="A"
 l_complset=.t.
 OTHERWISE
 l_complset=.f.
ENDCASE

	*IF NOT pl_BBAsb AND NOT l_CivAutho AND pl_NonGBB 
	IF l_complset
		** Only for non-B&B cases.
		** print 1 copy of each subpoena
		** For non-USDC courts, include a Notice to Consumer w/each subpoena
		SELECT 0

		SELECT CANotice
		SET ORDER TO (pc_CntNot)
		SEEK DTOC( ldRunDate) + lcCl_Code
		SCAN WHILE (Txn_Date = ldRunDate) AND (Cl_Code == lcCl_Code)
			* save txn date for consumer proof of service
			* 07/30/03
			ldtxn_d = Txn_Date
			l_dDate = due_date
			l_cdesc = DESCRIPT
			l_cmid = Mailid_no
			l_lhs = hs_notice
			

			DO PrntSubpwNot WITH Cl_Code, TAG, due_date, ;
			DESCRIPT, Mailid_no, Txn_Date, due_date, .T.

			pc_Court1=ALLTRIM(MASTER.court)
			IF LEFT( pc_Court1, 4) <> "USDC" and CANotice.TYPE ='S'
				DO PrntCons WITH l_dDate, l_lhs, l_cdesc, l_cmid
			ENDIF
**7/15/09 -merge jobs 
			****8/9/07	SPLIT the big jobs into smaller as the printer cannot handle them.
*!*				IF NOT EMPTY( mv)
*!*					DO prtenqa WITH mv, mclass, mgroup, ""
*!*				ENDIF
*!*				mv=""
			****8/9/07
		ENDSCAN



		SELECT CANotice
		SET ORDER TO (pc_CntNot)
		SEEK DTOC( ldRunDate) + lcCl_Code

		IF CANotice.TYPE <> "A" AND LEFT( pc_Court1, 4) <> "USDC"
			DO CAConPOS IN Subp_CA WITH ldtxn_d, CANotice.hs_notice, ldtxn_d
		ENDIF

		SELECT CANotice
		SEEK DTOC( ldRunDate) + lcCl_Code
		IF LEFT( pc_Court1, 4) <> "USDC"
			DO CAPosNot IN Subp_CA ;
			WITH TAG, CANotice.hs_notice, .T., .F., ldRunDate
		ELSE
			DO CAUSPoS IN Subp_CA WITH ldRunDate
		ENDIF

	ENDIF

	SELECT MASTER
	USE

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
	SEEK DTOC(ldRunDate) + lcCl_Code

	DO PrintGroup WITH mv, "CADefNtc"
	DO PrintField WITH mv, "CourtCounty", pc_c1Cnty
	DO PrintField WITH mv, "DocDate", DTOC( ldRunDate)
	DO PrintField WITH mv, "DepDate", DTOC( CANotice.due_date)

	**EF 10/26/04 - add "direct mail" text to CA Asbestos notices
	**EF 03/29/06 - changed the direct dial phone to Nick's per Liz D.

	IF ALLTRIM( pc_offcode) = "C"
		lcOrdText = IIF( pc_LitCode = "A  " , "PLEASE FAX OR MAIL ALL ORDERS TO: " ;
		+ CHR(13) + "RECORDTRAK, INC. " + CHR(13) + "ATTN: CA-ASBESTOS" + CHR(13) ;
		+ "651 Allendale Rd." + CHR(13) + "P.O. Box 61591" + CHR(13) + ;
		"King of Prussia, PA 19406 " + CHR(13) + ;
		"Phone: (610) 354-8344   Fax: (610) 992-1416", "")
		DO PrintField WITH mv, "OrdDirect",  lcOrdText
		***9/15/06 starts
		c_extrabb="Motions relating to this subpoena are to be filed and served " ;
		+ "electronically pursuant to Amended General Order 158. For a copy of Amended " ;
		+ "General Order 158, please contact LexisNexis at <http://www.lexisnexis.com/fileandserve/> " ;
		+ "or Berry & Berry at 510-250-0200 or at its website www.BerryandBerry.com " ;
		+ "<http://www.berryandberry.com/>. Important legal rights could be " ;
		+ "prejudiced should you fail to follow the provisions contained within " ;
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

		oMed.sqlexecute("select * from tblRequest WITH(NOLOCK) where cl_code = '" + ;
		fixquote(lcCl_Code) + "' and tag=' " + STR(CANotice.TAG) + "'", "Record")
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
	SEEK DTOC( ldRunDate) + lcCl_Code
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
	SEEK DTOC( ldRunDate) + lcCl_Code

	DO PrintGroup WITH mv, "CAOrdVer"
	DO PrintField WITH mv, "CourtCounty", pc_c1Cnty
	DO PrintField WITH mv, "DocDate", DTOC( ldRunDate)
	DO PrintField WITH mv, "DepDate", DTOC( CANotice.due_date)
	DO PrintField WITH mv, "Loc", ALLTRIM( pc_offcode)
	DO PrintField WITH mv, "SubAuth", IIF( l_CivAutho, "AUTHORIZATION", "SUBPOENA")
	DO PrintField WITH mv, "RT", pc_lrsno

	DO PrintGroup WITH mv, "Plaintiff"
	DO PrintField WITH mv, "FirstName", pc_plnam
	DO PrintField WITH mv, "LastName", ""
	DO PrintField WITH mv, "MidInitial", ""
	IF pl_BBCase

		oMed.sqlexecute("select * from tblRequest WITH (NOLOCK) where cl_code = '" + ;
		fixquote(lcCl_Code) + "' and tag=' " + STR(CANotice.TAG) + "'", "Record")

		lcRca_no = pc_plbbASB + "." + ASB_Round

		DO PrintField WITH mv, "Extra", lcRca_no
		SELECT CANotice
	ELSE
		DO PrintField WITH mv, "Extra", " "
	ENDIF

	lcAttyAdd= PrintAtyData ( pc_rqatcod)

	DO PrintGroup WITH mv, "ReqAtty"
	DO PrintField WITH mv, "Ata1", lcAttyAdd

	DO PrintGroup WITH mv, "Case"
	DO PrintField WITH mv, "Plcap", pc_plcaptn
	DO PrintField WITH mv, "Defcap", pc_dfcaptn
	DO PrintField WITH mv, "Case", IIF( EMPTY( pc_casenam), " ", pc_casenam)
	DO PrintField WITH mv, "Docket", pc_docket

	SELECT CANotice
	SEEK DTOC( ldRunDate) + lcCl_Code
	SCAN WHILE (Txn_Date = ldRunDate) AND (Cl_Code == lcCl_Code)
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
		endif		
			***1/28/09
	SET ORDER TO (pc_CntNot)


	SEEK DTOC( ldRunDate) + lcCl_Code

	DO PrintGroup WITH mv, "CAPltNtc"
	DO PrintField WITH mv, "Title", IIF( hs_notice, "HAND SERVED", " ")
	DO PrintField WITH mv, "ExtraCap", IIF( LEFT( pc_Court1, 4) <> "USDC", ;
	" TO CONSUMERS ATTORNEY", "")
	DO PrintField WITH mv, "DocDate", DTOC( ldRunDate)
	DO PrintField WITH mv, "DepDate", DTOC( due_date)
	DO PrintField WITH mv, "Loc", ALLTRIM( pc_offcode)
	DO PrintField WITH mv, "When", IIF( pl_BBCase, "A", "N")
	DO PrintField WITH mv, "When2", IIF( pl_psgwc, "G", ;
	IIF( pl_BBCase, "B", "O"))
	DO PrintField WITH mv, "When3", IIF( pl_BBCase, "C", "P")
	**EF 12/19/05 - starts: new price for the pasadena office notices
	DO PrintField WITH mv, "When4", IIF(pl_OfcPas, "W", "U")
	**DO PrintField WITH mv, "When4", IIF( pl_psgwc, "W", "U")
	**EF 12/19/05 - end

	DO PrintField WITH mv, "RT", pc_lrsno
	**EF 10/26/04 - add "direct-mail" text to CA Asbestos notices
	**EF 03/29/06 - changed the direct dial phone to Nick's per Liz D.
	IF ALLTRIM( pc_offcode) = "C"
		lcOrdText = IIF( pc_LitCode = "A  ", "PLEASE FAX OR MAIL ALL ORDERS TO: " ;
		+ CHR(13) + "RECORDTRAK, INC. " + CHR(13) + ;
		"ATTN: CA-ASBESTOS" + CHR(13) + "651 Allendale Rd." + CHR(13) + ;
		"P.O. Box 61591" + CHR(13) + "King of Prussia, PA 19406 " + ;
		CHR(13) + "Phone: (610) 354-8344  Fax: (610) 992-1416" , "")
		DO PrintField WITH mv, "OrdDirect",  lcOrdText
		*EF 10/26/04 -end
		***9/15/06 starts
*!*			c_extrabb="Motions relating to this subpoena are to be filed and served " ;
*!*			+ "electronically pursuant to Amended General Order 158. For a copy of Amended " ;
*!*			+ "General Order 158, please contact LexisNexis at <http://www.lexisnexis.com/fileandserve/> " ;
*!*			+ "or Berry & Berry at 510-250-0200 or at its website www.BerryandBerry.com " ;
*!*			+ "<http://www.berryandberry.com/>. Important legal rights could be " ;
*!*			+ "prejudiced should you fail to follow the provisions contained within " ;
*!*			+ "Amended General Order 158."
*!*			DO PrintField WITH mv, "ExtraBB", IIF( pl_BBAsb AND pc_Court1="SFSC", c_extrabb, " ")

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
	*USE ( f_TAAtty) IN 0 AGAIN ALIAS NotcAtty ORDER At_Code
	*SELECT NotcAtty

	* Requesting Attorney information
	*SEEK pc_rqatcod
	DO PrintGroup WITH mv, "ReqAtty"
	IF pl_BBCase
		DO PrintField WITH mv, "Ata1", "LAW OFFICES OF BERRY & BERRY"
		DO PrintField WITH mv, "Name_inv", ;
		"LEONARDO J. VACCHINA, ESQ.     PHONE NO.: (510) 250-0200"
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
	SELECT STR( TAG) AS TagStr, DESCRIPT AS Deponent, ;
	IIF( TYPE = "A", "AUTHO", "     ") AS A_Word, hs_notice  ;
	FROM CANotice ;
	INTO CURSOR ItemList ;
	WHERE Txn_Date = ldRunDate ;
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


			DO PrintGroup WITH mv, "Item"
			DO PrintField WITH mv, "Underline", "___"
			DO PrintField WITH mv, "Deponent", ALLT( ItemList.Deponent)
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
	DO PrintField WITH mv, "County", ALLTRIM( pc_c1Cnty)

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
	******ef 1/12/09  fax notices
FUNCTION getfaxaddress ()
	PRIVATE c_Addr  AS STRING
	c_Addr=""
	c_fax = STRTRAN(pc_defNotfax, " ", "")
	c_temp = STRTRAN( c_fax, "-", "")
	c_temp2 = STRTRAN( c_temp, "(", "")
	lc_FaxNum = "1"+ STRTRAN( c_temp2, ")", "")
	l_FaxNotice = (NOT EMPTY( pc_AtyFax) )
	DO CASE
		CASE l_FaxNotice

			c_Addr=IIF (LEN(ALLTRIM(lc_FaxNum))<10,"",lc_FaxNum)
			c_fax = STRTRAN( c_Addr, " ", "")
			c_temp = STRTRAN( c_fax, "-", "")
			c_temp2 = STRTRAN( c_temp, "(", "")
			c_Addr = STRTRAN( c_temp2, ")", "")

		OTHERWISE

			c_Addr=""
	ENDCASE
	RETURN c_Addr
	******ef 1/12/09  fax notices

