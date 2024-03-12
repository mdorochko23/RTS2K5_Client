** Yesno.prg - Handles longer strings as input.

parameters msg

*!*	set intensity off
*!*	msg = msg + space(2)
*!*	on key label esc keyboard ""

*!*	winlen = min(len(msg)+6,79)
*!*	msgrow = round(len(msg)/74,0)+1

*!*	define window yesno from 1,1 to msgrow+6,winlen title " User Confirmation "
*!*	** color scheme 1

*!*	move window yesno center
*!*	activate window yesno
*!*	clear gets

*!*	okcan = 1
*!*	@ 0,1 EDIT msg ;
*!*	   size msgrow,74;
*!*	   DEFAULT " " ;
*!*	   WHEN _curobj = _curobj + 1 ;
*!*	   color W+/B
*!*	@ msgrow+2,(winlen-12)/2 GET okcan ;
*!*	   PICTURE "@*HT Yes;No" ;
*!*	   SIZE 1,5,1 ;
*!*	   DEFAULT 1

*!*	read
*!*	release window yesno
*!*	release window userinp
*!*	on key label esc

return yesorno(msg)
