*//Reset environment
POP KEY ALL
ON SHUTDOWN
ON ERROR
SET HELP OFF
 
SET HELP ON
SET RESOURCE ON
SET SYSMENU TO DEFAULT
SET SAFETY OFF
SET TALK OFF
SET ESCAPE ON
SET EXCLUSIVE off
SET DECIMAL TO 8
CLEAR PROGRAM
CLEAR READ ALL
CLEAR ALL
CLEAR
CLOSE ALL
RELEASE ALL
SET LIBRARY TO
SET CLASSLIB To
SET NULLDISPLAY TO
SET PATH TO data
SET PRINTER OFF
SET PRINTER TO 
CLOSE DATA ALL
 
= SQLDisconnect(0) && Close all active connections
= SQLSetProp(0, "DispLogin", 1) && Allow the login dialog
 
With _VFP
 
 .AutoYield = .T.
	.EditorOptions = "LQKWT"
 
EndWith

 _INCLUDE = ".\header\App.h"

clear
set library to
set procedure to

*-- Set the Default Search path
SET PATH to Class;Code;Header;Library;media;Menu;Project;Report;.\Data


LOCAL lsIniFile as sTRING


IF File(".\project\rts.pjx")

	lsIniFile = "rts.ini"

	*-- Make sure ini file is not readonly
	=SetFileAttributes(".\rts.ini", 0)

	*-- Make sure project is not readonly
	=SetFileAttributes(".\project\rts.pjx", 0)
	=SetFileAttributes(".\project\rts.pjt", 0)

	MODIFY PROJECT .\project\rts nowait

Endif

IF File(".\project\data.pjx")

	lsIniFile = "rtsData.ini"


	*-- Make sure ini file is not readonly
	=SetFileAttributes(".\rts.ini", 0)

	*-- Make sure project is not readonly
	=SetFileAttributes(".\project\Data.pjx", 0)
	=SetFileAttributes(".\project\Data.pjt", 0)


	MODIFY PROJECT .\project\data nowait
Endif

WITH _Screen
	.Icon=".\media\app.ICO"
	.Caption = Sys(5) + Sys(2003)
	.fontname = "FixedSys"
	.fontsize = 9
	.fontbold = .f.
  .BACKCOLOR 	= VAL(MLPriPro("R",lsIniFile,"App","BackColor",Alltrim(Str(.BackColor))))
  .ForeCOLOR 	= VAL(MLPriPro("R",lsIniFile,"App","ForeColor",Alltrim(Str(.ForeColor))))
EndWith

acti wind command

CANCEL
