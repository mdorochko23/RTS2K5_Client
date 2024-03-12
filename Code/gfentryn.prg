*****************************************************************************
* gfEntryN.PRG - return entry name for a client
*
* History :
* Date      Name  Comment
* ---------------------------------------------------------------------------
* 06/12/97  Hsu   Initial release
*****************************************************************************
** Called by gfAddTxn
lParameter lcClient
LOCAL lcCode, lcEntry

lcCode = Upper(Left(lcClient,1))
Do Case
   Case lcCode >= "A" and lcCode <= "F"
      lcEntry = "ENTRY1"
   Case lcCode >= "G" and lcCode <= "L"
      lcEntry = "ENTRY2"
   Case lcCode >= "M" and lcCode <= "R"
      lcEntry = "ENTRY3"
   Otherwise
      lcEntry = "ENTRY4"
EndCase
Return lcEntry
