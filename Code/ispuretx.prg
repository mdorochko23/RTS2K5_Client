*Function IsPureTx

PARAMETERS tcCourt

tcCourt = UPPER(ALLTRIM(tcCourt))

*--IF LEFT(tcCourt,3) = "TX-" AND  LEFT(tcCourt,7) <> "TX-USDC" and LEFT(tcCourt,7) <> "TX-WCAB" && 01/17/2022 MD #261563 include USDC-TX
IF (LEFT(tcCourt,3) = "TX-" OR LEFT(tcCourt,7) = "USDC-TX") and LEFT(tcCourt,7) <> "TX-WCAB"
	RETURN .T.
ELSE
	RETURN .F.
ENDIF 