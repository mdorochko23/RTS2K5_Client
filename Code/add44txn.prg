**PROCEDURE Add44txn :
********************************************************
PARAMETERS  lc_location , lc_cl_code,ln_Tag, lc_id_tblrequests


LOCAL lcTemp AS STRING, fso2 AS OBJECT
lcTemp=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","rtExe", "\"))) + "ADD44.TXT"
fso2= CREATEOBJECT("Scripting.FileSystemObject")
IF (FILE(lcTemp))

	WAIT WINDOW "Adding txn 44.." NOWAIT
	lcdep="Z"
		DO TXN44_2RQ WITH  ALLT(lc_location), ;
			lc_cl_code, 44, ln_Tag, pc_mailid, PC_ISSTYPE,  ;
			"(F)" + ALLTRIM(pc_UserID),	lc_id_tblrequests , lcdep, .F.

	IF (FILE(	lcTemp))
		fso2.DeleteFile(lcTemp)
	ENDIF

ENDIF
RELEASE fso2

RETURN

