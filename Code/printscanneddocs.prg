*-----------------------------------------------------------------------------------------------------
procedure printScannedDocs
*  75726/78152 scanned docs only
*-- 12/13/2019 #146658 MD Added printCDept,printMDep,printHITech
LPARAMETERS printClCode, printTag, printIssueType,PrintAll,printCDept,printMDep,printHITech
LOCAL TagExt, mvHold, docWasPrinted, lnIII, streamPart, omedGen
If Type( "mvScanDocsOnly")="U"
	Public mvScanDocsOnly
	mvScanDocsOnly=""
ENDIF
If Type( "mvScanDocsOnly")<>"C"
   mvScanDocsOnly=""
ENDIF 
* 04/03/2018 MD - set ntag if its not previously set  #83454 
IF TYPE("ntag")="U"   
   ntag=printTag
ENDIF   
mvHold=mv
mv=ALLTRIM(mvScanDocsOnly)
omedGen=Createobject("generic.medgeneric")

FOR lnIII=1 TO LEN(ALLTRIM(mvHold)) STEP 7000
	streamPart=SUBSTR(mvHold,lnIII,7000)
	omedGen.sqlexecute("Exec [dbo].[insertTraceSDStream] '" + fixquote(printClCode) + "',' " + Str(printTag) + "', 1,'"+LEFT(fixquote(ALLTRIM(streamPart)),7000)+"', '"+Alltrim(Upper(goapp.currentuser.ntlogin))+"'")
NEXT
	
IF TYPE("printTag")="N"
	TagExt=PADL(ALLTRIM(STR(printTag)),3,"0")
ELSE 
   	tagExt=PADL(ALLTRIM(printTag),3,"0")
ENDIF  
  	
*----------------------------------------------
*-- 12/13/2019 #146658 MD  
IF NVL(printHITech,"0")="1"
	reprintDoc=.F.   
	IF PL_1ST_REQ =.F.
	   reprintDoc=.T.
	ENDIF 
	printDate = Iif( PL_1ST_REQ, DATE(), Ctod(timesheet.txn_Date))  
	IF ALLTRIM(NVL(printHITech,"0"))="1"
	  IF !USED("Spec_Ins")
		 SELECT 0
		 omedGen.sqlexecute("Exec [dbo].[GetTheLatestBlurb] '" + fixquote(printClCode) + "',' " + Str(printTag) + "'", "Spec_ins")
	  ENDIF 
	  szrequest=ALLTRIM(Spec_ins.spec_inst)
	  szEdtReq = gfAddCR( szrequest)	  
	  mv=KOPREQCOV2(printIssueType, reprintDoc,printDate,.F., printCDept, printTag, printMDep,.F.,.T.)
	ENDIF 
ENDIF 
*----------------------------------------------

WAIT WINDOW  "Printing scanned certifications.." nowait
* For Notices print S and R only.  For issue print all documents
IF ALLTRIM(UPPER(printIssueType))="S"    
   	printTagScanOnly("S","*.TIF")
	printTagScanOnly("S","*."+ALLTRIM(TagExt))
	IF PrintAll=1
		printTagScanOnly("B","*.TIF")
		printTagScanOnly("B","*."+ALLTRIM(TagExt))
    ENDIF 		
	printTagScanOnly("R","*.TIF")
	printTagScanOnly("R","*."+ALLTRIM(TagExt))
	IF PrintAll=1
		printTagScanOnly("P","*.TIF")
		printTagScanOnly("P","*."+ALLTRIM(TagExt))
		printTagScanOnly("H","*.TIF")
		printTagScanOnly("H","*."+ALLTRIM(TagExt))
	ENDIF
	*-- 08/22/2018 MD #91992 print scanned certs for scanned docs subpoena only tags both offices
	findcerts(.F.,printTag)
ELSE
	printTagScanOnly("A","*.TIF")
	printTagScanOnly("A","*."+ALLTRIM(TagExt))
	printTagScanOnly("B","*.TIF")
	printTagScanOnly("B","*."+ALLTRIM(TagExt))	
	IF !USED("Spec_Ins")
		SELECT 0
		omedGen.sqlexecute("Exec [dbo].[GetTheLatestBlurb] '" + fixquote(printClCode) + "',' " + Str(printTag) + "'", "Spec_ins")
	ENDIF 
	szrequest=ALLTRIM(Spec_ins.spec_inst)
	DO PRINTcer with printTag, 1, Spec_ins.id_tblspec_ins
	*-- 08/22/2018 MD #91992 print scanned certs for scanned docs subpoena only tags CA office only
	IF pl_ofcOak=.T.
   		findcerts(.F.,printTag)
	ENDIF 
ENDIF 
FOR lnIII=1 TO LEN(ALLTRIM(mv)) STEP 7000
	streamPart=SUBSTR(mv,lnIII,7000)
	omedGen.sqlexecute("Exec [dbo].[insertTraceSDStream] '" + fixquote(printClCode) + "',' " + Str(printTag) + "', 2,'"+LEFT(fixquote(ALLTRIM(streamPart)),7000)+"', '"+Alltrim(Upper(goapp.currentuser.ntlogin))+"'")    
NEXT

RELEASE omedGen
RETURN 
*------------------------------------------------------------------------------------------------------------------------------------------------
PROCEDURE printTagScanOnly
LPARAMETERS docType, docExt
LOCAL lcDest, lcSource, lcPCXArch, lcPCX, lcPCXPath, lcPCXArchpath
LOCAL  lnII, lnFiles1,lnFiles2
IF USED("tempDocSD")
   USE IN tempDocSD
ENDIF    
IF USED("tempDocSD2")
   USE IN tempDocSD2
ENDIF 
L_REPRINT=.F.   
IF PL_1ST_REQ =.F.
   L_REPRINT=.T.
ENDIF    
* in case same docs are in both folders select filenames in the temp table and get unuque names
SELECT 0 
CREATE CURSOR tempDocSD (fileName c(200)) 
lcPCXPath=ADDBS(ALLTRIM(IIF(pl_ofcOak,goApp.capcx, goApp.pcxpath)))
lcPCX =lcPCXPath+  ALLTRIM(pc_lrsno) + ALLTRIM(docType)+ALLTRIM(docExt)
lnFiles1=ADIR(laDoc1, lcPCX)
FOR lnII=1 TO lnFiles1
        SELECT tempDocSD
        APPEND BLANK 
        replace filename WITH laDoc1[lnII,1]
NEXT
lcPCXArchpath=ADDBS(ALLTRIM(IIF(pl_ofcOak,goApp.capcxArch, goApp.pcxarchpath)))
lcPCXArch =lcPCXArchpath+ RIGHT(ALLTRIM(pc_lrsno),1) + "\"+  ALLTRIM(pc_lrsno) + ALLTRIM(docType)+ALLTRIM(docExt)
lnFiles2=ADIR(laDoc2, lcPCXArch)
FOR lnII=1 TO lnFiles2
        SELECT tempDocSD
        APPEND BLANK 
        replace filename WITH laDoc2[lnII,1]
NEXT

SELECT DISTINCT filename FROM tempDocSD INTO CURSOR tempDocSD2 readwrite WHERE !EMPTY(ALLTRIM(filename)) ORDER BY filename 
* Once the list of unique names is selected loop through the list and send them to RPS

SELECT tempDocSD2
SCAN
	lcSource =lcPCXPath +  ALLTRIM(tempDocSD2.filename)
	lcDest   =lcPCXArchpath + RIGHT(ALLTRIM(pc_lrsno),1) + "\"+ALLTRIM(tempDocSD2.filename)
	DO SEND_PG IN SUBP_PA WITH lcSource, lcDest	
ENDSCAN
IF USED("tempDocSD")
   USE IN tempDocSD
ENDIF    
IF USED("tempDocSD")
   USE IN tempDocSD
ENDIF   
RETURN