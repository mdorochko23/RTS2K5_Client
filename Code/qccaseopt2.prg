**PROCEDURE qccaseopt2
LOCAL l_select as Boolean
l_select=.f.
*SUSPEND &&qccaseopt2
IF NOT pl_exitpick
l_select=goApp.OpenForm("qcaipjobs.frmqcpicklitarea","M", "C", "C")
ENDIF
*!*		IF l_select
*!*			goApp.OpenForm("qcaipjobs.frmqccases", "M","C","C")
*!*		ENDIF
RETURN l_select