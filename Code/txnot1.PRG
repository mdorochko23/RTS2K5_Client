Procedure txnot1
******************************************************************************
**11/28/2017:  Judicial vs. County court  #70136
**09/25/2017: skip is "S" scanned subp file exists
**08/16/2017: added Reissue
**08/08/2017 : removed attys list - replaced with 'All Parties of Record'/ Added pc_Suffix
**05/30/2017: Texas Notice of Intention to take deposition by written question
******************************************************************************
Parameters n_Tag, c_mdep, c_mid, reducted

Private c_nameinv, c_nameinvp, c_ratadd1, c_ratadd1p,  c_clcode,  c_cty, ;
	c_ratadd2, c_ratadd2p, c_ratcszP, c_ratcsz, c_date1, c_roloname, c_sign
LOCAL lcTXAmended
dbInit = Alias()
_Screen.MousePointer=11

**09/25/2017: skip is "S" scanned subp file exists
If TxSFile (n_Tag, "S")
	_Screen.MousePointer=0
	Return
Endif
**09/25/2017: skip is "S" scanned subp file exists

ots = Createobject("medtimesheet")

If Not Used( "Tabills")
	l_Tabill=gettabill(pc_clcode)
	If Not l_Tabill
		gfmessage("Cannot get TAbills file.")
		Return
	Endif
Endif
Set Procedure To ta_lib Additive
c_clcode= fixquote(pc_clcode)

If  Used('Record')
	Select Record
	Use
Endif

ots.sqlexecute(" exec dbo.GetRequestRecordbyClcodeTag '" + c_clcode + "','" + Str(n_tag) + "' ", "Record")


Select Record
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

**10/31/2017: #70884 Skip Holidays for TX issues : GFCHKDAT
c_date1=GFCHKDAT (Ctod(Left(Dtoc(Record.REQ_Date),10)),.F.,.F.)
c_datedue=Ctod(Left(Dtoc(Record.REQDUEDATE),10))
If Type("dep_date")="U"
	dep_date=c_datedue&&Timesheet.DUE_DATE
Endif

** 10/19/2017  : #71549 Old TX Reissue and Follow-ups  of Old tags do not use any programmed pages- Use scanned only
If  SkipTxDocs (PN_LRSNO, N_TAG )
	Return
Endif
** 10/19/2017  : Old TX Reissue and Follow-ups  of Old - do not use programmed pages- Use scanned only
d_DueDate= GetReqDueDate(c_clcode, n_tag, Iif(Type("dep_date")="T", Ttod(dep_date),dep_date))

lc_BarNum=Nvl(pc_BarNo,"")
c_cty=fixquote(Nvl(pc_c1Cnty,''))
c_charday=num2word(pn_c1Cmply)
*-------------------------------------------------------------------
*Do PrintGroup With mv, "TXNot1"
*Do PrintGroup With mv, "2_TXNot"
*-------------------------------------------------------------------
*--10/25/2022 #277503 call different TX form based on the request date
docID=2
ots.closealias("viewTxDocCode")
SELECT 0
ots.sqlexecute("exec dbo.TXDoc2Use 'N','" + fixquote(c_clcode)+ "', "+ALLTRIM(STR(n_tag)), "TXDoc2Use")
IF USED("TXDoc2Use")			
	GO top
	docID=TXDoc2Use.docCode		
ENDIF 
IF docID=2
	Do PrintGroup With mv, "2_TXNot"
else
	Do PrintGroup With mv, "3_TXNot"
ENDIF 
*--10/25/2022

*#255675 WY 12/21/2021 Support TX Header user selection
PRIVATE pcTxHeaderMode
pcTxHeaderMode = GetTxHeaderStyle(PN_LRSNO, N_TAG)


Do PrintField With mv, "Loc", "P"
Do PrintField With mv, "RequestDate", Dtoc(c_date1)
Do PrintField With mv, "PRequestDate", Dtoc(c_date1)
Do PrintField With mv, "DepDate", d_DueDate
Do PrintField With mv, "BarNo", lc_BarNum
Do PrintField With mv, "CharDays", c_charday + " (" + Alltrim(Str(pn_c1Cmply )) + ")"
Do PrintField With mv, "AttyType", Iif( pl_plisrq, "P", "D")
*DO PrintField WITH mv, "CrtType", ALLTRIM(pc_txCrtType)
*DO PrintField WITH mv, "County", UPPER(c_cty)
*DO PrintField WITH mv, "Suffix", pc_Suffix
**11/28/2017  Judicial vs. County court
mv_cap2=""
mv_cap2= txcourtcap()

If Empty(mv_cap2)
	Wait Window 'Error in court caption.'
	Return
Endif
mv=mv+mv_cap2
**11/28/2017  Judicial vs. County court

Do pDepInfo  In subp_pa With c_mid, Proper( c_mdep), .F.

Store "" To c_nameinv, c_nameinvp, c_ratadd1p, c_ratadd2p, c_ratcszP, c_phone,  c_Firm,  ;
	c_AttyInfo, c_ratadd1, c_ratadd2, c_ratcsz, c_Pltcap, c_AtName, c_EmailAdd, c_AtyFax

If Not Empty( pc_rqatcod)
	pl_GetAt = .F.
*DO gfatinfo WITH fixquote(pc_rqatcod), "M"
	Do AtyMixed With fixquote(pc_rqatcod), "M", .T.
	c_AtName = pc_AtyName
	c_nameinv = pc_AtySign
	c_ratadd1 = pc_Aty1Ad
	c_ratadd2 = pc_Aty2Ad
	c_ratcsz = pc_Atycsz
	c_phone = pc_AtyPhn
	c_Firm = pc_Atyfirm
	c_AtyFax=pc_AtyFax
	c_EmailAdd= TxRqemail(0,pc_rqatcod)
Endif


Do PrintGroup With mv, "Atty"
Do PrintField With mv, "Name_inv", c_nameinv
Do PrintField With mv, "Ata1", c_ratadd1 + Iif(Empty(c_ratadd2),"",", " + c_ratadd2)
Do PrintField With mv, "Ata2", "" &&c_ratadd2
Do PrintField With mv, "Atacsz", c_ratcsz
Do PrintField With mv, "Phone", c_phone
Do PrintField With mv, "Ata3", 	c_Firm
Do PrintField With mv, "Attn", c_EmailAdd
Do PrintField With mv, "FaxNo", c_AtyFax

lc_ddata=""
lc_ddata= TXNotDep(c_mid, Proper( c_mdep), n_Tag)

Do PrintGroup With mv, "Item"
Do PrintField With mv, "Tag", "TO: All Parties of Record" 	+ Chr(10) + lc_ddata
Do PrintField With mv, "Name", ""
Do PrintField With mv, "InfoText",""


Do PrintGroup With mv, "Case"
*255675 WY 12/21/2021 Support TX Header user selection
*Do PrintField With mv, "Plaintiff", pc_plcaptn
Do PrintField With mv, "Plaintiff", PrintFieldIntercept("Plaintiff", pc_plcaptn)

*255675 WY 12/21/2021 Support TX Header user selection
*Do PrintField With mv, "Defendant", pc_dfcaptn
Do PrintField With mv, "Defendant", PrintFieldIntercept("Defendant", pc_dfcaptn)

Do PrintField With mv, "Docket", pc_docket
Do PrintField With mv, "AttyType", Iif( pl_plisrq, "P", "D")
If Type('pd_pldob')<>"C"
	pd_pldob=Dtoc(pd_pldob)
Endif

Do PrintField With mv, "AttyName", Alltrim(c_nameinv)
Do PrintField With mv, "BirthDate", pd_pldob
Do PrintField With mv, "SSN", pc_plssn
Do PrintField With mv, "Term", pd_term
** Judicial vs. County court # 70136
Do PrintField With mv, "Dist", "" &&UPPER(ALLT( pc_distrct))
Do PrintField With mv, "Area", "" &&UPPER(c_cty)
*06/13/2018 MD #71930
    Do PrintField With mv, "Amended",lcTXAmended



** ---  01/29/2021 MD #222170 

LOCAL inDefendantName
STORE "" TO inDefendantName	
ots.closealias("viewDefName")
SELECT 0
ots.sqlexecute("exec dbo.AttyDefInfo '" + fixquote(c_clcode)+ "', "+ALLTRIM(convertToChar(n_Tag,1))+", '"+Iif( pl_plisrq, "P", "D")+"'", "viewDefName")
IF USED("viewDefName")			
	GO TOP 		   
	inDefendantName=ALLTRIM(DefendantName) 		   
Endif	
ots.closealias("viewDefName")
Do PrintField With mv, "DefendantName", inDefendantName	

*255675 WY 12/21/2021 notice title change
LOCAL lcDwq, llHaveDwq
lcDwq = GetTxDWQ(PC_CLCODE, n_Tag)
llHaveDwq = IIF(LEN(ALLTRIM(lcDwq)) > 0 and ALLTRIM(lcDwq) <> "!", .T., .F.)
Do PrintField With mv, "NoticeTitle", GetTxNoticeTitle(llHaveDwq)	
*Do PrintField With mv, "NoticeText", GetNoticeText(llHaveDwq, d_DueDate, c_mid, c_mdep)
*-- 06/27/2022 MD  #277503
localRT=pn_lrsno
localTag=N_TAG
Do PrintField With mv, "NoticeText", GetNoticeTextSP(localRT,localTag, d_DueDate, c_mid,reducted)

*255675 WY 12/21/2021 Support TX Header user selection
CreateTxHeader()

** ---  01/29/2021 MD #222170 
_Screen.MousePointer=11
Select ( dbInit)
Release ots
Wait Clear

Return
*************************************************************************
*************************************************************************
Function num2word
*************************************************************************
	Parameters nDay
	Local cDay As String
	c_alias=Alias()
	ots.closealias ("GetDays")
	cDay=""
	C_STR ="SELECT dbo.num2Words (" + Str(nDay) + ")"
	l_gotReq=ots.sqlexecute(C_STR,"GetDays")

	If Used("GetDays")
		cDay=Nvl(GetDays.Exp,'')
	Endif
	If !Empty(c_alias)
		Select (c_alias)
	Endif
	Return Alltrim(cDay)
ENDFUNC 
*************************************************************************
*************************************************************************
Function TXNotDep
* Print Deponent Information as apart of the Atty's info block on the Texas Notice page (txnot1)
*07/27/2017
*************************************************************************
	Parameters MID, MDEP, NTG
	Private C_ROLONAME, L_ROLOUSED, C_OLDFILE, OMEDGEN, L_GOT11LINE


	C_OLDFILE = Select()

	If Empty(Alltrim(MID)) And !Empty(Alltrim(PC_MAILID))
		MID=Alltrim(PC_MAILID)
	Endif


	OMEDGEN = Createobject("generic.medgeneric")
	L_GOT11LINE=.F.
	OMEDGEN.SQLEXECUTE(" select [dbo].[GetTxn11Description] ('" + FIXQUOTE(PC_CLCODE)+ "','" +Str(NTG ) +"')","Desc11")
	If Not Empty(Nvl(DESC11.Exp,''))
		L_GOT11LINE=.T.
	Endif

	If Type('pc_deptype')<>"C"
		If Not Isdigit( Left( Allt( MID), 1))
			PC_DEPTYPE = Left( Allt( MID), 1)
		Else
			PC_DEPTYPE = "D"
		Endif
	Endif

	If (L_GOT11LINE And PC_DEPTYPE = "H" )
		C_DEPTYPE=DEPTBYDESC(DESC11.Exp)
	Else
		C_DEPTYPE="Z"
	Endif
	**08/25/17: Mixed Case Letters for a grid on the Notice page
	L_MAIL=DepoData(MID,C_DEPTYPE,.T.)
	*L_MAIL=OMEDGEN.SQLEXECUTE("exec dbo.GetDepInfoByMailIdDept '" + MID+"','" + C_DEPTYPE + "' ", "pc_DepoFile")
	=CursorSetProp("KeyFieldList", "Code, id_tbldeponents", "pc_DepoFile")


	Select PC_DEPOFILE
	If Eof()

		Wait Window " No deponent data is available. Note the case and tag number (" + Alltrim(PC_LRSNO) + "." + Alltrim(Str(NTG) ) + ") and contact IT dept. Thank you."

	Endif
	Release OMEDGEN

	C_RETVAL=""

	C_ADDITION= GETDESCRIPT(C_DEPTYPE)


	C_DEP=DEPTOPRINT (Alltrim(Nvl(PC_DEPOFILE.Name,Proper(MDEP))))

	If Len( Alltrim(PC_DEPOFILE.ADD1))+Len(Alltrim(PC_DEPOFILE.ADD2))>=60
	** break into two lines for long address 08/07/2017
	**09/12/2017 - REMOVED PROPER FROM  C_DEP
		C_RETVAL=Space(7) + C_DEP+ Iif(PC_DEPTYPE = "H"  ,"",C_ADDITION) + Chr(10) + Space(12) +  ;
			" Custodian of Records, " + Alltrim(PC_DEPOFILE.ADD1)+ ", " + Alltrim(PC_DEPOFILE.ADD2) + ;
			IIF (Empty(Alltrim(PC_DEPOFILE.ADD2) ) ,"",", ")+  Chr(10) + Space(13) +  ;
			ALLTRIM(PC_DEPOFILE.CITY)+ ", " + Upper(Alltrim(PC_DEPOFILE.STATE)) +   " "+ Iif(Alltrim(PC_DEPOFILE.ZIP)='00000','', Alltrim(PC_DEPOFILE.ZIP))

	Else


		C_RETVAL=Space(7) + C_DEP+ Iif(PC_DEPTYPE = "H"  ,"",C_ADDITION) + Chr(10) + Space(14) +  ;
			" Custodian of Records, " +  Alltrim(PC_DEPOFILE.ADD1)+ ", " +Alltrim(PC_DEPOFILE.ADD2) +  ;
			IIF (Empty(Alltrim(PC_DEPOFILE.ADD2) ) ,"",", ") + ;
			ALLTRIM(PC_DEPOFILE.CITY)+ ", " + Upper(Alltrim(PC_DEPOFILE.STATE)) +   " "+ Iif(Alltrim(PC_DEPOFILE.ZIP)='00000','', Alltrim(PC_DEPOFILE.ZIP))
	Endif

	** AS 8/25/17 : BEFORE PROPER CASES IN AN ADDRESS
	*!*	IF LEN( ALLTRIM(PC_DEPOFILE.ADD1))+LEN(ALLTRIM(PC_DEPOFILE.ADD2))>=60
	*!*	** break into two lines for long address 08/07/2017

	*!*	C_RETVAL=SPACE(7) + PROPER(C_DEP) + IIF(PC_DEPTYPE = "H"  ,"",C_ADDITION) + CHR(10) + SPACE(12) +  ;
	*!*	" Custodian of Records, " +  PROPER(ALLTRIM(PC_DEPOFILE.ADD1))+ ", " + PROPER(ALLTRIM(PC_DEPOFILE.ADD2) )+ ;
	*!*	IIF (EMPTY(ALLTRIM(PC_DEPOFILE.ADD2) ) ,"",", ")+  CHR(10) + SPACE(13) +  ;
	*!*	PROPER( ALLTRIM(PC_DEPOFILE.CITY)) + ", " + UPPER(ALLTRIM(PC_DEPOFILE.STATE)) +   " "+ IIF(ALLTRIM(PC_DEPOFILE.ZIP)='00000','', ALLTRIM(PC_DEPOFILE.ZIP))

	*!*	ELSE


	*!*	C_RETVAL=SPACE(7) + PROPER(C_DEP) + IIF(PC_DEPTYPE = "H"  ,"",C_ADDITION) + CHR(10) + SPACE(14) +  ;
	*!*	" Custodian of Records, " +  PROPER(ALLTRIM(PC_DEPOFILE.ADD1))+ ", " + PROPER(ALLTRIM(PC_DEPOFILE.ADD2) )+  ;
	*!*	 IIF (EMPTY(ALLTRIM(PC_DEPOFILE.ADD2) ) ,"",", ") + ;
	*!*	PROPER( ALLTRIM(PC_DEPOFILE.CITY)) + ", " + UPPER(ALLTRIM(PC_DEPOFILE.STATE)) +   " "+ IIF(ALLTRIM(PC_DEPOFILE.ZIP)='00000','', ALLTRIM(PC_DEPOFILE.ZIP))
	*!*	ENDIF



	*!*	IF LEN( ALLTRIM(PC_DEPOFILE.ADD1))+LEN(ALLTRIM(PC_DEPOFILE.ADD2))>=60
	*!*	** break into two lines for long address 08/07/2017

	*!*	C_RETVAL=PROPER(C_DEP) + IIF(PC_DEPTYPE = "H"  ,"",C_ADDITION) + CHR(10) + SPACE(8) +  ;
	*!*	" Custodian of Records, " +  PROPER(ALLTRIM(PC_DEPOFILE.ADD1))+ ", " + PROPER(ALLTRIM(PC_DEPOFILE.ADD2) )+ ;
	*!*	IIF (EMPTY(ALLTRIM(PC_DEPOFILE.ADD2) ) ,"",", ")+  CHR(10) + SPACE(9) +  ;
	*!*	PROPER( ALLTRIM(PC_DEPOFILE.CITY)) + ", " + ALLTRIM(PC_DEPOFILE.STATE) +   " "+ IIF(ALLTRIM(PC_DEPOFILE.ZIP)='00000','', ALLTRIM(PC_DEPOFILE.ZIP))

	*!*	ELSE


	*!*	C_RETVAL=PROPER(C_DEP) + IIF(PC_DEPTYPE = "H"  ,"",C_ADDITION) + CHR(10) + SPACE(10) +  ;
	*!*	" Custodian of Records, " +  PROPER(ALLTRIM(PC_DEPOFILE.ADD1))+ ", " + PROPER(ALLTRIM(PC_DEPOFILE.ADD2) )+  ;
	*!*	 IIF (EMPTY(ALLTRIM(PC_DEPOFILE.ADD2) ) ,"",", ") + ;
	*!*	PROPER( ALLTRIM(PC_DEPOFILE.CITY)) + ", " + ALLTRIM(PC_DEPOFILE.STATE) +   " "+ IIF(ALLTRIM(PC_DEPOFILE.ZIP)='00000','', ALLTRIM(PC_DEPOFILE.ZIP))
	*!*	ENDIF

	Select ( C_OLDFILE)
	Return C_RETVAL
ENDFUNC 


*#255675 WY 12/21/2021 Support notice title change based on DWQ
FUNCTION GetTxNoticeTitle(tlHaveDWQ as Boolean) as String
	IF tlHaveDWQ 
		RETURN "NOTICE OF SUBPOENA AND DEPOSITION BY WRITTEN QUESTIONS OF"
	else
		RETURN "NOTICE OF INTENTION TO SUBPOENA"
	ENDIF 
ENDFUNC 

*#255675 WY 12/21/2021 Support notice text change based on DWQ
FUNCTION GetNoticeText (tlHaveDWQ as Boolean, tcDueDate as Datetime, tcMid as string, tcDepName as string) as String
	LOCAL lcDepName, lcReturn 
	lcDepName = BuildTxDepName(tcMid, tcDepName)
	IF tlHaveDWQ 		
		lcReturn = "the attached Deposition by Written Questions will be taken of the " + ;
					"Custodian of records for " + lcDepName + " before a Notary Public.  " + ;
					"In addition, the attached subpoena for Deposition by Written Questions " + ;
					"is being served on the Custodian of Records for " + lcDepName + ". " + ;
					"The requested documents and Deposition by Written Questions are " + ;
					"to be used in the above cause as evidence."
	ELSE
		*-- 04/07/2022 MD #254899
		*lcReturn = "to produce and permit copying and inspection of the documents " + ;
					"identified in the attached rider on " + tcDueDate && [DepDate] is tcDueDate	 
		lcReturn ="the attached subpoena and rider will be served upon "+ lcDepName +".  "+ ;
					"The requested documents are to be  used in the above cause for evidence."
	ENDIF 
	RETURN lcReturn
ENDFUNC 
FUNCTION GetNoticeTextSP (tclrs as Integer, tctag as Integer, tcDueDate as Datetime, tcMid as string,tcreducted ) as String
*-- 06/27/2022 MD  #277503
retval=""
lcSQLLine="exec dbo.TXNoticeText "+ALLTRIM(STR(tclrs))+", "+ALLTRIM(STR(tctag))+",'"+ALLTRIM(tcMid)+"',"+;
IIF(tcreducted=.T.,"1","0")+",'"+convertToChar(tcDueDate)+"'"
ots.sqlexecute(lcSQLLine,"viewTXNoticeText")
SELECT viewTXNoticeText
IF RECCOUNT()>0
	retval=ALLTRIM(viewTXNoticeText.text1)+CHR(13)+CHR(10)+ALLTRIM(viewTXNoticeText.text2)
ENDIF
RETURN retval	
ENDFUNC 
*#255675  Support notice text change based on DWQ
FUNCTION BuildTxDepName (tcMid as String, tcDepName as String) as String
	LOCAL lcDepType, lcNameAdditional

	lcDepType = left(alltrim(tcMid), 1)
	lcNameAdditional = ""
	if lcDepType = "H"
		lcNameAdditional = GetDescript(lcDepType)
		RETURN Upper(tcDepName) + " " + lcNameAdditional 
	ELSE
		RETURN Upper(tcDepName)
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