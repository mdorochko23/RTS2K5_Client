

**FUNCTION QCPROCESS
PARAMETERS n_PickOpt
LOCAL ll_ret AS Boolean
&& pl_backbtn2 - [BACK] BUTTON ON THE CASE SELECTION (OPTION 2)
&& pl_backbtn3- [BACK] BUTTON ON THE ISSUE SELECTION (OPTION 3)
IF (pl_backbtn2 OR  pl_backbtn3 )
	ll_ret=.T.
ELSE

ll_ret=IIF(NOT pl_exitpick, .T.,.F.)
ENDIF


DO CASE
CASE n_PickOpt=1

	pc_ToDoFile=""
	goApp.OpenForm("qcaipjobs.frmexcelstart", "S")

CASE n_PickOpt=2
	IF NOT pl_backbtn2 && initial selection show only if it is not a [Back] funtion
		ll_ret=qccaseopt2()
	ENDIF
	IF ll_ret
		ll_ret=goApp.OpenForm("qcaipjobs.frmqccases", "M","C","C")
	ENDIF

CASE n_PickOpt=3
	IF NOT pl_backbtn3 && initial selection show only if it is not a [Back] funtion
		ll_ret=qcissueopt3()
	ENDIF
	IF ll_ret
	**10/06/2011 - new reaserch options have been added
		ll_ret=	goApp.OpenForm("qcaipjobs.frmqcjobselect","M")
		*ll_ret=	goApp.OpenForm("qcaipjobs.frmqcjobs","M")
	ENDIF

CASE n_PickOpt=4

	o_qctemp = CREATEOBJ("generic.medgeneric")
	o_qctemp.sqlexecute("SELECT [dbo].[getactual_mgrsetting] ('" + fixquote(ALLTRIM(goApp.CurrentUser.ntlogin)) + "')", "IfAcctMgr")
	RELEASE o_qctemp

	SELECT IfAcctMgr
	IF NVL(IfAcctMgr.EXP,"0")="1"
		ll_ret=goApp.OpenForm("qcaipjobs.frmqcpicklitarea","M", "L", "L")
		IF ll_ret
			goApp.OpenForm("qcaipjobs.frmqccases", "M","L","L")
		ENDIF


	ELSE
		gfmessage("Not authorized to use that option.")
	ENDIF

OTHERWISE

ENDCASE




RETURN ll_ret
