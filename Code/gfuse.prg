*****************************************************************************
* gfUse.PRG - Open a table
*
* History :
* Date      Name  Comment
* ---------------------------------------------------------------------------
* 06/20/97  Hsu   Initial release
**  Called by gfAddCom, RCUWand, NewDepo
*****************************************************************************
LPARAMETER lcTable
LOCAL llUsed, lcFile

IF USED(lcTable)
	llUsed = .T.
	SELECT (lcTable)
ELSE
	llUsed = .F.
	SELECT 0
	lcFile = "f_" + lcTable
	IF pl_CAVer
		USE (&lcFile) AGAIN
	ELSE
		USE (&lcFile)
	ENDIF
ENDIF
RETURN llUsed
