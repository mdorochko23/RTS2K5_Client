
* 11/15/05 EF  Add RT Logo
* 09/15/05 DMA Add additional parameter for Login ID override
LPARAMETERS ;
	tsOfficeCode 	As 	String, ;
	tsLoginParm		As	String
#INCLUDE APP.h
*____________________________________________________________________
*____________________________________________________________________
* PROGRAM - 
*			AppMain.Prg
*
* Description-
*			Application Specific Main program
*
*	Note :
*		Set TAB width to 2 for viewing this 
*		& all other files in this project
*
*____________________________________________________________________
LOCAL lbOk AS Boolean, l_capslock as Boolean, l_numlock as Boolean

Local ARRAY laScreen[1]
**EF 11/15/05 - added RT logo 
DO rtlogo
DO copyright
****added RT logo
*----------------------------------------------
*-- Make some foundation class libraries available
*-- So we can at least launch the Application Object
*-- other class libraries will be made available 
*-- later
*----------------------------------------------
Set Classlib To Base.vcx
Set Classlib To App.VCX ADDI

*----------------------------------------------
*-- Instantiate the main application control object
*-- as public variable
*----------------------------------------------
PUBLIC goApp AS AppCusApp OF App
goApp = CreateObject("appcusApp")

*-- check to see that we actually have a valid 
*-- custom application control object
lbOk = MLValObj(goApp)

l_capslock = CAPSLOCK()
l_numlock = NUMLOCK()
= CAPSLOCK(.T.)
= NUMLOCK(.T.)
IF NOT DIRECTORY('T:\')
 gfMessage("The 'T' drive is not mapped."+CHR(13)+;
   "Please restart computer and complete login or contact IT dept.")
   QUIT
ENDIF    
*!*	IF ADIR(laT,"t:\*.*")=0
*!*	   gfMessage("The 'T' drive is not mapped."+CHR(13)+;
*!*	   "Please restart computer and complete login")
*!*	   QUIT
*!*	ENDIF    
*!*	RELEASE laT
IF lbOk    
    
	*-- Save the current state of the screen 
	*-- so it can be restored when we exit
	= MLScreen("PUSH", @laScreen)

	*--Fire off splash screen--*
	*goApp.Splash("On") && Recordtrak requested no splash screen for this application


	*//BWV temp... until loading the application takes some actual time
*	InKey(.5, "H")



	*----------------------------------------------
	*-- initialize the debug mode by unsetting it
	*-- the access method for the debugmode property
	*-- will read the value out of the inifile
	*-- the first time we need to check if we are 
	*-- in debugmode
	*----------------------------------------------
	goApp.DebugMode = .NULL.


	*----------------------------------------------
	*-- Inits & Login
	*----------------------------------------------
* 09/14/05 Pass new Login ID parameter to next level
*	IF AppInit(tsOfficeCode) 
	IF AppInit( tsOfficeCode, tsLoginParm)
		

*--3/11/2013: check for and run installation programs
 		=checkforinstalls()
 		
		* set plKoPVer and pl_CAVer           
       
		SET STATUS Off
		SET STATUS BAR On

		*--------------------------------------------
		*--display the main menu--*
		*--------------------------------------------
		WAIT APP_LOADING WINDOW NOWAIT NOCLEAR
		DO Main.mpr

		KEYBOARD '{alt+D}'

		********clear the rt logo
        *_screen.Cls 
        *************************rt logo
		*--------------------------------------------
		*-- Add developer's menu pad --*
		*--------------------------------------------
		
		If goApp.DebugMode  && Access method will read value from ini file
			Do MLTest
		Endif

		*--Done with splash screen--*
		goApp.Splash("Off")
		
		
		*--------------------------------------------
		*--Enter Event Loop--*
 		*--------------------------------------------
		WAIT CLEAR				&& clear any wait windows
		READ EVENTS				&& respond to any events until a clear events is issued
		
	ENDIF
	 

	*--------------------------------------------
	*--Save Main Window coordinates to INI file.
	*--------------------------------------------
	WITH _screen
	
		=MLPriPro(INI_ACTION_WRITE, APP_INI, INI_SECTION_APP, ;
			"MainWinZoom", ALLTRIM(STR(IIF(.windowstate>0, 2, 0))))
							
		IF .windowstate # 2  &&--Not Zoomed
			=MLPriPro(INI_ACTION_WRITE, APP_INI, INI_SECTION_APP, ;
				"MainWinTop",	ALLTRIM(STR(.Top)))
			=MLPriPro(INI_ACTION_WRITE, APP_INI, INI_SECTION_APP, ;
				"MainWinLeft",	ALLTRIM(STR(.Left)))
			=MLPriPro(INI_ACTION_WRITE, APP_INI, INI_SECTION_APP, ;
				"MainWinHeight", ALLTRIM(STR(.Height)))
			=MLPriPro(INI_ACTION_WRITE, APP_INI, INI_SECTION_APP, ;
				"MainWinWidth",	ALLTRIM(STR(.Width)))
		ENDIF

			=MLPriPro(INI_ACTION_WRITE, APP_INI, INI_SECTION_APP, ;
				"BackColor",	ALLTRIM(STR(.BackColor)))
			=MLPriPro(INI_ACTION_WRITE, APP_INI, INI_SECTION_APP, ;
				"ForeColor",	ALLTRIM(STR(.ForeColor)))


	ENDWITH
ENDIF


*----------------------------------------------
*--Reset Screen properties
*----------------------------------------------
*//Running from VFP (development)
If (Application.StartMode == 0)

	*//Restore screen properties
	= MLScreen("POP", @laScreen)
	_Screen.Visible = .T.

Endif
 = CAPSLOCK( l_capslock)
 = NUMLOCK( l_numlock)
RETURN lbOk

** EOF **
