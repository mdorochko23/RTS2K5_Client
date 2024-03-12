PROCEDURE gfClrDep
*
*   Clears the global variables (defined in Public.prg) which store critical
*   information about a deponent, that were filled in from Record.dbf and
*   subsidiary databases by companion routine gfGetDep.
*
*   REMINDER: Changes to this routine should be made in parallel with
*             changes to gfGetDep and Public.
*
*   Assumes that gfGetCas has already been called for the current case.
*
*   Called by New4Scr, Subp_pa, SortDep, CovPage, PrtCovP, Print30,
*             TheNotic, RStatus, CaseWork
*
*   Original coding: 11/2/2003 DMA
*  05/03/05  DMA  Remove commented reference to unused module DepDirec
*
STORE 0 TO pn_DepoRec, pn_Tag, pn_AFaxNo, pn_AFCount, pn_AFChkAmt, ;
   pn_Suppto

STORE "" TO pc_Depokey, pc_AdmKey, pc_DepoRCA, pc_Descrpt, pc_MailID, ;
   pc_IssType, pc_DepType, pc_DepoFile, pc_DepoDept, pc_Status, ;
   pc_IncCode, pc_NRSType, pc_RevStat, pc_RevLine, pc_FaxAttn, pc_BBType, ;
   pc_BBRound, pc_BBWebNo, pc_BBLocNo, pc_BBNuRCA, pc_TflAtty, pc_Tag, ;
   pc_TrimTag, pc_TagDist, pc_tagType, pc_ScanDocType

STORE {//} TO pd_OpenDep, pd_ReqDate, pd_ReqMail, pd_Expdate, pd_RschDate, ;
   pd_UpldDate, pd_rpsPrint

STORE .F. TO pl_Reissue, pl_Incompl, pl_HasNRS, pl_FromRev, pl_AMResp, ;
   pl_HoldPsy, pl_AutoFax, pl_Expdte, pl_Scann, pl_BBSent, pl_FrstLook, ;
   pl_Redacted, pl_Distrib, pl_Pickup, pl_Resrch, pl_WaivRcvd, pl_softflg

pl_GotDepo = .F.



RETURN
