*FUNCTION GetFirmCodeForAtt
PARAMETERS pat_code

LOCAL oMedTMP AS OBJECT
c_save = SELECT()

oMedTMP = CREATEOBJECT("generic.medgeneric")
c_RetFirmCode = ""

c_sql="select [dbo].[GetFirmCode] ('" + fixquote(pat_code) + "')"
oMedTMP.sqlexecute(c_sql,"lup_firmcode")
IF USED("lup_firmcode")
	SELECT lup_firmcode
	IF NOT EOF()
		c_RetFirmCode=UPPER(ALLTRIM(NVL(lup_firmcode.EXP,0)))
	ENDIF
ENDIF

oMedTMP.closealias("lup_firmcode")
RELEASE oMedTMP

select(c_save)

RETURN c_RetFirmCode
