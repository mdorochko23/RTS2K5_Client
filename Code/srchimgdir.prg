**************************************************************
*FUNCTION srchimgdir
PARAMETERS c_rt , l_FolderOnly

LOCAL lc_path AS STRING, l_lfound AS Boolean,icnt AS INTEGER
l_lfound=.F.
ofiles = CREATEOBJECT("Scripting.FileSystemObject")
lc_path = ADDBS(MLPriPro("R", "RTS.INI", "Data","IMGBASEALL", "\"))

c_base=""

*** AS 06/27/2012 look at the root first if not found then cheCk the folders
	FOR icnt =10 TO 1 STEP -1
		
		IF FILE(lc_path + ALLTRIM(c_rt) +"_" + ALLTRIM(STR(icnt)) + ".tif")
							
			c_base=lc_path + ALLTRIM(c_rt) +"_" + ALLTRIM(STR(icnt)) + ".tif"
			
			EXIT

		ENDIF
	NEXT


****

ofolders = ofiles.GetFolder(lc_path )
fc = ofolders.SubFolders
FOR EACH f1 IN fc
	STORE "" TO lc_folder,lc_srch
	lc_srch =lc_path 
	lc_folder = ALLTRIM(f1.NAME)

	IF !EMPTY(lc_folder) and UPPER(lc_folder)<>"BADCOURTORDER" 
		lc_srch  =lc_path + ADDBS(lc_folder)
	
	
	FOR icnt =10 TO 1 STEP -1
		
		IF FILE(lc_srch + ALLTRIM(c_rt) +"_" + ALLTRIM(STR(icnt)) + ".tif")
			l_lfound=.T.
			c_base=lc_srch + ALLTRIM(c_rt) +"_" + ALLTRIM(STR(icnt)) + ".tif"
			IF l_FolderOnly
				c_base=UPPER(ALLTRIM(lc_folder))
			endif

			EXIT

		ENDIF

	NEXT
 endif
NEXT
RELEASE ofolders
IF EMPTY(c_base) AND l_FolderOnly
c_base=lc_path
ENDIF



RETURN c_base


