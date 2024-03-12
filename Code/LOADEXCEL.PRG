PARAMETERS c_file, c_defdir, c_step
**03/08/10 - step 1 is used to re-organize the columns in a client's excel file
**09/28/09 - added to handle dates in the step 2
**pass an excel file

LOCAL lcpath AS STRING, c_var AS STRING, lnrowCntall AS NUMBER, l_newform AS Boolean
STORE "" TO lcpath, c_var
l_newform=.F.
IF TYPE('PC_LITCODE')<>"C"
	WAIT WINDOW "Litigation is not defind." 
	RETURN .F.
ENDIF
LOCAL omedEx as Object
omedEx=CREATEOBJECT("medmaster")



lcpath=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","AUTOMATEDISSUE", "\")))
c_var = LEFT(ALLTRIM(goApp.CurrentUser.orec.LOGIN) ,3)

IF c_step="1"

	IF USED('TheSettings')
		l_newform=THESETTINGS.newformat

	ELSE

		C_STR="exec [dbo].[GetAIPSettings] '" + PC_LITCODE + "'"
		L_OK=omedEx.SQLEXECUTE( C_STR,"TheSettings")
		IF  L_OK
			l_newform=THESETTINGS.newformat


		ENDIF
	ENDIF
	IF USED('avafile')
		SELECT avafile
		USE
	ENDIF

	IF l_newform
		USE (lcpath+"GSKFile.dbf"  )  ALIAS avafile IN 0
	ELSE
		USE (lcpath+"AVaFile.dbf"  )  ALIAS avafile IN 0
	ENDIF
	RELEASE omedEx
** use to tie the client's columns with our tempalte's file
ELSE
 l_newform=IIF(PC_LITCODE='AV1', .T.,.F.)
ENDIF
*!*	IF c_step="2"
*!*	**03/08/2010
*!*		*USE (lcpath+"template_ava_2.dbf"  )  ALIAS template_ava IN

IF l_newform
	USE (lcpath+"template_GSK.dbf"  )  ALIAS template_ava IN 0
ELSE

	USE (lcpath+"template.dbf"  )  ALIAS template_ava IN 0
ENDIF
*!*	else
*!*		USE (lcpath+"template_ava.dbf"  ) IN 0
*!*	endif

IF FILE(c_defdir + "AVAstep_" + c_var + ".dbf")
	DELETE FILE c_defdir + "AVAstep_" + c_var + ".dbf"
ENDIF
SELECT template_ava
COPY TO (c_defdir + "AVAstep_" + c_var + ".dbf")
SELECT template_ava
USE
USE (c_defdir + "AVAstep_" + c_var + ".dbf" )  ALIAS ava  IN 0
DO closeexcel WITH "Excel.EXE"

oleApp = CREATEOBJECT("Excel.Application")    && Launch Excel.
oleApp.VISIBLE=.F.                            && Display Excel.
oleApp.Workbooks.OPEN(c_file)        && Open the template
********************************************************************
IF c_step="1"
* put all fields names in the array
	lnTotColumns=AFIELDS(laAvaFile,"ava")
	DIMENSION laFlds[lnTotColumns]
	FOR lnFldCnt=1 TO lnTotColumns
		laFlds[lnFldCnt]=oleApp.Cells(1,lnFldCnt).VALUE
	NEXT
	IF l_newform
	ELSE
		lnTotColumns=30
	ENDIF
	lnrowCntall=lnTotColumns  &&04/01/2010 MD
ELSE
	lnrowCntall=oleApp.ROWS.COUNT   &&  04/01/2010 MD

ENDIF

********************************************************************
lnrowCnt=0
llExit=.F.

*FOR lnrowCnt=1 TO lnrowCntall &&oleApp.Rows.Count
* 04/01/2010 MD modified to load only active rows.
* The oleApp.Rows.Count returns 65666 (# of allowable Excel rows)

DO WHILE llexit=.F.
	lnrowCnt= lnrowCnt+1
	IF EMPTY(ALLTRIM(NVL(oleApp.Cells(lnrowCnt,1).VALUE,''))) AND EMPTY(ALLTRIM(NVL(oleApp.Cells(lnrowCnt,2).VALUE,''))) AND;
			EMPTY(ALLTRIM(NVL(oleApp.Cells(lnrowCnt,3).VALUE,'')))
		llExit=.T.
	ENDIF
	IF llExit=.F.
		SELECT ava
		APPEND BLANK
		FOR lnFldCnt=1 TO  lnrowCntall &&oleApp.cells.count
			*IF c_step="2"
				lcField=ALLTRIM(FIELD(lnFldCnt))

			*ENDIF


			lcValue=  oleApp.Cells(lnrowCnt,lnFldCnt).VALUE
			IF c_step="1" AND NOT EMPTY(NVL(lcValue,''))
				lcField= recolumn(NVL(lnFldCnt,''))
				IF ALLTRIM(UPPER(lcField))=="ERROR9999"
					oleApp.DisplayAlerts = 0
					oleApp.QUIT
					RETURN .F.
				ENDIF
			ENDIF

			IF EMPTY(NVL(lcField,""))
				EXIT
			ENDIF && no more columns
			IF !EMPTY(ALLTRIM(lcField)) AND ISNULL(lcValue)<>.T.
				REPLACE &lcField WITH convertField(&lcField, lcValue)

			ENDIF
		NEXT
	ENDIF
ENDDO

oleApp.DisplayAlerts = 0

*oleApp.ActiveWorkbook.SAVE

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

**************************************************************************************
FUNCTION recolumn
PARAMETERS lnField
LOCAL retval, lcFieldName
c_alias =ALIAS()
lcField=""
IF lnField>0
	lcFieldName=NVL(laFlds[lnField],'')		&& column name in excel

*IF NOT EMPTY(NVL(lcFieldName,''))

	SELECT AVaFile
	SET ORDER TO customh

	IF SEEK (ALLTRIM(UPPER(lcFieldName)))	&& match column name in excel with output table
		retval=ALLTRIM(AVaFile.excelh)
	ELSE
		retval=""
		GFMESSAGE('Check the Excel file your are trying to process, some columns are missing or misspelled. Please exit.')
*WAIT WINDOW "Check the Excel file your are trying to process, some columns are missing or misspelled."
		SELECT (c_alias)
		RETURN "ERROR9999"

	ENDIF
*ENDI

ENDIF
SELECT (c_alias)
RETURN retval
**************************************************************************************
