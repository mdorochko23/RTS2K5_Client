#Include App.h

**********************************************************************************************
* Procedure: SafeUserObjRead
*
* Description: Security wrapper used by menu Skip For.
*							 Ensures that the goApp.CurrentUser object is valid.
*
* Returns: Numeric.
*
* Parameters: psUserField - The user (pass) field to read.
*							pxDefault	- Default value to use if CurrentUser object 
*													or field is invalid.
*
**********************************************************************************************
LParameters psUserField, pxDefault
Local lxRetVal

*//Default values
lxRetVal = pxDefault

*//Do we have a valid CurrentUser on our app object?
If (Type("goApp.CurrentUser.Class") == T_CHARACTER)

	lxRetVal = goApp.CurrentUser.GetUserField(psUserField, pxDefault)

Endif

Return lxRetVal
