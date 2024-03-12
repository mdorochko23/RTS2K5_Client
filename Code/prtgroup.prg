FUNCTION  PrtGroup
* 8/6/09   Called By: kopreqcov
PRIVATE mv_g as memo
mv_g=""
DO PrintField WITH mv_g, "GroupName", ;
   IIF( pl_noGroup, "", "Group: " + PROPER( pc_grpname))
DO PrintField WITH mv_g, "GCaseName", ;
   IIF( pl_noGroup, "", "Main Case Name: " + PROPER( pc_casname))
DO PrintField WITH mv_g, "CaseNum", ;
   IIF( pl_noGroup, "", "Case Number: " + PROPER( pc_casenum))
RETURN mv_g
