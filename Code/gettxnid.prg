FUNCTION GetTxnID
*  Increments the system transaction ID count,
*  and returns the resulting Transaction ID to the calling program
*
** DMA 06/18/2002 Make all references to Txn_Big file explicit
** IZ  06/18/2002 Add soft-lock code to prevent duplicate IDs
** Called by gfAddTxn, AddRec, AddTxn21, AddWFee, AttCharg
**           CourFee, Gopher, Incoming, MemoTxn, NoLocTxn
**           OrigSubp, Paraleg, Prt2Rq, Statreq, Subp_PA, WitFee
**           ScanData, WitFNew
*****RETURN 0



	PRIVATE szalias, nid, nReproc

	szalias = ALIAS()
	nReproc = SET( "REPROCESS")
SET REPROCESS TO -1
SELECT 0
oMed = CREATEObject("generic.medgeneric")
oMed.opentable("Txn_big")
*!*	SELECT 0
*!*	USE (f_txn_big)

*!*	IF txn_big.num >= 9999000000
*!*	   WAIT WINDOW "Contact the IT Department!! " + CHR(13) + ;
*!*	      "Transaction ID counter will exceed 1,000,000 !!" + CHR(13) + ;
*!*	      "Function: GetTxnID()"
*!*	ENDIF

*!*	DO WHILE NOT RLOCK()
*!*	ENDDO
*!*	***IZ 06/18/02 add a soft lock to prevent duplicate txnid
	DO WHILE txn_big.flag
	ENDDO

	REPLACE txn_big.flag WITH .T.
	
nid = txn_big.num + 1
	REPLACE txn_big.num WITH nid
REPLACE txn_big.flag WITH .F.
	UNLOCK
	USE

IF NOT EMPTY(szalias)
   SELECT (szalias)
ENDIF
	SET REPROCESS TO nReproc

	ntxnid = nid
	RETURN nid
