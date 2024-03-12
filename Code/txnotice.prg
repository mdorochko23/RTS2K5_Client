PROCEDURE TXNotice
*
*                TEXAS NOTICE RE-PRINT PROCEDURE
*
*   Reprint all notices for a specific case and day.
** EF 3/20/06 EF Added to the VFP proj.
**---------------------------------------------------------------------------------
* 06/28/04 DMA Replace bNot with pl_Noticng
* 06/11/04 DMA Fix undetected bug in checking TABills.NoNotice flag
* 06/09/04 DMA Extract PrtWaiverForm + PrtNotc
*              into standalone module TXWaiver
* 12/05/01 DMA Correct spelling of "fourteen"
* 11/12/01 EF  Original coding

* Called by Reprint
* Assumes that gfGetCas has already been called

* Calls: gfuse.prg, gfunuse.prg, ta_lib.prg
*        gfEntryN, PrtTXNot, txcrtltr.prg, TXWaiver
******************************************************************
*PARAMETER llReprint, msoc_sec, dthisdate
PARAMETER dthisdate
* dthisdate is the date for which notices should be reprinted
* pc_clcode holds the case for which notices should be reprinted

PRIVATE nrec, nbal, csuborauth, bcourtd, x, bcourt, l_prtplain, ;
   llCourt, llTABills, llTXNotice, llRecord

WAIT WINDOW "Reprinting notices. Please wait." NOWAIT NOCLEAR 
SET PROCEDURE TO ta_lib additive
llReprint = .T.

szEdtReq = ""
l_prtplain = .F.                                     && Keep track of plaintiff attorney's notice being printed
pl_RepNotc = .T.                                    && Turn on global notice-reprinting flag

csuborauth = "S"

nbal = 0
*IF USED( "taatty")
  * SELECT taatty
*ELSE
  * SELECT 0
  * USE( f_taatty) AGAIN
*ENDIF
*SET ORDER TO at_code

*llRecord = gfuse( "Record")
*SET ORDER TO cltag

*llTABills = gfuse( "TABills")
*SET ORDER TO Clac

*llTXNotice = gfuse( "TXNotice")

l_TxNot=GetTxNotic(dThisDate)
		IF NOT l_TxNot
			gfmessage("Cannot get TX Notice file")
			RETURN
		ENDIF
 SELECT TXNotice
SET ORDER TO NtcList

IF SEEK( pc_clcode + DTOC( dThisDate))
   SCAN FOR cl_code = pc_clcode AND Txn_Date = dThisDate
      nrec = RECNO()
      * 06/11/04 DMA llReprint is always true
      *      IF llReprint
      DO WHILE (txn_date <> dThisDate) ;
            AND (cl_code == pc_clcode) ;
            AND NOT EOF()
         SKIP
      ENDDO
      IF (cl_code == pc_clcode) AND (txn_date = dThisDate)
         nrec = RECNO()
      ELSE
         GO nRec
      ENDIF
      *      ENDIF
      csuborauth = TXnotice.Type
      mclass = "TXNotice"

      * 1) Print the notice set for the Requesting Attorney
	*IF NOT USED ("TABills")
		l_Tabill=gettabill(pc_clcode)
		IF NOT l_Tabill
			gfmessage( "Cannot get TAbills file" )
			RETURN

		ENDIF
	*ENDIF
	SELECT TABILLS

      SELECT TABills
      SEEK pc_clcode + pc_rqatcod
      * 06/11/04 DMA Move checks on NoNotice flag to individual attorneys
*      IF TABills.NoNotice
*         LOOP
*      ENDIF

      IF NOT pl_plisrq
         * If req. att'y is not a plaintiff att'y, flag for later print
         l_prtplain = .T.
      ENDIF

      IF SEEK( ALLTRIM( pc_clcode) + pc_rqatcod)
         IF NOT TABills.NoNotice
            pl_noticng = .T.
            && 2/4/02 Remove waiver for requesting atty, per Sheri's request
            && do TXWaiver with TAMaster.rq_at_code,dThisDate
            && do prtenqa with mv, mclass, "1" ,""
            DO PrtTXNot WITH dThisDate
            *         DO PrtNotSet WITH pc_rqatcod, dThisDate
         ENDIF
      ENDIF


      * 2) Print Plaintiff attorney notice set
      * (if plaintiff attorney was not the requesting attorney)
      IF l_prtplain
         SELECT TABills
         IF SEEK( ALLTRIM( pc_clcode) + pc_platcod)
            IF NOT TABills.NoNotice
               pl_noticng = .F.
               DO TXWaiver WITH pc_platcod, dThisDate
               *            DO PrtWaiverForm WITH pc_platcod, dThisDate, TAMaster.cl_code
               DO prtenqa WITH mv, mclass, "1", ""
               DO PrtTXNot WITH dThisDate
               *            DO PrtNotSet WITH pc_platcod, dThisDate
            ENDIF
         ENDIF
      ENDIF

      *** 3) Print notice sets for all other counsel

      SELECT TABills
      IF SEEK( ALLTRIM( pc_clcode))
         pl_noticng = .F.
         SCAN WHILE ALLTRIM( TABills.cl_code) == ALLTRIM( pc_clcode)
            IF TABills.NoNotice
               LOOP
            ENDIF
            IF NOT INLIST( TABills.At_code, ALLTRIM( pc_platcod), ALLTRIM( pc_rqatcod)) ;
                  AND cl_code = pc_clcode
               DO TXWaiver WITH TABills.at_code, dThisDate
               *               DO PrtWaiverForm with TABills.at_code, dThisDate, TAMaster.cl_code
               DO prtenqa with mv, mclass, "1", ""
               DO PrtTXNot WITH dThisDate
               *               DO PrtNotSet WITH TABills.at_code, dThisDate
            ENDIF
         ENDSCAN
      ENDIF
      SELECT TXNotice
   ENDSCAN
ENDIF
*SELECT TABills
*=gfunuse( "TABills", llTABills)
*=gfunuse( "TXNotice", lltxNotice)
WAIT CLEAR

*SET PROCEDURE TO
* 1/2/02 Generate a court notice set for the case
DO TXCrtLtr WITH dthisdate&&,pc_clcode
RETURN
