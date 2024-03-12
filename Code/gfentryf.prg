*****************************************************************************
* gfEntryF.PRG - return entry file name for a client
*
* History :
* Date      Name  Comment
* ---------------------------------------------------------------------------
* 06/12/97  Hsu   Initial release
*****************************************************************************
lParameter lcClient
local lcCode, lcEntry

lcCode = Upper(Left(lcClient,1))
RETURN lcCode
Do Case
   Case lcCode >= "A" and lcCode <= "F"
      lcEntry = f_ENTRY1
   Case lcCode >= "G" and lcCode <= "L"
      lcEntry = f_ENTRY2
   Case lcCode >= "M" and lcCode <= "R"
      lcEntry = f_ENTRY3
   Otherwise
      lcEntry = f_ENTRY4
EndCase
Return lcEntry
