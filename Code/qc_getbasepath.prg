*FUNCTION qc_getbasepath

PARAMETERS CRt, c_webOrder, C_LocId, l_excelorders

LOCAL c_basepath AS STRING, oCon as Object
oCon = CREATEOBJ("generic.medgeneric")
c_basepath=""

IF l_excelorders
								** [dbo].[qc_ExcRetImageFile](217091,100089190,4978)
	oCon.sqlexecute("select [dbo].[qc_ExcRetImageFile] ('" + cRt + "','" + c_webOrder + "','"  + C_LocId+ "')" ,'NewBase')
	SELECT NewBase
	IF NOT EOF() 
	IF !EMPTY(ALLTRIM(NewBase.EXP))
		c_basepath =ALLTRIM(NewBase.EXP)	
	ENDIF
	ENDIF
ELSE
**show an existing one - an old one, but latests if there are few base per a case

	c_basepath= srchimgdir(ALLTRIM(cRt), .F.)



ENDIF

return  c_basepath