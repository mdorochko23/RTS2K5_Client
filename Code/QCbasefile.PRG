**************************************************************
*FUNCTION QCBaseFile
PARAMETERS c_rt , c_folder
LOCAL lc_path AS STRING, l_lfound AS Boolean,icnt AS INTEGER, lcSQLLine as String, obmed as Object
obmed=CREATEOBJECT('medgeneric')
l_lfound=.F.
ofiles = CREATEOBJECT("Scripting.FileSystemObject")
lc_path = ADDBS(MLPriPro("R", "RTS.INI", "Data","IMGBASEALL", "\"))
IF EMPTY(lc_path)
	lc_path="\\SANSTOR\IMAGE\img_base\"
ENDIF
STORE "" TO lc_srch,  c_base

	IF !EMPTY(c_folder) 
		lc_srch  =lc_path + ADDBS(c_folder)
	ELSE		 
		 RETURN c_base
	ENDIF
	

	FOR icnt =10 TO 1 STEP -1
		
		IF FILE(lc_srch + ALLTRIM(c_rt) +"_" + ALLTRIM(STR(icnt)) + ".tif")
			l_lfound=.T.
			c_base=lc_srch + ALLTRIM(c_rt) +"_" + ALLTRIM(STR(icnt)) + ".tif"			
			

		ENDIF

	NEXT

RELEASE obmed
RETURN c_base