PARAMETERS id_OutofBuss 

LOCAL c_file as String, oMed_b AS OBJECT, c_Alias as String
oMed_b=CREATEOBJECT("generic.medgeneric")
c_Alias=SELECT()
c_file=""
IF NVL(id_OutofBuss ,0) <>0

	oMed_b.closealias ('GetDoc')
	c_sql="EXEC dbo.GetOutOfBussinessDoc " + STR(id_OutofBuss)
	oMed_b.sqlexecute(c_sql,'GetDoc')


	IF USED("GetDoc") AND NOT EOF()	
		c_file = ADDBS(ALLTRIM(GetDoc.file_path))+ALLTRIM(GetDoc.file_name)
		IF !FILE(c_file)  

			c_file="" && does not exists

		ENDIF
	ENDIF
	
*!*	ELSE
*!*		gfmessage( "No documents have been stored yet. ")
** no file stored at the deponent details yet
ENDIF

IF NOT EMPTY(c_Alias)
SELECT (c_Alias)
endif

RELEASE oMed_b

RETURN c_file