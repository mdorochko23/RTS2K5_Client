PARAMETERS c_filepath AS STRING
LOCAL c_alias AS STRING
c_alias=ALIAS()
IF NOT EMPTY(ALLTRIM(c_filepath ))
&&04/13/2016- do not check for scan_name#38672
	*IF  FILE('c:\vfp\scan_name.exe')
		goApp.OpenForm("utility.frmcallrtsscan", "S", NULL, NVL(c_filepath ,""))
	*ELSE
	*	gfmessage("Do not have the RTS Scan program installed. Contact IT.")
	*ENDIF
ELSE
	gfmessage("No image data has been found for that case. You can search for a file.  ")
*	IF  FILE('c:\vfp\scan_name.exe')
	**allow to pick any
		goApp.OpenForm("utility.frmcallrtsscan", "S", NULL)
*	ENDIF

ENDIF

IF NOT EMPTY(c_alias)
	SELECT (c_alias)
ENDIF
RETURN
