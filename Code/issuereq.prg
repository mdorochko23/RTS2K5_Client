***************************************************************************
** EF 01/23/08 - Added [no print] option.
** EF 08/27/07 - Added call to a IssueNotc.prg
** EF 03/28/07 - skip notices question for the civil/subp issues
** EF 09/14/06 - Call frmDeponentSearch in the 'S' mode.
***************************************************************************

PARAMETERS cIssType, cMasterKeyValue, l_thesamecas
LOCAL loRecordord AS void, ld_Today AS DATE, lcTagType
LOCAL omedissd AS OBJECT,l_revdepo
lcTagType="RT"
pl_DuplTag=.F.
omedissd=CREATEOBJECT("medmaster")
omedissd.getitem(cMasterKeyValue)

*pl_GotCase = IIF(l_thesamecas,.T.,.F.)
pl_GotCase =.F.
DO gfgetcas




IF pc_c1Name = "MD-BaltimoCity"  AND  cIssType="S"
	GFMESSAGE( "Alert:  MD-BaltimoCity subpoena should be issued through the Deponent Option Screen.")
	RETURN

ENDIF



**TX-docs: 06/07/2017 TX courts issue need Bar# and email address for a RQ Atty

IF  (pl_txcourt AND cIssType="S")
	IF  TxValidation()
		RETURN
	ENDIF

ENDIF



IF cIssType="S"
	IF pldef1at	(PC_CLCode)
		RETURN
	ENDIF	&&05/03/2012 - check for 1 pl and 1 def atty in a case
	
	IF plnonotice(PC_CLCode)	&& 1/9/2019 YS Checking for plaintiff attys being inhibited #121772
		RETURN
	ENDIF
ENDIF

nTag= newtag()
IF nTag =0
	GFMESSAGE( 'Invalid Tag Number' )
	RETURN

ENDIF

l_rushdepo= pl_RushCas


IF !EMPTY(convrtDate(pd_closing))
	IF GFMESSAGE("Issuing or reprinting a request will cause the case to " + ;
			"be re-opened. Continue?",.T.)=.T.
		DO gfReOpen WITH .T., "Issuing or reprinting a request for tag" + ;
			ALLT( STR( nTag)) + "."
	ELSE

		RETURN
	ENDIF
ENDIF
**REOPRN CLOSED CASES
goApp.DebugMode=.F.
IF USED("Request")
	SELECT REQUEST
	USE
ENDIF
IF USED("PC_depofile")
	SELECT PC_depofile
	USE
ENDIF
IF USED("record")
	SELECT RECORD
	USE
ENDIF
oRequest=CREATEOBJECT("medRequest")
oRequest.getitem(.NULL.)
**1/23/08 add a supress print option
LOCAL c_clnt AS STRING
c_clnt=PC_CLCode
* 05/25/12- move to subp_pa=DO IfPrt1Req WITH c_clnt,STR(nTag)
**1.23.08
pl_RushCas=l_rushdepo
pc_Isstype=cIssType


IF chkAMsignature() =.F.
	GFMESSAGE("Cannot Issue, an account manager does not have a scanned signature stored in the files. Either contact IT dept or edit a case to have another Account Manager.")
	RETURN
ENDIF


SELECT REQUEST
SCATTER NAME loRecord MEMO
IF l_rushdepo=.F.
	IF NOT pl_ofcHous
		IF GFMESSAGE("Is this Request a Rush?",.T.)=.T.
			l_rushdepo = .T.
		ENDIF
	ENDIF
ENDIF
l_revdepo = .F.
IF GFMESSAGE("Issued from Review?",.T.)=.T.
	l_revdepo = .T.
ENDIF
pl_RushCas=l_rushdepo
SELECT REQUEST

loRecord = goApp.OpenForm("Deponent.frmDeponentSearch", "M", NULL, NULL,NULL,.F.,.T.)


IF ISNULL(loRecord) OR TYPE("loRecord")<>"O"
	C_STR= "Update tblMaster set subcnt='" +  IIF(nTag=0, STR(0),STR(nTag-1)) + "' Where cl_code = '" + fixquote(PC_CLCode) + "'"
	IF TYPE('oRequest')<>'O'
		oRequest=CREATEOBJECT("medRequest")
	ENDIF
	l_TagCntUpd=oRequest.sqlexecute(C_STR , "")

	RETURN
ENDIF
IF LEFT(loRecord.mailid_no, 1) = "S"
	GFMESSAGE( "You cannot issue to a Service Rolodex entry.")
	loRecord = goApp.OpenForm("Deponent.frmDeponentSearch", "M", NULL, NULL,NULL,.F.,.T.)
ENDIF
_SCREEN.MOUSEPOINTER= 11

REPLACE ;
	mailid_no 			WITH ALLTRIM(loRecord.mailid_no),;
	DESCRIPT 				WITH loRecord.NAME,;
	open_date 			WITH DATE(),;
	req_date 				WITH DATE(),;
	id_tbldeponents WITH loRecord.id_tbldeponents, ;
	STATUS					WITH "W", ;
	cl_Code WITH PC_CLCode, ;
	TAG WITH nTag, ;
	TYPE WITH  cIssType ;
	IN REQUEST

SELECT REQUEST
SCATTER MEMVAR
lc_formtype=""
d_null=NULL
d_empty=""

ld_Today=d_today
pd_revstop=IIF(ISNULL(pd_revstop), DTOC(d_empty), pd_revstop)
*IIF(pd_revstop={  /  /    },"",pd_revstop)
C_STR=""
c_rev=""
IF pd_revstop<>"  /  /    " OR  pd_revstop<>""
	c_rev =IIF( pl_Review AND DTOC(ld_Today) <= pd_revstop, 'U', 'N')
ENDIF
C_STR= "Exec dbo.AddNewRequest '" +  MASTER.id_tblMaster + "','" ;
	+ IIF(ISNULL(m.id_tbldeponents),'',m.id_tbldeponents) + "','" ;
	+ fixquote(PC_CLCode) + "','" ;
	+ STR(m.tag) + "','W','" ;
	+ ALLTRIM(m.mailid_no) + "','" ;
	+ ALLTRIM(m.RCA_no) + "','" ;
	+ ALLTRIM(pc_userid) + "','" ;
	+ fixquote(m.descript) + "',null ,null ,"   ;
	+ IIF(m.Expedite,STR(1),STR(0)) + ",'" ;
	+ IIF(m.Expedite, IIF(ISNULL(m.Expdate),d_empty,DTOC(m.Expdate)), d_empty) + "','" ;
	+ m.type + "','"  ;
	+ c_rev + "'," ;
	+ STR(0) + "," ;
	+ IIF(l_revdepo,STR(1),STR(0)) + "," ;
	+ IIF(m.First_look,STR(1),STR(0)) + ",'" ;
	+ ALLTRIM(m.FL_Atty) + "','" ;
	+ ALLTRIM(m.Web_Order) + "',null ,'" ;
	+ ALLTRIM(m.Asb_Round) + "','" ;
	+ ALLTRIM(m.BB_locator) + "','" ;
	+ STR(0) + "','" ;
	+ STR(0) + "'," ;
	+ STR(1) + ",'" ;
	+ ALLTRIM(lc_formtype) + "'," ;
	+ IIF(m.HoldPsy, STR(1),STR(0)+",0, null")

**get new record's id
lRequest=oRequest.sqlexecute(C_STR,"")
l_RqId=omedissd.sqlexecute( "select dbo.fn_GetID_tblRequest ('" + fixquote(PC_CLCode) + "','" +  STR(nTag) + "')", "ReqsId")
IF NOT lRequest
	=GFMESSAGE("A tag was not added. Contact IT.")
*--	MESSAGEBOX("A tag was not added. Contact IT.",16, "Add Deponent Error")
	RETURN
ELSE
**update Tag count

	C_STR= "Update tblMaster set subcnt='" +  STR(nTag) + "' Where cl_code = '" + fixquote(PC_CLCode) + "' and active =1"
	l_TagCntUpd=omedissd.sqlexecute(C_STR , "")

	IF NOT l_TagCntUpd
		=GFMESSAGE("Tag count was not updated. Contact IT dept.")
*--		WAIT WINDOW "Tag count was not updated. Contact IT dept."
	ENDIF
ENDIF

oRequest.getitem(ReqsId.EXP)
*REPLACE id_tblrequests WITH ReqsId.EXP IN REQUEST
pc_mailid=loRecord.mailid_no

CREATE CURSOR IfCancel (tblName CHAR(15),tblKey CHAR(36), Action CHAR(1))
SELECT IfCancel
DO  doIfcancel WITH "IfCancel","Record",ReqsId.EXP, "D"
DO  doIfcancel WITH "IfCancel","Request",ReqsId.EXP, "D"

_SCREEN.MOUSEPOINTER=0
RELEASE loRecord
RELEASE oRequest
*------------------------------get the tag type-------------------------------------------
o_rt= CREATEOBJ("REQUEST.frmselectreqtype")
IF o_rt.exit_mode="OK"
	lcTagType=o_rt.reqtype
ELSE
	lcTagType='RT'
ENDIF
RELEASE o_rt
lcSQLLine=""
lcSQLLine="update tblRequest set tag_type='"+ALLTRIM(lcTagType)+"', PrintOrigReq =" +  IIF(pl_StopPrtIss, STR(1),STR(0)) +  " where "+;
	"id_tblrequests='"+ReqsId.EXP+"'"
omedissd.sqlexecute(lcSQLLine)
*------------------------------get the tag type-------------------------------------------

pc_Isstype=cIssType
pn_TAG =nTag
**05/11/2011- TO CALL A CHCEK FOR THE DUPLICATE DEPONENT THE LAST PARAMETER TO THE SUBP_PA WAS added as .t.
DO Subp_PA WITH .F., 1, nTag,.F.,.F.,.F.,cIssType, .F., .T.



IF NOT INLIST( pc_platcod, "A14604P", "A14622P", "A14637P", ;
		"A14638P", "A14753P", "A16078P", "A16124P", "A16486P")

	IF pl_prtnotc
		IF USED('UserCtrl')
			SELECT UserCtrl
			c_SSNLst4=RIGHT( UserCtrl.SSN, 4)
		ENDIF
		DO IssueNotc WITH c_SSNLst4, ld_Today



	ENDIF
ENDIF
*!*	IF NOT pl_DuplTag && called by shwduptag

*!*		=gfmessage("A request has been issued" + IIF( pl_StopPrtIss, ", but won't be printed.","." ))
*!*	ELSE
*!*	SELECT REQUEST
*!*	REPLACE STATUS WITH "T"
*!*	lcSQLLine="update tblRequest set STATUS='T' where id_tblrequests='"+ReqsId.Exp+"'"
*!*	omedissd.sqlexecute(lcSQLLine)
*!*		=gfmessage("A request has been canceled.")
*!*	ENDIF
*!*
RELEASE omedissd
*****************end 10/9/06

