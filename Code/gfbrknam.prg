FUNCTION GFBrkNam
*
* Breaks a one-field name into its component parts.

* 03/18/2004 DMA Initial Coding
*
PARAMETER c_longname, c_last, c_first, c_init, c_given
*
* Parameters:
*   c_longname:  Original name field, as stored in file, in the form
*                <surname> ;<given-name>
*                <given-name> may include an optional middle initial;
*                             the initial must be followed by a period
*                             and be the rightmost alphabetic
*                             character in the subfield
*   c_last:   last name(s)
*   c_first:  first name(s) w/o middle initial
*   c_init:   middle initial, w/o period
*   c_given:  complete given-name, including middle initial
*
PRIVATE n_semi
n_semi = AT( ";", c_longname)
IF n_semi > 0
   c_last = ALLT( SUBS( c_longname, 1, n_semi - 1))
   c_given = ALLT( SUBS( c_longname, n_semi + 1))
   IF RIGHT( c_given, 1) = "."
      c_init = SUBS( c_given, LEN( c_given) - 1, 1)
      c_first = ALLT( LEFT( c_given, LEN( c_given) - 2))
   ELSE
      c_init = " "
      c_first = c_given
   ENDIF
ENDIF
RETURN
