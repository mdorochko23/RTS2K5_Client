FUNCTION YesOrNo
parameters msg

*private userinp,esckey

*msg = msg + space(2)

*esckey = on("key", "escape")
*on key label esc keyboard ""
*userinp = .t.

*winlen = min(len(msg)+6, 79)
*msgrow = round(len(msg)/74, 0) + 1

*define window w_yesno from 1,1 to msgrow+3, winlen ;
   title " User Confirmation ";
   double shadow color scheme 1

*move window w_yesno center
*activate window w_yesno
*clear gets

*@ 1,1 say msg get userinp picture "@! Y"
*read
*release window w_yesno
*on key label esc &esckey

LOCAL l_confirm
l_confirm=gfmessage(msg,.T.)
RETURN (l_confirm)

*--return MESSAGEBOX(msg,4," User Confirmation ") = 6
