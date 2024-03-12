**************************************************************************************
* PROGRAM: GFDSTYPE
* Programmer: kdl
* Date: 7/20/04
* Abstract: Convert single character ship type to 2 chr ship type
**************************************************************************************
PARAMETER c_Input
IF PARAMETERS() < 1
	RETURN "P"
ENDIF

c_Input = UPPER(c_Input)
c_String = IIF( c_Input = "D", "DS", ;
	IIF( c_Input = "C", "CD", ;
	IIF( c_Input = "V", "VS", ;
	IIF( c_Input = "M", "MT", ;
	IIF( c_Input = "W", "DV", ;
	IIF( c_Input = "F", "FT", "P"))))))

RETURN c_string
