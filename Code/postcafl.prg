*------------------------------------------------------------------------------------
* CA Silica First Look imitation proccess
* The program updates tblSCanLook, tblRequest, tblDistTodo, pdf_ocr..tblJobs, chon_rtfl..tblpatiens, chon_rtfl..tbldocuments and
* copies images from CA to KOP
*------------------------------------------------------------------------------------
LOCAL lnCurArea, lnLrsNo, lnTag, lcFlDocsIn, lcFlDocsOut, lnPatID, lnPages, lnYY
lnCurArea=SELECT()
SET CLASSLIB TO UTILITY ADDITIVE

oMed=createobject("generic.medgeneric")     
oLRSTag = CREATEOBJECT("utility.frmGetLrsTag", "F")	
oLRSTag.SHOW			 			
lnLrsNo=oLRSTag.lnLrsNo
lnTag=oLRSTag.lnTag	
RELEASE oLRSTag	
IF lnLRSNo=0
   RETURN 
ENDIF    
lcFlDocsIn=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","CAFLInPath", "\")))+PADL(ALLTRIM(STR(lnLrsNo)),8,"0")+"\"+PADL(ALLTRIM(STR(lntag)),3,"0")
lcFlDocsOut=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","CAFLOutPath", "\")))+PADL(ALLTRIM(STR(lnLrsNo)),8,"0")+"\"+PADL(ALLTRIM(STR(lntag)),3,"0")
IF !DIRECTORY(lcFlDocsIn)
   gfmessage("Can't find directory "+CHR(13)+ALLTRIM(lcFlDocsIn))
   RETURN 
ENDIF 
IF DIRECTORY(lcFlDocsOut)
   gfmessage("The directory "+ALLTRIM(lcFlDocsOut)+" already exists")
   RETURN 
ENDIF 
MD &lcFlDocsOut 

   
lnPages=ADIR(laList,ADDBS(ALLTRIM(lcFlDocsIn))+"*.*tif")

WAIT WINDOW "Adding Scanlook record" NOWAIT NOCLEAR 
*--- Add record to tblScanLook
DO addScanLook WITH lnLrsNo, lnTag, lnPages

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
    lcDocTagFile=ADDBS(ALLTRIM(lcFlDocsIn))+laList[lnYY,1]
    lcDocSavedTagFile=ADDBS(ALLTRIM(lcFlDocsOut))+laList[lnYY,1]
    COPY FILE &lcDocTagFile TO &lcDocSavedTagFile
    lnPageNum=VAL(SUBSTR(laList[lnYY,1],2,AT(".",laList[lnYY,1])-1))
    DO addDocuments with  lnLrsNo, lnTag,lnPatID, lnPageNum, laList[lnYY,1], laList[lnYY,2]           		          
NEXT 

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
lcSQLLine="exec dbo.addCAFLtoChon "+ALLTRIM(STR(lnLrsNo))+", "+ALLTRIM(STR(lnTag))
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
lcSQLLine="exec dbo.addCAFLtoChonDocs "+ALLTRIM(STR(lnLrsNo))+", "+ALLTRIM(STR(lnTag))+", "+ALLTRIM(STR(lnPageNum))+", "+;
ALLTRIM(STR(lnsize))+", "+ALLTRIM(STR(lnPatID))+", '"+ALLTRIM(lcPageName)+"'"
oMed.sqlexecute(lcSQLLine)
SELECT (lnCurArea)
RETURN 
*--------------------------------------------------------------------------------------------------------------------------------
PROCEDURE addDistToDo
LPARAMETERS lnLrsNo, lnTag, lnPages
LOCAL lnCurArea, lnID, lcSQLLine
lnCurArea=SELECT()
n_dsid=dsjobid(1)
lcSQLLine="exec dbo.addCAFLDistToDoRecord "+ALLTRIM(STR(lnLrsNo))+", "+ALLTRIM(STR(lnTag))+", "+;
"'"+ALLTRIM(goApp.CurrentUser.ntlogin)+"', '"+ALLTRIM(n_dsid)+"', "+ALLTRIM(STR(lnPAges))
oMed.sqlexecute(lcSQLLine)
  
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


