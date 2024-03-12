LPARAMETERS lcAcctMgr
LOCAL oMed, lcSQLine, retval, lnCurArea
lnCurArea=SELECT()
oMed = CREATEOBJECT("generic.medgeneric")		
retval=""
lcSQLLine="select initials from tbluserctrl where login='"+;
ALLTRIM(UPPER(lcAcctMgr))+"'"
omed.sqlexecute(lcSQLLine, "viewInits")
IF USED("viewInits")
	SELECT viewInits
	IF RECCOUNT()>0
	   retval=ALLTRIM(UPPER(NVL(viewInits.initials,"")))
	ENDIF 
	USE IN viewInits
ENDIF
SELECT (lnCurArea)
RETURN retval

