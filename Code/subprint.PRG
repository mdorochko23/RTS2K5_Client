******************************************************************************************************************
***PROCEDURE subprint
***EF: 11/28/2017: Judicial vs. County court # 70136
***EF : 3/25/14-rider can be a stored 'Return" image now 	- Il-WCC, NJ and all KOP subps
***EF : March, 2012 -added as a part of the work on the sharing etween KOP and CA offices a new USDC subp forms.
******************************************************************************************************************
*10/12/2021 WY 251233 added tlCalledFromFiling parameter
Parameters ntagSUB, ccrtSUB,ccrtSUB2, cAtName, cnameinv,  creqType, ccounty, mdep, mid, tlCalledFromFiling
*-- 01/19/2023 MD  
IF PCOUNT()<10
  tlCalledFromFiling=.F.
ENDIF 

Local lcselect As String, llRunTxSubDocWithBlindError as Boolean
llRunTxSubDocWithBlindError = .f.
lcselect =Alias()

*-- 11/23/2021 MD 
PUBLIC scannedSubPrinted
scannedSubPrinted=.F.
*-- 11/23/2021 MD 

lcCommandedTo=""
docID=2
Local oMEDSUB As Object
oMEDSUB = Createobject("medtimesheet")
Store "" To lcPDist, lcPDiv
mdefendant = Allt(pc_dfcaptn)
szPltName = pc_plcaptn
Local c_term As String
c_term=""
&&08/29/13 - use month year per Liz
c_term=termdate(pd_term)
mTerm=c_term
mRDocket = pc_docket
llProvider = Iif( creqType = "S", pl_c1Prvdr, .F.)

If (pl_c1Form Or pl_NJSub)  And !PL_TXCOURT &&6/27/2011 NJ SUBPOENA
	Select court
	c_order=Order()
	If Empty(Alltrim(c_order))
		=CursorSetProp("KeyFieldList", "COURT", "COURT")
		Index On court Tag court Additive
	Endif
	Set Order To court
	Seek pc_Court1
	bBalt = (pc_c1Name = "MD-BaltimoCity")
**4/7/15 -mew MD Balt subp

	If bBalt
		Do mdsubp With ntagSUB, ccrtSUB,ccrtSUB2, cAtName, cnameinv,  creqType, ccounty, mdep, mid, Iif(PL_1ST_REQ Or PL_2NDQUE , 0,3)
		Release oMEDSUB
		If Not Empty(lcselect)
			Select (lcselect)
		Endif
		Return
	Endif
**4/7/15 -new MD Balt subp
	If creqType <> "A" And (pl_ofcMD Or pl_MdAsb)
		Local l_NoMdProof As Boolean
		l_NoMdCert=oMEDSUB.sqlexecute("SELECT dbo.fn_NoMdCert('" + fixquote(pc_rqatcod) + "')", "NoMdCert")
		l_NoMdProof=Iif(l_NoMdCert,NoMdCert.Exp, .F.)

		If Not l_NoMdProof
			Do MDProof In subp_pa With ntagSUB, pc_platcod
		Endif
	Endif
	If ( Left( Alltrim(UPPER(pc_Court1)), 4) = "USDC"  )
	    * --- 08/10/2018 MD #98879 added USDC subpoena for Abilify
	    IF ALLTRIM(UPPER(pc_litcode))=="ABL" AND ALLTRIM(UPPER(pc_area))=="MDL" AND creqType = "S"
	       Do usdc_ABL With ccrtSUB,ccrtSUB2, creqType, ccounty, mdep
	       If Not Empty(lcselect)
				Select (lcselect)
			Endif
	       RETURN
	    ELSE	
	        *-- 11/08/2021 MD commented out here. The print goes into else statement
			* Do PrintGroup With mv, "SubpoenaUSDC" &&all usdc like sub print the same form as 03/08/12

			*10/26/2021 WY #253848 (support a distinct subpoena front-page for USDC-TX when DWQ is selected)
			LOCAL lcDwqResult
			lcDwqResult = GetTxDWQ(PC_CLCODE, ntagSUB)
			IF Left(Alltrim(UPPER(pc_Court1)), 7) = "USDC-TX" and LEN(ALLTRIM(lcDwqResult)) > 0
				Do PrintGroup With mv, "SubUSDCTXDQW"
			else
				Do PrintGroup With mv, "SubpoenaUSDC" &&all usdc like sub print the same form as 03/08/12
			ENDIF 

		ENDIF 
	Else
**11/02/2016: added 2nd form for LehighCo #52199
**09/19/2016 :  added 2nd form for the PA-bucks #48982
**Check if old or new form by an issue date:  start
		Local l_old As Boolean
		l_old=.T. && assume we use an old one
*IF UPPER(ALLT( ccrtSUB)) ="PA-BUCKSCOUNTY"
		l_old=SubForm2( pn_lrsno , ntagSUB , ccrtSUB)
*ENDIF
		** --- 08/03/2020 MD #173172 -----------------------------------
		DO CASE 
		CASE  (pl_ILCook=.T. or plCourtIN=.T.) AND TxSFile (ntagSUB, "S")=.T.	
		 ** use scanned subpoena if its exists for IL or IN 	
			NTAG=ntagSUB
			Do pspecdoc In subp_pa With "S"					
			scannedSubPrinted=.T.	&&-- 11/23/2021 MD 	
			Return
		 CASE pl_ILCook=.T.
			Do PrintGroup With mv,"SubpoenaIL-All"
		CASE plCourtIN=.T.
			** --- 08/05/2020 MD #170629 ----------------------------------- 
			Do PrintGroup With mv,"SubpoenaIN-All2"
		OTHERWISE 
			**Check if old or new form by an issue date:  end		
			Do PrintGroup With mv, "Subpoena" + ;
			IIF( pl_MichCrt, "MI-Courts2",  Iif(l_old,Allt( ccrtSUB), Allt( ccrtSUB) + '2'))		&& 6/14/2022, ZD #273584, JH
*			IIF( pl_MichCrt, "MI-Courts",   Iif(l_old,Allt( ccrtSUB), Allt( ccrtSUB) + '2'))
		ENDCASE 
	Endif

Else
	** --- 08/03/2020 MD #173172 -----------------------------------
	DO CASE 
		 CASE  (pl_ILCook=.T. or plCourtIN=.T.) AND TxSFile (ntagSUB, "S")=.T.	
		 ** use scanned subpoena if its exists for IL or IN 	
			NTAG=ntagSUB
			Do pspecdoc In subp_pa With "S"						
			Return
		 CASE pl_ILCook=.T.
			Do PrintGroup With mv,"SubpoenaIL-All"
		CASE plCourtIN=.T.
			** --- 08/05/2020 MD #170629 ----------------------------------- 
			Do PrintGroup With mv,"SubpoenaIN-All2"
		OTHERWISE 
		&&8/26/2015- added WEBFORM to PCCP
		&&03/11/13 ADDED KOP GENERIC FORMS ( ONE FOR THE NOTICE SET AND ONE FOR COURT SET) :"HoldPrint" Project.
		If pc_RpsForm="KOPGeneric" Or pl_webform
			Local c_scanpcx As String, c_riderpcx As String
			Store "" To c_scanpcx, c_riderpcx
			&&05/23/13- print a scanned subpena page with a court set and rps forms with notices and court sets for signing a subp
			If (pl_noticng   And  Type('pd_dateCourtset')<>"D" )  &&OR 	 pl_Reissue	 &&- , Reissue  Also (12/18/13)

				If pl_webform
					Do PrintGroup With mv, "Subpoena" + Allt( ccrtSUB)
				Else
					Do PrintGroup With mv, Iif(Not pl_HSubpCourt , "PAGen_Notice", "PAGen_Court")
				Endif

			Else

			**10/17/13 - USE THE SAME LOGIC WHEN REPRINTING A HOLDSUBPS

				If PL_1ST_REQ  Or pl_UpdHoldReqst  && USE A FAKE PATH FOR FUTURE REQUEST

					Do PrintGroup With mv, "ScannedSub"
					c_scanpcx=FakeSubPcx(ntagSUB)
					Do PrintField With mv, "Id", c_scanpcx
					Do PrintField With mv, "RT", "RT: " + pc_lrsno 	+ "." + Allt(Str(ntagSUB))
					Release oMEDSUB
					If Not Empty(lcselect)
						Select (lcselect)
					Endif
				Else
					&&	07/17/2013  ALL SEC REQUESTS  OR COURTS SETS USE A SCANNED SUBPOENAS
					ntag= ntagSUB
					Do pspecdoc In subp_pa With 'G'

				Endif
				Return
			Endif


		******************************03/11/13 ADDED KOP GENERIC FORMS*****************************

		Else
	**05/30/2017 :TX docs 2017
	**10/25/16: do not print SubpoenaOther page here and in subp_pa #51529

			If PL_TXCOURT
	*!*	**09/25/2017: skip is "S" scanned subp file exists ( two types covered by that: Notice and Subp Page)
				If  Nvl(creqType,'A') ="S"
					If  TxSFile (ntagSUB, "S")
						NTAG=ntagSUB
						Do pspecdoc In subp_pa With "S"
						Return
					Else
	** 10/19/2017  : #71549 Old TX Reissue and Follow-ups  of Old tags do not use any programmed pages- Use scanned only
						If  SkipTxDocs (PN_LRSNO,ntagSUB )
							Return
						Endif
	** 10/19/2017  : Old TX Reissue and Follow-ups  of Old - do not use programmed pages- Use scanned only
						*10/11/2021 WY 251233 (support test version with 1_ going forward)
						*Do PrintGroup With mv, "TXSubpoena"
						*Do PrintGroup With mv, 	"1_TXSubpoena"
						*255675	
						*--10/25/2022 #277503 call different TX form based on the request date
						docID=2
						oMEDSUB.closealias("viewTxDocCode")
						SELECT 0
						oMEDSUB.sqlexecute("exec dbo.TXDoc2Use 'S','" + fixquote(pc_clcode)+ "', "+ALLTRIM(STR(pn_tag)), "TXDoc2Use")
						IF USED("TXDoc2Use")			
							GO top
							docID=TXDoc2Use.docCode		
						ENDIF 
						IF docID=2
							Do PrintGroup With mv, 	"2_TXSubpoena"
						else
							Do PrintGroup With mv, 	"3_TXSubpoena"
						ENDIF 
						*-----------------------------						
						llRunTxSubDocWithBlindError = .t.
						PRIVATE pcTxHeaderMode
						pcTxHeaderMode = GetTxHeaderStyle(PN_LRSNO, ntagSUB)
					Endif

				Endif
	*!*	**09/25/2017: skip is "S" scanned subp file exists

			Else
				Return

			Endif &&10/25/16: do not print SubpoenaOther page
		ENDIF
	ENDCASE   && 08/03/2020 IL SUBPOENA pl_ILCook=.T. 
Endif

*** ------------------------------------------------------------------------------------
*** ------------------------------------------------------------------------------------
**  -- 09/14/2020 MD #192266 moved SP call here
LOCAL leadfirmName, leadFileNo,inDefendantName, inRole,leadrequestDate, leadFaxNo, leadSendDate
STORE "" TO leadfirmName, leadFileNo,inDefendantName, inRole,leadrequestDate ,leadFaxNo, leadSendDate
IF plCourtIn=.T. or PL_TXCOURT OR pl_ILCook=.T.&& 01/29/2021 MD #222170   *-- 12/14/2021 MD #257044 added  pl_ILCook

	oMEDSUB.closealias("viewDefName")
	SELECT 0
	oMEDSUB.sqlexecute("exec dbo.AttyDefInfo '" + fixquote(pc_clcode)+ "', "+ALLTRIM(STR(pn_tag))+", '"+Iif( pl_plisrq, "P", "D")+"'", "viewDefName")
	IF USED("viewDefName")			
	   	GO TOP 
	   	leadfirmName=ALLTRIM(AttyFirm)
	   	leadFileNo=ALLTRIM(fileno)
	   	inDefendantName=ALLTRIM(DefendantName) 
	   	inRole=ALLTRIM(attyrole) 
	   	leadSendDate=CTOD(sendDate)
	   	leadrequestDate=CTOD(reqDate) &&01/29/2021 MD #211402
	   	leadFaxNo=ALLTRIM(fax)
	Endif	
	oMEDSUB.closealias("viewDefName")
ENDIF 	
*** ------------------------------------------------------------------------------------
*** ------------------------------------------------------------------------------------

If  llProvider And TxNotFed
	If Used("REQUEST")
		Select Request

		lcPDist = DISTRICT
		lcPDiv  = division
		If Not "DIVISION" $ Upper( lcPDiv)
			lcPDiv = Allt( lcPDiv) + " Division"
		Endif
	Endif

	Do PrintGroup With mv, "Provider"
	Do PrintField With mv, "Dist", lcPDist
	Do PrintField With mv, "Div", lcPDiv

	l_ST=oMEDSUB.sqlexecute("SELECT dbo.gfState('" + Iif(Empty(Alltrim(pc_depofile.state)),"PA",Alltrim(pc_depofile.state)) + "')", "DepSt")
	lc_State=Iif(l_ST,DepSt.Exp, "")
	Do PrintField With mv, "State", Alltrim(lc_State)
	Do PrintField With mv, "CaseDist", pc_distrct
	Do PrintField With mv, "CaseDiv", Iif (Isnull(pc_mfcture),pc_divisn,pc_mfcture)
Endif

If pc_RpsForm <> "Blank"

&&EF 09/24/03 Civil Lit Reissue should print 'original' subp req date
	If pl_Hipaa And pl_Reissue
		mdate = gfChkDat( fOrigIss( pn_Suppto) + 20, .F., .F.)
		pd_maild = gfChkDat( fOrigIss( pn_tag), .F., .F.)
	Endif



	ldtxn11 = gfChkDat( fOrigIss(Iif(pl_Reissue, pn_Suppto,pn_tag)), .F., .F.)
	If Type("mdate")<>"D"
		mdate = gfChkDat( fOrigIss( pn_tag), .F., .F.)
	Endif
	mdate= mdate

	Do PrintField With mv, "RequestDate",  Dtoc(ldtxn11)

	Do PrintField With mv, "Loc", ;
		IIF(pl_ofcMD Or pl_ofcPgh, "P", pc_Offcode)
**08/08/03 Print consolidation info for MD-Baltimore filings only
	If bBalt
		Do PrintField With mv, "ConsCase", Iif( Not Isnull( pc_mfcture), ;
			"Consolidation Case No: " + pc_mfcture, "")
	Endif
**08/08/03

	If Type( "ldDueDate") = "D" Or Type( "ldDueDate") = "T"
		If (Dtoc(ldDueDate))<>"  /  /    "
			dep_date = ldDueDate
		Endif
	Endif

	c_cl=	pc_clcode
**08/16/2017 : TX Reissues uses original tag's depo date
	*-- 01/31/2024 MD # 349435  for all reissued subpoena's use original tag
	*-- If (pl_Reissue And PL_TXCOURT And creqType="S")
	If (pl_Reissue And creqType="S")
		n_tg=Nvl(pn_Suppto,pn_tag)
	Else
		n_tg=pn_tag
	Endif

*n_tg=pn_tag

	pd_DueDate= GetReqDueDate(c_cl, n_tg, Iif(Type("dep_date")="T", Ttod(dep_date),dep_date))

	If pl_MichCrt
		ldBusOnly = MIDueDat( Iif( l_Reprint, sztxndate + 1, d_today + 1))
	Endif

	If llRunTxSubDocWithBlindError
		* 01/04/2022 #255675 WY
		* when running TX subpoena, the field "infotext" requires the field "DepDate" 
		* this is a blank magic RPS requirement
		Do PrintField With mv, "DepDate", ""
	else
		Do PrintField With mv, "DepDate", ;
			IIF( pl_MichCrt Or pl_NJSub , Dtoc( ldBusOnly), Dtoc (pd_DueDate))
	ENDIF 

	If bBalt Or ('MD-'$pc_c1Name)
		Do PrintField With mv, "DepDateDayWeek",  Cdow(pd_DueDate)
		Do PrintField With mv, "DepDateDayMonth",  Day(pd_DueDate)
		Do PrintField With mv, "DepDateMonth",  WhatMonthIsIt( Month(pd_DueDate))
		Do PrintField With mv, "DepDateYear", Year(pd_DueDate)

	Endif

	If Type('szEdtReq')="U"
		If Used("Spec_ins")
			Select Spec_ins
			Use
		Endif
		oMEDSUB.sqlexecute("Exec [dbo].[GetTheLatestBlurb] '" + fixquote(pc_clcode) + "',' " + Str(pn_tag) + "'", "Spec_ins")
		szEdtReq=gfAddCR( Spec_ins.spec_inst)
	Endif

	If Empty( Alltrim(szEdtReq))
		szEdtReq = gfAddCR( szrequest)
	Endif
**04/16/2010- RE-SPACE THE BLURB
	*Do PrintField With mv, "BlurbText",  Strtran( Strtran( szEdtReq, Chr(13), " "), Chr(10), "")
	Do PrintField With mv, "InfoText",  Strtran( Strtran( szEdtReq, Chr(13), " "), Chr(10), "")
	lc_EmailAdd=""

	If PL_TXCOURT And creqType="S"
		lcAlias=Alias()
		lc_BarNum=Nvl(pc_BarNo,"")
		Do PrintField With mv, "BarNo", lc_BarNum
*Do PrintField With mv, "Suffix", pc_Suffix
**11/28/2017:  Judicial vs. County court
		mv_cap2=""
		mv_cap2= txcourtcap()
		If Empty(mv_cap2)
			Wait Window 'Error in court caption.'
			Return
		Endif
		mv=mv+mv_cap2
**11/28/2017:  Judicial vs. County court
		c_rqat=  Nvl(pc_rqatcod,'')
		lc_EmailAdd= TxRqemail(0,c_rqat)
		If Not Empty( pc_rqatcod)
			pl_GetAt = .F.
			Do AtyMixed With fixquote(c_rqat), "M", .T.
		Endif
		If !Empty(lcAlias )
			Select (lcAlias )
		ENDIF

		*09/22/2021 WY 251233  put label and data into 1 string for name, dob and ssn		
		*if caller did not pass in tlCalledFromFiling, vfp will initialize to .f.
		Do PrintField With mv, "PlfNameDobSsn", TxCombinePlaintiffFields(tlCalledFromFiling)
 		*255675 WY 12/19/2021
		Do PrintField With mv, "CommandedTo", GetTxCommandedTo(PC_CLCODE, ntagSUB, Dtoc(pd_DueDate))   		
		*255675 WY 12/19/2021
		**-- 06/28/2022 MD #277503
		IF docID=3
			oMEDSUB.closealias("viewTXSubpRules")
			SELECT 0
			oMEDSUB.sqlexecute("exec dbo.TXSubpRules '" + fixquote(pc_clcode)+ "',"+ALLTRIM(STR(ntagSUB))+",'"+Dtoc(pd_DueDate)+"','"+ALLTRIM(mid)+"'", "viewTXSubpRules")
			IF USED("viewTXSubpRules")			 
				 DO PrintField WITH mv, "TxFinCode", ALLTRIM(viewTXSubpRules.txFinCode)
				 DO PrintField WITH mv, "TxRule", ALLTRIM(viewTXSubpRules.txRule)
				 *Do PrintField With mv, "CommandedTo", ALLTRIM(viewTXSubpRules.commandedTo)
				 lcCommandedTo= ALLTRIM(viewTXSubpRules.commandedTo)
			ELSE
				DO PrintField WITH mv, "TxFinCode",""
				DO PrintField WITH mv, "TxRule",""
				*Do PrintField With mv, "CommandedTo", ""			
			ENDIF		

			Do PrintField With mv, "TXReqDate",  Dtoc(ldtxn11) && 09/02/2022 MD to fix not printing CommandedTo
		ENDIF
		**-- 06/28/2022 MD		
		CreateTxHeader()
		 
	ENDIF		

	Do PrintGroup With mv, "Case"
	*255675
	*Do PrintField With mv, "Plaintiff", szPltName 
	Do PrintField With mv, "Plaintiff", PrintFieldIntercept("Plaintiff",szPltName)  
	*255675
	*Do PrintField With mv, "Defendant", mdefendant
	Do PrintField With mv, "Defendant", PrintFieldIntercept("Defendant",mdefendant)

	Do PrintField With mv, "AttyType", Iif( pl_plisrq, "P", "D")  
		
**06/04/2013 USDC PRINTS signature
	If !PL_TXCOURT
		oMEDSUB.closealias("AttySign")
		l_Ok=oMEDSUB.sqlexecute("SELECT dbo.AttySignature('" + fixquote(pc_rqatcod) + "')", "AttySign")
		c_attysign=""
		If Not l_Ok
			c_attysign=Iif(Empty(Alltrim(pc_AtySign)), cnameinv,pc_AtySign)
		Else
			c_attysign=fixquote(AttySign.Exp)
		Endif
	Else
		c_attysign=Iif(Empty(Alltrim(pc_AtySign)), cnameinv,pc_AtySign)
	Endif
***Signature added
	*-- 04/04/2022 MD #266064
	*--Do PrintField With mv, "AttyName", Alltrim(c_attysign)
	If ( Left( Alltrim(UPPER(pc_Court1)), 4) = "USDC"  )		
		oMEDSUB.closealias("usdcBar")
		l_BarNum=oMEDSUB.sqlexecute("SELECT dbo.fn_AttyBarNum('" + fixquote(pc_rqatcod)+ "')", "usdcBar")
		usdcBarNo=Iif(l_BarNum,usdcBar.Exp, "")
		oMEDSUB.closealias("usdcBar")
		Do PrintField With mv, "AttyName", Alltrim(c_attysign)+" "+IIF(LEN(ALLTRIM(NVL(usdcBarNo,"")))=0,"","SB# "+ALLTRIM(NVL(usdcBarNo,"")))
	ELSE
		Do PrintField With mv, "AttyName", Alltrim(c_attysign)
	ENDIF 
	Do PrintField With mv, "Docket", mRDocket
	Do PrintField With mv, "Court", Iif(pc_RpsForm="KOPGeneric" , Alltrim( ccounty ),ccrtSUB ) &&08/29/13 PER lIZ USE SOOUNTY FOR KOPGENERIC COURTS
	Do PrintField With mv, "Court2",  Iif(pl_NJSub,Proper(ccounty),ccrtSUB2)

**11/28/2017   Judicial vs. County court  #70136
	If PL_TXCOURT And creqType="S"
		ccounty="" &&fixquote(Nvl(pc_c1Cnty,''))
	Endif

	Do PrintField With mv, "County", Upper(ccounty)
	Do PrintField With mv, "Term", mTerm
* ------------------------------------------------------------
**02/29/12 All KOP litigation use the same USDC form && removed AND pc_Litcode='C  '
**09/17/09 all USDC courts follow the same rule

**11/28/2017: use one general caption on all TX docs ( remove DIST, AREA and County from CASE): Judicial vs. County court  #70136
	If PL_TXCOURT
		Do PrintField With mv, "Dist",  ""
	Else

		If ( Left( Alltrim(pc_Court1), 4) = "USDC" ) && AND NOT pl_CAVer )
**4/16/09 USDC edit per Liz'a request - do not print "NONE" district
			Do PrintField With mv, "Dist", Iif(Alltrim(pc_tagdist)='NONE', '',Allt( pc_tagdist))
		Else
			Do PrintField With mv, "Dist",  Upper(Allt( pc_distrct))
		Endif
	Endif


**02/29/12 All KOP litigation use the same USDC form && removed AND pc_Litcode='C  '
**09/17/09 all USDC courts follow the same rule
	If ( Left( Alltrim(pc_Court1), 4) = "USDC" ) && AND NOT pl_CAVer )
**4/16/09 -edit USDC per Liz's request
**11/12/14- use a part of a court's description  per Liz
		c_court=""
		nlen=0
		nlen= Len(Alltrim(pc_c1Desc))
		c_court=Right( Alltrim(pc_c1Desc), nlen-7)
		Do PrintField With mv, "Area", c_court
	Else
**11/28/2017  Judicial vs. County court  #70136
*Do PrintField With mv, "Area", Iif((PL_TXCOURT And creqType="S"),Alltrim(pc_txCrtType) ,  mCrtDesc)
		Do PrintField With mv, "Area", Iif((PL_TXCOURT And creqType="S"),Alltrim("") ,  mCrtDesc)
	Endif
	If Type('pd_pldob')<>"C"
		pd_pldob=Dtoc(pd_pldob)
	Endif
	Do PrintField With mv, "BirthDate",  Left(pd_pldob,10)
	Do PrintField With mv, "SSN", pc_plssn


	If Left( Alltrim(pc_Court1), 4) = "USDC"  And pl_c1Form &&09/17/09
		Do PrintField With mv, "FullName",  pc_plnam
		Do PrintField With mv, "DepoState", Upper(getstatename(Alltrim(pc_depofile.state)))
		Do PrintField With mv, "FirmName", cnameinv

	Endif
    &&-------------------------------------------------------------------------
	&& 05/31/2019 MD #135050 the doctor name is not formatted due to the blank MID
	isMIDBlank=.F.
	IF EMPTY(ALLTRIM(NVL(pc_mailid,"")))
		isMIDBlank=.T.
	   pc_mailid=ALLTRIM(NVL(request.mailid_no,""))
	ENDIF 
	&&-------------------------------------------------------------------------
	Do pDepInfo  In subp_pa With mid, Proper( mdep), .F.
	&&------------------------------------------------------------------------
	&& 05/31/2019 MD #135050 set MID back to blank.  To make sure nothing is affected
    IF isMIDBlank=.T.
       pc_mailid=""
    ENDIF 
	&&------------------------------------------------------------------------
* ----------- 02/01/2019 MD #123591------------------------
	LOCAL ldefendantName
	ldefendantName=""	
	If Left( Alltrim(UPPER(pc_Court1)), 4) = "USDC"
		oMEDSUB.closealias("viewDefName")
		SELECT 0
		oMEDSUB.sqlexecute("exec dbo.AttyDefName '" + fixquote(pc_clcode)+ "', '"+Iif( pl_plisrq, "P", "D")+"'", "viewDefName")
		IF USED("viewDefName")
			 ldefendantName=ALLTRIM(viewDefName.defendantName)	 	
		ENDIF
	ENDIF 		

	If Left( Alltrim(UPPER(pc_Court1)), 4) = "USDC"		
		Do PrintField With mv, "DefendantName", ldefendantName   
	ENDIF 
*--------------------------------------------------------------
** --- 08/07/2020 MD #170629 added plCourtIN ----------------------------------- 
	If (TxNotFed Or pl_ILCook OR plCourtIN ) And !PL_TXCOURT
		Do PrintGroup With mv, "Atty"
		Do PrintField With mv, "Name_inv", cnameinv
		Do PrintField With mv, "Ata1", mratadd1
		Do PrintField With mv, "Ata2", mratadd2
		Do PrintField With mv, "Atacsz", mratcsz
		Do PrintField With mv, "Phone", mphone
		
		IF pl_MichCrt													&& 6/14/2022, ZD #273584, JH 
			Do PrintField With mv, "atac", pc_AtyCity 						
			Do PrintField With mv, "atas", pc_AtyState
			Do PrintField With mv, "ataz", pc_AtyZip
		ENDIF															&& 6/14
																		
**09/18/07- print a firm's name with the USDC subs.
		If Left( Alltrim(pc_Court1), 4) = "USDC"
			Do PrintField With mv, "Ata3", pc_AtyFirm			
		ENDIF
		IF  plCourtIN=.T.
			LOCAL INnewDistrict, INnewCounty
			STORE "" TO INnewDistrict, INnewCounty 			
			Do PrintField With mv, "FaxNo", leadFaxNo
			*---- 09/17/2020 MD #191480
			*--- 09/23/2020 fixed spelling error
			LOCAL lcSQLLine
			omedSub.closealias("viewINDCourtDist")													
			omedSub.sqlexecute("exec dbo.INNotcCourtDist '" +fixquote(PC_CLCODE)+"'", "viewINDCourtDist")	
			SELECT viewINDCourtDist
			IF RECCOUNT()>0
				GO top
				*---IndCourtDist=ALLTRIM(NVL(district,"" ))  10/29/2020 MD #202001
				*-- IndSubpHeader=ALLTRIM(NVL(subpHeader,"" ))  07/07/2021 MD
				INnewDistrict=ALLTRIM(NVL(newDistrict,"" ))
				INnewCounty=ALLTRIM(NVL(newCounty,"" ))
			ENDIF 			
			omedSub.closealias("viewINDCourtDist")	
			*--Do PrintField With MV, "District", ALLTRIM(IndCourtDist)  10/29/2020 MD #202001	
			*-- Do PrintField With MV, "District", ALLTRIM(IndSubpHeader) 	
			*-- 07/07/2021 MD
			Do PrintField With MV, "District", ALLTRIM(INnewDistrict) 	
			Do PrintField With MV, "County", ALLTRIM(INnewCounty) 		
			*---- 09/17/2020 MD #191480	
		ENDIF 
	ENDIF
	
		
	If  PL_TXCOURT

&& 08/24/2017 : ADDED A COMMA TO ATTY'S ADDRESS
		c_line1=""
		c_line1=pc_Aty1Ad + Iif(Empty(Alltrim(pc_Aty2Ad)), "", ", " + pc_Aty2Ad)  &&+  IIF(EMPTY(ALLTRIM(pc_Aty2Ad)), "", ", " )

		Do PrintGroup With mv, "Atty"
		Do PrintField With mv, "Name_inv", pc_AtySign
		Do PrintField With mv, "Ata1", c_line1
		Do PrintField With mv, "Ata2","" && pc_Aty2Ad
		Do PrintField With mv, "Atacsz", pc_Atycsz
		Do PrintField With mv, "Phone", pc_AtyPhn
		Do PrintField With mv, "Ata3", pc_AtyFirm
		Do PrintField With mv, "Attn", lc_EmailAdd
		Do PrintField With mv, "FaxNo", pc_AtyFax
	Endif





	If pl_c1Form And !PL_TXCOURT
		Do PrintField With mv, "PLAtty", szPlAtty
	ENDIF
	
	*  02/01/2019 MD #123591
	If Left( Alltrim(UPPER(pc_Court1)), 4) = "USDC"
	    * -- 04/05/2019  MD #123591
	    c_rqat=  Nvl(pc_rqatcod,'')
	    lc_EmailAdd= TxRqemail(0,c_rqat)
		Do PrintField With mv, "attyemail",lc_EmailAdd		
	ENDIF 
	
	If pl_ofcMD And Alltrim( pc_Court1) = "MD-HCA"
		Store "" To szPlAtty, mnameinvP, mratadd1P, mratadd2P, mratcszP, mphoneP, mCrtDesc
		If Not Empty( pc_platcod)
			c_plAtty =fixquote(pc_platcod)
			pl_GetAt = .F.
			Do gfatinfo With c_plAtty, "M"

			szPlAtty =pc_AtyName
			mnameinvP = pc_AtySign
			mratadd1P = pc_Aty1Ad
			mratadd2P = pc_Aty2Ad
			mratcszP = pc_Atycsz
			mphoneP = pc_AtyPhn

		Endif

		Do PrintGroup With mv, "PLAtty"
		Do PrintField With mv, "Ata12", mratadd1P
		Do PrintField With mv, "Ata22", mratadd2P
		Do PrintField With mv, "Atacsz2", mratcszP
	Endif
Endif                                        &&12/10/02 MD subp

&&EF 10/17/02, 11/12/02:  Michigan subpoenas print special fields plus pl_ILCook as 1/16/2013
** --- 08/05/2020 MD #170629  added plCourtIN=.T.----------------------------------- 
If pl_MichCrt Or pl_ILCook OR plCourtIN=.T.
	lcAlias = Select()
	lc_RqAtty=fixquote(pc_rqatcod)
	l_BarNum=oMEDSUB.sqlexecute("SELECT dbo.fn_AttyBarNum('" + lc_RqAtty + "')", "AtBarNum")
	lc_BarNum=Iif(l_BarNum,AtBarNum.Exp, "")
	Select ( lcAlias)
	If Type('pd_pldob')<>"C"
		pd_pldob=Dtoc(pd_pldob)
	ENDIF	
	If pl_ILCook
		*  -- 09/09/2019 MD #143028
		*  -- lc_RecPertain = pc_plnam + " DOB: " +  Left(pd_pldob,10) + " SSN:" + pc_fullssn
		lc_RecPertain = pc_plnam 
	Else
		lc_RecPertain = pc_plnam + Chr(13) + "DOB: " +  Left(pd_pldob,10) +Chr(13) + ;
			"RT#: " + pc_lrsno + " Tag #: " + Alltrim( Str( ntagSUB))
	ENDIF
	IF plCourtIN=.T.
		Do PrintField With mv, "BarNo", lc_BarNum
		Do PrintField With mv, "IssueDate", Dtoc( mdate)
		Do PrintField With mv, "ClientRep", Alltrim(pc_amgr_nm)
	ELSE 
		Do PrintField With mv, "RecPertain", lc_RecPertain
		Do PrintField With mv, "BarNo", lc_BarNum
		If pl_ILCook
			Do PrintField With mv, "ClientRep", Alltrim(pc_amgr_nm)
			*-- 12/14/2021 MD #257044 print issuedate as sendDate
			* Do PrintField With mv, "IssueDate", Dtoc( mdate)
			Do PrintField With mv, "IssueDate", Dtoc(leadSendDate)
			Do PrintField With mv, "Id", pc_ScanSg

		ENDIF
	ENDIF 
ENDIF

If bBalt
	Do PrintGroup With mv, "SubpoenaMD-Balt2"
	Do PrintField With mv, "DepDate", Dtoc( pd_DueDate)

	Do PrintField With mv, "DepDateDayWeek",  Cdow(pd_DueDate)
	Do PrintField With mv, "DepDateDayMonth",  Day(pd_DueDate)
	Do PrintField With mv, "DepDateMonth",  WhatMonthIsIt( Month(pd_DueDate))
	Do PrintField With mv, "DepDateYear", Year(pd_DueDate)


	Do PrintField With mv, "RequestDate", Dtoc( mdate)
	Do PrintField With mv, "Loc", ;
		IIF( pl_ofcMD Or pl_ofcPgh, "P", pc_Offcode)


	Do PrintField With mv, "ConsCase", Iif( Isnull( pc_mfcture), "", ;
		"Consolidation Case No: " + pc_mfcture)

	Do PrintGroup With mv, "Case"
	Do PrintField With mv, "Plaintiff", szPltName
	Do PrintField With mv, "Defendant", mdefendant
	Do PrintField With mv, "AttyType", Iif( pl_plisrq, "P", "D")
	Do PrintField With mv, "AttyName", cnameinv
	Do PrintField With mv, "Docket", mRDocket



	Do PrintGroup With mv, "Atty"
	Do PrintField With mv, "Ata1", mratadd1
	Do PrintField With mv, "Ata2", mratadd2
	Do PrintField With mv, "Atacsz", mratcsz
	&&-------------------------------------------------------------------------
	&& 05/31/2019 MD #135050 the doctor name is not formatted due to the blank MID
	isMIDBlank=.F.
	IF EMPTY(ALLTRIM(NVL(pc_mailid,"")))
		isMIDBlank=.T.
	   pc_mailid=ALLTRIM(NVL(request.mailid_no,""))
	ENDIF 
	&&-------------------------------------------------------------------------	
	Do pDepInfo In subp_pa With mid, Proper( mdep), .F.
	&&------------------------------------------------------------------------
	&& 05/31/2019 MD #135050 set MID back to blank.  To make sure nothing is affected
    IF isMIDBlank=.T.
       pc_mailid=""
    ENDIF 
	&&------------------------------------------------------------------------
	
ENDIF
** --- 08/07/2020 MD #170629 ----------------------------------- 
** --- 08/31/2020 MD removed "Proper" from firmname
IF plCourtIn=.T.    
	LOCAL indDefName
	indDefName=CHRTRAN(ALLTRIM(UPPER(NVL(inDefendantName,""))),"(S)","")
	Do PrintField With mv, "FirmName", leadfirmName
	Do PrintField With mv, "subDefName", IIF(INLIST(indDefName,"PLAINTIFF","DEFENDANT"),"",inDefendantName)
	Do PrintField With mv, "Role", inRole
	Do PrintField With mv, "Issueday", DAY(leadrequestDate)
	Do PrintField With mv, "Issuemonth", CMONTH(leadrequestDate)
	Do PrintField With mv, "Issueyear", YEAR(leadrequestDate)
	Do PrintField With mv, "Sendday", DAY(leadSendDate)
	Do PrintField With mv, "Sendmonth", CMONTH(leadSendDate)
	Do PrintField With mv, "Sendyear", YEAR(leadSendDate)
	Do PrintField With mv, "Fileno", leadFileNo
	Do PrintField With mv, "RTTag",ALLTRIM(STR(pn_lrsno))+"."+ALLTRIM(STR(pn_tag))
	
ENDIF
** --- 08/07/2020 MD #170629 ----------------------------------- 
** ---  01/29/2021 MD #222170 
** --- 02/03/2021 MD #222873 ----------------------------------- 
IF plCourtIn=.T. 
		oMEDSUB.closealias("viewNoticeAttyList")
		SELECT 0
		oMEDSUB.sqlexecute("exec dbo.NoticeAttyList '" + fixquote(pc_clcode)+ "'", "viewNoticeAttyList")
		IF USED("viewDefName")
			 ldefendantName=ALLTRIM(viewDefName.defendantName)	 	
		ENDIF		
		LOCAL ntcLoop,ntcCount,ntcRound,ntcMod, noticeString1,noticeString2	
		SELECT IIF(!EMPTY(ALLTRIM(NVL(viewNoticeAttyList.attyName,""))),ALLTRIM(NVL(viewNoticeAttyList.attyName,""))+CHR(13),"")+;
		IIF(!EMPTY(ALLTRIM(NVL(viewNoticeAttyList.attyFirm,""))),ALLTRIM(NVL(viewNoticeAttyList.attyFirm,""))+CHR(13),"")+;
		IIF(!EMPTY(ALLTRIM(NVL(viewNoticeAttyList.attyAdd1,""))),ALLTRIM(NVL(viewNoticeAttyList.attyAdd1,""))+" ","")+;
		IIF(!EMPTY(ALLTRIM(NVL(viewNoticeAttyList.attyAdd2,""))),ALLTRIM(NVL(viewNoticeAttyList.attyAdd2,"")),"")+;
		IIF(LEN(ALLTRIM(NVL(viewNoticeAttyList.attyAdd1,"")))+LEN(ALLTRIM(NVL(viewNoticeAttyList.attyAdd2,"")))>0,CHR(13),"")+;
		IIF(!EMPTY(ALLTRIM(NVL(viewNoticeAttyList.attyAdd3,""))),ALLTRIM(NVL(viewNoticeAttyList.attyAdd3,""))+CHR(13),""); 
			FROM viewNoticeAttyList INTO ARRAY arAtty
			ntcCount = ALEN( arAtty) / 2
			ntcRound = ROUND(ntcCount, 0)
			ntcMod = MOD( ntcCount, 2)
			FOR ntcLoop = 1 TO ntcRound
				DO PrintGroup WITH mv, "Item"
				STORE "" TO noticeString1,noticeString2
				IF (ntcLoop*2-1)<=ALEN(arAtty)
					noticeString1=arAtty[ ntcLoop*2-1, 1]
				ENDIF 
				IF (ntcLoop <=ntcRound) OR ntcMod = 0
					IF (ntcLoop*2)<=ALEN(arAtty)
						noticeString2=arAtty[ntcLoop*2,1]
					ENDIF 
				ENDIF
				DO PrintField WITH mv, "Col1", noticeString1
				DO PrintField WITH mv, "Col2", noticeString2
			ENDFOR
		
		oMEDSUB.closealias("viewNoticeAttyList")
ENDIF 
** --- 02/03/2021 MD #222873 ----------------------------------- 
** --- 08/07/2020 MD #170629 ----------------------------------- 
IF  PL_TXCOURT
	Do PrintField With mv, "DefendantName", inDefendantName	
	IF docID=3
		Do PRINTGROUP With MV, "Item"
		Do PRINTFIELD With MV, "Tbl1Col", lcCommandedTo
	ENDIF
ENDIF 
** ---  01/29/2021 MD #222170

**02/29/12 All KOP litigation use the same USDC form && removed AND pc_Litcode='C  '
**03/11/14- PRINT EXIBIT A WITH NOTICES/ORDER VERIFICATIONS
If (Left( Alltrim(pc_Court1), 4) = "USDC") && AND NOT bNotcall && DO NOT PRINT AN ATTACMENT FOR NOTICES (KOP ONLY, BUT PRINT FOR THE CA)

	If pl_kopVer =.T. And Not bNotcall
** DO NOT PARINT THAT PAGE WITH  NOTICES
		Do PrintGroup With mv, "USDCPage2"
	Endif


	If pl_CAVer =.T. And Not pl_CANotc
** DO NOT PARINT THAT PAGE WITH THE CA NOTICES
		Do PrintGroup With mv, "USDCPage2"
	Endif


&&3/25/14-rider can be a stored 'Return" image now
	Local c_riderpcx As String
	c_riderpcx=""
	c_riderpcx=SUBRIDERPCX	(pn_tag,"R",1 )
	If !Empty(Alltrim(c_riderpcx))
		ntag= pn_tag
		Do pspecdoc In subp_pa With 'R'

	Else

		Do PrintGroup With mv, "ExhibitUSDC"
**12/19/2017  #75494 - make sure we have a blurb
**04/16/2010- Respace the blurbs
		If Type('szEdtReq')="U" OR EMPTY(ALLTRIM(szEdtReq))
			If Used("Spec_ins")
				Select Spec_ins
				Use
			Endif
			oMEDSUB.sqlexecute("Exec [dbo].[GetTheLatestBlurb] '" + fixquote(pc_clcode) + "',' " + Str(pn_tag) + "'", "Spec_ins")
			szEdtReq=gfAddCR( Spec_ins.spec_inst)
		Endif

		Do PrintField With mv, "InfoText",  Strtran( Strtran( szEdtReq, Chr(13), " "), Chr(10), "")
		Do PrintField With mv, "CaseplCap", szPltName
		Do PrintField With mv, "CasedefCap", mdefendant
		Do PrintField With mv, "CaseDocket", mRDocket
		Do PrintField With mv, "ControlLrsNo", Str(pn_lrsno)
		Do PrintField With mv, "ControlTag" , Str( pn_tag)
		Do PrintField With mv, "Deponent" , mdep
		lc_RecPertain=""
		*01/31/2023 MD #349243
		lc_RecPertain = pc_plnam + "  DOB: " +  Left(pd_pldob,10) +  "  SSN: " + Alltrim( pc_plssn)+;
		IIF(LEN(ALLTRIM(NVL(pc_maiden1,"")))>0,"  AKA: "+alltrim(NVL(pc_maiden1,"")),"")
		Do PrintField With mv, "Pertain" , lc_RecPertain

	Endif   &&3/25/14-rider by image

Endif



If pl_kopVer And Alltrim(pc_Court1)='IL-WCC'
	Do PrintGroup With mv, "Plaintiff"
* DMA 05/25/04 Switch to long plaintiff name
	Do PrintField With mv, "FirstName", pc_plnam
	Do PrintField With mv, "MidInitial", ""
	Do PrintField With mv, "LastName", ""
	Do PrintField With mv, "Addr1", pc_pladdr1
	Do PrintField With mv, "Addr2", pc_pladdr2
	If Type('pd_pldob')<>"C"
		pd_pldob=Dtoc(pd_pldob)
	Endif
	If Type('pd_pldod')<>"C"
		pd_pldod=Dtoc(pd_pldod)
	Endif

	Do PrintField With mv, "BirthDate", Left(pd_pldob,10)
	Do PrintField With mv, "SSN", Allt( pc_plssn)
	Do PrintField With mv, "DeathDate",  Left(pd_pldod,10)
	Do PrintField With mv, "Extra", ""

ENDIF
	

***EF 11/07/08 PAGE 2 FOR CIVIL LIT usdc
Release oMEDSUB
If Not Empty(lcselect)
	Select (lcselect)
ENDIF
Return
*****************************************************************************************************************************
*****************************************************************************************************************************
Function WhatMonthIsIt()
*****************************************************************************************************************************
Parameters nId
Private c_month As String
c_month =''
c_month= laMonth[nId ]
Return c_month



*09/22/2021 WY 251233		
*put label and data into 1 string for name, dob and ssn
FUNCTION TxCombinePlaintiffFields (tlRedact as Boolean) as String
	LOCAL lcReturnStr, lcDob, llHaveSSn
	lcReturnStr = ""

	*name
	IF LEN(ALLTRIM(pc_plnam)) > 0
		lcReturnStr = pc_plnam && no label needed
	ENDIF 

	*dob
	lcDob = IIF(Type('pd_pldob') <> "C", Dtoc(PD_PLDOB), PD_PLDOB)		 
	IF LEN(ALLTRIM(lcDob)) > 4 && this is 4 "/  /"    if no dob skip
		IF tlRedact 
			*redact (label only)
			lcReturnStr = lcReturnStr + "  DOB: "
		else
			*label and data
			IF LEN(lcReturnStr) > 0
				lcReturnStr = lcReturnStr + "  DOB: " + Left(lcDob,10)
			ELSE
				lcReturnStr = "DOB: " + Left(lcDob,10)	
			ENDIF 
		ENDIF 
	ELSE
		**no label, no data
	ENDIF 

	*ssn
	IF LEN(pc_plssn) > 0
		IF tlRedact 
			*redact (label only)
			lcReturnStr = lcReturnStr + "  SSN: "
		else
			*when ssn is missing, user wants to see blank not ###-##
			*llHaveSSn = IIF(ISDIGIT(pc_fullssn), .t., .f.)
			*10/29/2021 WY 254896 (a legit ssn has a number)
			llHaveSSn = StringHaveNumber(pc_fullssn)
			IF llHaveSSn
				IF LEN(lcReturnStr) > 0
					lcReturnStr = lcReturnStr + "  SSN: " + ALLTRIM(pc_fullssn) &&pc_plssn 01/24/2023 MD #302061
				ELSE
					lcReturnStr = "SSN: " + ALLTRIM(pc_fullssn) &&pc_plssn 01/24/2023 MD #302061
				ENDIF 
			ELSE
				*do not include SSN caption and data
			ENDIF 
		ENDIF 
	ELSE
		**no label, no data		
	ENDIF 
	*-- 02/13/2024 MD #350397
	IF LEN(ALLTRIM(NVL(pc_maiden1,""))) > 0
		IF tlRedact 
			*redact (label only)
			lcReturnStr = lcReturnStr + "  AKA: "
		else						
			IF LEN(lcReturnStr) > 0
				lcReturnStr = lcReturnStr + "  AKA: " + ALLTRIM(pc_maiden1) &&pc_plssn 01/24/2023 MD #302061
			ELSE
				lcReturnStr = "AKA: " + ALLTRIM(pc_maiden1) &&pc_plssn 01/24/2023 MD #302061
			ENDIF 		
		ENDIF 
	ELSE
		**no label, no data		
	ENDIF 
	*-- 02/13/2024 
	RETURN lcReturnStr
ENDFUNC 

*return .t. if a string has a number, determine whether or not to display a SSN
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


*****************************************************************************************************************************
*!*	**3/11/2013- retutrn future path for a scanned subp for a KOP Generic courts (signed subp)
*!*	FUNCTION FakeSubpPcx
*!*	PARAMETERS ntagn
*!*	LOCAL lcLrs AS STRING, lcSPath AS STRING, lcDPath AS STRING
*!*	lcLrs = ALLT( pc_lrsno)
*!*	lcSPath = goApp.pcxpath
*!*	lcDPath = goApp.pcxarchpath +"\" + RIGHT(lcLrs,1) + "\"

*!*	lcSource =lcSPath +  lcLrs  + "S1." + TRANS(ntagn, "@L 999")
*!*	lcDest   = lcDPath + "\"+ lcLrs  +"S1." + TRANS(ntagn, "@L 999")
*!*	IF  NOT FILE(lcDest )
*!*		lcDest =lcSource
*!*	ENDIF
*!*	RETURN lcDest
*!*	*************************


*#255675
FUNCTION GetTxCommandedTo(tcClode as String,  tnTagSub as Integer, tcDueDate as string) as String
	LOCAL lcDwq
	lcDwq = GetTxDWQ(tcClode, tnTagSub)

	IF LEN(ALLTRIM(lcDwq)) > 0
		Return "to give a deposition by written questions and produce and permit copying and inspection " + ;
			"of the documents identified below before a Notary Public at your office on " + tcDueDate 
	ELSE
		RETURN "to produce and permit copying and inspection of the documents identified in the attached rider on " + tcDueDate
	ENDIF 
ENDFUNC 

*#255675 WY handle 3 fields in the TX subpoena header
PROCEDURE CreateTxHeader() 
	Do PrintField With mv, "UnderCasePlaintiff", PrintFieldIntercept("UnderCasePlaintiff")   		
	*Do PrintField With mv, "UCPlaintiff", PrintFieldIntercept("UnderCasePlaintiff")   		
	IF pcTxHeaderMode = 3
		Do PrintField With mv, "Ver", PrintFieldIntercept("Ver", szPltName)   		
	ELSE
		Do PrintField With mv, "Ver", PrintFieldIntercept("Ver")   		
	ENDIF 
	Do PrintField With mv, "UnderCaseDef", PrintFieldIntercept("UnderCaseDef")   
*	Do PrintField With mv, "UCDef", PrintFieldIntercept("UCDef")   	

ENDPROC 


