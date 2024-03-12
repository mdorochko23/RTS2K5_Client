* 11/21/05 MD  Add Version #
* 11/17/05 EF  Add UserDepartment
* 09/14/05 DMA Add new parameter for login ID override
*************************************************************************
LPARAMETERS ;
	tsOfficeCode, ;
	tsLoginParm		AS	String
*____________________________________________________________________
*____________________________________________________________________
* PROGRAM - Initialization
*
*
*	Note :
*		Set TAB width to 2 for viewing this & all other files in this
*		project
*
*____________________________________________________________________
#INCLUDE APP.h
LOCAL lbOK 										AS Boolean, ;
			lbDebug 								AS Boolean, ;
			loCurrentUser						AS medUser OF Security, ;
			lsContextSpecificPath 	AS String

*//Default values
lbOK = .T.
lbDebug = goApp.DebugMode

*-- Hold the Office code Override Parameter that was passed in
goApp.OfficeCode = UPPER( tsOfficeCode)

* 09/14/05 Store the Login Override Parameter, if any, in the app property
goApp.UserNameParm = NVL( tsLoginParm, '') 

*----------------------------------------------
*--Suspend ability to close application during INIT
*----------------------------------------------
_SCREEN.CLOSABLE=.F.

*----------------------------------------------
*--Define PUBLIC Variables
*----------------------------------------------
PUBLIC glError, gaScreen

*----------------------------------------------
*--Save Screen properties and Modify for Application
*----------------------------------------------
WITH _SCREEN

  *!*		.Visible = .F.
  .CAPTION		= APP_NAME
  .ICON			= APP_ICON
  .BACKCOLOR 	= VAL(MLPriPro(INI_ACTION_READ, APP_INI, INI_SECTION_APP, ;
  					"BackColor", Alltrim(Str(.BackColor))))
  .ForeCOLOR 	= VAL(MLPriPro(INI_ACTION_READ, APP_INI, INI_SECTION_APP, ;
  					"ForeColor", Alltrim(Str(.ForeColor))))


  *--------------------------------------------
  *--Move Main Window to previous coordinates.
  *--------------------------------------------
  .WINDOWSTATE = IIF(VAL(MLPriPro(INI_ACTION_READ, APP_INI, INI_SECTION_APP, ;
  					"MainWinZoom","2"))>0, 2, 0)
  IF .WINDOWSTATE # 2  &&--Not Zoomed
    .TOP    = VAL(MLPriPro(INI_ACTION_READ, APP_INI, INI_SECTION_APP, ;
    			"MainWinTop", "0"))
    .LEFT   = VAL(MLPriPro(INI_ACTION_READ, APP_INI, INI_SECTION_APP, ;
    			"MainWinLeft", "0"))
    .HEIGHT = VAL(MLPriPro(INI_ACTION_READ, APP_INI, INI_SECTION_APP, ;
    			"MainWinHeight", "480"))
    .WIDTH  = VAL(MLPriPro(INI_ACTION_READ, APP_INI, INI_SECTION_APP, ;
    			"MainWinWidth", "640"))
  ENDIF

ENDWITH


IF NOT(lbDebug)  THEN
  *----------------------------------------------
  *--Activate Global Error Handler (form errors override)
  *----------------------------------------------
  ON ERROR DO mlError ;
    WITH ERROR(), ;
    MESSAGE(), ;
    MESSAGE(1), ;
    SYS(16), ;
    LINENO(), ;
    SYS(102), ;
    SYS(100), ;
    SYS(101), ;
    LASTKEY(), ;
    ALIAS(), ;
    SYS(18), ;
    SYS(5), ;
    SYS(6), ;
    SYS(2003), ;
    WONTOP(), ;
    SYS(2011), ;
    SYS(2018), ;
    SET("CURSOR"), ;
    PROG(), ;
    '', ;
    APP_INI, ;
    getENV('USERNAME'), ;
    APP_NAME, ;
    .t.
ELSE
  ON ERROR &&BWV temp
ENDIF

*--goApp.CurrentUser.ntLogin , ;


*----------------------------------------------
*--Check for System Locks
*----------------------------------------------
lbOK = MlSysLck("IN")

IF lbOK

  *//Global settings
  SET STRICTDATE TO 0
  SET STATUS BAR ON
  SET TALK OFF

  *//Allow F5 to perform context specific refresh 
  *//(Note: ensure form is able to process request.)
  ON KEY LABEL F5 ;
  	IIF(((TYPE( "_Screen.ActiveForm.Class") = T_CHARACTER) AND ;
  		PEMStatus( _SCREEN.ACTIVEFORM, "F5Refresh", 5)), ;
  		_SCREEN.ACTIVEFORM.F5Refresh(), .F.)

ENDIF

IF lbOK

  *----------------------------------------------
  *--Kick off Librarys
  *----------------------------------------------
  *-- Set Libraries
  = SetClassLibs()
  SET HELP OFF

  *----------------------------------------------
  *--Check for valid Login
  *----------------------------------------------

	*-- this would normally display the login form 
	*-- but we are not doing that for this app
	*-- We are going off the NT Login 
  *lbOK = AppLogin() 
	loCurrentUser = CREATEOBJECT("Security.MedUser")

	*-- tell the mediator to lookup the user 
	*-- by keying off the NTLogin
	*-- Since we do not have a primary key 
	*-- for the current user yet
	*-- we do not want to get a new record by passing 
	*-- a null key
	*-- the parameter for GetItem is still 
	*-- the primary key field
	*-- NT login is filled in and available in the 
	*-- request filter alias
	loCurrentUser.LookupUserBy = "NTLogin"
	loCurrentUser.GetItem(NULL)

	goApp.CurrentUser = loCurrentUser
	goApp.UserDepartment = ALlTRIM(UPPER(dept))

	*-- To Validate that we are logged in successfully
	*-- we should have a valid primary key value for the user 
	*-- if not then the user is not a valid registered user
	*-- Notify the User and fail out
	lbOk = (Type('loCurrentUser.PrimaryKeyValue') == T_CHARACTER) ;
				AND NOT(Empty(Nvl(loCurrentUser.PrimaryKeyValue, "")))
	
	IF NOT lbOk Then
		lsMessage = "Invalid Login -- " + loCurrentUser.Ntlogin + ;
			" is not a valid registered user for this application."
*		=MessageBox(lsMessage, MB_DEFBUTTON1 + MB_ICONEXCLAMATION + MB_OK , "Invalid Login" )  )
		ERROR lsMessage
	ENDIF
ENDIF

IF lbOk Then
	*-- now that we have information about the current user get the context 
	*-- specific path for that user taking into consideration
	*-- the Office code Override that was passed 
	*-- to the application as a parameter/command line switch
	lc_ServerName=MLPriPro("R", "RTSDATA.INI", "SQL","SERVER", "\")
	lcTestVersion=IIF(JUSTSTEM(ALLTRIM(UPPER(SYS(16,0))))="RTSTEST","Test","")	
	_SCREEN.Caption = APP_NAME + "  [USER: " + ;
		ALLTRIM( UPPER( goApp.CurrentUser.oRec.FullName)) +"] ("+ALLTRIM(UPPER(lc_ServerName))+")"+;
		SPACE(2)+lcTestVersion+;
		" Version: "+ALLTRIM(lookVrsnBuilt("Version",lcTestVersion))+;
		SPACE(5)+"Built: "+ALLTRIM(lookVrsnBuilt("Built",lcTestVersion))
		
	lsContextSpecificPath = goApp.DataPath

	SET PATH TO &lsContextSpecificPath.

	*-- todo: 	
	*--					IF .pl_Admin THEN
	*--						.pl_Source = "*"
	*--					ENDIF
		

	*-- Set up a bunch of public variables 
	*-- to replicate legacy code
	DO PUBLIC

  *--Some workaround stuff due to Top Level forms--*
  SET SYSMENU TO
  SET SYSMENU AUTOMATIC

  *----------------------------------------------
  *--Define Shutdown procedure and reset screen closing
  *----------------------------------------------
  ON SHUTDOWN DO MenuAction WITH "FILE", "EXIT"
  _SCREEN.CLOSABLE=.T.

ENDIF

SET MESSAGE TO " "

RETURN lbOK

**EOF**
