*Purpose: Pass a string (tcPropResults) back to the caller with all relevant properties for a form along with any controls 
*SkipGetPem.dbf hold properties to exclude due to problems within the access method(years of leftovers, that should be handled)
*Some controls and properties are not relevant thus they are excluded 
*Written by: WY
*Written on: 07/08/2021

PARAMETERS tcSkipGetPemPath as String, tcPropResults as string 
LOCAL loForm as Form
LOCAL loControl As Control
LOCAL lcBaseClass as String
LOCAL lcResult, i, lcOldAlias, loValue

lcOldAlias = ALIAS()
IF USED("SkipGetPem") = .f.
	*GetPem() does not get called for these properties
	*avoid errors caused by reading the property and the access methods runs
	*(legacy code with problems but does not get called by RMS)
	*USE C:\TestErrorProps\SkipGetPem IN 0 SHARED
	USE ADDBS(tcSkipGetPemPath) + 'skipgetpem' IN 0 SHARED
ENDIF 
*lookup should be faster from memory
SELECT propname FROM SkipGetPem INTO array gaSkipProps
USE IN SkipGetPem

IF _screen.formCount > 0 
	lcResult = ""
	loForm = _screen.Forms[1]
	*SET STEP ON 
	=AMEMBERS(gaFormProps,loForm, 0)
	*BUILD A HEADER
	lcResult = REPLICATE("=", 60) + CHR(13)
	lcResult = lcResult + "FORM NAME: " + loForm.name + " " + TTOC(DATETIME()) + CHR(13)
	lcResult = lcResult + REPLICATE("=", 60) + CHR(13)
	**GET FORM PROPERTIES WITHOUT CONTROLS
	FOR i = 1 TO ALEN(gaFormProps,0)
		IF INLIST(gaFormProps[i],"CONTROLS","ACTIVEFORM","ACTIVECONTROL","OBJECTS","PARENT") = .F.
			loValue = GetPemWrapper (@loForm, gaFormProps[i])
			lcResult = lcResult + BuildOutputStr("", gaFormProps[i], loValue)
		ENDIF 
	ENDFOR 
	RELEASE gaFormProps

	**FORM CONTROLS**
	lcResult = lcResult + REPLICATE("=", 15) + CHR(13)
	lcResult = lcResult + "Controls:" + CHR(13)
	lcResult = lcResult + REPLICATE("=", 15) + CHR(13)
	FOR EACH loFormControl IN loForm.OBJECTS
		
		=AMEMBERS(gaObjectProps,loFormControl,0)		
		IF ObjectHaveBaseClass(@gaObjectProps)							
			lcBaseClass = ALLTRIM(UPPER(loFormControl.BaseClass))
			IF ExcludeControl(lcBaseClass) = .f.
				DO case
					CASE lcBaseClass == "PAGEFRAME" &&container
						lcResult = lcResult + HandlePageFrame("", @loFormControl)
					CASE lcBaseClass == "GRID" &&container
						lcResult = lcResult + HandleGrid("", @loFormControl)
					CASE lcBaseClass == "CONTAINER" &&container
						lcResult = lcResult + HandleContainer("", @loFormControl)
					CASE lcBaseClass == "OPTIONGROUP"  &&container
						lcResult = lcResult + HandleOptionGroup("", @loFormControl)
					*not containers
					CASE INLIST(lcBaseClass, "TEXTBOX","LABEL","CUSTOM","COMBOBOX","CHECKBOX","EDITBOX","TIMER","LISTBOX","SPINNER")
						lcResult = lcResult + HandleSimpleControl("", @loFormControl)
					OTHERWISE
						SET STEP on
				ENDCASE 
			ENDIF 
		ELSE
			*strange*
			*frmMasterSearch.custContextMenu (sub class of appcontrols.vcx cuscontextmenu) does not have a baseclass property
			*Oh well frmMasterSearch.custContextMenu does nothing
		ENDIF 
		RELEASE gaObjectProps
	ENDFOR 
ELSE
	lcResult = "No active form to read"
ENDIF 
RELEASE gaSkipProps
tcPropResults = lcResult
IF LEN(lcOldAlias) > 0
	SELECT (lcOldAlias)
ENDIF 



FUNCTION HandlePageFrame (tcFormName as String, toFormControl as PageFrame) as String
	LOCAL lcResult, i, j, k, l, lcHiearchy, lcBaseClass
	LOCAL loPropValue, lcHiearchy 
	lcResult = ""
	=AMEMBERS(gaPageFrameProps, toFormControl,0)
	FOR i = 1 TO alen(gaPageFrameProps)

		IF NormalPageFrameProp(gaPageFrameProps[i])     				
			loPropValue = GetPemWrapper (toFormControl, gaPageFrameProps[i])
			lcHiearchy = BuildHierarchy(tcFormName, toFormControl.Name)			
			lcResult = lcResult + BuildOutputStr(lcHiearchy , gaPageFrameProps[i], loPropValue)
		ELSE
			IF ALLTRIM(gaPageFrameProps[i]) == "PAGES"
				*if an error is related to the grid's datasource, it will reset the grid
				*thus columnCount will be 0 by the time this runs
				FOR j = 1 TO toFormControl.PageCount
					=AMEMBERS(gaPageProps, toFormControl.PAGES(j),0)
					FOR k = 1 TO alen(gaPageProps)
						*SET STEP ON 
						*?gaPageProps(k) 
						IF gaPageProps(k) == "CONTROLS"	
							*handle controls within A PAGE
							*expect the column header and a normal control
							FOR l = 1 TO toFormControl.PAGES(j).ControlCount
								IF ObjectHaveBaseClass (@gaPageProps)
								
									lcBaseClass = UPPER(toFormControl.pages(j).controls(l).BASECLASS)
									DO CASE
										CASE lcBaseClass == "GRID"								
											lcResult = lcResult + HandleGrid("." + toFormControl.Name + "." + toFormControl.pages(j).NAME, ;
																						 toFormControl.pages(j).controls(l))
										CASE lcBaseClass == "CONTAINER"
											lcResult = lcResult + HandleContainer("." + toFormControl.Name + "." + toFormControl.pages(j).NAME, ;
																						 toFormControl.pages(j).controls(l))
										CASE lcBaseClass == "PAGEFRAME"
											*PAGEFRAME WITHIN A PAGEFRAME
											lcResult = lcResult + HandlePageFrame("." + toFormControl.Name + "." + toFormControl.pages(j).NAME, ;
																						 toFormControl.pages(j).controls(l))																						
										CASE lcBaseClass == "OPTIONGROUP"
											lcResult = lcResult + HandleOptionGroup("." + toFormControl.Name + "." + toFormControl.pages(j).NAME, ;
																						 toFormControl.pages(j).controls(l))																																
										OTHERWISE	
											IF ExcludeControl (toFormControl.pages(j).controls(l).BaseClass) = .F. 																																							
												lcResult = lcResult + HandleSimpleControl(tcFormName + "." + toFormControl.Name + "." + toFormControl.PAGES(j).NAME, ;
																					 		toFormControl.pages(j).controls(l))										
											ENDIF 
									ENDCASE											
								ENDIF 
							
							ENDFOR

						ELSE
							*PROPERTIES WITHIN 1 PAGE
							IF INLIST(gaPageProps(k), "PARENT","ACTIVECONTROL","OBJECTS") = .F.								
								*handle column properties			
								loValue = GetPemWrapper(toFormControl.Pages(j), gaPageProps(k))								
								lcHiearchy = BuildHierarchy(tcFormName, toFormControl.Name + "." + toFormControl.Pages(j).name)		
								lcResult = lcResult + BuildOutputStr(lcHiearchy, gaPageProps(k), loValue)							
							ENDIF 
						ENDIF 
					ENDFOR 
					**DO NOT RELEASE (AVOID PROBLEMS WHEN A PAGEFRAME IS WITHIN ANOTHER PAGEFRAME)
					**RELEASE gaPageProps
				ENDFOR 

			ENDIF 

		ENDIF 
	ENDFOR 
	**DO NOT RELEASE (AVOID PROBLEMS WHEN A PAGEFRAME IS WITHIN ANOTHER PAGEFRAME)
	**RELEASE gaPageFrameProps
	RETURN lcResult
ENDFUNC


FUNCTION HandleSimpleControl (tcParentContainerName as string, toFormControl as Control) as string
	LOCAL lcResult, i

	lcResult = ""
	=AMEMBERS(gaSimpleProps, toFormControl,0)
	FOR i = 1 TO alen(gaSimpleProps)
		IF ValidSimpleControlProp(gaSimpleProps[i])
			loPropValue = GetPemWrapper(toFormControl, gaSimpleProps[i])
			IF LEN(tcParentContainerName) > 0
				lcResult = lcResult + BuildOutputStr(tcParentContainerName + "." + toFormControl.Name, gaSimpleProps[i], loPropValue)			
			ELSE 
				lcResult = lcResult + BuildOutputStr("." + toFormControl.Name, gaSimpleProps[i], loPropValue)			
			ENDIF 
		ENDIF 
	ENDFOR 
	RELEASE gaSimpleProps
	RETURN lcResult
ENDFUNC 


FUNCTION HandleGrid (tcParentContainerName as String, toFormControl as Grid) as String
	LOCAL lcResult, lcLadder 
	lcResult = ""
	LOCAL i, j,k,l,m
	=AMEMBERS(gaGridProps, toFormControl,0)
	FOR i = 1 TO alen(gaGridProps)

		IF INLIST(gaGridProps[i],"PARENT","COLUMNS","OBJECTS") = .F.
			*loPropValue = GETPEM(toFormControl, gaGridProps[i])
			loPropValue = GetPemWrapper(toFormControl, gaGridProps[i])
			lcResult = lcResult + BuildOutputStr(tcParentContainerName + "." + toFormControl.Name, gaGridProps[i], loPropValue)
		ELSE
			IF gaGridProps[i] = "COLUMNS"
				*if error is related to the grid's data source (perhaps the same work area), it will reset the grid
				*thus columnCount will be 0 (this happens before error handler)
				FOR j = 1 TO toFormControl.ColumnCount
					=AMEMBERS(gaGridColProps, toFormControl.Columns(j),0)
					FOR k = 1 TO alen(gaGridColProps)
						IF gaGridColProps(k) == "CONTROLS"	
							*handle controls within the column
							*expect the column header and a normal control
							*SET STEP ON 
							FOR l = 1 TO toFormControl.Columns(j).ControlCount
								IF ObjectHaveBaseClass(@gaGridColProps)
									IF ExcludeControl(toFormControl.Columns(j).controls(l).BaseClass) = .f. && exclude column header							
										*calling HandleSimpleControl() runs HandlePageFrame() again for some reason (some type reference error)
										*lcResult = lcResult + HandleSimpleControl(toFormControl.Name, toFormControl.Columns(j).controls(l))
										=AMEMBERS(gaGridColControlProps, toFormControl.Columns(j).controls(l),0)
										FOR m = 1 TO alen(gaGridColControlProps)
											IF INLIST(gaGridColControlProps[m],"CONTROLS","ACTIVEFORM","ACTIVECONTROL","OBJECTS","PARENT") = .F.									
												loValue = GetPemWrapper(toFormControl.Columns(j).controls(l), gaGridColControlProps(m))
												lcLadder = BuildHierarchy(tcParentContainerName, ;
																			toFormControl.Name + "." + toFormControl.Columns(j).name + "." + toFormControl.Columns(j).controls(l).name)
												lcResult = lcResult + BuildOutputStr(lcLadder, gaGridColControlProps(m), loValue)																
											ENDIF 
										ENDFOR 
										RELEASE gaGridColControlProps
									ENDIF 
								ENDIF 	
							ENDFOR
						ELSE
							IF INLIST(gaGridColProps(k), "PARENT","COLUMNS","OBJECTS") = .F.
								*handle column properties													
								loValue = GetPemWrapper(toFormControl.Columns(j), gaGridColProps(k))
								lcLadder = BuildHierarchy(tcParentContainerName, ;
														toFormControl.Name + "." + toFormControl.Columns(j).name)
								lcResult = lcResult + BuildOutputStr(lcLadder, gaGridColProps(k), loValue)							
							ENDIF 
						ENDIF 
					ENDFOR
					RELEASE gaGridColProps 

				ENDFOR 

			ENDIF 
		ENDIF 
	ENDFOR
	RELEASE gaGridProps
	RETURN lcResult 
ENDPROC 


FUNCTION HandleContainer (tcParentContainerName as String, toFormControl as Container) as String
	LOCAL lcResult, i,j
	lcResult = ""
	=AMEMBERS(gaContainerProps, toFormControl,0)

	FOR i = 1 TO alen(gaContainerProps)
		IF INLIST(gaContainerProps[i],"PARENT","OBJECTS", "ACTIVECONTROL") = .F.
			IF ALLTRIM(gaContainerProps[i]) = "CONTROLS"
				LOCAL lcBaseClass, lcParentName
				FOR j = 1 TO toFormControl.ControlCount	

					IF ObjectHaveBaseClass(@gaContainerProps)
						lcBaseClass = UPPER(toFormControl.Controls(j).BaseClass)
						lcParentName =  IIF(LEN(tcParentContainerName)=0, ;
											"." + toFormControl.Name, ;
											tcParentContainerName + "." + toFormControl.Name)
						IF ExcludeControl(lcBaseClass) = .f.
							DO case
								CASE lcBaseClass == "GRID" 
									lcResult = lcResult + HandleGrid(lcParentName,  toFormControl.Controls(j))
								CASE lcBaseClass == "PAGEFRAME" 
									lcResult = lcResult + HandlePageFrame(lcParentName,  toFormControl.Controls(j))
								CASE lcBaseClass == "CONTAINER"
									*CONTAINER WITHIN A CONTAINER 
									lcResult = lcResult + HandleContainer(lcParentName,  toFormControl.Controls(j))
								CASE lcBaseClass == "OPTIONGROUP"
									lcResult = lcResult + HandleOptionGroup(lcParentName,  toFormControl.Controls(j))
								OTHERWISE 
									lcResult = lcResult + HandleSimpleControl(lcParentName, toFormControl.Controls(j))							
							ENDCASE 			
						ENDIF 
					ENDIF 
				ENDFOR 				
			ELSE
				loPropValue = GetPemWrapper(toFormControl, gaContainerProps[i])
				lcResult = lcResult + BuildOutputStr(tcParentContainerName + "." + toFormControl.Name, gaContainerProps[i], loPropValue)
			ENDIF 
		ENDIF 
	ENDFOR 
	**DO NOT RELEASE (AVOID PROBLEMS WHEN A CONTAINER IS IN ANOTHER CONTAINER)
	**RELEASE gaContainerProps
	RETURN lcResult
ENDFUNC 


FUNCTION HandleOptionGroup(tcParentContainerName as String, toFormControl as OptionGroup) as String
	LOCAL lcResult,i,j 
	LOCAL loPropValue

	lcResult = ""
	=AMEMBERS(gaOptionGrpProps, toFormControl,0)	
	FOR i = 1 TO alen(gaOptionGrpProps)
		IF INLIST(gaOptionGrpProps[i],"PARENT","OBJECTS", "ACTIVECONTROL") = .F.
			IF ALLTRIM(gaOptionGrpProps[i]) == "BUTTONS"
				FOR j = 1 TO toFormControl.ButtonCount	
					lcResult = lcResult + HandleSimpleControl("." + toFormControl.Name, toFormControl.BUTTONS(j))
				ENDFOR 				
			ELSE
				loPropValue = GetPemWrapper(toFormControl, gaOptionGrpProps[i])
				lcResult = lcResult + BuildOutputStr("." + toFormControl.Name, gaOptionGrpProps[i], loPropValue)
			ENDIF 
		ENDIF 
	ENDFOR
	RELEASE gaOptionGrpProps
	RETURN lcResult 
ENDFUNC 


FUNCTION BuildHierarchy (tcParentStr as String, tcStr2 as String) as String
	IF LEN(tcParentStr) = 0
		RETURN "." + tcStr2 
	ELSE
		RETURN tcParentStr + "." + tcStr2  
	ENDIF 	
ENDFUNC 

FUNCTION ObjectHaveBaseClass(taObjProps) as Boolean
	IF ASCAN(taObjProps,"BASECLASS")> 0
		RETURN .T.
	ELSE
		RETURN .f.
	ENDIF 
ENDFUNC


FUNCTION BuildOutputStr (tcContainerName as string, tcPropName as String, toPropValue) as String

	IF TooMuchInformation(tcPropName)	
		RETURN ""
	ELSE 
		LOCAL lcVarType, lcStr	
		lcStr = ""
		lcVarType = VARTYPE(toPropValue) 
		DO case
			CASE lcVarType = 'C'
				lcStr = tcContainerName + "." + tcPropName + "="
				lcStr = lcStr + toPropValue+ CHR(13)		
			CASE lcVarType = 'L'
				lcStr = tcContainerName + "." + tcPropName + "="
				lcStr = lcStr + IIF(toPropValue, '.T.', '.F.') + CHR(13)			
			CASE lcVarType = 'N'		
				lcStr = tcContainerName + "." + tcPropName + "="
				lcStr = lcStr + " " + ALLTRIM(STR(toPropValue,18,7)) + CHR(13)	&& AVOID ROUNDING		
			CASE lcVarType = 'O'
				lcStr = tcContainerName + "." + tcPropName + "="
				lcStr = lcStr + "OBJECT" + CHR(13)			
			CASE lcVarType = 'U'
				lcStr = tcContainerName + "." + tcPropName + "="
				lcStr = lcStr + "UNKNOWN" + CHR(13)			
			CASE lcVarType = 'D'		
				lcStr = tcContainerName + "." + tcPropName + "="
				lcStr = lcStr + DTOC(toPropValue) + CHR(13)			
			CASE lcVarType = 'T'		
				lcStr = tcContainerName + "." + tcPropName + "="
				lcStr = lcStr + TTOC(toPropValue) + CHR(13)			
			CASE lcVarType = 'Y'		
				lcStr = tcContainerName + "." + tcPropName + "="
				lcStr = lcStr + "CURRENCY" + CHR(13)			
			CASE lcVarType = 'G'		
				lcStr = tcContainerName + "." + tcPropName + "="
				lcStr = lcStr + "GENERAL" + CHR(13)			
			CASE lcVarType = 'X'		
				lcStr = tcContainerName + "." + tcPropName + "="
				lcStr = lcStr + "NULL" + CHR(13)			
			OTHERWISE
				SET STEP ON 
		ENDcase 
		*?lcStr
		RETURN lcStr
	ENDIF 
ENDFUNC 	


*EXCLUDE CONTROLS WE DON'T NEED TO KNOW ABOUT
*EXTRACTING TOO MUCH WILL BLOAT THE RESULTS FILE
FUNCTION ExcludeControl (tcBaseClass as String) as Boolean
	tcBaseClass = UPPER(ALLTRIM(tcBaseClass)) 	
	IF INLIST(tcBaseClass,"COMMANDBUTTON","COMMANDGROUP", ;
				"LINE","HYPERLINK","SHAPE","HEADER", ; && HEADER IS GRID COLUMN HEADER
				"IMAGE","OLECONTROL","OLEBOUNDCONTROL","TOOLBAR", ;
				"CONTROL","CURSOR") 

		RETURN .T.
	ELSE
		RETURN .F.
	ENDIF 
ENDFUNC 


*EXCLUDE PROPERTY WE DON'T NEED TO KNOW ABOUT
*EXTRACTING TOO MUCH WILL BLOAT THE RESULTS FILE
FUNCTION TooMuchInformation(tcPropName as String) as Boolean
	
	*COLOR
	IF INLIST(tcPropName,"FILLCOLOR","BACKCOLOR", ;
			"FILLSTYLE","FORECOLOR","COLORSCHEME", ;
			"COLORSOURCE","DISABLEDBACKCOLOR", ;
			"DISABLEDFORECOLOR","SELECTEDBACKCOLOR","SELECTEDFORECOLOR", ;
			"HIGHLIGHTBACKCOLOR","HIGHLIGHTFORECOLOR", ;
			"SELECTEDITEMBACKCOLOR","SELECTEDITEMFORECOLOR", ;
			"BORDERCOLOR","GRIDLINECOLOR")

		RETURN .T.
	ENDIF
	*FONT
	IF INLIST(tcPropName, "FONTBOLD","FONTCHARSET","FONTCONDENSE", ;
				"FONTEXTEND","FONTITALIC","FONTNAME","FONTOUTLINE", ;
				"FONTSHADOW","FONTSIZE","FONTSTRIKETHRU","FONTUNDERLINE")
		RETURN .T.
	ENDIF 
	*GRID COLUMN DYNAMIC
	IF INLIST(tcPropName, "DYNAMICALIGNMENT","DYNAMICBACKCOLOR", ;
				"DYNAMICCURRENTCONTROL","DYNAMICFONTBOLD","DYNAMICFONTITALIC", ;
				"DYNAMICFONTNAME","DYNAMICFONTOUTLINE", ;
				"DYNAMICFONTSHADOW","DYNAMICFONTSIZE","DYNAMICFONTSTRIKETHRU", ;
				"DYNAMICFONTUNDERLINE","DYNAMICFORECOLOR","DYNAMICINPUTMASK")
		RETURN .T.
	ENDIF 
	*OLE	
	IF INLIST(tcPropName,"OLEDRAGMODE", "OLEDRAGPICTURE","OLEDROPEFFECTS", ;
				"OLEDROPHASDATA","OLEDROPMODE")
		RETURN .T.
	ENDIF 
	*MISCELLANEOUS
	IF INLIST(tcPropName, "HELPCONTEXTID","WHATSTHISBUTTON","WHATSTHISHELP", ;
				"WHATSTHISHELPID", "BORDERSTYLE","ENABLEHYPERLINKS", "DRAGICON", ;
				"DRAGMODE","PICTURE","PICTUREPOSITION","RIGHTTOLEFT")
		RETURN .T.
	ENDIF 
			
	RETURN .F.

ENDFUNC


*why do we need a try-catch wrapper
*because some property have an access method
*calling GETPEM() will run the access method, the access method within the base class have years of clutter and can cause a runtime error
*example 1) MEDMASTER.REPORT_ACCESS, CREATEOBJECT() THROWS AN ERROR (frmMasterSearch)
*example 2) frmMasterEdit.txtName_first (and a dozen or so more controls) datasource_access THROWS AN ERROR
FUNCTION GetPemWrapper (toObject, tcProp as String)

	*Look for known access method problems
	LOCAL lcResult, loResult 

	lcResult = ""
	AMEMBERS(gaSkip, toObject,0)
	IF ObjectHaveBaseClass(@gaSkip)
		IF ALEN(gaSkipProps) > 0  &&note is in skipgetpem.devnote
			IF ASCAN(gaSkipProps, ALLTRIM(UPPER(tcProp)))  > 0
				lcResult = "Avoid Reading" 
			ENDIF 
		ENDIF 
	ENDIF 
	RELEASE gaSkip
	IF LEN(lcResult) > 0
		RETURN lcResult
	ENDIF 

	*get property value
	TRY 
		loResult = GETPEM(toObject, tcProp)
	CATCH
		loResult = "Access Runtime Error" && property should be in SkipGetPem.DBF 
	ENDTRY 
	RETURN loResult
ENDFUNC 

FUNCTION ValidSimpleControlProp(tcPropName as string) as Boolean
	tcPropName = UPPER(ALLTRIM(tcPropName))
	*avoid inlist(), do not want to mess with set extact
	*DO NOT WANT CONFUSE CONTROLS with CONTROLSOURCE
	IF tcPropName == "PARENT" OR ;
		tcPropName == "OBJECTS" OR ;
		tcPropName == "CONTROLS" OR ;
		tcPropName == "ACTIVEFORM" OR ;
		tcPropName == "ACTIVECONTROL"
		RETURN .F.
	ELSE
		RETURN .t.		
	ENDIF 

ENDFUNC

FUNCTION NormalPageFrameProp(tcPropName as string) as Boolean
	tcPropName = UPPER(ALLTRIM(tcPropName))
	*avoid inlist(), do not want to mess with set extact
	IF tcPropName == "PARENT" OR ;
		tcPropName == "OBJECTS" OR ;
		tcPropName == "PAGE" OR ;
		tcPropName == "PAGES" 
		RETURN .F.
	ELSE
		RETURN .t.		
	ENDIF 

ENDFUNC
