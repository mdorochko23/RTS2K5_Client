
PARAMETERS cDrivePath
IF PCOUNT() < 1
	lcRtnVal = "Failed: Drive does not exist"
	RETURN lcRtnVal
ENDIF
* support.microsoft.com/kb/135818 -- How to List Available Drives A-Z from Visual FoxPro
LOCAL lcDrive, lcPath, lcUNC, lnUNCMaxSize, lnResult, lcRtnVal
IF VARTYPE(cDrivePath)="C" AND ISALPHA(cDrivePath) AND IIF(LEN(cDrivePath)<=2 OR SUBSTR(cDrivePath,2,2)=":\",.T.,.F.)
	lnResult = -1
	lcDrive = UPPER(LEFT(cDrivePath,1))+":"
	lcDrvType = DRIVETYPE(lcDrive)
	lcPath = SUBSTR(cDrivePath,3)
	IF lcDrvType = 4  && network or removable drive
		lnUNCMaxSize = 400
		lcUNC = SPACE(lnUNCMaxSize)
* lnResult values:
* #DEFINE NO_ERROR                     0
* #DEFINE ERROR_BAD_DEVICE          1200
* #DEFINE ERROR_CONNECTION_UNAVAIL  1201
* #DEFINE ERROR_EXTENDED_ERROR      1208
* #DEFINE ERROR_MORE_DATA            234
* #DEFINE ERROR_NOT_SUPPORTED         50
* #DEFINE ERROR_NO_NET_OR_BAD_PATH  1203
* #DEFINE ERROR_NO_NETWORK          1222
* #DEFINE ERROR_NOT_CONNECTED       2250 <-- typical error for non-UNC drive mappings
* Declare, call and clear the DLL
		DECLARE INTEGER WNetGetConnection IN WIN32API AS ConvDrvToUNC STRING @lcDrive, STRING @lcUNC, INTEGER @lnUNCMaxSize
		lnResult = ConvDrvToUNC(@lcDrive, @lcUNC, @lnUNCMaxSize)
		CLEAR DLLS "ConvDrvToUNC"
	ENDIF
	DO CASE
	CASE EMPTY(lnResult)
		lcRtnVal = ALLTRIM(LEFT(lcUNC,AT(CHR(0), lcUNC)-1)) + lcPath  && ALLTRIM() may not be needed
	CASE lcDrvType <> 4 OR lnResult = 2250
* Invalid network resource
		DO CASE
		CASE lcDrvType=0
			lcRtnVal = "Failed: Drive does not exist"
		CASE lcDrvType=1
			lcRtnVal = "Failed: Drive is not mapped or has no root directory"
		CASE lcDrvType=2
			lcRtnVal = "Failed: Drive is a floppy or flash disk"
		CASE lcDrvType=3
			lcRtnVal = "Failed: Drive is a hard disk"
		CASE lcDrvType=4
			lcRtnVal = "Failed: Drive is a network or removable drive"
		CASE lcDrvType=5
			lcRtnVal = "Failed: Drive is a CD-ROM drive"
		CASE lcDrvType=6
			lcRtnVal = "Failed: Drive is a RAM disk"
		OTHERWISE
			lcRtnVal = "is an unexpected drive type"
		ENDCASE
	OTHERWISE
		lcRtnVal = "Invalid system response. Win32Api Error #"+LTRIM(STR(lnResult))
	ENDCASE
ELSE
	lcRtnVal = IIF(LEN(cDrivePath)<3,"Invalid drive letter.","Invalid path - Path must contain initial backslash.")
ENDIF
RETURN lcRtnVal

