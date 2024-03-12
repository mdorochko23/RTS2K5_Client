#Include APP.h
*____________________________________________________________________
* PROGRAM HMLogin 
*
* NOTES : User Login Module.
*____________________________________________________________________
LParameters tbOverrideLogin
Local lbOK

*--Default values--*
lbOK = .T.

*--Test for active forms--*
If MLFormUp(.T.)
   Return .F.
Endif
tbOverrideLogin = .F.

*--Do the Login--*
If !tbOverrideLogin
	lnWindowState = _screen.WindowState
	lbOk = goApp.GetLogin()
ELSE 
	lbOk = .T.
Endif

If lbOK

	*//App setup (post login)
*!*		lbOK = AppSetup()

Endif

IF lbOK
	_Screen.Visible = .T.
	_screen.WindowState= lnWindowState 
Else
	_screen.Visible = .F.
  *--Shut down--*
  goApp.ExitSystem(.T.)

Endif

Return lbOK