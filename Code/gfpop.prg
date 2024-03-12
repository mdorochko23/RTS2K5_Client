*****************************************************************************
* gfPop.Prg - restore last saved work area environment
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
PARAMETERS arStack

local nRows

nRows = ALEN(arStack,1)
IF nRows > 1                                    && first row is dummy
	IF ! EMPTY(arStack[nRows,1])
		SELECT (arStack[nRows,1])                 && back to workspace
		IF RECCOUNT() >= arStack[nRows,3]
			GO arStack[nRows,3]                    && and correct record
		ENDIF
		IF EMPTY(arStack[nRows,2])
			SET ORDER TO
		ELSE
			SET ORDER TO (arStack[nRows,2])
		ENDIF
	ENDIF
	DIMENSION arStack[nRows - 1,3]               && pop stack pointer
ELSE
	= gfMsg("Stack Underflow. See MIS department.")
ENDIF
RETURN

