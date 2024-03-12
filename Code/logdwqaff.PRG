*Function logdwqaff
**10/25/2017:  Logs edits on the TX DWQs and Affidavits 
PARAMETERS cclcode, cTag, cUser,cdwq, ccerttyp, cspot
LOCAL O_MED as Object
_SCREEN.MOUSEPOINTER=11
PRIVATE OMED AS OBJECT
O_MED=CREATEOBJECT("generic.medgeneric")

*!*		**UPDATE REQUEST'S DATA and log 
		c_sql=" exec [dbo].[LogDWQs] '" + FIXQUOTE(cclcode) + "','" + Alltrim(ctag) + "','" + Alltrim(cUser)  + "','" + ALLTRIM(cdwq)  +"','"+  cspot +"'"

		O_MED.sqlexecute(c_sql,'')
*!*		**UPDATE dbo.tblAffTriggerLog log

		c_sql=" exec [dbo].[LogTXAff] '" + FIXQUOTE(cclcode) + "','" + Alltrim(ctag) + "','" + Alltrim(cUser)  + "','" + ALLTRIM(ccerttyp)  +"','"+  cspot +"'"
		O_MED.sqlexecute(c_sql,'')
	
	RELEASE O_MED	
		_SCREEN.MOUSEPOINTER=0
 RETURN  .t.
