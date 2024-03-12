PROCEDURE RepTXCov
	**5/11/06-added to the project.
	**************************************************************
	* 06/22/04 DMA Remove contact print group; data now in templates
	* 06/15/04 DMA Extracted from TXReprin
	***********************************************************************
	** Called from frmtxrepwvr

	PRIVATE ldWork, ldtxn11, szattn, lcOfc, llUserCtrl, c_rolodex, c_deponame
	szattn = ""
	dbHold = SELECT()
	SET PROCEDURE TO TA_Lib ADDITIVE
	SELECT  timesheet
	*SET ORDER TO Status
	IF NOT EOF()
		*IF SEEK ( pc_clcode + "*" + STR(ntag))
		ldtxn11 = txn_date
		creqtype = TYPE
	ELSE
		RETURN
	ENDIF
	IF TYPE( "creqtype") <> "C"
		creqtype = "S"
	ENDIF

	**EF  02/19/02 Changed issue date for FED court to 17 bus. days.
	ldBusOnly = gfDtSkip( ldtxn11, IIF( pc_TxCtTyp = "FED", 16, 9))
	*USE
	SELECT (dbHold)

	SELECT MASTER

	IF creqtype = "S"
		mdate = ldBusOnly
		duedate = ldBusOnly + 20
		*   duedate = ldBusOnly + IIF( creqtype = "S", 20, 0)
	ELSE
		mdate = timesheet.txn_date
		duedate = ldBusOnly
	ENDIF
	duedate = gfChkDat( duedate, .F., .F.)

	pc_deptype = UPPER( LEFT( ALLTRIM( timesheet.MailID_No), 1))
	IF NOT INLIST( pc_deptype, "H", "E", "A", "D")
		pc_deptype = "D"
	ENDIF

	IF pc_deptype = "H"
		c_deponame = UPPER( ALLT( timesheet.DESCRIPT))
		* Determine the Department!!
		DO CASE

			CASE "(ECHO)" $ c_deponame
				cdept = "E"

			CASE "(RAD)" $ c_deponame
				cdept = "R"

			CASE "(PATH)" $ c_deponame
				cdept = "P"

			CASE "(BILL)" $ c_deponame OR ;
					"(BILLING)" $ c_deponame
				cdept = "B"

			OTHERWISE
				cdept = "M"
		ENDCASE

		** This is filled in only if hospital!!
		DO CASE
			CASE cdept == "E"
				IF EMPTY(szattn)
					szattn = "ATTN: ECHOCARDIOGRAM DEPARTMENT"
				ENDIF
				TheInfo = "ECHO"
				TheInfo2 = "ECHO"

			CASE cdept == "R"
				IF EMPTY(szattn)
					szattn = "ATTN: RADIOLOGY DEPARTMENT"
				ENDIF
				TheInfo = "RAD"
				TheInfo2 = "RAD"

			CASE cdept == "P"
				IF EMPTY(szattn)
					szattn = "ATTN: PATHOLOGY DEPARTMENT"
				ENDIF
				TheInfo = "PATH"
				TheInfo2 = "PATH"

			CASE cdept == "B"
				IF EMPTY(szattn)
					szattn =  "ATTN: BILLING DEPARTMENT"
				ENDIF
				TheInfo = "BILLS"
				TheInfo2 = "BILLS"

			OTHERWISE
				IF EMPTY(szattn)
					szattn = "ATTN: MEDICAL RECORDS DEPARTMENT"
				ENDIF
				TheInfo = "MED"
				TheInfo2 = "MED"
		ENDCASE
	ELSE
		TheInfo = "OTHER"
		TheInfo2 = "MED"
	ENDIF

	DO PrintGroup WITH mv, IIF( creqtype = "S", "TX_SubpCov", "TX_AuthCovT")

	dIssue = timesheet.txn_date
	szEdtReq=""
	DO PrintField WITH mv, "Loc", pc_offcode

	DO PrintField WITH mv, "DueDate", DTOC( duedate)
	oMed =CREATEOBJECT('medgeneric')
	WAIT WINDOW "Getting Special Instruction" NOWAIT NOCLEAR 
	**10/01/18 SL #109598
	*+ " tag, TYPE, spec_inst, dept, mailid_no from tblspec_ins   WITH (INDEX (IX_TBLSPEC_INS_1)) " 
	l_SpecIns=oMed.sqlexecute("select id_tblSpec_ins, id_tblTimesheet, Txn_date, cl_code, " ;
		+ " tag, TYPE, spec_inst, dept, mailid_no from tblspec_ins " ;
		+ " WHERE cl_code = '" + fixquote(pc_clcode) + "' and tag ='" ;
		+ STR(timesheet.TAG) + "' ORDER BY txn_date", "Spec_ins")

	SELECT spec_ins
	LOCATE FOR id_tbltimesheet =timesheet.id_tbltimesheet
	IF  FOUND()

		szrequest = ""
		szEdtReq = ""
		sztxndate = spec_ins.txn_date
		szrequest = spec_ins.Spec_Inst
		SET MEMOWIDTH TO 68

		szEdtReq = gfAddCR( spec_ins.Spec_Inst)
		creqtype = UPPER( ALLT( spec_ins.TYPE))
	ENDIF

	IF NOT USED("pc_depofile")
		WAIT WINDOW "Getting Deponent's information" NOWAIT NOCLEAR 

		l_mail=oMed.sqlexecute("exec dbo.GetDepInfoByMailIdDept '" ;
			+ timesheet.MailID_No +"','" ;
			+ ALLTRIM(spec_ins.dept) + "' ", "pc_DepoFile")
		=CURSORSETPROP("KeyFieldList", "Code, id_tbldeponents", "pc_DepoFile")

	ENDIF


	DO PrintField WITH mv, "InfoText", szEdtReq
	DO PrintField WITH mv, "Info", TheInfo

	DO PrintField WITH mv, "RequestCode", IIF( creqtype = "S", "SUBP", "AUTH")

	DO PrintField WITH mv, "SecondRequest", "0"
	DO PrintField WITH mv, "SecRequest", "0"
	DO gfPrtGrp

	DO PrintGroup WITH mv, "Control"
	DO PrintField WITH mv, "Date",  DTOC( mdate)

	DO PrintField WITH mv, "LrsNo", pc_lrsno
	DO PrintField WITH mv, "Tag", STR( ntag)

	*DO PrintGroup WITH mv, "Contact"
	*DO PrintField WITH mv, "Name", szwrkname
	*DO PrintField WITH mv, "Extension", szext
	*DO PrintField WITH mv, "Phone", szThePhone

	DO PrintGroup WITH mv, "Deponent"
	DO PrintField WITH mv, "Name", c_deponame

	*c_rolodex = gfMailN( F.MailID_No)
	DO PrintField WITH mv, "Addr", ;
		PROPER(ALLTRIM( pc_depofile.add1)) + ' ' + PROPER(ALLTRIM( pc_depofile.add2 ))
	DO PrintField WITH mv, "City", PROPER(ALLTRIM(pc_depofile.city))
	DO PrintField WITH mv, "State", pc_depofile.state
	DO PrintField WITH mv, "Zip", pc_depofile.zip
	DO PrintField WITH mv, "Extra", szattn

	DO PrintGroup WITH mv, "Plaintiff"

	DO PrintField WITH mv, "FirstName", pc_plnam
	DO PrintField WITH mv, "MidInitial", ""
	DO PrintField WITH mv, "LastName", ""
	DO PrintField WITH mv, "Addr1", pc_pladdr1
	DO PrintField WITH mv, "Addr2", pc_pladdr2
	IF TYPE('pd_pldob')<>"C"
		pd_pldob=DTOC(pd_pldob)
	ENDIF
	DO PrintField WITH mv, "BirthDate",  pd_pldob
	DO PrintField WITH mv, "SSN", pc_plssn
	IF TYPE('pd_pldod')<>"C"
		pd_pldod=DTOC(pd_pldod)
	ENDIF
	DO PrintField WITH mv, "DeathDate", pd_pldod
	DO PrintField WITH mv, "Extra", ;
		IIF( NOT EMPTY( pc_maiden1), "A.K.A.: " + TRIM( pc_maiden1), "")

	gcCl_code = pc_clcode
	gntag = ntag
	mclass = "TXReprint"
	DO prtenqa WITH mv, mclass, "1", ""
	WAIT CLEAR 
	RETURN
