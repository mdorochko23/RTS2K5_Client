******************************************************************************************
* 11/28/2017:  Validate Hospital's departments . #67478:
** 04/19/2018 Adds EOF() Check
******************************************************************************************
Parameters cMailId
Local C_DEPT As String
If Type ('LC_DEPT')<>"C"
	Public LC_DEPT As String
Endif
Local O_MESSAGE4 As Object


getvalidh ( Alltrim(cMailId))


C_DEPT=""
Do While Empty(C_DEPT)

	LC_MESSAGE = "Please pick a Valid Department."
	O_MESSAGE4 = Createobject('rts_message',LC_MESSAGE)
	O_MESSAGE4.Show
	Do HOSPDEPT.MPR
	C_DEPT=LC_DEPT
	If Type('C_DEPT')<>"C"
		C_DEPT="X"
	Endif

	If Used("ValidH")
		Select ValidH
		Go Top
		Seek C_DEPT
		If Found()
			Exit
		Else
			C_DEPT=""
			GFMESSAGE( "Invalid department. Please check the Rolodex Data for that Hospital." )
			IF !EOF()
				Skip
			ENDIF
			Loop
		Endif

	Endif

Enddo
Release LC_DEPT
Release O_MESSAGE4
Return C_DEPT

**************************************************************************
**************************************************************************
Procedure  getvalidh
Parameters c_mid
lnCurArea=Alias()
_Screen.MousePointer=11
Private O_MEDh As Object
O_MEDh=Createobject("generic.medgeneric")

O_MEDh.closealias("ValidH")
If pl_CAVer
	c_sql="Exec [dbo].[GetCAValidDept] "
Else
	c_sql="Exec  [dbo].[GetValidDept] '" + c_mid + "'"
Endif

O_MEDh.SQLEXECUTE( c_sql,"ValidH")

If Used('ValidH')
	=CursorSetProp("KeyFieldList", "CodeH", "ValidH")
	Index On codeh Tag codeh   Additive

Endif


Release O_MEDh
If !Empty(lnCurArea)
	Select (lnCurArea)

Endif

Return




