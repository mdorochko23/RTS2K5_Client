**8/10/09 - make one general function that can be used through teh various CA print modules.
FUNCTION GetCADeliv
PARAMETERS  c_offcode, dControl, c_clcode
PRIVATE lGotDocSr as Boolean, c_ServNam as String, cAlias as String
PRIVATE omedSign as Object
c_ServNam=""
lGotDocSr=.f.
cAlias =ALIAS()
omedSign= CREATEOBJECT("medtimesheet")
SELECT 0

		lGotDocSr=omedSign.sqlexecute("SELECT dbo.gfDocServer('" + ALLTRIM(c_offcode) + "',' " +  DTOC(dControl)+ "', '" + fixquote(c_clcode) + "')", "ServName")
		IF NOT lGotDocSr			
			gfmessage(" Cannot get a signer of the documents. Contact IT.")
		ELSE
		
		c_ServNam=IIF(ISNULL(ServName.EXP),"",ALLTRIM(ServName.EXP))
		SELECT ServName
		use
		ENDIF
		
IF NOT EMPTY(cAlias)
SELECT (cAlias)
endif
RELEASE omedSign
RETURN c_ServNam
