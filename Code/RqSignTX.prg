
****************get Rq Atty signature( TX docs)******************************************************************
*FUNCTION RqSignTX #60359
************************************************************************************************************
PARAMETERS c_RqAtty

LOCAL oMedRq AS OBJECT, c_Email AS STRING, 	l_gotemail AS Boolean

c_sign=""
_SCREEN.MOUSEPOINTER=11
oMedRq = CREATEOBJECT("generic.medgeneric")


oMedRq.closealias("AtSign")

oMedRq.sqlexecute("SELECT name_inv FROM tbldefendant WHERE at_code='" +c_RqAtty+ "' and active =1", "AtSign")

c_sign=IIF(ISNULL(ALLTRIM(AtSign.NAME_INV)),"",ALLTRIM(AtSign.NAME_INV))


_SCREEN.MOUSEPOINTER=0
RELEASE oMedRq

RETURN c_sign
