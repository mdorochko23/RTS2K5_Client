FUNCTION gfCode39
** 03/23/01 DMA Extracted from Barcode, Printbar, Prntbar2
**  to eliminate repeated code
** Assumes that gfBarDef has been already called to
** define all bar-code characters and constants.

PARAMETERS x_text
Private ctext, x_letter, n_letter

ctext = ""
For n_letter = 1 TO LEN(x_text)
   x_letter = SUBSTR(x_text, n_letter, 1)
   n_havecode = AT(x_letter, pc_BChars)
   ctext = ctext + IIF( n_havecode=0, x_letter, pc_barchar[n_havecode]) ;
      + pc_esc + "*p+" + pc_narrow + "X"
EndFor
ctext = pc_xstart + ctext + pc_xend
RETURN ctext
