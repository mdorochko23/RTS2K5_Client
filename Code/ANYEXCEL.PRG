
PARAMETERS CFILE

lcTEMP=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","CTemp", "\")))
lcpath=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","TemplExcel", "\")))
**\\imagesvr\rtdocs1\QCExcel\Templates\
c_file =lcpath+"Any_Excel.dbf"
IF USED("AnyExcel")
	SELECT AnyExcel 
	USE
ENDIF
USE  (c_file) IN 0 ALIAS anyexcel 


IF FILE(lcTEMP+ "NR" + ".dbf")
	DELETE FILE  lcTEMP+ "NR" + ".dbf"
ENDIF
SELECT anyexcel 
COPY TO (lcTEMP+ "NR" + ".dbf")
SELECT anyexcel 
USE
USE (lcTEMP+ "NR" + ".dbf")  ALIAS anyexcel    IN 0

DO closeexcel WITH "Excel.EXE"


oleApp = CREATEOBJECT("Excel.Application")    && Launch Excel.
oleApp.VISIBLE=.F.                            && Display Excel.
oleApp.Workbooks.OPEN(cfile)        && Open the template
********************************************************************

* put all fields names in the array
lnTotColumns=AFIELDS(laAvaFile,"anyexcel")
DIMENSION laFlds[lnTotColumns]
FOR lnFldCnt=1 TO lnTotColumns
	laFlds[lnFldCnt]=oleApp.Cells(1,lnFldCnt).VALUE
NEXT
lnTotColumns=AFIELDS(laAvaFile,"anyexcel")
lnrowCntall=oleApp.ROWS.COUNT

lnrowCnt=0
llExit=.F.


DO WHILE llexit=.F.
	lnrowCnt= lnrowCnt+1

	IF llExit=.F.
		SELECT anyexcel
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
