#INCLUDE App.h
*________________________________________________________________________________
*________________________________________________________________________________
FUNCTION F_InputEnabledAccess(oThis AS Object) AS Boolean
*
*
*
*________________________________________________________________________________
LOCAL lsRights 								AS String, ;
			loUser 									AS medUser OF Security, ;
			lbRetval 								AS Boolean, ;
			lbCurrentEnabledSetting AS Boolean, ;
			lsObjectId							AS String


	WITH oThis
		lbCurrentEnabledSetting = .Enabled
		lsObjectId							= .ObjectId
	EndWith


	lbRetval = lbCurrentEnabledSetting 

	IF NOT ISNULL(lsObjectId)
		loUser = goApp.CurrentUser
		lsRights = UPPER(ALLTRIM(loUser.GetObjectRight(lsRights)))
		
		DO CASE
			CASE (lsRights == "ENABLED")
				*-- User is allowed to see this object enabled
				*-- so return whatever the current enabled setting is
				lbRetval = lbCurrentEnabledSetting 
			
			CASE (lsRights == "DISABLED" )
				*-- this object is disabled for the current user so always return .F.
				lbRetval = .F.

			CASE (lsRights == "INVISIBLE" )
				*-- this object is disabled for the current user so always return .F.
				lbRetval = .F.
			
			CASE (lsRights == "READONLY" )
				*-- User is allowed to see this object enabled
				*-- so return whatever the current enabled setting is
				lbRetval = lbCurrentEnabledSetting 
			
			
			OTHERWISE
				*-- ToDo: Fire an unhandled exception error here
				lbRetval = .F.
			
		ENDCASE
		
	ENDIF

RETURN lbRetval
 
ENDFUNC


*________________________________________________________________________________
*________________________________________________________________________________
FUNCTION F_InputEnabledAssign (tbEnabled AS Boolean, tsObjectId AS String) AS Boolean
*
*
*
*________________________________________________________________________________
LOCAL lbRetval AS Boolean, lsRights AS String, loUser AS medUser OF Security

	IF ISNULL(tsObjectId) Then
			*-- No Security Set for this Object So 
			*-- Set the Value to whatever was passed in
			lbRetval = tbEnabled
		
	Else
		loUser = goApp.CurrentUser
		lsRights = UPPER(ALLTRIM(loUser.GetObjectRight(lsRights)))
		
		DO CASE
			CASE (lsRights == "ENABLED")
				*-- User is allowed to see this object enabled
				*-- so Set enabled to whatever value was passed in 
				lbRetval  = tbEnabled
			

			CASE (lsRights == "DISABLED" )
				*-- this object is disabled for the current 
				*-- user so always set enabled to .F.
				lbRetval  = .F.

			CASE (lsRights == "INVISIBLE" )
				*-- this object is invisible for the current 
				*-- user so always set enabled to .F.
				lbRetval = .F.
			
			CASE (lsRights == "READONLY" )
				*-- User is allowed to see this object enabled
				*-- so return whatever the current enabled setting is
				*-- let readonly prevent them from changing data
				lbRetval = tbEnabled
			
			
			OTHERWISE
				*-- ToDo: Fire an unhandled exception error here
				lbRetval = .F.
			
		ENDCASE
		
	ENDIF

RETURN lbRetval

ENDFUNC


*________________________________________________________________________________
*________________________________________________________________________________
FUNCTION F_InputVisibleAccess(oThis AS Object) AS Boolean
*
*
*
*________________________________________________________________________________
LOCAL lsRights 								AS String, ;
			loUser 									AS medUser OF Security, ;
			lbRetval 								AS Boolean, ;
			lbCurrentVisibleSetting AS Boolean, ;
			lsObjectId							AS String


	WITH oThis
		lbCurrentVisibleSetting = .Visible
		lsObjectId							= .ObjectId
	EndWith


	lbRetval = lbCurrentVisibleSetting 

	IF NOT ISNULL(lsObjectId)
		loUser = goApp.CurrentUser
		lsRights = UPPER(ALLTRIM(loUser.GetObjectRight(lsRights)))
		
		DO CASE
			CASE (lsRights == "ENABLED")
				*-- User is allowed to see this object enabled
				*-- so return whatever the current Visible setting is
				lbRetval = lbCurrentVisibleSetting 
			
			CASE (lsRights == "DISABLED" )
				*-- this object is disabled for the current user 
				*-- so return whatever the current Visible setting is
				lbRetval = lbCurrentVisibleSetting 

			CASE (lsRights == "INVISIBLE" )
				*-- this object is invisible for the current user 
				*-- so always return .F.
				lbRetval = .F.
			
			CASE (lsRights == "READONLY" )
				*-- User is allowed to see this object enabled
				*-- so return whatever the current Visible setting is
				lbRetval = lbCurrentVisibleSetting 
			
			
			OTHERWISE
				*-- ToDo: Fire an unhandled exception error here
				lbRetval = .F.
			
		ENDCASE
		
	ENDIF

RETURN lbRetval
 
ENDFUNC


*________________________________________________________________________________
*________________________________________________________________________________
FUNCTION F_InputVisibleAssign (tbVisible AS Boolean, tsObjectId AS String) AS Boolean
*
*
*
*________________________________________________________________________________
LOCAL lbRetval AS Boolean, lsRights AS String, loUser AS medUser OF Security


	IF ISNULL(tsObjectId) Then
			*-- No Security Set for this Object So 
			*-- Set the Value to whatever was passed in
			lbRetval = tbVisible
		
	Else
		loUser = goApp.CurrentUser
		lsRights = UPPER(ALLTRIM(loUser.GetObjectRight(lsRights)))
		
		DO CASE
			CASE (lsRights == "ENABLED")
				*-- User is allowed to see this object enabled
				*-- so Set Visible to whatever value was passed in 
				lbRetval  = tbVisible
			

			CASE (lsRights == "DISABLED" )
				*-- this object is disabled for the current 
				*-- so Set Visible to whatever value was passed in 
				lbRetval  = tbVisible

			CASE (lsRights == "INVISIBLE" )
				*-- this object is invisible for the current 
				*-- user so always set visible to .F.
				lbRetval = .F.
			
			CASE (lsRights == "READONLY" )
				*-- User is allowed to see this object enabled
				*-- so Set Visible to whatever value was passed in 
				lbRetval  = tbVisible
			
			
			OTHERWISE
				*-- ToDo: Fire an unhandled exception error here
				lbRetval = .F.
			
		ENDCASE
		
	ENDIF
	

RETURN lbRetval

ENDFUNC





*________________________________________________________________________________
*________________________________________________________________________________
FUNCTION F_InputReadOnlyAccess(oThis AS Object) AS Boolean
*
*
*
*________________________________________________________________________________
LOCAL lsRights 								AS String, ;
			loUser 									AS medUser OF Security, ;
			lbRetval 								AS Boolean, ;
			lbCurrentReadOnlySetting AS Boolean, ;
			lsObjectId							AS String


	WITH oThis
		lbCurrentReadOnlySetting = .ReadOnly
		lsObjectId							= .ObjectId
	EndWith


	lbRetval = lbCurrentReadOnlySetting 

	IF NOT ISNULL(lsObjectId)
		loUser = goApp.CurrentUser
		lsRights = UPPER(ALLTRIM(loUser.GetObjectRight(lsRights)))
		
		DO CASE
			CASE (lsRights == "ENABLED")
				*-- User is allowed to see this object enabled
				*-- so return whatever the current enabled setting is
				lbRetval = lbCurrentReadOnlySetting 
			
			CASE (lsRights == "DISABLED" )
				*-- this object is disabled for the current user 
				*-- so always return Readonly = .T.
				lbRetval = .T.

			CASE (lsRights == "INVISIBLE" )
				*-- this object is invisible for the current user 
				*-- so always return Readonly = .T.
				lbRetval = .T.
			
			CASE (lsRights == "READONLY" )
				*-- User is allowed to see this object enabled
				*-- so always return Readonly = .T.
				lbRetval = .T.
			
			
			OTHERWISE
				*-- ToDo: Fire an unhandled exception error here
				lbRetval = .T.
			
		ENDCASE
		
	ENDIF

RETURN lbRetval
 
ENDFUNC


*________________________________________________________________________________
*________________________________________________________________________________
FUNCTION F_InputReadOnlyAssign (tbReadOnly AS Boolean, tsObjectId AS String) AS Boolean
*
*
*
*________________________________________________________________________________
LOCAL lbRetval AS Boolean, lsRights AS String, loUser AS medUser OF Security


	IF ISNULL(tsObjectId) Then
			*-- No Security Set for this Object So 
			*-- Set the Value to whatever was passed in
			lbRetval = tbReadOnly
		
	Else
		loUser = goApp.CurrentUser
		lsRights = UPPER(ALLTRIM(loUser.GetObjectRight(lsRights)))
		
		DO CASE
			CASE (lsRights == "ENABLED")
				*-- User is allowed to see this object enabled
				*-- so Set readonly to whatever value was passed in 
				lbRetval  = tbReadOnly

			CASE (lsRights == "DISABLED" )
				*-- this object is disabled for the current 
				*-- user so always set ReadOnly to .T.
				lbRetval  = .T.

			CASE (lsRights == "INVISIBLE" )
				*-- this object is invisible for the current 
				*-- user so always set ReadOnly to .T.
				lbRetval  = .T.
			
			CASE (lsRights == "READONLY" )
				*-- User is allowed to see this object enabled
				*-- so return whatever the current enabled setting is
				*-- let readonly prevent them from changing data
				lbRetval = .T.
			
			
			OTHERWISE
				*-- ToDo: Fire an unhandled exception error here
				lbRetval = .T.
			
		ENDCASE
		
	ENDIF
	

RETURN lbRetval

ENDFUNC




*________________________________________________________________________________
*________________________________________________________________________________
FUNCTION F_ButtonEnabledAccess(oThis AS Object) AS Boolean
*
*
*
*________________________________________________________________________________
LOCAL lsRights 								AS String, ;
			loUser 									AS medUser OF Security, ;
			lbRetval 								AS Boolean, ;
			lbCurrentEnabledSetting AS Boolean, ;
			lsObjectId							AS String


	WITH oThis
		lbCurrentEnabledSetting = .Enabled
		lsObjectId							= .ObjectId
	EndWith


	lbRetval = lbCurrentEnabledSetting 

	IF NOT ISNULL(lsObjectId)
		loUser = goApp.CurrentUser
		lsRights = UPPER(ALLTRIM(loUser.GetObjectRight(lsRights)))
		
		DO CASE
			CASE (lsRights == "ENABLED")
				*-- User is allowed to see this object enabled
				*-- so return whatever the current enabled setting is
				lbRetval = lbCurrentEnabledSetting 
			
			CASE (lsRights == "DISABLED" )
				*-- this object is disabled for the current user so always return .F.
				lbRetval = .F.

			CASE (lsRights == "INVISIBLE" )
				*-- this object is disabled for the current user so always return .F.
				lbRetval = .F.
			
			OTHERWISE
				*-- ToDo: Fire an unhandled exception error here
				lbRetval = .F.
			
		ENDCASE
		
	ENDIF

RETURN lbRetval
 
ENDFUNC


*________________________________________________________________________________
*________________________________________________________________________________
FUNCTION F_ButtonEnabledAssign (tbEnabled AS Boolean, tsObjectId AS String) AS Boolean
*
*
*
*________________________________________________________________________________
LOCAL lbRetval AS Boolean, lsRights AS String, loUser AS medUser OF Security

	IF ISNULL(tsObjectId) Then
			*-- No Security Set for this Object So 
			*-- Set the Value to whatever was passed in
			lbRetval = tbEnabled
		
	Else
		loUser = goApp.CurrentUser
		lsRights = UPPER(ALLTRIM(loUser.GetObjectRight(lsRights)))
		
		DO CASE
			CASE (lsRights == "ENABLED")
				*-- User is allowed to see this object enabled
				*-- so Set enabled to whatever value was passed in 
				lbRetval  = tbEnabled
			

			CASE (lsRights == "DISABLED" )
				*-- this object is disabled for the current 
				*-- user so always set enabled to .F.
				lbRetval  = .F.

			CASE (lsRights == "INVISIBLE" )
				*-- this object is invisible for the current 
				*-- user so always set enabled to .F.
				lbRetval = .F.
			
			
			OTHERWISE
				*-- ToDo: Fire an unhandled exception error here
				lbRetval = .F.
			
		ENDCASE
		
	ENDIF
	

RETURN lbRetval

ENDFUNC


*________________________________________________________________________________
*________________________________________________________________________________
FUNCTION F_ButtonVisibleAccess(oThis AS Object) AS Boolean
*
*
*
*________________________________________________________________________________
LOCAL lsRights 								AS String, ;
			loUser 									AS medUser OF Security, ;
			lbRetval 								AS Boolean, ;
			lbCurrentVisibleSetting AS Boolean, ;
			lsObjectId							AS String


	WITH oThis
		lbCurrentVisibleSetting = .Enabled
		lsObjectId							= .ObjectId
	EndWith


	lbRetval = lbCurrentVisibleSetting 

	IF NOT ISNULL(lsObjectId)
		loUser = goApp.CurrentUser
		lsRights = UPPER(ALLTRIM(loUser.GetObjectRight(lsRights)))
		
		DO CASE
			CASE (lsRights == "ENABLED")
				*-- User is allowed to see this object enabled
				*-- so return whatever the current enabled setting is
				lbRetval = lbCurrentVisibleSetting 
			
			CASE (lsRights == "DISABLED" )
				*-- this object is disabled for the current user 
				lbRetval = lbCurrentVisibleSetting 

			CASE (lsRights == "INVISIBLE" )
				*-- this object is disabled for the current user so always return .F.
				lbRetval = .F.
			
			OTHERWISE
				*-- ToDo: Fire an unhandled exception error here
				lbRetval = .F.
			
		ENDCASE
		
	ENDIF

RETURN lbRetval
 
ENDFUNC


*________________________________________________________________________________
*________________________________________________________________________________
FUNCTION F_ButtonVisibleAssign (tbVisible AS Boolean, tsObjectId AS String) AS Boolean
*
*
*
*________________________________________________________________________________
LOCAL lbRetval AS Boolean, lsRights AS String, loUser AS medUser OF Security


	IF ISNULL(tsObjectId) Then
			*-- No Security Set for this Object So 
			*-- Set the Value to whatever was passed in
			lbRetval = tbVisible
		
	Else
		loUser = goApp.CurrentUser
		lsRights = UPPER(ALLTRIM(loUser.GetObjectRight(lsRights)))
		
		DO CASE
			CASE (lsRights == "ENABLED")
				*-- User is allowed to see this object enabled
				*-- so Set enabled to whatever value was passed in 
				lbRetval  = tbVisible
			

			CASE (lsRights == "DISABLED" )
				*-- this object is disabled for the current 
				lbRetval  = tbVisible

			CASE (lsRights == "INVISIBLE" )
				*-- this object is invisible for the current 
				lbRetval = .F.
			
			
			OTHERWISE
				*-- ToDo: Fire an unhandled exception error here
				lbRetval = .F.
			
		ENDCASE
		
	ENDIF
	

RETURN lbRetval

ENDFUNC



*________________________________________________________________________________
*________________________________________________________________________________
FUNCTION F_MenuAccessDenied (tsObjectId AS String) AS Boolean
*-- 
*-- Returns True if menu access is denied for the current user for a given
*-- Menu's objectid
*-- 
*________________________________________________________________________________
LOCAL lbRetval AS Boolean, lsRights AS String, loUser AS medUser OF Security
		
loUser = goApp.CurrentUser
lsRights = UPPER(ALLTRIM(loUser.GetObjectRight(lsRights)))

DO CASE
	CASE (lsRights == "DISABLED")
		lbRetval = .T.

	CASE (lsRights == "ENABLED")
		lbRetval = .F.

	OTHERWISE
		lbRetval = .T.
			
ENDCASE

RETURN lbRetval

*________________________________________________________________________________
*________________________________________________________________________________
Procedure F_MakeCursorWritable
*--
*-- Parameters:		p_cSource - Alias to reopen as writable.
*-- Return Val:		None
*________________________________________________________________________________
LParameters p_cAlias

*--Open in temporary work area--*
Use (Dbf(p_cAlias)) Again In 0 Alias c_TempMakeCursorWritable

*--Close original alias--*
Use In (p_cAlias)

*--Reopen as correct alias--*
Use (Dbf("c_TempMakeCursorWritable")) Again In 0 Alias (p_cAlias)

*--Close our temporary alias--*
Use In c_TempMakeCursorWritable

*//Make alias current
Select (p_cAlias)

RETURN
******************************************************************
FUNCTION GetHosp
local lc_Dept, ln_bar

lc_Dept = ""
DEFINE POPUP DeptPop FROM 17,39 TO 17,60 ;
	TITLE " SELECT Department " ;
	FOOTER " Press <Esc> to cancel "

DEFINE BAR 1 OF DeptPop PROMPT "\<Medical Department"
DEFINE BAR 2 OF DeptPop PROMPT "\<Radiology Department"
DEFINE BAR 3 OF DeptPop PROMPT "\<Pathology Department"
DEFINE BAR 4 OF DeptPop PROMPT "\<Echocardiogram Department"
DEFINE BAR 5 OF DeptPop PROMPT "\<Billing Department"
DEFINE BAR 6 OF DeptPop PROMPT "\-"
DEFINE BAR 7 OF DeptPop PROMPT "Cancel Request" KEY "ESC", "ESC"

ON SELECTION POPUP DeptPop DEACTIVATE POPUP DeptPop
SIZE POPUP DeptPop BY 10,10 &&TO CNTBAR("DeptPop"), 60

DO WHILE .T.
	ACTIVATE POPUP DeptPop
	ln_bar = BAR()
	DO CASE
		CASE ln_bar = 1
			lc_Dept = "M"

		CASE ln_bar = 2
			lc_Dept = "R"

		CASE ln_bar = 3
			lc_Dept = "P"

		CASE ln_bar = 4
			lc_Dept = "E"

		CASE ln_bar = 5
			lc_Dept = "B"

		CASE ln_bar = CNTBAR("DeptPop") OR LASTKEY() = 27
			lc_Dept = ""
			EXIT
	ENDCASE

	IF LASTKEY() = 26 OR BETWEEN( ln_bar, 1, 5)
		EXIT
	ENDIF
ENDDO

DEACTIVATE POPUP DeptPop
RELEASE POPUP DeptPop
RETURN lc_Dept
