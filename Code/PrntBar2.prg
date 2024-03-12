*****************************************************************************
* PrntBar2.prg, Print individual Bar Code line for LRS.TAG and other strings
*
* Called by BillCovr
* History :
* Date      Name  Comment
* ---------------------------------------------------------------------------
*01/20/2006 - MD converted for VFP
*****************************************************************************
Parameter nlrsno, lntag, lnHeight, lnWidth
Private l_notag, nbarhi, nnarrow, n_parms
n_parms = PCOUNT()
nnarrow = IIF( n_parms < 4, 3.6, lnWidth)
nbarhi = IIF( n_parms < 3, 3, lnHeight)
l_notag = (PCOUNT() < 2)
If PCOUNT() < 1
   gfmessage( "Could not print Bar code.")
Return
Endif

*!*	*!*	DO gfBarDef WITH nnarrow, nbarhi
*!*	want to replace with call to barcode 39 font
Do lfBarCode with pc_lrsno, pn_Tag                  && print out bar code
*--Do lfBarCode with Master.lrs_no, CaseDeponent.Tag                  && print out bar code
Return

* --------------------------------------------------------------
* Print out bar code
* --------------------------------------------------------------
Procedure lfBarCode
Parameter nlrsno, lntag
*need to make sure nlrsno type is numeric
IF TYPE('nlrsno')='C'
	nlrsno=VAL(nlrsno)
ENDIF

PRIVATE arblines, szchars, szcode, ll_big
DIMENSION arbline[1]
EXTERNAL ARRAY artext

** determine if font for Atty needs to be printed in big size
IF TYPE("nlrsno") = "C"
   ll_big = IIF(ASC(LEFT(nlrsno,1))>=65, .T., .F.)
ELSE
   ll_big = .F.
ENDIF


if NOT l_notag
   ** Print Leading Zeros for RT# portion at Wayne's Request 
   arbline[1] = transform(nlrsno, "@L 99999999") + "." + transform(lnTag, "@L 999")

   If LEN(arbline[1]) < 9
      arbline[1] = arbline[1] + REPLICATE("-", 9 - LEN(arbline[1]))
   Endif
else
* If no tag was provided, nlrsno may be an attorney code or other string,
* so do not perform leading-zero padding.
* Print Leading Zeros for RT# portion at Wayne's Request 
   arbline[1] = alltrim(nlrsno)
endif

** Print the BarCode
Do lfPrtCode WITH arbline

WAIT CLEAR
RETURN

* --------------------------------------------------------------
PROCEDURE lfPrtCode
PARAMETERS artext
PRIVATE nbetween, nlength, nmargin, ll_went
ll_went = .T.
nlabelhi = 2
nskipline = nlabelhi - nbarhi
ncpi = 10
nwide = ROUND(nnarrow * 2.25, 0)                 && 2.25 x nNarrow
nlblacross = 3
bartext = SPACE(30)

&& Get current margin position
nmargin = SET("MARGIN")
SET MARGIN TO 0

? " " + Chr(13) + Chr(10) AT 0

* -- Do this for each row in the array --
FOR x = 1 TO ALEN(artext)
   && Setup for Code39 using "*" for check digits
   artext[x] = "*" + UPPER(ALLTRIM(artext[x])) + "*"
   bartext = ALLTRIM(artext[x])
   barstring = artext[x]

   && Code39 width
   nlength = (LEN(barstring) + 2) * ((3 * nwide) + (6 * nnarrow) + nnarrow)
   nbetween = IIF(nlblacross > 1, (2550 / nlblacross) - nlength, 0)
   ndistance = nlength + nbetween

   && This prints out the bar codes!!
   ??? SPACE(30) + gfcode39(barstring)
   ??? pc_esc + "*p+" + ALLTRIM(STR(nbetween,5)) + "X"
*!*	*!*			*need to replace the above with a call to font code39


   && Move Printer position to print the text!!
   FOR kk = 1 TO nbarhi - 1
      ??? CHR(10) + CHR(13)
   ENDFOR

   && Figure out how to print the text for the barcode(s)!!
** make At_code bigger in font, everything else should be normal (font 12)
   IF ll_big
      ? pc_f10
      ? pc_f18b + artext[x] AT 30
      ?
   ELSE
      ? pc_f12 + artext[x] AT 30
      ?
   ENDIF
   && Move Printer position to print the next barcode!!
NEXT x

SET MARGIN TO nmargin                           && Restore margin position
Return
