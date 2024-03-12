FUNCTION chkalikedep

PARAMETERS c_NewDepo, c_case
LOCAL l_retval as Boolean, lcSQLLine as String, oMedDep as Object
oMedDep = CREATEOBJECT("generic.medgeneric")
WAIT WINDOW "Check all alike deponents" NOWAIT NOCLEAR 
STORE .f. to  l_retval, pl_continue

pc_deponentID=""
*lcSQLLine="SELECT DESCRIPT , TAG, id_tblRequests,"+;
"dbo.fn_GetStatusDesc (Status, nrs_code, inc, hstatus, inprogress) as StatusName,"+;
"id_tbldeponents, mailid_no FROM tblRequest WHERE  cl_code='"+ALLTRIM(c_case)+;
"' and active=1"
lcSQLLine=" exec dbo.ChkAlikeDeponents '"+ALLTRIM(c_case)+ "'" 
oMedDep.sqlexecute(lcSQLLine,"viewDepList")   
SELECT viewDeplist
IF RECCOUNT()=0
   USE IN viewDeplist
   RETURN 
ENDIF 
   
SELECT descript as NAME , TAG, statusname, id_tblRequests, ;
id_tbldeponents, mailid_no, "" AS COMMENT FROM viewDepList ;
WHERE descript like UPPER(ALLTRIM(c_NewDepo)) + "%";
ORDER BY descript, TAG  INTO CURSOR Depolist
			
SELECT Depolist
IF RECCOUNT()=0
	l_retval=.t.
ENDIF    


IF RECCOUNT()>0
    
	=goApp.OpenForm("qcaipjobs.frmchkalikedep", "M",c_NewDepo,c_NewDepo)
	
	IF pl_continue		
		l_retval=.t.							
    ENDIF
ENDIF
RELEASE oMedDep
WAIT CLEAR 	

RETURN l_retval