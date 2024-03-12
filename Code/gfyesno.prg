*****************************************************************************
* gfYesNo.Prg - prompt a yes/no question to user
*
* History :
* Date      Name  Comment
* ---------------------------------------------------------------------------
* 07/02/03  DMA   Auto-resize and word wrap message text
* 10/22/97  Hsu   Initial release
*****************************************************************************
Parameter lcMsg
*!*	Private llYes, lnYes, lnLen, n_strlen
*!*	n_strlen = LEN( lcMsg)
*!*	lnLen = IIF ( n_strlen > 76, 76, n_strlen) 
*!*	lnLen = IIF( lnLen < 20, 20, lnLen)
*!*	Define Window wYes At 14,(scol()-lnLen-4)/2 ;
*!*	   Size 5, lnLen + 2 ;
*!*	   Title " Confirmation " ;
*!*	   NoGrow NoFloat NoMinimize NoZoom Double Color Scheme 10
*!*	Activate Window wYes
*!*	lnYes = 1
*!*	@ 1,1 Say (lcMsg) SIZE ( n_strlen/76) + 1, lnLen
*!*	@ 3,lnLen - 16 Get lnYes Function "*HT \!\<Yes;\?\<No" Size 1,6,2
*!*	Read Cycle
*!*	Deactivate Window wYes
*!*	Release Window wYes

=gfmessage(lcMsg,.t.)

*--RETURN MESSAGEBOX(lcMsg,4," Confirmation ") = 6

*!*	RETURN (lnYes = 1)