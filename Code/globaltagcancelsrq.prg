*********************************************************************************************
*Global Tag cancellation SRQ Only
*********************************************************************************************
LOCAL lnCurArea, lcDefault, lcFile, llCharge, llPrint, lcFileName, lcComment21, lcComment77, lcLRSNo, lcTag, lcSQLLine, llCancelOrder
lnCurArea=SELECT()
*!*	lcDefault=SYS(5) + SYS(2003)
*!*	SET DEFAULT TO c:\temp
*!*	*lcFile=GETFILE("XLS","Load Cancel List")
*!*	SET DEFAULT TO &lcDefault
*!*	gfMessage("Please make sure the file is in format:  LRS#, Tag, Comment21, Comment77. Please no column headers.")
*!*	IF gfMessage("Continue?",.T.)=.F.
*!*	   RETURN 
*!*	ENDIF 
*!*	llCharge=gfMessage("Add attorney cancellation charge?",.T.)
*!*	llPrint=gfMessage("Print cancellation lettter?",.T.)
*!*	llCancelOrder=gfMessage("Cancel Orders?",.T.)
oMed=createobject("generic.medgeneric")  
*!*	*lcFile="'"+ALLTRIM(lcFile)+"'" 
*!*	*!*	IMPORT FROM &lcFile xl5
*!*	*!*	lcFileName=DBF()
*!*	*!*	USE
*!*	*!*	lcFileName="'"+ALLTRIM(lcFileName)+"'"
*!*	lcFileName="c:\rts2k5\client\cancellist1.dbf"
*!*	USE &lcFileName ALIAS xlsFile EXCLUSIVE
*!*	*!*	ALTER TABLE xlsFile ADD COLUMN comment c(100)
*!*	*!*	ALTER TABLE xlsFile ADD COLUMN printcan l
*!*	*!*	ALTER TABLE xlsFile ADD mailid_no c(10)
*!*	*!*	ALTER TABLE xlsFile ADD dept c(1)
*!*	*!*	ALTER TABLE xlsFile ADD cl_code c(10)
*!*	*!*	ALTER TABLE xlsFile ADD tag n(3)
*!*	*!*	ALTER TABLE xlsFile ADD txn7 d
*!*	*!*	ALTER TABLE xlsFile ADD Checkno c(10)
*!*	SELECT xlsFile
*!*	GO TOP 
*!*	lcComment21=''
*!*	lcComment77=''
*!*	FOR lnII=1 TO AFIELDS(laFlds)
*!*	    IF ALLTRIM(UPPER(laFlds[lnII,1]))=="C"
*!*	       lcComment21=xlsFile.c
*!*	    ENDIF 
*!*	    IF ALLTRIM(UPPER(laFlds[lnII,1]))=="D"
*!*	       lcComment77=xlsFile.d
*!*	    ENDIF 
*!*	NEXT  
*!*	*  Check if the first case is SRQ   
*!*	SELECT xlsFile
*!*	GO top
*!*	*!*	lcSQLLine="select litigation from tblmaster where lrs_no="+ALLTRIM(STR(xlsFile.a))+" and active=1 "
*!*	*!*	oMed.sqlexecute(lcSQLLine,"viewSRQLit")
*!*	*!*	SELECT viewSRQLit
*!*	*!*	IF RECNO()=0 OR ALLTRIM(UPPER(litigation))<>'SRQ'
*!*	*!*	   gfmessage("This program was design for SRQ litigation only")
*!*	*!*	   RETURN 
*!*	*!*	ENDIF    
*!*	SCAN   
*!*	   lcLRSNo=xlsFile.a
*!*	   lcTag=xlsFile.b    
*!*	   WAIT WINDOW "Processing "+ALLTRIM(STR(lcLRSNo))+"."+ALLTRIM(STR(lcTag)) NOWAIT NOCLEAR 
*!*	   SELECT 0
*!*	   lcSQLLine="exec dbo.globalCancellationAttyList "+ALLTRIM(STR(lcLRSNo))+", "+ALLTRIM(STR(lcTag))
*!*	   oMed.sqlexecute(lcSQLLine,"viewAtList")
*!*	   SELECT 0
*!*	   * add txn 21 (one per tag), change request status, add coments if needed   
*!*	   lcSQLLine="exec globalTagCancellationSRQ "+ALLTRIM(STR(lcLRSNo))+", "+ALLTRIM(STR(lcTag))+", '"+;
*!*	   ALLTRIM(goApp.CurrentUser.ntlogin)+"', '"+ALLTRIM(fixquote(lcComment21))+"'"
*!*	   oMed.sqlexecute(lcSQLLine,"viewClCode")
*!*	   SELECT viewCLCOde
*!*	   IF RECCOUNT()=0
*!*	      USE IN viewCLCode
*!*	      SELECT xlsFile 
*!*	      replace comment WITH "Unable to update tables"
*!*	      LOOP
*!*	   ENDIF 
*!*	   
*!*	   IF llCharge=.T. and viewCLCode.status="W"	   
*!*		   SELECT viewAtList
*!*		   IF RECCOUNT()>0
*!*		      * add txn 77 one per ordering attorney
*!*		      SCAN FOR !EMPTY(ALLTRIM(NVL(viewAtList.at_code,"")))  
*!*		            * add txn 77 one per ordering attorney
*!*		            
*!*		           lnCancelCharge=gfcanfee(viewCLCode.cl_code, lcTag, viewAtList.at_code)                             
*!*		           lcSQLLine="Exec dbo.gfAddTxn4 '"+DTOC(DATE())+"', 'CANCEL', '"+ALLTRIM(UPPER(viewClCode.cl_code))+"', 77, "+;
*!*		           ALLTRIM(STR(lcTag))+", '"+ALLTRIM(UPPER(viewClCode.mailid_no))+"', 0, 4,'',0,'','"+ALLTRIM(UPPER(viewClCode.type))+"', "+;
*!*		           "'(GCSRQ)"+ALLTRIM(goApp.CurrentUser.ntlogin)+"', '"+ALLTRIM(viewCLCode.id_Tblrequests)+"', "+;
*!*		           "'"+ALLTRIM(viewAtList.at_code)+"', "+ALLTRIM(STR(lnCancelCharge,10,4))
*!*		           oMed.sqlexecute(lcSQLLine, "viewTSID")
*!*		           
*!*		           * cancel orders
*!*		           IF llCancelOrder=.T.
*!*		              lcSQLLine="Exec dbo.cancelOrderByLRSTagAtCode "+ALLTRIM(STR(lcLRSNo))+", "+ALLTRIM(STR(lcTag))+", '(GCSRQ)"+;
*!*				      ALLTRIM(goApp.CurrentUser.ntlogin)+"', '"+ALLTRIM(viewAtList.at_code)+"'"
*!*		              oMed.sqlexecute(lcSQLLine)
*!*		           ENDIF 
*!*		           
*!*		           IF !EMPTY(ALLTRIM(lcComment77))
*!*		               lcSQLLine="exec dbo.gfAddCom '"+DTOC(DATE())+"', 'CANCEL', '"+ALLTRIM(UPPER(viewClCode.cl_code))+"', 77, "+;
*!*		               ALLTRIM(STR(lcTag))+", '"+ALLTRIM(UPPER(viewClCode.mailid_no))+"', 0,'"+ALLTRIM(lcComment77)+"', 0,"+;
*!*		               "'(GCSRQ)"+ALLTRIM(goApp.CurrentUser.ntlogin)+"', '"+ALLTRIM(viewTSID.id_Tbltimesheet)+"'"
*!*		               oMed.sqlexecute(lcSQLLine)
*!*		           ENDIF 
*!*		           SELECT viewAtList
*!*		      ENDSCAN            
*!*		   ENDIF 
*!*		ENDIF 
*!*	    
*!*	   IF viewCLCOde.status="W" AND EMPTY(ALLTRIM(NVL(viewCLCOde.hstatus,"")))     
*!*	      IF llPrint=.T.    
*!*		      *-------------  Print Letter ------------------------      
*!*		      ldTxn7={}
*!*		      lnCheck=""
*!*		      oMed.sqlexecute("select txn_Date, wit_fee,[count] from tblTimeSheet where cl_code='"+FIXQUOTE(viewClCode.cl_code)+;
*!*		      "' and tag='"+ALLTRIM(STR(lcTag))+"' and txn_code=7 and deleted is null order by txn_Date", "viewTimeSheet")
*!*			  SELECT viewTimeSheet
*!*	 		  SCAN FOR viewTimeSheet.wit_fee>0	  	     
*!*				   ldTxn7=viewTimeSheet.txn_date
*!*				   lnCheck=IIF(NVL(viewTimeSheet.count,0)>0,ALLTRIM(STR(viewTimeSheet.count)),"CreditCard")
*!*			  ENDSCAN
*!*		      SELECT xlsFile 
*!*		      replace printcan WITH .T., mailid_no WITH ALLTRIM(UPPER(NVL(viewClCode.mailid_no,''))), ;
*!*		      dept WITH ALLTRIM(UPPER(NVL(viewClCode.department,""))), cl_code WITH ALLTRIM(UPPER(NVL(viewClCode.cl_code,""))), tag WITH lcTag,;
*!*		      txn7 with NVL(ldTxn7,{}), Checkno WITH lnCheck
*!*		      *-----------------------------------------------------
*!*		  ELSE 
*!*		      SELECT xlsFile 
*!*		      replace comment WITH "The records were successfully updated;"
*!*		  ENDIF
*!*	   ELSE 
*!*	      SELECT xlsFile 
*!*		  replace comment WITH "Status - "+ALLTRIM(viewCLCOde.status)+IIF(EMPTY(ALLTRIM(NVL(viewCLCOde.hstatus,""))),"", ;
*!*		  "; hstatus - "+ALLTRIM(NVL(viewCLCOde.hstatus,""))) 
*!*	   ENDIF
*!*	   USE IN viewCLCOde
*!*	   SELECT xlsFile 
*!*	ENDSCAN    
USE t:\cancelsrq\srqlist2.DBF ALIAS xlsFile
SET ORDER TO MID   && ALLTRIM(UPPER(MAILID_NO))+"*"+ALLTRIM(UPPER(DEPT))
DO printCanLetter
SELECT xlsFile
*!*	COPY TO c:\temp\srqcancel WITH prod 
*!*	lcFile=STRTRAN(UPPER(ALLTRIM(lcFile)),".XLS","Up.xls")
*!*	COPY TO &lcFile TYPE xl5
*!*	USE IN xlsFile 
*!*	gfmessage("Result file is saved as "+ALLTRIM(lcFile))
gfmessage("Done")
WAIT CLEAR 
SELECT (lnCurArea)	   



*------------------------------------------------
PROCEDURE printCanLetter
LOCAL lnCurArea
lnCurArea=SELECT()
lcProcedure = SET("Procedure")
SET PROCEDURE TO GLOBAL ADDITIVE
LOCAL n_faxno, c_fax, c_PrintQ, lcLtr, l_continue                                
LOCAL lcLtr, lcAction, lnWorkArea
LOCAL lcDesc, lcAttn, lcAdd1, lcAdd2, lcCity, lcState, lcZip, llSpecIns
lnFaxQue=9
lnPrintQue=4
lnFaxCnt=0
lnPrintCnt=0
SELECT xlsFile
*INDEX ON ALLTRIM(UPPER(mailid_no))+"*"+ALLTRIM(UPPER(dept)) TAG mid
GO TOP 
DO WHILE !EOF()
   lcMailId=ALLTRIM(UPPER(xlsFile.mailid_no))
   IF !EMPTY(ALLTRIM(NVL(lcMailId,""))) AND EMPTY(ALLTRIM(printque))
	   lcDept=ALLTRIM(UPPER(dept))
	   lcLtr = ""
	   lcDept=NVL(lcDept,"")
	   IF SUBSTR(lcMailId, 1, 1) <> "H"		
	      lcDept=''
	   ENDIF    
	   lcDesc = ALLTRIM(NVL(xlsFile.DESCRIPT,""))
	   DO setDeponentInfo WITH lcDept, lcMailID 	  
	   lcAttn =pc_MAttn
	   lcAdd1 = pc_MAdd1
	   lcAdd2 = pc_MAdd2
	   lcCity = pc_MailCity
	   lcZip = pc_MailZip
	   lcState = pc_MailSt
	   IF EMPTY(lcAttn)
		  lcAttn = SPACE(30)
	   ENDIF
	   n_faxno = pn_MailFax	
	   IF TYPE("n_faxno")="C"
          c_fax= ALLTRIM(n_faxno)          
	   ELSE
	      c_fax= ALLTRIM(STR(n_faxno))
	   ENDIF			   
	   IF LEN(ALLTRIM(NVL(c_fax,"")))=10  AND LEFT(ALLTRIM(NVL(c_fax,"")),2)<>"00";
	   AND LEFT(ALLTRIM(NVL(c_fax,"")),2)<>"11" AND LEFT(ALLTRIM(NVL(c_fax,"")),2)<>"01";
	   AND LEFT(ALLTRIM(NVL(c_fax,"")),2)<>"0 " AND LEFT(ALLTRIM(NVL(c_fax,"")),2)<>"1 ";
	   AND LEFT(ALLTRIM(NVL(c_fax,"")),2)<>"05" 		  
	      lnFaxCnt=lnFaxCnt+1
	      IF lnFaxCnt>4000
	         lnFaxCnt=1
	         lnFaxQue=lnFaxQue+1
	      ENDIF    
	  	  c_PrintQ="SRQFax"+PADL(ALLTRIM(STR(lnFaxQue)),3,"0")
	   ELSE
	      lnPrintCnt=lnPrintCnt+1
	      IF lnPrintCnt>4000
	         lnPrintCnt=1
	         lnPrintQue=lnPrintQue+1
	      ENDIF  
	      c_PrintQ="SRQCan"+PADL(ALLTRIM(STR(lnPrintQue)),3,"0")
	   ENDIF
	   * first page with dep info
	   DO lfPrnRps WITH lcLtr, lcDesc, lcAdd1, lcAdd2, lcCity, lcState, lcZip, lcAttn, 1
	   
	   * second page with list of cases
	   DO PrintGroup WITH lcLtr, "CancelSRQ"
	   *DO PrintGroup WITH lcLtr, "Item"
	   DO lfPrnRps WITH lcLtr, lcDesc, lcAdd1, lcAdd2, lcCity, lcState, lcZip, lcAttn, 2	   
	   DO printfield WITH lcLtr, "Loc",	"P"
	   *DO PrintField WITH lcLtr, "ControlDate", DTOC(DATE())
	   DO PrintGroup WITH lcLtr,"Control"
	   DO printfield WITH lcLtr,"Date", DTOC(DATE())
       
	   SELECT xlsFile
	   lcDept=xlsFile.dept
	   lnDepCntr=0
	   DO WHILE !EOF() AND ALLTRIM(UPPER(mailid_no))==ALLTRIM(UPPER(lcMailId)) AND ALLTRIM(UPPER(dept))==ALLTRIM(UPPER(lcDept))       
	       pl_GotCase=.F.	      
	       lnDepCntr=lnDepCntr+1
	       IF lnDepCntr>200
	            DO PrtEnQ_2 WITH lcLtr, c_PrintQ, "1", c_fax,lcMailID,0,ALLTRIM(goApp.CurrentUser.ntlogin)
	            lcLtr=""
	            lnDepCntr=0
	          	DO PrintGroup WITH lcLtr, "CancelSRQ"
	   			*DO PrintGroup WITH lcLtr, "Item"
	   			DO lfPrnRps WITH lcLtr, lcDesc, lcAdd1, lcAdd2, lcCity, lcState, lcZip, lcAttn, 2	   
	   			DO printfield WITH lcLtr, "Loc",	"P"
	   			*DO PrintField WITH lcLtr, "ControlDate", DTOC(DATE())
	   			DO PrintGroup WITH lcLtr,"Control"
	   			DO printfield WITH lcLtr,"Date", DTOC(DATE())
	  	   ENDIF 
	       lcSQLLine="select * from tblmaster where cl_code='"+ALLTRIM(xlsFile.cl_code)+"' and active=1"
	       oMed.sqlexecute(lcSQLLine,"MASTER")       
	       DO gfGetCas       
*!*		       lcSQLLine="select * from tblrequest where cl_code='"+ALLTRIM(xlsFile.cl_code)+"' and tag="+ALLTRIM(STR(xlsFile.tag))+" and active=1"
*!*		       oMed.sqlexecute(lcSQLLine,"record")   	       
		   gnWFee = NVL(xlsFile.wit_fee,0)
		   gcCl_code =NVL(xlsFile.cl_code,"")
		   ldReqDate=NVL(TTOD(xlsFile.req_date),{})
		   ldTxn7=NVL(xlsFile.txn7DATE,{})
		   lcSocSec=alltrim(STRTRAN(NVL(master.soc_sec,""),"-",""))
		   IF LEN(ALLTRIM(lcSocSec))=9
		      lcSocSec="###-##-"+RIGHT(ALLTRIM(lcSocSec),4)
		   ELSE 
		      lcSocSec=""
		   ENDIF    
	       DO PrintGroup WITH lcLtr, "Item"
	       
		   
		   DO PrintField WITH lcLtr, "Col1", ALLTRIM( STR(xlsFile.LRS_NO))
		   DO PrintField WITH lcLtr, "Col2", ALLTRIM(STR(xlsFile.TAG))
		   DO PrintField WITH lcLtr, "Col3", ALLTRIM(master.name_first)+" "+ALLTRIM(master.name_last)
		   DO PrintField WITH lcLtr, "Col4", DTOC(master.brth_date)
		   DO PrintField WITH lcLtr, "Col5", lcSocSec
		   DO PrintField WITH lcLtr, "Col6", IIF(EMPTY(ldReqDate),"",ldReqDate)
		   DO PrintField WITH lcLtr, "Col7", IIF(gnWFee=0,"",ALLTRIM(STR(gnWFee,10,2)))	   
		   DO PrintField WITH lcLtr, "Col8", IIF(EMPTY(ldTxn7),"",ldTXN7)	
		   DO PrintField WITH lcLtr, "Col9", IIF(EMPTY(NVL(xlsFile.checkno,"")),"",xlsFile.checkno)	   
		   	
		   SELECT xlsFile 
		   *replace comment WITH "The records were successfully updated; Cancellation letter was printed"
		   replace printque WITH c_PrintQ
	       SKIP 
	   ENDDO 
	   DO PrtEnQ_2 WITH lcLtr, c_PrintQ, "1", c_fax,lcMailID,0,ALLTRIM(goApp.CurrentUser.ntlogin)
   ELSE 
      SELECT xlsFile
      SKIP
   ENDIF 
         
   SELECT xlsFile
ENDDO    
select (lnCurArea)			
RETURN 
			
			

*----------------------------------------------------------------------------
* return valid date string
*----------------------------------------------------------------------------
FUNCTION lfValDate
	PARAMETER lcDate
	PRIVATE lcValid
	IF TYPE("lcDate")="C"
		IF ! EMPTY(CTOD(NVL(lcDate,"")))
			lcValid = DTOC(CTOD(lcDate))
		ELSE
			lcValid = " "
		ENDIF
	ENDIF
	IF INLIST(TYPE("lcDate"),"D","T")
		IF !EMPTY(NVL(lcDate,{}))
			lcValid = DTOC(lcDate)
		ELSE
			lcValid=""
		ENDIF
	ENDIF
	RETURN lcValid

	*----------------------------------------------------------------------------
	* set up common fields in the cancel letter
	*----------------------------------------------------------------------------
PROCEDURE lfCommon
	PARAMETER lcLtr2, ldCanDate, lcLitigation, lcAcctMgr
	PRIVATE lcName, lcPhone, c_offlocation
	c_offlocation=""
	*EF 02/28/02 Do not ask for TX checks for $1.00.
	
	DO PrintGroup WITH lcLtr2, "CancelListSRQ"
	DO printfield WITH lcLtr2, "Line1", IIF(lcLitigation='SRQ',"","This request is being cancelled.")
	DO printfield WITH lcLtr2, "Line2", IIF(lcLitigation='SRQ',"","For that reason, no additional fees can be accepted.")		
	DO printfield WITH lcLtr2, "Line3", IIF(lcLitigation='SRQ',"The records are currently not needed, but RecordTrak will contact you should the situation change.","")
						
    l_GetRps= Acdamnumber (lcAcctMgr)
	IF l_getrps
	   c_offlocation= IIF(ISNULL(LitRps.RpsOffCode), 'P', LitRps.RpsOffCode)		    
    endif	
					
	DO printfield WITH lcLtr2, "Loc",	c_offlocation		

	* --- do not use acc mgr. fixed for cancel letter ---
	lcName = "RecordTrak Representative"
	
	lcPhone = IIF(lcLitigation='SRQ',"1-888-801-7649","1-800-220-1291")
	

	DO PrintGroup WITH lcLtr2,"Control"

	IF EMPTY(ldCanDate)
		DO printfield WITH lcLtr2,"Date", DTOC(DATE())
	ELSE
		DO printfield WITH lcLtr2,"Date", DTOC(ldCanDate)
	ENDIF


	DO PrintGroup WITH lcLtr2, "Contact"
	DO printfield WITH lcLtr2, "Name", lcName
	DO printfield WITH lcLtr2, "Phone", lcPhone
	RETURN
	*----------------------------------------------------------------------------
	* print to RPS
	*----------------------------------------------------------------------------
PROCEDURE lfPrnRps
	PARAMETER lcLtr1, lcDesc, lcAdd1, lcAdd2, lcCity, lcState, lcZip, ;
		lcAttn, lnPage
    if lnPage=1
	   DO lfCommon WITH lcLtr1,DATE(), "SRQ", "SARAH"
	ENDIF 
	
	DO PrintGroup WITH lcLtr1, "Deponent"
	DO printfield WITH lcLtr1, "Name", lcDesc
	DO printfield WITH lcLtr1, "Addr", ;
		IIF(EMPTY(lcAdd2), lcAdd1, lcAdd1+CHR(13) + lcAdd2)
	DO printfield WITH lcLtr1, "City", lcCity
	DO printfield WITH lcLtr1, "State", lcState
	DO printfield WITH lcLtr1, "Zip", lcZip
	DO printfield WITH lcLtr1, "Extra", IIF(ISNULL(lcAttn),'',lcAttn)	
	
	RETURN
*--------------------------------------------------------------------------------------------------------------
PROCEDURE setDeponentInfo
LPARAMETERS plcDept, plcMailID
LOCAL n_dec
PUBLIC c_MAdd1, pc_MAdd2, pc_MailCity, pc_MailSt, ;
	pc_MailZip, pc_FaxSub, pc_FaxAuth, pc_GovtLoc, pc_MailFName, ;
	pc_MailLName, pc_RadDpt, pc_PathDpt, pc_EchoDpt, pc_EFaxSub, ;
	pc_EFaxAuth, pc_PFaxSub, pc_PFaxAuth, pc_RFaxSub, pc_RFaxAuth, ;
	pc_BFaxSub, pc_BFaxAuth, pc_MAttn, pc_BatchRq, pn_MailPhn, ;
	pn_MailFax, pn_RadFax, pn_PathFax, ;
	pn_EchFax, pn_BillFax, pl_MailFax, pl_FaxOrig, pl_EFax, pl_EFaxOrg, ;
	pl_PFax, pl_PFaxOrg, pl_RFax, pl_RFaxOrg, pl_BfaxOrg, ;
	pl_CallOnly, pl_MCall, pl_BCall, pl_PCall, pl_RCall, ;
	pl_ECall
	
STORE "" TO pc_MAdd1, pc_MAdd2, pc_MailCity, pc_MailSt, ;
	pc_MailZip, pc_FaxSub, pc_FaxAuth, pc_GovtLoc, pc_MailFName, ;
	pc_MailLName, pc_RadDpt, pc_PathDpt, pc_EchoDpt, pc_EFaxSub, ;
	pc_EFaxAuth, pc_PFaxSub, pc_PFaxAuth, pc_RFaxSub, pc_RFaxAuth, ;
	pc_BFaxSub, pc_BFaxAuth, pc_MAttn, pc_BatchRq
STORE 0 TO pn_MailPhn, pn_MailFax, pn_RadFax, pn_PathFax, ;
	pn_EchFax, pn_BillFax
STORE .F. TO pl_MailFax, pl_FaxOrig, pl_EFax, pl_EFaxOrg, ;
	pl_PFax, pl_PFaxOrg, pl_RFax, pl_RFaxOrg, pl_BfaxOrg, ;
	pl_CallOnly, pl_MCall, pl_BCall, pl_PCall, pl_RCall, ;
	pl_ECall

IF USED("viewDepoFile")
   USE IN viewDepoFile
ENDIF    

IF NOT EMPTY(ALLTRIM(NVL(plcMailID,"")))
	oMed.sqlexecute("exec dbo.GetDepInf '"+plcMailID+"'", "viewDepoFile")

	SELECT viewDepoFile

	IF TYPE('plcDept')='C' 
	IF plcDept<>"Z" AND !EMPTY(plcDept) AND UPPER( LEFT(plcMailID, 1))="H"
		LOCAL lnXXX, lcField
		lcField=""
		=AFIELDS(laDeptFlds)
		FOR lnXXX=1 TO ALEN(laDeptFlds,1)
			IF ALLTRIM(UPPER(laDeptFlds[lnXXX,1]))=="DEPT_CODE"
				lcField="DEPT_CODE"
			ENDIF
			IF ALLTRIM(UPPER(laDeptFlds[lnXXX,1]))=="DEPTCODE"
				lcField="DEPTCODE"
			ENDIF
			IF ALLTRIM(UPPER(laDeptFlds[lnXXX,1]))=="CODE"
				lcField="CODE"
			ENDIF
		NEXT
		IF !EMPTY(ALLTRIM(lcField))
			LOCATE FOR &lcField= plcDept
			IF NOT FOUND()
			**EF 3/20/07- make sure it finds master record.
			 LOCATE FOR &lcField= 'Z'
			endif

        endif
		ENDIF
	ENDIF
	pc_MailDesc = NAME
	pc_MAdd1    = Add1
	pc_MAdd2    = Add2
	pc_MailCity = City
	pc_MailSt   = State
	pc_MailZip  = Zip
	n_dec=SET('DECIMALS')
	SET DECIMALS TO 0
	pn_MailPhn  = IIF(TYPE('Phone')='N',Phone,VAL(Phone))
	SET DECIMALS TO n_dec
	***11/29/07 - DO NOT FAX WHEN A BATCH REQUEST'S MAIL ID IS USED
	l_oK=oMed.sqlexecute("SELECT  dbo.GetRpsQueueName('" + plcMailID + "')", "RPSQ")
	IF l_oK
	 pc_BatchRq =ALLTRIM(NVL(RpsQ.exp,""))
	 SELECT viewDepoFile
	ENDIF
	pl_FaxOrig  = IIF(EMPTY(pc_BatchRq),FaxOrig,.f.)
	pc_FaxSub   = IIF(EMPTY(pc_BatchRq),Fax_Sub,"")
	pc_FaxAuth  = IIF(EMPTY(pc_BatchRq),Fax_Auth,"")		
	pn_MailFax  = IIF(EMPTY(pc_BatchRq),Fax_no,0)
	pl_MailFax  = IIF(EMPTY(pc_BatchRq),Fax,.F.)
	
	pc_GovtLoc  = Govt
	pl_CallOnly = Callonly

	pc_MailFName = NAME
	pc_MailLName = ""
	pc_MAttn     = ALLTRIM( attn)


	pc_RadDpt   = ""
	pc_PathDpt  = ""
	pc_EchoDpt  = ""
	pn_RadFax   = IIF(EMPTY(pc_BatchRq),Fax_no,0)
	pn_PathFax  = IIF(EMPTY(pc_BatchRq),Fax_no,0)
	pn_EchFax   = IIF(EMPTY(pc_BatchRq),Fax_no,0)
	pl_EFax     = IIF(EMPTY(pc_BatchRq),Fax,.F.)
	pl_EFaxOrg  = IIF(EMPTY(pc_BatchRq),FaxOrig,.F.)
	pl_PFax     = IIF(EMPTY(pc_BatchRq),Fax,.F.)
	pl_PFaxOrg  = IIF(EMPTY(pc_BatchRq),FaxOrig,.F.)
	pl_RFax     = IIF(EMPTY(pc_BatchRq),Fax,.F.)
	pl_RFaxOrg  = IIF(EMPTY(pc_BatchRq),FaxOrig,.F.)
	pc_EFaxSub  = IIF(EMPTY(pc_BatchRq),Fax_Sub,"")
	pc_EFaxAuth = IIF(EMPTY(pc_BatchRq),Fax_Auth,"")
	pc_PFaxSub  = IIF(EMPTY(pc_BatchRq),Fax_Sub,"")
	pc_PFaxAuth = IIF(EMPTY(pc_BatchRq),Fax_Auth,"")
	pc_RFaxSub  = IIF(EMPTY(pc_BatchRq),Fax_Sub,"")
	pc_RFaxAuth = IIF(EMPTY(pc_BatchRq),Fax_Auth,"")
	pn_BillFax  = IIF(EMPTY(pc_BatchRq),Fax_no,0)
	pl_BfaxOrg  = IIF(EMPTY(pc_BatchRq),FaxOrig,.F.)
	pc_BFaxSub  = IIF(EMPTY(pc_BatchRq),Fax_Sub,"")
	pc_BFaxAuth = IIF(EMPTY(pc_BatchRq),Fax_Auth,"")
	pl_MCall    = Callonly
	pl_BCall    = Callonly
	pl_PCall    = Callonly
	pl_RCall    = Callonly
	pl_ECall    = Callonly
	



ENDIF

pl_Mail = .T.

RETURN
	