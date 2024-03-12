**Parameters lcOffice
***************************************************************************
** EF  03/08/06  Switched to SQL
** DMA 05/11/04  Make array public to eliminate build error
** EF  3/16/04   remove #7 as default MD rps
** EF  1/07/04   add Rps21 ( Pasadena work in the K O P office), remove
**               a parameter and use public variables instead
** kdl 6/17/02   add RPS 9 setting
** EF  6/14/02   add CA Rps for 651 building
** EF  1/30/02   add Texas office
** EF  4/17/01   add CA offices
*****************************************************************************


 
i_Id=goApp.OpenForm("utility.frmrps","M","")
*!*	DO rps.spr WITH laRpsCh, lnDefRps
**Set Default RPS for each office**************

*FOR ln = 1 TO ALEN( laRpsCh, 1)
  * IF laRpsCh[ln]
    *  i = ln                                      && selected RPS
   *ENDIF
*NEXT
gnRps = IIF( pl_OfcOak AND INLIST( i_id, 2, 3, 4), 18, i_id)
RETURN gnRps
