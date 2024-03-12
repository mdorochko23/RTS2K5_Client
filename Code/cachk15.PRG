**PROCEDURE  CaChk15
*******************************************************
**05/09/2017 #61228 : ask for a check for KOP issues to CA locations
*******************************************************
IF EMPTY(ALLTRIM(NVL(pc_mailst,'')) ) AND  pl_KOPVer
	pc_mailst= TgState(PC_MAILID)
ENDIF

LOCAL L_WITFEE AS Boolean
L_WITFEE=.F.

IF pl_KOPVer AND  ALLTRIM(NVL(pc_mailst,''))='CA'
	L_WITFEE=GFMESSAGE("Do you need to send a $15.00 check with this request?",.T.)
	IF L_WITFEE
		PL_POSTFEE=.T.
		pc_SpecHand="SPC"
	ELSE
		PL_POSTFEE=.F.
		
	ENDIF
ENDIF

RETURN
