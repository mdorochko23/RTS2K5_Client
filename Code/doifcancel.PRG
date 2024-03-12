PARAMETERS cAlias,cTable,cKey,cAction
LOCAL c_ChkKey AS STRING, c_Alias AS STRING
c_Alias=ALIAS()

SELECT (cAlias)
c_ChkKey=IIF(ISNULL(cKey),"",cKey)
INSERT INTO (cAlias) VALUES ( cTable ,c_ChkKey, cAction)
IF !EMPTY(c_Alias)
	SELECT (c_Alias)
ENDIF

RETURN

