*********************************************************************************************
*Global Tag cancellation 
*********************************************************************************************
LOCAL lnCurArea, lcDefault, lcFile, llCharge, llPrint, lcFileName, lcComment21, lcComment77, lcLRSNo, lcTag, lcSQLLine
lnCurArea=SELECT()
lcDefault=SYS(5) + SYS(2003)
SET DEFAULT TO c:\temp
lcFile=GETFILE("XLS","Load Cancel List")
SET DEFAULT TO &lcDefault
gfMessage("Please make sure the file is in format:  LRS#, Tag, Comment21, Comment77. Please no column headers.")
IF gfMessage("Continue?",.T.)=.F.
   RETURN 
ENDIF 
llCharge=gfMessage("Add attorney cancellation charge?",.T.)
llPrint=gfMessage("Print cancellation lettter?",.T.)
oMed=createobject("generic.medgeneric")  
lcFile="'"+ALLTRIM(lcFile)+"'" 
IMPORT FROM &lcFile xl5
lcFileName=DBF()
USE
lcFileName="'"+ALLTRIM(lcFileName)+"'"
USE &lcFileName ALIAS xlsFile EXCLUSIVE
ALTER TABLE xlsFile ADD COLUMN comment c(100)
SELECT xlsFile
GO TOP 
lcComment21=''
lcComment77=''
FOR lnII=1 TO AFIELDS(laFlds)
    IF ALLTRIM(UPPER(laFlds[lnII,1]))=="C"
       lcComment21=xlsFile.c
    ENDIF 
    IF ALLTRIM(UPPER(laFlds[lnII,1]))=="D"
       lcComment77=xlsFile.d
    ENDIF 
NEXT  
plZPrintWasSelected = llPrint
plZDontAskPrintQuestion = .T.  
SCAN   
   lcLRSNo=xlsFile.a
   lcTag=xlsFile.b  
   WAIT WINDOW "Processing "+ALLTRIM(STR(lcLRSNo))+"."+ALLTRIM(STR(lcTag)) NOWAIT NOCLEAR 
   SELECT 0
   lcSQLLine="exec dbo.globalCancellationAttyList "+ALLTRIM(STR(lcLRSNo))+", "+ALLTRIM(STR(lcTag))
   oMed.sqlexecute(lcSQLLine,"viewAtList")
   SELECT 0
   lcSQLLine="exec globalTagCancellation "+ALLTRIM(STR(lcLRSNo))+", "+ALLTRIM(STR(lcTag))+", '"+;
   ALLTRIM(goApp.CurrentUser.ntlogin)+"', '"+ALLTRIM(fixquote(lcComment21))+"'"
   oMed.sqlexecute(lcSQLLine,"viewClCode")
   SELECT viewCLCOde
   IF RECCOUNT()=0
      USE IN viewCLCode
      SELECT xlsFile 
      replace comment WITH "Unable to update tables"
      LOOP
   ENDIF 
   * add txn 21 (one per tag), change request status, add coments if needed   
   IF llCharge=.T.	   
	   SELECT viewAtList
	   IF RECCOUNT()>0
	      * add txn 77 one per ordering attorney
	      SCAN FOR !EMPTY(ALLTRIM(NVL(viewAtList.at_code,"")))  
	            * add txn 77 one per ordering attorney
	            
	           lnCancelCharge=gfcanfee(viewCLCode.cl_code, lcTag, viewAtList.at_code)                             
	           lcSQLLine="Exec dbo.gfAddTxn4 '"+DTOC(DATE())+"', 'CANCEL', '"+ALLTRIM(UPPER(viewClCode.cl_code))+"', 77, "+;
	           ALLTRIM(STR(lcTag))+", '"+ALLTRIM(UPPER(viewClCode.mailid_no))+"', 0, 4,'',0,'','"+ALLTRIM(UPPER(viewClCode.type))+"', "+;
	           "'(GC)"+ALLTRIM(goApp.CurrentUser.ntlogin)+"', '"+ALLTRIM(viewCLCode.id_Tblrequests)+"', "+;
	           "'"+ALLTRIM(viewAtList.at_code)+"', "+ALLTRIM(STR(lnCancelCharge,10,4))
	           oMed.sqlexecute(lcSQLLine, "viewTSID")
	           * cancel orders
	           lcSQLLine="Exec dbo.cancelOrderByLRSTagAtCode "+ALLTRIM(STR(lcLRSNo))+", "+ALLTRIM(STR(lcTag))+", '"+;
			   ALLTRIM(goApp.CurrentUser.ntlogin)+"', '"+ALLTRIM(viewAtList.at_code)+"'"
	           oMed.sqlexecute(lcSQLLine)
	           
	           IF !EMPTY(ALLTRIM(lcComment77))
	               lcSQLLine="exec dbo.gfAddCom '"+DTOC(DATE())+"', 'CANCEL', '"+ALLTRIM(UPPER(viewClCode.cl_code))+"', 77, "+;
	               ALLTRIM(STR(lcTag))+", '"+ALLTRIM(UPPER(viewClCode.mailid_no))+"', 0,'"+ALLTRIM(lcComment77)+"', "+;
	               "'(GC)"+ALLTRIM(goApp.CurrentUser.ntlogin)+"', '"+ALLTRIM(viewTSID.id_Tbltimesheet)+"'"
	               oMed.sqlexecute(lcSQLLine)
	           ENDIF 
	           SELECT viewAtList
	      ENDSCAN            
	   ENDIF 
	ENDIF 
    
   IF viewCLCOde.status="W" AND EMPTY(ALLTRIM(NVL(viewCLCOde.hstatus,"")))     
      IF llPrint=.T.    
	      *-------------  Print Letter ------------------------      
	      pl_GotCase=.F.
	      pl_GotDep=.F.
	      lcSQLLine="select * from tblmaster where cl_code='"+ALLTRIM(viewCLCOde.cl_code)+"' and active=1"
	      oMed.sqlexecute(lcSQLLine,"MASTER")
	      DO gfGetCas
	      DO gfGetDep WITH viewCLCOde.cl_code,lcTag
	      DO PrintCan WITH viewCLCOde.cl_code, lcTag, .T., .T.
	      SELECT xlsFile 
	      replace comment WITH "The records were successfully updated; Cancellation letter was printed"
	  ELSE 
	      SELECT xlsFile 
	      replace comment WITH "The records were successfully updated;"
	  ENDIF
   ELSE 
      SELECT xlsFile 
	  replace comment WITH "Status - "+ALLTRIM(viewCLCOde.status)+IIF(EMPTY(ALLTRIM(NVL(viewCLCOde.hstatus,""))),"", ;
	  "; hstatus - "+ALLTRIM(NVL(viewCLCOde.hstatus,""))) 
   ENDIF
   USE IN viewCLCOde
   SELECT xlsFile 
ENDSCAN    
lcFile=STRTRAN(UPPER(ALLTRIM(lcFile)),".XLS","Up.xls")
COPY TO &lcFile TYPE xl5
USE IN xlsFile 
gfmessage("Result file is saved as "+ALLTRIM(lcFile))
IF NOT USED('C_MEDUSER')
IF NOT EMPTY(pc_UseriD)
	loCurrentUser = CREATEOBJECT("Security.MedUser")	
	loCurrentUser.GetItem(NULL)

ENDIF
ENDIF
		
WAIT CLEAR 
SELECT (lnCurArea)	   