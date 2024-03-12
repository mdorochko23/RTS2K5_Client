FUNCTION shipchk
PARAMETERS c_clcode AS STRING
LOCAL l_cancel  AS Boolean, oMedShip AS OBJECT
oMedShip = CREATEOBJ("generic.medgeneric")
l_cancel =.F.
c_Alias =ALIAS()
IF USED("Tabills")
SELECT Tabills
USE
ENDIF

DO gettabill WITH c_clcode

SELECT Tabills
	IF RECCOUNT()=0
		gfmessage("Attorney list is empty!"+CHR(13)+;
			"Can't continue with that order. Please add attorneys to that case.")
		RETURN .T.
	ENDIF
	WAIT WINDOW  "Checking records delivery settings for participating clients.. Please wait." NOWAIT 
	SCAN

		c_Atty=fixquote(Tabills.at_code)
** check if the shipment methods are set : at least at one level
		oMedShip.sqlexecute("SELECT [dbo].[NeedsShipSetting] ('" +ALLTRIM(fixquote(c_clcode)) + "','" +  c_Atty + "')", "ChkShip")
		IF ChkShip.EXP
			l_cancel =.T.
			gfmessage("Can not find a proper shipment setting for this attorney("  + ALLTRIM(c_Atty) +  "). Please update it before you continue with that order." )
		ENDIF
	ENDSCAN

	

IF NOT EMPTY(c_Alias)
	SELECT (c_Alias)
ENDIF
RELEASE oMedShip
RETURN l_cancel
