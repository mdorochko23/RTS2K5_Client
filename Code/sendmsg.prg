FUNCTION SendMsg
PARAMETER szmsg, nbtntype, reverse, titlestr

PRIVATE btnchoice, btnchoice2
**EF 5/9/01
IF PCOUNT() < 4
   titlestr = " RTS System Message "
ELSE
   titlestr = " " + ALLT(titlestr) + " "
ENDIF
** HN 1/15/98 Added reverse to switch default of buttons.
IF PCOUNT() < 3
   reverse = .F.
ENDIF
btnchoice = 1

*!*	DEFINE WINDOW wndmsg ;
*!*	   FROM INT((SROW()-6)/2),INT((SCOL()-62)/2) ;
*!*	   TO INT((SROW()-6)/2)+5,INT((SCOL()-62)/2)+61 ;
*!*	   TITLE titlestr ;
*!*	   NOFLOAT NOCLOSE DOUBLE

*!*	ACTIVATE WINDOW wndmsg

*!*	@ 1,1 SAY PADC(szmsg, WCOLS("WndMsg")-1)

DO CASE
   CASE nbtntype = 1
*!*	      @ 3,21 GET btnchoice PICTURE "@*HT \<OK" ;
*!*	         SIZE 1,8,1 DEFAULT 1
	
	MESSAGEBOX(szmsg,0,titlestr )


   CASE nbtntype = 2

		btnchoice = IIF(MESSAGEBOX(szmsg,4 + IIF(reverse, 256, 0),titlestr) = 6, 1, 2)

*!*	      btnchoice  = 0
*!*	      btnchoice2 = 0

*!*	      IF NOT reverse
*!*	         @ 3,(WCOLS("WndMsg")-11)/2 GET btnchoice ;
*!*	            PICTURE "@*HT \<Yes"
*!*	         @ 3,(WCOLS("WndMsg")-11)/2 + 7 GET btnchoice2 ;
*!*	            PICTURE "@*HT \<No"
*!*	      ELSE
*!*	         @ 3,(WCOLS("WndMsg")-11)/2 + 7 GET btnchoice2 ;
*!*	            PICTURE "@*HT \<No"
*!*	         @ 3,(WCOLS("WndMsg")-11)/2 GET btnchoice ;
*!*	            PICTURE "@*HT \<Yes"
*!*	      ENDIF

ENDCASE
&& _CUROBJ = OBJNUM(BtnChoice)

&& Wait for user input!!
*!*	READ CYCLE MODAL
*!*	IF nbtntype = 2
*!*	   IF btnchoice2 = 1
*!*	      btnchoice = 2
*!*	   ENDIF
*!*	ENDIF

*!*	DEACTIVATE WINDOW wndmsg
*!*	RELEASE WINDOW wndmsg

*!*	IF LASTKEY() = 27
*!*	   btnchoice = 0
*!*	ENDIF

RETURN btnchoice
