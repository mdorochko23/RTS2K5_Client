	**************************************************************************
*PROCEDURE eclnotice
	PARAMETER mratcode, nTAG, lFax


	PRIVATE lc_NameInv, lc_Ratadd1, lc_Ratadd2, lc_Ratadd3, lc_RAtFax, ;
		lc_RqAtType, mLrs, mrpltcap, mrdefcap, mrdocket, mrterm, szSpcIns, ;
		lcTagName, lcNotice, lc_NoObjmde, lc_Waive, lc_Intrgtion, ;
		ld_Deposit, lcInit, lc_EmailAdd

	STORE "" TO lc_NoObjmde, lc_Waive, lc_Intrgtion, lc_NameInv, lc_Ratadd1, ;
		lc_Ratadd2, lc_Ratadd3, lc_RAtCSZ, lc_RAtFax, lc_RqAtType, ;
		lcInit, lc_EmailAdd
	_SCREEN.MOUSEPOINTER=11	
	WAIT WINDOW "Printing Notice page. Please wait." NOWAIT NOCLEAR
	
	oMed = CREATEobject("generic.medgeneric")
	c_Alias = SELECT()
			
	*l_HowNot=oMed.sqlexecute("SELECT dbo.AttyNoticeSend('" + mratcode + "')", "AtNot")
	lc_SendType = IIF(lFax,"F", "P")
			
	
	
	l_Notice= getNotice (pc_clcode, ntag)
	IF NOT l_Notice
		gfmessage('Cannot open the PsNotice File.')
		RETURN
	ENDIF

	llHoldFlag = .F.
	lCourtSet=.f.
	
	SET PROCEDURE TO ta_lib ADDITIVE

	c_TrimArea = UPPER( ALLTRIM( pc_area))
	
	contphone = ""	
	contname= pc_amgr_nm 
	contphone=pc_amgr_ph
	
	IF EMPTY(contphone)
		contphone = "(800) 355-7400"                 && Direct dial phone number
	ENDIF
	 
	
	IF NOT USED("court")
		omed.sqlexecute("exec dbo.GetAllCourt", "court")
	ENDIF

	SELECT COURT
	SELECT DISTINCT COURT.DESC ;
		FROM COURT INTO ARRAY bcourtd ;
		WHERE ALLTRIM(COURT.COURT)==ALLTRIM(pc_Court1)
	bcourt = ALLT( IIF( _TALLY > 0 AND NOT EMPTY( bcourtd[1]), ;
		bcourtd[1], master.COURT))

	IF pl_RepNotc
		mclass = "RepNot"
	ENDIF

	mgroup = "1"
	platp = .F.                                     && Keep track of plaintiff attorney's notice being printed
	csuborauth = "A"                                && Defaults, to be set later correctly
	nbal = 0
	
	

	* 07/23/04 DMA Use new long plaintiff name
	* 12/23/03 DMA Remove deleted litigations E1, E2, E3
	IF NOT INLIST( pc_litcode, "D  ", "E  ")
		mrpltcap  = IIF( llHoldFlag OR pl_zicam, ALLTRIM( pc_plcaptn), pc_plnam)
	ELSE
		mrpltcap = pc_plnam
	ENDIF

	mrdefcap  = ALLTRIM( pc_dfcaptn)
	mrdocket  = ALLTRIM( pc_docket)

	mrduedate = DTOC( PSNOTICE2.due_date)
	mrddtword = pd_request
	mrterm = ALLT(  pd_term)
	mLrs   = pc_lrsno
	
	c_AtNot = mratcode
	

	****************************
	c_Atty=fixquote(c_AtNot)
	pl_GetAt = .F.
	DO gfatinfo WITH c_Atty, "M"
	szAtName = pc_AtyName

	lc_NameInv = pc_AtySign &&ALLTRIM(Name_inv)
	lc_Ratadd1 = pc_AtyFirm &&ALLTRIM( firm)
	lc_Ratadd2 = pc_Aty1Ad &&ALLTRIM( NewAdd1)
	lc_Ratadd3 =pc_Aty2Ad &&ALLTRIM( NewAdd2)
	lc_RAtCSZ = pc_Atycsz &&ALLTRIM( NewCity + " " + NewState + "  " + NewZip)
	lc_RAtFax = pc_AtyFax
	c_fax = STRTRAN( lc_RAtFax, " ", "")
	c_temp = STRTRAN( c_fax, "-", "")
	c_temp2 = STRTRAN( c_temp, "(", "")
	lc_FaxNum = "1"+ STRTRAN( c_temp2, ")", "")	
	ll_FaxNotice = (NOT EMPTY( pc_AtyFax) AND lc_SendType == "F")
	ll_EmailNot = (NOT EMPTY( pc_AtyFax) AND lc_SendType == "E")
	
&& Get Requesting Attorney Info!!
	*******************
	c_Atty=fixquote(pc_rqatcod)
	pl_GetAt = .F.
	DO gfatinfo WITH c_Atty, "M"
	mrrqatname = ""
	
	lcInit= pc_AtyName	
	mrrqatname = ALLTRIM(pc_AtySign)
	

&& Get Requesting Attorney Type!!
	lc_RqAtType = IIF( pl_plisrq, "Plaintiff", "Defendant")
	lcNotice = ""

	SELECT REQUEST
	LOCATE FOR cl_code =PC_CLCODE AND TAG =nTAG
	
	pl_GotDepo = .F.
	DO gfGetDep WITH PC_CLCODE, nTAG
	
	l_Autho=.T.
	*IF NOT l_Autho
		*lcNotice = IIF( pl_FromRev, pc_ltsfnot, pc_litsnot)
	*ELSE
		lcNotice = IIF( pl_FromRev, pc_litfnot, pc_litnotc)
	*ENDIF

	IF pl_MDasb AND NOT l_Autho
		lcNotice = "NotDuces"
	ENDIF
	IF pl_MdlHold
		lcNotice = "HoldRezNot"
	ENDIF
	IF pl_RezNY
		lcNotice = "NoticeAuthor"
	ENDIF

	
		DO PrintGroup WITH mv, IIF( NOT EMPTY( lcNotice), ALLT( lcNotice), ;
			"NoticeAuthor")
		DO PrintField WITH mv, "Loc", ;
			IIF( pl_ofcPgh OR pl_ofcMD, "P", pc_offcode)
		DO PrintField WITH mv, "FaxLoc", ;
			IIF( pl_ofcPgh OR pl_ofcMD, "P", pc_offcode)
		**09/12/05 start- intergel/florida changes to a notice page

		DO PrintField WITH mv, "WebAddress", ;
			IIF( pl_IRGFl, "", " OR REPLY THROUGH OUR WEB SITE AT Recordtrak.com")

		****end 9/12/05


	
	DO PrintField WITH mv, "DueDate", mrduedate
	**EF 08/29/03
	IF pl_MDasb AND NOT l_Autho
		DO PrintField WITH mv, "Deposit", DTOC( ld_Deposit)
	ENDIF
	**06/20/03 baycol special data
	IF pl_Baycol AND NOT l_Autho
		DO PrintField WITH mv, "ReqAtty", mrrqatname
		DO PrintField WITH mv, "NoticeDif", IIF( pl_FromRev, ;
			"as 10 day notice that, in the absence of any objection within 10 day period, RecordTrak will be", ;
			"to notify you that RecordTrak is" )
		DO PrintField WITH mv, "Listed", IIF( pl_FromRev, "NOT", "")
	ENDIF
	**06/20/03
	DO PrintGroup WITH mv, "Case"

	DO PrintField WITH mv, "LRS", mLrs
	DO PrintField WITH mv, "Name", pc_plnam
	DO PrintField WITH mv, "Plaintiff", mrpltcap
	DO PrintField WITH mv, "Defendant", mrdefcap
	DO PrintField WITH mv, "AttyName", mrrqatname
	IF NOT pl_CAVer
		DO PrintField WITH mv, "AttyType", IIF( lc_RqAtType = "Defendant", "D", "P")
	ENDIF
	DO PrintField WITH mv, "Court", PROPER( bcourt )
	DO PrintField WITH mv, "Term", mrterm
	DO PrintField WITH mv, "Docket", mrdocket

NOTE ³ Following array logic included by Mark Rizzo on 11/12/97
NOTE ³ to correct the passing of attorney rolodex fields.
	DO PrintGroup WITH mv, "Atty"

	laRTS = ""
	lcRPS = ""
	DIMENSION laRTS[5]
	DIMENSION laRPS[5]
	laRTS[1] = "lc_NameInv"
	laRTS[2] = "lc_RAtAdd1"
	laRTS[3] = "lc_RAtAdd2"
	laRTS[4] = "lc_RAtAdd3"
	laRTS[5] = "lc_RAtCSZ"
	laRPS[1] = "Name_inv"
	laRPS[2] = "Ata1"
	laRPS[3] = "Ata2"
	laRPS[4] = "Ata3"
	laRPS[5] = "Atacsz"
	lnRTS = 0
	FOR nLoop = 1 TO 5
		lnRTS = lnRTS + 1
		DO WHILE lnRTS < 6
			IF EMPTY(&laRTS[lnRTS].)
				lnRTS = lnRTS + 1
			ELSE
				EXIT
			ENDIF
		ENDDO
		IF lnRTS < 6
			DO PrintField WITH mv, laRPS[nLoop], &laRTS[lnRTS].
		ELSE
			DO PrintField WITH mv, laRPS[nLoop], " "
		ENDIF
	NEXT nLoop

	DO PrintField WITH mv, "FaxNo", lc_RAtFax

	DO PrintGroup WITH mv, "Contact"
	DO PrintField WITH mv, "Name", contname
	DO PrintField WITH mv, "Phone", contphone


	*------------------------------------------------------------------------
	*EF  caseinfo
	* 08/28/02 DMA Use public vbls for group/case information
	*------------------------------------------------------------------------

	IF pl_ofcKOP OR pl_ofcMD OR pl_ofcPgh OR  pl_ofcHous
		pl_KOPVer=.T.
	ENDIF
	IF pl_KOPVer  AND NOT pl_zicam
		DO gfPrtGrp
	ENDIF
	*------------------------------------------------------------------------


	**** This is for the list of record custodians

	CREATE CURSOR AutoSubp (DepTag N(3))

	x = 0
	SET MEMOWIDTH TO 75
	_PLENGTH = 57

&& Print List of Notices!!
	SELECT PSNOTICE2
	

	
	DO PrintField WITH mv, "RequestDate", DTOC( PSNOTICE2.txn_date)
	c_sql=" Exec [dbo].[GetIssueLine] '" + fixquote(PC_CLCODE)+ "','" + ALLTRIM(STR(PSNOTICE2.TAG) )+ "'"

	*c_sql="SELECT * FROM tbltimesheet with (nolock,index(IX_tblTIMESHEET)) WHERE cl_code='" + ;
				fixquote(PC_CLCODE) + "' AND tag='" +  ;
				ALLTRIM(STR(PSNOTICE.TAG) )+ "' AND txn_code=11"
	oMed.sqlexecute(c_sql,'Timesheet2')

			SELECT timesheet2
					

			
				DO PrintGroup WITH mv, "Item"
				DO PrintField WITH mv, "Tag", ALLTRIM( STR( PSNOTICE2.TAG))
				DO PrintField WITH mv, "Name", "____ " + ALLTRIM( timesheet2.DESCRIPT)
				DO PrintField WITH mv, "InfoText", PSNOTICE2.spec_inst
			

			INSERT INTO AutoSubp ;
				(DepTag) ;
				VALUES ;
				(timesheet2.TAG)
		

	IF TYPE( "llHoldFlag")="U"
		llHoldFlag=.F.
	ENDIF

	IF USED( "AutoSubp")
		*recused = gfuse( "record")
		SELECT REQUEST
		* SET ORDER TO cltag

		SELECT AutoSubp
		GO TOP
		SCAN
			SELECT REQUEST
			*IF SEEK( pc_clcode + "*" + STR( AutoSubp.DepTag))
			** Changed 5/26/98 to print Subpoenas for "Attached" Notice form
			*--3/26/03 kdl start: update tag variables before call to subp_pa
			pl_GotDepo = .F.
			DO gfGetDep WITH PC_CLCODE, AutoSubp.DepTag


			IF (REQUEST.TYPE <> "A") AND NOT lCourtSet
				*--3/26/03 kdl end:
				* IF (Record.type <> "A") AND llHoldFlag AND NOT lcourtset
				**EF 02/10/05 -do not fax subps if original is requested
				pl_FaxSubp = IIF(pl_c1Form,ll_FaxNotice,.F.)

				IF pl_FaxSubp
					szfaxnum =IIF (LEN(ALLTRIM(lc_FaxNum))<10,'',lc_FaxNum)
				ENDIF

				**********

				IF NOT USED('Spec_ins')
					oMed.sqlexecute("exec dbo.GetSpec_Insbyclcode '"+PC_CLCODE+"'", "Spec_Ins")
				ENDIF

				*DO subp_pa WITH .T., 2, AutoSubp.DepTag, .T., .F., lCourtSet,.T.
				pl_FaxSubp = .F.
			ENDIF
			*ENDIF
			SELECT AutoSubp
		ENDSCAN

		
	
		IF NOT lCourtSet
			SELECT AutoSubp
			USE
			SELECT timesheet2
			USE
			SELECT Psnotice2
			use
		ENDIF
		
	ENDIF
	IF NOT EMPTY(c_alias)
	SELECT (c_Alias)
	ENDIF
	_SCREEN.MOUSEPOINTER=0
	RETURN
	******************************************
PROCEDURE GetNotice

PARAMETERS c_client, n_tag
LOCAL l_RetVal as Boolean, l_done as Boolean, C_STR as String
oMed = CREATEOBJECT("generic.medgeneric")
c_Clcode=oMed.cleanstring(c_client)
STORE .f. to l_RetVal, l_done

**10/01/18 SL #109598
*C_STR="SELECT * FROM tblPSnotice with (NOLOCK,INDEX (ix_tblPSnotice_1)) " 
C_STR="SELECT * FROM tblPSnotice with (NOLOCK) " ; 
+ " where tblPSnotice.Cl_Code =" + c_Clcode ;
+ " and tag ='" + STR(n_tag) + "' and active=1"
l_done=oMed.sqlexecute(C_STR, "PSnotice2")
IF l_done THEN
	l_RetVal=.T.	
	=CURSORSETPROP("KeyFieldList", "ID_tblPSnotice,Cl_code, USER_CODE", "PSnotice2")
	INDEX ON ALLTRIM(USER_CODE)+ALLTRIM(CL_CODE) FOR .NOT.PRINTED TAG TOPRINT ADDITIVE
	INDEX ON ALLTRIM(USER_CODE)+ALLTRIM(CL_CODE) TAG REPRINT ADDITIVE
	INDEX ON CL_CODE TAG CL_CODE ADDITIVE
	
ENDIF
RETURN l_RetVal
	
