PROCEDURE RepRQCov
	***************************************************************************
	** Called from GenUtils, PrintCov
	** 04/09/2007 - EF -added a new phone for propulsid
	** 03/19/2007 - EF -added a new phone for the SRQ lit cases, use [dbo].[GetIssueLine].
	** 02/23/2006 - MD modified for VFP
	****************************************************************************
	PARAMETER lcLrs, ntag, lRTheader
	LOCAL szAlias, szOrd, bUsed, lcRqst, lloGen, lcSQLLine, c_offphone
	STORE "" TO cDuedate, cIssdate
	szAlias = ALIAS()
	IF TYPE("oGen")!="O"
		oGen=CREATEOBJECT("transactions.medrequest")
		lloGen=.T.
	ENDIF
	CREATE CURSOR temprep (textline c(80), groupcode c(1))

	lfSetGlobals(pc_clcode)
	pl_GotDepo = .F.
	DO gfGetDep WITH pc_clcode, ntag
	** 8/26/09 switch to a new Deponent Rolo
	**deponent info
	*lcSQLLine="select * from tblDeponent with (nolock) where mailid_no='"+ALLTRIM( pc_mailid)+"' and active=1"
	lcSQLLine=" exec dbo.GetDepInf'"+pc_MailID+"'"
	oGen.sqlexecute(lcSQLLine,"viewDepo")
	SELECT viewDepo
	IF RECCOUNT()>0
		lcAddr1 = ALLTRIM( add1)
		lcAddr2 = ALLTRIM(add2)
		lcCity = ALLTRIM(City)
		lcST = ALLTRIM(State)
		lcZip = ALLTRIM(Zip)
	ENDIF
	USE
	szAttn=""
	lcSQLLine="exec dbo.GetSpecInsbyClCodeTag '"+fixquote(ALLTRIM(pc_clcode))+"', '"+ALLTRIM(STR(ntag))+"'"
	oGen.sqlexecute(lcSQLLine,"viewSpecIns")
	SELECT viewSpecIns
	IF RECCOUNT()>0
		DO lookAttn WITH viewSpecIns.dept
	ENDIF
	USE IN viewSpecIns

	DO FindDates
	DO addSpecIns IN printCov WITH pc_clcode, ntag
	lcDOB="DOB: " + DTOC(oGen.checkdate(pd_pldob)) +"   DOD: " + DTOC(oGen.checkdate(pd_pldod))

	**3/19/07 - add a new phone for SRQ lit cases
	**4/09/07 - add a new phone for Propulsid

	DO CASE
		CASE pl_ofcMD OR pl_ofcPgh OR pl_ofcKOp
			**11/29/07 use new ADC numbers
			*l_GetRps= rpslitdata (pc_litcode)
			l_GetRps= Acdamnumber (pc_amgr_id)
			 IF l_getrps			
		    		c_phone= IIF(ISNULL(LitRps.RpsPhone),'',LitRps.RpsPHONE)
		    		c_offphone=	TRANSFORM( ALLTRIM(c_Phone), pc_fmtphon)
		    	 ELSE
		    		 c_offphone=""
			 endif	
					
		OTHERWISE
			c_offphone=""
	ENDCASE
	**3/19/07 - add a new phone for SRQ lit cases

	SELECT temprep
	IF RECCOUNT()=0
		APPEND BLANK
	ENDIF
	GO TOP
	IF NVL(pl_Softimg,.F.)
		_ASCIIROWS=58
		REPORT FORM printRequestCoverLetter TO FILE (pc_softdir + "8_covrrp.txt") ASCII
	ELSE
		REPORT FORM printRequestCoverLetter TO PRINTER NOCONSOLE
	ENDIF
	SELECT temprep
	USE
	IF lloGen=.T.
		RELEASE oGen
	ENDIF

&& Restore to original workarea
	IF NOT EMPTY(szAlias)
		SELECT (szAlias)
	ENDIF

	RETURN

	***********************************************
PROCEDURE FindDates
	LOCAL dIssdate, duedate, lcSQLLine, lloGen, lnCurArea
	STORE .F. TO l_PropCases, l_PropSubp
	lnCurArea=SELECT()
	IF TYPE("oGen")!="O"
		oGen=CREATEOBJECT("transactions.medrequest")
		lloGen=.T.
	ENDIF

	oGen.sqlexecute("exec dbo.GetHoldays '" + fixquote(pc_clcode) + "', '"+ALLTRIM(pc_Court1)+"'", "gfholdval")

	holddays = gfholdval.EXP
	SELECT gfholdval
	USE

	lnComply = 10
	lcSQLLine="select * from tblCourt with (nolock) where court='"+ALLTRIM(pc_Court1)+"' and active=1"
	oGen.sqlexecute(lcSQLLine,"viewCourt")
	SELECT viewCourt
	IF RECCOUNT()>0
		lnComply = holddays + IIF(NOT EMPTY(NVL(pc_court2,"")), pn_c2cmply, pn_c1cmply)
	ENDIF
	SELECT viewCourt
	USE

	DO CASE
		CASE pc_litcode == "3  " AND pc_IssType = "A"
			l_PropCases = ( INLIST( ALLTRIM( UPPER( pc_area)), "PENNSYLVANIA", ;
				"NEWJERSEY"))
		CASE pc_litcode == "3  " AND pc_IssType = "S"
			l_PropSubp = .T.
	ENDCASE

	*lcSQLLine="select * from tblTimeSheet with (nolock) where cl_code='"+;
		fixquote(ALLTRIM(pc_clcode))+"' and tag='"+ALLTRIM(STR(ntag))+"' and txn_code=11 and deleted is null"
		
	lcSQLLine="Exec [dbo].[GetIssueLine] '" + fixquote(ALLTRIM(pc_clcode))+"','" +ALLTRIM(STR(ntag))+"'"
		
	oGen.sqlexecute(lcSQLLine, "viewTimeSheet")

	IF NVL(pl_OfcHous,.F.)
		SELECT viewTimeSheet
		IF RECCOUNT()>0
			ldtxn11=viewTimeSheet.txn_date
		ELSE
			ldtxn11=d_today
		ENDIF
		ldBusOnly = gfDtSkip( ldtxn11, IIF( pc_TxCtTyp = "FED", 16, 9))
		dIssdate = IIF( pc_IssType = "S", ldBusOnly, ldtxn11)

		duedate=IIF (pc_IssType="S", gfChkDat((dIssdate+ 20), .F., .F.), ;
			gfChkDat((dIssdate + 10), .F., .F.))
		cIssdate = DTOC( dIssdate)
	ENDIF
	**TX cases


	IF l_PropSubp
		SELECT viewTimeSheet
		IF RECCOUNT()>0
			ldtxn11=viewTimeSheet.txn_date
		ELSE
			ldtxn11=d_today
		ENDIF

		ldBusOnly = gfChkDat((ldtxn11 + 10), .F., .F.)
		dIssdate = IIF( pc_IssType = "S", ldBusOnly, ldtxn11)
		duedate=gfChkDat((dIssdate + 10), .F., .F.)
		cIssdate = DTOC( dIssdate )
	ENDIF

	IF l_PropCases
		SELECT viewTimeSheet
		IF RECCOUNT()>0
			ldtxn11=viewTimeSheet.txn_date
		ELSE
			ldtxn11=d_today
		ENDIF
		ldBusOnly = ldtxn11
		FOR i = 0 TO 13
			ldBusOnly = ldBusOnly+1
			ldBusOnly = gfChkDat( ldBusOnly, .F., .F.)
		NEXT
		dIssdate = ldBusOnly
		duedate = gfChkDat( dIssdate+20, .F., .F.)

		cIssdate = DTOC(dIssdate)

	ELSE
		IF NOT NVL(pl_OfcHous,.F.) AND NOT l_PropSubp
			cIssdate = DTOC( pd_ReqDate)
			IF NOT EMPTY(oGen.checkdate(pd_ReqDate)) AND NOT EMPTY(NVL(pc_Court1,""))
				IF pc_IssType <> "A"
					IF holddays > 0 AND NOT NVL(pl_Reissue,.F.)
						cIssdate = DTOC(TTOD(pd_ReqDate) + holddays)
					ENDIF
				ELSE
					IF NVL(pl_FromRev,.F.)
						cIssdate = DTOC(TTOD(pd_ReqDate) + pn_litfday)
					ELSE
						cIssdate = DTOC(TTOD(pd_ReqDate) + pn_litiday)
					ENDIF
				ENDIF
			ENDIF
			IF pc_IssType = "A"
				duedate = gfChkDat( CTOD( cIssdate) + 10, .F., .F.)
			ELSE
				IF NOT EMPTY(NVL(holddays,0))
					duedate = gfChkDat( CTOD( cIssdate) + lnComply, .F., .F.)
				ELSE
					duedate = gfChkDat( CTOD( cIssdate) + 30, .F., .F.)
				ENDIF
			ENDIF
		ENDIF
	ENDIF
	cDuedate = DTOC(duedate)
	SELECT viewTimeSheet
	USE

	RETURN cIssdate
	*********************************************************************************
PROCEDURE lookAttn
	PARAMETERS lcDept
	retval=""
	IF pc_deptype = "H"
		retval = "ATTN: RECORDS"
		cdept = lcDept
		DO CASE
			CASE cdept == "R"
				retval = "ATTN: RADIOLOGY DEPARTMENT"
			CASE cdept == "E"
				retval = "ATTN: ECHOCARDIOGRAM DEPARTMENT"
			CASE cdept == "P"
				retval = "ATTN: PATHOLOGY DEPARTMENT"
			CASE cdept == "B"
				retval=  "ATTN: BILLING DEPARTMENT"
			OTHERWISE
				retval = "ATTN: MEDICAL RECORDS DEPARTMENT"
		ENDCASE
	ENDIF
	RETURN retval

	*********************************************************************************
PROCEDURE lfSetGlobals
	LPARAMETERS lcClCode
	LOCAL lloGen, lcSQLLine, lnCurArea, llTbl
	lnCurArea=SELECT()
	IF TYPE("oGen")!="O"
		oGen=CREATEOBJECT("transactions.medrequest")
		lloGen=.T.
	ENDIF
	IF !USED("master")
		lcSQLLine="select * from tblMaster with (nolock) where cl_code='"+;
			fixquote(ALLTRIM(lcClCode))+"' and active=1"
		oGen.sqlexecute(lcSQLLine,"Master")
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
