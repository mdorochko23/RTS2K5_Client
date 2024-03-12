**Function HoldRulzA
LOCAL omed2 AS OBJECT
omed2=CREATEOBJECT("medmaster")
LOCAL lRetval as Boolean
lRetval=.f.
**#51529 - removed litigation rules for "S" when calculating a hold and comply
lRetval =omed2.SQLEXECUTE("exec DBO.GetHoldRulzAOnly", "Holdrulz")
IF lRetval
	=CURSORSETPROP("KeyFieldList", "Office, Litigation", "HoldRulz")
	INDEX ON OFFICE+ALLTRIM(LITIGATION) FOR ACTIVE TAG OFFLIT ADDITIVE
	INDEX ON OFFICE+ALLTRIM(LITIGATION) FOR ISSTYPE="A" TAG TYPEA ADDITIVE
ENDIF
RELEASE omed2
RETURN lRetval
