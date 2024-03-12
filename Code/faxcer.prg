**PROCEDURE FaxCer

PARAMETERS ntag, bReq, ntxn_id, l_cType, lc_Request
PRIVATE dbInit, dbSpec_Ins, l_cCertType, nrec, l_nCnt, l_cCert, ncnt, l_cCert2, ;
	l_cType, ntxn_id, l_cDblLtr, l_cDblLtr2, c_cltag, l_cert, c_Specmark
dbInit = SELECT()

WAIT WINDOW "Faxing certification page(s)." NOWAIT NOCLEAR



STORE "" TO l_cCert, l_cCert2, l_cCertType, c_Specmark
STORE 0 TO nrec, ncnt
SELECT 0

l_cCertType = UPPER(l_cType)
szEdtReq = gfAddCR( lc_Request)



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
	SELECT spec_ins
	REPLACE cert_type WITH pc_CertTyp
	LOCAL oGen AS medGeneric OF generic
	oGen=CREATEOBJECT("medGeneric")
	C_STR=""
	
	C_STR=" exec dbo.UpdCertsSpecInstruction   '" +   STR(ntxn_id) + "','" +pc_CertTyp + "'"  
	
	l_Retval= oGen.sqlexecute(C_STR,"")
	RELEASE oGen



ENDIF

**EF 3/25/05 - always print 'Med records' cert first
ncntr = RAT( "R", l_cCertType)
IF ncntr <> 0
	l_Cert = STRTRAN( l_cCertType, "R", "", 1, 2)
	l_cCertType ="R" + l_Cert
ENDIF
**EF -end

nRec = LEN( l_cCertType)
l_nCnt = 1
DO WHILE .T.
	IF l_nCnt > nRec
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
		DO case
		
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



	c_Specmark=ALLTRIM(UPPER(NVL(pc_litcode,"")))+"."+ALLTRIM(UPPER(NVL(pc_Initials,"")))

	DO PrintField WITH mv, "SpecMark", c_Specmark
**3/19/07 - end

	DO printfield WITH mv, "What", ALLTRIM( l_cWhat)
	DO printfield WITH mv, "Cap", UPPER( ALLTRIM( l_cWhat))
	DO printfield WITH mv, "What1", ALLTRIM( l_cWhat1)
	DO printfield WITH mv, "Be", ALLTRIM( l_cBe)
	DO printfield WITH mv, "How", ALLTRIM( c_show)
	DO printfield WITH mv, "Tense", ALLTRIM( l_cTense)
	DO printfield WITH mv, "InfoText", ;
		STRTRAN( STRTRAN( szEdtReq, CHR(13), " "), CHR(10), "")

	DO printgroup WITH mv, "Case"
	DO printfield WITH mv, "Plaintiff", ALLTRIM( pc_plcaptn)
	DO printfield WITH mv, "Defendant", ALLTRIM( pc_dfcaptn)
	DO printfield WITH mv, "Dist", ALLTRIM( pc_maiden1)

	DO printgroup WITH mv, "Control"
	DO printfield WITH mv, "LrsNo", pc_lrsno
	DO printfield WITH mv, "Tag", ALLTRIM( STR( ntag))

	DO printgroup WITH mv, "Plaintiff"
	DO printfield WITH mv, "FirstName", pc_plnam
	DO printfield WITH mv, "MidInitial", ""
	DO printfield WITH mv, "LastName", ""
	IF TYPE('pd_pldob')<>"C"
		pd_pldob=DTOC(pd_pldob)
	ENDIF
	DO printfield WITH mv, "BirthDate",  pd_pldob
	DO printfield WITH mv, "SSN", pc_plssn


	SELECT timesheet

	DO printgroup WITH mv, "Deponent"
	IF NOT EOF()
		DO printfield WITH mv, "Name", UPPER( ALLTRIM( timesheet.DESCRIPT))

	ELSE
		DO printfield WITH mv, "Name",  ""
	ENDIF
ENDDO

WAIT CLEAR
SELECT( dbInit)
RETURN
