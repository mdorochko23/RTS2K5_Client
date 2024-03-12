FUNCTION CHKDATE
* Used by Valid clauses in cacasein.spr, CaseInfo.spr
*** CHKDATE ***
parameters chrdate
private chrcvt,mdy

** Accepts a field name or variable name containing a string
** of date type data.

if type(chrdate) = "C"                          && added for y2k tac
   chrcvt = &chrdate
   if chrcvt = "  /  /  " OR empty(chrcvt)
      return .t.
   else
      mdy = ctod(chrcvt)
      if empty(mdy)
         return .f.
      else
         return .t.
      endif
   endif
else
return .t.
endif
