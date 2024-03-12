PROCEDURE pWrQuest
******************************************************************************
*EF Texas Notice of Intention to take deposition by written question
******************************************************************************
* 07/12/06 EF  Updated signer's name to Chris Jones.
* 03/08/06 EF  Added to the VFP project.
*-----------------------------------------------------------------------------
* 12/06/04 DMA Update notice signature from Sheri to Andrew R. Kirby
* 06/28/04 DMA Switch to global variables for case-level data
*              Eliminate pagecount, cl_code as parameters
*              Replace bnot w/pl_noticng
* 06/09/04 DMA Extracted from PrtTXQst
** Called from Subp_PA, PrtTXNot, TxCrtLtr, GenUtils
** gfGetCas has already been called by upper-level routine
** Calls  gfAddCR, PrintField, PrintGroup

PARAMETERS n_Tag, c_mdep, c_mid

PRIVATE c_nameinv, c_nameinvp, c_ratadd1, c_ratadd1p, ;
	c_ratadd2, c_ratadd2p, c_ratcszP, c_ratcsz, c_date1, c_roloname, c_sign

dbInit = ALIAS()
ots = CREATEOBJECT("medtimesheet")
_SCREEN.MOUSEPOINTER=11
IF NOT USED( "Tabills")
	l_Tabill=gettabill(pc_clcode)
	IF NOT l_Tabill
		gfmessage("Cannot get TAbills file")
		RETURN
	ENDIF
ENDIF
SET PROCEDURE TO ta_lib ADDITIVE


IF NOT USED('Request')
	**10/01/18 SL #109598
	*C_STR ="SELECT * FROM tblRequest  with (INDEX (ix_tblRequests)) " 
	C_STR ="SELECT * FROM tblRequest " ;
		+ " where id_tblmaster='" + MASTER.ID_TBLMASTER + "' AND TAG ='" + STR(n_Tag) + "' AND DELETED IS NULL ORDER BY TAG"
	l_gotReq=ots.sqlexecute(C_STR,"Request")
ENDIF



SELECT REQUEST

*SET ORDER TO cltag
*SEEK pc_clcode + "*" + STR(ntag)
*SEEK TAMaster.cl_code + "*" + STR(ntag)
* 04/03/2002 MNT - Corrected Date of Notice ***
c_date1=CTOD(LEFT(DTOC(REQUEST.Open_Date),10))
d_reqdate=CTOD(LEFT(DTOC(REQUEST.req_Date),10))

DO PrintGroup WITH mv, "TX_WrQuest"

DO PrintField WITH mv, "Loc", ;
	IIF( INLIST( pc_offcode, "G", "M"), "P", pc_offcode)
*   IIF( INLIST( tamaster.lrs_nocode, "G", "M"), "P", TAMaster.lrs_nocode)

DO PrintField WITH mv, "RT", pc_lrsno + "." + ALLTRIM( STR( n_Tag))
*!*	IF d_reqdate<{07/12/2006}
*!*		DO PrintField WITH mv, "Signature", IIF( pl_noticng, "", "/S/ Andrew R. Kirby")
*!*	ELSE
*!*		DO PrintField WITH mv, "Signature", IIF( pl_noticng, "", "/S/ Chris Jones")
*!*	endif
c_sign=""
DO CASE
CASE d_reqdate<{07/12/2006}
 	c_sign="/S/ Andrew R. Kirby"
CASE BETWEEN(d_reqdate,{07/13/2006}, {11/21/2006})
	c_sign="/S/ Chris Jones"
OTHERWISE
	c_sign = "/S/ Sheri Scott"
ENDcase
DO PrintField WITH mv, "Signature", IIF( pl_noticng, "", c_sign)
DO PrintField WITH mv, "PertainsTo", ALLTRIM( pc_plnam)

DO PrintField WITH mv, "RequestDate", DTOC(c_date1)
DO IfNOTXCourT
DO GFTXCOUR
IF NOT EMPTY(timesheet.ID_TBLTimesheet)
	*IF NOT USED( "Spec_ins")
	*c_code =fixquote(pc_clcode)
	**10/01/18 SL #109598
	*l_spec=ots.sqlexecute("select * from tblspec_ins with (INDEX (ix_tblSpec_ins)) " 
	l_spec=ots.sqlexecute("select * from tblspec_ins " ;
		+ " where id_tblTimesheet ='" +timesheet.ID_TBLTimesheet + "'","Spec_ins")
	*ots.sqlexecute("select * from tblspec_ins where cl_code = '" + c_code + "' and tag=' " + STR(n_Tag) + "'", "Spec_ins")
ELSE
	l_spec=.F.
ENDIF
IF l_spec
	SELECT Spec_ins
	szEdtReq = ""
	*LOCATE FOR ID_TBLTimesheet =timesheet.ID_TBLTimesheet
	*IF FOUND()

	*SET ORDER TO cltag
	*IF SEEK( pc_clcode + "*" + ALLTRIM( STR( n_Tag)))
	szrequest = Spec_ins.spec_inst
	* 05/28/03 DMA Use new utility routine
	* 06/24/04 DMA Pass field width to routine
	szEdtReq = gfAddCR( Spec_ins.spec_inst) &&, 68)
	*ENDIF
ELSE
	szEdtReq=""
ENDIF
DO PrintField WITH mv, "InfoText", szEdtReq

DO PrintGroup WITH mv, "Case"
DO PrintField WITH mv, "Plaintiff", pc_plcaptn
DO PrintField WITH mv, "Defendant", pc_dfcaptn
DO PrintField WITH mv, "Docket", pc_docket
IF TYPE('pd_pldob')<>"C"
			pd_pldob=DTOC(pd_pldob)
ENDIF
DO PrintField WITH mv, "BirthDate", pd_pldob
DO PrintField WITH mv, "SSN", pc_plssn
*IF pl_ofcHous
DO PrintField WITH mv, "Extra", TRIM( pc_maiden1)
*ENDIF
DO PrintField WITH mv, "AttyType", IIF( pl_plisrq, "P", "D")

*IF NOT USED("pc_depofile")
_SCREEN.MOUSEPOINTER=11
l_mail=ots.sqlexecute("exec dbo.GetDepInfoByMailIdDept '" + timesheet.MAILID_NO +"','" + ALLTRIM(Spec_ins.dept)+ "' ", "pc_DepoFile")
=CURSORSETPROP("KeyFieldList", "Code, id_tbldeponents", "pc_DepoFile")
_SCREEN.MOUSEPOINTER=0
*endif



DO PrintGroup WITH mv, "Deponent"

c_Dname = ALLTRIM( PROPER( c_mdep))
ncnt2 = AT( "(", (ALLTRIM( c_Dname)), 1)
IF ncnt2 <> 0
	irest = LEN( c_Dname)
	c_Dpart1 = LEFT( (ALLTRIM( c_Dname)), ncnt2)
	c_Dpart2 = UPPER( RIGHT( ALLTRIM( c_Dname), irest-(ncnt2)))
	c_mdep = PROPER( c_Dpart1) + (c_Dpart2)
ENDIF

DO PrintField WITH mv, "Name", c_mdep
DO PrintField WITH mv, "Addr", ALLTRIM(pc_depofile.add1 + ' ' + pc_depofile.add2)
DO PrintField WITH mv, "City", ALLTRIM(pc_depofile.City)
DO PrintField WITH mv, "State", pc_depofile.State
DO PrintField WITH mv, "Zip", pc_depofile.Zip

*lltaatty = gfuse("Taatty")
*SET ORDER TO at_code
STORE "" TO c_nameinv, c_nameinvp, c_ratadd1p, c_ratadd2p, c_ratcszP, ;
	c_AttyInfo, c_ratadd1, c_ratadd2, c_ratcsz, c_Pltcap, c_AtName

IF NOT EMPTY( pc_rqatcod)

	pl_GetAt = .F.
	DO gfatinfo WITH fixquote(pc_rqatcod), "M"
	c_AtName = pc_AtyName
	c_nameinv = pc_AtySign
	c_ratadd1 = pc_Aty1Ad
	c_ratadd2 = pc_Aty2Ad
	c_ratcsz = pc_Atycsz
	c_phone = pc_AtyPhn
	c_Firm = pc_Atyfirm
	lcAlias = SELECT()
	l_BarNum=ots.sqlexecute("SELECT dbo.fn_AttyBarNum('" + fixquote(pc_rqatcod) + "')", "AtBarNum")
	c_Tba=IIF(l_BarNum,AtBarNum.EXP, "")
	SELECT ( lcAlias)

	*IF SEEK( pc_rqatcod)

	*szAtName = ALLTRIM( Taatty.newfirst) + " " + ALLTRIM( Taatty.newlast)
	*mnameinv = ALLTRIM( name_inv)
	* mratadd1 = ALLTRIM( newadd1)
	*mratadd2 = ALLTRIM( newadd2)
	* mratcsz = ALLTRIM( newcity) + ", " + ALLTRIM( newstate) ;
	*  + "  " + ALLTRIM( newzip)
	*mPhone = STR( Taatty.phone)
	*mFirm = ALLTRIM( Taatty.firmname)
	*mTba = ALLTRIM( TAAtty.BarNumber)
	*ENDIF
ENDIF

DO PrintGroup WITH mv, "Atty"
DO PrintField WITH mv, "Name_inv", c_nameinv
DO PrintField WITH mv, "Ata1", c_Firm
DO PrintField WITH mv, "Ata2", c_ratadd2
DO PrintField WITH mv, "Atacsz", c_ratcsz
DO PrintField WITH mv, "Ata3", c_Tba
SELECT TABills
SET ORDER TO cl_code
iCnt = 0                                          && 2/6/02 per Sheri's request
i = 1
DIMENSION ARCol1[55]
DIMENSION ARCol2[55]
STORE "" TO ARCol1, ARCol2

IF SEEK( ALLTRIM( pc_clcode))
	DO WHILE ALLTRIM( TABills.cl_code) == ALLTRIM( pc_clcode) AND NOT EOF()
		IF ALLTRIM( TABills.at_code) = ALLTRIM( pc_rqatcod)
			SKIP
			LOOP
		ENDIF
		* SELECT Taatty
		*SET ORDER TO at_code
		pl_GetAt = .F.
		DO gfatinfo WITH fixquote(TABills.at_code), "M"
		*IF SEEK( TABills.at_code)
		iCnt = iCnt + 1
		c_PlAtty = pc_AtySign
		*ALLTRIM( Taatty.newfirst) + " " + ;
ALLTRIM( Taatty.newlast)
		c_AttyInfo = STR( iCnt) + ". " + UPPER( c_PlAtty) + "," &&IIF( icnt=i, ".", ", ")

		IF iCnt%2 <> 0
			ARCol1[I] = ARCol1[I] + CHR(13) + c_AttyInfo
		ELSE
			ARCol2[I] = ARCol2[I] + CHR(13) + c_AttyInfo
		ENDIF
		*ENDIF
		SELECT TABills
		SKIP
		LOOP
	ENDDO
	DO PrintGroup WITH mv, "Item"
	DO PrintField WITH mv, "Tag", ARCol1[i]
	DO PrintField WITH mv, "Name", ARCol2[i]

ENDIF
_SCREEN.MOUSEPOINTER=11
SELECT ( dbInit)
WAIT CLEAR

RETURN
*************************************************************************
PROCEDURE IfNoTxCourt
PRIVATE c_Alais AS String
c_AlIAS=ALIAS()
IF NOT USED ("TXCourt")
	o = CREATE("generic.medgeneric")
	o.sqlexecute("exec GetAllTxCourt", "TxCourt")
	pc_TxCtTyp = SUBS( pc_Court1, 1, 3)
	SELECT TxCourt
	CURSORSETPROP("KeyFieldList", "COURT,CRT_ID,County", "TXCourt")
	INDEX ON COURT TAG COURT
	INDEX ON CRT_ID TAG CRT_ID
	DO CASE

		CASE pc_TxCtTyp = "FED"
			INDEX ON CRT_ID TAG Federal FOR CRTType = "FED"
			SET ORDER TO Federal
			SEEK( pc_Court2)
			pc_TxHold  = "(14) fourteen"
			DO CASE

				CASE pc_Court2 == "US-DOL"
					pc_TxCtLn1 = "UNITED STATES DEPARTMENT OF LABOR"
					pc_TxCtLn2 = "OFFICE OF ADMINISTRATIVE LAW JUDGES"

					* 06/29/04 DMA Copied Georgia/Federal from gfTxCour for consistency
				CASE UPPER(ALLTRIM(pc_area)) = "GEORGIA"
					pc_TxCtLn1 = ""
					pc_TxCtLn2 = "IN THE SUPERIOR COURT OF FULTON COUNTY"
					pc_TxCtLn3 = "STATE OF GEORGIA"

				OTHERWISE
					pc_TxCtLn1 = "UNITED STATES DISTRICT COURT"
					pc_TxCtLn2 = ALLT( TxCourt.District) + " DISTRICT"
					pc_TxCtLn3 = ALLT( TxCourt.Division) + " DIVISION"

			ENDCASE

		CASE pc_TxCtTyp = "CCL"
			INDEX ON County TAG CCL FOR CRTType = "CCL"
			SET ORDER TO CCL
			SEEK pc_plCnty
			* 06/15/04 DMA Correct phrasing on court title
			pc_TxCtLn1 = "In the County Civil"
			pc_TxCtLn2 = "Court At Law No. " + ALLT( pc_cclnum)
			*         pc_TxCtLn1 = "In the County Court"
			*         pc_TxCtLn2 = "At Civil Law No. " + ALLT( pc_cclnum)
			pc_TxCtLn3 = ALLT( pc_plCnty) + " County, Texas"
			pc_TxHold  = "(20) twenty"

		CASE pc_TxCtTyp = "DIS"
			INDEX ON County TAG District FOR CRTType = "DIS"
			SET ORDER TO District
			SEEK pc_plCnty
			* 06/29/04 Copied WV handler from gfTXCour for consistency
			pc_TxCtLn1 = "In the " + UPPER( ALLT( pc_distrct)) + ;
				IIF( UPPER(ALLTRIM(pc_area)) = "WESTVIRGINIA", " Circuit", " District")
			pc_TxCtLn2 = "Court In and For "
			pc_TxCtLn3 = UPPE( ALLT( TxCourt.County)) + " County, " + ;
				IIF( UPPER(ALLTRIM(pc_area)) = "WESTVIRGINIA", "West Virginia", "Texas")
			pc_TxHold  = "(20) twenty"
	OTHERWISE
		STORE "" TO pc_TxCtLn1,	pc_TxCtLn2,	pc_TxCtLn3, pc_TxHold 
	ENDCASE


ENDIF
SELECT (c_AlIAS)
return
