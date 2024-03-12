**05/30/2017: get email for Rq Atty ( TX docs)
PARAMETERS n_type, c_RqAtty
LOCAL oMedRq AS OBJECT, c_Email AS STRING, 	l_gotemail AS Boolean
l_gotemail=.F.
c_Email =""
_SCREEN.MOUSEPOINTER=11
oMedRq = CREATEOBJECT("generic.medgeneric")

oMedRq.closealias("AtEmail")
l_gotemail=oMedRq.sqlexecute("select dbo.GetAtEmail4Docs ('" + fixquote(c_RqAtty) + "')","AtEmail")
IF l_gotemail
	c_Email=LOWER(IIF(ISNULL(ALLTRIM(AtEmail.EXP)),"",ALLTRIM(AtEmail.EXP)))
ENDIF
_SCREEN.MOUSEPOINTER=0
RELEASE oMedRq

RETURN c_Email
