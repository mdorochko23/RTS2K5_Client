FUNCTION gfChkPln2_Msg(LI_PLANSTATUS)
*
*  Purpose:	Returns str message from provided integer return code from
*            	dbo.fn_GetPlanStatusInactRetDel.
*
*  11/06/2019, JH, ZD #144856
*
*  Called from:	gfChkPln2
*

PRIVATE li_RetPlanChk as Integer
PRIVATE ls_PlanMsg as String

IF TYPE("LI_PLANSTATUS") <> "N"
	ls_PlanMsg = "Can not determine..."
ELSE
	li_RetPlanChk = LI_PLANSTATUS
	ls_PlanMsg = ""
	IF li_RetPlanChk > 0
		IF li_RetPlanchk >= 10000
			ls_PlanMsg = ls_PlanMsg+ " is not found in the Plan table"
			li_RetPlanChk = 0
		ELSE		
			IF li_RetPlanChk >= 1000
				ls_PlanMsg = " has multiple active records"
				li_RetPlanChk = 0
			ELSE	
				ls_PlanMsg = ls_PlanMsg+ " is"
			ENDIF
		ENDIF
		IF li_RetPlanChk >= 100	
			ls_PlanMsg = ls_PlanMsg+ " inactive"
			li_RetPlanChk = li_RetPlanChk-100
			IF li_RetPlanChk > 0
			   ls_PlanMsg = ls_PlanMsg+","
			ENDIF   		
		ENDIF
		IF li_RetPlanChk >= 10	
			ls_PlanMsg = ls_PlanMsg+ " retired"
			li_RetPlanChk = li_RetPlanChk-10		
			IF li_RetPlanChk > 0
			   ls_PlanMsg = ls_PlanMsg+","
			ENDIF   		
		ENDIF
		IF li_RetPlanChk > 0	
			ls_PlanMsg = ls_PlanMsg+ " deleted"
		ENDIF
		ls_PlanMsg = ls_PlanMsg+". "
	ENDIF
ENDIF
RETURN ls_PlanMsg

ENDFUNC
