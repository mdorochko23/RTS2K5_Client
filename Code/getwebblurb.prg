PARAMETERS cWebOrderId 
LOCAL lc_Alias AS STRING, lc_Blurb as string, l_retval as Boolean
LOCAL  omed as Object
lc_Alias=ALIAS()
omed=CREATEOBJECT('medgeneric')
********get a blurb as entered by a cleint on the web
IF USED("ClientBlurb")
	SELECT ClientBlurb
	USE
ENDIF
l_retval=.f.
l_retval=omed.sqlexecute("Exec [dbo].[GetClientBlurb] '" + cWebOrderId  + "'", "ClientBlurb")

IF NOT l_retval
gfmessage("Failed to get the blurb's text")
		RETURN
ENDIF

SELECT ClientBlurb
IF NOT EOF()	
	lc_Blurb=ALLTRIM(ClientBlurb.exp)
ENDIF
	
IF NOT EMPTY(Lc_Alias)
	SELECT (lc_Alias)
ENDIF
RELEASE omed
RETURN lc_Blurb
