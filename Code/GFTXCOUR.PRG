PROCEDURE gfTXCour
************************************************************************
** EF  03/08/06 Added to the VFP project
*------------------------------------------------------------------------
* DMA 06/29/04 Eliminate unnecessary code; define all values in gfGetCas
* DMA 06/28/04 Use global case-level variables
* EF  02/13/03 Add Federal-Georgia court caption
* EF  12/10/02 Add West Virginia court caption
* EF  12/28/01 Get Texas Court data
** Called from PrtTxQst, pWrQuest, Subp_PA, PTXAffid, TXWaiver
** Assumes that gfGetCas has been called prior to entry
***********************************************************************

DO PrintField WITH mv, "CourtOf", UPPER( pc_TxCtLn1)
DO PrintField WITH mv, "County", UPPER( pc_TxCtLn2)
DO PrintField WITH mv, "CrtDesc", UPPER( pc_TxCtLn3)
DO PrintField WITH mv, "CourtDays", pc_TxHold
RETURN
