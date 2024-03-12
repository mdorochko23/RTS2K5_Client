*PROCEDURE txquest
********************************************************************************************************
*EF 11/28/2017:  Judicial vs. County court  #70136
*EF 08/14//2017 added 1 (L) more  dwqs
*EF 08/11//2017 added 5 more  dwqs
*EF 08/09/2017: Added pc_Suffix
*EF 06/21/2017: Texas DirectQuestins

* c_type: FIRST 6 types of a questions: "MA"- medical  Admissible ,  "BA"- biling Admissible, "GA"-generic Admissible
*							"MN"- medical  Non-Admissible ,  "BN"- biling Non-Admissible, "GN"-Non-Admissible

********************************************************************************************************
Parameters n_Tag, c_mdep, c_mid, c_type, l_reduct

Private c_nameinv, c_nameinvp, c_ratadd1, c_ratadd1p,  c_clcode,  c_cty, ;
	c_ratadd2, c_ratadd2p, c_ratcszP, c_ratcsz, c_date1, c_roloname, c_sign, contname, contphone
LOCAL lcTXAmended
LOCAL lsDocPrefix		&& 12/5/2022, ZD #291976, JH
dbInit = Alias()

** 09/25/2017: Added a new type (!) - Not Required
&& check for a scanned page "Q" type
C_RIDERPCX=""
C_RIDERPCX=SUBRIDERPCX	(n_Tag,"Q",1 )
If !Empty(Alltrim(C_RIDERPCX))    Or  c_type='!'   
	ntag= n_Tag
	Do pspecdoc In subp_pa With 'Q'
Else

** 10/19/2017  : #71549 Old TX Reissue and Follow-ups  of Old tags do not use any programmed pages- Use scanned only
	If  SkipTxDocs (PN_LRSNO,N_TAG )
		Return
	Endif
** 10/19/2017  : #71549 Old TX Reissue and Follow-ups  of Old tags do not use any programmed pages- Use scanned only

	ots = Createobject("medtimesheet")
	_Screen.MousePointer=11
	Set Procedure To ta_lib Additive
	c_clcode= fixquote(pc_clcode)

	If Not Used('Request')
		ots.sqlexecute(" exec dbo.GetRequestRecordbyClcodeTag '" + c_clcode + "','" + Str(n_Tag) + "' ", "Request")
	Endif
	Select Request
	*06/13/2018 MD #71930------------------------------------------------        
	IF USED('viewTXAM')
	   USE IN viewTXAM
	ENDIF 
	lcSQLLine=" exec [dbo].[qc_CheckTXAM]   '" +fixquote(c_clcode) + "'," + convertToChar(n_Tag,1)
    ots.sqlexecute(lcSQLLine,'viewTXAM')
    lcTXAmended=""
    IF ALLTRIM(UPPER(NVL(viewTXAM.addInfo,"")))=="TXAM" AND ALLTRIM(UPPER(NVL(request.type,"A")))=="S" AND LEFT(ALLTRIM(UPPER(NVL(pc_Court1,""))),2)="TX"       
      lcTXAmended="AMENDED"
    ENDIF 
    IF USED('viewTXAM')
	   USE IN viewTXAM
	ENDIF 
    *---------------------------------------------------------------------   
*c_cty=fixquote(NVL(pc_c1Cnty,'')) &&Judicial vs. County court  #70136

	SZEDTREQ= GETSPECINSFORTAG(n_Tag)

**09/21/2017: remove reductions  #69867
*!*		IF l_reduct
*!*			SZEDTREQ=numtoxx(SZEDTREQ)
*!*		endif
	*-- 03/30/2021 md @232193 added Exact equal and alltrim(upper( to c_Type

	*10/07/2021 WY 245050 (SUPPORT NEW TEMPLATE FIELDS DUE TO USDS-TX)
	*<245050>

*!*		Do Case
*!*			Case ALLTRIM(UPPER(c_type))=="F"  &&  F: dqnong.doc
*!*				Do PrintGroup With mv, "1_TXDQGN"
*!*			Case ALLTRIM(UPPER(c_type))=="B" && dqbill.doc
*!*				Do PrintGroup With mv, "1_TXDQBA"
*!*			Case  ALLTRIM(UPPER(c_type))=="A" &&dqma.doc
*!*				Do PrintGroup With mv, "1_TXDQMA"
*!*			Case  ALLTRIM(UPPER(c_type))=="C" &&dqag.doc
*!*				Do PrintGroup With mv, "1_TXDQGA"
*!*			Case  ALLTRIM(UPPER(c_type))=="D" && dqnonm.doc
*!*				Do PrintGroup With mv, "1_TXDQMN"
*!*			Case  ALLTRIM(UPPER(c_type))=="E" && dqnonb.doc
*!*				Do PrintGroup With mv, "1_TXDQBN"
*!*			Otherwise
*!*				Do PrintGroup With mv, "1_TXDQ" + ALLTRIM(Upper(c_type))
*!*		ENDCASE
	
*!*	*255675 12/24/2021 support a new set of templates		&& rem 12/5/2022, ZD #291976, jh
*!*	Do Case
*!*		Case ALLTRIM(UPPER(c_type))=="F"  &&  F: dqnong.doc
*!*			Do PrintGroup With mv, "2_TXDQGN"
*!*		Case ALLTRIM(UPPER(c_type))=="B" && dqbill.doc
*!*			Do PrintGroup With mv, "2_TXDQBA"
*!*		Case  ALLTRIM(UPPER(c_type))=="A" &&dqma.doc
*!*			Do PrintGroup With mv, "2_TXDQMA"
*!*		Case  ALLTRIM(UPPER(c_type))=="C" &&dqag.doc
*!*			Do PrintGroup With mv, "2_TXDQGA"
*!*		Case  ALLTRIM(UPPER(c_type))=="D" && dqnonm.doc
*!*			Do PrintGroup With mv, "2_TXDQMN"
*!*		Case  ALLTRIM(UPPER(c_type))=="E" && dqnonb.doc
*!*			Do PrintGroup With mv, "2_TXDQBN"
*!*		Otherwise
*!*			Do PrintGroup With mv, "2_TXDQ" + ALLTRIM(Upper(c_type))
*!*	Endcase

	lsDocPrefix="3"											&& 12/5/2022, ZD #291976, JH
   	Do Case
   		Case ALLTRIM(UPPER(c_type))=="F"  &&  F: dqnong.doc
   			Do PrintGroup With mv, lsDocPrefix+"_TXDQGN"
   		Case ALLTRIM(UPPER(c_type))=="B" && dqbill.doc
   			Do PrintGroup With mv, lsDocPrefix+"_TXDQBA"
   		Case  ALLTRIM(UPPER(c_type))=="A" &&dqma.doc
   			Do PrintGroup With mv, lsDocPrefix+"_TXDQMA"
   		Case  ALLTRIM(UPPER(c_type))=="C" &&dqag.doc
   			Do PrintGroup With mv, lsDocPrefix+"_TXDQGA"
   		Case  ALLTRIM(UPPER(c_type))=="D" && dqnonm.doc
   			Do PrintGroup With mv, lsDocPrefix+"_TXDQMN"
   		Case  ALLTRIM(UPPER(c_type))=="E" && dqnonb.doc
   			Do PrintGroup With mv, lsDocPrefix+"_TXDQBN"
   		Otherwise
   			Do PrintGroup With mv, lsDocPrefix+"_TXDQ" + ALLTRIM(Upper(c_type))
   	Endcase													&& 12/5/2022
	
	
	*!*	Do Case
	*!*		Case ALLTRIM(UPPER(c_type))=="F"  &&  F: dqnong.doc
	*!*			Do PrintGroup With mv, "TXDQGN"
	*!*		Case ALLTRIM(UPPER(c_type))=="B" && dqbill.doc
	*!*			Do PrintGroup With mv, "TXDQBA"
	*!*		Case  ALLTRIM(UPPER(c_type))=="A" &&dqma.doc
	*!*			Do PrintGroup With mv, "TXDQMA"
	*!*		Case  ALLTRIM(UPPER(c_type))=="C" &&dqag.doc
	*!*			Do PrintGroup With mv, "TXDQGA"  
	*!*		Case  ALLTRIM(UPPER(c_type))=="D" && dqnonm.doc
	*!*			Do PrintGroup With mv, "TXDQMN"	
	*!*		Case  ALLTRIM(UPPER(c_type))=="E" && dqnonb.doc
	*!*			Do PrintGroup With mv, "TXDQBN"
	*!*		Otherwise
	*!*			Do PrintGroup With mv, "TXDQ" + ALLTRIM(Upper(c_type))
	*!*	Endcase
	*</245050>

	*-- 03/30/2021 md @232193 
*11/28/2017:  Judicial vs. County court  #70136
*10/07/2021 WY 245050 (REMOVE STANDARD HEADER FIELDS) 
* <245050>
*!*		mv_cap2=""
*!*		mv_cap2= txcourtcap()
*!*		If Empty(mv_cap2)
*!*			Wait Window 'Error in court caption.'
*!*			Return
*!*		Endif
*!*		mv=mv+mv_cap2
*</245050>
	
	
*!*		DO PrintField WITH mv, "County", UPPER(c_cty)
*!*		DO PrintField WITH mv, "CaseDist", UPPER(ALLT( pc_distrct))
*!*		DO PrintField WITH mv, "Crttype", ALLTRIM(pc_txCrtType)
*!*		DO PrintField WITH mv, "Suffix", pc_Suffix
*11/28/2017:  Judicial vs. County court  #70136

	*</238984>

	*255675 12/21/2021 Support TX Header user selection
	PRIVATE pcTxHeaderMode
	pcTxHeaderMode = GetTxHeaderStyle(PN_LRSNO,N_TAG)


	*10/07/2021 WY 245050 (APPLY HEADER FIELDS) 
 	* <245050>
 	LOCAL lcResult, lnLen
	DO case
		CASE UPPER(LEFT(pc_Court1,3)) == "TX-"
			Do PrintField With mv, "Title1", "CAUSE NO. " + pc_docket
			Do PrintField With mv, "ForThe", ""
			Do PrintField With mv, "CaseArea", ""			
			lcResult = "IN THE " + ALLTRIM(pc_txCrtType) + " COURT"
	 		Do PrintField With mv, "CrtType2", lcResult

			IF ALLTRIM(PC_DISTRCT) = "."			&& 2/13/2023, ZD #304476, JH
				lcResult = ""						&& 2/13
			ELSE
				Do Case
					Case ALLTRIM(PC_TXCRTTYPE)= "COUNTY"
						lcResult="AT LAW NO. " +   Upper(Allt( PC_DISTRCT)) + PC_SUFFIX
					Case ALLTRIM(PC_TXCRTTYPE)="DISTRICT"
						lcResult= Upper(Allt( PC_DISTRCT)) + PC_SUFFIX +" JUDICIAL"  +" DISTRICT"
					Otherwise
						lcResult= "" && "Not Programmed" Alex said otherwise blank
				ENDCASE
			ENDIF
			*CaseDist2
	 		Do PrintField With mv, "CaseDist2", lcResult

			*USDCDocket
			Do PrintField With mv, "USDCDocket", ""
			*County2
			lcResult = ALLTRIM(fixquote(NVL(pc_c1Cnty,''))) + " COUNTY, TEXAS"
	 		Do PrintField With mv, "County2", lcResult
		CASE UPPER(LEFT(pc_Court1,7)) == "USDC-TX" && perhaps this should just be USDC
			*Title1
			Do PrintField With mv, "Title1", "IN THE UNITED STATES DISTRICT COURT"
			*ForThe (same rule as subprint.prg  Do PrintField With mv, "Area", c_court)
			lcResult=""
			lnLen=0
			lnLen= Len(Alltrim(pc_c1Desc))
			lcResult = Right(Alltrim(pc_c1Desc), lnLen - LEN("USDC-TX"))			
 			Do PrintField With mv, "ForThe", "FOR THE " + ALLTRIM(UPPER(lcResult)) 
			*CaseArea
			*-- 02/28/2022 MD#265806 Skip division for USDC-TX court
 			*--Do PrintField With mv, "CaseArea", UPPER(ALLTRIM(pc_divisn)) + " DIVISION"	
 			*-- 03/01/2022 MD #265806 Print it if the values is there
 			Do PrintField With mv, "CaseArea",IIF(LEN(ALLTRIM(NVL(pc_divisn,"")))=0,"", UPPER(ALLTRIM(pc_divisn)) + " DIVISION")	
	 		Do PrintField With mv, "CrtType2", "" 			
			*CaseDist2
 			Do PrintField With mv, "CaseDist2", ""
 			*USDCDocket
 			lcResult = "CIVIL ACTION NO. " + UPPER(ALLTRIM(pc_docket))
 			Do PrintField With mv, "USDCDocket", lcResult
			*County2
	 		Do PrintField With mv, "County2", ""
	ENDCASE
 	*</245050>
	  

	*<08/12/2021 WY 238984> handle ssn and dob caption generation here instead of within the word doc
	*make caption generation conditional base on existence of field, 
	*sometimes the witness is a company instead of a person		
	*redact (l_reduct) comes into play only when the field is not blank
	*<238984>
	*!*	 	Do PrintField With mv, "SSN", Iif(l_reduct, '',pc_plssn )
	*!*		If Type('pd_pldob')<>"C"
	*!*			PD_PLDOB=Dtoc(PD_PLDOB)
	*!*		ENDIF
	*!*		Do PrintField With mv, "DOB", Iif(l_reduct, '',PD_PLDOB)
			
	LOCAL lcDobWithLabel, lcSsnWithLabel 
	*ssn
	*11/15/2021 WY #256321
	*since Master.soc_sec have masks without data, work with pc_fullssn instead of pc_plssn
	*IF LEN(ALLTRIM(pc_plssn)) = 0 
	IF LEN(ALLTRIM(pc_fullssn)) = 0 OR StringHaveNumber (pc_fullssn) = .f. 
		lcSsnWithLabel =  ""
	ELSE
		IF l_reduct 
			lcSsnWithLabel = "SSN#: " 
		ELSE
			*lcSsnWithLabel = "SSN#: " + CleanAndMaskSsn(pc_fullssn) && pc_plssn
					
			*10/29/2021 WY 254896
			IF StringHaveNumber (pc_fullssn)				
				*lcSsnWithLabel = "SSN#: " + CleanAndMaskSsn(pc_fullssn)  &&-- 01/24/2023 MD #302061
				lcSsnWithLabel = "SSN#: " + ALLTRIM(pc_fullssn)
			ELSE
				lcSsnWithLabel = ""
			ENDIF 
		ENDIF 
	ENDIF  
	*-- 02/13/2024 MD #350397
	IF LEN(ALLTRIM(NVL(pc_maiden1,""))) > 0 		
		IF l_reduct 
			lcSsnWithLabel = ALLTRIM(lcSsnWithLabel)+IIF(LEN(ALLTRIM(lcSsnWithLabel))=0,""," ")+"AKA: "
		ELSE
			lcSsnWithLabel = ALLTRIM(lcSsnWithLabel)+IIF(LEN(ALLTRIM(lcSsnWithLabel))=0,""," ")+"AKA: "+ ALLTRIM(pc_maiden1)
		ENDIF 
	ENDIF  
	*-- 02/13/2024 
	*dob
	IF LEN(ALLTRIM(PD_PLDOB)) = 0 OR ALLTRIM(PD_PLDOB) == "/  /" 	
		lcDobWithLabel = ""
	ELSE
		IF l_reduct 
			lcDobWithLabel = "DOB: " 
		ELSE
			lcDobWithLabel = "DOB: " + PD_PLDOB
		ENDIF 
	ENDIF 
 	Do PrintField With mv, "SSN", lcSsnWithLabel
	Do PrintField With mv, "DOB", lcDobWithLabel
	*</238984>
	

	Do PrintField With mv, "PertainTo",	pc_plnam&&PC_PLNAMRV
	Do PrintField With mv, "InfoText", ;
		STRTRAN( Strtran( SZEDTREQ, Chr(13), " "), Chr(10), "")
	Do PrintGroup With mv, "Case"

	*255675 WY 12/21/2021 Support TX Header user selection
	*Do PrintField With mv, "Plaintiff", pc_plcaptn
	DO  PrintField With mv, "Plaintiff", PrintFieldIntercept("Plaintiff", pc_plcaptn) 
	
	*Do PrintField With mv, "Defendant", pc_dfcaptn
	Do PrintField With mv, "Defendant", PrintFieldIntercept("Defendant", pc_dfcaptn)

	Do PrintField With mv, "Docket", pc_docket
	*06/13/2018 MD #71930
    Do PrintField With mv, "Amended",lcTXAmended
	Do pDepInfo  In subp_pa With c_mid, Proper( c_mdep), .F.
 
	*04/16/2021 MD #71930------------------------------------------------  
	*--IF ALLTRIM(UPPER(NVL(c_type,'')))=='R'	&& 08/06/2021 MD #247162	      
		ots.closealias("viewAccdDate")
		lcSQLLine=" exec [dbo].[qc_AccdDate]   '" +ALLTRIM(fixquote(c_clcode)) + "', '" + ALLTRIM(fixquote(pc_rqatcod))+"'"
	    ots.sqlexecute(lcSQLLine,'viewAccdDate')
	    LOCAL ldAccidentDate
	    IF NVL(viewAccdDate.accidentDate,"01/01/1900")="01/01/1900"
	    	ldAccidentDate=""
	    else
		    ldAccidentDate=DTOC(convertToDate(viewAccdDate.accidentDate))
		ENDIF 
	    Do PrintField With mv, "AccidentDate", ldAccidentDate
	    ots.closealias("viewAccdDate")
	*--ENDIF  && #247162
	*04/16/2021 MD #71930------------------------------------------------   
	
	Release ots


	*#255675  WY 12/21/2021 Support TX Header user selection
	CreateTxHeader()

	Do PRINTFIELD With MV, "RTTAG", PC_LRSNO + "." + Alltrim(Str(N_TAG))			&& 12/5/2022, ZD #291976, JH


Endif
_Screen.MousePointer=0
Select ( dbInit)

Wait Clear

Return
****************************************************************************************************************


*MIMIC SP FormatSSN
FUNCTION CleanAndMaskSsn (tcDirtySsn as String) as String
	LOCAL lcResult

	tcDirtySsn = ALLTRIM(tcDirtySsn)
	lcResult = ""	
	lcResult = STRTRAN(tcDirtySsn, "-", "")
	lcResult = STRTRAN(lcResult, ",", "")
	lcResult = STRTRAN(lcResult, " ", "")
	IF LEN(lcResult) < 9
		lcResult = replicate('0', 9 - LEN(lcResult)) + lcResult && replicate('0', 0) will run fine
	ENDIF 
	RETURN "###-##-" + right(lcResult ,4)
ENDFUNC

*return .t. if a string has a number, determine whether or not to display a SSN
*10/29/2021 WY 254896
FUNCTION StringHaveNumber (tcValue as string) as Boolean
	tcValue = ALLTRIM(tcValue)
	LOCAL i
	IF LEN(tcValue) > 0
		FOR i = 1 TO LEN(tcValue)
			IF ISDIGIT(SUBSTR(tcValue,i,1))
				RETURN .t.
			ENDIF 		
		ENDFOR
		RETURN .f.
	ELSE
		RETURN .f.
	ENDIF 
ENDFUNC 

*255675 WY 12/21/2021 Support TX Header user selection
PROCEDURE CreateTxHeader() 
	Do PrintField With mv, "UnderCasePlaintiff", PrintFieldIntercept("UnderCasePlaintiff")   		
	IF pcTxHeaderMode = 3
		Do PrintField With mv, "Ver", PrintFieldIntercept("Ver", pc_plcaptn)   		
	ELSE
		Do PrintField With mv, "Ver", PrintFieldIntercept("Ver")   		
	ENDIF 
	Do PrintField With mv, "UnderCaseDef", PrintFieldIntercept("UnderCaseDef")   	
ENDPROC 