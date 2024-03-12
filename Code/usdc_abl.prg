PROCEDURE usdc_abl
*--- 08/10/2018 MD #98879
Parameters ccrtSUB,ccrtSUB2,  creqType, ccounty, mdep
Local lcselect As String
LOCAL c_cl, n_tg, mRLeadAttyName,mRLeadAttyFirm, mRLeadAttyEmail,mDefendantName, mRAttyCode, mRLeadAdd1, mRLeadAdd2, mRLeadCity, mRLeadPhone, DeponentName, DeponentCity, DeponentAddr
lcselect =Alias()
Local oGen As Object
oGen = Createobject("medgeneric")

c_cl=pc_clcode
n_tg=pn_tag

*--- Master Info -----------
mdefendant = Allt(pc_dfcaptn)
szPltName = pc_plcaptn
mRDocket = ALLTRIM(pc_docket)
mRDiv= ALLTRIM(pc_divisn)
ldtxn11 = gfChkDat( fOrigIss(Iif(pl_Reissue, pn_Suppto,n_tg)), .F., .F.)
c_court=""
nlen= Len(Alltrim(pc_c1Desc))
c_court=Right( Alltrim(pc_c1Desc), nlen-7)
If Type('pd_pldob')<>"C"
	pd_pldob=Dtoc(pd_pldob)
ENDIF

*----Request Info ----------
If Type("mdate")<>"D"
	mdate = gfChkDat( fOrigIss( n_tg), .F., .F.)
Endif
mdate= mdate

If Type( "ldDueDate") = "D" Or Type( "ldDueDate") = "T"
	If (Dtoc(ldDueDate))<>"  /  /    "
		dep_date = ldDueDate
	Endif
Endif
pd_DueDate= GetReqDueDate(c_cl, n_tg, Iif(Type("dep_date")="T", Ttod(dep_date),dep_date))	
*--- Spec Ins -------------
If Type('szEdtReq')="U"
	If Used("Spec_ins")
		Select Spec_ins
		Use
	Endif
	oGen.sqlexecute("Exec [dbo].[GetTheLatestBlurb] '" + fixquote(pc_clcode) + "',' " + Str(n_tg) + "'", "Spec_ins")
	szEdtReq=gfAddCR( Spec_ins.spec_inst)
Endif
If Empty( Alltrim(szEdtReq))
	szEdtReq = gfAddCR( szrequest)
ENDIF

*--- deponent Info ----
STORE "" TO mRDepName, mRDepAddr, mRDepCity
oGen.closealias("viewDepABL")
oGen.sqlexecute("exec dbo.getABLDepInfo '"+ALLTRIM(c_cl)+"', "+ALLTRIM(convertToChar(n_tg,1)),"viewDepABL")
SELECT viewDepABL
IF RECCOUNT()>0
   GO top
   DeponentName=ALLTRIM(name)
   DeponentAddr=ALLTRIM(address)
   DeponentCity=ALLTRIM(city)
Endif	

*---- Atty Info -------
STORE "" TO mRLeadAttyName, mRLeadAttyFirm, mRLeadAttyEmail, mRDefendantName, mRDepAddr, mRDepCity, mRAttyCode
oGen.closealias("viewDepABL")
oGen.sqlexecute("exec dbo.getABLAttyInfo '"+ALLTRIM(c_cl)+"', "+ALLTRIM(convertToChar(n_tg,1)),"viewAttyABL")
SELECT viewAttyABL
IF RECCOUNT()>0
   GO TOP 
   mRLeadAttyName=ALLTRIM(AttyName)
   mRLeadAttyFirm=ALLTRIM(AttyFirm)
   mRLeadAttyEmail=ALLTRIM(email)
   mDefendantName=ALLTRIM(DefendantName)
   mRAttyCode=ALLTRIM(attyCode)
Endif	
oGen.closealias("viewDepABL")
oGen.closealias("viewAttyABL")
oGen.sqlexecute("exec dbo.getAttyInfoByAtCodeAndAddType '"+ALLTRIM(mRAttyCode)+"', 'M'","viewAttyABL")
SELECT viewAttyABL
IF RECCOUNT()>0
    GO top
   	mRLeadAdd1=add1
	mRLeadAdd2=add2
	mRLeadCity=ALLTRIM(NVL(city,''))+", "+ALLTRIM(NVL(state,''))+" "+ALLTRIM(NVL(zip,''))
	mRLeadPhone=ALLTRIM(NVL(phone,''))
	IF LEN(ALLTRIM(mRLeadPhone))<10
	   mRLeadPhone=""
	ELSE
	  mRLeadPhone="("+LEFT(ALLTRIM(mRLeadPhone),3)+")"+SUBSTR(ALLTRIM(mRLeadPhone),4,3)+"-"+RIGHT(ALLTRIM(mRLeadPhone),4)
    ENDIF 	   
ENDIF  
oGen.closealias("viewAttyABL")  
*--  Check if the scanned subpoena exisits. Print programmed one onle if there is no scanned docs.
IF findScannedSubp(n_tg)=.F.
	*----------------------------------------------------------------------------------------------
	*----  Page ------
	IF pl_1st_Req=.T. AND pl_reissue=.F.
	    mclass="ABLFstSubp"
    ENDIF 
	Do PrintGroup With mv, "SubpoenaABL1" 

	Do PrintGroup With mv, "Case"
	Do PrintField With mv, "Plaintiff", szPltName
	Do PrintField With mv, "Defendant", mdefendant
	Do PrintField With mv, "Docket", mRDocket
	Do PrintField With mv, "Area", c_court
	Do PrintField With mv, "FullName",  pc_plnam
	Do PrintField With mv, "FirmName", mRLeadAttyFirm
	Do PrintField With mv, "AttyName", mRLeadAttyName


	Do PrintField With mv, "Loc", IIF(pl_ofcMD Or pl_ofcPgh, "P", pc_Offcode)

	Do PrintField With mv, "DeponentName", DeponentName
	Do PrintField With mv, "DeponentAddr", DeponentAddr
	Do PrintField With mv, "DeponentCity", DeponentCity
    Do PrintField With mv, "RequestDate",  Dtoc(ldtxn11)

	Do PrintField With mv, "DefendantName", mDefendantName

	Do PrintGroup With mv, "Atty"
	Do PrintField With mv, "Ata1", mRLeadAdd1
	Do PrintField With mv, "Ata2", mRLeadAdd2
	Do PrintField With mv, "Atacsz", mRLeadCity
	Do PrintField With mv, "Phone", mRLeadPhone	
	Do PrintField With mv, "Attyemail", mRLeadAttyEmail
	Do PrintField With mv, "Division", mRDiv 
	*----------------------------------------------------------------------------------------------
ENDIF 
* ---- Additional Pages ----
If pl_kopVer =.T. And Not bNotcall
** DO NOT PARINT THAT PAGE WITH  NOTICES
	Do PrintGroup With mv, "SubpoenaABL2"
	** ---11/05/2018 MD# 115503
	Do PrintField With mv, "DeponentName", DeponentName
	Do PrintField With mv, "Division", mRDiv 
	Do PrintField With mv, "Docket", mRDocket
	Do PrintField With mv, "RTTag",ALLTRIM(Str(pn_lrsno))+"."+ALLTRIM(Str( pn_tag))
	** ---
	Do PrintGroup With mv, "SubpoenaABL3"
ENDIF

Local c_riderpcx As String
c_riderpcx=""
c_riderpcx=SUBRIDERPCX	(n_tg,"R",1 )
If !Empty(Alltrim(c_riderpcx))
	ntag= pn_tag
	Do pspecdoc In subp_pa With 'R'

Else
	Do PrintGroup With mv, "ExhibitUSDC"	
	Do PrintField With mv, "InfoText",  Strtran( Strtran( szEdtReq, Chr(13), " "), Chr(10), "")
	Do PrintField With mv, "CaseplCap", szPltName
	Do PrintField With mv, "CasedefCap", mdefendant
	Do PrintField With mv, "CaseDocket", mRDocket
	Do PrintField With mv, "ControlLrsNo", Str(pn_lrsno)
	Do PrintField With mv, "ControlTag" , Str( pn_tag)
	Do PrintField With mv, "Deponent" , mdep
	lc_RecPertain=""
	lc_RecPertain = pc_plnam + "  DOB: " +  Left(pd_pldob,10) +  "  SSN: " + Alltrim( pc_plssn)
	Do PrintField With mv, "Pertain" , lc_RecPertain

Endif   



Release oGen
If Not Empty(lcselect)
	Select (lcselect)
Endif
Return
*-------------------------------------------------------------------------------------------------------------------------
FUNCTION findScannedSubp
PARAMETERS printTag
LOCAL wasPrinted, TagExt
IF TYPE("printTag")="N"
	TagExt=PADL(ALLTRIM(STR(printTag)),3,"0")
ELSE 
   	TagExt=PADL(ALLTRIM(printTag),3,"0")
ENDIF    	
WAIT WINDOW  "Checking/Printing Scanned Subpoenas.." nowait
WasPrinted=.F.
WasPrinted=printTag("G","*.TIF",WasPrinted)
IF WasPrinted=.F.
	WasPrinted=printTag("G","*."+ALLTRIM(TagExt),WasPrinted)
ENDIF 	
RETURN WasPrinted
*------------------------------------------------
PROCEDURE printTag
LPARAMETERS docType, docExt,printed
LOCAL lcDest, lcSource, lcPCXArch, lcPCX,lcPCXPath, lcPCXArchpath
LOCAL  lnII, lnFiles1,lnFiles2
IF USED("tempDoc")
   USE IN tempDoc
ENDIF    
IF USED("tempDoc2")
   USE IN tempDoc2
ENDIF    

* in case same docs in both folders select filenames in the temp table and get unuque names
SELECT 0 
CREATE CURSOR tempDoc (fileName c(200))
lcPCXPath=ADDBS(ALLTRIM(IIF(pl_ofcOak,goApp.capcx, goApp.pcxpath)))
lcPCX =lcPCXPath + ALLTRIM(pc_lrsno) + ALLTRIM(docType)+ALLTRIM(docExt)
lnFiles1=ADIR(la1, lcPCX)
FOR lnII=1 TO lnFiles1
        SELECT tempDoc
        APPEND BLANK 
        replace filename WITH la1[lnII,1]
NEXT
lcPCXArchpath=ADDBS(ALLTRIM(IIF(pl_ofcOak,goApp.capcxArch, goApp.pcxarchpath)))
lcPCXArch =lcPCXArchpath + RIGHT(ALLTRIM(pc_lrsno),1) + "\"+  ALLTRIM(pc_lrsno) + ALLTRIM(docType)+ALLTRIM(docExt)
lnFiles2=ADIR(la2, lcPCXArch)
FOR lnII=1 TO lnFiles2
        SELECT tempDoc
        APPEND BLANK 
        replace filename WITH la2[lnII,1]
NEXT 
SELECT DISTINCT filename FROM tempDoc INTO CURSOR tempDoc2 WHERE !EMPTY(ALLTRIM(filename)) ORDER BY filename 
* Once the list of unique names is selected loop through the list and send them to RPS
SELECT tempDoc2
SCAN
	lcSource =lcPCXPath +  ALLTRIM(tempDoc2.filename)
	lcDest   =lcPCXArchpath + RIGHT(ALLTRIM(pc_lrsno),1) + "\"+ALLTRIM(tempDoc2.filename)	
	DO SEND_PG IN SUBP_PA WITH lcSource, lcDest 
	printed=.T.
ENDSCAN
IF USED("tempDoc")
   USE IN tempDoc
ENDIF    
IF USED("tempDoc2")
   USE IN tempDoc2
ENDIF   
RETURN printed
