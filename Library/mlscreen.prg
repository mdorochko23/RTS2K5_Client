#Include foxpro.h
*-----------------------------------------------------*
*// Used to push/pop most _screen settings.  This is 
*// a developer utility.
*//
*// Notes:	Even with LockScreen = .T. and Visible = .F., 
*//					setting WindowState causes flicker.
*//
*//					Special care needs to be given to the order
*//					of setting values because the screen height
*//					changes as menu/status bar/toolbar settings
*//					change.
*-----------------------------------------------------*
LParameters pcMode, paArray
Local ln, llOldLock, laToolBar[1]

*//System Toolbar Name Defines
#DEFINE VFP_TOOLBAR_COLOR_PALETTE		"Color Palette"
#DEFINE VFP_TOOLBAR_DATABASE_DESIGN	"Database Designer"
#DEFINE VFP_TOOLBAR_FORM_CONTROLS		"Form Controls"
#DEFINE VFP_TOOLBAR_FORM_DESIGN			"Form Designer"
#DEFINE VFP_TOOLBAR_LAYOUT					"Layout"
#DEFINE VFP_TOOLBAR_PRINT_PREVIEW		"Print Preview"
#DEFINE VFP_TOOLBAR_QUERY_DESIGN		"Query Designer"
#DEFINE VFP_TOOLBAR_REPORT_CONTROLS	"Report Controls"
#DEFINE VFP_TOOLBAR_REPORT_DESIGN		"Report Designer"
#DEFINE VFP_TOOLBAR_STANDARD				"Standard"
#DEFINE VFP_TOOLBAR_VIEW_DESIGN			"View Designer"

*//Cleanup parameters
pcMode = IIf((Type("pcMode") = "C"), Upper(AllTrim(pcMode)), "")

*//Build array with all system toolbars
Dimension laToolBar[11, 2]
laToolBar[1, 1]		=	VFP_TOOLBAR_COLOR_PALETTE
laToolBar[2, 1]		=	VFP_TOOLBAR_DATABASE_DESIGN
laToolBar[3, 1]		=	VFP_TOOLBAR_FORM_CONTROLS
laToolBar[4, 1]		=	VFP_TOOLBAR_FORM_DESIGN
laToolBar[5, 1]		=	VFP_TOOLBAR_LAYOUT
laToolBar[6, 1]		=	VFP_TOOLBAR_PRINT_PREVIEW
laToolBar[7, 1]		=	VFP_TOOLBAR_QUERY_DESIGN
laToolBar[8, 1]		=	VFP_TOOLBAR_REPORT_CONTROLS
laToolBar[9, 1]		=	VFP_TOOLBAR_REPORT_DESIGN
laToolBar[10, 1]		=	VFP_TOOLBAR_STANDARD
laToolBar[11, 1]		=	VFP_TOOLBAR_VIEW_DESIGN

For ln = 1 To 11

  *//Does window (toolbar) exist?
  If WExist(laToolBar[ln, 1])
    
    *//Set flag indicating if toolbar is visible
    laToolBar[ln, 2] = .T.
    
	Endif

EndFor

With _Screen

	*//Try to minimize any flicker
	llOldLock = .LockScreen
	.LockScreen = .T.

	*//Pushing or popping
	If (pcMode == "PUSH")

		Dimension paArray[24]
		paArray[1] = .Caption
		paArray[2] = .FontName
		paArray[3] = .FontSize
		paArray[4] = .Icon
		paArray[5] = .Backcolor
		paArray[6] = .Left
		paArray[7] = .Top
		paArray[8] = .Height
		paArray[9] = .Width
		paArray[10] = .WindowState
		paArray[11] = .Visible
		paArray[12] = (Set("STATUS BAR") == "ON")
		paArray[13] = (Set("SYSMENU") != "OFF")
		paArray[14] = laToolbar[1, 2]
		paArray[14] = laToolbar[1, 2]
		paArray[15] = laToolbar[2, 2]
		paArray[16] = laToolbar[3, 2]
		paArray[17] = laToolbar[4, 2]
		paArray[18] = laToolbar[5, 2]
		paArray[19] = laToolbar[6, 2]
		paArray[20] = laToolbar[7, 2]
		paArray[21] = laToolbar[8, 2]
		paArray[22] = laToolbar[9, 2]
		paArray[23] = laToolbar[10, 2]
		paArray[24] = laToolbar[11, 2]

	Else
		
		*//Restore menu/status bar/toolbar settings first... they impact screen height
		If (paArray[12] <> (Set("STATUS BAR") == "ON"))
		
			If paArray[12]
			
				Set Status Bar On
			
			Else
			
				Set Status Bar off
				
			Endif
		
		Endif

		If (paArray[13] <> (Set("SYSMENU") != "OFF"))
		
			If paArray[13]
			
				Set SysMenu On
			
			Else
			
				Set SysMenu Off
				
			Endif
		
		Endif

		For ln = 1 To 11
		
			If (paArray[13 + ln] <> laToolbar[ln, 2])
			
				If paArray[13 + ln]
				
					Show Window (laToolbar[ln, 2])
				
				Else
				
					Hide Window (laToolbar[ln, 2])
					
				Endif
			
			Endif
		
		EndFor

		*//Now we can set size, width, etc.
		.Visible 			= paArray[11]
		.Caption			= paArray[1]
		.FontName			= paArray[2]
		.FontSize			= paArray[3]
		.Icon					= paArray[4]
		.Backcolor		= paArray[5]		
		*_Screen.WindowState	= paArray[10]
	
		*//Don't touch x,y properties if _screen is not "Normal"
		If (paArray[10] = WINDOWSTATE_NORMAL)
		
			.Move(paArray[6], paArray[7], paArray[9], paArray[8])

		Endif

	Endif

	*//Restore lockscreen
	.LockScreen = llOldLock

EndWith