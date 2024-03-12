FUNCTION STATDESC
** Statdesc.prg - Returns the status of a record request
********************* W A R N I N G ****************************************
*                                                                          *
*     CHANGES TO THE STATUS CODES REQUIRE MATCHING                         *
*     CHANGES TO RECORDTRAK.COM WEBSITE CODE.                              *
*                                                                          *
****************************************************************************
* Called by PrintChk, Orders, SetRec, Record.SPR, DepoData.spr
* 08/07/03 kdl add parameter for incomplete records
* 08/01/03 kdl Change display of 1st look status descrip
* 08/30/02 DMA Handle combined Received/NRS situation
* 01/23/01 DMA Add status code "F" for first-look records
* 08/29/00 DMA Add status code "Q"
* Annotated 10/13/99 DMA

PARAMETERS statcode,nrscode,l_Recinc,chstatus
IF PCOUNT() = 1
   nrscode = ""
ENDIF
*--8/07/03 kdl start: add parameter check
IF PCOUNT() < 3
   l_Recinc = .F.
ENDIF
IF PCOUNT() < 4
	chstatus=''
ENDIF

PRIVATE c_code
c_code = LEFT( statcode, 1)
DO CASE

   CASE c_code = "A"
      RETURN "COUNSEL"

   CASE c_code = "C"
      RETURN "CANC"

   CASE c_code = "F"
      *--8/01/03 kdl start:  Change 4 screen display of 1st look status descrip
      *--8/7/03 kdl start: adjust to use passed parameter value for inclomplete
      IF l_Recinc
         RETURN "FRST-IC"
      ELSE
         RETURN "FRST-LK"
      ENDIF
      *--kdl out 8/01/03: return "WAIT.."
      *--8/01/03 kdl end:

   CASE c_code = "I"
      RETURN "INCOMP"

   CASE c_code = "N"
      RETURN "NRS" + IIF( NOT EMPTY(nrscode), "-" + nrscode, "")

   CASE c_code = "Q"
      RETURN "RESRCH"

   CASE c_code = "R"
* Handling for combined received/NRS tags
      RETURN "RCV" + IIF( NOT EMPTY(nrscode), "+NRS", "D")

   CASE c_code = "T"
      RETURN "NOT ISS"

   CASE c_code = "W"
      RETURN IIF(EMPTY(chstatus),"WAIT..","WAIT..S")
*--      RETURN "WAIT.."

   OTHERWISE
      RETURN statcode + " (?)"

ENDCASE
