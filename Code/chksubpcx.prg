PARAMETERS cPcxSubp 
**checks if a scanned subp file exists at the t:\pcx: Part of the HOLDPRINT project
LOCAL  oFSO as Object, l_retval as Boolean
l_retval =.F.
oFSO = CREATEOBJ('Scripting.FileSystemObject')



	IF ofso.FileExists(cPcxSubp)
		l_retval =.t.
	ENDIF
	
RELEASE oFSO
RETURN l_retval