*function GetTxHoldDays
*#255675 WY 12/19/2021
PARAMETERS tnLrsno as Integer, tnTag as Integer, tcCourt as String

LOCAL loMed, lnCurAlias, lnHoldType, lnResultDays, lcSql 
lnCurAlias=SELECT()
loMed = CREATEOBJECT("generic.medgeneric")		
lnResultDays=0
lnHoldType = 0
lcSql = "SELECT Holdtype FROM tblQCExtraTagData WHERE Lrs_No = " + ;
				ALLTRIM(STR(tnLrsno)) + " and tag = " + ALLTRIM(STR(tnTag)) + " and deletedby is null"
loMed.sqlexecute(lcSql, "curHoldType")
IF USED("curHoldType")
	lnHoldType = curHoldType.Holdtype
	USE IN curHoldType
ENDIF 

DO CASE 
	CASE lnHoldType = 10
		lnResultDays = 10
	CASE lnHoldType = 20 
		lnResultDays = 0 && skip caller already have tblcourt.comply and tblCourt.hold
	*--CASE lnHoldType = 24	&& 06/24/2022 MD #
	CASE INLIST(lnHoldType,24,11)		
		*--lcSQL="Select financialHold as hold FROM tblcourt WHERE court = '" + tcCourt + "'"
		lcSQL="exec dbo.qc_TXFinancialHoldDays '"+ALLTRIM(tcCourt)+"', "+ALLTRIM(STR(lnHoldType))
		loMed.sqlexecute(lcSQL, "finHold")
		IF USED("finHold")
			lnResultDays = finHold.hold
			USE IN finHold
		ENDIF		
	OTHERWISE 
		lnResultDays=0
ENDCASE
RELEASE loMed
SELECT (lnCurAlias)
RETURN lnResultDays