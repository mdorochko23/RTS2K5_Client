Parameters c_BTBILLTO, l_ShowMsg
**09/26/2013- check billto data -if atty code or just text- do not let text to be stored-request a valid atty code
Local c_alias As String, l_valid As Boolean, c_billto As String, o_MED As Object
c_alias=Alias()
c_billto=Alltrim(Nvl(c_BTBILLTO,''))
If Empty(c_billto)
	Return .T.

Endif
_Screen.MousePointer=11
o_MED=Createobject("generic.medgeneric")
Select 0
l_valid =.T.
o_MED.closealias ("RqBillTo")
o_MED.sqlexecute("SELECT dbo.qc_GetRqAttyBillto ('" + pc_clcode + "')" ,"RqBillTo")
If  empty(Nvl(RqBillTo.Exp,''))

If Not Empty(c_billto)
	o_MED.closealias ("ChkBilto")
	o_MED.sqlexecute("SELECT [dbo].[ValidateBillTo] ('" +Alltrim(fixquote(c_billto)) + "')", "ChkBillto")
	If Empty(Nvl(ChkBilLto.Exp,''))
		l_valid =.F.
		If  l_ShowMsg
			gfmessage("The attorney/firm submitting this case has supplied a Bill To location that has not been added to indirect billing. Please update this information to process this case." )
		Endif
	Endif

ENDIF
ENDIF 
Release o_MED
_Screen.MousePointer=0
If Not Empty(c_alias)
	Select (c_alias)
Endif

Return l_valid

