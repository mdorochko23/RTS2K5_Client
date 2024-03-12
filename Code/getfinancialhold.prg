*function GetFinancialHold
*11/10/2021 WY #255663 (obtain tblCourt.financialHold for TX financial)
PARAMETERS tnLrsno as Integer, tnTag as Integer, tcCourt as String

LOCAL loMed, lcSQLine, lnCurArea, lnResult
lnCurArea=SELECT()
loMed = CREATEOBJECT("generic.medgeneric")		
lnResult=0

IF IsUsingFinancial(loMed, tnLrsno, tnTag)
	lcSQLLine="Select financialHold as hold FROM tblcourt WHERE court = '" + tcCourt + "'"
	loMed.sqlexecute(lcSQLLine, "finHold")
	IF USED("finHold")
		lnResult = finHold.hold
		USE IN finHold
	ENDIF 
ELSE
	lnResult = 0 && not using Tx Financial fields
ENDIF 
RELEASE loMed
SELECT (lnCurArea)
RETURN lnResult


FUNCTION IsUsingFinancial (toMed, tnLrsno as Integer, tnTag as Integer) as Boolean
	LOCAL lcSQL, llResult
	llResult = .f.
	lcSql = "SELECT financial FROM tblQCExtraTagData WHERE Lrs_No = " + ;
				ALLTRIM(STR(tnLrsno)) + " and tag = " + ALLTRIM(STR(tnTag)) + " and deletedby is null"
	
	toMed.sqlexecute(lcSql, "fin")
	IF USED("fin")
		IF ConvertToNum(fin.financial) = 1
			llResult = .t.
		ENDIF 
		USE IN fin
	ENDIF
	RETURN llResult
ENDFUNC