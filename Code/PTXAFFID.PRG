PROCEDURE PTXAffid
** Called from Subp_Pa when generating original request by paper or fax
** Called from GenUtils when reprinting the affidavits only
** Calls gfTXCour, gfLkUp, gfMailN, PrintGroup, PrintField
** Replaces RepTxAff in TxReprin
** Assumes that gfGetCas has been already called for case-level globals
** and that public variable nTag contains the tag number being printed.
***
***
**EF 3/8/06 -added to the vfp project
*-------------------------------------------------------------------------
** 02/18/2002  DMA  Add Echocardiogram option
** 06/10/04 DMA Extracted from Subp_Lib for use as Standalone module
*------------------------------------------------------------------------
*Print Texas affidavits
*--------------------------------------------------
PARAMETERS cDept2
* cDept2 is the string of department codes for which affidavits must be printed
PRIVATE i, nRec, cdept, lcEnt, c_rolodex, c_MailID, lc_CurOrder
oMed =createobject('medgeneric')
SET PROCEDURE TO ta_lib ADDITIVE
nRec = LEN( cDept2)
i = 1

DO WHILE .T.
	IF i > nRec
		EXIT
	ENDIF
	cdept = SUBSTR( cDept2, i, 1)

	DO CASE

		CASE cdept = "E"
			szAffType = "ECHOCARDIOGRAM VIDEOS"
			TheInfo = "ECHO"
			szItem = "VIDEOS"

		CASE cdept = "R"
			szAffType = "RADIOLOGY RECORDS"
			TheInfo = "RAD"
			szItem = "FILMS"

		CASE cdept = "P"
			szAffType = "PATHOLOGY MATERIALS"
			TheInfo = "PATH"
			szItem = "SLIDES/BLOCKS"

		CASE cdept = "B"
			szAffType =  "BILLING RECORDS"
			TheInfo = "BILLS"
			szItem = "PAGES"

		CASE cdept = "M"
			szAffType = "MEDICAL RECORDS"
			TheInfo = "MED"
			szItem = "PAGES"

		CASE cdept = "S"
			szAffType = "BUSINESS RECORDS"
			TheInfo = "S"
			szItem = "PAGES"

		CASE cdept = "G"
			szAffType = ""
			TheInfo = "G"
			szItem = ""

		OTHERWISE
			szAffType = "RECORDS"
			TheInfo = "NR"
			szItem = "PAGES"
	ENDCASE

	i = i + 1

	DO PrintGroup WITH mv, IIF( cdept=="G", "TX_GenAff", "TX_Affid")


	*lcEnt = pc_entryn
	*SELECT( pc_entryn)
	SELECT timesheet

	c_MailID = MailID_No
	mdep = ALLTRIM( DESCRIPT)
	sDname = PROPER( mdep)
	ncnt2 = AT( "(", (ALLTRIM( sDname)), 1)
	IF ncnt2 <> 0
		irest = LEN( sDname)
		sDpart1 = LEFT( PROPER( ALLTRIM( sDname)), ncnt2)
		sDpart2 = UPPER( RIGHT( ALLTRIM( sDname), irest - (ncnt2)))
		mdep = PROPER( sDpart1) + PROPER( sDpart2)
	ENDIF

	DO PrintField WITH mv, "Attn", ALLTRIM( szAffType)
	DO PrintField WITH mv, "Items", ALLTRIM( szItem)
	DO PrintField WITH mv, "Tag", STR( ntag)

	l_ST=oMed.sqlexecute("SELECT dbo.gfState('" + IIF(EMPTY(pc_depofile.state),"TX",pc_depofile.state) + "')", "DepSt")
	lc_State=IIF(l_ST,DepSt.EXP, "")
	lcPrtState = ""
	lcPrtState = ALLTRIM(UPPER( lc_State))
	DO PrintField WITH mv, "DepState", lcPrtState


	** Get and print court data
	IF pl_OfcHous
		DO gfTXCour && IN gftxcour WITH ALLTRIM( TAMaster.court)
	ELSE
		SELECT court
	ENDIF

	SELECT timesheet

	DO PrintGroup WITH mv, "Case"
	DO PrintField WITH mv, "Plaintiff", ALLTRIM( pc_plcaptn)
	DO PrintField WITH mv, "Defendant", ALLTRIM( pc_dfcaptn)
	DO PrintField WITH mv, "Docket", pc_docket


	DO PrintGroup WITH mv, "PlCaption"
	DO PrintField WITH mv, "FirstName", pc_plnam
	DO PrintField WITH mv, "MidInitial", ""
	DO PrintField WITH mv, "LastName", ""

	DO PrintGroup WITH mv, "Deponent"
	DO PrintField WITH mv, "Name", mdep
	DO PrintField WITH mv, "Addr", ;
		PROPER(ALLTRIM( pc_depofile.add1)) + ' ' + PROPER(ALLTRIM( pc_depofile.add2 ))
	DO PrintField WITH mv, "City", PROPER(ALLTRIM(pc_depofile.city))
	DO PrintField WITH mv, "State", pc_depofile.state
	DO PrintField WITH mv, "Zip", pc_depofile.zip
ENDDO
pl_TXAffid = .F.
RETURN
