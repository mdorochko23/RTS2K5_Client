**************************************************************************************
** EF- Reprint a HOLD Request :  10/17/13
**
*****************************************************************************************************

PARAMETERS n_lrsno, tagreq, l_updauth
LOCAL  l_got11 AS Boolean, n_Opt AS INTEGER, l_Canc2Fax AS Boolean, l_GetPOS AS Boolean, c_grname AS STRING
STORE .F. TO pl_PdfReprint,  l_got11, l_Fax1Req , l_PrtFax,  l_Fax2Req, l_Canc2Fax, l_GetPOS, pl_CANotc
pl_PrtOrigSubp=.F.
pl_PdfReprint=.F.
pl_EditReq=.T.
pl_2ndQue=.T.
pl_1st_Req=.F.
PRIVATE  c_fax AS STRING, c_faxnum1 AS STRING,c_pickdept AS STRING, c_POSStatus AS STRING
STORE "" TO c_fax, c_faxnum1, PC_ISSTYPE,c_pickdept, c_POSStatus
LOCAL ots2 AS medtimesheet OF timesheet
ots2 = CREATEOBJECT("medtimesheet")
n_Opt=0
STORE "" TO szfaxnum, MCLASS, c_grname, c_queue

************************************************************************************************

***GET TXN11
_SCREEN.MOUSEPOINTER=11
l_got11=ots2.sqlexecute(" exec dbo.GetTxn11Line '" + fixquote(pc_clcode)+ "','" + STR(tagreq ) + "'" ,"Timesheet")

IF NOT l_got11 OR EOF()
	RETURN
ENDIF
IF NOT EMPTY(timesheet.id_tbltimesheet)
	ots2.getitem(timesheet.id_tbltimesheet)
	SELECT timesheet
	PC_ISSTYPE=ALLTRIM(timesheet.TYPE)
	IF EMPTY(NVL(PC_ISSTYPE,''))
		PC_ISSTYPE=REQUEST.TYPE
	ENDIF
ENDIF
IF TYPE ('dTxnDate')="U"
	DTXNDATE =  CTOD(timesheet.TXN_DATE)
ENDIF

*!*	********LATEST SPEC INST
IF USED("Spec_ins")
	SELECT Spec_ins
	USE
ENDIF
ots2.sqlexecute("Exec [dbo].[GetTheLatestBlurb] '" + timesheet.CL_code + "',' " + STR(tagreq) + "'", "Spec_ins")


********DEPONENT'S DATA
IF USED("pc_DepoFile")
	SELECT pc_DepoFile
	USE
ENDIF


IF   UPPER( LEFT( timesheet.MailID_NO, 1))="H"
	c_pickdept= NVL(Spec_ins.dept,"Z")
ELSE
	c_pickdept="Z"
ENDIF


WAIT WINDOW "Getting Deponent's information" NOWAIT
l_mail=ots2.sqlexecute("exec dbo.GetDepInfoByMailIdDept  '" + timesheet.MailID_NO +"','" + c_pickdept + "' ", "pc_DepoFile")

=CURSORSETPROP("KeyFieldList", "Code, id_tbldeponents", "pc_DepoFile")

SELECT pc_DepoFile
IF EOF()
	WAIT WINDOW "No Deponent's information has been found."
	RETURN
ENDIF


_SCREEN.MOUSEPOINTER=0
pl_Mail=.F.
DO gfDepInf WITH c_pickdept


IF LEN(ALLTRIM(pc_DepoFile.fax_no))=10 AND NOT INLIST(ALLTRIM(pc_DepoFile.fax_no),'1111111111','2222222222','3333333333','4444444444','5555555555','6666666666','7777777777','8888888888','9999999999','0000000000')
	IF pl_UpdHoldReqst  && 3/21/14 DO NOT ALLOW FAX YET -
		l_Prt2Req=.T.
		l_Fax2Req=.F.
	ELSE
		l_Prt2Req=.F.
		l_Fax2Req=.T.
	ENDIF

ELSE
	l_Prt2Req=.T.
	l_Fax2Req=.F.

ENDIF
IF TYPE ('MCLASS')='U'
	PUBLIC MCLASS
	MCLASS=""
ENDIF
IF TYPE ('MV')='U'
	PUBLIC MV
	MV=""
ENDIF
IF TYPE( "mgroup")="U"
	PUBLIC mgroup
	mgroup = "1"
ENDIF
SET PROCEDURE TO ta_lib ADDITIVE



gnHold = IIF( pl_nohold, 0, pn_c1Hold)
SELECT COURT
lnComply = IIF( SEEK( pc_Court1), gnHold + comply, 10)
mcounty = pc_c1Cnty
gnFRDays = pn_litfday
gnIssDays = pn_litiday
llFromRev = IIF (gnFRDays<>0, .T.,.F.)
mcourt = pc_Court1
mcourt2 = pc_Court2
bNotcall=.F.
c_Action =IIF( PC_ISSTYPE="S","7","8")
b1streq=2
gdBlankDt={  /  /    }
bNotcall =.F.
**-----------MATER data
pl_GotCase=.F.
DO gfgetcas
**-----------Released/Due date
ots2.CLOSEALIAS("MailDate")
LOCAL d_MailDte2 AS DATE
c_sql = " SELECT [dbo].[GetTagMailDate] ('" +fixquote(pc_clcode) + "','" +STR(tagreq) +"')"
ots2.sqlexecute (c_sql,"MailDate")
IF  NOT EOF()
	d_MailDte2=CTOD(LEFT(DTOC(MailDate.EXP),10))
ELSE
	d_MailDte2=CTOD(timesheet.TXN_DATE)
ENDIF

pd_duedate=  GetReqDueDate ( pc_clcode, tagreq, {  /  /    })
IF TYPE( "pd_duedate") = "D"
	IF  EMPTY( pd_duedate)
		cIssType=PC_ISSTYPE
*pd_duedate=getduedate(pd_MailDte,  DTXNDATE ,cIssType, DTXNDATE, lnComply , gnHold, .F., .F.)
		pd_duedate=getduedate(d_MailDte2,  DTXNDATE ,cIssType, DTXNDATE, lnComply , gnHold, .F., .F.)
	ENDIF
ENDIF

n_revision=2
bNotcall=.F.
l_autosub=.F.
l_autocov=.T.

******Call Edit Blurb
l_retval= EditHoldReq ( n_lrsno, tagreq,  NVL(c_pickdept,"Z"),  l_Fax2Req)


IF NOT l_retval && NOT CANCELED

	IF TYPE("pc_userid")<>"C"
		pc_userid="UpdHold"
	ENDIF

	IF USED("Spec_ins")
		SELECT Spec_ins
		USE
	ENDIF
********LATEST SPEC INST AFTER IT HAD BEEN EDITED  ABOVE

	ots2.CLOSEALIAS("SPECDEPT")
	c_sql = " SELECT [dbo].[GetDeptCode2] ('" +fixquote(pc_clcode) + "','" +STR(tagreq) +"')"
	ots2.sqlexecute (c_sql,"SPECDEPT")
	ots2.sqlexecute("Exec [dbo].[GetTheLatestBlurb] '" + fixquote(timesheet.CL_code) + "',' " + STR(tagreq) + "'", "Spec_ins")

&&2/5/15 : stop using  followup with pdfs
*!*		DO PrintReqst WITH IIF(pl_EditReq,.F., pl_PdfReprint), n_revision, tagreq, UPPER(ALLT(timesheet.DESCRIPT))
	DO PrintReqst WITH IIF(pl_EditReq,.F., .F.), n_revision, tagreq, UPPER(ALLT(timesheet.DESCRIPT))
ELSE
	RETURN
ENDIF





IF EMPTY(MCLASS) OR ALLTRIM(MCLASS)="SPC"
	DO queueclass WITH l_Fax2Req ,l_Prt2Req , ALLTRIM(GOAPP.userdepartment)
ENDIF
**01/18/10- get rps by a dept's category -start
pc_BatchRq=""
pl_SpecRpsSrv=.F.
** 6/7/12 -added international requests to that RPS + 3/7/16 added Corp Pharm #34447
ots2.CLOSEALIAS("RpsGov")
ots2.sqlexecute("select [dbo].[getDepCategory] ('"  + fixquote(ALLTRIM(pc_clcode))+"', '"+ALLTRIM(STR(tagreq))+"')" ,"RPSGov")
IF INLIST(NVL(RPSGov.EXP,''),'G','I','P') AND  pc_offCODE='P'

	MCLASS= "RpsGov"
ENDIF

IF pc_offCODE="P" AND MCLASS<> "RpsGov"
	l_oK=ots2.sqlexecute("SELECT dbo.GetRpsQueueNamebyDept ('" + pc_MailID + "','" + NVL(Spec_ins.dept,"Z")+ "','" + pc_offCODE +"')", "RpsQ")
	IF l_oK
		pl_SpecRpsSrv=NVL(RpsQ.EXP,.F.)
		pc_BatchRq=IIF(pl_SpecRpsSrv,"RpsBatch","")

	ENDIF
ENDIF
**01/18/10- get rps by a dept's category -end

DO CASE
CASE !EMPTY(NVL(pc_BatchRq,""))
	c_queue=pc_BatchRq
OTHERWISE
	c_queue=MCLASS
ENDCASE


c_grname=mgroup



DO prtenqa WITH MV,  c_queue, c_grname, IIF( l_Fax2Req, ALLTRIM( szfaxnum), "")
DO RetProc IN subp_pa

gfmessage("A request has been generated.")
RELEASE ots2
pc_CertTyp = ""

IF USED('pc_DepoFile')
	SELECT pc_DepoFile
	USE
ENDIF

RETURN


******************************************************************************************
PROCEDURE DeptInfo
**07/16/12 -attention line modifications
LOCAL  c_DepAttn AS STRING


IF LEFT(timesheet.MailID_NO ,1)="H"
	DO CASE
	CASE "(CATH)" $ UPPER(ALLT(timesheet.DESCRIPT))
		c_deptype = "C"

	CASE "(ECHO)" $ UPPER(ALLT(timesheet.DESCRIPT))
		c_deptype = "E"

	CASE "(RAD)" $ UPPER(ALLT(timesheet.DESCRIPT))
		c_deptype= "R"

	CASE "(PATH)" $ UPPER(ALLT(timesheet.DESCRIPT))
		c_deptype = "P"

	CASE "(BILL)" $ UPPER(ALLT(timesheet.DESCRIPT)) OR ;
			"(BILLING)" $ UPPER(ALLT(timesheet.DESCRIPT))
		c_deptype = "B"

	CASE "(MED)" $ UPPER(ALLT(timesheet.DESCRIPT))
		c_deptype= "M"

	OTHERWISE
		c_deptype = "Z"

	ENDCASE
ELSE
	c_deptype = "Z"


ENDIF




RETURN  c_deptyp
**********************************************************************
PROCEDURE DepInfoLetter
PARAMETERS c_dept
LOCAL c_attn2 AS STRING
STORE "" TO c_attn2, c_attn
IF pc_deptype = "H"

	IF NOT EMPTY(c_dept)
** This is filled in only if hospital!!
		DO CASE
		CASE c_dept == "E"
			c_attn = "ECHOCARDIOGRAM"
			STORE  "ECHO" TO TheInfo, TheInfo2
		CASE c_dept == "R"
			c_attn = "RADIOLOGY"
			STORE  "RAD" TO TheInfo, TheInfo2
		CASE c_dept == "P"
			c_attn = "PATHOLOGY"
			STORE  "PATH" TO TheInfo, TheInfo2
		CASE c_dept == "B"
			c_attn =  "BILLING"
			STORE  "BILLS" TO TheInfo, TheInfo2
		CASE c_dept == "C"
			c_attn =  "CARDIAC CATHS"
			STORE  "CATH" TO TheInfo, TheInfo2
		OTHERWISE
			c_attn = "MEDICAL RECORDS"
			STORE  "MED" TO TheInfo, TheInfo2
		ENDCASE
		c_attn2 = "ATTN: " + c_attn + " DEPARTMENT"
	ELSE
		c_attn2 = ""
		STORE  "MED" TO TheInfo, TheInfo2
	ENDIF                                        && not empty cdept
ELSE
	TheInfo = "OTHER"
	TheInfo2 = "MED"
ENDIF                                           && pc_deptype = H

&&07/16/12-ATTENTION LINE FROM ROLODEX
szattn=IIF(EMPTY(ALLTRIM(pc_MAttn)),c_attn2 , ALLTRIM(UPPER(pc_MAttn)))

RETURN
****************************************************************************
FUNCTION EditHoldReq
**************************************************************************
PARAMETERS nlrs, tag2req, cdept, lFaxDocs, l_skipfax
c_type=PC_ISSTYPE
pl_1st0tag = .F.
PL_STOPPRTISS=.F.
LOCAL omed AS medtimesheet OF timesheet
omed = CREATEOBJECT("medtimesheet")
l_cancel=.F.
&& Allow user to pick the deponent that will receive the request
bselect = IIF(bNotcall,.T.,.F.)
l_Reprint=.F.
n_ReqButt = 1
n_PickReq = 1

&&#65765 NO FAXING for the update hold of the SUBP Requests
IF  (pl_UpdHoldReqst AND NVL(PC_ISSTYPE,'A')='S')

	l_Prt2Req=.T.
	l_Fax2Req=.F.
ELSE
	IF NOT lFaxDocs  &&& request was picked as a fax earlier
		STORE .F. TO l_Prt2Req, l_Fax2Req,  l_Reprint, l_ViewReq
		ln_Pick = GOAPP.OpenForm("issued.frmReq2type", "M", timesheet.TXN_DATE, timesheet.TXN_DATE)

		IF ln_Pick=0 THEN
			gfmessage("Canceled.")
			RETURN .T.
		ENDIF
		DO CASE
		CASE ln_Pick=1
			l_Prt2Req=.T.
		CASE ln_Pick=2
			l_Fax2Req=.T.
		OTHERWISE
			l_cancel=.T.
		ENDCASE
	ELSE
		STORE .F. TO l_Prt2Req,  l_Reprint, l_ViewReq
		l_Fax2Req=.T.

	ENDIF



ENDIF


**START 9/11/14 -ask if they want to supress a request AGAIN
LOCAL l_Conf AS Boolean, l_Confirm AS Boolean
l_Confirm=.F.
omed.CLOSEALIAS("Suppress")
omed.sqlexecute("select [dbo].[WasTagSuppressed] ('" + pc_clcode+ "','" +  ALLTRIM(STR( tag2req ))+ "')", "Suppress")
IF NVL(Suppress.EXP,.F.)=.T.

	l_Conf=.F.
	lc_message = "Do you want to supresss a request?"
	o_message = CREATEOBJECT('rts_message_yes_no',lc_message)
	o_message.SHOW
	l_Conf=IIF(o_message.exit_mode="YES",.T.,.F.)
	o_message.RELEASE
	PL_STOPPRTISS=l_Conf
	** YS 05/29/18 RPS No Print Job Logging [#88327]	
	** YS 06/06/18 Change from ots2 to OMED
	IF PL_STOPPRTISS
		lcSQLLine=" exec [dbo].[AddTrackStopPrint]   '" + convertToChar(pc_lrsno,1) + "','" + convertToChar(fixquote(pc_clcode),1) + "','" + convertToChar(PN_TAG,1) + "','";
			+ convertToChar(pc_isstype,1) + "','" + convertToChar(fixquote(PC_USERID),1) + "','updhold.prg(1)','"+ ALLTRIM(MCLASS) +"'"
		*lcSQLLine=" exec [dbo].[AddTrackStopPrint]   '" + ALLTRIM(pc_lrsno) + "','" + ALLTRIM(pc_clcode) + "','" + ALLTRIM(STR(PN_TAG)) + "','";
		+ pc_isstype + "','" + ALLTRIM(PC_USERID) + "','updhold.prg(1)','" + MCLASS + "'"
		omed.sqlexecute(lcSQLLine,'')
	ENDIF

ENDIF
***********************END 9/11/14
IF NOT l_cancel
&&&11/18/09TEMPRARY ADD HEER: NEEDS TO MERGE WITH THE SAME ON IN REPPDF.PRG
	IF LEN(ALLTRIM(pc_DepoFile.fax_no))=10 AND NOT l_Prt2Req AND NOT PL_STOPPRTISS
		lc_message = "Do you want to print a Fax Cover Sheet?"
		o_message = CREATEOBJECT('rts_message_yes_no',lc_message)
		o_message.SHOW
		l_Confirm=IIF(o_message.exit_mode="YES",.T.,.F.)
		o_message.RELEASE
		IF l_Confirm
			l_Fax2Req=.T.
			l_Prt2Req=.F.
			l_Canc2Fax= FAX2REQST (tagreq)
		ELSE
			l_Fax2Req=.F.
			l_Prt2Req=.T.
			l_Canc2Fax = .F.
		ENDIF
		IF l_Canc2Fax

			l_Fax2Req=.F.
			l_Prt2Req=.T.
		ENDIF
		szfaxnum= cleanfax ( ALLTRIM(pc_DepoFile.fax_no))
	ENDIF


***3/31/14- force sh when an original txn 11 had it-start

	lc_OrigHS=""
	omed.CLOSEALIAS("SHtxn11")
	omed.sqlexecute(" select dbo.GetHoldPrintSpecHandling ('" + STR( nlrs) +"','" + ALLTRIM(STR(tag2req)) + "')","SHtxn11")
	IF USED("SHtxn11")	AND !EOF()
		lc_OrigHS=  ALLTRIM(NVL(SHtxn11.EXP,""))
	ENDIF




	IF l_Prt2Req AND EMPTY(lc_OrigHS)
		l_spechand = .F.
		IF (NOT l_Fax2Req   ) AND NOT PL_STOPPRTISS
			l_Confirm=gfmessage("Do you want to add Special Handling Instructions?",.T.)
			IF l_Confirm
*l_spechand = .T.
*DO SpecHand	IN subp_pa
			ENDIF
		ENDIF
	ENDIF

	IF !EMPTY(ALLTRIM(lc_OrigHS)) OR l_Confirm
		l_spechand = .T.
		DO SpecHand	IN subp_pa
	ENDIF


***3/31/14- force sh when an original txn 11 had it-end

&&1) PRINT request
&&Get the latest rxn 44 /txn11 transaction
	IF USED("LatestReq")
		SELECT LatestReq
		USE
	ENDIF
	omed.sqlexecute("Exec [dbo].[GetTheLatestFollowUp]  '" + timesheet.CL_code + "',' " + STR(tagreq) + "'", "LatestReq")


	c_retvalue=""
	IF NOT EMPTY(NVL(LatestReq.id_tbltimesheet,""))
		c_retvalue=GOAPP.OpenForm("casedeponent.frmRequestDetails", "M", LatestReq.id_tblRequests, ;
			LatestReq.id_tblRequests,LatestReq.id_tbltimesheet, c_type, .T., "M", ;
			"SecReq",pl_RushCas)
	ENDIF

	IF ISNULL(c_retvalue)
		l_cancel=.T.
		MV=""
		STORE .F. TO l_Fax2Req, l_Prt2Req
		RETURN
	ENDIF


ENDIF
*pl_2ndQue = .F.
RELEASE omed


RETURN  l_cancel

