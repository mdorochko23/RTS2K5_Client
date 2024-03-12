PROCEDURE CAPOSPage
	**08/24/10 EF -Oakland office move
	**7/20/09  EF - start.
	** Print Proof of service of notice for both 'Plaintiff' and 'Defendant'
	** Called from CA_Notice,  Subp_PA, also calls itself recursively in special situations

	PARAMETERS nTag, llHS, llNotice, llDefOnly, ldControl, lcPOSType
	* nTag: Tag number of deponent being noticed
	* llHS: .T. for hand-serve; .F. for US Mail
	* llNotice: .T. if "LOCATION: <deponent>" field is to be printed
	* llDefOnly: .T. if notices go only to defense attorneys
	* ldControl: Date to be printed on notice
	* lcPOSType: "PLAINTIFF"/"DEFENSE"
	PRIVATE dbInit, dbTAAtty, mPhone, dbTABills, nCount, nLoop, ;
		lcAt_Code, arAtty, lcString1, lcString2, lnDefCnt, llRepeat
	PRIVATE c_detail1, c_detail2, c_detail3, c_NotcType, c_defend, c_Atty
	PRIVATE omedPos as Object
	c_Atty=""
	dbInit = SELECT()
	omedPos= CREATEOBJECT("medtimesheet")
	WAIT WINDOW "Printing Proof of Service of Notice " +  IIF(lcPOSType="P", " Plaintiff's copy", "Defense Copy") NOWAIT NOCLEAR 
	_SCREEN.MOUSEPOINTER=11
	IF NOT TYPE( "ldControl") = "D"
		*gfmessage("Problem...")
		ldControl=convertToDate(ldControl)

	ENDIF
	*-- 02/10/2021 MD #224406 added check for WCAB
	IF LEFT(ALLTRIM(UPPER(pc_court1)), 4) = "WCAB" and pl_ofcoaK 
		DO WCABProof IN subp_ca WITH nTag, llHS, llNotice, llDefOnly, ldControl
		RETURN
	ENDIF 
	llRepeat = .F.	
	c_defend = ""	
	SELECT 0
	l_GotDefName=omedPos.sqlexecute("SELECT dbo.fn_GetDef_Name('" + fixquote(pc_rqatcod) + "')", "DefName")
	IF NOT l_GotDefName
		gfmessage(" Cannot get a defendant. Contact IT.")
	ELSE
		c_defend=ALLTRIM(DefName.EXP)
	ENDIF

	IF NOT USED( "Subpoena")		
		USE (f_subpoena) IN 0 ORDER CLTAG
	ENDIF
	SELECT Subpoena	
	llDefault = .T.
	lFormExt = .F.
	c_NotcType = " "
	IF SEEK( pc_clcode + STR( nTag))
		llDefault = .F.
		lFormExt = Subpoena.Extra
		c_NotcType = Subpoena.TYPE	
	ENDIF

	_SCREEN.MOUSEPOINTER=0
	IF llDefault		
		*DO PrintGroup WITH mv, "CAPosNotice"
		DO PrintGroup WITH mv, "CAPos" + lcPOSType
		 * -------------------------------------------------------
    	&& 11/25/2019 MD #186387  
		LOCAL ldefendantName
		ldefendantName=""		
		oMedPos.closealias("viewDefName")
		SELECT 0
		oMedPos.sqlexecute("exec dbo.AttyDefName '" + fixquote(pc_clcode)+ "', '"+Iif( pl_plisrq, "P", "D")+"'", "viewDefName")
		IF USED("viewDefName")
			 ldefendantName=ALLTRIM(viewDefName.defendantName)		 	
		ENDIF
		 			
		Do PrintField With mv, "DefendantName", ldefendantName  
		&& 11/25/2019 MD #186387 
	ELSE
		DO CASE
			CASE c_NotcType = "P"
				DO PrintGroup WITH mv, "CAPosNoticeDepPers"
				DO PrintField WITH mv, "FormExtra", ;
					IIF( lFormExt, "(and production of Documents and Things)", "")
				DO PrintField WITH mv, "FormExtra2", ;
					IIF( lFormExt, ;
					"including Notice to Consumer pursuant to CCP 1985.3/" + ;
					"Notice to Employee pursuant to 1985.6 (if applicable)", "")

			CASE c_NotcType = "C"
				DO PrintGroup WITH mv, "CAPosNoticeCivil"
				DO PrintField WITH mv, "FormExtra", ;
					IIF( lFormExt, ;
					"(Duces Tecum and supporting affidavit if applicable), " + ;
					"including Notice to Consumer pursuant to CCP 1985.3/" + ;
					"Notice to Employee pursuant to 1985.6 (if applicable)", "")
				
		ENDCASE
	ENDIF
	IF INLIST(ALLTRIM(UPPER(lcPOSType)),"D","P")
		** -- 08/11/2020 MD #186945
		oMedPos.closealias("AtBarNo")
		oMedPos.sqlexecute("SELECT dbo.fn_AttyBarNum('" + pc_rqatcod+ "')", "AtBarNo")
		SELECT AtBarNo
		GO top
		lc_BarNum=ALLTRIM(AtBarNo.exp)
		DO PrintField WITH mv, "BarNo" ,  lc_BarNum
		oMedPos.closealias("AtBarNo")
    ENDIF 		
	DO PrintField WITH mv, "Loc", pc_offcode
	DO PrintField WITH mv, "How", IIF( llHS, "H", "N")
	DO PrintField WITH mv, "ByMail", IIF( llHS, " ", "BY MAIL ")

	lcPara = ""
	IF NOT llHS
		IF pl_OfcPas THEN			
			c_detail1 = "Walnut Professional Building, 711 E Walnut St, Suite 201"
			c_detail2 = "Pasadena CA  91101"
			c_detail3 = "Pasadena"
		ELSE		
			c_detail1 = "130 Webster Street, Suite 100"
			c_detail2 = "Oakland, CA  94607"
			c_detail3 = "Oakland"
		ENDIF
		lcPara = "and, following ordinary business practice at " + c_detail1 + ", " + ;
			c_detail2 + " for collection and processing of correspondence for mailing " + ;
			"with the United States Postal Service, caused said documents to be mailed the same day" + ;
			" in the United States Post Office at " + c_detail3 + ", California." + CHR(13)
	ENDIF
	DO PrintField WITH mv, "Para", IIF(lcPOSType="D", "", lcPara)

**8/10/09 added getcaSigner/GetCADeliv
	IF EMPTY( pc_MailNam)		
		pc_MailNam=getcaSigner(ldControl,pc_offcode)
	ENDIF
	IF EMPTY( pc_ServNam)		
		pc_ServNam=GetCADeliv(pc_offcode,ldControl,pc_clcode)
	ENDIF
	
	DO PrintField WITH mv, "MailPers", IIF( llHS AND lcPOSType="P" , pc_ServNam, pc_MailNam)

	DO PrintGroup WITH mv, "Deponent"
	
    IF TYPE("pc_MailID")!='C'
       pc_MailID=""
    ENDIF      
     IF TYPE("mdep")!='C'
    	mdep=CANOTICE.DESCRIPT
    ENDIF  
   
                IF LEFT( ALLT(pc_MailID), 1)=="D" AND !EMPTY(ALLTRIM(pc_MailID))
					c_drname=gfdrformat(mdep)
					c_dep = IIF(NOT "DR."$c_drname,"DR. "+ALLTRIM(c_drname),c_drname)
				ELSE		
				    c_dep = ALLTRIM(mdep)
				ENDIF
	
	DO PrintField WITH mv, "Name", IIF( llNotice, " ", "LOCATION: " + C_Dep)

	DO PrintGroup WITH mv, "Control"
	DO PrintField WITH mv, "Date", DTOC( ldControl)	

	DO PrintGroup WITH mv, "Atty"
	DO PrintAty IN SUBP_CA WITH pc_rqatcod

	
		l_Tabill=gettabill(pc_clcode)
		IF NOT l_Tabill
			gfmessage("Cannot get TAbills file")
			RETURN
		ENDIF
		
	
	SELECT tabills
	
	nCount = 0
	
		* Build array of participating  attorneys
		SELECT CODE, At_Code FROM tabills  INTO ARRAY arAtty ;
			WHERE tabills.cl_Code = pc_clcode ;
			AND tabills.At_Code <> pc_rqatcod ;
			AND tabills.CODE = lcPOSType ;
			AND INLIST( tabills.Response, "T", "S") ;
			AND NOT tabills.NoNotice
	
	gnCount = _TALLY

	_SCREEN.MOUSEPOINTER=0

	
IF gnCount =0
= gfmsg( "No Participating Attys..  Make a note.")
ENDIF

	IF gnCount > 0
		= ASORT( arAtty, 1, -1, 1)

		nCount = ALEN( arAtty) / 2
		FOR nLoop = 1 TO ROUND( nCount/2, 0)
			DO PrintGroup WITH mv, "Item"
			lcString1 = " "
			lcString2 = " "

			lcAt_Code = arAtty[ nLoop*2-1, 2]			
			lcString1=getstring1(lcAt_Code)

			*     Prepare column 2 data, if any
			IF (nLoop < ROUND( nCount/2, 0)) OR MOD( nCount, 2) = 0
				lcAt_Code = arAtty[ nLoop*2, 2]				
				lcString2=getstring2(lcAt_Code)
			ENDIF

			DO PrintField WITH mv, "Col1", lcString1
			DO PrintField WITH mv, "Col2", lcString2
		ENDFOR

	ENDIF
	

	DO PrtCourt IN SUBP_CA WITH .T.	
	DO PrintGroup WITH mv, "Case"
	DO PrintField WITH mv, "Def_name", ;
		IIF( pl_PSGWC, ", " + ALLTRIM(DefName.EXP), "")
	DO PrtCases IN SUBP_CA WITH pc_rqatcod

	
	IF TYPE ( "l_FaxAllow")= "U"
		IF TYPE ( "l_Fax1Req")= "U" OR TYPE ( "l_PrtFax")= "U"
			l_Fax1Req=.F.
			l_PrtFax =.F.
		ENDIF
		l_FaxAllow = (pl_1st_Req AND (l_Fax1Req OR l_PrtFax))
		l_Fax2Req=.F.

	ENDIF

	
	IF pc_offcode="C" AND 	lcPOSType="D"	AND pl_CANotc
		pc_defNotfax =pc_AtyFax
		IF l_FaxAllow AND  NOT l_Fax2Req
			c_fax = STRTRAN( szfaxnum, " ", "")
			c_temp = STRTRAN( c_fax, "-", "")
			c_temp2 = STRTRAN( c_temp, "(", "")
			szfaxnum = STRTRAN( c_temp2, ")", "")
		ENDIF
	ELSE
	
		*l_Fax2Req=.F.

	ENDIF
	
**Fax codef 
IF ALLTRIM(lcPOSType)=="D" AND pl_CANotc
	IF NOT EMPTY( mv) AND LEN(pc_defNotfax)=10
		mclass="FaxCodef"
		DO prtenqa WITH mv, mclass, mgroup,  IIF( l_Fax2Req, ALLTRIM( szfaxnum), "")
	ENDIF
endif
	SELECT (dbInit)
	RELEASE omedPos
	WAIT CLEAR

	RETURN
********************************************************************************************************************
***7/28/06 get string functions: add fax#
FUNCTION getstring1
	PARAMETERS lcAt_Code
	PRIVATE c_Atty AS STRING, lcString  AS STRING
	lcString=""
	_SCREEN.MOUSEPOINTER=11
	c_Atty=fixquote(lcAt_Code)
	*--- 06/07/2021 MD per email add atty email
	lcAttyEmail=""
	oMedPos.closealias("viewPosPageE")
	SELECT 0
	oMedPos.sqlexecute("select dbo.getAttyEmailList2('"+ALLTRIM(c_Atty)+"',9)", "viewPosPageE")
	IF USED("viewPosPageE")
		lcAttyEmail=LOWER(ALLTRIM(NVL(viewPosPageE.exp,"")))
		oMedPos.closealias("viewPosPageE")
	ENDIF 	
	*--- 06/07/2021 MD 	 
	pl_GetAt = .F.
	DO gfatinfo WITH c_Atty, "M"	

	lcString = ALLTRIM(pc_AtyFirm) + CHR(13) + ;
		IIF( NOT EMPTY( pc_AtySIGN), "ATTN: " + pc_AtySIGN + CHR(13), "") +  ;
		IIF( NOT EMPTY( pc_Aty1Ad), ALLTRIM( pc_Aty1Ad) + CHR(13), "") + ;
		IIF( NOT EMPTY( pc_Aty2Ad), ALLTRIM( pc_Aty2Ad) + CHR(13), "") + ;
		pc_Atycsz  + CHR(13)+;
		IIF(LEN(ALLTRIM(NVL(pc_AtyFax,"")))>0,ALLTRIM(pc_AtyFax)+ CHR(13),"")+;
		IIF(LEN(ALLTRIM(lcAttyEmail))>0,ALLTRIM(lcAttyEmail)+CHR(13),"")

	_SCREEN.MOUSEPOINTER=0
	RETURN     lcString
	************************************************************************************
FUNCTION getstring2
	PARAMETERS lcAt_Code

	PRIVATE c_Atty AS STRING, lcString2  AS STRING, lcAttyEmail
	lcString=""	
	_SCREEN.MOUSEPOINTER=11
	c_Atty=fixquote(lcAt_Code)
	*--- 06/07/2021 MD  per email add atty email
	lcAttyEmail=""
	oMedPos.closealias("viewPosPageE")
	SELECT 0
	oMedPos.sqlexecute("select dbo.getAttyEmailList2('"+ALLTRIM(c_Atty)+"',9)", "viewPosPageE")
	IF USED("viewPosPageE")
		lcAttyEmail=LOWER(ALLTRIM(NVL(viewPosPageE.exp,"")))
		oMedPos.closealias("viewPosPageE")
	ENDIF 
	*--- 06/07/2021 MD 	 
	pl_GetAt = .F.
	DO gfatinfo WITH c_Atty, "M"
	lcString = ALLTRIM(pc_AtyFirm) + CHR(13) + ;
		IIF(NOT EMPTY(pc_AtySIGN), "ATTN: " + pc_AtySIGN  + CHR(13),"")  +;
		IIF(NOT EMPTY(pc_Aty1Ad), ALLTRIM(pc_Aty1Ad) + CHR(13), "") + ;
		IIF(NOT EMPTY(pc_Aty2Ad), ALLTRIM(pc_Aty2Ad) + CHR(13), "") + ;
		pc_Atycsz  + CHR(13) + ;
		IIF(LEN(ALLTRIM(NVL(pc_AtyFax,"")))>0,ALLTRIM(pc_AtyFax)+ CHR(13),"")+;
		IIF(LEN(ALLTRIM(lcAttyEmail))>0,ALLTRIM(lcAttyEmail)+CHR(13),"")

	_SCREEN.MOUSEPOINTER=0
	RETURN lcString