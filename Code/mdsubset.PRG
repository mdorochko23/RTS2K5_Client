PROCEDURE MDSubSet
******************************************************************************************
** EF 03/24/15  Print the MD subpoena forms to send to the court for a signature- txn 19 tags for a date
******************************************************************************************
PARAMETERS  d_DateFrom,  n_RT, n_TagFrom, n_tagTo
PRIVATE lc_Alias, ln_Ok, c_Order,  c_cov,	c_PrintJob, c_Print, ll_Retval	, c_subs, c_subs2 , lc_TEMPFILE 
STORE "" TO c_PrintJob,pc_BatchRq, c_cov, c_subs2
_SCREEN.MOUSEPOINTER=11
lc_Alias = ALIAS()
pl_PrtOrigSubp=.T.
oMed = CREATEOBJECT("generic.medgeneric")
d_MDate=d_DateFrom
pl_MdSubset=.t.
l_continue= getmdtags (n_RT, d_DateFrom ,n_TagFrom,n_tagTo )
IF 	l_continue
	SELECT Mdtags
	IF EOF()
		gfmessage( "No subpoenas to print. ")
		RETURN
	ENDIF
	
_SCREEN.MOUSEPOINTER=11
	SET PROCEDURE TO TA_LIB ADDITIVE
	c_cov = CovLtr(d_MDate)
	c_PrintJob = c_PrintJob + c_cov

	SELECT Mdtags
	INDEX ON CL_CODE+STR(TAG) TAG CLTAG ADDITIVE
	c_Order=" cltag"
	SET ORDER TO &c_Order
	SCAN
		STORE "" TO c_subs, MV
		gcCl_code = Mdtags.CL_CODE
		gntag = Mdtags.TAG
		ll_Retval = GetCase (Mdtags.CL_CODE, Mdtags.TAG )
		IF ll_Retval   &&valid case
			c_subs =GetSubp (Mdtags.lrs_no, Mdtags.TAG , Mdtags.CL_CODE)
			c_subs2 =c_subs2+c_subs
			**ADD TXN 4		
			 c_str=""	
			c_str= "Exec dbo.AddTxn4_MDSubNote '" + DTOC(DATE())+  " ', '" ;
			+LEFT(fixquote(Mdtags.DESCRIPT),40) + "','" +Mdtags.cl_code+ "',' " ;
			+ ALLTRIM(STR(4)) + "','"  + ALLTRIM(STR(Mdtags.tag)) + "','" ;
			+ Mdtags.Mailid_no + "','" + STR(0) + "','" ;
			+ ALLTRIM(STR(0)) + "','" +  "" + "','" ;
			+ ALLTRIM(STR(0)) + "', '"  + "" + "','"  ;
			+ ALLTRIM('S')+ "', '" ;
			+ ALLTRIM(pc_UserID) + "','" ;
			+ Mdtags.id_tblrequests+"', 'MD Baltimore City Subpoena Generated'" 
			l_Retval =	oMed.sqlexecute(c_str,"")
			**
		ENDIF
		SELECT Mdtags
	ENDSCAN
	PL_1ST_REQ=.F.
	l_Prt2Req=.F.
	pl_SkipBatchPRT=.T.
	pl_noticng=.T.
	pc_EmailAdd=""
	DO prtenqa WITH c_PrintJob+c_subs2, "MDsubSet", "1" , ""	

***** -email excel at end of the process
IF EMPTY(ALLTRIM(n_RT))
		lc_TEMPFILE =""
		lc_TEMPFILE = MdfileExl (d_MDate)
endif
	pl_PrtOrigSubp=.F.
	gfmessage( "The set has been sent to the Rps17 printer.")


ENDIF

_SCREEN.MOUSEPOINTER=0
IF USED(lc_Alias)
	SELECT (lc_Alias)
ENDIF
pl_MdSubset=.f.
RELEASE oMed
WAIT CLEAR
RETURN
************************************************************************
PROCEDURE CovLtr
** Prints Issuance Leter

************************************************************************
PARAMETERS d_send
PRIVATE c_Print
c_Print = ""

SET PROCEDURE TO TA_LIB ADDITIVE

DO printgroup WITH c_Print, "MDCovLtr"

DO printfield WITH c_Print, "Loc","P"
DO printfield WITH c_Print, "Date", DTOC( d_send)

RETURN c_Print

*************************************************************************
PROCEDURE GetCase
** Gets data regarding selected case/tag
*************************************************************************
PARAMETERS c_client, n_tag

PRIVATE c_Alias, c_Order1, c_order2, l_Retval

c_Alias = ALIAS()
l_Retval = .T.
oMed.CLOSEALIAS('Master')
l_Retval =	oMed.sqlexecute(" EXEC [dbo].[GetMasterByclcode] '" + c_client + "'",'Master')

SELECT MASTER
pl_GotCase = .F.
DO gfGetCas
**Exclude test cases

c_RqAtty=fixquote(pc_rqatcod)
pl_GetAt = .F.
DO gfatinfo WITH c_RqAtty, "M"
l_Retval=.T.
IF pl_testcas

	IF  ALLTRIM(goApp.CurrentUser.orec.LOGIN) ='ELLEN'
		pl_testcas=.F.
		RETURN .T.
	ENDIF


	l_Retval = .F.
	RETURN l_Retval
ENDIF






IF NOT EMPTY(c_Alias)
	SELECT (c_Alias)
ENDIF

RETURN l_Retval
********************************************************************************************************************
PROCEDURE GetSubp

*******************************************************************************************************************
PARAMETERS  nRTn, cTagn, cClcode
PRIVATE c_SubList, c_Alias
pl_noticng = .F.
STORE "" TO c_SubList, c_Alias
LOCAL C_STR AS STRING ,  ccl_code AS STRING, l_done AS Boolean
oMed1 = CREATE("generic.medgeneric")
c_Alias=ALIAS()
PRIVATE n_tagnum AS INTEGER, n_HOLDrec AS INTEGER

IF USED("spec_ins")
	USE IN Spec_ins
ENDIF
l_SpecIns=oMed.sqlexecute(" Exec dbo.GetSpec_InsbyClCode '" + fixquote(cClcode) + "'", "Spec_ins")

IF NOT l_SpecIns
	gfmessage('Cannot get the Special Instruction File. Try later or contact IT dept.')
	RETURN
ENDIF


IF TYPE ("cTagn")="C"
	PN_TAG =VAL(cTagn)
ELSE

	PN_TAG =cTagn
ENDIF

DO getrequest WITH cClcode,  IIF(TYPE ("cTagn")="N", cTagn,VAL(cTagn))  IN QCISSUE

pc_mailid=REQUEST.mailid_no

	DO MDSUBP WITH  IIF(TYPE ("cTagn")="N", cTagn,VAL(cTagn)), MASTER.court ,"",  PC_ATYFIRM, PC_ATYSIGN, 'S',PC_C1CNTY, REQUEST.DESCRIPT,REQUEST.mailid_no, 1
c_SubList= MV

IF USED('Spec_ins')
	SELECT Spec_ins
	USE
ENDIF
SELECT REQUEST
USE

IF !EMPTY(c_Alias)
	SELECT (c_Alias)
ENDIF

CLEAR WINDOW
RETURN c_SubList

******************************************************************************
**************************************************************************************
PROCEDURE getmdtags
PARAMETERS  n_RT, n_date, n_tag1, n_tag2
PRIVATE lc_Alias	,  l_req AS Boolean, C_STR AS STRING
LOCAL oMed_md

_SCREEN.MOUSEPOINTER=11
lc_Alias = ALIAS()
l_req=.T.
C_STR =""
oMed_md = CREATEOBJECT("generic.medgeneric")
oMed_md.CLOSEALIAS('MDTags')




IF  EMPTY(ALLTRIM(n_RT ))&& all for a date

	C_STR =" exec dbo.GetMDClientMemoSet  '" + DTOC(n_date)+ "', 0,0,0"
ELSE

&& select a specific ones
	C_STR =" exec dbo.GetMDClientMemoSet  '" + DTOC(n_date)+ "','"   + n_RT+ "','" + n_tag1 + "','" +n_tag2 + "'"

ENDIF
l_req=oMed_md.sqlexecute(C_STR  ,"MDTags")

_SCREEN.MOUSEPOINTER=0
RELEASE oMed_md
RETURN l_req
***************************************************************
Function MdfileExl 
PARAMETERS lcDate
PRIVATE   fso AS Object
fso = CREATEOBJECT("Scripting.FileSystemObject")
LOCAL lcAlias as String, c_attachment as String
lcAlias= ALIAS()
_SCREEN.MOUSEPOINTER=11

lcTEMP=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","CTemp", "\")))
*lcDate=DTOC(DATE())
IF TYPE ("lcDate") ="D" 
	lcDate=DTOC(lcDate)
ENDIF

lCTEMPFILE=lcTEMP + "MdSet_" + STRTRAN(lcDate,"/","") + ".xls"
IF   fso.FileExists(ALLTRIM(lCTEMPFILE))
	RELEASE fso
	RETURN ""
ENDIF

IF USED('MdExcl')
SELECT MdExcl
USE
endif

IF USED('MdTags')
SELECT MdTags
SELECT  m.lrs_no, m.plaintiff,  m.tag, m.court, m.txn_date, m.descript, m.rq_at_code  FROM MdTags M INTO CURSOR MdExcl
SELECT MdExcl

GO top	

	IF NOT EOF()
		COPY TO (STRTRAN(lcTEMPFILE,"'","")) TYPE XL5
		omed.closealias("UserAcct")
		omed.sqlexecute("exec  DBO.[GetUserByLogin] '" +	ALLTRIM( pc_UserId) + "'", "UserAcct")
		SELECT UserAcct
		IF NOT EOF()

			c_SendTo=STRTRAN(ALLT( UserAcct.Email),";",",")
			c_CopyTo=""&&"rpsverify@hotmail.com"
			c_FromName=ALLTRIM(UserAcct.FULLNAME )
			c_FromEmail=STRTRAN(ALLT( UserAcct.Email),";",",")
			c_Subject=ALLTRIM("List of Client Memo Tags for MD-Baltimore Subpoena Set on " + ALLTRIM(lcDate)+ "."   )
			c_Message=ALLTRIM("Please check the RPS17 printer for the subpoenas ( attached excel file lists the rt/tags) for the Baltimore City court.")
			STORE "" TO c_attachment,c_bCCList
			c_attachment=lCTEMPFILE
			DO sendwwemail WITH c_FromEmail, c_FromName, c_SendTo,c_CopyTo, c_bCCList, c_Subject, c_Message, c_attachment
		ENDIF
	*	GFMESSAGE("The " + lcTEMPFILE + " excel file had been emailed to you.")
endif

ENDIF

RELEASE fso
IF NOT EMPTY(lcAlias)
	SELECT (lcAlias)
ENDIF

_SCREEN.MOUSEPOINTER= 0

RETURN lCTEMPFILE