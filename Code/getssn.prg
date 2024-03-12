PROCEDURE GetSSN
* Looks up employee's SSN in the UserCtrl file and stores it in
* public variable pc_SSNFull
** Called by Incoming, AddTxn21
** Calls gfUse, gfUnUse
** DMA 07/07/02 Use new public variables pc_SSNFull, pc_SSNLst4
** HN  04/05/02 Re-written to use UserCtrl table instead of EMP table.

PRIVATE llUserCtrl, szAlias
szAlias = ALIAS()

llUserCtrl = gfUse( "UserCtrl")
SET ORDER TO SSN4

pc_SSNFull = IIF( SEEK( ALLT( pc_SSNLst4)), UserCtrl.SSN, pc_SSNLst4)
= gfUnuse( "UserCtrl", llUserCtrl)

IF NOT EMPTY( szalias)
   SELECT (szalias)
ENDIF
RETURN
