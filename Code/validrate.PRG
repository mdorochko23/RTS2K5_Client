***************************************************************************************************************************
**11/12/2012 EF: added to validate billing rates 
***************************************************************************************************************************
PARAMETERS c_plan, c_rate


LOCAL lc_message as String,  obj_med AS OBJECT, ln_CurArea AS String, lc_sql as String, lc_val as String

ln_CurArea=ALIAS()
lc_val= c_rate
obj_med=CREATEOBJECT("generic.medgeneric")
SELECT 0


obj_med.closealias('ChkCat')

lc_sql=""
lc_sql=" select [dbo].[IfBillCatDisabled] ('" +c_Plan+  "','" + c_rate + "')"
	
obj_med.SQLEXECUTE(lc_sql,'ChkCat')
	
IF USED(	'ChkCat')
IF NVL(ChkCat.exp,.F.)
 	gfMessage("That Billing Category does not exists for selected plan. Pick another one or cancel.")  
	lc_val=""
	
ENDIF
ENDIF

RELEASE obj_med

IF NOT EMPTY(ln_CurArea)
SELECT (ln_CurArea)
ENDIF
RETURN lc_val