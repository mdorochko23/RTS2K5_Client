PROCEDURE PrintCer
** EF 05/02/2012 - Added Inventory certs (Cardiology, Path and Rad)
** MD 07/11/2007 - Modified to create c_mark as Litigation + userctrl.initials
** EF 04/24/2007 - added the rpslitdata
** EF 03/19/2007 -added a spec mark field for the SRQ lit cases and call to the GetSpecInsForTag.
** EF 11/30/2005 -Switched to SQL
*--------------------------------------------------------------------------
*Program: printcer
*Date: 9/26/00
*By: EF
*Abstract: Print record certifications for each request
* Assumes that gfGetCas has been called in advance for case-level globals
* and gfGetDep has been called for tag-level globals
* Called By: subp_pa.prg, reprtcer.prg
* Calls: printgroup, printfield in ta_lib; gfAddCR
*
*Modifications:
* EF  04/29/05 Edit verbiage on all cert pages
* EF  03/25/05 Always print a "Medical Records" certification first
* kdl 07/09/04 Moved procedure setting save out of "if" condition
* DMA 07/09/04 Replace gsCertType with pc_CertTyp
* EF  06/17/04 Reset the "Set Procedure to" back to TA_LIB when called from subp_pa
* DMA 06/03/04 Use long plaintiff names, global variables
* EF  04/30/04 Fix a bug: update only a select record in the spec_ins file
* DMA 05/27/03 Use gfAddCR to format request and cert blurbs.
* EF  05/09/03 Added a new "C" (cardiac catheterization) type certification
* KDL 09/16/02 Add call to special cert form for Connecticut asbestos tags
*     when deponent types are either association or employer
* DMA 05/16/01 Account for duplicate txn_ids when searching spec_ins
* DMA 12/13/00 Add initialization to local variables
*
*--------------------------------------------------------------------------

*PROCEDURE pPrtCert
PARAMETERS ntag, bReq, ntxn_id
PRIVATE dbInit, dbSpec_Ins, l_cCertType, nrec, l_nCnt, l_cCert, ncnt, l_cCert2, ;
	l_cType, ntxn_id, l_cDblLtr, l_cDblLtr2, c_cltag, l_cert, c_Specmark, l_scancert
LOCAL lsMID, lsMDEP, lsCertType	&& 3/10/2022, ZD #265694, JH

dbInit = SELECT()

WAIT WINDOW "Printing certification page(s)." NOWAIT NOCLEAR
**05/30/2017 - TX courts (SUBPS) have their own affidafits
**10/26/16- #51529 Removed per non-programmed subp project
*IF pl_TxCourt  AND NVL(PC_ISSTYPE,'A')="S"
*11/16/2021 WY #256321 (include USDC-TX)  
IF (pl_TxCourt OR LEFT(PC_COURT1,7) = 'USDC-TX') AND NVL(PC_ISSTYPE,'A')="S"
	RETURN
ENDIF

IF (pl_TxCourt OR LEFT(PC_COURT1,7) = 'USDC-TX') AND NVL(PC_ISSTYPE,'A')="A"		&& 3/10/2022, ZD #265694, JH
	SELECT TIMESHEET
	lsMID = Alltrim(TIMESHEET.mailid_no)
	lsMDEP = Upper(Allt(TIMESHEET.Descript))
	SELECT Spec_ins
	lsCertType = UPPER(ALLTRIM(SPEC_INS.CERT_TYPE))
	Do txaffid with Iif(PL_REISSUE And PN_SUPPTO<>0 , PN_SUPPTO, NTAG), Alltrim(lsMDEP), Alltrim(lsMID), Nvl(lsCertType,'N')
	SELECT (dbInit)
	RETURN
ENDIF																				&& 3/10/2022

*-----------------------------------------------------------------
* 01/25/2018 MD #77400 remove check for pl_NosForm
l_scancert=.F.
*IF pl_nosform 
	** when ready to use the scanned certs- replace x with a correct type
	*l_scancert=findimg(ntag, "X")- TAG LEVEL (NOT USED)
	**a) check CERT type in the ScanDocLog - CASE LEVEL
			l_scancert=findcerts(.f.,ntag)	   	
	IF l_scancert
		RETURN
	ENDIF
	** 03/23/2018 MD do not print standard certs for scandocs only
	IF l_scancert=.F.
	    IF USED("viewRecSD")
	       USE IN viewRecSD
	    ENDIF 
	    LOCAL lnCurArea
	    lnCurArea=SELECT()
  		LOCAL oGenSD AS medGeneric OF generic
  		oGenSD=CREATEOBJECT("medGeneric")
  		oGenSD.sqlexecute("dbo.getRecScanDocs '"+ALLTRIM(pc_clcode)+"', '"+ALLTRIM(STR(ntag))+"'","viewRecSD")
  		RELEASE oGenSD
  		SELECT viewRecSD  		  
  		IF ALLTRIM(viewRecSD.scanDocs)=="1"
  		   USE IN viewRecSD  		   
  		   SELECT (lnCurArea)
  		   RETURN 
  		ENDIF 
  		SELECT (lnCurArea)
  	ENDIF 
*ENDIF
*-------------------------------------------------------------------
**10/26/16 -check for scanend certs on the non-programmed subp and skip in-house onces
STORE "" TO l_cType, l_cCert, l_cCert2, l_cCertType, c_Specmark
STORE 0 TO nrec, ncnt
SELECT 0
SELECT Spec_ins
l_cType = ALLTRIM( Spec_ins.cert_type)
l_cCertType = UPPER(l_cType)
szEdtReq = gfAddCR( szrequest)

IF EMPTY(szEdtReq)
	szEdtReq= GetSpecInsForTag(ntag)
ENDIF

*--- 04/01/2021 MD #227534  Florida State certs
IF LEFT(ALLTRIM(UPPER(NVL(PC_COURT1,""))),2)=="FL"
	DO printFLSTCert
	RETURN
ENDIF 	
*--- 04/01/2021 MD #227534
IF bReq <> 1

	LOCATE FOR id_tblSpec_ins=ntxn_id
	IF TAG = ntag AND cl_code = pc_clcode
		szEdtReq = gfAddCR( szrequest)
		pc_CertTyp = ALLTRIM( l_cType)
	ENDIF
ENDIF

*--7/09/04 kdl start: moved procedure setting save out of "if" condition

ncnt = RAT( "L", pc_CertTyp)
IF ncnt <> 0
	l_cCert = STRTRAN( pc_CertTyp, "L", "", 1, 2)
	SET PROCEDURE TO GLOBAL ADDITIVE
	l_cCert2 = getCertif()
	IF EMPTY( l_cCert2)
		gfmessage(" You must pick a certification type.")

		DO WHILE EMPTY( l_cCert2)
			l_cCert2 = getCertif()
			LOOP
		ENDDO
	ENDIF
	l_cCertType = ALLTRIM( l_cCert2) + ALLTRIM( l_cCert)
	SELECT Spec_ins
	REPLACE cert_type WITH pc_CertTyp
	LOCAL oGen AS medGeneric OF generic
	oGen=CREATEOBJECT("medGeneric")
	C_STR=""

	C_STR=" exec dbo.UpdCertsSpecInstruction   '" +   STR(ntxn_id) + "','" +pc_CertTyp + "'"


*!*		C_STR="update tblSpec_ins  set cert_type='" + pc_CertTyp + ;
*!*			"' where id_tblSpec_ins='" + STR(ntxn_id) + "' and  active =1"

	l_Retval= oGen.sqlexecute(C_STR,"")
	RELEASE oGen



ENDIF

**EF 3/25/05 - always print 'Med records' cert first
ncntr = RAT( "R", l_cCertType)
IF ncntr <> 0
	l_cert = STRTRAN( l_cCertType, "R", "", 1, 2)
	l_cCertType ="R" + l_cert
ENDIF
**EF -end

nrec = LEN( l_cCertType)
l_nCnt = 1
DO WHILE .T.
	IF l_nCnt > nrec
		EXIT
	ENDIF
	l_cDblLtr = SUBSTR( l_cCertType, l_nCnt, 1)
	l_cDblLtr2 = STRTRAN( l_cCertType, l_cDblLtr, "", 2,  1)
	l_cCert = SUBSTR( l_cDblLtr2, l_nCnt, 1)
	l_cCertType = l_cDblLtr2
	STORE "" TO l_cWhat, l_cWhat1, l_cBe, l_cTense, c_show

	DO CASE
*****05/02/12-start
	CASE INLIST(l_cCert ,'D','H','Y')
		l_cWhat = ""
		l_cWhat1 = ""
		l_cBe = ""
		l_cTense = ""
		c_show = ""
		DO CASE

		CASE l_cCert=="D"
			DO printgroup WITH mv, "Cert_IR"
		CASE l_cCert=="H"
			DO printgroup WITH mv, "Cert_IP"
		OTHERWISE
			DO printgroup WITH mv, "Cert_IC"
		ENDCASE



*****05/02/12-end
	CASE l_cCert == "X"
		l_cWhat = "radiology materials/records"
		l_cWhat1 = "film(s)"
		l_cBe = "is"
		l_cTense = "was"
		c_show = "have been forwarded to"
		DO printgroup WITH mv, "Cert_X"

	CASE l_cCert == "R"
		l_cWhat = "records"
		l_cWhat1 = ""
		l_cBe = ""
		c_show = ""
		l_cTense = "were"
		DO printgroup WITH mv, "Cert_RB"

	CASE l_cCert == "P"
		l_cWhat = "pathology materials/records"
		l_cWhat1 = "pathology/cytology"
		l_cBe = "are"
		c_show = "sent to"
		l_cTense = "was"
		DO printgroup WITH mv, "Cert_P"

	CASE l_cCert == "B"
		l_cWhat1 = "billing record(s)"
		l_cWhat = "billing"
		l_cBe = ""
		c_show = ""
		l_cTense = "were"
		DO printgroup WITH mv, "Cert_RB"

	CASE l_cCert == "E"
		l_cWhat = "echocardiogram materials/records"
		l_cWhat1 = "echocardiogram(s)"
		l_cBe = "are"
		c_show = ""
		l_cTense = "was"
		DO printgroup WITH mv, "Cert_E"

	CASE l_cCert == "F"
		l_cWhat = "photographs"
		l_cWhat1 = ""
		l_cBe = "are"
		c_show = ""
		l_cTense = "were"
		DO printgroup WITH mv, "Cert_F"

	CASE l_cCert == "C"
		l_cWhat = "cardiac catheterization materials/records"
		l_cWhat1 = "cardiac catheterization(s)"
		l_cBe = "are"
		c_show = ""
		l_cTense = "was"
		DO printgroup WITH mv, "Cert_E"

	ENDCASE

	l_nCnt = l_nCnt + 1
**3/19/07 - addded for SRQ lit cases
**c_Specmark= IIF(pc_litCode='SRQ', 'S','')

	l_GetRps= rpslitdata (pc_litcode)

*!*		IF l_getrps
*!*			c_Specmark= IIF(ISNULL(LitRps.RpsMark),'',LitRps.RpsMark)
*!*		ELSE
*!*		    c_Specmark=""
*!*		endif

	c_Specmark=ALLTRIM(UPPER(NVL(pc_litcode,"")))+"."+ALLTRIM(UPPER(NVL(pc_Initials,"")))

	DO PrintField WITH mv, "SpecMark", c_Specmark
**3/19/07 - end

	DO PrintField WITH mv, "What", ALLTRIM( l_cWhat)
	DO PrintField WITH mv, "Cap", UPPER( ALLTRIM( l_cWhat))
	DO PrintField WITH mv, "What1", ALLTRIM( l_cWhat1)
	DO PrintField WITH mv, "Be", ALLTRIM( l_cBe)
	DO PrintField WITH mv, "How", ALLTRIM( c_show)
	DO PrintField WITH mv, "Tense", ALLTRIM( l_cTense)
	DO PrintField WITH mv, "InfoText", ;
		STRTRAN( STRTRAN( szEdtReq, CHR(13), " "), CHR(10), "")

	DO printgroup WITH mv, "Case"
	DO PrintField WITH mv, "Plaintiff", ALLTRIM( pc_plcaptn)
	DO PrintField WITH mv, "Defendant", ALLTRIM( pc_dfcaptn)
	DO PrintField WITH mv, "Dist", ALLTRIM( pc_maiden1)

	DO printgroup WITH mv, "Control"
	DO PrintField WITH mv, "LrsNo", pc_lrsno
	DO PrintField WITH mv, "Tag", ALLTRIM( STR( ntag))

	DO printgroup WITH mv, "Plaintiff"
	DO PrintField WITH mv, "FirstName", pc_plnam
	DO PrintField WITH mv, "MidInitial", ""
	DO PrintField WITH mv, "LastName", ""
	IF TYPE('pd_pldob')<>"C"
		pd_pldob=DTOC(pd_pldob)
	ENDIF
	DO PrintField WITH mv, "BirthDate",  pd_pldob
	DO PrintField WITH mv, "SSN", pc_plssn


	SELECT timesheet

	DO printgroup WITH mv, "Deponent"
	IF NOT EOF()
		DO PrintField WITH mv, "Name", UPPER( ALLTRIM( timesheet.DESCRIPT))

	ELSE
		DO PrintField WITH mv, "Name",  ""
	ENDIF
ENDDO
*set procedure to (curproc)   &EF 06/17/04
WAIT CLEAR
SELECT( dbInit)
RETURN
*******************************************************************
* PROCEDURE: connasb
* DATE: 9/11/02
* BY: KDL
* ABSTRACT: Print Connecticut asbestos custom certification page when
*        the deponent type is either employer or association
********************************************************************
PROCEDURE connasb
*--document
DO printgroup WITH mv, "Ct_a_emp"

*--document variables
DO printgroup WITH mv, "Control"
DO PrintField WITH mv, "LrsNo", pc_lrsno
DO PrintField WITH mv, "Tag", ALLTRIM( STR( ntag))

DO printgroup WITH mv, "Plaintiff"
DO PrintField WITH mv, "FirstName", pc_plnam
DO PrintField WITH mv, "MidInitial", ""
DO PrintField WITH mv, "LastName", ""
DO PrintField WITH mv, "SSN", pc_plssn
RETURN
*******************************************************************
* PROCEDURE: printFlSTCert
*--- 04/01/2021 MD #227534 
PROCEDURE printFLSTCert
DO printgroup WITH mv, "FLStCert"
DO PrintField WITH mv, "Info",STRTRAN( STRTRAN( szEdtReq, CHR(13), " "), CHR(10), "")

DO printgroup WITH mv, "Case"
DO PrintField WITH mv, "Plaintiff", ALLTRIM( pc_plcaptn)
DO PrintField WITH mv, "Defendant", ALLTRIM( pc_dfcaptn)
DO PrintField WITH mv, "County", ALLTRIM(pc_c1cnty)
DO PrintField WITH mv, "Docket", ALLTRIM( pc_docket)
DO PrintField WITH mv, "Court", ALLTRIM(pc_c1Desc) 
DO PrintField WITH mv, "Name", pc_plnam
DO PrintField WITH mv, "Dist", ALLTRIM(pc_distrct)
SELECT timesheet
DO printgroup WITH mv, "Deponent"
IF NOT EOF()
	DO PrintField WITH mv, "Name", UPPER( ALLTRIM(NVL(timesheet.DESCRIPT,"")))
ELSE
	DO PrintField WITH mv, "Name",  ""
ENDIF
RETURN
