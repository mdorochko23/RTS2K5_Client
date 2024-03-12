#INCLUDE FoxPro.h
#INCLUDE objectids.h


*-- Application Build Mode Defines
#Define KEYTYPE_GUID								"string"
#Define KEYTYPE_INTEGER							"Integer"

*#Define KEYTYPE											KEYTYPE_INTEGER
#Define KEYTYPE											KEYTYPE_GUID

#IF KEYTYPE = KEYTYPE_GUID
	KEYTYPE_FIELD_DEFINITION					 C(36) 
#ELSE
	KEYTYPE_FIELD_DEFINITION					 I 
#ENDIF


#Define DATAACCESS_VFPFILESERVER 		0	&& Set APP_DATAACCESS_MODEL to this for accessing VFP Data From the Mediator
#Define DATAACCESS_COMSERVER 				1 && Set APP_DATAACCESS_MODEL to this for accessing SQL or other data via a COM+ VFP DataAdapter

#Define CONNECTION_MODE_SINGLE			1	&& Connections are obtained for the individual data adaptor.
#Define CONNECTION_MODE_SHARED			2	&& Connections are shared across data adaptors.

*#Define	APP_DATAACCESS_MODEL				DATAACCESS_VFPFILESERVER 
#Define	APP_DATAACCESS_MODEL				DATAACCESS_COMSERVER 

*-- Developer Defines
#Define CRLF		CHR(13) + CHR(10)
#Define CR			CHR(13)
#Define MB_NEWLINE	CHR(13)

*-- Form Launch Flags
#DEFINE FORM_LAUNCH_MODAL				"M"
#DEFINE FORM_LAUNCH_INVISIBLE		"I"
#DEFINE FORM_LAUNCH_OBJECT			"O"
#DEFINE FORM_LAUNCH_NORMAL			""

*-- Avi Files
#DEFINE AVI_WAITING		".\Media\Waiting.Avi"	

 
*-- PEMSTATUS 
#DEFINE PEMSTATUS_ATTRIBUTE_CHANGED 			0
#DEFINE PEMSTATUS_ATTRIBUTE_READONLY 			1
#DEFINE PEMSTATUS_ATTRIBUTE_PROTECTED 		2
#DEFINE PEMSTATUS_ATTRIBUTE_TYPE 					3
#DEFINE PEMSTATUS_ATTRIBUTE_USERDEFINED 	4
#DEFINE PEMSTATUS_ATTRIBUTE_DEFINED 			5
#DEFINE PEMSTATUS_ATTRIBUTE_INHERITED			6


#DEFINE PEMSTATUS_TYPE_PROPERTY						"Property"
#DEFINE PEMSTATUS_TYPE_EVENT							"Event"
#DEFINE PEMSTATUS_TYPE_METHOD							"Method"
#DEFINE PEMSTATUS_TYPE_OBJECT							"Object"

*-- FileAttribut Constants for SetFileAttributes
	#define FILE_ATTRIBUTE_NONE             		0 
	#define FILE_ATTRIBUTE_READONLY             1 
	#define FILE_ATTRIBUTE_HIDDEN               2 
	#define FILE_ATTRIBUTE_SYSTEM               4 
	#define FILE_ATTRIBUTE_ARCHIVE              32 
	#define FILE_ATTRIBUTE_ENCRYPTED            64 
	#define FILE_ATTRIBUTE_NORMAL               128 
	#define FILE_ATTRIBUTE_TEMPORARY            256 
	#define FILE_ATTRIBUTE_COMPRESSED           1024 


*-- These values returned by INKEY(), LASTKEY(), and
*   assigned to nKeyCode in the grid KeyPress Event.
#Define K_ENTER				13
#Define K_SH_ENTER		13
#Define K_CTRL_ENTER 	10
#Define K_ESCAPE			27
#Define K_TAB					9
#Define K_SH_TAB			15
#Define K_UP					5
#Define K_SH_UP				56
#Define K_CTRL_UP			141
#Define K_ALT_UP			152
#Define K_DOWN				24
#Define K_SH_DOWN			50
#Define K_CTRL_DOWN		145
#Define K_ALT_DOWN		160
#Define K_LEFT				19
#Define K_SH_LEFT			52
#Define K_CTRL_LEFT		26
#Define K_ALT_LEFT		155
#Define K_RT					4
#Define K_SH_RT				54
#Define K_CTRL_RT			2
#Define K_ALT_RT			157
#Define K_PGUP				18
#Define K_SH_PGUP			57
#Define K_CTRL_PGUP		31
#Define K_ALT_PGUP		153
#Define K_PGDN				3
#Define K_SH_PGDN			51
#Define K_CTRL_PGDN		30
#Define K_ALT_PGDN		161
#Define K_INS					22
#Define K_SH_INS			22
#Define K_CTRL_INS		146
#Define K_ALT_INS			162
#Define K_DEL					7
#Define K_SH_DEL			7
#Define K_CTRL_DEL		147
#Define K_ALT_DEL			163
#Define K_HOME				1
#Define K_SH_HOME			55
#Define K_CTRL_HOME		29
#Define K_ALT_HOME		151
#Define K_END					6
#Define K_SH_END			49
#Define K_CTRL_END		23
#Define K_ALT_END			159
#Define K_CTRL_F12		138

*--Application Generic Messages
#Define APP_ASK_EXIT						"Are you sure you want to Exit?"
#Define APP_LOADING							"Loading, Please wait..."
#Define APP_ERROR_CRITICAL			"Critical Application Error!"
#Define APP_NOTAVAILFORMS				"Function not available until ALL Active Forms are Closed!"
#Define APP_BADPARAMS						"Invalid Parameter Passed!"


*--Application Specific 
#Define APP_NAME								"RecordTrak (RTS)"
#Define APP_ICON								[rts.ico]
#Define APP_INI									[rts.ini]

*//Menu Pad Defines
#Define MENU_PAD_FILE																"FILE"

*//MENU BAR Cases Menu
*//Case Data
	#Define MENU_BAR_CASE_DATA_PRIMARY_CASE_INFO		10000
	#Define MENU_BAR_CASE_DATA_CASE_INSTRUCTIONS		10001
	#Define MENU_BAR_CASE_DATA_ADDITIONAL_CASE_INFO		10002
*//Deponents & Requests
	*//Add New Deponent
		#Define MENU_BAR_DEPREQ_ADD_NEW_NO_ISSUE		10003
		#Define MENU_BAR_DEPREQ_ADD_NEW_ISSUE_SUBPOENA	10004
		#Define MENU_BAR_DEPREQ_ADD_NEW_ISSUE_AUTH		10005
	#Define MENU_BAR_DEPREQ_DEP_SUM						10006
	#Define MENU_BAR_DEPREQ_SELDEP						10007
	#Define MENU_BAR_DEPREQ_VIEW_TAG_0					10008
	#Define	MENU_BAR_DEPREQ_VIEW_ALL					10009
	#Define MENU_BAR_DEPREQ_VIEW_RECEIVED_MATERIALS		10010
	#Define MENU_BAR_DEPREQ_VIEW_DEP_CAT				10011
	#Define MENU_BAR_DEPREQ_VIEW_DEL_DEP				10012
*//Court Document Processing
	#Define MENU_BAR_COURT_DOC_WAV_REC					10013
	#Define MENU_BAR_COURT_DOC_PRINT_NOTICES			10014
	#Define MENU_BAR_COURT_DOC_PRINT_CERT				10015
*//Attorney & Order Information
	#Define MENU_BAR_ATT_ORDER_PART_ATT					10016
	#Define MENU_BAR_ATT_ORDER_ASBESTOS_COST_SHARING	10017
*//Bar Code Printing	
	#Define MENU_BAR_CODE_PRINT_AUTH					10018
	#Define MENU_BAR_CODE_PRINT_INTERROGATORY			10019
	#Define MENU_BAR_CODE_PRINT_ATT_CORRES				10020
	#Define MENU_BAR_CODE_PRINT_STATUS_COUNSEL			10021
	#Define MENU_BAR_CODE_PRINT_RECS_RECEIVED			10022
*//Bates Labels
	#Define MENU_BAR_BATES_PRINT_LABELS					10023
	#Define MENU_BAR_BATES_ADD_TAGS						10024
	

*//Menu Bar Defines: File Pad
#Define MENU_BAR_FILE_CASES													11001
#Define MENU_BAR_FILE_ATTORNEYS												11003
#Define MENU_BAR_FILE_DEPO													11002
#Define MENU_BAR_FILE_COURT													11004
#Define MENU_BAR_FILE_EXIT													11105
#Define MENU_BAR_FILE_LOGIN_USER										11107

*//Menu Bar Defines: Window Pad
#Define MENU_BAR_WINDOW_CLOSEALL										41005

#Define READMODE_SINGLE									1
#Define READMODE_LIST									2

#Define INI_ACTION_READ									"R"
#Define INI_ACTION_WRITE								"W"

#Define INI_SECTION_APP									"APP"
#Define INI_SECTION_SEARCH							"Search"
#Define INI_SECTION_SQL									"SQL"
#Define INI_SECTION_DATA								"DATA"

#Define INI_KEY_UID										"uid"
#Define INI_KEY_PWD										"pwd"
#Define INI_KEY_SERVER									"Server"
#Define INI_KEY_DATABASE								"Database"

#Define INI_KEY_INCREMENTAL_SEARCH_INTERVAL					"IncrementalSearchInterval"

#Define READMODE_SINGLE									1
#Define READMODE_LIST									2

#Define ALEN_ELEMENTS									0
#Define ALEN_ROWS										1
#Define ALEN_COLUMNS									2

*//Office Mediator Defines
#Define MED_OFFICE_GET_LIST_BY_CODE					1
#Define MED_OFFICE_GET_LIST_BY_DESC					2

*//Common strings
#Define STR_PRE_UPDATE_PLEASE_CORRECT								"Please correct the following in order to continue:"



*--
#DEFINE MASTERCASEFORM_CLASS			"FRMCASE"