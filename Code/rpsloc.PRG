*FUNCTION RpsLoc
**08/21/2017: New ACD Lines #67249
** get RPS location's code 
LOCAL c_offlocation as String, l_GetRps as Boolean, c_retval  as String
c_offlocation=""
l_GetRps=.f.
DO CASE

CASE pl_ofcMD OR pl_ofcPgh OR pl_OfcKop
	l_GetRps= Acdamnumber (pc_amgr_id)
	IF l_GetRps
		c_offlocation=IIF(ISNULL(LitRps.RpsOffCode), 'P', LitRps.RpsOffCode)
		IF EMPTY(ALLTRIM(c_offlocation))
			c_offlocation=pc_Offcode
		ENDIF
	ENDIF
	
	
	
OTHERWISE
c_offlocation=pc_Offcode
ENDCASE

c_retval= getLocCode(pc_offcode ,UPPER(pc_Litcode), UPPER( pc_area) , c_offlocation)


RETURN c_retval

******************************************
FUNCTION getLocCode
***************************************
PARAMETERS  c_office , c_lit, c_area, c_code

LOCAL lc_RetVal as String,  C_STR as String, oMed_acd as Object
oMed_acd = CREATEOBJECT("generic.medgeneric")

 lc_RetVal =c_code

oMed_acd.closealias ('RpsA')
c_str=" exec  [dbo].[GetRpsLocationCode] '" + c_office + "','" + c_lit + "','" + c_area + "'"
l_RetVal=oMed_acd.sqlexecute(C_STR, "RpsA")
IF USED('RpsA') 
SELECT RpsA
IF !EOF()
 lc_RetVal= NVL(RpsA.LocCode,c_code)
 
 ELSE
  lc_RetVal=c_code
endif

endif

RELEASE oMed_acd
RETURN lc_RetVal


******************************************
FUNCTION ACDPhone
***************************************
PARAMETERS  c_office , c_lit, c_area, c_phn
LOCAL lc_RetVal as String,  C_STR as String, oMed_acd as Object
oMed_acd = CREATEOBJECT("generic.medgeneric")
 
lc_RetVal=c_phn
oMed_acd .closealias ('RpsA')	
	c_str=" exec  [dbo].[GetRpsLocationCode] '" + c_office + "','" +UPPER(c_Lit)+  "','" + ALLTRIM(UPPER( c_area)  )+ "'"
	l_RetVal=oMed_acd .sqlexecute(c_str, "RpsA")
	IF USED('RpsA') 
SELECT RpsA
IF !EOF()
 lc_RetVal= NVL(RpsA.ACDPhone,c_phn)
 
 ELSE
  lc_RetVal=c_phn
endif

endif

RELEASE oMed_acd
RETURN lc_RetVal
	

