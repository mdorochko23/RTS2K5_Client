************************************************
* PROCEDURE - MLTest
*
* Parameter p_aMenu - 3 Column array of options to add to TestX menu
*											1) Prompt
*											2) Action
*											3) [Optional] Skip For Clause
*
* This procedure adds the PROGRAM menu pad
* to the system menu.
************************************************
LParameters p_aMenu
Local l_nMenu, l_cPrompt, l_cAction, l_cMessage, l_lSkipFor

*//Help out the project manager
External Array p_aMenu

Define Pad _msm_prog Of _MSYSMENU ;
	Prompt "Test\<X" ;
	Color Scheme 3 ;
	Key Alt+X, "" ;
	Message "Debug, run, compile, generate and document programs"

On Pad _msm_prog Of _MSYSMENU Activate Popup _mprog

Define Popup _mprog Margin Relative Shadow Color Scheme 4

Define Bar _mpr_do Of _mprog ;
	Prompt "\<Do..." ;
	Key CTRL+D, "Ctrl+D" ;
	Message "Run a program"
Define Bar _mpr_cancl Of _mprog ;
	Prompt "\<Cancel" ;
	Message "Stop running a program"
Define Bar _mpr_suspend Of _mprog ;
	Prompt "\<Suspend" ;
	Message "Suspends the currently running program"
Define Bar _mpr_resum Of _mprog ;
	Prompt "\<Resume" ;
	Key CTRL+M, "Ctrl+M" ;
	Message "Resume suspended program"
Define Bar _mpr_sp100 Of _mprog ;
	Prompt "\-"
Define Bar _mwi_debug Of _mprog ;
	Prompt "De\<bug" ;
	Message "Display Debug window"
Define Bar _mwi_trace Of _mprog ;
	Prompt "\<Trace" ;
	Message "Display Trace window"
Define Bar _mpr_sp200 Of _mprog ;
	Prompt "\-"
Define Bar 5 Of _mprog ;
	Prompt "Turn \<Error Handler Off" ;
	Skip For Empty(On("Error")) ;
	Message "Reset Error Handler to VFP's default"
On Selection Bar 5 Of _mprog On Error
Define Bar _mpr_sp300 Of _mprog ;
	Prompt "\-"
Define Bar _mpr_compl Of _mprog ;
	Prompt "Co\<mpile..." ;
	Message "Compile specified program"
Define Bar _mpr_gener Of _mprog ;
	Prompt "Ge\<nerate..." ;
	Message "Generate code for screens or menus"
Define Bar _mst_macro Of _mprog ;
	Prompt "M\<acros..." ;
	Message "Define custom keyboard shortcuts"
Define Bar _med_find Of _mprog ;
	Prompt "\<Find..." ;
	Key CTRL+F, "Ctrl+F" ;
	Message "Searches for specified text"
Define Bar _mpr_sp300 Of _mprog ;
	Prompt "\-"
Define Bar 1 Of _mprog ;
	Prompt "\<View..." ;
	Message "Open View Window"
On Selection Bar 1 Of _mprog Set
Define Bar 2 Of _mprog ;
	Prompt "\<1 Modify File..." ;
	Message "Modify File"
On Selection Bar 2 Of _mprog Modify Command ?
Define Bar 3 Of _mprog ;
	Prompt "\<2 Modify Class..." ;
	Message "Modify Class"
On Selection Bar 3 Of _mprog Modify Class ?
Define Bar 4 Of _mprog ;
	Prompt "\<3 Do Form..." ;
	Message "Run a form"
On Selection Bar 4 Of _mprog Do Form ("?")

*//Any extras to add on
If (Type("p_aMenu[1, 1]") = "C")

	Define Bar 6 Of _mprog ;
		Prompt "\-"

	For l_nMenu = 1 To ALen(p_aMenu, 1)
	
		*//Skip For clause specified?
		If Empty(p_aMenu[l_nMenu, 3])
		
			*//Add default
			p_aMenu[l_nMenu, 3] = ".F."
		
		Endif
		
		Define Bar (7 + l_nMenu) Of _mprog ;
			Prompt p_aMenu[l_nMenu, 1] ;
			Skip For &p_aMenu[l_nMenu, 3].
			
		On Selection Bar (7 + l_nMenu) Of _mprog &p_aMenu[l_nMenu, 2].
	
	EndFor

Endif