
*FUNCTION properdate
PARAMETERS c_Field, c_Value


**VALIDATE SSN - 09/05/2012
LOCAL C1 AS STRING, C2 AS STRING,  l_validDate AS Boolean, C_DATE AS STRING, l_ExcVerify AS Boolean,n_year as Integer
STORE "" TO C1, C2, c_socsec, C_DATE
STORE .T. TO  l_validDate, l_ExcVerify
n_year=0

DO CASE

CASE PC_COLTYPE="D" && ALL DATE TYPE COLUMNS
	DO CASE
	CASE TYPE ("c_Value")="T"
		C_DATE =LEFT(ALLTRIM(TTOC(c_Value)),10)
	CASE TYPE ("c_Value")="C"	AND NOT "D"$ALLTRIM(c_Value)
		C_DATE =ALLTRIM(c_Value)
	CASE TYPE ("c_Value")="D"
		C_DATE =LEFT(ALLTRIM(DTOC(c_Value)),10)

	ENDCASE

	n_lendate =LEN(C_DATE )

	IF n_lendate<>0
		C1=SUBSTR(ALLTRIM(C_DATE), 3 ,1)
		C2=SUBSTR(ALLTRIM(C_DATE), 6 ,1)
		IF C1<>'/' OR C2<>'/'
			l_validDate=.F.

		ENDIF
		IF n_lendate<>10
			l_validDate=.F.

		ENDIF
		n_year=VAL(RIGHT(LEFT(C_DATE,8),2))
		IF n_year<19  OR n_year>20&& WRONG CENTURY
			l_validDate=.F.

		
		ENDIF
		
	ENDIF
	

ENDCASE
l_ExcVerify=l_validDate
RETURN l_ExcVerify
