*PROCEDURE txaffid
******************************************************************************
*EF 11/28/2017:  Judicial vs. County court  #70136
*EF 11/10/2017: Added a tag level  'f' files 
*EF 09/25/2017: Added a 3rd type - Not Required	- skip printing
*EF 08/09/2017: Added pc_Suffix
*EF 05/31/2017: Texas Affidavit: 2 types: Billing and Non-Billing

******************************************************************************
Parameters n_Tag, c_mdep, c_mid, c_type
Private c_nameinv, c_nameinvp, c_ratadd1, c_ratadd1p,  c_clcode,  c_cty, SZEDTREQ, c_ratadd2, c_ratadd2p, c_ratcszP, c_ratcsz, c_date1, c_roloname, c_sign, contname, contphone, l_Xcert As Boolean
LOCAL lb_TX_Not_In_Suit
LOCAL lsDocPrefix			&& 12/5/2022, ZD #291976, JH
LOCAL lsThis_Firmcode

_Screen.MousePointer=11
l_Xcert =.F.
**09/25/2017 - Changed the   l_prntcert=.t.
*l_Xcert =findcerts(.T.)
If PN_TAG=0 Or Type ('PN_TAG') <>"N"
	PN_TAG=n_Tag
Endif

** 10/19/2017  : #71549 Old TX Reissue and Follow-ups  of Old tags do not use any programmed pages- Use scanned only
If  SkipTxDocs (PN_LRSNO,N_TAG )
	Return
Endif
** 10/19/2017  : #71549 Old TX Reissue and Follow-ups  of Old tags do not use any programmed pages- Use scanned only

*!*	**11/10/2017 - Print tag level scanned certs "F"  for tags issued after 9/22/17
If  TxSFile (n_Tag,"F")
	Do TXPages With "F",n_Tag ,  c_mid
	l_Xcert =.T.
Endif

** 09/25/2017: Added a 3rd type - Not Required
If  l_Xcert  Or    c_type="!"
	_Screen.MousePointer=0
	Return
Endif

dbInit = Alias()
ots = Createobject("medtimesheet")

Set Procedure To ta_lib Additive
c_clcode= fixquote(pc_clcode)
* removed per #70136
*c_cty=fixquote(Nvl(pc_c1Cnty,''))
SZEDTREQ=""
SZEDTREQ= GETSPECINSFORTAG(n_Tag)


*10/07/2021 WY 245050 (SUPPORT NEW TEMPLATE FIELDS DUE TO USDS-TX)
*<245050>

*!*	**09/08/2021 WY 239734 support Lapeze affidavit
*!*	*<239734>
*!*	IF UPPER(ALLTRIM(PC_AREA)) == "K-PHILA-LAPEZE"
*!*		DO CASE 
*!*			CASE c_type = "B"
*!*				Do PrintGroup With mv, "1_TXAffKB"			
*!*			OTHERWISE 		
*!*				Do PrintGroup With mv, "1_TXAffKT"					
*!*		ENDCASE 
*!*	else
*!*	*</239734>
*!*		Do Case
*!*			Case c_type="B"
*!*				Do PrintGroup With mv, "1_TXAffB"			
*!*				*255675 
*!*				if pl_plisrq && requesting att is plaintiff
*!*					Do PrintField With mv, "Plaintifftext", GetPlaintiffText()
*!*				ELSE
*!*					Do PrintField With mv, "Plaintifftext", ""			
*!*				ENDIF 

*!*			Otherwise
*!*				Do PrintGroup With mv, "1_TXAffNB"
*!*		Endcase
*!*	ENDIF && <239734>

lsZiehlDoc = ""
lb_TX_Not_In_Suit = .F.		&& 6/27/2022, ZD #273344, JH
lsDocPrefix="3"				&& 12/5/2022, ZD #291976, JH
IF UPPER(ALLTRIM(PC_AREA)) == "K-PHILA-LAPEZE"					&& 12/5/2022, ZD #291976, JH
	DO CASE 
	CASE c_type = "B"
		Do PrintGroup With mv, lsDocPrefix+"_TXAffKB"			
	OTHERWISE 		
		Do PrintGroup With mv, lsDocPrefix+"_TXAffKT"					
	ENDCASE 
ELSE
	IF NOT EMPTY(pc_rqatcod)									&& 11/14/2023, ZD #335199, JH
		lsThis_Firmcode = GetFirmCodeForAtt(pc_rqatcod)	
    ELSE
        lsThis_Firmcode = ""
	ENDIF
    if lsThis_Firmcode = "F000020713" 						 	&& 11/14/2023, ZD #335199, JH
		Do Case
		Case c_type="B"
			IF UPPER(ALLTRIM(pc_Court1)) == "TX-NOT IN SUIT"		
				lb_TX_Not_In_Suit = .T.
				Do PrintGroup With mv, lsDocPrefix+"_TXAffB_NIS"	
			ELSE
				lsZiehlDoc = "ZB"
				Do PrintGroup With mv, lsDocPrefix+"_TXAffZB"			
			ENDIF
		Case c_type="M"
			IF UPPER(ALLTRIM(pc_Court1)) == "TX-NOT IN SUIT"		
				lb_TX_Not_In_Suit = .T.
				Do PrintGroup With mv, lsDocPrefix+"_TXAffNB_NIS"	
			ELSE
				lsZiehlDoc = "ZM"
				Do PrintGroup With mv, lsDocPrefix+"_TXAffZM"			
			ENDIF
		Case c_type="X"
			IF UPPER(ALLTRIM(pc_Court1)) == "TX-NOT IN SUIT"		
				lb_TX_Not_In_Suit = .T.
				Do PrintGroup With mv, lsDocPrefix+"_TXAffNB_NIS"	
			ELSE
				lsZiehlDoc = "ZX"
				Do PrintGroup With mv, lsDocPrefix+"_TXAffZX"			
			ENDIF
		Otherwise
			IF UPPER(ALLTRIM(pc_Court1)) == "TX-NOT IN SUIT"			&& 2/9/2024, ZD #351338, JH
				lb_TX_Not_In_Suit = .T.
				Do PrintGroup With mv, lsDocPrefix+"_TXAffNB_NIS"		
			ELSE
				Do PrintGroup With mv, lsDocPrefix+"_TXAffNB"
			ENDIF														&& 2/9			
		endcase
	else													&& 11/4/2023, ZD #335199, JH
		Do Case
		Case c_type="B"
			IF UPPER(ALLTRIM(pc_Court1)) == "TX-NOT IN SUIT"			&& 6/27/2022, ZD #273344, JH
				lb_TX_Not_In_Suit = .T.
				Do PrintGroup With mv, lsDocPrefix+"_TXAffB_NIS"		&& 6/27					
			ELSE
				Do PrintGroup With mv, lsDocPrefix+"_TXAffB"			
			ENDIF
			*255675 
			if pl_plisrq && requesting att is plaintiff
				Do PrintField With mv, "Plaintifftext", GetPlaintiffText()
			ELSE
				Do PrintField With mv, "Plaintifftext", ""			
			ENDIF 

		Otherwise
			IF UPPER(ALLTRIM(pc_Court1)) == "TX-NOT IN SUIT"			&& 6/27/2022, ZD #273344, JH
				lb_TX_Not_In_Suit = .T.
				Do PrintGroup With mv, lsDocPrefix+"_TXAffNB_NIS"		&& 6/27			
			ELSE
				Do PrintGroup With mv, lsDocPrefix+"_TXAffNB"
			ENDIF
		Endcase
	endif
ENDIF															&& 12/5/2022, ZD #291976, JH
													&& 12/5/2022, ZD #291976, JH

Do PRINTFIELD With MV, "RTTAG", ALLTRIM(STR(PN_LRSNO))+"."+Alltrim(Str(N_TAG))	&& 12/5/2022, ZD #291976, JH


** 12/1/2022, repl w above, JH
***255675
**IF UPPER(ALLTRIM(PC_AREA)) == "K-PHILA-LAPEZE"
**	DO CASE 
**		CASE c_type = "B"
**			Do PrintGroup With mv, "2_TXAffKB"			
**		OTHERWISE 		
**			Do PrintGroup With mv, "2_TXAffKT"					
**	ENDCASE 
**else
**	Do Case
**		Case c_type="B"
**			IF UPPER(ALLTRIM(pc_Court1)) == "TX-NOT IN SUIT"			&& 6/27/2022, ZD #273344, JH
**				lb_TX_Not_In_Suit = .T.
**				Do PrintGroup With mv, "TXAffB_NIS"						&& 6/27					
**			ELSE
**				Do PrintGroup With mv, "2_TXAffB"			
**			ENDIF
**			*255675 
**			if pl_plisrq && requesting att is plaintiff
**				Do PrintField With mv, "Plaintifftext", GetPlaintiffText()
**			ELSE
**				Do PrintField With mv, "Plaintifftext", ""			
**			ENDIF 
**
**		Otherwise
**			IF UPPER(ALLTRIM(pc_Court1)) == "TX-NOT IN SUIT"			&& 6/27/2022, ZD #273344, JH
**				lb_TX_Not_In_Suit = .T.
**				Do PrintGroup With mv, "TXAffNB_NIS"					&& 6/27			
****			ELSE
**  			Do PrintGroup With mv, "2_TXAffNB"
**  		ENDIF
**  Endcase
**ENDIF

*!*	IF UPPER(ALLTRIM(PC_AREA)) == "K-PHILA-LAPEZE"
*!*		DO CASE 
*!*			CASE c_type = "B"
*!*				Do PrintGroup With mv, "TXAffKB"			
*!*			OTHERWISE 		
*!*				Do PrintGroup With mv, "TXAffKT"					
*!*		ENDCASE 
*!*	else
*!*	*</239734>
*!*		Do Case
*!*			Case c_type="B"
*!*				Do PrintGroup With mv, "TXAffB"
*!*			Otherwise
*!*				Do PrintGroup With mv, "TXAffNB"
*!*		Endcase
*!*	ENDIF && <239734>
*</245050>

*#255675
PRIVATE pcTxHeaderMode
pcTxHeaderMode = GetTxHeaderStyle(PN_LRSNO,N_TAG)


IF EMPTY(lsZiehlDoc)
**11/28/2017:  Judicial vs. County court #70136
	mv_cap2=""
	*mv_cap2= txcourtcap()
	
	IF NOT lb_TX_Not_In_Suit					&& 6/27/2022, ZD #273344, JH
		mv_cap2= BuildTopSectionStr()
		IF EMPTY(mv_cap2)
			Wait Window 'Error in court caption.'
			Return
		ENDIF
		mv=mv+mv_cap2
	ENDIF

	*!*	Do PrintField With mv, "County", Upper(c_cty)
	*!*	Do PrintField With mv, "CaseDist", Upper(Allt( pc_distrct))
	*!*	Do PrintField With mv, "Crttype", Alltrim(pc_txCrtType)
	*!*	Do PrintField With mv, "Suffix", pc_Suffix
	If Type('pd_pldob')<>"C"
		PD_PLDOB=Dtoc(PD_PLDOB)
	Endif
	Do PrintField With mv, "DOB", PD_PLDOB
	Do PrintField With mv, "PertainTo",	pc_plnam &&PC_PLNAMRV
	Do PrintField With mv, "InfoText", ;
		STRTRAN( Strtran( SZEDTREQ, Chr(13), " "), Chr(10), "")
	Do PrintGroup With mv, "Case"
	*255675
	*Do PrintField With mv, "Plaintiff", pc_plcaptn
	Do PrintField With mv, "Plaintiff", PrintFieldIntercept("Plaintiff", pc_plcaptn)
	*255675 
	*Do PrintField With mv, "Defendant", pc_dfcaptn
	Do PrintField With mv, "Defendant", PrintFieldIntercept("Defendant", pc_dfcaptn)

	Do PrintField With mv, "Docket", pc_docket
	Do pDepInfo  In subp_pa With c_mid, Proper( c_mdep), .F.

	IF NOT lb_TX_Not_In_Suit		&& 6/27/2022, ZD #273344, JH
		CreateTxHeader()
	ENDIF
ELSE
	Do PrintField With mv, "DOB", PD_PLDOB
	*-- 02/13/2024 MD #350397
	*DO PrintField WITH mv, "SSN", pc_plssn		
	DO PrintField WITH mv, "SSN", ALLTRIM(NVL(pc_plssn,""))+IIF(LEN(ALLTRIM(NVL(pc_plssn,"")))=0,""," ")+ALLTRIM(NVL(pc_maiden1,""))
	Do PrintField With mv, "PertainTo",	pc_plnam 
	IF lsZiehlDoc = "ZB"
		Do PrintField With mv, "InfoText", ;
			STRTRAN( Strtran( SZEDTREQ, Chr(13), " "), Chr(10), "")
	ENDIF
	SDNAME = Allt( Proper( MDEP))
	NCNT2 = At( "(", (Allt(SDNAME)), 1)
	If NCNT2 <> 0
		IREST = Len( SDNAME)
		SDPART1 = Left( Proper( Allt(SDNAME)), NCNT2)
		SDPART2 = Upper( Right( Allt(SDNAME), IREST-(NCNT2)))
		MDEP = Proper( SDPART1) + Proper( SDPART2)
	Endif
	Do PRINTFIELD With MV, "DeponentName", MDEP
ENDIF


_Screen.MousePointer=0
*10/01/2021 WY 245050 (call txaffid.prg for USDC-TX) 
*Select ( dbInit)
IF LEN(dbInit) > 0
	Select (dbInit)
ENDIF 

Release ots
Wait Clear

Return




*resolve print headings for TX and USDC-TX affidavits
*10/07/2021  245050 WY (Create Affidavit print headings for TX or USDC-TX)
FUNCTION BuildTopSectionStr () as String 
	LOCAL lnLen, lcTemp, lcPrgResult
	lcTemp = ""
	lcPrgResult = ""

	DO CASE 
		*handle TX-
		CASE UPPER(LEFT(pc_Court1,3)) == "TX-"
			*Heading1
		 	Do PrintField With lcPrgResult, "Heading1", "CAUSE NO. " + ALLTRIM(pc_docket)			
			*CaseArea
		 	Do PrintField With lcPrgResult, "CaseArea", "" 			
			*Division
		 	Do PrintField With lcPrgResult, "Division", ""		
			*CrtType2
			Do PRINTFIELD With lcPrgResult,"CrtType2", "IN THE " + Alltrim(PC_TXCRTTYPE) + "COURT"				

			*CaseDist2 (follow known rules from txcourtcap.prg)
			IF ALLTRIM(PC_DISTRCT) = "."			&& 1/11/2023, ZD #300721, JH
				lcTemp = ""							&& 1/11
			ELSE
				Do Case
					Case ALLTRIM(PC_TXCRTTYPE)= "COUNTY"
						lcTemp = "AT LAW NO. " + Upper(Allt(PC_DISTRCT)) + PC_SUFFIX
					Case ALLTRIM(PC_TXCRTTYPE)="DISTRICT"
						lcTemp = Upper(Allt( PC_DISTRCT)) +   PC_SUFFIX + " JUDICIAL"  +" DISTRICT"
					Case ALLTRIM(PC_TXCRTTYPE)="PROBATE"		&& 8/9/2022, ZD #282566, JH
						lcTemp = ""
					Otherwise
						lcTemp = "Not Programmed"
				ENDCASE	
			ENDIF
			Do PRINTFIELD With lcPrgResult,"CaseDist2",lcTemp

			*USDCDocket
			Do PrintField With lcPrgResult, "USDCDocket", ""
			*county2
			Do PRINTFIELD With lcPrgResult, "County2", ALLTRIM(Upper(fixquote(NVL(pc_c1Cnty,'')))) + " COUNTY, TEXAS"

		*handle USDC-TX		
		CASE UPPER(LEFT(pc_Court1,7)) == "USDC-TX"
			*Heading1
		 	Do PrintField With lcPrgResult, "Heading1", "IN THE UNITED STATES DISTRICT COURT"	
			*CaseArea
			lnLen = Len(Alltrim(pc_c1Desc))
			lcTemp = Right(Alltrim(pc_c1Desc), lnLen - LEN("USDC-TX"))			
		 	Do PrintField With lcPrgResult, "CaseArea", "FOR THE " + UPPER(lcTemp)			
			*Division	
			*-- 02/28/2022 MD#265806 Skip division for USDC-TX court	
		 	*--Do PrintField With lcPrgResult, "Division", UPPER(ALLTRIM(pc_divisn)) + " DIVISION"	
		 	*-- 03/01/2022 MD #265806 Print it if the values is there
		 	Do PrintField With lcPrgResult, "Division",IIF(LEN(ALLTRIM(NVL(pc_divisn,"")))=0,"", UPPER(ALLTRIM(pc_divisn)) + " DIVISION")
			*CrtType2
		 	Do PrintField With lcPrgResult, "CrtType2", ""
			*CaseDist2
		 	Do PrintField With lcPrgResult, "CaseDist2", ""
			*USDCDocket
	 		lcTemp = "CIVIL ACTION NO. " + UPPER(ALLTRIM(pc_docket)) 
		 	Do PrintField With lcPrgResult, "USDCDocket", lcTemp		
			*county2
		 	Do PrintField With lcPrgResult, "County2", ""
		OTHERWISE 
			*not ready to handle
			lcPrgResult = ""
	ENDCASE

	RETURN lcPrgResult
ENDFUNC 


*255675 12/19/2021 WY
FUNCTION GetPlaintiffText () as String
	RETURN "The service provided was necessary and the amount charged " + ;
	"for the service was reasonable and necessary at the time and " + ;
	"place that the service was provided." + Chr(10)
ENDFUNC

*255675 12/19/2021 WY handle 3 fields in the header 
PROCEDURE CreateTxHeader() 
	Do PrintField With mv, "UnderCasePlaintiff", PrintFieldIntercept("UnderCasePlaintiff")   		
	IF pcTxHeaderMode = 3
		Do PrintField With mv, "Ver", PrintFieldIntercept("Ver", pc_plcaptn)   		
	ELSE
		Do PrintField With mv, "Ver", PrintFieldIntercept("Ver")   		
	ENDIF 
	Do PrintField With mv, "UnderCaseDef", PrintFieldIntercept("UnderCaseDef")  

ENDPROC 