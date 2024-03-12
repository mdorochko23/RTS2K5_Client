**07/05/2017: #64272 - stop looking at the firm and display a msg when Rq not the same as ordering 

PARAMETERS cAty, cRqAty, nRtNumber
LOCAL oMed as Object, l_retval as Boolean, s_str AS String
l_retval=.f.
s_str=""
_SCREEN.MOUSEPOINTER=11
oMed = CREATEOBJECT("generic.medgeneric")

IF USED('SameFirm')
	SELECT SameFirm
	USE
ENDIF
SELECT 0
s_str= "select [dbo].[NewLocationOrderAlert] ('" + cAty + "','" + cRqAty +"','" + STR(nRtNumber) +"')"
*s_str= "select [dbo].[qc_NewLocationOrderAlert] ('" + cAty + "','" + cRqAty +"','" + STR(nRtNumber) +"')"
l_retval=oMed.sqlexecute (s_str, "SameFirm")

IF NOT l_retval
		gfmessage("Failed to get the data.")
		RETURN
ENDIF

SELECT SameFirm
IF NOT EOF()	
	l_retval= NVL(SameFirm.exp,0)
ENDIF
	


RELEASE oMed
	_SCREEN.MOUSEPOINTER=0

RETURN l_retval
