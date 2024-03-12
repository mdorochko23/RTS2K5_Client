**FUNCTION OrigTxaff

Parameters c_clcode, n_tag

Local O_MED As Object
_Screen.MousePointer=11
Private OMED As Object
O_MED=Createobject("generic.medgeneric")
Local lctype2 As String
O_MED.closealias('MirCert2')
lcSQLLine ="select  [dbo].[getTXN11Certs] ('" +Alltrim(fixquote(c_clcode))+"','"   + Str(n_tag) + "')"
O_MED.sqlexecute(lcSQLLine,'MirCert2')
lcType2=Nvl(MirCert2.Exp,"")

Release O_MED
_Screen.MousePointer=0
Return lcType2



