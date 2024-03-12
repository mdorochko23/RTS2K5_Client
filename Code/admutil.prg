PROCEDURE ADMUTIL
*  Called by RTS
*  Calls Caseclos, AcWitFee, UpdType, FLook_PA, CAPSNot, CASer, CAUpdTag
*  RateMain, gfClrCas, gfClrDep, UpdMirr

* 12/18/03 DMA  Eliminate unused rate-maintenance options
* 12/09/03 DMA  Full replacement for AdmCase.prg and AdmCase.spr
*
goApp.OpenForm("utility.frmadmutil", "", "", "")

RETURN
