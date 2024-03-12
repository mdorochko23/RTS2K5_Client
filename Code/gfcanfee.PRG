******************************************************************************
* gfCanFee.Prg - get cancel fee for an attorney's rate schedule
*   Tabills and order tables must be open before calling this function.
*
* Date      Name  Comment
* ---------------------------------------------------------------------------
* 06/02/06  EF    Edited to use stored proc to get tblBill data
* 09/15/05  Kdl   Converted to access to SQL table where available
* 11/13/97  Hsu   Initial release
******************************************************************************
PARAMETER lcClient, lnTag, lcAtty
LOCAL lnCancel, lcPlan, lcPlanType,llrate

lnCancel = 0
lcPlan = ""
lcPlanType = ""
llrate=.f.
*c_sql="SELECT b.[plan], b.plan_type " + ;
	"FROM tblbill b WITH (index (ix_tblbills_2)) INNER JOIN tblorder o ON b.id_tblbills = o.ID_tblbills " + ;
	"WHERE b.at_code = '&lcatty.' AND b.cl_code='&lcclient.' AND o.tag="+ALLTRIM(STR(lnTag))+" AND b.invoice_no=0"
c_sql="exec dbo.GetPlanAndPlanType '" + fixquote(lcClient) + "','"  ;
 + 	lcAtty + "','" + STR(lntag) + "'"
 
omed=CREATE("medtimesheet")

l_plan= omed.sqlexecute(c_sql,'plan')
IF NOT l_plan AND EOF()
 RETURN 0
ENDIF
SELECT plan
IF RECCOUNT('plan')>0
	lcPlan = plan.plan
	lcPlanType = plan.plan_type
	lcPlanType=IIF(NOT INLIST(lcPlanType,'P','F'), 'P', lcPlanType)
	USE IN plan
ELSE
	USE IN plan
	RETURN 0
ENDIF

IF ! EMPTY(lcPlan) AND ! EMPTY(lcPlanType)
	IF lcPlanType = "P"
		IF NOT USED('rateschd')
			USE T:\VFPFree\Global\rateschd
			llRate = .T.
		ENDIF
	ELSE
		IF NOT USED('ratefile')
			USE T:\VFPFree\Global\ratefile
			llRate = .T.
		ENDIF
	ENDIF
	SET ORDER TO idcode
	IF SEEK(lcPlan+"CANCFEE")
		lnCancel = rate
	ELSE
	ENDIF
	IF llrate AND USED('rateschd')
		USE IN rateschd
	ENDIF
	IF llrate AND USED('ratefile')
		USE IN ratefile
	ENDIF
ENDIF

RETURN lnCancel

