**PROCEDURE qcissueopt3
LOCAL l_select AS Boolean
l_select=.F.
*AND  NOT pl_backbtn3  
IF NOT pl_exitpick 
	l_select=goApp.OpenForm("qcaipjobs.frmqcpicklitarea","M", "", "")

endif
RETURN l_select