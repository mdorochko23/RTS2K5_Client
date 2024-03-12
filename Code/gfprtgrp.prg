PROCEDURE gfPrtGrp
*EF 09/29/05 -added to the MEI RTS
*----------------------------------old comments-----------------------------
* 09/17/2002 DMA Eliminate printing of headers when no data available
* 08/28/2002 DMA Consolidates printing of group/case information
*                (for Ohio Asbestos cases)
*
*   Assumes gfGetCas has been previously called to set pl_noGroup
*   pl_noGroup = .T. if there is no group info available for the case
*   pl_noGroup = .F. if the case is litigation = Asbestos or Silica,
*                    area = Ohio, filing office = KoP, and there is
*                    group info stored in the CaseInfo file.
*
*  Calls: PrintField
*  Called By: Print30, ReqAuth, Subp_PA, TheNotic, TxReprin
*
DO PrintField WITH mv, "GroupName", ;
   IIF( pl_noGroup, "", "Group: " + PROPER( pc_grpname))
DO PrintField WITH mv, "GCaseName", ;
   IIF( pl_noGroup, "", "Main Case Name: " + PROPER( pc_casname))
DO PrintField WITH mv, "CaseNum", ;
   IIF( pl_noGroup, "", "Case Number: " + PROPER( pc_casenum))
RETURN
