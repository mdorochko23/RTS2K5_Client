FUNCTION nempty(txInput)
* works like EMPTY(), except returns TRUE for NULL values
* like EMPTY(), accepts most data types as input, returns T or F
* (useful when one wants to treat a null value or empty value the same - which is often)

IF EMPTY(txInput) OR ISNULL(txInput)
	RETURN .T.
ELSE
	RETURN .F.
ENDIF
* end of FUNCTION nempty()
