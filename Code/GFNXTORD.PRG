*****************************************************************************
* gfNxtOrd.Prg: Get Next Manual Order Record Id Number
*
* Date      Name  Comment
* ---------------------------------------------------------------------------

* 05/31/00  Hsu   Initial Release
* 08/16/05 kdl use default office pathing for free tables
******************************************************************************
LOCAL lnNxtOrder, lcAlias, lnReprocess,lc_office

lcAlias = ALIAS()
lnReprocess = SET("reprocess")
SELECT 0
*--8/16/05 kdl start: use default office pathing for free tables
DO gfgetcas
DO CASE
	CASE pc_offcode="C"
		lc_office="CAL"
	CASE pc_offcode="U"
		lc_office="PAS"
	OTHERWISE
		lc_office="KOP"
ENDCASE
lc_path=ADDBS(MLPriPro("R", "RTS.INI", "Data","KOP", "\"))
USE lc_path+"NxtOrder"
*--Use (f_NxtOrder)
lnNxtOrder = 0
SET REPROCESS TO AUTOMATIC
IF FLOCK()
	lnNxtOrder = nxtOrdNum
	REPLACE nxtOrdNum WITH lnNxtOrder + 1
	REPLACE lastUpdate WITH DATE()
	UNLOCK
ENDIF
USE IN NxtOrder
SET REPROCESS TO (lnReprocess)
IF ! EMPTY(lcAlias)
	SELECT (lcAlias)
ENDIF
RETURN lnNxtOrder

