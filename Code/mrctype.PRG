**************************************************************
*baby, mom, dad - MRC cases
**************************************************************

PARAMETERS  ln_RT
LOCAL  OMED1 AS OBJECt, c_CurArea AS String, c_type as String
c_CurArea=ALIAS()
_SCREEN.MOUSEPOINTER=11
PRIVATE OMED AS OBJECT
OMED1=CREATEOBJECT("generic.medgeneric")
l_ok=.t.
omed1.closealias("MRCType")
c_type=""

IF NOT EMPTY(ln_RT)
		lc_sql=""		
	
		lc_sql ="select dbo.getMRClinktype( '" +STR(ln_rt) + "')"
		omed1.SQLEXECUTE( lc_sql,"MRCType")
		SELECT MRCType
		IF !EOF()	
			c_type=ALLTRIM(NVL(MRCType.exp, ''))

		ENDIF

ENDIF

RELEASE OMED1
IF NOT EMPTY(c_CurArea )
SELECT (c_CurArea )
ENDIF

RETURN c_type