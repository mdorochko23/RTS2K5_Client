
*FUNCTION srchimgbase
PARAMETERS c_rt 
LOCAL lc_path AS STRING, l_lfound AS Boolean,icnt AS INTEGER
l_lfound=.F.
ofiles = CREATEOBJECT("Scripting.FileSystemObject")
lc_path = ADDBS(MLPriPro("R", "RTS.INI", "Data","IMGBASEALL", "\"))
IF EMPTY(lc_path)
	lc_path="\\SANSTOR\IMAGE\img_base\"
ENDIF


ofolders = ofiles.GetFolder(lc_path )
fc = ofolders.SubFolders
FOR EACH f1 IN fc
	STORE "" TO lc_folder,lc_srch
	lc_srch =lc_path 
	lc_folder = ALLTRIM(f1.NAME)

	IF !EMPTY(lc_folder) and UPPER(lc_folder)<>"BADCOURTORDER" 
		lc_srch  =lc_path + ADDBS(lc_folder)
	ENDIF
	

	FOR icnt =1 TO 10
		IF FILE(lc_srch + ALLTRIM(c_rt) +"_" + ALLTRIM(STR(icnt)) + ".tif")
			l_lfound=.T.
			EXIT

		ENDIF

	NEXT

NEXT
RELEASE ofolders

RETURN l_lfound

*!*	LOCAL lc_path as String, l_lfound as Boolean,icnt as Integer
*!*	l_lfound=.f.
*!*	lc_path = ADDBS(MLPriPro("R", "RTS.INI", "Data","IMGBASE", "\"))

*!*	FOR icnt =1 TO 10
*!*	IF FILE(lc_path+ ALLTRIM(c_rt) +"_" + ALLTRIM(STR(icnt)) + ".tif")
*!*		l_lfound=.t.
*!*		exit

*!*	endif

*!*	next


*!*	RETURN l_lfound