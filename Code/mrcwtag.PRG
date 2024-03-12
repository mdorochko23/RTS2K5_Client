**PROCEDURE mrcWtag
PRIVATE OMED AS OBJECT

OMED=CREATEOBJECT("REQUEST.medREQUEST")
**05/12/14 - MIssouri cases - 32 cases 91 new tags.
**05/06/14 - MDL non trial  6021 tags ( 442 cases with pl attys)
**05/05/14 - 35 State tags
**05/01-05/02 - 5216 tags for  371 MDL non trial  cases
*lcSQLLine="Exec  [dbo].[GetMRCWTags_Batch2] " 
*lcSQLLine="Exec DBO.GetMRCWtags"
*lcSQLLine="Exec [dbo].[GetMRCWTags_Missouri32newcases] " 
*lcSQLLine="Exec [dbo].[GetMRCWTags_CasesGroup520] "  &&5/21/14- group 520 cases= 2701 tags

lcSQLLine="Exec [dbo].[MRCWTags_Random] " && 26 tags per Alec's list
DIRECTSQL(lcSQLLine,"Newtags")



SELECT  lrs_no,DESCRIPT,Department , mailid , ReqType AS [type],sentDate AS [IssDate], ;
	Scope, [Status]  , mrcfile, mrcreqid, CmlpDate, STCdate  ;
	FROM newtags INTO CURSOR Addtag READWRITE ;
	WHERE NOT EMPTY(NVL(lrs_no,0)) ORDER BY lrs_no



nicnt=1
nitems=RECCOUNT('addtag')
IF nitems>0
	SELECT Addtag

	SCAN
		WAIT WINDOW "Processing new tags" + STR(nicnt)  NOWAIT
		c_path =""
		c_blurb=""
		c_status=""

		IF Addtag.lrs_no<>0
		 c_status = IIF(EMPTY(NVL(Addtag.CmlpDate,'') ) and EMPTY(NVL( Addtag.STCdate,'') ) , "T","W")
		 c_issdate =Addtag.IssDate
			DO mrctag WITH STR(lrs_no),DESCRIPT, Department, mailid , 'A',c_issdate, Scope,  c_status,  mrcfile, mrcreqid
		ENDIF
		nicnt=nicnt+1
		SELECT Addtag

	ENDSCAN
ENDIF
RELEASE OMED
gfmessage("Processing complete")


******************************************************************************
PROCEDURE mrctag

LPARAMETERS nrt,cdescript, cDept2,  cmailid, ctype, csend ,cblurb, cstatus, cmrcCase, cmrcRequest
LOCAL lcSQLLine, lcIDTblTimeSheet, ncurarea,cclcode, cdept

ncurarea=SELECT()
cdept="Z"

SET CLASSLIB TO issued ADDIT
_SCREEN.MOUSEPOINTER=11
PRIVATE OMED AS OBJECT
OMED=CREATEOBJECT("REQUEST.medREQUEST")
SELECT 0
IF EMPTY(cmailid)
	gfmessage("Add tag cancelled.No location selected.")
	RETURN
ENDIF
c_today=DTOC(DATE())

***deponent
lcSQLLine="select dbo.GetdepName ( '" + cmailid + "')"
OMED.sqlexecute(lcSQLLine,"TagDesc")
IF EMPTY(ALLTRIM(cdescript))
	cdescript=NVL(TagDesc.EXP,"")
ENDIF

****master
lcSQLLine="exec dbo.GetMasterbyRTNumber " + ALLTRIM(nrt)
nr=OMED.sqlexecute(lcSQLLine,"master")

IF RECCOUNT("master")=0
	RETURN .F.
ENDIF

cclcode=MASTER.cl_code
lcSQLLine=""

*//get department
PC_DEPTYPE = UPPER( LEFT( cmailid, 1))
IF NOT INLIST( PC_DEPTYPE, "H", "E", "A", "D")
	PC_DEPTYPE = "D"
ENDIF

IF PC_DEPTYPE ="H"
	DO CASE
	CASE  "Radiology Catalog"$cDept2
		pc_CertTyp="D"
		cdept="R" 	
	CASE  "Medical"$cDept2
		pc_CertTyp="R"
		cdept="M"
	CASE "Billing"$cDept2
		pc_CertTyp="B"
		cdept="B"
	OTHERWISE
		cdept="M"
		pc_CertTyp="R"
	ENDCASE
ELSE
cdept="Z" 	
DO CASE
	CASE  "Radiology Catalog"$cDept2
		pc_CertTyp="D"
		
	CASE  "Medical"$cDept2
		pc_CertTyp="R"
		
	CASE "Billing"$cDept2
		pc_CertTyp="B"
		
	OTHERWISE
		pc_CertTyp="R"
		
	ENDCASE
ENDIF

cAddition=""
DO CASE
	CASE  "Radiology Catalog"$cDept2
		cAddition=' (RAD)'
		
	CASE  "Medical"$cDept2
		cAddition=' (MED)'
	CASE "Billing"$cDept2
		cAddition=' (BILL)'
	CASE "Psychiatric" $cDept2		
		cAddition=' (PSYCH)'
	ENDCASE



lcSQLLine=""
*// Request
cReqdate= IIF(cstatus='T', '',csend) 
cReqdate2= IIF(EMPTY(NVL(cReqdate,{})),"null","'"+cReqdate+"'")+ ","  

lcSQLLine="exec  dbo.InsertMRCRequest '"+ALLTRIM(MASTER.id_tblmaster)+"', "+;
	"'"+fixquote(ALLTRIM(cclcode))+"', '"+ALLTRIM(cmailid)+"', "+;
	"'"+LEFT(fixquote(ALLTRIM(UPPER(cdescript))),50)+"', " +  cReqdate2 +  cReqdate2 + ;
	" '" + cstatus + "','" + ctype + "','" + ;
	"(MRC) "+ALLTRIM(Pc_userid)+"','" + cdept + "','" + cAddition + "'"


nr=OMED.sqlexecute(lcSQLLine,"viewReq")
SELECT viewReq
IF RECCOUNT()=0
	gfmessage("Problem with Tag")
	RETURN .F.
ENDIF

lcSQLLine="SELECT TAG, MAILID_NO, REQ_DATE, REQDUEDATE,expedite, id_tblrequests FROM tblrequest with (nolock) WHERE id_tblrequests ='"+viewReq.id_tblrequests+ "' and active =1 "
nr=OMED.sqlexecute(lcSQLLine,"viewRequest")

*//Set Public Var
pl_GotCase=.F.
DO gfGetCas
pl_GotDepo=.F.
DO gfGetDep WITH MASTER.cl_code,viewRequest.TAG
STORE "" TO  lctblSpecid,lcIDTblTimeSheet




*// TXN 11/19
n_txn=IIF(cstatus="W",11,19)


lcIDTblTimeSheet=OMED.addtxnrec("I",CTOD(csend),;
	ALLTRIM(UPPER(fixquote(cdescript))), ALLTRIM(cclcode), n_txn,;
	viewRequest.TAG,ALLTRIM(cmailid), 0,0.0000, 0, "","","",0, ;
	"", "A",Pc_userid, viewRequest.id_tblrequests, "")
IF EMPTY(ALLTRIM(lcIDTblTimeSheet))
	gfmessage("Problem with Txn11/19.")

	RETURN .F.
ENDIF
*// SpecIns
lcSQLLine=""
lctblSpecid= AddSpec_ins (lcIDTblTimeSheet, cclcode,viewRequest.TAG, cdescript, ctype, cmailid ,cdept, cblurb)
IF !lctblSpecid
	gfmessage("Problem with Blurbs")
	RETURN .F.
ENDIF
*//  add notice
*!*	coffice="P"
*!*	n_printed=0
*!*	pl_handsrv=.f.
*!*	pl_ofchous=.f.
*!*	pl_prntnot=.f.
*!*		STORE "" TO pc_servnam, pc_mailnam
*!*		lc_str=""
*!*		lc_str="Exec dbo.sp_AddNotice '" ;
*!*			+ fixquote(cclcode) + "','" ;
*!*			+ STR((viewRequest.TAG) + "','" ;
*!*			+ DTOC(d_today) + "','" ;
*!*			+ DTOC(d_today)) + "','" ;
*!*			+ fixquote(cdescript) + "','" ;
*!*			+ cblurb + "','" ;
*!*			+ IIF( pl_prntnot, ALLT(pc_rqatcod), "no print") + "','" ;
*!*			+ pc_litcode + "','0'," ;
*!*			+ ALLTRIM(cmailid) + "','" + ctype+ ;
*!*			+ "'," ;
*!*			+ IIF(coffice="P",STR(0), STR(n_printed)) + " ," ;
*!*			+ IIF(pl_handsrv,STR(1),STR(0)) + "," ;
*!*			+ IIF(pl_handsrv,STR(1),STR(0)) + ", null, '','', '', '" ;
*!*			+ ALLTRIM(pc_userid) + "'," + IIF (pl_ofchous,STR(1),STR(0)) ;
*!*			+ ",'" + IIF( pl_handsrv, pc_servnam, pc_mailnam) + "'"

*!*		l_notice=omed.sqlexecute(lc_str,"")

*
*// Add Orders
DO SetOrdTg WITH viewRequest.TAG

*** add to log

lc_str=""
lc_str="Exec [dbo].[AddMRCWtags] '" + cmrcCase + "','" + ;
	nrt+ "','"  +fixquote(cclcode)  + "','" + ;
	STR(viewRequest.TAG)  + "','" + cmrcRequest + "','AddWtags'"

l_ok=OMED.sqlexecute(lc_str,"")

IF NOT EMPTY(ncurarea)
	SELECT (ncurarea)
ENDIF
RELEASE OMED

RETURN
*****************************************************
PROCEDURE DIRECTSQL
PARAMETERS lcSQLLine, lcCursor

LOCAL lnCurArea, loConn, lnConnHandle
lnCurArea=SELECT()
loConn=CREATEOBJECT("RTS.Data.SQLConnection", "")

lnConnHandle=SQLSTRINGCONNECT(loConn.ConnectionString)

IF lnConnHandle>0

	SQLEXEC(lnConnHandle,lcSQLLine,lcCursor)

ENDIF

SQLDISCONNECT(lnConnHandle)

SELECT (lnCurArea)

RETURN lnConnHandle
