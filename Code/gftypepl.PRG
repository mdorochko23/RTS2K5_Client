*****************************************************************************
* gfTypePl.PRG - get plan type from rate schedule plan table (Rev. 1)
*        plan.dbf must be opened before calling this function
*
* History :
* Date      Name  Comment
* ---------------------------------------------------------------------------
* 08/18/09 EF - notify users of non existing billing plans
* 10/04/05 kdl start: convert to use sql server table
* !!!!!!!!!  Note to developers: Will be removed from the RTS project ;
            once the FVP Billing is released. Aprox. Feb. 2004.
* 11/11/98  Hsu   Initial release
*****************************************************************************
Parameter lcPlan
LOCAL lcPlanType, lcAlias
lcAlias = Alias()
lcPlanType = " "

omed=create("medtimesheet")
*--4/5/23 kdl: ignore deleted rows [310147]
c_sql="SELECT [plan_type] FROM tblplan WHERE [plan]='&lcplan.' and active = 1"
*--c_sql="SELECT [plan_type] FROM tblplan WHERE [plan]='&lcplan.'"
omed.sqlexecute(c_sql,'plan')
IF RECCOUNT('plan')>0
   lcPlanType = plan.plan_type
ENDIF
IF USED('plan')
	USE IN plan
ENDIF
IF ! EMPTY(lcAlias)
   SELECT (lcAlias)
ENDIF
IF EMPTY(lcPlanType)
	Wait "The plan= "+lcPlan+ " does not exist in our system. Pelase edit it first."  Window
endif
RETURN lcPlanType



*--lcAlias = Alias()
*--Select Plan
*--Set Order to plan
*--If Seek(lcPlan)
*--   lcPlanType = plan_type
*--Endif
*--If ! Empty(lcAlias)
*--   Select (lcAlias)
*--Endif

* Wait "plan="+lcPlan+ " type="+lcplantype Window

*--Return lcPlanType
