*IsValidTxDistrict()
*11/26/2021 WY 252784   TX district must be 1) a number, 2) a dot 3) or "NONE"
PARAMETERS tcDistValue
 
tcDistValue = ALLTRIM(tcDistValue)
DO CASE
	CASE LEN(tcDistValue) = 0
		RETURN .f.
	CASE tcDistValue == "."
		RETURN .t.
	CASE UPPER(tcDistValue) == "NONE"
		RETURN .t.
	OTHERWISE 
		*every character needs to be a number
		LOCAL i 
		FOR i = 1 TO LEN(tcDistValue)
			IF NOT BETWEEN(ASC(SUBSTR(tcDistValue, i,1)),48, 57)
				RETURN .f.
			ENDIF 
		ENDFOR 
		RETURN .t. &&every character is a number
ENDCASE