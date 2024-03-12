*****************************************************************************
* gfPush.Prg - save current work area environment
*  Workspace alias         (n,1)
*  Order (index tag)    (n,2)
*  Record number        (n,3)
*
* History :
* Date      Name  Comment
* ---------------------------------------------------------------------------
* 08/14/97  Hsu   Initial release
*****************************************************************************
** Called by gfAddTxn, gfAddCom
PARAMETER arStack

LOCAL  nRows

nRows = ALEN(arStack,1)                         && number of rows in stack
nRows = nRows + 1
DIMENSION arStack[nRows,3]
arStack[nRows,1] = ALIAS()
IF ! EMPTY(arStack[nRows, 1])
	arStack[nRows,2] = ORDER()
	arStack[nRows,3] = RECNO()
ENDIF
RETURN

