*****************************************************************************
* gfUnUse.PRG - Close a table
*
* History :
* Date      Name  Comment
* ---------------------------------------------------------------------------
* 06/20/97  Hsu   Initial release
** Called by gfAddCom, NewDepo
*****************************************************************************
LPARAMETER lcTable, llUsed
LOCAL lcAlias

IF ! llUsed
	lcAlias = ALIAS()
	SELECT (lcTable)
	USE
	IF ! EMPTY(lcAlias) AND lcAlias != UPPER(lcTable)
		SELECT (lcAlias)
	ENDIF
ENDIF
RETURN
