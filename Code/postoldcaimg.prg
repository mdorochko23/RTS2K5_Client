*------------------------------------------------------------------------------------
* Post CA Old Images imitation proccess
* The program updates tblSCanLook, tblRequest, tblDistTodo, pdf_ocr..tblJobs, chon_rtfl..tblpatiens, chon_rtfl..tbldocuments and
* copies images from CA to KOP
* convert pdf to tiff
*------------------------------------------------------------------------------------
LOCAL lnCurArea, lnLrsNo, lnTag, lcFlDocsIn, lcFlDocsOut, lnPatID, lnPages, lnYY, c_sql
lnCurArea=SELECT()

DO checkdlls

SET CLASSLIB TO UTILITY ADDITIVE

oMed=createobject("generic.medgeneric")     
oLRSTag = CREATEOBJECT("utility.frmGetLrsTag", "F")	
oLRSTag.caption="Post Old CA Images"
oLRSTag.SHOW			 			
lnLrsNo=oLRSTag.lnLrsNo
lnTag=oLRSTag.lnTag	
RELEASE oLRSTag	
IF lnLRSNo=0
   RETURN 
ENDIF    
lcDocsIn=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","CAOldImageInPath", "\")))
lcDocsOut=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","RTDocs", "\")))+PADL(ALLTRIM(STR(lnLrsNo)),8,"0")+"\"+PADL(ALLTRIM(STR(lntag)),3,"0")

IF !DIRECTORY(lcDocsIn)
   gfmessage("Can't find directory "+CHR(13)+ALLTRIM(lcFlDocsIn))
   RETURN 
ENDIF 
IF DIRECTORY(lcDocsOut)
   IF ADIR(laList,ADDBS(ALLTRIM(lcDocsOut))+"*.tif")>0
      IF gfmessage("The images already exist in "+ALLTRIM(lcDocsOut)+".  Overwrite?",.T.)=.F.
         RETURN
      ELSE 
         lcDocsDelete=ADDBS(ALLTRIM(lcDocsOut))+"*.*"
         DELETE FILE &lcDocsDelete
      ENDIF 
   ENDIF 
ELSE 
   MD &lcDocsOut 
ENDIF 
lcCurDir=SYS(5)+SYS(2003)  
SET DEFAULT TO &lcDocsIn
lcFileName=GETFILE("PDF")
SET DEFAULT TO &lcCurDir

DO PDFtoTiff WITH lcFileName,lcDocsOut 
*DO convertPDFtoTiff WITH lcFileName,lcDocsOut 
   
lnPages=ADIR(laList,ADDBS(ALLTRIM(lcDocsOut))+"*.*tif")

*!*	WAIT WINDOW "Adding Scanlook record" NOWAIT NOCLEAR 
*!*	*--- Add record to tblScanLook
*!*	DO addScanLook WITH lnLrsNo, lnTag, lnPages

WAIT WINDOW "Adding tblPatients record" NOWAIT NOCLEAR 
*-- Add record to chon_RTFL tblPatients
lnPatID=addPatients(lnLrsNo, lnTag)
IF lnPatID<1
   gfMessage("Error while updating tblPatients")
   RETURN .F.
ENDIF  

*----  Add records to chon_RTFL tblDocuments
WAIT WINDOW "Adding tblDocuments record" NOWAIT NOCLEAR 
FOR lnYY=1 TO lnPages   
    lnPageNum=VAL(SUBSTR(laList[lnYY,1],2,AT(".",laList[lnYY,1])-1))
    DO addDocuments with  lnLrsNo, lnTag,lnPatID, lnPageNum, laList[lnYY,1], laList[lnYY,2]           		          
NEXT 

*-- 9/22/2011 kdl update tblrequest scan data and post jobs to ditttodo
c_sql= "exec dbo.getrequestbylrsno " + alltrim(str(lnLrsNo)) + "," + alltrim(str(lnTag)) 
oMed.sqlexecute(c_sql,"request")
IF RECCOUNT("request")>0
	c_base=IIF( request.first_look AND NOT request.distribute,"w:\rt-fl","w:\rt-docs")
	cfoldname=ADDBS(c_base)+ADDBS(PADL(ALLTRIM(STR(lnLrsNo)),8,"0"))+PADL(ALLTRIM(STR(request.TAG)),3,"0")
	nf=ADIR(a_files,ADDBS(cfoldname)+"*.tif")
	IF nf>0
		cf=ALLTRIM(STR(nf))

		c_sql="update tblrequest set scan_date='"+DTOC(a_files[1,3])+"',scan_pages=&cf.,scanned=1,scan_table='WEJ1' where id_tblrequests='"+ ;
			request.id_tblrequests+"'"
		nr=omed.sqlexecute(c_sql)

		c_sql="update tblTimeSheet set [count]=&cf., editedBy='" + goApp.CurrentUser.ntlogin + "', edited=getdate() " + ; 
			" where cl_code='" + request.cl_code + "' and tag= " + ALLTRIM(STR(request.TAG)) + " and txn_code in (1,41) and deleted is null"
		nr=omed.sqlexecute(c_sql)
	ENDIF
ENDIF
	
*--- Add record to tblDistToDo
WAIT WINDOW "Adding tblDistToDo record" NOWAIT NOCLEAR 
IF addDistToDo(lnLrsNo, lnTag, lnPages)=.F.
   RETURN 
ENDIF    

WAIT CLEAR 
gfmessage("Done")	
SELECT (lnCurArea)

*-----------------------------------------------------------------------------------------------------------------------
FUNCTION addPatients
LPARAMETERS lnLrsNo, lnTag
LOCAL lnCurArea, lnID, lcSQLLine
lnCurArea=SELECT()
lnID=0
lcSQLLine="exec dbo.addCAOldImgtoChon "+ALLTRIM(STR(lnLrsNo))+", "+ALLTRIM(STR(lnTag))
oMed.sqlexecute(lcSQLLine, "viewChonPatientID")
SELECT viewChonPatientID
IF RECCOUNT()>0
   lnID=viewChonPatientID.nPatientID
ENDIF   
USE IN viewChonPatientID
SELECT (lnCurArea)
RETURN lnID
*-----------------------------------------------------------------------------------------------------------------------
PROCEDURE addScanLook
LPARAMETERS lnLrsNo, lnTag, lnPages
LOCAL lnCurArea, lcSQLLine
lnCurArea=SELECT()
lcSQLLine="exec dbo.addScanLookRecord "+ALLTRIM(STR(lnLrsNo))+", "+ALLTRIM(STR(lnTag))+", "+ALLTRIM(STR(lnPages))
oMed.sqlexecute(lcSQLLine)
SELECT (lnCurArea)
RETURN 
*-------------------------------------------------------------------------------------------------------------------------
PROCEDURE addDocuments
LPARAMETERS lnLrsNo, lnTag, lnPatID, lnPageNum, lcPageName, lnSize
LOCAL lnCurArea, lnID, lcSQLLine
lnCurArea=SELECT()
lnID=0
lcSQLLine="exec dbo.addCAOldImgtoChonDocs "+ALLTRIM(STR(lnLrsNo))+", "+ALLTRIM(STR(lnTag))+", "+ALLTRIM(STR(lnPageNum))+", "+;
ALLTRIM(STR(lnsize))+", "+ALLTRIM(STR(lnPatID))+", '"+ALLTRIM(lcPageName)+"'"
oMed.sqlexecute(lcSQLLine)
SELECT (lnCurArea)
RETURN 
*--------------------------------------------------------------------------------------------------------------------------------
PROCEDURE addDistToDo
LPARAMETERS lnLrsNo, lnTag, lnPages
LOCAL lnCurArea, lnID, lcSQLLine
lnCurArea=SELECT()
lcSQLLine="exec dbo.getBBOrderedDSList "+alltrim(STR(lnLrsNo))+", "+ALLTRIM(STR(lnTag))
oMed.sqlexecute(lcSQLLine,"viewAttyDsList")
SELECT viewAttyDSList
SCAN 
    n_dsid=dsjobid(1)
    lcSQLLine="exec dbo.addCAOldImgDistToDoRecord "+ALLTRIM(STR(lnLrsNo))+", "+ALLTRIM(STR(lnTag))+", "+;
     "'"+ALLTRIM(goApp.CurrentUser.ntlogin)+"', '"+ALLTRIM(n_dsid)+"', "+ALLTRIM(STR(lnPAges))+", "+;
     "'"+ALLTRIM(UPPER(viewAttyDSList.at_code))+"', '"+ALLTRIM(UPPER(viewAttyDSList.shiptype))+"'"     
	oMed.sqlexecute(lcSQLLine)
	SELECT viewAttyDSList
ENDSCAN 	  
SELECT (lnCurArea)
RETURN .T.
   
*--------------------------------------------------------------------------------------------------------------------------------
FUNCTION dsjobid
LPARAMETERS lnRecs
LOCAL n_Curarea, n_jobnum, c_Prefix, l_distid, n_RetjobID
n_Curarea = SELECT()
lcGlobalPath=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","Global", "\")))
l_distid=.t.
IF NOT USED("distid")	
	USE (ADDBS(lcGlobalPath)+'distid') IN 0
	l_distid=.f.
ENDIF

SELECT distid

GOTO TOP
DO WHILE NOT RLOCK()
ENDDO
DO WHILE flag
ENDDO
REPLACE flag WITH .T.
*-- Increment counter
n_jobnum = distid.jobid_no + lnRecs
n_RetjobID=distid.jobid_no
c_Prefix = distid.prefix
IF n_jobnum >=  99999999
   REPLACE distid.jobid_no WITH lnRecs
	n_jobnum = lnRecs
	n_RetjobID=1
   IF RIGHT(c_Prefix,1) != "Z"
      *-- Increment prefix
      c_Prefix = CHR(ASC(c_Prefix) + 1)
      REPLACE distid.prefix WITH c_Prefix
   ELSE
      *-- Should never happen :-(
      DO WHILE .T.
         MESSAGEBOX("Seek MIS help! Please do not continue!!")
         MESSAGEBOX( "DS Job ID overflow !!")
      ENDDO
   ENDIF
ELSE
   REPLACE distid.jobid_no WITH n_jobnum
ENDIF

REPLACE distid.flag WITH .F.
UNLOCK

IF NOT l_distid=.t.
	USE IN distid
ENDIF	

SELECT (n_CurArea)

RETURN (c_Prefix + PADL(ALLTRIM(STR(n_RetjobID)), 8, "0"))

*---------------------------------------------------------------
PROCEDURE PDFToTiff
LPARAMETERS cPdffile,cTiffFile
LOCAL c_convert,c_drive,c_selected,c_temp,c_Outfile
c_Outfile=cTiffFile+"\P000.TIF"
c_temp='Z.Z'
*cnewfile=(ADDBS(JUSTPATH(cfile))+JUSTSTEM(cfile)+'.TIF')

IF NOT FILE(cPdffile)
	return
ENDIF 

WAIT WINDOW 'Converting PDF file to Multi-page TIFF format.' NOWAIT NOCLEAR 
*c_selected=thisform.temp_path+SYS(3)+".pdf"
*COPY FILE (cPdffile) TO (c_selected)
c_drive=SYS(5)+SYS(2003)
SET DEFAULT TO 'C:\RTS'

DECLARE long PDFToImageConverter in "c:\rts\pdf2image.dll" ;
	String szPDFFileName , String szOutputName, ;
	String szUserPassword,String szOwnPassword, ;
	long xresolution,long yresolution,long bitcount, ;
	long compression, long quality,INTEGER grayscale, ;
	INTEGER multipage,long firstPage,long lastPage

Declare long PDFToImageGetPageCount  in "c:\rts\pdf2image.dll" ;
	string szPDFFileName 

Declare PDFToImageSetCode in "c:\rts\pdf2image.dll" ;
	string szRegcode

LOCAL coutfile,npagecnt,nok

=PDFToImageSetCode("VPEDRFXY2PIDMFAGEXYUXEJHYEXNVERYPDF")

npagecnt=PDFToImageGetPageCount(cpdffile)

WAIT WINDOW "Converting PDF file to Tiff File: " + ALLTRIM(STR(npagecnt)) + " page(s)" NOWAIT NOCLEAR 

nok = PDFToImageConverter(cPdffile, c_Outfile ;
,"", "", 200, 200, 1, 4, 70, 0, 0, -1, -1)

WAIT CLEAR 

IF nok>0 
	 gfMessage("Failed to convert PDF file to Tiff file")  	
ENDIF

CLEAR DLLS "PDFToImageConverter","PDFToImageGetPageCount","PDFToImageSetCode" 

SET DEFAULT TO (c_drive)

*!*	IF FILE(c_selected)
*!*		ERASE (c_selected)
*!*	ENDIF

*---------------------------------------------------------------
*!*	PROCEDURE convertPDFToTiff
*!*	PARAMETERS lcFileName, lcOutPath
*!*	LOCAL lcCurDir, lcInFile, lcOutFile, lcLine, lnII, lcConvertPath, lcConvertPathFiles

*!*	lcConvertPath=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","tempConvPDF", "\")))

*!*	IF !DIRECTORY("C:\Program Files\PDF2Image v2.0.1")
*!*	   gfMessage("Can't convert PDF to TIF."+CHR(13)+"Folder C:\Program Files\PDF2Image v2.0.1 doesn't exist.")
*!*	   RETURN .F.
*!*	ENDIF   
*!*	IF !DIRECTORY("C:\Program Files\PDF2Image v2.0.1")
*!*	    gfMessage("Can't convert PDF to TIF."+CHR(13)+"File PDF2Image.exe doesn't exist.")
*!*	    RETURN .F.
*!*	ENDIF    
*!*	WAIT WINDOW "Converting PDF to TIFF. Please wait...." NOWAIT NOCLEAR
*!*	lcCurDir=SYS(5)+SYS(2003)   
*!*	IF !DIRECTORY(lcConvertPath)
*!*	    MD  &lcConvertPath
*!*	ENDIF 
*!*	lcConvertPathFiles=ADDBS(ALLTRIM(lcConvertPath))+"*.*"
*!*	DELETE FILE &lcConvertPathFiles

*!*	lcFileName=STRTRAN(lcFileName,".pdf","")
*!*	lcInFile=ADDBS(ALLTRIM(lcConvertPath))+STRTRAN(ALLTRIM(UPPER(JUSTFNAME(lcFileName))),".PDF","")+".pdf"
*!*	lcOutFile=STRTRAN(ALLTRIM(UPPER(JUSTFNAME(lcFileName))),".PDF","")+".tif"
*!*	lcOutFile=STRTRAN(ALLTRIM(UPPER(lcOutFile)),"_","")
*!*	lcOutFile=STRTRAN(ALLTRIM(UPPER(lcOutFile))," ","")
*!*	lcOutFile=ADDBS(ALLTRIM(lcConvertPath))+lcOutFile

*!*	COPY FILE &lcFileName TO &lcInFile
*!*	SET DEFAULT TO 'C:\Program Files\PDF2Image v2.0.1'
*!*	lcLine="RUN Pdf2Img.exe  -i "+ALLTRIM(lcInFile)+" -r 200x200 -c g4 -b 1 -o "+(ALLTRIM(lcOutFile))
*!*	&lcLine
*!*	SET DEFAULT TO &lcCurDir
*!*	IF ADIR(laOutPut,lcOutPath+"*.*")>0
*!*	   DELETE FILE &lcOutPath+"*.*"
*!*	ENDIF 
*!*	FOR lnII=1 TO ADIR(laTiffPages,"c:\temp\convertPDF\*.tif")
*!*		lcInFile=ADDBS(ALLTRIM(lcConvertPath))+ALLTRIM(laTiffPages[lnII,1])+IIF(".TIF"$ALLTRIM(UPPER(laTiffPages[lnII,1])),"",".tif") 
*!*	    lcOutFile=ADDBS(ALLTRIM(lcOutPath))+"P"+PADL(ALLTRIM(STR(lnII)),7,"0")+".tif"    	     
*!*		COPY FILE &lcInFile TO &lcOutFile
*!*	NEXT 
*!*	WAIT CLEAR 

*----------------------------------------------------
PROCEDURE checkdlls

LOCAL ndlls,ncnt,d_TxtTiff,n_TxtTif,C_STRING


ndlls=ADIR(a_dlls,"\\sanstor\image\Release\vfp\RTS\Dlls\*.dll")

FOR ncnt=1 TO ALEN(a_dlls,1)
	IF INLIST(UPPER(JUSTEXT(a_dlls[ncnt,1])),"DLL")
		IF NOT FILE("c:\rts\"+ALLTRIM(a_dlls[ncnt,1]))
			WAIT WINDOW "Copying required startup file. Please wait..." NOWAIT NOCLEAR
			COPY FILE ("\\sanstor\image\Release\vfp\RTS\Dlls\"+ALLTRIM(a_dlls[ncnt,1])) ;
				TO ("c:\rts\"+ALLTRIM(a_dlls[ncnt,1]))
			IF NOT "CIMAGE.DLL" $ UPPER(ALLTRIM(a_dlls[ncnt,1]))
				c_string="regsvr32 "+"c:\rts\"+ALLTRIM(a_dlls[ncnt,1])
				RUN &c_string
			ENDIF
			WAIT CLEAR
		ENDIF
	ENDIF
NEXT

*// check for location of xfrxlib
IF DIRECTORY("c:\windows\system32") AND NOT FILE("c:\windows\system32\xfrxlib.fll")
 	COPY FILE "\\sanstor\image\Release\vfp\RTS\Dlls\xfrxlib.fll" TO "c:\windows\system32\xfrxlib.fll"
ENDIF 

*// check for tiffmaker90
ndlls=ADIR(a_dlls,"\\sanstor\image\Release\tm90\*.*")
FOR ncnt=1 TO ALEN(a_dlls,1)
	IF NOT FILE("c:\rts\"+ALLTRIM(a_dlls[ncnt,1]))
		WAIT WINDOW "Copying required startup file. Please wait..." NOWAIT NOCLEAR
		COPY FILE ("\\sanstor\image\Release\tm90\"+ALLTRIM(a_dlls[ncnt,1])) ;
			TO ("c:\rts\"+ALLTRIM(a_dlls[ncnt,1]))
		WAIT CLEAR

	ELSE
*// check date of user file		d_TxtTiff = a_dlls[ncnt,3]
		n_TxtTiff = ADIR(a_txtTiff,"c:\rts\"+ALLTRIM(a_dlls[ncnt,1]))
		d_TxtTiff = a_dlls[ncnt,3]
		IF (n_TxtTiff > 0) AND (d_TxtTiff > a_txtTiff[1, 3])
			WAIT WINDOW "Updating required startup file. Please wait..." NOWAIT NOCLEAR

			COPY FILE ("\\sanstor\image\Release\tm90\"+ALLTRIM(a_dlls[ncnt,1])) ;
				TO ("c:\rts\"+ALLTRIM(a_dlls[ncnt,1]))
		ENDIF
	ENDIF
NEXT
WAIT CLEAR 