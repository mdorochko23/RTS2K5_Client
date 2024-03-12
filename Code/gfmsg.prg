*****************************************************************************
* gfMsg.PRG - display warning message
*
* History :
* Date      Name  Comment
* ---------------------------------------------------------------------------
* 06/12/97  Hsu   Initial release
*****************************************************************************
Parameter lcMsg, llNoWait

Wait Clear
If Parameter() = 1 Or ! llNoWait
   gfmessage(lcMsg)
Else
   Wait Window lcMsg + Chr(13) + "Please wait." NOWAIT NOCLEAR 
Endif
Return
