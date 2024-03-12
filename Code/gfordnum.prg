FUNCTION gfOrdNum
* Utility function to generate the ordinal suffix for a day of the month
* 05/28/03 DMA Original coding
PARAMETER n_day
* If n_day is a date variable, the day of the month is extracted.
* If n_day is numeric, program assumes that the day of the month was
*   already extracted.
PRIVATE c_ordinal, n_work
IF TYPE ("n_day") = "D"
   n_work = DAY( n_day)
ELSE
   n_work = n_day
ENDIF
DO CASE
   CASE INLIST( n_work, 1, 21, 31)
      c_ordinal = "st"
   CASE INLIST( n_work, 2, 22)
      c_ordinal = "nd"
   CASE INLIST( n_work, 3, 23)
      c_ordinal = "rd"
   OTHERWISE
      c_ordinal = "th"
ENDCASE
RETURN c_ordinal
