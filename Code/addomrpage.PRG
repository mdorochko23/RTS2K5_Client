**FUNCTION addomrpg
PARAMETERS c_ReqType,  l_Fax
LOCAL l_add AS Boolean

DO CASE
CASE  pl_KOPVer  AND (c_ReqType=="A") AND NOT l_Fax
	l_add =.T.

CASE  pl_ILcook AND c_ReqTypE="S"
	l_add =.T.
OTHERWISE

	l_add =.F.
ENDCASE



RETURN  l_add
