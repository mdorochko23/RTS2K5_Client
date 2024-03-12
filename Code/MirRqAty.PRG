***FUNCTION MirRqAty
PARAMETERS n_mircase, c_CurRqaty, n_qcRt
LOCAL l_ok as Boolean, ogen as Object, l_cuser as String, lc_sql as String, c_Atcode as String
c_Atcode=""
STORE "" TO l_cuser, lc_sql

ogen=CREATEOBJECT('medgeneric')

l_cuser = ALLTRIM(pc_UserID)

ogen=CREATEOBJECT('medgeneric')
ogen.CLOSEALIAS("UpdQr")
lc_sql=" EXEC [dbo].[qc_UpdateRqAtyFromMirrorCase] '" + ALLTRIM(STR(n_mircase)) +  "','" + fixquote(c_CurRqaty) +"','"  + ALLTRIM(n_qcRt) +"','"  + l_cuser + "'"

ogen.sqlexecute(lc_SQL,"UpdQr")

IF USED('UpdQr')
	c_Atcode=NVL(UpdQr.exp,'')
endif

RETURN IIF(EMPTY(c_Atcode),c_CurRqaty, c_Atcode)