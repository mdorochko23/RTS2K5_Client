FUNCTION gfRStat
*****************************************************************************
* gfRstat.PRG - return record status
*
* History :
* Date      Name  Comment
* ---------------------------------------------------------------------------
** EF 4/26/06 -Added to the project
******************************************************************************
* 06/09/05  DMA   add waiver-received field to values returned in parameters
* 05/03/04  IZ    added a reissue field
* 04/15/04  IZ    added new variables from record
* 12/18/97  HN    Initial release
*****************************************************************************
PARAMETER lcClient, lnTag, lc_type, ld_reqdate, ld_senddate, ll_reissue, ;
   ll_wrcvd
PRIVATE lcstat, lcAlias, llRecord, llkop
llkop = IIF( PARAMETERS() >2 , .T., .F.)

lcAlias = ALIAS()
*llRecord = gfUse("record")

*SET ORDER TO ClTag
IF NOT l_rec
gfmessage("Cannot get the Record. Contact IT dept.")
 lcstat = ""
 RETURN
ENDIF
SELECT Record
IF NOT EOF()
*IF SEEK( lcClient + "*" + STR( lnTag))
*\\ accomodate scaning hold
   lcstat = IIF(EMPTY(NVL(hstatus,'')),ALLTRIM(status),ALLTRIM(hstatus))
*   lcstat = ALLTRIM( status)
** 04/15/04 IZ added new variables
   IF llkop
      ld_reqdate = req_date
      ld_senddate = send_date
      lc_type = type
      ll_reissue = reissue
      * 06/09/05 DMA Add Waiver-Received field
      ll_wrcvd = waivrcvd
   ENDIF
** end IZ
ELSE
   lcstat = ""
ENDIF
*= gfUnUse( "record", llRecord)
*select Record
*USE
IF NOT EMPTY( lcAlias)
   SELECT (lcAlias)
ENDIF
RETURN lcstat
