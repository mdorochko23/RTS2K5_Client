FUNCTION gfDtSkip
*
*  Calls: gfChkDat
*  Called by: FLPrint, FLProc, RepRqCov, SetRec, Subp_PA, TXReprin
*             FLCov1.spr
*
* 06/20/02 DMA Revised to use gfChkDat for more accurate identification
*              of holidays (both fixed and floating)
*
PARAMETERS d_Date, n_Skip
**  d_Date: Starting date
**  n_Skip: Number of business days to skip

*** Returns the date of the first business day that is <<n_Skip>> business
*** days after <<d_Date>>.

PRIVATE n_Skipped, d_NewDate

d_NewDate = d_Date

FOR n_Skipped = 1 TO n_Skip
   d_NewDate = gfChkDat( d_NewDate + 1, .F., .F. )
ENDFOR
RETURN d_NewDate
