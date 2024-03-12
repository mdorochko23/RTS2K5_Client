*-----------------------------------------------
* 01/25/2018 - MD #77400
* 01/30/2018 - MD added check for the tag ext
* Print scan certs if founded
* First check for the tag level "F" If found tag level, print them, ignore case and generic ones
* if not found tag level, check the case level "X". If found, print them, ignore generic ones
* If not found case level print generic ones (l_foundX=.F.)
* checkCertNow is passed as .T./.F. originally it was desinged to print scanned certs for NonProgrammed Subpoenas only
* Now, if the certs were scanned print them
FUNCTION findCerts
PARAMETERS checkCertNow, certTag
LOCAL certWasPrinted, certTagExt
IF TYPE("certTag")="N"
	certTagExt=PADL(ALLTRIM(STR(certTag)),3,"0")
ELSE 
   	certTagExt=PADL(ALLTRIM(certTag),3,"0")
ENDIF    	
WAIT WINDOW  "Printing scanned certifications.." nowait
certWasPrinted=.F.
certWasPrinted=printTagCaseCerts("F","*.TIF",certWasPrinted,checkCertNow)
certWasPrinted=printTagCaseCerts("F","*."+ALLTRIM(certTagExt),certWasPrinted,checkCertNow)
IF certWasPrinted=.F.
	certWasPrinted=printTagCaseCerts("X","*.TIF",certWasPrinted,checkCertNow)
	certWasPrinted=printTagCaseCerts("X","*."+ALLTRIM(certTagExt),certWasPrinted, checkCertNow)
ENDIF 
RETURN certWasPrinted
*------------------------------------------------
PROCEDURE printTagCaseCerts
LPARAMETERS docType, docExt,printedCert, checkCertNow
LOCAL lcDest, lcSource, lcPCXArch, lcPCX,lcPCXPath, lcPCXArchpath
LOCAL  lnII, lnFiles1,lnFiles2, printedCert
IF USED("tempCertDoc")
   USE IN tempCertDoc
ENDIF    
IF USED("tempCertDoc2")
   USE IN tempCertDoc2
ENDIF    

* in case same cert is in both folders select filenames in the temp table and get unuque names
SELECT 0 
CREATE CURSOR tempCertDoc (fileName c(200))
lcPCXPath=ADDBS(ALLTRIM(IIF(pl_ofcOak,goApp.capcx, goApp.pcxpath)))
lcPCX =lcPCXPath + ALLTRIM(pc_lrsno) + ALLTRIM(docType)+ALLTRIM(docExt)
lnFiles1=ADIR(laCert1, lcPCX)
FOR lnII=1 TO lnFiles1
        SELECT tempCertDoc
        APPEND BLANK 
        replace filename WITH laCert1[lnII,1]
NEXT
lcPCXArchpath=ADDBS(ALLTRIM(IIF(pl_ofcOak,goApp.capcxArch, goApp.pcxarchpath)))
lcPCXArch =lcPCXArchpath + RIGHT(ALLTRIM(pc_lrsno),1) + "\"+  ALLTRIM(pc_lrsno) + ALLTRIM(docType)+ALLTRIM(docExt)
lnFiles2=ADIR(laCert2, lcPCXArch)
FOR lnII=1 TO lnFiles2
        SELECT tempCertDoc
        APPEND BLANK 
        replace filename WITH laCert2[lnII,1]
NEXT 
SELECT DISTINCT filename FROM tempCertDoc INTO CURSOR tempCertDoc2 WHERE !EMPTY(ALLTRIM(filename)) ORDER BY filename 
* Once the list of unique names is selected loop through the list and send them to RPS
SELECT tempCertDoc2
SCAN
	lcSource =lcPCXPath +  ALLTRIM(tempCertDoc2.filename)
	lcDest   =lcPCXArchpath + RIGHT(ALLTRIM(pc_lrsno),1) + "\"+ALLTRIM(tempCertDoc2.filename)
	IF checkCertNow=.F.
		DO SEND_PG IN SUBP_PA WITH lcSource, lcDest
	ENDIF 
	printedCert=.T.
ENDSCAN
IF USED("tempCertDoc")
   USE IN tempCertDoc
ENDIF    
IF USED("tempCertDoc2")
   USE IN tempCertDoc2
ENDIF   
RETURN printedCert

*-----------------------------------------------------------------------------------------------------------------------------
* 01/25/2018 MD #77400 
**11/8/2016-Find Scanned Cets (X files) #51529
*!*	LOCAL lcLrs AS STRING, lcSPath AS STRING, lcDPath AS STRING,  lcDest AS STRING, lc_pcxfile AS STRING, l_foundx AS Boolean
*!*	lcLrs = ALLT( pc_lrsno)

*!*	LOCAL  omed_img AS OBJECT
*!*	omed_img= CREATEOBJECT("generic.medgeneric")
*!*	omed_img.closealiAs("Scanx")
*!*	**09/25/2017: REMOVE WHEN POSSIBLE THE deleted() X  FILES.
*!*	c_sql=" EXEC [dbo].[ScanCerts2]  '" +lcLrs+"'"
*!*	omed_img.sqlexecute(c_sql,"Scanx")
*!*	=CURSORSETPROP("KeyFieldList", "nid", "Scanx")
*!*	INDEX ON nid TAG Sort1 ADDITIVE
*!*	WAIT WINDOW  "Printing scanned certifications.." nowait
*!*	l_foundx=.F.
*!*	*--------------
*!*	IF  USED('Scanx') AND NOT EOF()	
*!*		l_foundx=.T.
*!*	ENDIF


*!*	*****printr all 'x' files when requested
*!*	IF l_prntcert AND l_foundx

*!*	cdoctype="X"
*!*	lcSPath = ADDBS(ALLTRIM(goApp.pcxpath))
*!*	lcDPath =ADDBS(ALLTRIM( goApp.pcxarchpath ))+ RIGHT(lcLrs,1) + "\"
*!*	lcDest=""
*!*	lc_pcxfile=""

*!*		SELECT Scanx
*!*		SET ORDER TO Sort1
*!*		SCAN  

*!*	*******************************************************************************
*!*	**11/8/2016 - x files (scanned certs)
*!*	*******************************************************************************
*!*				nPage=RECNO()
*!*				lcSource =lcSPath +  lcLrs  + cdoctype+  ALLTRIM(STR(nPage)) +".TIF"   &&ALLTRIM(Scanx.SDOCNEW )&&
*!*				lcDest   =ADDBS(ALLTRIM(lcDPath)) +  lcLrs  +cdoctype +ALLTRIM(STR(nPage)) +".TIF"  
*!*				IF NOT SEND_PG(lcSource, lcDest)
*!*					EXIT
*!*				ENDIF		
*!*			SELECT Scanx

*!*		ENDSCAN


*!*	ENDIF
*!*	RELEASE omed_img
*!*	RETURN l_foundx






