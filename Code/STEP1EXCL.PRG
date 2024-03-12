PARAMETERS c_file2, c_defdir, c_folder
*10/26/2010 -QC -step 1 excel pre-process
**pass an excel file

LOCAL lcpath AS STRING, c_var AS STRING, lnrowCntall AS NUMBER, l_newform AS Boolean, lctmpath AS STRING
STORE "" TO lcpath, c_var, lctmpath
DO closeexcel WITH "Excel.EXE"
IF TYPE('PC_LITCODE')<>"C"
	WAIT WINDOW "Litigation is not defined."
	RETURN .F.
ENDIF
LOCAL omedEx AS OBJECT
********************************************************************************
PUBLIC PC_COLTYPE AS STRING
plExcVerify=.T.
********************************************************************************
omedEx=CREATEOBJECT("medmaster")
l_newform=.T. && All QC excels are a new form -the old AIP has an old and a new one.

lcpath=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","QCExcel", "\")))
**06/25/15- MADE TAG COMMENT (BI) -1000 CHARACTERS(MEMO)
**09/10/12- edited address1 and 2 (i,j) columns to be 50 characters
*lctmpath=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","QCTemplExcel", "\")))
lctmpath=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","TemplExcel", "\")))


c_var = LEFT(ALLTRIM(goApp.CurrentUser.orec.LOGIN) ,3)

IF USED('step1file')
	SELECT step1file
	USE
ENDIF

IF l_newform
	USE (lctmpath+"E_GSKFile.dbf"  )  ALIAS step1file IN 0
	USE (lctmpath+"E_template_GSK.dbf"  )  ALIAS template_1 IN 0

ENDIF



IF FILE(lcpath + c_folder +"\" + "e_step_" + c_var + ".dbf")
	DELETE FILE c_defdir + c_folder +"\"  + "E_step_" + c_var + ".dbf"
ENDIF
SELECT template_1
COPY TO (lcpath + c_folder +"\" + "E_step_" + c_var + ".dbf")
SELECT template_1
USE

IF USED('TODOFILE')
	SELECT TODOFILE
	USE
ENDIF


USE (lcpath + c_folder +"\" + "E_step_" + c_var + ".dbf" )  ALIAS TODOFILE  IN 0
PC_TODOFILE =lcpath + c_folder +"\" + "E_step_" + c_var + ".dbf"

oleApp = CREATEOBJECT("Excel.Application")    && Launch Excel.
oleApp.VISIBLE=.F.                            && Display Excel.
oleApp.Workbooks.OPEN(c_file2)        && Open the template
********************************************************************
* put all fields names in the array
lnTotColumns=AFIELDS(laAvaFile,"TODOFILE")
DIMENSION laFlds[lnTotColumns]
FOR lnFldCnt=1 TO lnTotColumns
	laFlds[lnFldCnt]=oleApp.Cells(1,lnFldCnt).VALUE
NEXT

lnrowCntall=lnTotColumns

********************************************************************
lnrowCnt=0
llExit=.F.

CREATE CURSOR  chkheader ( HName c(45) )
INDEX ON ALLTRIM(UPPER(HName)) TAG HName ADDITIVE

*to load only active rows.
*The oleApp.Rows.Count returns 65666 (# of allowable Excel rows)

DO WHILE llExit=.F.
	lnrowCnt= lnrowCnt+1
&&& CCC
	IF TYPE ("NVL(oleApp.Cells(lnrowCnt,1).VALUE,'')") ="C" AND TYPE ("NVL(oleApp.Cells(lnrowCnt,2).VALUE,'')") ="C" AND TYPE ("NVL(oleApp.Cells(lnrowCnt,3).VALUE,'')") ="C"
		IF EMPTY(ALLTRIM(NVL(oleApp.Cells(lnrowCnt,1).VALUE,''))) AND EMPTY(ALLTRIM(NVL(oleApp.Cells(lnrowCnt,2).VALUE,''))) AND;
				EMPTY(ALLTRIM(NVL(oleApp.Cells(lnrowCnt,3).VALUE,'')))
			llExit=.T.
		ENDIF
	ELSE
&&NcC
		IF  TYPE ("NVL(oleApp.Cells(lnrowCnt,1).VALUE,0)")  ="N" AND  TYPE ("NVL(oleApp.Cells(lnrowCnt,2).VALUE,'')") ="C"

			IF NVL(oleApp.Cells(lnrowCnt,1).VALUE,0)=0 AND EMPTY(ALLTRIM(NVL(oleApp.Cells(lnrowCnt,2).VALUE,''))) AND;
					EMPTY(ALLTRIM(NVL(oleApp.Cells(lnrowCnt,3).VALUE,'')))
				llExit=.T.
			ENDIF
*!*			ELSE
*!*				WAIT WINDOW " Columns are out of ORDER(CCC, NNC)"   NOWAIT
*!*				RETURN

		ENDIF
	ENDIF
***12/30/2010 -columns are out of datatype order


	IF llExit=.F.
		SELECT TODOFILE
		APPEND BLANK

		FOR lnFldCnt=1 TO  lnrowCntall &&oleApp.cells.count

			lcField=ALLTRIM(FIELD(lnFldCnt))
			lcValue= oleApp.Cells(lnrowCnt,lnFldCnt).VALUE



			PC_COLTYPE=""
			lcField= recolumn(NVL(lnFldCnt,''),lnrowCnt)

			IF lcField='AK'
				IF  TYPE("lcValue")<>"C"
					lcValue=STR(lcValue,16, 6)
				ENDIF
			ENDIF



**********************************************************
			LOCAL l_lvalidssn AS Boolean, l_lvalidDate AS Boolean
			STORE .T. TO l_lvalidssn, l_lvalidDate
			IF lnrowCnt>1
				**VALIDATE SSN - 09/11/2012 
				DO CASE
				CASE lcField='D'
					IF TYPE (' lcValue')="N"
						lcValue=STR( lcValue)
					ENDIF
					IF  lcValue<>"SS#" &&ssn
						l_lvalidssn =properSSN(lcField,lcValue)
						plExcVerify=l_lvalidssn
					ENDIF

				CASE PC_COLTYPE="D" && ALL DATE TYPE COLUMNS
					l_lvalidDate =properDATE(lcField,lcValue)
					plExcVerify=l_lvalidDate
				ENDCASE
			ENDIF

**********************************************************

			IF ALLTRIM(UPPER(lcField))=="ERROR9999"
				oleApp.DisplayAlerts = 0
				oleApp.QUIT
				RETURN .F.
			ENDIF

			IF EMPTY(NVL(lcField,""))
				IF NOT plExcVerify
					gfmessage("Alert: the column # " + ALLTRIM(STR(lnFldCnt))+  "(" + lcValue + ") in your excel file does not match a template's column header name. Please fix and then continue."  )
					RETURN
				ENDIF
				EXIT
			ENDIF && no more columns

			IF NOT plExcVerify AND !EMPTY(NVL(lcField,""))  AND !EMPTY(ALLTRIM(NVL(lcValue,'')))

				DO CASE
				CASE	 TYPE('&lcField')<>ALLTRIM(PC_COLTYPE)
					gfmessage("Alert: the column # " + ALLTRIM(STR(lnFldCnt))+  "(" + lcValue + ") in your excel file does not match a template's column DATA TYPE. Please fix and then continue."  )
				CASE !l_lvalidssn
					gfmessage("Alert: the column SS# " +  "(" + lcValue + ") in your excel file has an invalid value. Please fix and then continue."  )
				CASE !l_lvalidDate && invalid date
					gfmessage("Alert: the column # " + ALLTRIM(STR(lnFldCnt))+  "(" + lcValue + ") in your excel file does not have a valid DATE. Please fix and then continue."  )
				OTHERWISE && dups in a names
					gfmessage("Alert: Some column names in your excel file are duplicate." + "Please fix the " + ALLTRIM(UPPER(lcValue)) + "."   )
				ENDCASE

				RETURN
			ENDIF



			IF !EMPTY(ALLTRIM(lcField)) AND ISNULL(lcValue)<>.T.
				REPLACE &lcField WITH convertField(&lcField, lcValue)

			ENDIF
		NEXT
	ENDIF
ENDDO

oleApp.DisplayAlerts = 0


oleApp.QUIT

RELEASE omedEx
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
PARAMETERS lnField, lnRow
LOCAL retval, lcFieldName
c_alias =ALIAS()
STORE "" TO lcField, retval




IF lnField>0
	lcFieldName=NVL(laFlds[lnField],'')		&& column name in excel

	IF !EMPTY(lcFieldName)

		SELECT step1file
		SET ORDER TO customh

		IF SEEK (ALLTRIM(UPPER(lcFieldName)))

			retval=ALLTRIM(step1file.excelh)
			IF lnRow=1
				SELECT chkheader
				IF NOT SEEK( ALLTRIM(UPPER(lcFieldName)))
					INSERT INTO chkheader( HName) VALUES ( ALLTRIM(UPPER(lcFieldName)) )
				ELSE

					plExcVerify=.F.

				ENDIF
			ELSE
				plExcVerify=.T.
			ENDIF
			PC_COLTYPE=ALLTRIM(step1file.COLTYPE)


		ELSE
			plExcVerify=.F.
*WAIT WINDOW "Warrning: Some column's name in your excel file do not match a template. Some data could be missing on your tags." NOWAIT
		ENDIF

	ENDIF
ENDIF
SELECT (c_alias)
RETURN retval
**************************************************************************************
