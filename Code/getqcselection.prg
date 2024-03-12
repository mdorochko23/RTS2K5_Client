**FUNCTION getqcselection
PARAMETERS c_OrdType
LOCAL ln_pick as Integer
DO CASE
	CASE c_OrdType="WebE"
		ln_pick=1		
	CASE c_OrdType="WebC"
		ln_pick=2		
	CASE c_OrdType="WebN"		
		ln_pick=3
	CASE c_OrdType="WebL"	
		ln_pick=4
		
	OTHERWISE
	ln_pick =3 
ENDCASE

RETURN ln_pick