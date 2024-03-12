*****************************************************************************************************************
*Adds txn 7, 37, 5,45,54,55,56,58,59,60  for a list of rt/tags
*****************************************************************************************************************


PARAMETERS C_FILE, n_crcd
LOCAL  OMED AS OBJECT,  n_minutes AS INTEGER, c_comment AS STRING, lnCurArea AS STRING, c_date AS STRING
LOCAL lbError as boolean,liErrCount as integer, lsErrMessage as string, liRowCnt as integer, liContinue as integer, liUserResp as integer	&& JOE
LOCAL lbSkipRow as boolean, lsRowError as string, liHeaderRec as integer
PUBLIC lnTotHeader as integer

liErrCount = 0
lsErrMessage = ""
liHeaderRec = 0
liRowCnt = 2
lnTotHeader = 0

c_date=""
l_ok =.F.
lnCurArea=ALIAS()
_SCREEN.MOUSEPOINTER=11
PRIVATE OMED AS OBJECT
OMED=CREATEOBJECT("generic.medgeneric")
SELECT 0
CREATE CURSOR Todo2 (err c(100), Lrs_No N(6), TAG N(4), txn7 N(8,2), txn37 N(8,2), txn5 n(6,2), txn45 c(4), txn54 c(4), txn55 c(4), ;
	txn56 c(4), txn58 c(4), txn59 c(4), txn60 c(4), Done L NULL)

lcTEMP=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","CTemp", "\")))
SELECT 0

** 4/30/2020, ZD #167546, JH.
**gfMessage("Please make sure the file is in format: Lrs_no, Tag, txn7, txn37.  Use zero(0) if you have no fee for txn7 or/and txn37, do not leave them blank.")	&& JOE
**IF gfMessage("Continue?",.T.)=.F.
**	 RETURN
**ENDIF

IF TYPE("PC_USERID")<>"C"
	PC_USERID=ALLTRIM(goApp.CurrentUser.orec.LOGIN)
ENDIF

C_FILE="'" +C_FILE + "'"
IF anEXCEL(&C_FILE)=.F.
	IF NOT EMPTY(lnCurArea)
		SELECT (lnCurArea)
	ENDIF
	WAIT WINDOW "Process cancelled."
	RETURN ""
ENDIF
if lnTotHeader <> 24
	gfMessage("Spreadsheet of transaction rows should have 12 columns and 2 rows of headers (see example template).")	
	RETURN
endif

SELECT anEXCEL
DELETE ALL FOR Lrs_No=0
GO TOP
DO CLEARTMP
IF  EOF()
	gfMessage( 'No rows/transactions in spreadsheet to process.' )		&& 4/30/2020, ZD #167546, JH.
	RETURN
ENDIF
IF  EMPTY(ALLTRIM(C_FILE))
	gfMessage( 'No Excel file selected.' )								&& 4/30/2020, ZD #167546, JH.
	RETURN
ENDIF

SELECT anEXCEL
USE

USE (lcTEMP+ "todo" + ".dbf") IN 0
SET DELETED ON

SELECT todo
SCAN
	liRowCnt = liRowCnt+1			&& 4/30/2020, ZD #167546, JH.
	lbError = .F.
    lsRowError = ""
	SCATTER MEMVAR
	STORE "" TO cRttodo, cTagtodo

	IF TYPE("todo.lrs_no")="N"
		cRttodo= ALLTRIM(STR(todo.Lrs_No))
	ELSE
		cRttodo= ALLTRIM(todo.Lrs_No)
	ENDIF

	IF NOT lbSkipRow
		IF TYPE("todo.tag")="N"
			cTagtodo=  ALLTRIM(STR(todo.TAG))
		ELSE
			cTagtodo=ALLTRIM(todo.TAG)
		ENDIF

		IF EMPTY(cTagtodo) OR EMPTY(cRttodo)
			lbError = .T.
			liErrCount = liErrCount+1			&& 4/30/2020, ZD #167546, JH.
			lsRowError = "Invalid tag number. "
			lsErrMessage = lsErrMessage+"Row "+str(liRowCnt)+" : Invalid tag number."+chr(13)+chr(10)
		ELSE									&& 04/30/2020, ZD #167546, JH.
			c_sql = "SELECT COUNT(*) as cntrecs FROM Recordtrak..tblRequest where cl_code = dbo.getClCodeByLrs("+cRtToDo+") and tag="+cTagToDo+" and active=1"
			l_ok =OMED.SQLEXECUTE(c_sql,"ValidRTT")
			select ValidRTT
			if cntrecs = 0
				lbError = .T.
				liErrCount = liErrCount+1
				lsRowError = lsRowError+"Invalid RT/Tag number. "
				lsErrMessage = lsErrMessage+"Row "+str(liRowCnt)+" : RT/Tag number not found."+chr(13)+chr(10)
			ENDIF
			OMED.CloseAlias("ValidRTT")
		    select todo
		ENDIF

		** check txn 7 and txn 37 - max limit -$20.00
		IF TYPE("todo.TXN7")="N"
			cTXN7=  ALLTRIM( STR(todo.txn7,5,2))
		ELSE
			if EMPTY(ALLTRIM(TODO.TXN7)) 
				cTXN7 = "0"
			else
				cTXN7=STR(VAL(todo.txn7),5,2)
			ENDIF
		ENDIF
		IF TYPE("todo.TXN37")="N"
			cTXN37=  ALLTRIM(STR(todo.txn37,5,2))
		ELSE
			if ALLTRIM(TODO.TXN37) = ""
				cTXN37 = "0"
			else
				cTXN37= STR( VAL(todo.txn37),5,2)
			ENDIF
		ENDIF
		IF TYPE("todo.TXN5")="N"							&& 4/30/2020, ZD #167546, JH.
			cTXN5 =  ALLTRIM(STR(todo.txn5,5,2))
		ELSE
			if EMPTY(ALLTRIM(TODO.TXN5))
				cTXN5 = "0"
			else
				cTXN5= ALLTRIM(todo.txn5)
			ENDIF
		ENDIF


		IF TYPE("todo.TXN45")="N"							&& 4/30/2020, ZD #167546, JH.
			cTXN45=  ALLTRIM(STR(todo.TXN45))
		ELSE
			if EMPTY(ALLTRIM(TODO.TXN45))
				cTXN45 = "0"
			else
				cTXN45= ALLTRIM(todo.TXN45)
			ENDIF
		ENDIF

		IF TYPE("todo.TXN54")="N"							&& 4/30/2020, ZD #167546, JH.
			cTXN54=  ALLTRIM(STR(todo.TXN54))
		ELSE
			if EMPTY(ALLTRIM(TODO.TXN54))
				cTXN54 = "0"
			else
				cTXN54= ALLTRIM(todo.TXN54)
			ENDIF
		ENDIF


		IF TYPE("todo.TXN55")="N"							&& 4/30/2020, ZD #167546, JH.
			cTXN55=  ALLTRIM(STR(todo.TXN55))
		ELSE
			if EMPTY(ALLTRIM(TODO.TXN55))
				cTXN55 = "0"
			else
				cTXN55= alltrim(todo.TXN55)
			ENDIF
		ENDIF

		IF TYPE("todo.TXN56")="N"							&& 4/30/2020, ZD #167546, JH.
			cTXN56=  ALLTRIM(STR(todo.TXN56))
		ELSE
			if EMPTY(ALLTRIM(TODO.TXN56))
				cTXN56 = "0"
			else
				cTXN56= alltrim(todo.TXN56)
			ENDIF
		ENDIF

		IF TYPE("todo.TXN58")="N"							&& 4/30/2020, ZD #167546, JH.
			cTXN58=  ALLTRIM(STR(todo.TXN58))
		ELSE
			if EMPTY(ALLTRIM(TODO.TXN58))
				cTXN58 = "0"
			else
				cTXN58= ALLTRIM(todo.TXN58)
			ENDIF
		ENDIF

		IF TYPE("todo.TXN59")="N"							&& 4/30/2020, ZD #167546, JH.
			cTXN59=  ALLTRIM(STR(todo.TXN59))
		ELSE
			if EMPTY(ALLTRIM(TODO.TXN59))
				cTXN59 = "0"
			else
				cTXN59= ALLTRIM(todo.TXN59)
			ENDIF
		ENDIF

		IF TYPE("todo.TXN60")="N"							&& 4/30/2020, ZD #167546, JH.
			cTXN60=  ALLTRIM(STR(todo.TXN60))
		ELSE
			if EMPTY(ALLTRIM(TODO.TXN60))
				cTXN60 = "0"
			else
				cTXN60= ALLTRIM(todo.TXN60)
			ENDIF
		ENDIF
		IF VAL(cTXN7) > 20.00
			lbError = .T.
			liErrCount = liErrCount+1
			lsRowError = lsRowError+"Txn 7 amt > $20. "
			lsErrMessage = lsErrMessage+"Row "+str(liRowCnt)+" : Txn 7 amount amount exceeds $20."+chr(13)+chr(10)
		ENDIF
		IF VAL(cTXN37)  > 20.00
			lbError = .T.
			liErrCount = liErrCount+1
			lsRowError = lsRowError+"Txn 37 amt > $20. "
			lsErrMessage = lsErrMessage+"Row "+str(liRowCnt)+" : Txn 37 amount amount exceeds $20."+chr(13)+chr(10)
		ENDIF
		IF NOT INLIST(cTXN45,"0","1")
			lbError = .T.
			liErrCount = liErrCount+1
			lsRowError = lsRowError+"Txn 45 incorrect value. "
			lsErrMessage = lsErrMessage+"Row "+str(liRowCnt)+" : Txn 45 value can only be blank, 0 or 1."+chr(13)+chr(10)
		ENDIF
		IF NOT INLIST(cTXN54,"0","1")
			lbError = .T.
			liErrCount = liErrCount+1
			lsRowError = lsRowError+"Txn 54 incorrect value. "
			lsErrMessage = lsErrMessage+"Row "+str(liRowCnt)+" : Txn 54 value can only be blank, 0 or 1."+chr(13)+chr(10)
		ENDIF
		IF NOT INLIST(cTXN55,"0","1")
			lbError = .T.
			liErrCount = liErrCount+1
			lsRowError = lsRowError+"Txn 55 incorrect value. "
			lsErrMessage = lsErrMessage+"Row "+str(liRowCnt)+" : Txn 55 value can only be blank, 0 or 1."+chr(13)+chr(10)
		ENDIF
		IF NOT INLIST(cTXN56,"0","1")
			lbError = .T.
			liErrCount = liErrCount+1
			lsRowError = lsRowError+"Txn 56 incorrect value. "
			lsErrMessage = lsErrMessage+"Row "+str(liRowCnt)+" : Txn 56 value can only be blank, 0 or 1."+chr(13)+chr(10)
		ENDIF
		IF NOT INLIST(cTXN58,"0","1")
			lbError = .T.
			liErrCount = liErrCount+1
			lsRowError = lsRowError+"Txn 58 incorrect value. "
			lsErrMessage = lsErrMessage+"Row "+str(liRowCnt)+" : Txn 58 value can only be blank, 0 or 1."+chr(13)+chr(10)
		ENDIF
		IF NOT INLIST(cTXN59,"0","1")
			lbError = .T.
			liErrCount = liErrCount+1
			lsRowError = lsRowError+"Txn 59 incorrect value. "
			lsErrMessage = lsErrMessage+"Row "+str(liRowCnt)+" : Txn 59 value can only be blank, 0 or 1."+chr(13)+chr(10)
		ENDIF
		IF NOT INLIST(cTXN60,"0","1")
			lbError = .T.
			liErrCount = liErrCount+1
			lsRowError = lsRowError+"Txn 60 incorrect value. "
			lsErrMessage = lsErrMessage+"Row "+str(liRowCnt)+" : Txn 60 value can only be blank, 0 or 1."+chr(13)+chr(10)
		ENDIF


		select ToDo2
		INSERT INTO Todo2 (Lrs_No,TAG,txn7,txn37,txn5,txn45,txn54,txn55,txn56,txn58,txn59,txn60,err,Done) VALUES ;
			(M.Lrs_No, M.TAG, M.txn7, M.txn37,m.txn5,m.txn45,m.txn54,m.txn55,m.txn56,m.txn58,m.txn59,m.txn60,left(lsRowError,100),NOT lbError)
	ENDIF

	SELECT todo
ENDSCAN

liUserResp = 6			&& JOE
IF liErrCount > 0		&& JOE
  liUserResp = MESSAGEBOX("There are "+STR(liErrCount)+" error(s) with the spreadsheet. "+chr(13)+chr(10)+chr(13)+chr(10)+"(Yes) Review errors?"+chr(13)+chr(10)+chr(13)+chr(10)+"(No) just process the ones without errors?",52,"Errors found. Review?")
  if (liUserResp = 6)
	liUserResp = MESSAGEBOX(lsErrMessage,276,"Errors found. Continue loading the rows without errors?")	
  ENDIF
ENDIF

IF INLIST(liUserResp,6,7)	
	select todo2		
	scan
		if done
			LRS_NO = ToDo2.Lrs_no
				Tag = Todo2.Tag
			IF TYPE("ToDo2.TXN7")="N"
				cTXN7=  ALLTRIM( STR(ToDo2.txn7,5,2))
			ELSE
				if EMPTY(ALLTRIM(ToDo2.TXN7)) 
					cTXN7 = "0"
				else
					cTXN7=STR(VAL(ToDo2.txn7),5,2)
				ENDIF
			ENDIF
			IF TYPE("ToDo2.TXN37")="N"
				cTXN37=  ALLTRIM(STR(ToDo2.txn37,5,2))
			ELSE
				if ALLTRIM(ToDo2.TXN37) = ""
					cTXN37 = "0"
				else
					cTXN37= STR( VAL(ToDo2.txn37),5,2)
				ENDIF
			ENDIF
			IF TYPE("ToDo2.TXN5")="N"							&& 4/30/2020, ZD #167546, JH.
				cTXN5 =  ALLTRIM(STR(ToDo2.txn5,5,2))
			ELSE
				if EMPTY(ALLTRIM(ToDo2.TXN5))
					cTXN5 = "0"
				else
					cTXN5= ALLTRIM(ToDo2.txn5)
				ENDIF
			ENDIF
			IF TYPE("ToDo2.TXN45")="N"							&& 4/30/2020, ZD #167546, JH.
				cTXN45=  ALLTRIM(STR(ToDo2.TXN45))
			ELSE
				if EMPTY(ALLTRIM(ToDo2.TXN45))
					cTXN45 = "0"
				else
					cTXN45= ALLTRIM(ToDo2.TXN45)
				ENDIF
			ENDIF
			IF TYPE("ToDo2.TXN54")="N"							&& 4/30/2020, ZD #167546, JH.
				cTXN54=  ALLTRIM(STR(ToDo2.TXN54))
			ELSE
				if EMPTY(ALLTRIM(ToDo2.TXN54))
					cTXN54 = "0"
				else
					cTXN54= ALLTRIM(ToDo2.TXN54)
				ENDIF
			ENDIF
			IF TYPE("ToDo2.TXN55")="N"							&& 4/30/2020, ZD #167546, JH.
				cTXN55=  ALLTRIM(STR(ToDo2.TXN55))
			ELSE
				if EMPTY(ALLTRIM(ToDo2.TXN55))
					cTXN55 = "0"
				else
					cTXN55= alltrim(ToDo2.TXN55)
				ENDIF
			ENDIF
			IF TYPE("ToDo2.TXN56")="N"							&& 4/30/2020, ZD #167546, JH.
				cTXN56=  ALLTRIM(STR(ToDo2.TXN56))
			ELSE
				if EMPTY(ALLTRIM(ToDo2.TXN56))
					cTXN56 = "0"
				else
					cTXN56= alltrim(ToDo2.TXN56)
				ENDIF
			ENDIF
			IF TYPE("ToDo2.TXN58")="N"							&& 4/30/2020, ZD #167546, JH.
				cTXN58=  ALLTRIM(STR(ToDo2.TXN58))
			ELSE
				if EMPTY(ALLTRIM(ToDo2.TXN58))
					cTXN58 = "0"
				else
					cTXN58= ALLTRIM(ToDo2.TXN58)
				ENDIF
			ENDIF
			IF TYPE("ToDo2.TXN59")="N"							&& 4/30/2020, ZD #167546, JH.
				cTXN59=  ALLTRIM(STR(ToDo2.TXN59))
			ELSE
				if EMPTY(ALLTRIM(ToDo2.TXN59))
					cTXN59 = "0"
				else
					cTXN59= ALLTRIM(ToDo2.TXN59)
				ENDIF
			ENDIF
			IF TYPE("ToDo2.TXN60")="N"							&& 4/30/2020, ZD #167546, JH.
				cTXN60=  ALLTRIM(STR(ToDo2.TXN60))
			ELSE
				if EMPTY(ALLTRIM(ToDo2.TXN60))
					cTXN60 = "0"
				else
					cTXN60= ALLTRIM(ToDo2.TXN60)
				ENDIF
			ENDIF

		   c_sql="exec dbo.AddSubpoenaFees10Types "+ALLTRIM(STR(Lrs_no))+","+ALLTRIM(str(Tag))+",'"+ALLTRIM(PC_USERID)+"',"+cTXN7+","+cTXN37+"," ;
			+STR(n_crcd)+","+cTXN5+",'"+cTXN45+"','"+cTXN54+"','"+cTXN55+"','"+cTXN56+"','"+cTXN58+"','"+cTXN59+"','"+cTXN60+"'"
	      l_ok =OMED.SQLEXECUTE(c_sql)
	

	SELECT todo

		endif
	endscan

	DO Emailfile
ENDIF

RELEASE OMED


select ToDo
use


_SCREEN.MOUSEPOINTER=0

RETURN l_ok

*********************************************************************************************

FUNCTION anEXCEL

PARAMETERS CFILE
LOCAL lcValue2 as String

lcTEMP=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","CTemp", "\")))
lcpath=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","TemplExcel", "\")))	&& TemplExcel=\\imagesvr\rtdocs1\QCExcel\Templates\

C_FILE =lcpath+"AnExcel2.dbf"
IF USED("AnExcel")
	SELECT anEXCEL
	USE
ENDIF
USE (C_FILE) IN 0 ALIAS anEXCEL


IF USED(lcTEMP+ "TODO" + ".dbf")
	SELECT  lcTEMP+ "todo" + ".dbf"
	USE
ENDIF
IF FILE(lcTEMP+ "TODO" + ".dbf")
	DELETE FILE  lcTEMP+ "todo" + ".dbf"
ENDIF
SELECT anEXCEL
COPY TO (lcTEMP+ "TODO" + ".dbf")
SELECT anEXCEL
USE
USE (lcTEMP+ "TODO" + ".dbf")  ALIAS anEXCEL    IN 0

DO closeexcel WITH "Excel.EXE"


oleApp = CREATEOBJECT("Excel.Application")    && Launch Excel.
oleApp.VISIBLE=.F.                            && Display Excel.
oleApp.Workbooks.OPEN(CFILE)        && Open the template
********************************************************************

* put all fields names in the array
lnTotColumns=AFIELDS(laAvaFile,"anexcel")
DIMENSION laFlds[lnTotColumns]
FOR lnFldCnt=1 TO lnTotColumns
	laFlds[lnFldCnt]=oleApp.Cells(1,lnFldCnt).VALUE
NEXT
lnTotColumns=AFIELDS(laAvaFile,"anexcel")

lnrowCntall=oleApp.ROWS.COUNT

lnrowCnt=0
llExit=.F.

DO WHILE llExit=.F.
	lnrowCnt= lnrowCnt+1

	IF llExit=.F.
		SELECT anEXCEL
		APPEND BLANK
		FOR lnFldCnt=1 TO  lnTotColumns

			lcField=ALLTRIM(FIELD(lnFldCnt))
			lcValue=  oleApp.Cells(lnrowCnt,lnFldCnt).VALUE
			IF TYPE("lcValue")="C"
				lcValue2 = UPPER(lcValue)
				if INLIST(lcValue2,"LRS_NO","TAG","TXN 7","TXN 37","TXN 5","TXN 45","TXN 54","TXN 55","TXN 56","TXN 58","TXN 59","TXN 60","RT#","TAG#","TXN 7 AMOUNT","TXN 37 AMOUNT","MINUTES","ENTER 1 OR LEAVE BLANK")
					lnTotHeader = lnTotHeader+1
				ENDIF
			ENDIF

			IF 	lnFldCnt = 1 and ISNULL(lcValue)
				llExit=.T.
				EXIT
			ENDIF


			IF !EMPTY(ALLTRIM(lcField)) AND ISNULL(lcValue)<>.T.
				REPLACE &lcField WITH convertField(&lcField, lcValue)
			ENDIF
		NEXT
	ENDIF
ENDDO

oleApp.DisplayAlerts = 0
oleApp.QUIT

RETURN .T.

*--------------------------------------

FUNCTION convertField

LPARAMETERS lxInField, lxOutField

DO CASE
CASE TYPE("lxInField")="C"
	lxOutField=convertToChar(lxOutField,1)
CASE TYPE("lxInField")="N"
	lxOutField=convertToNum(lxOutField)
CASE TYPE("lxInField")="D"
	lxOutField=convertToDate(lxOutField)
CASE TYPE("lxInField")="T"
	lxOutField=convertToDate(lxOutField)
CASE TYPE("lxInField")="L"
	lxOutField=convertToBool(lxOutField,2)

ENDCASE

RETURN lxOutField

****************************************************

FUNCTION GETTMPFILE

PARAMETERS CTEMPFILE

PRIVATE C_FILE AS STRING

C_ROOT=SYS(5) + "\"
N_NUM1=1

N_FILES = ADIR(A_FILES, C_ROOT +ALLTRIM(UPPER(CTEMPFILE)))
IF N_FILES > 0
	=ASORT(A_FILES)
	N_NUM1 =GETNUMBER(A_FILES(ALEN(A_FILES,1), 1), LEN(ALLTRIM("todo_")))
ENDIF
C_FILE=LEFT(CTEMPFILE,LEN(CTEMPFILE)-5) + ALLTRIM(STR(N_NUM1+1)) +".xls"
RETURN C_FILE

*********************************************************************************************

PROCEDURE CLEARTMP

IF USED('todo')
	SELECT  todo
	USE
ENDIF
RETURN

*******************************************************************************

PROCEDURE Emailfile

PRIVATE   fso AS OBJECT, OMED AS OBJECT
fso = CREATEOBJECT("Scripting.FileSystemObject")
LOCAL lcAlias AS STRING
lcAlias= ALIAS()
_SCREEN.MOUSEPOINTER=11
lcDate=DTOC(DATE())

OMED=CREATEOBJECT("generic.medgeneric")
lcTEMP=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","CTemp", "\")))

lCTEMPFILE=lcTEMP + "SubpFee_" + STRTRAN(lcDate,"/","") + ".xls"
IF fso.FileExists(ALLTRIM(lCTEMPFILE))
	fso.DeleteFile (lCTEMPFILE)
ENDIF


IF USED('Todo2')
	SELECT Todo2
    GO TOP

    CREATE CURSOR data2 (err c(100), Lrs_No N(6), TAG N(4), txn7 N(8,2), txn37 N(8,2), txn5 n(6,2), txn45 c(4), txn54 c(4), txn55 c(4), ;
	    txn56 c(4), txn58 c(4), txn59 c(4), txn60 c(4), Done L NULL)

	SELECT  Lrs_No, TAG, txn7, txn37, txn5, txn45, txn54, txn55, txn56, txn58,txn59,txn60, err FROM  Todo2 INTO CURSOR  data2 
	SELECT data2
	GO TOP

	IF NOT EOF()
		COPY TO (STRTRAN(lCTEMPFILE,"'","")) TYPE XL5
		OMED.closealias("UserAcct")
		OMED.SQLEXECUTE("exec DBO.[GetUserByLogin] '" +ALLTRIM( PC_USERID) + "'", "UserAcct")
		SELECT UserAcct
		IF NOT EOF()
			c_SendTo=STRTRAN(ALLT( UserAcct.Email),";",",")
			c_CopyTo="rtverifyoutbound@recordtrak.com"
			c_FromName=ALLTRIM(UserAcct.FULLNAME )
			c_FromEmail=STRTRAN(ALLT( UserAcct.Email),";",",")
			c_Subject=ALLTRIM("Subpoena Fees added on " + lcDate + "."   )
			c_Message=ALLTRIM("Please, see attached excel file.")
			STORE "" TO c_attachment,c_bCCList
			c_attachment=lCTEMPFILE
			DO sendwwemail WITH c_FromEmail, c_FromName, c_SendTo,c_CopyTo, c_bCCList, c_Subject, c_Message, c_attachment
		ENDIF
		gfMessage("Please review the " + lCTEMPFILE + " Excel file or/and check the email that had been sent to you.")
	ENDIF

ENDIF
RELEASE OMED
RELEASE fso  
IF NOT EMPTY(lcAlias)
	SELECT (lcAlias)
ENDIF

_SCREEN.MOUSEPOINTER= 0
