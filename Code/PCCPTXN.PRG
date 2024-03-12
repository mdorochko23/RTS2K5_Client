
*****************************************************************************************************************
*Adds txn 7 and txn 37 for a list of rt/tags (Zendesk#24137)
**EF 12/7/15.
*****************************************************************************************************************
PARAMETERS C_FILE, n_crcd
LOCAL  OMED AS OBJECT,  n_minutes AS INTEGER, c_comment AS STRING, lnCurArea AS STRING, c_date AS STRING
c_date=""
l_ok =.F.
lnCurArea=ALIAS()
_SCREEN.MOUSEPOINTER=11
PRIVATE OMED AS OBJECT
OMED=CREATEOBJECT("generic.medgeneric")
SELECT 0
CREATE CURSOR Todo2 (Lrs_No  N(6) , TAG N(4), txn7  N(8,2), txn37 N(8,2), Done L NULL)

lcTEMP=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","CTemp", "\")))
SELECT 0
gfMessage("Please make sure the file is in format: Lrs_no, Tag, txn7, txn37.  Use zero(0) if you have no fee for txn7 or/and txn37, do not leave them blank.")
IF gfMessage("Continue?",.T.)=.F.
	RETURN
ENDIF

IF TYPE("PC_USERID")<>"C"
	PC_USERID=ALLTRIM(goApp.CurrentUser.orec.LOGIN)
ENDIF

C_FILE="'" +C_FILE + "'"
IF anEXCEL(&C_FILE)=.F.
	IF NOT EMPTY(lnCurArea)
		SELECT (lnCurArea)
	ENDIF
	WAIT WINDOW "Process canceled."
	RETURN ""
ENDIF

SELECT anEXCEL
DELETE ALL FOR Lrs_No=0
GO TOP
DO CLEARTMP
IF  EOF()
	WAIT WINDOW "No Data to process.."
	RETURN
ENDIF
IF  EMPTY(ALLTRIM(C_FILE))
	WAIT WINDOW "No excel file selected.."
	RETURN
ENDIF

SELECT anEXCEL
USE

USE (lcTEMP+ "todo" + ".dbf")   IN 0
SET DELETED ON

SELECT  todo
SCAN
	SCATTER MEMVAR
	STORE "" TO cRttodo, cTagtodo

	IF TYPE("todo.lrs_no")="N"
		cRttodo= ALLTRIM(STR(todo.Lrs_No))
	ELSE
		cRttodo= ALLTRIM(todo.Lrs_No)
	ENDIF

	IF TYPE("todo.tag")="N"
		cTagtodo=  ALLTRIM(STR(todo.TAG))
	ELSE
		cTagtodo=ALLTRIM(todo.TAG)
	ENDIF

	IF EMPTY(cTagtodo) OR EMPTY(cRttodo)
		gfMessage( 'Invalid Tag Number' )
		SKIP
		LOOP
	ENDIF

** check txn 7 and txn 37 - max limit -$20.00
	IF TYPE("todo.TXN7")="N"
		cTXN7=  ALLTRIM( STR(todo.txn7,5,2))
	ELSE
		cTXN7=STR(VAL(todo.txn7),5,2)
	ENDIF
	IF TYPE("todo.TXN37")="N"
		cTXN37=  ALLTRIM(STR(todo.txn37,5,2))
	ELSE
		cTXN37= STR( VAL(todo.txn37),5,2)
	ENDIF


	IF VAL(cTXN7)  >20.00  OR VAL(cTXN37)>20.00
		gfMessage( 'One of the txn amount is greater than $ 20.00. Pelase fix and try again.' )
		SKIP
		LOOP
	ENDIF


	c_sql=""
	c_sql=" exec  dbo.AddSubpoenaFees2Types '" + cRttodo + "','" + cTagtodo + "','" + ALLTRIM(PC_USERID) + "','" + cTXN7 + "','" + cTXN37 + "'," + STR(n_crcd) 

	l_ok =OMED.SQLEXECUTE(c_sql)

	IF l_ok
		SELECT Todo2
		INSERT INTO Todo2  (Lrs_No, TAG, txn7, txn37, Done)   VALUES (M.Lrs_No, M.TAG, M.txn7, M.txn37, .T.)
	ENDIF

	SELECT todo

ENDSCAN


RELEASE OMED

** generate an excel to email back
IF l_ok
	DO Emailfile
ENDIF


_SCREEN.MOUSEPOINTER=0

RETURN l_ok

*********************************************************************************************
FUNCTION anEXCEL
PARAMETERS CFILE

lcTEMP=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","CTemp", "\")))
lcpath=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","TemplExcel", "\")))
**\\imagesvr\rtdocs1\QCExcel\Templates\
C_FILE =lcpath+"AnExcel.dbf"
IF USED("AnExcel")
	SELECT anEXCEL
	USE
ENDIF
USE  (C_FILE) IN 0 ALIAS anEXCEL


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

			IF 	ISNULL(lcValue)
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
IF   fso.FileExists(ALLTRIM(lCTEMPFILE))
	fso.DeleteFile (lCTEMPFILE)
ENDIF


IF USED('Todo2')
	SELECT Todo2

	SELECT  Lrs_No, TAG, txn7, txn37 FROM  Todo2 WHERE    Done=.T.   INTO CURSOR  data2  ORDER BY Lrs_No, TAG
	SELECT data2
	GO TOP

	IF NOT EOF()
		COPY TO (STRTRAN(lCTEMPFILE,"'","")) TYPE XL5
		OMED.closealias("UserAcct")
		OMED.SQLEXECUTE("exec  DBO.[GetUserByLogin] '" +	ALLTRIM( PC_USERID) + "'", "UserAcct")
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
