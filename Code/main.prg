* 09/14/05 DMA Add second parameter for login ID override
LPARAMETERS ;
	OfficeCode 	AS 	STRING, ;
	TempLogin	AS	STRING

#INCLUDE APP.h

*____________________________________________________________________
*____________________________________________________________________
* PROGRAM - Main
*           (Entry Point)
*
* Fox Ver - VFP 8
*
*	Note :
*
*		Set TAB width to 2 for viewing this & all other files in this
*		project
*
*____________________________________________________________________
LOCAL lsDir AS STRING

*!*	_Screen.Visible = .F.
*!*	_Screen.Closable = .F.

*----------------------------------------------
*--Set the Application Directory--*
*----------------------------------------------

lsDir = MLAppDir()


*SET DEFAULT TO (lsDir)
*-- do not set the data path
*-- a context sensitive data path will be set
*-- once we know more about the logged in user
*-- and how they logged in (i.e., Office code parameter passed to main app)
*SET PATH to Class;Code;Header;Library;media;Menu;Project;Report;.\Data
SET PATH TO .\CLASS;.\CODE;.\HEADER;.\LIBRARY;.\media;.\MENU;.\PROJECT;.\REPORT;.\FORM


*----------------------------------------------
*--Clear System (Generic)--*
*----------------------------------------------
OfficeCode = IIF( TYPE( 'OfficeCode') <> T_CHARACTER, ;
	"",  ALLTRIM( NVL( OfficeCode, "")))
*-- if it was empty make it null
OfficeCode = IIF( EMPTY(OfficeCode), NULL, OfficeCode)

*-- temporarily hold on to the office code by
*-- writing it to a Property on the screen
*-- otherwise we will lose it
*-- when mlinit does a clear all
LOCAL lbPropertyExists AS Boolean

lbPropertyExists = (TYPE('_Screen.OfficeCode') == T_CHARACTER) ;
	AND (UPPER(PemStatus(_SCREEN, "OfficeCode", ;
	PEMSTATUS_ATTRIBUTE_TYPE)) == ;
	UPPER(PEMSTATUS_TYPE_PROPERTY))

IF lbPropertyExists THEN
	_SCREEN.OfficeCode = OfficeCode
ELSE
	_SCREEN.ADDPROPERTY("OfficeCode", OfficeCode)
ENDIF
*/ 09/14/05 DMA Handle new parameter for Login override
TempLogin = IIF( TYPE('TempLogin') <> T_CHARACTER, ;
	"",  ALLTRIM( NVL( TempLogin, "")))
*-- if it was empty make it null; otherwise, convert to upper case
TempLogin = IIF( EMPTY(TempLogin), NULL, UPPER(TempLogin))

*-- temporarily hold on to the Login override value by
*-- writing it to a Property on the screen
*-- otherwise we will lose it
*-- when mlinit does a clear all
LOCAL lbTempLoginExists AS Boolean

lbTempLoginExists = (TYPE( '_Screen.TempLogin') == T_CHARACTER) ;
	AND ( UPPER( PemStatus( _SCREEN, "TempLogin", ;
	PEMSTATUS_ATTRIBUTE_TYPE)) == ;
	UPPER(PEMSTATUS_TYPE_PROPERTY))

IF lbTempLoginExists THEN
	_SCREEN.TempLogin = TempLogin
ELSE
	_SCREEN.ADDPROPERTY("TempLogin", TempLogin)
ENDIF


*-- initialize all settings
*-- and clear variables and procedures
*-- to start out in a clean default state
DO MLInit

*-- After mlinit, read the
*-- office code parameter out of the
*-- custom screen property
LOCAL lsOfficeCode AS STRING
lsOfficeCode = _SCREEN.OfficeCode
*/ 09/14/05 DMA Pick up Login override parameter, too
LOCAL lsTempLogin AS STRING
lsTempLogin = _SCREEN.TempLogin

*----------------------------------------------
*-- reset the path in case mlinit clears it
*-- at the time of writing this it doesn't
*-- but it potentially could
*----------------------------------------------
SET PATH TO .\CLASS;.\CODE;.\HEADER;.\LIBRARY;.\media;.\MENU;.\PROJECT;.\REPORT;.\FORM
IF DIRECTORY("c:\temp",1)=.F.
   mkdir("c:\temp")
ENDIF 
   
*----------------------------------------------
*--Add a debugging aid
*----------------------------------------------
IF VERSION(2)>0
	ON KEY LABEL CTRL+F12 SUSPEND
ENDIF

*----------------------------------------------
*--Run the Main System--*
*----------------------------------------------
* 09/15/05 DMA Pass new parm to next level routine
*=AppMain(lsOfficeCode)
=AppMain(lsOfficeCode, lsTempLogin)


*----------------------------------------------
*--Clear System (Generic)--*
*----------------------------------------------
*-- close clear and release
*-- all variables, procedures, DLLs, etc.
*-- and set all settings back to a default state
*----------------------------------------------
DO MLClose

RETURN
