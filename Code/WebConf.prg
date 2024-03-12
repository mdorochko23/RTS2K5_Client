PARAMETERS c_webord, n_mode
*n_mode =1 && old location
*n_mode =2 && new location

LOCAL lc_path AS STRING,  lc_cnf AS STRING, c_origord AS STRING
LOCAL fso AS OBJECT, o_MedTemp AS OBJECT
fso = CREATEOBJECT("Scripting.FileSystemObject")

IF n_mode=1
		c_origord= c_webord
		lc_path = ADDBS(MLPriPro("R", "RTS.INI", "Data","WebConfirmation", "\"))
	ELSE
		lc_path = ADDBS(MLPriPro("R", "RTS.INI", "Data","WebConfirmSwitch", "\"))
		c_origord=""
ENDIF



IF n_mode=2
o_MedTemp = CREATEOBJECT("generic.medgeneric")

o_MedTemp.closealias("OrigOrd")
o_MedTemp.sqlexecute("SELECT   dbo.QC_getOrigWebOrder('" + ALLTRIM(c_webord) + "')", "OrigOrd")
IF USED("OrigOrd")

	c_origord=STR(OrigOrd.EXP)

	IF EMPTY(c_origord)
		RELEASE fso
		RELEASE o_medTemp
		RETURN ""
	ENDIF

ENDIF	


ENDIF  && a result from a function above

	IF NOT DIRECTORY(lc_path)
		DO mapdrive WITH lc_path, n_mode
	ENDIF






	lc_cnf=""
	IF  fso.FileExists(ALLTRIM(lc_path+ ALLTRIM(c_origord) + ".pdf"))

		lc_cnf=lc_path+ ALLTRIM(c_origord) + ".pdf"

	ENDIF


RELEASE fso
RELEASE o_medTemp
RETURN lc_cnf
