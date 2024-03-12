** 11/19/2018 YS #117438 Not allowed to change the bill category when tags on the case have disabled bill category

PARAMETERS c_plan, c_rate, c_clcode, c_idTblBills 


LOCAL lc_message as String,  obj_med AS OBJECT, ln_CurArea AS String, lc_sql as String, lc_val as String

ln_CurArea=ALIAS()
lc_val= c_rate
obj_med=CREATEOBJECT("generic.medgeneric")
SELECT 0


obj_med.closealias('ChkCat')

lc_sql=""
lc_sql=" select [dbo].[IfBillCatDisabled] ('" +c_Plan+  "','" + c_rate + "')"
	
obj_med.SQLEXECUTE(lc_sql,'ChkCat')
	
IF USED('ChkCat')
IF NVL(ChkCat.exp,.F.)
 	gfMessage("That Billing Category does not exists for selected plan. Pick another one or cancel.")  
	lc_val=""
ELSE
	lc_sql=""
	lc_sql=" select [dbo].[fn_CheckOrderBillCat] ('" + fixquote(c_clcode)+ "','" +c_idTblBills + "','" +c_Plan + "')"
	
	obj_med.SQLEXECUTE(lc_sql,'ChkUpd')
	
	IF USED('ChkUpd')
		IF !NVL(ChkUpd.exp,.T.)
		 	gfMessage("The billing plan can not be changed to this plan."+CHR(13)+"The billing category saved for existing tags does not exist for this plan."+CHR(13)+;
		 				"Update the billing category for existing tags, choose a different billing plan or"+CHR(13)+"contact accounting with questions.")  
			lc_val=""
		ENDIF
	ENDIF 
	
ENDIF
ENDIF

RELEASE obj_med

IF NOT EMPTY(ln_CurArea)
SELECT (ln_CurArea)
ENDIF
RETURN lc_val
