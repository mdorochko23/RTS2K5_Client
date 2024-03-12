LPARAMETERS tsFileName AS String, ;
						nAttributes AS Integer


*function SetFileAttr(tcFileName) 

LOCAL ARRAY laFiles[1,5]
LOCAL lsFileName AS String, ;
			lbFileExists AS Boolean, ;
			lbRetval as Boolean, ;
			liFilesFound AS integer, ;
			lbIsDirectory AS Boolean



lbRetval = .T.
lsFileName = fullpath(tsFileName)

liFilesFound = adir(laFiles,lsFileName, 'ASHR')

lbIsDirectory = (liFilesFound = 1) ;
								AND (('D' $ laFiles[1,5]) or ('V' $ (laFiles[1,5])))


*-- File must exist and not be a wildcard reference 
lbFileExists = File(lsFileName) ;
								AND ( liFilesFound = 1) ;
								AND NOT(lbIsDirectory)
								

IF lbFileExists

	*-- the zero clears all attributes from the file 
	#IFNDEF FILE_ATTRIBUTE_READONLY
		#define FILE_ATTRIBUTE_NONE             		0 
		#define FILE_ATTRIBUTE_READONLY             1 
		#define FILE_ATTRIBUTE_HIDDEN               2 
		#define FILE_ATTRIBUTE_SYSTEM               4 
		#define FILE_ATTRIBUTE_ARCHIVE              32 
		#define FILE_ATTRIBUTE_ENCRYPTED            64 
		#define FILE_ATTRIBUTE_NORMAL               128 
		#define FILE_ATTRIBUTE_TEMPORARY            256 
		#define FILE_ATTRIBUTE_COMPRESSED           1024 
	#ENDIF

	declare integer SetFileAttributes in Win32API ; 
	 string cFileNameToAlter, ; 
	 integer nAttributeMask 

	lbRetval = SetFileAttributes(lsFileName, nAttributes) = 1

ENDIF

return lbRetval
