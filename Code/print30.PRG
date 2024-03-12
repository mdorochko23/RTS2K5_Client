* --------------------------------------------------------------------------
* Print Status Letter to Counsel
* 07/21/16 MD: added addGenAutho2 and addAutho2 to process Tiff documents only.  The PDF documents will be processed by RPS #42693
* 03/11/09 EF: fixing problem with non-characters in the body of an STC. (infoTEXT)
* 04/14/08 EF: Added AM Fax #.
* 11/13/07 EF: Added civil Lit STCs
* 04/27/07 EF: Added SRU dept.
* 12/27/06 EF: print Sheri's STCs in Texas
* --------------------------------------------------------------------------
*PROCEDURE lfPrint30
PARAMETER llAtty, llRqAtty, llPlAtty, lcAtCode, lcid_tblCode30, lcClCode, llPrintAutho, lcPageList, lcGenAutho, llPrintOnly, id_stc       
PRIVATE lcLtr, lcTmp, lnAddr, lcAlias, lcProc, lcArea, c_info, lcQueue,laAddr, laEnv, lnAddr
DIMENSION laAddr[5], laEnv[1,3]
STORE "" TO lcQueue, lcLtr ,lcTmp
lcAlias = ALIAS()
gnRPS=0
lcTmpAl = lcAlias
STORE SPACE(1) TO laAddr
IF PARAMETERS()<10
   llPrintOnly=.F.
ENDIF 



IF PARAMETERS()<11
   id_stc=''
ENDIF 



STORE .F. TO  pl_UpdHoldReqst , PL_SKIPBATCHPRT, PL_PRTORIGSUBP, PL_NOTICNG

lcUser= IIF(!EMPTY(ALLTRIM(goApp.currentuser.orec.Dept)), ;
ALLTRIM(goApp.currentuser.orec.Dept) + "/" +  LEFT( goApp.currentuser.orec.Name_First, 1) + ;
LEFT( goApp.currentuser.orec.Name_Last, 1), "UNKNOWN")

IF opendata()=.F.
   RETURN 
ENDIF    
SELECT viewAttyA
*IF llAtty
	lnAddr = 0
	IF NOT EMPTY(NewLast+newfirst)
		lnAddr = lnAddr + 1
		laAddr(lnAddr) = ALLTRIM(ALLTRIM(newfirst) + " " + ;
		IIF(EMPTY(NewInit), "", NewInit + ".")) + " " + ALLTRIM(NewLast)
	ENDIF
	IF NOT EMPTY(Printable_firm)
		lnAddr = lnAddr + 1
		laAddr[lnAddr] = Printable_firm
	ENDIF
	IF NOT EMPTY(Add1)
		lnAddr = lnAddr + 1
		laAddr[lnAddr] = Add1
	ENDIF
	IF NOT EMPTY(Add2)
		lnAddr = lnAddr + 1
		laAddr[lnAddr] = Add2
	ENDIF
	IF NOT EMPTY(City)
		lnAddr = lnAddr + 1
		laAddr[lnAddr] = ALLTRIM(City) + " " + State + "  " + Zip
	ENDIF
*ENDIF

**11/13/2007 ADDED A SPECIAL TEXT TO CIVIL LIT STCS

lc_CCList=""
IF pc_litcode="C  "
	IF llAtty AND pc_rqatcod= viewAttyA.AT_CODE
		lc_CCList="A COPY OF THIS DOCUMENT HAS BEEN PROVIDED TO ALL COUNSEL IN THIS CASE"
	ELSE
		IF (llRqAtty AND llPlAtty) AND pc_rqatcod= viewAttyA.AT_CODE
			lc_CCList= "A COPY OF THIS DOCUMENT HAS BEEN PROVIDED TO PLAINTIFF'S COUNSEL IN THIS CASE"  + CHR(13)
		ENDIF
	ENDIF

ENDIF

SELECT (lcAlias)

SET PROCEDURE TO GLOBAL ADDITIVE

SELECT viewAttyA
IF EMPTY(Fax_no) 
	lcFaxNo = "-"
ELSE
	lcFaxNo = gfPhoneToChar(Fax_no) &&(AtFax)
ENDIF



SELECT viewCode30A


DO PrintGroup WITH lcLtr, ;
IIF( viewCode30A.Item_1, "Status1FLetter", "Status1Letter")
*---------------------------------------------------------------------------
*EF 11/4/99 added for case info
* DMA 08/28/02 Code updated to use public vbls
*     pl_nogroup is True unless case is Ohio Asbestos in KoP AND there is
*                        actual group info in CaseInfo file
*----------------------------------------------------------------------------
*--- 04/04/2019 MD #128894
*!*	IF pl_KoPVer
*!*		mv = lcLtr
*!*		DO gfPrtGrp
*!*		lcLtr = mv
*!*	ENDIF
*----------------------------------------------------------------------------
**4/14/08 -added AM Fax Number form civil lit cases only -start
 IF  pl_KOPVer
	c_FaxCode="P"	
	IF ALLTRIM(pc_litcode) ="C"
		l_AMFaxCode= GetAMFaxCode (pc_amgr_id)
		IF l_AMFaxCode
			c_FaxCode=IIF(ISNULL(AMFax.RpsAMFaxCode) or EMPTY(AMFax.RpsAMFaxCode), 'P', AMFax.RpsAMFaxCode)			
		ENDIF
		
	ENDIF
ELSE
c_FaxCode=pc_offcode
ENDIF

**4/14/08 -added AM Fax Number form civil lit cases only-end


DO printfield WITH lcLtr, "Loc", ;
IIF( INLIST( pc_offcode, "G"), "P", c_FaxCode)

IF pl_KoPVer	
	SELECT( lcTmpAl)
	IF NOT EMPTY(viewBillA.file_no)
		DO printfield WITH lcLtr, "FileNo", ;
		"Your File #:" + ALLTRIM(viewBillA.file_no)
	ELSE
		DO printfield WITH lcLtr, "FileNo", ""
	ENDIF
	SELECT (lcAlias)
ENDIF
DO printfield WITH lcLtr, "RequestDate", viewCode30A.txn_date

DO PrintGroup WITH lcLtr, "Plaintiff"
* 05/25/04 DMA Switch to long plaintiff name
DO printfield WITH lcLtr, "FirstName", ALLTRIM(pc_plnam)
DO printfield WITH lcLtr, "MidInitial", ""
DO printfield WITH lcLtr, "LastName",  ""

DO PrintGroup WITH lcLtr, "Atty"
IF pl_CAVer	
    IF EMPTY(ALLTRIM(NVL(viewCode30A.attention,"")))
	   SELECT viewCode30A
	   lcSAttn = NVL(viewCode30A.attention,"")
	   lcSEmail= NVL(viewCode30A.email,"")
	   oFrm=CREATEOBJECT("casedeponent.frmGetSTCAttention",lcSAttn,lcSEmail, lcAtCode)
	   oFrm.SHOW
	   lcSAttn=ALLTRIM(ofrm.txtAttention.VALUE)
	   lcSEmail=ALLTRIM(ofrm.cboEmail.value)
	   RELEASE oFrm
       LOCAL oGenMed AS medGeneric OF generic
	   oGenMed=CREATEOBJECT("medGeneric")
	   lcSQLLine="update tblCode30 set attention='"+ALLTRIM(lcSAttn)+"', email='"+alltrim(upper(lcSEmail))+"'"+;
	   " where id_tblCode30='"+viewCode30A.id_tblCode30+"'"
	   oGenMed.sqlexecute(lcSQLline)
	   RELEASE oGenMed
	ELSE 
	   lcSAttn=alltrim(viewCode30A.attention)	   
	ENDIF    
	DO printfield WITH lcLtr, "Name_inv", ALLTRIM(lcSAttn)
	
ELSE
	DO printfield WITH lcLtr, "Name_inv", laAddr[1]
ENDIF 
DO printfield WITH lcLtr, "Ata1", laAddr[2]
DO printfield WITH lcLtr, "Ata2", laAddr[3]
DO printfield WITH lcLtr, "Ata3", laAddr[4]
DO printfield WITH lcLtr, "Atacsz", laAddr[5]
DO printfield WITH lcLtr, "FaxNo", ;
IIF( LEN( lcFaxNo) < 10, "", "Fax #: " + lcFaxNo)

* 06/18/03 Use new-format RCA Number via global variables
***
IF NOT pl_BBCase
	STORE "" TO pc_BBRound, pc_BBWebNo, pc_BBLocNo, pc_BBNuRCA
ELSE
	pc_BBRound = viewRequestA.ASB_Round
	pc_BBWebNo = viewRequestA.Web_Order
	pc_BBLocNo = viewRequestA.BB_Locator
	pc_BBNuRCA = pc_plbbASB + "." + pc_BBRound
ENDIF
***



DO printfield WITH lcLtr, "LrsNo", pc_lrsno + ;
IIF( pl_BBAsb, " ASB #:" + pc_BBNuRCA, "")
DO printfield WITH lcLtr, "TagNo", ALLTRIM(STR(viewCode30A.TAG))
DO printfield WITH lcLtr, "DepName", ALLTRIM(viewCode30A.DESCRIPT)

lcTmp = ALLTRIM( pc_plcaptn)

IF NOT EMPTY( pc_dfcaptn)
	lcTmp = lcTmp + "   VS   " + ALLTRIM( pc_dfcaptn)
ENDIF
DO printfield WITH lcLtr, "PltName", lcTmp
&&EF 09/16/2002 Select Code30 record for reprints
SELECT viewCode30A
lcTmp = ""
IF viewCode30A.Item_1
	lcTmp = lcTmp + "The above-named deponent requires a fee approval "
	lcTmp = lcTmp + "in the amount of $" + TRANSFORM(fee_amt, "9999.99")
	lcTmp = lcTmp + " for " + LOWER(ALLTRIM(page_cnt))
	lcTmp = lcTmp + pc_eol + pc_eol
ENDIF
IF viewCode30A.item_2
	lcTmp = lcTmp + "The above-named deponent requires the dates of service "
	lcTmp = lcTmp + LOWER(ALLTRIM(TYPE))
	lcTmp = lcTmp + " before they can research for the requested material."
	lcTmp = lcTmp + pc_eol + pc_eol
ENDIF
** DMA  05/05/03  Add HIPAA-compliant Authorization option to Code30 file
IF viewCode30A.item_3 OR viewCode30A.item_4 OR viewCode30A.HIPAA_Auth OR viewCode30A.nrsfrec
	DO CASE
		CASE viewCode30A.item_3
			lcTmp = lcTmp + "An Authorization:" + pc_eol
		CASE viewCode30A.item_4
			lcTmp = lcTmp + "A Subpoena:" + pc_eol
		CASE viewCode30A.HIPAA_Auth
			lcTmp = lcTmp + "A HIPAA-Compliant Authorization:" + pc_eol
	ENDCASE
	c_info = ""

** Make sure only one Eol character per line for proper spacing.
	IF NOT EMPTY(viewCode30A.comm1)
		c_info = STRTRAN(STRTRAN(ALLTRIM(viewCode30A.comm1), CHR(13)), CHR(10)) + pc_eol
	ENDIF
	IF NOT EMPTY(viewCode30A.comm2)
		c_info = c_info + STRTRAN(STRTRAN(ALLTRIM(viewCode30A.comm2), CHR(13)), CHR(10)) + pc_eol
	ENDIF
	IF NOT EMPTY(viewCode30A.comm3)
		c_info = c_info + STRTRAN(STRTRAN(ALLTRIM(viewCode30A.comm3), CHR(13)), CHR(10)) + pc_eol
	ENDIF
	IF NOT EMPTY(viewCode30A.comm4)
		c_info = c_info + STRTRAN(STRTRAN(ALLTRIM(viewCode30A.comm4), CHR(13)), CHR(10)) + pc_eol
	ENDIF
	IF NOT EMPTY(viewCode30A.comm5)
		c_info = c_info + STRTRAN(STRTRAN(ALLTRIM(viewCode30A.comm5), CHR(13)), CHR(10)) + pc_eol
	ENDIF
	IF NOT EMPTY(viewCode30A.comm6)
		c_info = c_info + STRTRAN(STRTRAN(ALLTRIM(viewCode30A.comm6), CHR(13)), CHR(10)) + pc_eol
	ENDIF
	IF NOT EMPTY(viewCode30A.comm7)
		c_info = c_info + STRTRAN(STRTRAN(ALLTRIM(viewCode30A.comm7), CHR(13)), CHR(10)) + pc_eol
	ENDIF
	c_info = ALLT(c_info)
	lcTmp = lcTmp + c_info + pc_eol + pc_eol
ENDIF
IF viewCode30A.item_5
	SET MEMOWIDTH TO 70
	FOR x = 1 TO MEMLINES(viewCode30A.OTHER)
		lcTmp = lcTmp + MLINE(OTHER, x) + pc_eol
	NEXT x
ENDIF

IF !EMPTY(ALLTRIM(NVL(viewCode30A.stctype,""))) AND RIGHT(ALLTRIM(NVL(viewCode30A.stctype,"")),2)<>'XX'
	lcTmp=""
	SET MEMOWIDTH TO 70
	FOR x = 1 TO MEMLINES(viewCode30A.OTHER)
		lcTmp = lcTmp + MLINE(OTHER, x) + pc_eol
	NEXT x
ENDIF 

IF EMPTY(lcTmp)
	lcTmp = " "
ENDIF
**03/11/09- fixing problem with non-characters in the body of an STC.
*DO printfield WITH lcLtr, "InfoItem", lcTmp
DO printfield WITH lcLtr, "InfoText", lcTmp

lcTmp = "If RecordTrak does not receive a response to our requests "
lcTmp = lcTmp + "within one month from date above, we will "
lcTmp = lcTmp + "terminate all efforts in the procurement of this "
lcTmp = lcTmp + "record for the above-named deponent."

DO printfield WITH lcLtr, "EndTxt", lcTmp

&& -- print account manager name and phone ---
lcPhone = pc_amgr_ph
IF EMPTY(lcPhone)
	lcPhone = "1-800-" + ;
	IIF( pc_litcode == "C  ", "686-0658", "220-1291")
ENDIF
* 07/18/2019 MD #138221
IF ALLTRIM(UPPER(NVL(master.acct_mgr,"")))=="CLIENT SERVICES"
	lcPhone=ALLTRIM(lcPhone)+" Prompt 2"
ENDIF 
*--
DO PrintGroup WITH lcLtr, "Contact"
DO printfield WITH lcLtr, "Name", IIF( NOT EMPTY(pc_amgr_nm), ;
pc_amgr_nm, "RecordTrak Representative")
DO printfield WITH lcLtr, "Phone", lcPhone

** 03/23/04 IZ added user initials and department after CcTxt
DO printfield WITH lcLtr, "CcTxt", ;
IIF( pc_litcode == "I  ", "cc: Defense Counsel"+CHR(13)+lcUser, lcUser) + CHR(13)+ IIF( !EMPTY(lc_CCList), CHR(13)+lc_CCList, "")
****11/09/07 -added CC atty

** end IZ

* 05/05/03 DMA Eliminate E1, E2, E3 litigations per CBroach request
lcArea = IIF( INLIST( pc_litcode, "D  ", "E  ", "G  "), ;
"Area: " + ALLTRIM(pc_area), "  ")

IF pl_KoPVer
	DO PrintGroup WITH lcLtr, "Case"
	DO printfield WITH lcLtr, "Area", lcArea
ENDIF


*--5/23/02 kdl start: Set TX 2nd print queue flag to true
**04/14/2010 -removed as not being used
*!*	IF pl_OfcHous
*!*		pl_2ndQue = .T.
*!*	ENDIF
*--5/23/02 kdl end:

** 11/24/03 IZ if it is MD/Summarized and Asbestos, assign to the RPS7 (print only in Maryland)

IF pl_MdSumAsb
	gnRPS = 7
ENDIF

lcFaxNo=STRTRAN(lcFaxNo,"-","") 
&&04/29/14 - EXCLUDE ALL BAD FAX NUMBERS &&LEFT(ALLTRIM(lcFaxNo),3)="111" 
IF LEN( lcFaxNo) < 10 OR INLIST(ALLTRIM(lcFaxNo),'1111111111','2222222222','3333333333','4444444444','5555555555','6666666666','7777777777','8888888888','9999999999','0000000000')
   lcFaxNo=""
ENDIF 


	
**EF 06/06/05 - added "RPS9" for the RTU STC Letters
**EF 12/21/04 - change print destination based on user's department
pl_StopPrtIss=.F.
IF ISNULL(pc_userdpt)=.T. OR TYPE("pc_userdpt")!="C"
	pc_userdpt=GOAPP.currentuser.orec.PC_USERDPT
ENDIF
IF TYPE("pc_EmailAdd")<>"C"
   pc_EmailAdd=""
ENDIF  
DO CASE
    CASE !EMPTY(ALLTRIM(pc_EmailAdd)) AND !EMPTY(ALLTRIM(lcFaxNo)) AND llPrintOnly=.F.
         lcQueue = "emailSTCFax"
    CASE !EMPTY(ALLTRIM(pc_EmailAdd)) AND EMPTY(ALLTRIM(lcFaxNo)) AND llPrintOnly=.F.
         lcQueue = "emailSTC"
    CASE !EMPTY(ALLTRIM(lcFaxNo)) AND llPrintOnly=.F.
    &&09/30/14- do not fax to below numebr per Alec/James as new fax server cannot handel it- email instead to the civilcases inbox
      IF ALLTRIM(lcFaxNo)='6109921405' 
    	  	 lcQueue = "emailSTC"
    	 	 pc_EmailAdd="CivilCases@recordtrak.com"
    	 	 lcFaxNo=""
      ELSE  
    
         lcQueue = "STC30fax"
        ENDIF 
	CASE INLIST(pc_userdpt,"SRU")
		lcQueue = "SRUCode30"
	CASE INLIST(pc_userdpt, "RCU","DSU")
		lcQueue = "Code30"
	CASE INLIST(pc_userdpt, "RTU","ASU","RTURUSH","DPU")
		lcQueue = "Rps9"
	CASE INLIST(pc_userdpt, "SALES")
**12/27/06 EF: print Sheri's STCs in Texas
		lcQueue = "TXCode30"
	OTHERWISE
		lcQueue = "AMCode30"
ENDCASE


IF PC_LITCODE ='ZOL' 
 c_declivery=""
   oGenMed=CREATEOBJECT("medGeneric")
   oGenMed.closealias('STcShip')
  lcSQLLine="select dbo.STCDeliveryType ('" + id_stc      + "')"
  oGenMed.sqlexecute(lcSQLline, "StcShip")
  IF USED("StcShip")
  	c_declivery =ALLTRIM(StcShip.exp)    
  ENDIF  
  RELEASE oGenMed
  IF c_declivery ="P" AND lcQueue = "STC30fax"
	lcQueue = 'Rps5STC'
	lcFaxNo=''
ENDif
ENDIF 




**EF 10/25/04 - added a new print queue class
**EF 01/22/07 -start: display a printer selecton screen for the Pasadena's cases+ Oakland(2/6/07)
IF INLIST(pc_offcode,'S','C')
*IF NOT pl_KoPVer
	IF gnRPS = 0
		DO RPS
		lcQueue='Rps' + ALLTRIM(STR(gnRPS))+"_STC" 
	ENDIF
ENDIF
***1/22/07- end

IF llPrintAutho=.T.
   IF checktest("PRINT30")=.T.
   	  lcLtr=addAutho(lcLtr)
   ELSE 
      lcLtr=addAutho2(lcLtr)   
   ENDIF          
ENDIF
IF LEN(ALLTRIM(lcPageList))>0
   lcLtr=addDocs(lcLtr, lcPageList)
ENDIF 
IF LEN(ALLTRIM(lcGenAutho))>0
	IF checktest("PRINT30")=.T.
       lcLtr=addGenAutho(lcLtr, lcGenAutho)
    ELSE 
       lcLtr=addGenAutho2(lcLtr, lcGenAutho)
    ENDIF 
ENDIF 

  * DO PrintEnq IN GLOBAL WITH lcLtr, lcQueue, "1", viewCode30A.cl_code, viewCode30A.TAG, ALLTRIM(pc_userid)
 pc_clcode=viewCode30A.cl_code
 pn_tag=viewCode30A.TAG
do prtEnq_2 IN GLOBAL WITH lcLtr, lcQueue, "1", lcFaxNo,viewCode30A.cl_code, viewCode30A.TAG, ALLTRIM(pc_userid), id_stc
mv=""
IF NOT EMPTY(lcAlias)	
	SELECT (lcAlias)
ENDIF
RETURN

*-----------------------------------------------------------------------------
FUNCTION opendata
LOCAL lcSQLLine
LOCAL oGen AS medGeneric OF generic
oGen=CREATEOBJECT("medGeneric")
**07/18/2011- ADDED STORED PROC INSTEAD OF SQL STATEMENTS
SELECT 0
lcSQLLine=" exec dbo.GetCode30byUniqueId '"+ALLTRIM(lcid_tblCode30)+"'"	
*lcSQLLine="select * from  tblCode30 where id_tblCode30='"+ALLTRIM(lcid_tblCode30)+"'"		
llRetval=oGen.sqlexecute(lcSQLline,"viewCode30A")
IF RECCOUNT("viewCode30A")=0   
   gfmessage("Can't open tblCode30")       
   RETURN .F.
ENDIF     

SELECT 0
IF USED("master")
   USE IN master
ENDIF    
lcSQLLine="select * from tblMaster with (nolock) where cl_code='"+ALLTRIM(fixquote(lcClCode))+"' and active=1"		
llRetval=oGen.sqlexecute(lcSQLline,"Master")
IF RECCOUNT("Master")=0
   gfmessage("Can't open tblMaster")       
   RETURN .F.
ENDIF     
pl_GotCase=.F.
DO gfGetCas WITH .F.

SELECT 0
lcSQLLine="exec dbo.GetAttyAddressByAtCodeAndAddType '" + ALLTRIM(lcAtCode) + "','M'"	
llRetval=oGen.sqlexecute(lcSQLline,"viewAttyA")
IF RECCOUNT("viewAttyA")=0
   gfmessage("Can't open tblAttorney")       
   RETURN .F.
ENDIF    

SELECT 0
lcSQLLine=" exec dbo.GetRequestRecordbyClcodeTag '"+ALLTRIM(pc_clcode)+"',"+ALLTRIM(STR(viewCode30A.Tag))
*lcSQLLine="select * from tblRequest with (nolock) where cl_code='"+ALLTRIM(pc_clcode)+"' and tag='"+;
ALLTRIM(STR(viewCode30A.Tag))+"' and active=1"
oGen.sqlexecute(lcSQLLine,"viewRequestA")
IF RECCOUNT("viewRequestA")=0
   gfmessage("Can't open tblRequest")       
   RETURN .F.
ENDIF  

SELECT 0
lcSQLLine=" EXEC [dbo].[GetBillsByClCodeAtCode] '"+ALLTRIM(fixquote(lcClCode))+"','"+ ALLTRIM(lcAtCode)+"'"
*lcSQLLine="select * from tblBill where cl_code='"+ALLTRIM(fixquote(lcClCode))+"' and at_code='"+ALLTRIM(lcAtCode)+"' and active=1"		
oGen.sqlexecute(lcSQLline,"viewBillA")
IF RECCOUNT("viewBillA")=0
   gfmessage("Can't open tblBill")       
   RETURN .F.
ENDIF  

SELECT 0
lcSQLLine="select dbo.getSTCAuthoLink('"+ALLTRIM(lcClCode)+"', "+ALLTRIM(STR(viewCode30A.Tag))+")"
oGen.sqlexecute(lcSQLLine,"viewAuthoLinkA")
IF RECCOUNT("viewAuthoLinkA")=0
   gfmessage("Can't open AuthoLink")       
   RETURN .F.
ENDIF  

SELECT 0
*lcSQLLine="select * from tblGenAutho where active=1"
lcSQLLine="exec [dbo].[ListGenAutho] "
oGen.sqlexecute(lcSQLLine,"viewGenAuthoA")
IF RECCOUNT("viewGenAuthoA")=0
   gfmessage("Can't open GenAutho")       
   RETURN .F.
ENDIF  
SELECT viewGenAuthoA
INDEX ON ALLTRIM(UPPER(fileCode)) TAG fileCode
set ORDER to fileCode

RELEASE oGen 
RETURN .T.
*-----------------------------------------------------------------------------
FUNCTION addAutho
LPARAMETERS lcLtr
LOCAL lcFileName, lcAuthoPath, lcInAuthoFile, lcOutAuthoFile, lcOutAuthoFileTiff, lcCurDir
LOCAL lcRetPDf2Tiff
IF !EMPTY(ALLTRIM(NVL(viewAuthoLinkA.exp,"")))
   lcFileName=STRTRAN(ALLTRIM(viewRequestA.mailid_no)," ","_")
   lcInAuthoFile='"'+ALLTRIM(viewAuthoLinkA.exp)+'"'
   lcAuthoPath=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","AUTHOPATH", "\")))
   lcOutAuthoFile=ADDBS(ALLTRIM(lcAuthoPath))+ALLTRIM(lcFileName)+IIF(".PDF"$ALLTRIM(UPPER(viewAuthoLinkA.exp)),".pdf",".tif")
   lcOutAuthoFileTiff=ADDBS(ALLTRIM(lcAuthoPath))+ALLTRIM(lcFileName)+".tif" 
   IF FILE(lcOutAuthoFile)
      DELETE FILE &lcOutAuthoFile
   ENDIF    
   IF FILE(lcInAuthoFile)
      COPY FILE &lcInAuthoFile TO &lcOutAuthoFile
	   IF ".PDF"$ALLTRIM(UPPER(lcOutAuthoFile)) 
	      lcRetPDf2Tiff=""
		  lcRetPDf2Tiff=checkFileLoc()
		  IF EMPTY(ALLTRIM(lcRetPDF2Tiff))
		     RETURN lcLtr
		  ENDIF 		     
	      WAIT WINDOW "Converting PDF to TIFF. Please wait...." NOWAIT NOCLEAR
	      lcCurDir=SYS(5)+SYS(2003)        
	      lcInFile="c:\temp\"+ALLTRIM(lcFileName)+".pdf"
	      lcOutFile="c:\temp\"+ALLTRIM(lcFileName)+".tif"
	      IF FILE(lcInFile)
	         DELETE FILE &lcInFile
	      ENDIF 
	      IF FILE(lcOutFile)
	         DELETE FILE &lcOutFile
	      ENDIF 
	      COPY FILE &lcOutAuthoFile TO &lcInFile
	      SET DEFAULT TO &lcRetPDF2Tiff	      
	      lcLine="RUN Pdf2Img.exe  -m -i "+ALLTRIM(lcInFile)+" -r 200x200 -c g4 -b 1 -o "+(ALLTRIM(lcOutFile))
	      &lcLine
	      SET DEFAULT TO &lcCurDir
	      IF FILE(lcOutAuthoFileTiff)
	        DELETE FILE &lcOutAuthoFileTiff
	      ENDIF    
	      COPY FILE &lcOutFile TO &lcOutAuthoFileTiff
	      WAIT CLEAR 
	   ENDIF 
	   DO PrintGroup WITH lcLtr, "STCAuth"     
	   DO PrintField WITH lcLtr, "Id", lcOutAuthoFileTiff
   ENDIF 
endif   
RETURN lcLtr

*-----------------------------------------------------------------------------------------------------------------
FUNCTION addDocs
LPARAMETERS lcLtr, lcPageList
LOCAL lcFileName, lcCurDir, lnLRS, lcRogPath, lnII, lcPage, lcChar, lcLrsNo
lcLrsNo=pn_lrsno
*lcRogPath=getRogsPath(lcLrsNo)
**09/13/2010 replaced by a stand alone proc 
lcRogPath=getRogsdir(lcLrsNo)
lcRogPath=ADDBS(ALLTRIM(lcRogPath))+PADL(ALLTRIM(STR(pn_lrsno)),8,"0")+"\004\"+;
          PADL(ALLTRIM(STR(viewCode30A.tag)),3,"0")
lcPage=""
FOR lnII=1 TO LEN(ALLTRIM(lcPageList))
    lcChar=SUBSTR(ALLTRIM(lcPageList),lnII,1)
    IF lcChar=";"
       IF LEN(ALLTRIM(lcPage))>0
          lcFileName=ADDBS(ALLTRIM(lcRogPath))+"P"+PADL(ALLTRIM(lcPage),7,"0")+".TIF"         
          IF FILE(lcFileName)    	   
	   	     DO PrintGroup WITH lcLtr, "STCAuth"     
	         DO PrintField WITH lcLtr, "Id", lcFileName
	      ELSE
	         gfmessage("Can't locate "+ALLTRIM(lcFileName)+". The STC will be printed without Attachment.")
	      ENDIF 
	      lcPage=""
	   ENDIF 
   ELSE
       IF ISDIGIT(lcChar)
          lcPage=ALLTRIM(lcPage)+ALLTRIM(lcChar)
       ENDIF    
   ENDIF 
 NEXT 
RETURN lcLtr
*-----------------------------------------------------------------------------
FUNCTION addGenAutho
LPARAMETERS lcLtr, lcGenAutho
LOCAL lcFileName, lcAuthoPath, lcInAuthoFile, lcOutAuthoFile, lcOutAuthoFileTiff, lcCurDir
lcPage=""
FOR lnII=1 TO LEN(ALLTRIM(lcGenAutho))
    lcChar=SUBSTR(ALLTRIM(lcGenAutho),lnII,1)
    IF lcChar=";"
       IF LEN(ALLTRIM(lcPage))>0
          SELECT viewGenAuthoA
          SEEK PADL(ALLTRIM(UPPER(lcPage)),2,"0")
          IF FOUND()             
             lcFileName=getGenAuthoName(NVL(viewGenAuthoA.filePath,''), NVL(viewGenAuthoA.fileName,''), lcPage)                     
             IF FILE(lcFileName)    	   
	   	        DO PrintGroup WITH lcLtr, "STCAuth"     
	            DO PrintField WITH lcLtr, "Id", lcFileName
	         ELSE
	            gfmessage("Can't locate "+ALLTRIM(lcFileName)+". The STC will be printed without Generic Attachment.")
	         ENDIF 
	      ENDIF 
	      lcPage=""
	   ENDIF 
   ELSE
       IF ISDIGIT(lcChar)
          lcPage=ALLTRIM(lcPage)+ALLTRIM(lcChar)
       ENDIF    
   ENDIF 
 NEXT 
RETURN lcLtr
*-----------------------------------------------------------------------------
PROCEDURE getGenAuthoName(filePath, lcFileName, lcPage)
IF !EMPTY(ALLTRIM(NVL(filePath,"")))    
   lcFileName=STRTRAN(ALLTRIM(lcFileName)," ","_")  
   lcInAuthoFile=ADDBS(ALLTRIM(filePath))+ALLTRIM(lcFileName)
   lcAuthoPath=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","AUTHOPATH", "\")))
   lcOutAuthoFile=ADDBS(ALLTRIM(lcAuthoPath))+ALLTRIM(lcFileName)
   lcOutAuthoFileTiff=ADDBS(ALLTRIM(lcAuthoPath))+"GenAth"+PADL(ALLTRIM(lcPage),2,"0")+".tif" 
   IF FILE(lcOutAuthoFile)
      DELETE FILE &lcOutAuthoFile
   ENDIF    
   IF FILE(lcOutAuthoFileTiff)
	  DELETE FILE &lcOutAuthoFileTiff
   ENDIF    
   IF FILE(lcInAuthoFile)
      COPY FILE &lcInAuthoFile TO &lcOutAuthoFile
	   IF ".PDF"$ALLTRIM(UPPER(lcOutAuthoFile))     
		  lcRetPDf2Tiff=""
		  lcRetPDf2Tiff=checkFileLoc()
		  IF EMPTY(ALLTRIM(lcRetPDF2Tiff))
		     RETURN lcLtr
		  ENDIF 		 
	      WAIT WINDOW "Converting PDF to TIFF. Please wait...." NOWAIT NOCLEAR
	      lcCurDir=SYS(5)+SYS(2003)        
	      lcInFile="c:\temp\CONVRT.PDF"
	      lcOutFile="c:\temp\CONVRT.TIF"
	      IF FILE(lcInFile)
	         DELETE FILE &lcInFile
	      ENDIF 
	      IF FILE(lcOutFile)
	         DELETE FILE &lcOutFile
	      ENDIF 
	      COPY FILE &lcOutAuthoFile TO &lcInFile
	      SET DEFAULT TO &lcRetPDF2Tiff
	      lcLine="RUN Pdf2Img.exe  -m -i "+ALLTRIM(lcInFile)+" -r 200x200 -c g4 -b 1 -o "+(ALLTRIM(lcOutFile))
	      &lcLine
	      SET DEFAULT TO &lcCurDir
	       
	      COPY FILE &lcOutFile TO &lcOutAuthoFileTiff
	      WAIT CLEAR 
	   ENDIF 	   
   ENDIF 
endif   
RETURN lcOutAuthoFileTiff

*------------------------------------------------------------------------------------------
PROCEDURE getRogsPath
LPARAMETERS lnLrsNo
LOCAL lnCurArea, lcPath, lcRTRogsPath, lcRetPath
LOCAL lcSQLLine
LOCAL oGen AS medGeneric OF generic
oGen=CREATEOBJECT("medGeneric")
lnCurArea=SELECT()
lcRetPath=""
SELECT 0
IF used("viewRogsPath")
   USE IN viewRogsPath
ENDIF    
lcSQLline="exec  [dbo].[getimagepath] 'ROG'"
oGen.sqlexecute(lcSQLLine, "viewRogsPath")
SELECT viewRogsPath
SCAN 
    lcPath=ALLTRIM(viewRogsPath.sPath)
    lcRTRogsPath=ALLTRIM(lcPath)+PADL(ALLTRIM(STR(lnLrsNo)),8,"0")
    IF !DIRECTORY(lcRTRogsPath) 
      IF !DIRECTORY(lcPath) 
          * this directory always there, so assuming the server itself is down
          * put some delay for server recovery
          WAIT WINDOW "Waiting for RTRogs Server response " TIMEOUT 20
      ENDIF 
    ENDIF 
    IF DIRECTORY(lcRTRogsPath)
       lcRetPath=lcPath
       EXIT 
    ENDIF     
ENDSCAN 
USE IN viewRogsPath
RELEASE oGen 
SELECT (lnCurArea)
RETURN  lcRetPath

*----------------------------------------------------------------------
FUNCTION checkFileLoc
LOCAL lcOS, lcPlatform
lcOS = OS(1)
DO CASE
CASE "6.02" $ lcOS AND OS(11) = "1"
	lcPlatform = "WIN8" && win10 and win8 return the same code 
CASE "6.01" $ lcOS AND OS(11) = "1"
	lcPlatform = "WIN7"
OTHERWISE 
	lcPlatform = "WINXP"
ENDCASE 

IF lcPlatform="WINXP"
	IF !DIRECTORY("C:\Program Files\PDF2Image v2.0.1")
   		gfMessage("Can't convert PDF to TIF."+CHR(13)+"Folder C:\Program Files\PDF2Image v2.0.1 doesn't exist.")
  		RETURN ""
	ENDIF    
	IF !File("C:\Program Files\PDF2Image v2.0.1\PDF2Image.exe")
   		gfMessage("Can't convert PDF to TIF."+CHR(13)+"File PDF2Image.exe doesn't exist.")
   		RETURN ""
	ENDIF    
	RETURN "'C:\Program Files\PDF2Image v2.0.1\'"
ELSE 
	IF !DIRECTORY("C:\Program Files (x86)\PDF2Image v2.0.1")
   		gfMessage("Can't convert PDF to TIF."+CHR(13)+"Folder C:\Program Files (x86)\PDF2Image v2.0.1 doesn't exist.")
  		RETURN ""
	ENDIF    
	IF !File("C:\Program Files (x86)\PDF2Image v2.0.1\PDF2Image.exe")
   		gfMessage("Can't convert PDF to TIF."+CHR(13)+"File PDF2Image.exe doesn't exist.")
   		RETURN ""
	ENDIF    
	RETURN "'C:\Program Files (x86)\PDF2Image v2.0.1\'"
ENDIF 
RETURN ""
*------------------------------------------------------------------------------------------
FUNCTION addAutho2
* uset this part for tiff documents only
* pdf documents will be processed by RPS 
LPARAMETERS lcLtr
LOCAL lcFileName, lcAuthoPath, lcInAuthoFile, lcOutAuthoFile, lcOutAuthoFileTiff, lcCurDir
IF !EMPTY(ALLTRIM(NVL(viewAuthoLinkA.exp,""))) AND RIGHT(ALLTRIM(UPPER(viewAuthoLinkA.exp)),4)=".TIF"
   lcFileName=STRTRAN(ALLTRIM(viewRequestA.mailid_no)," ","_")
   lcInAuthoFile='"'+ALLTRIM(viewAuthoLinkA.exp)+'"'
   lcAuthoPath=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","AUTHOPATH", "\")))
   lcOutAuthoFile=ADDBS(ALLTRIM(lcAuthoPath))+ALLTRIM(lcFileName)+".tif"
   lcOutAuthoFileTiff=ADDBS(ALLTRIM(lcAuthoPath))+ALLTRIM(lcFileName)+".tif" 
   IF FILE(lcOutAuthoFile)
      DELETE FILE &lcOutAuthoFile
   ENDIF    
   IF FILE(lcInAuthoFile)
       COPY FILE &lcInAuthoFile TO &lcOutAuthoFile	   	  	   
	   DO PrintGroup WITH lcLtr, "STCAuth"     
	   DO PrintField WITH lcLtr, "Id", lcOutAuthoFileTiff	  
   ENDIF 
endif   
RETURN lcLtr
*-----------------------------------------------------------------------------
FUNCTION addGenAutho2
LPARAMETERS lcLtr, lcGenAutho
LOCAL lcFileName, lcAuthoPath, lcInAuthoFile, lcOutAuthoFile, lcOutAuthoFileTiff, lcCurDir
lcPage=""
FOR lnII=1 TO LEN(ALLTRIM(lcGenAutho))
    lcChar=SUBSTR(ALLTRIM(lcGenAutho),lnII,1)
    IF lcChar=";"
       IF LEN(ALLTRIM(lcPage))>0
          SELECT viewGenAuthoA
          SEEK PADL(ALLTRIM(UPPER(lcPage)),2,"0")
          IF FOUND()             
          	IF RIGHT(ALLTRIM(UPPER(NVL(viewGenAuthoA.fileName,""))),4)=".TIF"   
             	* process only tiff documents
             	* the pdf documents will be processed by RPS               
             	lcFileName=getGenAuthoName(NVL(viewGenAuthoA.filePath,''), NVL(viewGenAuthoA.fileName,''), lcPage)                         
             	IF FILE(lcFileName)    	   
	   	      	 	 DO PrintGroup WITH lcLtr, "STCAuth"     
	           		 DO PrintField WITH lcLtr, "Id", lcFileName
	        	ELSE
	            	 gfmessage("Can't locate "+ALLTRIM(lcFileName)+". The STC will be printed without Generic Attachment.")
	           ENDIF 
	         ENDIF 
	      ENDIF 
	      lcPage=""
	   ENDIF 
   ELSE
       IF ISDIGIT(lcChar)
          lcPage=ALLTRIM(lcPage)+ALLTRIM(lcChar)
       ENDIF    
   ENDIF 
 NEXT 
RETURN lcLtr