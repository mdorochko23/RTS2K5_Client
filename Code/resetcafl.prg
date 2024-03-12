*------------------------------------------------------------------------------------
* CA Silica First Look release imitation proccess
* The program updates status of tblRequest back to "W" 
*------------------------------------------------------------------------------------
LOCAL lnCurArea, lnLrsNo, lnTag, lcFlDocsIn, lcFlDocsOut, lnPatID, lnPages, lnYY
lnCurArea=SELECT()
SET CLASSLIB TO UTILITY ADDITIVE

oMed=createobject("generic.medgeneric")     
oLRSTag = CREATEOBJECT("utility.frmGetLrsTag", "F2")	
oLRSTag.SHOW			 			
lnLrsNo=oLRSTag.lnLrsNo
lnTag=oLRSTag.lnTag	
RELEASE oLRSTag	
IF lnLRSNo=0
   RETURN 
ENDIF    

lcSQLLine="update tblRequest set status='W' where cl_code=(select dbo.getclcodebylrs("+ALLTRIM(STR(lnLrsNo))+")) and tag="+ALLTRIM(STR(lnTag))+;
" and active=1 and status='F'"
oMed.sqlexecute(lcSQLLine)

gfMessage("Done")
RETURN 
