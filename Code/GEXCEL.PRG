*********************************************************************************************
FUNCTION GEXCEL
PARAMETERS CFILE

lcTEMP=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","CTemp", "\")))
lcpath=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","TemplExcel", "\")))
**\\imagesvr\rtdocs1\QCExcel\Templates\
C_FILE =lcpath+"GEXCEL.dbf"
IF USED("GEXCEL")
	SELECT GEXCEL
	USE
ENDIF
USE  (C_FILE) IN 0 ALIAS GEXCEL


IF FILE(lcTEMP+ "g2pcx" + ".dbf")
	SELECT (lcTEMP+ "g2pcx" + ".dbf")
	USE
	DELETE FILE  lcTEMP+ "g2pcx" + ".dbf"
ENDIF
SELECT GEXCEL
COPY TO (lcTEMP+ "g2pcx" + ".dbf")
SELECT GEXCEL
USE
USE (lcTEMP+ "g2pcx" + ".dbf")  ALIAS GEXCEL    IN 0

DO closeexcel WITH "Excel.EXE"


oleApp = CREATEOBJECT("Excel.Application")    && Launch Excel.
oleApp.VISIBLE=.F.                            && Display Excel.
oleApp.Workbooks.OPEN(CFILE)        && Open the template
********************************************************************

* put all fields names in the array
lnTotColumns=AFIELDS(laAvaFile,"GEXCEL")
DIMENSION laFlds[lnTotColumns]
FOR lnFldCnt=1 TO lnTotColumns
	laFlds[lnFldCnt]=oleApp.Cells(1,lnFldCnt).VALUE
NEXT
lnTotColumns=AFIELDS(laAvaFile,"GEXCEL")
lnrowCntall=oleApp.ROWS.COUNT

lnrowCnt=0
llExit=.F.


DO WHILE llExit=.F.
	lnrowCnt= lnrowCnt+1

	IF llExit=.F.
		SELECT GEXCEL
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
	N_NUM1 =GETNUMBER(A_FILES(ALEN(A_FILES,1), 1), LEN(ALLTRIM("g2pcx_")))
ENDIF
C_FILE=LEFT(CTEMPFILE,LEN(CTEMPFILE)-5) + ALLTRIM(STR(N_NUM1+1)) +".xls"
RETURN C_FILE
*********************************************************************************************

PROCEDURE CLEARTMP

IF USED('g2pcx')
	SELECT g2pcx
	USE
ENDIF

RETURN
*******************************************************************************
FUNCTION AddG
PRIVATE OMED AS OBJECT
LOCAL lcAlias as String, l_ok as Boolean
lcAlias=ALIAS()
OMED=CREATEOBJECT("generic.medgeneric")
l_ok=.f.
IF USED('g2pcx') AND !EOF()

SELECT  g2pcx
SCAN
	SCATTER MEMVAR
	STORE "" TO cRttodo, cTagtodo

	IF TYPE("g2pcx.lrs_no")="N"
		cRttodo= ALLTRIM(STR(g2pcx.Lrs_No))
	ELSE
		cRttodo= ALLTRIM(g2pcx.Lrs_No)
	ENDIF

	IF TYPE("g2pcx.tag")="N"
		cTagtodo=  ALLTRIM(STR(g2pcx.TAG))
	ELSE
		cTagtodo=ALLTRIM(g2pcx.TAG)
	ENDIF

	IF EMPTY(cTagtodo) OR EMPTY(cRttodo)
		gfMessage( 'Invalid Tag Number' )
		SKIP
		LOOP
	ENDIF


	IF EMPTY(g2pcx.origsubp)		
		gfMessage( 'One of the RT/tag has a missing subpoena name. Pelase fix and try again.' )
		SKIP
		LOOP
	ENDIF
	

	c_sql=""
	c_sql=" exec  dbo.AddSubpoenaFees '" + cRttodo + "','" + cTagtodo + "','CRCD-" + ALLTRIM(PC_USERID) + "','" + cTXN7 + "','" + cTXN37 + "'"

	l_ok =OMED.SQLEXECUTE(c_sql)

	
	IF l_ok
		SELECT g2pcx
		INSERT INTO Todo2  (Lrs_No, TAG, txn7, txn37, Done)   VALUES (M.Lrs_No, M.TAG, M.txn7, M.txn37, .T.)
	ENDIF

	SELECT g2pcx

ENDSCAN


ENDIF
RELEASE OMED
** generate an excel to email back
IF l_ok
	DO Emailfile
ENDIF


_SCREEN.MOUSEPOINTER=0

IF !EMPTY( lcAlias )
SELECT ( lcAlias )
ENDIF


RETURN l_ok