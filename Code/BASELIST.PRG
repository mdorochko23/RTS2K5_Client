**************************************************************
*FUNCTION BaseList
PARAMETERS c_rt 
LOCAL lc_path AS STRING, l_lfound AS Boolean,icnt AS INTEGER, lcSQLLine as String, obmed as Object, C_ALIAS AS String
C_ALIAS=ALIAS()
obmed=CREATEOBJECT('medgeneric')
l_lfound=.F.
ofiles = CREATEOBJECT("Scripting.FileSystemObject")
lc_path = ADDBS(MLPriPro("R", "RTS.INI", "Data","IMGBASEALL", "\"))
STORE "" TO lcSQLLine, c_base
obmed.closealias("BaseFolders")
lcSQLLine=" select 0 as pick, BaseImgDesc, BaseImgFolder  from tblBaseImgFolders with (nolock) where active =1"
obmed.sqlexecute(lcSQLLine,"BaseFolders")
=CURSORSETPROP("KeyFieldList", "BaseImgFolder", "BaseFolders")
INDEX ON ALLTRIM(UPPER(BaseImgFolder)) TAG BaseImg ADDITIVE
ofolders = ofiles.GetFolder(lc_path )
fc = ofolders.SubFolders
FOR EACH f1 IN fc
	STORE "" TO lc_folder,lc_srch
	lc_srch =lc_path 
	lc_folder = ALLTRIM(f1.NAME)

	IF !EMPTY(lc_folder) and UPPER(lc_folder)<>"BADCOURTORDER" 
		lc_srch  =lc_path + ADDBS(lc_folder)
		
	ENDIF
	

	FOR icnt =10 TO 1 STEP -1
		
		IF FILE(lc_srch + ALLTRIM(c_rt) +"_" + ALLTRIM(STR(icnt)) + ".tif")
			l_lfound=.T.
			
			SELECT BaseFolders 
			IF SEEK(UPPER(ALLTRIM(lc_folder)))
			 replace pick WITH 1
			endif
			
			

		ENDIF

	NEXT

NEXT
RELEASE ofolders
RELEASE obmed
IF NOT EMPTY(C_ALIAS)
SELECT (C_ALIAS)
endif
RETURN l_lfound