FUNCTION STATQUAL
*
*  Determine the status qualifier string for a request
*  Extracted from SetRec for multiple usage
********************* W A R N I N G ****************************************
*                                                                          *
*     CHANGES TO THE STATUS CODES REQUIRE MATCHING                         *
*     CHANGES TO RECORDTRAK.COM WEBSITE CODE.                              *
*                                                                          *
****************************************************************************
*  03/04/04 DMA Added "Research" qualifier
*  02/20/04 EF  Added a 'Waiver Received' qualifier
*  08/25/03 kdl Added first-look status to Hold-C status exclusion list
*  04/11/03 kdl Added 1st look rec status qualifiers (merged on 8/1/03)
** 04/10/03 IZ  do not display "HOLD_S" if tag is a Reissue
*  03/26/03 kdl Add 1st look status qualifiers (merged on 8/1/03)
*  03/20/02 EF  Add Pickup qualifier
*  06/17/02 DMA Check on Record.Send_Date for "Hold_S" status
*  07/18/01 DMA Add "Hold_A" qualifier
*  02/27/01 DMA Original code extracted
*
*  Assumes that the Record and TAMaster files are open
*  and positioned on the case and request being processed
*
*  Does NOT use public variables for fields in Record file,
*  because a deponent has not been selected yet when called
*  by SetRec routine.
*
*  Called by SetRec, CovLet
*  Calls gFLkStat
*
*--7/03/03 kdl start: add private variable
local c_qualifr, n_1lkstat
*--kdl out: PRIVATE c_qualifr
*--7/03/03 kdl end:

c_qualifr = SPAC(6)

DO CASE
      &&EF 03/20/03
   CASE CaseDeponent.Status = "W" AND CaseDeponent.Pickup
      c_qualifr = "PICKUP"

   CASE CaseDeponent.Status = "W" ;
         AND NOT EMPTY( CaseDeponent.Req_Date) ;
         AND NOT EMPTY( master.Court)
      IF CaseDeponent.AM_Resp
         c_qualifr = "HOLD_A"
      ENDIF
      ** 04/10/03 IZ do not display "HOLD_S" if this is a Reissue

      IF NOT CaseDeponent.Reissue AND CaseDeponent.Type <> "A"
         IF MAX( CaseDeponent.req_date + holddays, CaseDeponent.Send_Date) > d_today
            c_qualifr = "HOLD_S"
         ENDIF
         IF CaseDeponent.waivrcvd
            c_qualifr = "WAIVRCV"
         ENDIF
      ENDIF

   CASE CaseDeponent.Status = "W" ;
         AND CaseDeponent.AM_Resp
      c_qualifr = "HOLD_A"

   CASE CaseDeponent.Status = "F"
      *--3/26/03 kdl start: Add 1st look status qualifiers
      n_1lklvl = gflkstat("LEVEL", CaseDeponent.first_look, CaseDeponent.Status, CaseDeponent.Tag)
      DO CASE
         CASE n_1lklvl = 1
            c_qualifr = "PRE_REV"
         CASE n_1lklvl = 2
            c_qualifr = "PRE_REV"
         CASE n_1lklvl = 3
            c_qualifr = "ATTY_R"
         OTHERWISE
            c_qualifr = ""
      ENDCASE
      *--kdl out 3/26/03: c_qualifr = "F/L   "
      *--3/26/03 kdl end:

      *--04/11/03 kdl start: add 1st look received qualifier
   CASE CaseDeponent.Status = "R" AND CaseDeponent.first_look
      n_1lklvl = gflkstat("LEVEL", CaseDeponent.first_look, CaseDeponent.Status, CaseDeponent.Tag)
      DO CASE
         CASE INLIST(n_1lklvl, 4, 5)
            c_qualifr = "FLK_REC"
         CASE n_1lklvl = 6
            c_qualifr = "FLK_FUL"
      ENDCASE
      *--04/11/03 kdl end:

   CASE INLIST( CaseDeponent.Status, "R", "N") ;
         AND CaseDeponent.Inc
      c_qualifr = "INC   "

ENDCASE

* 03/04/03 DMA Add "Research" qualifier
IF CaseDeponent.Research
   c_qualifr = "RESRCH"
ENDIF

*--8/25/03 kdl start: added first-look status "F" to exclusion list
IF CaseDeponent.Hold ;
      AND NOT INLIST( CaseDeponent.Status, "N", "R", "C", "F")
   c_qualifr = "HOLD_C"
ENDIF
**
RETURN( c_qualifr)
