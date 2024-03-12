FUNCTION AsbOrder
* ***************************************************************************
* AsbOrder.prg - check order status for a single Asbestos attorney
*
* History :
* Date      Name  Comment
* ---------------------------------------------------------------------------
* 03/25/04  DMA   Add missing blank between court and docket number
* 02/16/04  DMA   Use public variables, NewShare database
* 04/22/03  DMA   Improved search algorithm for old-format Shares file
* 03/02/00  HSU   Initial release
* ***************************************************************************
* Called by: Orders
* Calls: None
* Assumes that TAMaster, TAAtty, Record, and NewShare are open.
* Assumes that gfGetCas has been called, and Record has been positioned to
* the current tag.
* Assumes that the user has pressed <F9> from the "3" screen after selecting
* an attorney whose firm code is in c_AttyFirm
* Returns .T. if the attorney is permitted to purchase the current tag in the
*    current case. This occurs under the following circumstances:
* 1) The tag has a Round number in Record.ASB_Round, and the case has an
*    ASB Number in global public variable pc_plbbasb
* 2) The Newshare file has an entry for that ASB/Round combination which
*    identifies an attorney that
*    (a) is a current participant [NewShare.date_out is empty] and
*    (b) has a firm code that matches c_AttyFirm.
*
PARAMETERS c_AttyFirm
PRIVATE c_DockInfo, c_RoundID
PRIVATE l_OK2Order
l_OK2Order = .F.

* 02/16/04 DMA Firm code now passed in as parameter

* 02/16/04 DMA Use global variables to acquire ASB ID Number and Docket

**03/16/2021 WY support increase docket width #225470 
*c_DockInfo = ALLT( LEFT( getPub("pc_Court1"), 4)) + " " + ALLT( LEFT( getPub("pc_docket"), 15))
c_DockInfo = ALLT( LEFT( getPub("pc_Court1"), 4)) + " " + ALLT( LEFT( getPub("pc_docket"), 75))

c_RoundID = Request.ASB_Round

SELECT DISTINCT BB_Combo FROM NewShare INTO CURSOR Active ;
   WHERE ( NewShare.ASB_ID = getPub("pc_plBBASB") OR NewShare.Docket = c_DockInfo) ;
   AND NewShare.Round_ID = c_RoundID ;
   AND EMPTY( NewShare.Date_Out)

IF _TALLY = 0
   	SELECT Active
   	USE
	RETURN .F.
ENDIF

* --- check B&B participants table ---
USE ( f_taatty) AGAIN IN 0 ORDER BB_Combo ALIAS FirMatch
SELECT Active
SCAN WHILE NOT l_OK2Order
   SELECT FirMatch
   IF SEEK( Active.BB_Combo)
      IF FirMatch.FirmCode == c_attyfirm
         l_OK2Order = .T.
      ENDIF
   ENDIF
   SELECT Active
ENDSCAN
USE

SELECT FirMatch
USE

RETURN l_OK2Order
