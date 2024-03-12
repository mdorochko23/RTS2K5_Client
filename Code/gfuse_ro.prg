*****************************************************************************
* gfUse_Ro.PRG - Open a table
*
* History :
* Date      Name  Comment
* ---------------------------------------------------------------------------
* 06/20/97  Hsu   Initial release
* 08/10/98  HN    Adapted to OPen a table for Read Only use.
*****************************************************************************
Parameter lcTable
Private llUsed, lcFile

If Used(lcTable)
   llUsed = .T.
   Select (lcTable)
Else
   llUsed = .F.
   Select 0
   lcFile = "f_" + lcTable
   Use (&lcFile) Noupdate
Endif
Return llUsed
