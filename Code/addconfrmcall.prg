
*PARAMETERS c_clcode
**EF : 1/5/09 - added a parameters , tryig to fix a probelmw ith pc_clcode var beinf re-assigned to a differrent value
** so it causing an error
LOCAL lnCallType, lnUnits, lc_requestID, lc_TimeSheetID, loMed_ph as Object
loMed_ph=CREATEOBJECT("request.medrequest")
lsSQL = "select dbo.gfIssued('" + fixquote(Pc_clcode)+ "', '" + STR(pn_Tag) + "')"
loMed_ph.Sqlexecute(lsSQL, "viewIssued")
IF viewIssued.EXP =.F.
	RETURN
ENDIF
lcSQLLine="exec [dbo].[GetRequestTagandDescriptionOnly] '" +ALLTRIM(fixquote(Pc_clcode))+"','" +ALLTRIM(STR(pn_Tag)) + "'"
*!*	lcSQLLine="select id_tblRequests, mailid_no, descript "+;
*!*		"from tblRequest where cl_code='"+ALLTRIM(Pc_clcode)+"' and "+;
*!*		"tag="+ALLTRIM(STR(pn_Tag))+" and active=1"
loMed_ph.sqlexecute(lcSQLLine,"PhRequest")

lnUnits=0.1
lnCallType=loMed_ph.lookmailphone(ALLTRIM(PhRequest.MailID_no))
lnCallType = IIF( lnCallType = 1, 8, 2)       && Outgoing 8 -> LD; 2 -> local
* Add record to timesheet
loMed_ph.addTxnRec("S",DATE(), ALLTRIM(fixquote(PhRequest.DESCRIPT)),;
	pc_ClCode,lnCallType, pn_Tag,;
	ALLTRIM(PhRequest.MailID_no), lnUnits, 0, 0, "", "", 0, 0, "", "",;
	goApp.CurrentUser.ntlogin, PhRequest.id_tblrequests,"")

*Pull id_tblTimeSheet
lc_TimeSheetID=loMed_ph.gettimesheetid (pc_ClCode, pn_Tag, lnCallType, DATE())

* Add Comments

loMed_ph.addcomrec("S",DATE(), ALLTRIM(fixquote(PhRequest.DESCRIPT)), ;
	pc_ClCode,lnCallType, pn_Tag, ALLTRIM(PhRequest.MailID_no), 0, 0,;
	"CONFIRMATION CALL", 0,0, goApp.CurrentUser.ntlogin, lc_TimeSheetID)

* Update flags
lsSQLLine=" exec [dbo].[UpdateCallConfirmationOnTag] '" +ALLTRIM(goApp.CurrentUser.ntlogin)+"','" +ALLTRIM(PhRequest.id_tblrequests) +"'"
*!*	lsSQLLine="update tblRequest set Call_Cnt=call_cnt+1, Last_Call= '"+DTOC(d_today) +"', "+;
*!*		"edited='"+TTOC(DATETIME())+"', "+;
*!*		"editedby='"+goApp.CurrentUser.ntlogin+"' "+;
*!*		" where id_tblRequests='"+ALLTRIM(PhRequest.id_tblrequests)+"' and active=1"
loMed_ph.sqlexecute(lsSQLLine)
SELECT PhRequest
USE

IF !EMPTY(convrtDate(pd_closing))
	WAIT WINDOW "NOTE: Case is being automatically re-opened." NOWAIT NOCLEAR
	DO gfReOpen WITH .T., 'adding a phone call for tag '+ALLT(STR(pn_Tag)) + "."
ENDIF
RELEASE loMed_ph
WAIT CLEAR
