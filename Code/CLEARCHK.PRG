PROCEDURE CLEARCHK
*** Called by RTS
*** ClearChk.Prg - Program to Clear Checks
*** For Philadelphia, California and Texas

** EF 04/13/06 - added to the FVP project
***-----------------------------------------------------------------------***
** 01/21/05  DMA  Use new-format plaintiff name
** 07/23/04  DMA  Make MonthArr into public array
** 12/02/03  kdl  Increase check range for kop office
** 03/20/03  kdl  Add un-void transaction record call
LOCAL l_ok as Boolean
l_ok=.t.
ON KEY LABEL "ESC" KEYBOARD ""

 l_ok=goApp.OpenForm("case.frmclearchk", "M")
IF NOT l_ok
 RETURN
ENDIF

RETURN
