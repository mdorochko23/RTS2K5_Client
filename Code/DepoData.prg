

*FUNCTION DepoData
Parameters  cmailid, cDeptype, lMixedLt
LOCAL l_ok as Byte
l_ok =.f.
lnCurArea=ALIAS()
_SCREEN.MOUSEPOINTER=11
PRIVATE OMED_d AS OBJECT
OMED_d=CREATEOBJECT("generic.medgeneric")
SELECT 0

IF  lMixedLt
l_ok =OMED_d.SQLEXECUTE("exec dbo.MixedCaseDepInfoByMailIdDept '" + cmailid+"','" + CDEPTYPE + "' ", "pc_DepoFile")
else
l_ok =OMED_d.SQLEXECUTE("exec dbo.GetDepInfoByMailIdDept '" +  cmailid+"','" + CDEPTYPE + "' ", "pc_DepoFile")
ENDIF


RELEASE omed_d
IF !empTy(lnCurArea)
SELECT (lnCurArea)
endif

RETURN l_ok

