* ***************************************************************************
* gfOnHold.prg - return Bill To attorney account on hold status
*            assume tabills and taatty are open
*
* History :
* Date      Name  Comment
* ---------------------------------------------------------------------------
* 09/15/05  kdl   Converted to VFP/SQL
* 05/09/03  EF    Add 'Bankrupt' to an atty AR status
* 07/01/00  Hsu   Set default onhold status to TRUE
* 06/19/00  Hsu   Initial release
* ***************************************************************************
PARAMETER lcAtty, lcClient
PRIVATE llOnHold, laEnv, lcBillTo
DIMENSION laEnv(1,3)

llOnHold = .T.
lcBillTo = "-1"

omed=create("medtimesheet")
c_sql="SELECT b.*,d.billstatus FROM tblbill b JOIN tbldefendant d ON b.id_tbldefendant = d.id_tbldefendant " + ;
	"WHERE b.at_code='&lcAtty.' and b.cl_code='&lcClient.'"

omed.sqlexecute(c_sql,'tabills')
SCAN FOR at_code = lcAtty AND cl_code = lcClient
	IF EMPTY(invoice_no)
		lcBillTo = bill_to
		EXIT
	ENDIF
ENDSCAN

IF lcBillTo = "-1"
	=gfmessage("Ship-To attorney code:" + lcAtty + CHR(13) + ;
		"Client code:" + lcClient + " are invalid."+ CHR(13) + ;
		"Check 3,1 Attorney Order Screen.")
	
*--	MESSAGEBOX("Ship-To attorney code:" + lcAtty + CHR(13) + ;
		"Client code:" + lcClient + " are invalid."+ CHR(13) + ;
		"Check 3,1 Attorney Order Screen.",0+48)
ELSE
* --- if no bill to, use check ship to attorney ---
	IF EMPTY(lcBillTo)
		lcBillTo = lcAtty
	ENDIF
	IF NOT EMPTY(id_tbldefendant)
		IF INLIST(UPPER(billstatus), "H", "B")
			=gfmessage("Ship-To atty code:" + lcAtty + CHR(13) + ;
				"Bill-To atty code:" + lcBillTo + " account is on hold." + CHR(13) + ;
				"Check with client representative.")
*!*				MESSAGEBOX("Ship-To atty code:" + lcAtty + CHR(13) + ;
*!*					"Bill-To atty code:" + lcBillTo + " account is on hold." + CHR(13) + ;
*!*					"Check with client representative.",0+16)
			llOnHold = .T.
		ELSE
			llOnHold = .F.
		ENDIF
	ELSE
		=gfmessage("Ship-To atty code:" + lcAtty + CHR(13) + ;
			"Bill-To atty code:" + lcBillTo + " is invalid." + CHR(13) + ;
			"Check Attorney Rolodex.")
*--		MESSAGEBOX("Ship-To atty code:" + lcAtty + CHR(13) + ;
*--			"Bill-To atty code:" + lcBillTo + " is invalid." + CHR(13) + ;
*--			"Check Attorney Rolodex.",0+48)
	ENDIF
ENDIF
RETURN llOnHold

