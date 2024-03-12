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
SET EXCLUSIVE ON
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

EndWith

*//Setup working environment
With _Screen

  .Caption = "RTS Client (Development)"
  .FontSize = 8
  .Fontname = "Arial"
  .MousePointer = 0
  .ForeColor = RGB(0,0,0)
  .BackColor = RGB(255,255,255)

ENDWITH

SET PATH to class;code;header;library;media;project;report

MODIFY PROJECT project\rts nowait