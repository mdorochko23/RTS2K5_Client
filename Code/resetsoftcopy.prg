*********************************************************************************************
*Global Tag cancellation 
*********************************************************************************************
LPARAMETERS lcList
LOCAL lnCurArea, lcDefault, lcFile, llCharge, llPrint, lcFileName, lcComment21, lcComment77, lcLRSNo, lcTag, lcSQLLine
IF ALLTRIM(UPPER(goApp.currentUser.oRec.dept))<>"IT"  
   gfmessage("This function is for IT department usage only")
   RETURN
ENDIF 
   
IF lcList=.T.
   lcFile=getFileToReset()
   lcMessage="The Tags have been reset"
ELSE 
   lcFile=getSingleTagToReset()
   lcMessage="The Tag has been reset"
ENDIF 
IF EMPTY(ALLTRIM(lcFIle))
   RETURN
ENDIF 

oMed=createobject("generic.medgeneric")     
SELECT &lcFile     
SCAN   
   lnLRSNo=xlsFile.a
   lnTag=xlsFile.b      
   lcSQLLine="select * from tbltagitem where lrs_no="+ALLTRIM(STR(lnLrsNo))+" and tag="+ALLTRIM(STR(lnTag))+" and active=1"
   oMed.sqlexecute(lcSQLLine, "viewJobs")
   SELECT viewJobs
   IF RECCOUNT()=0
      USE IN viewJobs
      SELECT &lcFile
      LOOP 
   ENDIF    
   lcOldFile=ALLTRIM(viewjobs.softcopy_infolder)
   lcBaseName=ADDBS(JUSTPATH(lcOldFile))+JUSTSTEM(lcOldFile)
	
	IF FILE(lcBaseName+".org")
*--6/4/19: accomodate PDF SC format [87505]
	   IF ALLTRIM(UPPER(NVL(viewjobs.sInbDocType,"TIFF")))=="PDF"
		   RENAME (lcBaseName+".pdf") to (lcBaseName+".sav")
		   RENAME (lcBaseName+".org") to (lcBaseName+".pdf")
	   ELSE
		   RENAME (lcBaseName+".tif") to (lcBaseName+".sav")
		   RENAME (lcBaseName+".org") to (lcBaseName+".tif")
	   ENDIF
	ENDIF 
	*-------------  TimeSheet ------------------------
	lcSQLLine="update tbltimesheet set deleted=getdate(),deletedby='"+alltrim(goApp.CurrentUser.ntlogin)+"' "+;
	"where cl_code=dbo.getclcodebylrs("+ALLTRIM(STR(lnLRSNo))+") and tag="+ALLTRIM(STR(lnTag))+" and txn_code in (1,41) and deleted is null"
	oMed.sqlexecute(lcSQLLine)
	*-------------  Request  ------------------------
	lcSQLLine="update tblrequest set status='W',distribute=0,nrs=0, nrs_code='',inc=0,hstatus='', hnrs=0,hnrs_code='',hinc=0,hqual='', fin_Date=null, "+;
	"scanned=0, scan_date=null, scan_pages=0, scan_table='', pages=0, "+;
	" edited=getdate(),editedby='"+alltrim(goApp.CurrentUser.ntlogin)+"' "+;
	"where cl_code=dbo.getclcodebylrs("+ALLTRIM(STR(lnLRSNo))+") and tag="+ALLTRIM(STR(lnTag))+" and active=1"
	oMed.sqlexecute(lcSQLLine)
	*-------------  TagItem  ------------------------
	lcSQLLine="update tbltagitem set softcopy_done=null, scan_date=null where nid="+ALLTRIM(viewjobs.nid)
	oMed.sqlexecute(lcSQLLine)
	*-------------  RTDocs ---------------------------
	lcDoc=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","rtDocs", "\")))+PADL(ALLTRIM(STR(lnLRSNo)),8,"0")+"\"
	lcDocTag=ALLTRIM(lcDoc)+PADL(ALLTRIM(STR(lnTag)),3,"0")+"\"
	IF DIRECTORY(lcDocTag)	   	
	   FOR lnII=1 TO 99			&& allow up to 99 folders 
	       lcDocSavedTag=ALLTRIM(lcDoc)+"SV"+PADL(ALLTRIM(STR(lnII)),2,"0")+"_"+PADL(ALLTRIM(STR(lnTag)),3,"0")+"\"
		   IF !DIRECTORY(lcDocSavedTag)
		      MD &lcDocSavedTag
		      FOR lnYY=1 TO ADIR(laList,ALLTRIM(lcDocTag)+"*.*")
		          lcDocTagFile=ALLTRIM(lcDocTag)+laList[lnYY,1]
		          lcDocSavedTagFile=ALLTRIM(lcDocSavedTag)+laList[lnYY,1]
		          COPY FILE &lcDocTagFile TO &lcDocSavedTagFile
		          DELETE FILE &lcDocTagFile
		      NEXT 
		      EXIT 
		   ENDIF 
	    NEXT 
	    RD &lcDocTag
	ENDIF 
	*-------------  ChonRTS ---------------------------
	lcSQLLine="delete chon_rts..tbldocuments where npatientid=(select npatientid from chon_rts..tblpatients where smrn="+ALLTRIM(STR(lnLRSNo))+")"+;
    " and ntag="+ALLTRIM(STR(lnTag))
    oMed.sqlexecute(lcSQLLine)
    
    *-------------  tblDistToDo ---------------------------
    lcSQLLine="select * from tbldisttodo where lrs_no="+ALLTRIM(STR(lnLRSNo))+"and tag="+ALLTRIM(STR(lnTag))+" AND rectype='D1' and rem_Date is null"
    oMed.sqlexecute(lcSQLLine,"viewDistToDo")
    SELECT viewDistToDo
    IF RECCOUNT()=0      
       lcDSID=gfdsjobid()    
	   lcSQLLine="insert into tblDistToDo values(newid(), '"+alltrim(lcDSID)+"', "+ALLTRIM(STR(lnLRSNo))+", "+;
       ALLTRIM(STR(lnTag))+",'',0, '', null, null,getdate(), '"+ALLTRIM(TIME())+"', 1, null, null,null, 0, 'D1','"+;
       alltrim(goApp.CurrentUser.ntlogin)+"', '', null, null, null, null,0, null, null, 0, null,null,null,null,null,null,null,null,null, getdate(),'"+;
       alltrim(goApp.CurrentUser.ntlogin)+"',null,null,null,null,0,1,null,null,null)"
       oMed.sqlexecute(lcSQLLine)
       lcSQLLine="update tbldisttodo set rem_Date=getdate(), rem_by='"+alltrim(goApp.CurrentUser.ntlogin)+"' where lrs_no="+ALLTRIM(STR(lnLRSNo))+;
       "and tag="+ALLTRIM(STR(lnTag))+" and rem_Date is null"
       oMed.sqlexecute(lcSQLLine)
    ENDIF 
    USE IN viewJobs
    USE IN viewDistToDo    
    SELECT &lcFile  
ENDSCAN   
SELECT &lcFile   
USE  
gfMessage(lcMessage)
RETURN 
 
*--------------------------------------------------------------------------------------------------------------
FUNCTION getFileToReset
lnCurArea=SELECT()
lcDefault=SYS(5) + SYS(2003)
SET DEFAULT TO c:\temp
lcFile=GETFILE("XLS","Load Reset Soft Copy List")
SET DEFAULT TO &lcDefault
gfMessage("Please make sure the file is in format:  LRS#, Tag. Please no column headers.")
IF gfMessage("Continue?",.T.)=.F.
   RETURN ""
ENDIF 

lcFile="'"+ALLTRIM(lcFile)+"'" 
IMPORT FROM &lcFile xl5
lcFileName=DBF()
USE
lcFileName="'"+ALLTRIM(lcFileName)+"'"
USE &lcFileName ALIAS xlsFile EXCLUSIVE
SELECT (lnCurArea)
RETURN 'xlsFile'
*------------------------------------------------------------------------------
FUNCTION getSingleTagToReset
lnCurArea=SELECT()
lcDefault=SYS(5) + SYS(2003)
SET CLASSLIB TO UTILITY ADDITIVE
oLRSTag = CREATEOBJECT("utility.frmGetLrsTag", "S")	
* show the form in modal
oLRSTag.SHOW			 			
* when the form returns to code, grab the values
lnLrsNo=oLRSTag.lnLrsNo
lnTag=oLRSTag.lnTag	
RELEASE oLRSTag				
CREATE CURSOR xlsFile (a n(10), b n(4))
INSERT INTO xlsFile values(lnLrsNo, lnTag)
		
SELECT (lnCurArea)
RETURN 'xlsFile'