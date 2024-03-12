FUNCTION CHKMMYY
* Used in VALID clauses in screens cacasein, CaseInfo
*** Checks the month and year of the date for validity
*
*  02/01/00 DMA  Remove pre-Y2k code
*  10/04/99 DMA  Y2K changes
parameters chrdate
private chrcvt, mdy
** Accepts a field name or variable name containing a string
** of date type data.

if type(chrdate) = "C"                          && added for y2k tac
   chrcvt = &chrdate
   if chrcvt = "  /  /  " OR empty(chrcvt)
      return .t.
   else
      mdy = ctod(substr(chrcvt,1,3) + "01"+ substr(chrcvt, 6, 5) )
      if empty(mdy)
         return .f.
      else
         if val(substr(chrcvt, 4, 2)) < 0 OR val(substr(chrcvt, 4, 2)) > 31
            return .f.
         else
            return .t.
         endif
      endif
   endif
else
return .t.
endif
