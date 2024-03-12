**8/10/09 - make one general function that can be used through teh various CA print modules.
FUNCTION GetCASigner
PARAMETERS dControl, c_offcode
PRIVATE lGotSigner as Boolean, c_MailNam as String, cAlias as String
PRIVATE omedSign as Object, c_date as String
cAlias =ALIAS()
omedSign= CREATEOBJECT("medtimesheet")
SELECT 0
lGotSigner=.f.
STORE "" TO c_MailNam,c_date

IF TYPE ('dControl')='C'
c_date=dControl
ELSE
c_date=DTOC(dControl)
ENDIF

lGotSigner=omedSign.sqlexecute("SELECT dbo.gfSigner('" + c_date + "','" +  ALLTRIM(c_offcode) + "')", "MailPers")
		IF NOT lGotSigner			
			gfmessage(" Cannot get a signer of the documents. Contact IT.")
		else
		c_MailNam=IIF(ISNULL(MailPers.EXP),"",ALLTRIM(MailPers.EXP))
		SELECT MailPers
		use
		ENDIF
IF NOT EMPTY(cAlias)
SELECT (cAlias)
endif
RELEASE omedSign
RETURN c_MailNam
