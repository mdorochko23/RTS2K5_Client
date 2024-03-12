PARAMETERS uidtblrequests,ntag,cclcode, lsOffice

&& param: lsOffice optional, 'P' from soft-copy calls.  && 12/11/2023, zd #340399, JH

LOCAL lcSQLLine, lnCurArea, lnRecCnts,omed
lnCurArea=SELECT()
omedchk=CREATEOBJECT('medgeneric')
IF !EMPTY(convrtDate(pd_closing))
	DO gfReOpen WITH .F., "Adding a witness fee or other check."
ENDIF

WAIT WINDOW "Looking for previous uncleared witness fee checks. Please wait." NOWAIT NOCLEAR
*lcSQLLine="Select * from tblCheck with (nolock) where cl_code='"+cclcode+"' and tag='"+ALLTRIM(STR(ntag))+"' and active =1"
lcSQLLine="EXEC [dbo].[GetCheckbyClTag]  '"+cclcode+"','" + ALLTRIM(STR(ntag))+"'"
omedchk.sqlexecute(lcSQLLine,"GetChecks")
SELECT GetChecks
lnRecCnts=RECCOUNT()
USE

WAIT CLEAR

IF lnRecCnts>0

	lbOK = goApp.openform("Transactions.frmBrowseChecks", "M",.NULL.,cclcode,ntag,0)
	IF gfmessage("PLEASE NOTE: If the fee you are entering is a replacement check" + ;
			", do not proceed until contacting accounting for payment approval. Continue?",.T.) = .F.

*IF NOT gfmessage("Continue to enter witness fee?",.t.)
		SELECT (lnCurArea)
		RETURN
	ENDIF
ENDIF
&&11/06/09 - EF -do not allow issuing of a chcek to a test case
PRIVATE l_testcase AS Boolean
l_testcase=.F.
*lcSQLLine="Select testcase from tblmaster with (nolock) where cl_code='"+cclcode+"'  and active =1"
lcSQLLine= "select dbo.CaseTestStatus ('" + +cclcode+"')"
omedchk.sqlexecute(lcSQLLine,"IfTestCase")
SELECT 	IfTestCase
IF NOT EOF()
	l_testcase=NVL(IfTestCase.EXP,.F.)
ENDIF
**11/06/09 -end
***06/07/2011- use timesheet.frmWitFee2- witfee 3 project
IF NOT l_testcase OR goApp.userdepartment="IT"
	omedchk.closealias('RecStatus')
	omedchk.sqlexecute("select [dbo].[getRequestStatus] ('" + uidtblrequests + "') ", "RecStatus")
	&& 09/17/2019, ZD #143322, JH
	SELECT RecStatus
	&& 09/17/2019

	IF NVL(RecStatus.EXP," ")<>"T" &&08/26/2013- no checks for not issued tags
&&		lbOK = goApp.openform("timesheet.frmWitFee2", "M",.NULL.,.NULL.,uidtblrequests)
		lbOK = goApp.openform("timesheet.frmWitFee2", "M",.NULL.,.NULL.,uidtblrequests, .F., lsOffice)	&& 12/11/2023, zd #340399, JH
	ELSE
		gfmessage("Cannot issue a check to a Not-Issued tag.")
	ENDIF
ELSE
	gfmessage("Cannot issue a check to a test case.")
ENDIF
RELEASE omedchk

SELECT (lnCurArea)
