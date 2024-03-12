
**Procedure SubpAttch
** Rider page to go with each KOP subpoena page
PARAMETERS MV, C_INFO,  N_TAG, C_DEP
LOCAL C_RIDERPCX AS STRING, N_COUNT AS INTEGER, L_RIDER AS BOOLEAN
LOCAL lcSQLLine
WAIT WINDOW "Printing Attachment to a Subpoena" NOWAIT
**08/08/2017- USE WITH TX Courts
**06/01/2017 - skip TX Courts
**03/11/2015 - for usdc it print already with a subpage in subprint.prg
**01/30/2014 - for PA-Montgomery  Fillings sets do not show SSn and DOB on a rider
**07/10/2013- Print scanned rider "R" type image when found 'HOLD_PRINT' project

&&IF  LEFT( ALLTRIM(pc_Court1), 4) = "USDC"  
IF  LEFT(ALLTRIM(pc_Court1),4) = "USDC" AND UPPER(ALLTRIM(pc_Court1)) <> "USDC-17" 	&& per AK, 10/4/2023, JH
	RETURN
ENDIF

C_RIDERPCX=""
C_RIDERPCX=SUBRIDERPCX	(N_TAG,"R",1 )
IF !EMPTY(ALLTRIM(C_RIDERPCX))
	ntag= N_TAG
	DO pspecdoc IN subp_pa WITH 'R'
**move to pcxarchf
ELSE

** 10/19/2017  : #71549 Old TX Reissue and Follow-ups  of Old tags do not use any programmed pages- Use scanned only
	*If  SkipTxDocs (PN_LRSNO,N_TAG ) && commented out 10/11/2021 WY #251233
	*	Return && commented out 10/11/2021 WY #251233
	*Endif && commented out 10/11/2021 WY #251233
** 10/19/2017  : #71549 Old TX Reissue and Follow-ups  of Old tags do not use any programmed pages- Use scanned only
	*10/11/2021 WY #251233 (TX support only scanned rider, no need for code generated rider)
	IF pl_Txcourt 
		RETURN 
	ENDIF 


***4/30/14 - USE DEPONENTS NAME INSTEAD OF THE TXN 11 LINE DESCRIPTION -PER LIZ
	LOCAL C_DEPT2 AS STRING
	C_DEP2=""
	C_SQL="select dbo.GetDeptCode2('" +FIXQUOTE(PC_CLCODE) +"',"+ALLTRIM(STR(N_TAG))+") as deptcode"
	IF TYPE('OMED') <>"O"
		OMED= CREATEOBJECT("generic.medgeneric")
	ENDIF
	OMED.SQLEXECUTE(C_SQL, "Dept")
	C_ADDITION= GETDESCRIPT(NVL(DEPT.DEPTCODE,'Z'))
	**09/07/17 : alwaus Upper deponame on a rider 
	&&-------------------------------------------------------------------------
	&& 05/31/2019 MD #135050 the doctor name is not formatted due to the blank MID
	isMIDBlank=.F.
	IF EMPTY(ALLTRIM(NVL(pc_mailid,"")))
		isMIDBlank=.T.
	   pc_mailid=ALLTRIM(NVL(request.mailid_no,""))
	ENDIF 
	&&-------------------------------------------------------------------------
	IF USED ('PC_DEPOFILE')
		C_DEP2=DEPTOPRINT(upper (ALLTRIM(NVL(PC_DEPOFILE.NAME,C_DEP))))
	ELSE

		OMED.closealias('TagDesc')
		lcSQLLine="select dbo.GetdepName ( '" + PC_Mailid+ "')"
		OMED.SQLEXECUTE(lcSQLLine,"TagDesc")
		IF USED('TagDesc')
			C_DEP2=DEPTOPRINT(ALLTRIM(NVL(TagDesc.EXP,"")))
		ELSE
			C_DEP2= C_DEP
		ENDIF

	ENDIF
	&&-------------------------------------------------------------------------
	&& 05/31/2019 MD #135050 set MID back to blank.  To make sure nothing is affected
    IF isMIDBlank=.T.
       pc_mailid=""
    ENDIF 
    &&-------------------------------------------------------------------------
    
***4/30/14 - USE DEPONENTS NAME INSTEAD OF THE TXN 11 LINE DESCRIPTION -PER LIZ
** --- 08/07/2020 MD #170629 added plCourtIN -----------------------------------
	IF plCourtIn=.T.
		* DO PRINTGROUP WITH MV, "SubpIN_Atch" -- 07/08/2021
		DO PRINTGROUP WITH MV, "SubpIN_Atch2"
		Do PrintGroup With mv, "Case"
		Do PrintField With mv, "Plaintiff",  pc_plcaptn
		Do PrintField With mv, "Defendant",  Allt(pc_dfcaptn)
		Do PrintField With mv, "Docket", pc_docket
		Do PrintField With mv, "County", Upper(pc_c1cnty)
		Do PrintField With mv, "Loc", IIF(pl_ofcMD Or pl_ofcPgh, "P", pc_Offcode)		
	ELSE 
		DO PRINTGROUP WITH MV, "SubpAttch"
		DO PRINTFIELD WITH MV, "InfoText", C_INFO &&--07/14/2021 MD
	ENDIF 
**09/21/2017: remove reductions  #69867
*!*		IF TYPE("pd_dateCourtset") ="D"  &&4/17/14 - replace nn by xx for rider with filings
*!*			C_INFO=numtoxx(C_INFO)
*!*		ENDIF
	*-- DO PRINTFIELD WITH MV, "InfoText", C_INFO 07/14/2021 MD
	DO PRINTFIELD WITH MV,"DeponentName", C_DEP2  + C_ADDITION &&C_DEP

	DO PRINTGROUP WITH MV, "Plaintiff"
	DO PRINTFIELD WITH MV, "FirstName", ALLTRIM( PC_PLNAM)
	DO PRINTFIELD WITH MV, "MidInitial", ""
	DO PRINTFIELD WITH MV, "LastName", ""
	IF TYPE('pd_pldob')<>"C"
		PD_PLDOB=DTOC(PD_PLDOB)
	ENDIF

**04/18/2014- do not show dob and ssn for riders with notices/ord verif
**01/30/2014 - for  Fillings sets do not show SSn and DOB on a rider
	
		DO CASE 
		CASE plCourtIn=.T. &&-- 08/13/2020 MD print for Indina court
			LOCAL INnewDistrict, INnewCounty
			STORE "" TO INnewDistrict, INnewCounty 	
			*--DO PRINTFIELD WITH MV, "BirthDate",  LEFT(PD_PLDOB,10) -- 07/08/2021 MD
			DO PRINTFIELD WITH MV, "BirthDate",  IIF(LEN(alltrim(LEFT(NVL(PD_PLDOB,""),10)))>0,"Date of Birth: "+alltrim(LEFT(NVL(PD_PLDOB,""),10)),"")
			*--DO PRINTFIELD WITH MV, "SSN", PC_FULLSSN &&pc_plssn
			DO PRINTFIELD WITH MV, "SSN", IIF(LEN(alltrim(NVL(PC_FULLSSN,"")))>0,"Social Security: "+alltrim(NVL(PC_FULLSSN,"")),"") &&pc_plssn
			*---- 09/17/2020 MD #191480			
			omed.closealias("viewINDCourtDist")													
			omed.sqlexecute("exec dbo.INNotcCourtDist '" +fixquote(PC_CLCODE)+"'", "viewINDCourtDist")	
			SELECT viewINDCourtDist
			IF RECCOUNT()>0
				GO top
				*--IndCourtDist=ALLTRIM(NVL(district,"" )) 10/29/2020 MD #202001
				*-- 07/09/2021
				*-- IndSubpHeader=ALLTRIM(NVL(subpHeader,"" ))
				INnewDistrict=ALLTRIM(NVL(newDistrict,"" ))
				INnewCounty=ALLTRIM(NVL(newCounty,"" ))
				*-- 07/09/2021
			ENDIF 			
			omed.closealias("viewINDCourtDist")	
			*--Do PrintField With MV, "District", ALLTRIM(IndCourtDist)  10/29/2020 MD	 #202001
			*-- 07/09/2021
			*-- Do PrintField With MV, "District", ALLTRIM(IndSubpHeader) 				
			Do PrintField With MV, "District", ALLTRIM(INnewDistrict) 	
			Do PrintField With MV, "County", ALLTRIM(INnewCounty) 
			*-- 07/09/2021		
			*---- 09/17/2020 MD #191480	
			
		case TYPE("pd_dateCourtset") ="D"  OR pl_Noticng

			*!*	08/03/2021  WY 194733 (IL notice needs to display SSN and DOB)
			*!* Alec wants to include all IL (including IL-WCC)			
			IF LEFT(UPPER(pc_Court1), 3) = 'IL-' AND pl_Noticng
				*get SSN and DOB
				C_SQL = "exec dbo.GetSsnDobFromMaster '" + FIXQUOTE(PC_CLCODE) + "'"
				LOCAL lcOldAlias
				lcOldAlias = ALIAS()
				omed.closealias("ssnAndDob") && omed declared above		
				omed.SqlExecute(C_SQL, "ssnAndDob") 				
				DO PRINTFIELD WITH MV, "BirthDate", DTOC(ssnAndDob.brth_date)
				DO PRINTFIELD WITH MV, "SSN", ALLTRIM(ssnAndDob.soc_sec)			
				USE IN ssnAndDob
				IF LEN(lcOldAlias) > 0
					SELECT (lcOldAlias)
				ENDIF 
			else
				DO PRINTFIELD WITH MV, "BirthDate",  ""
				DO PRINTFIELD WITH MV, "SSN", ""
			ENDIF 

			**DO PRINTFIELD WITH MV, "BirthDate",  ""
			**DO PRINTFIELD WITH MV, "SSN", ""

		OTHERWISE 
			DO PRINTFIELD WITH MV, "BirthDate",  LEFT(PD_PLDOB,10)
			DO PRINTFIELD WITH MV, "SSN", PC_FULLSSN &&pc_plssn
		ENDCASE 
	*-- 09/18/2019 MD #143595 
	
	** --- 08/07/2020 MD #170629 added plCourtIN -----------------------------------
	** --  08/31/2020 MD removed "proper" from firmname
	IF plCourtIn=.T.
		LOCAL leadfirmName, leadFileNo,leadDefendantName, leadRole,leadAtty,leadBarNo,leadNameInv,;
		leadAdd1,leadAdd2,leadAddcsz,leadAddcsz,leadPhone,leadFax, leadrequestDate, leadSendDate, leadInfoText
		STORE "" TO leadfirmName, leadFileNo,leadDefendantName, leadRole,leadAtty,leadBarNo,leadNameInv,;
		leadAdd1,leadAdd2,leadAddcsz,leadAddcsz,leadPhone,leadFax, leadrequestDate,  leadSendDate, leadInfoText
		oMED.closealias("viewDefName")
		SELECT 0
		oMED.sqlexecute("exec dbo.AttyDefInfo '" + fixquote(pc_clcode)+ "', "+ALLTRIM(STR(N_TAG))+", '"+Iif( pl_plisrq, "P", "D")+"'", "viewDefName")
		IF USED("viewDefName")			
		   	GO TOP 
		   	leadfirmName=ALLTRIM(AttyFirm)
		   	leadFileNo=ALLTRIM(fileno)
		   	leadDefendantName=ALLTRIM(DefendantName)  
		   	leadRole=ALLTRIM(attyrole) 
		   	leadAtty=ALLTRIM(rqAttyCode)
		   	leadBarNo=ALLTRIM(BarNo)
		   	leadNameInv=ALLTRIM(NameInv)
		   	leadAdd1=ALLTRIM(add1)
		   	leadAdd2=ALLTRIM(add2)
		   	leadAddcsz=ALLTRIM(Addcsz)
		   	leadPhone=ALLTRIM(Phone)
		   	leadFax=ALLTRIM(Fax)
		   	leadrequestDate=CTOD(reqDate)
		   	leadSendDate=CTOD(sendDate) && 01/29/2021 MD#211402
		   	leadInfoText=GFADDCR(ALLTRIM(infoText))  &&--07/14/2021 MD
		Endif	
		oMED.closealias("viewDefName")
		ldtxn11 = gfChkDat( fOrigIss(Iif(pl_Reissue, pn_Suppto,N_TAG)), .F., .F.)
		Do PrintField With mv, "InfoText", leadInfoText &&--07/14/2021 MD
		Do PrintField With mv, "FirmName", leadfirmName
		Do PrintField With mv, "subDefName", leadDefendantName
		Do PrintField With mv, "ClientRep", Alltrim(pc_amgr_nm)
		Do PrintField With mv, "Role", leadRole
		Do PrintField With mv, "RequestDate", ldtxn11
		Do PrintField With mv, "Issueday", DAY(leadrequestDate)
		Do PrintField With mv, "Issuemonth", CMONTH(leadrequestDate)
		Do PrintField With mv, "Issueyear", YEAR(leadrequestDate)
		Do PrintField With mv, "Sendday", DAY(leadSendDate) && 01/29/2021 MD#211402
		Do PrintField With mv, "Sendmonth", CMONTH(leadSendDate)
		Do PrintField With mv, "Sendyear", YEAR(leadSendDate)
		Do PrintField With mv, "Fileno", leadFileNo
		Do PrintField With mv, "RTTag",ALLTRIM(STR(pn_lrsno))+"."+ALLTRIM(STR(N_TAG))
		
		Do PrintGroup With mv, "Atty"
		Do PrintField With mv, "Name_inv", leadNameInv
		Do PrintField With mv, "Ata1", leadAdd1
		Do PrintField With mv, "Ata2", leadAdd2
		Do PrintField With mv, "Atacsz", leadAddcsz
		Do PrintField With mv, "Phone", leadPhone
		Do PrintField With mv, "FaxNo", leadFax
		Do PrintField With mv, "BarNo", leadBarNo
		*--- 10/06/2020 MD #196821
		*-- DO PRINTFIELD WITH MV, "AKA",ALLTRIM(NVL(pc_maiden1,'')) -- 07/08/2021 MD
		DO PRINTFIELD WITH MV, "AKA",IIF(LEN(alltrim(NVL(pc_maiden1,"")))>0,"AKA: "+alltrim(NVL(pc_maiden1,"")),"")		
	ELSE 
	
		DO PRINTFIELD WITH MV, "AKA",ALLTRIM(NVL(pc_maiden1,''))
		DO PRINTGROUP WITH MV, "Case"
		DO PRINTFIELD WITH MV, "Case", " "

		DO PRTCASES IN SUBP_CA WITH PC_RQATCOD

		DO PRINTGROUP WITH MV, "Control"
		DO PRINTFIELD WITH MV, "Date",  ""
		DO PRINTFIELD WITH MV, "LrsNo", PC_LRSNO
		DO PRINTFIELD WITH MV, "Tag", ALLTRIM( STR( N_TAG))

	ENDIF 
	** --- 02/03/2021 MD #222873 ----------------------------------- 
	IF plCourtIn=.T. 
		oMED.closealias("viewNoticeAttyList")
		SELECT 0
		oMED.sqlexecute("exec dbo.NoticeAttyList '" + fixquote(pc_clcode)+ "'", "viewNoticeAttyList")
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
		
		oMED.closealias("viewNoticeAttyList")
	ENDIF 
	** --- 02/03/2021 MD #222873 ----------------------------------- 
	** --- 08/07/2020 MD #170629 ----------------------------------- 
ENDIF && if not scanned "R" found print a regular one

RETURN
