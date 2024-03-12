**************************************************************************************
*  PROGRAM retire
*  Date: 2/03
*  By:  kdl
*  Abstract: Procedures for deponent retirement processes
*
*  Called by: frmdeponentdetail
*  Calls:gfYesNo.prg,gfuse.prg,gfno_yes.prg,printrp.prg
*  Modifications:
*
*************************************************************************************
* 06/04/2010 - MD added activestatus='R' when tbldeponent is updated

*****************************************************************************
* PROCEDURE: DPREQRET
*
*-- Abstract: Process request to retire deponent - check if there are active
*--           issues and confirm user request
*****************************************************************************
PROCEDURE DpReqRet

*--1st check if the deponent is elegible for retirement
PRIVATE n_CurArea
*--evaluate for return conditions
DO CASE
   CASE NOT goApp.CurrentUser.oRec.unitmgr
      =lp_message("Function not authorized. See your Unit Manager.")
      RETURN
   CASE deponent.retire
      =lp_message("Deponent already retired.")
      RETURN
ENDCASE

n_CurArea = SELECT()
SELECT deponent
*--PUSH KEY CLEAR
IF NOT listreqs( deponent.mailid_no)
   IF lf_yesno("Are you sure you want to RETIRE this DEPONENT?")
      SELECT (n_CurArea)
      DO DpRetire
   ENDIF
ELSE
   CLEAR TYPEAHEAD
   IF lf_yesno("Can not retire deponet. View active issue(s)?")
      SELECT (n_CurArea)
      DO dpRqdisp WITH "dpActReq", "cur_mail"
   ENDIF
ENDIF
SELECT (n_CurArea)
*--POP KEY
RETURN
*****************************************************************************
* PROCEDURE: LISTREQS
*
*-- Abstract: Prepare list of all active request for passed mailid
*****************************************************************************
PROCEDURE listreqs
PARAMETER c_mailidno, c_addwhere
PRIVATE c_Select, l_grecord
IF PARAMETERS() < 2
   c_addwhere = ""
ENDIF

WAIT WINDOW "Checking for active requests.  Please wait..." NOWAIT NOCLEAR
*--DO waitscr WITH "Checking for active requests.  Please wait..."
*--=gfMsg("Checking for active requests...",.T.)
*--l_grecord = gfuse("grecord")

c_Select = "SELECT r.cl_code,r.tag,r.status,r.req_date," + ;
   "r.last_call,r.mailid_no,r.descript,m.lrs_no," + ;
   "m.name_first,m.name_last " + ;
   "FROM tblrequest r, tblmaster m " + ;
   "WHERE m.cl_code = r.cl_code AND " +;
   "r.mailid_no ='&c_mailidno.' AND " + ;
   "r.status IN ('I','T','W') " +;
   IIF(EMPTY(c_addwhere), "", "AND " + c_addwhere)  + ;
   " ORDER BY m.lrs_no, r.tag"
o_rolgen=CREATEOBJECT('medgeneric')
o_rolgen.sqlexecute(c_select,'cur_mail')

*--c_Select = "SELECT grecord.cl_code,grecord.tag,grecord.status,grecord.req_date," + ;
   "grecord.last_call,grecord.mailid_no,grecord.descript,tamaster.lrs_no," + ;
   "tamaster.name_first,tamaster.name_last " + ;
   "FROM grecord, tamaster " + ;
   "WHERE tamaster.cl_code = grecord.cl_code AND " +;
   "grecord.mailid_no = c_mailidno  AND " + ;
   "grecord.status IN ('I', 'T', 'W') " +;
   IIF(EMPTY(c_addwhere), "", "AND " + c_addwhere)  + ;
   "INTO CURSOR cur_mail ORDER BY tamaster.lrs_no, grecord.tag"
*--&c_select
*--DO waitclr
WAIT CLEAR
IF RECCOUNT('cur_mail')> 0
	RETURN .T.
ELSE
	RETURN .F.
ENDIF

*--= gfunuse("grecord", l_grecord)
*****************************************************************************
* PROCEDURE: DPRETIRE
*
*-- Abstract: Flag deponent as retire
*****************************************************************************.
PROCEDURE DpRetire
PRIVATE c_Alias,c_sql

c_sql="UPDATE tbldeponent SET retire=1,retired='"+DTOC(d_today)+"',retiredby='&pc_userid.' "+;
	", activestatus='R' WHERE id_tbldeponents='"+deponent.id_tbldeponents+"'"

o_rolgen=CREATEOBJECT('medgeneric')
o_rolgen.sqlexecute(c_sql)

REPLACE deponent.retire WITH .T., ;
	deponent.retired WITH DTOC(d_today), ;
	deponent.retiredby WITH pc_userid IN deponent

*!*	c_Alias = ALIAS()
*!*	DO WHILE NOT RLOCK()
*!*	ENDDO
*!*	REPLACE &c_Alias..retired WITH .T., ;
*!*	   &c_Alias..retireby   WITH pc_UserId, ;
*!*	   &c_Alias..retiredate WITH DATE()
*!*	UNLOCK

RETURN
*****************************************************************************
* PROCEDURE: DPRQDISP
*
*-- Abstract: Display list of items
*****************************************************************************
PROCEDURE dpRqdisp
PARAMETER c_RptForm, c_Alias, c_Mailidno
IF PARAMETERS()<= 2
   c_Mailidno = deponent.mailid_no
ENDIF
SELECT (c_Alias)
GO TOP
oRep=CREATEOBJECT("app.rt_frm_repoutput",c_RptForm,'Active Issue(s) List',c_Alias)
oRep.Show

****************************************************************************
* PROCEDURE: DPSERRET
*
*-- Abstract: Process request to retire service center - check if there are active
*--           issues and confirm user request
*****************************************************************************
PROCEDURE DpSerRet
*--1st check if the sc is elegible for retirement
PRIVATE n_CurArea
*--evaluate for return conditions
DO CASE
   CASE NOT goApp.CurrentUser.oRec.unitmgr
      lp_message("Function not authorized. See your Unit Manager.")
      RETURN
   CASE deponent.retire
      lp_message("Service center already retired.")
      RETURN
ENDCASE
n_CurArea = SELECT()
IF NOT Dpslinks(deponent.mailid_no)
   IF lf_yesno("Are you sure you want to RETIRE this SERVICE CENTER?")
      SELECT (n_CurArea)
      DO DpRetire
   ENDIF
ELSE
   IF lf_yesno("Can not retire service center. View linked deponent(s)?")
      SELECT (n_CurArea)
      DO dpRqdisp WITH "servlink", "servlinks"
*--      DO dpRqdisp WITH "linkdep", "linkdep",service.mailid_no
   ENDIF
ENDIF
SELECT (n_CurArea)
*--POP KEY
RETURN
*****************************************************************************
* PROCEDURE: DPSLINKS
*
*-- Abstract: Identify service center active linked requests
*****************************************************************************
PROCEDURE Dpslinks
PARAMETER c_serviceid
PRIVATE c_CurDbf, l_Result, l_grecord
l_Result = .t.                                  && result of check for active deponents, default is true for found


c_serviceid=ALLTRIM(c_serviceid)

c_sql="SELECT DISTINCT d.mailid_no,d.name,c.[name],dd.servid_no FROM tbldeponent d "+;
	"JOIN tbldepodetail dd ON dd.id_tbldeponents=d.id_tbldeponents "+; 
	"JOIN tbldepocode c ON c.id_tbldepocodes=d.id_tbldepocodes "+;
	"WHERE dd.servid_no='&c_serviceid.' AND NOT d.mailid_no='&c_serviceid.' ORDER BY c.[name],mailid_no"

o_rolgen=CREATEOBJECT('medgeneric')
o_rolgen.sqlexecute(c_sQL,'servlinks')
WAIT CLEAR
RETURN (RECCOUNT('servlinks')>0)

*!*	DO listlink IN selserv WITH "CHK_LINKS"

*!*	l_Result = IIF( RECCOUNT() > 0, .t., .f.)

*!*	RETURN (l_Result)
*****************************************************************************
* FUNCTION: lf_yesno
*
*-- Abstract: Prompt user for yes or no answer
*****************************************************************************
FUNCTION lf_yesno
PARAMETERS lc_message
LOCAL l_response
lo_message = CREATEOBJECT('rts_message_yes_no',lc_message)
lo_message.SHOW
l_response=IIF(lo_message.exit_mode="YES",.T.,.F.)
lo_message.release
RELEASE lo_message
RETURN l_response
*****************************************************************************
* PROCEDURE: lp_message
*
*-- Abstract: display a mesage to the user
*****************************************************************************
PROCEDURE lp_message
LPARAMETERS c_message
o_message = CREATEOBJECT('rts_message',c_message)
o_message.SHOW
RELEASE o_message