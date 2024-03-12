FUNCTION PrtPrere
**EF -12/01/05 - Added to the FVP project
**EF -02/17/04 - prints  "Certificate Prerequisite .." page as a part of
**             - a subpoena or court filing sets

** Called by CourtSet2, Subp_PA ********************************************
************************************************************************
PARAMETERS iCount, dDate
**iCount - a designator for Original/Copy page
Private lCopy, c_Job, c_attysign
LOCAL oGenMed2 as medGeneric OF generic
oGenMed2=CREATEOBJECT("medGeneric")
SET PROCEDURE TO TA_LIB additive
IF TYPE('dDate')='L'
	dDate=DATE()
ENDIF

c_Job = ""
c_attysign=""
lCopy = (iCount = 2)
DO PrintGroup WITH c_Job, "RepCourtCertif"
DO PrintGroup WITH c_Job, "Case"
DO PrintField WITH c_Job, "LRS", IIF(lCopy, "**C O P Y**", "")
DO PrintField WITH c_Job, "Plaintiff", ALLT( pc_plcaptn)
DO PrintField WITH c_Job, "Defendant", ALLT( pc_dfcaptn)

l_Ok=oGenMed2.sqlexecute("SELECT dbo.AttySignature('" + fixquote(pc_rqatcod) + "')", "AttySign")

IF NOT l_Ok
	c_attysign=pc_AtySign
ELSE
	c_attysign=FIXQUOTE(AttySign.exp)
endif

DO PrintField WITH c_Job, "AttyName", c_attysign
DO PrintField WITH c_Job, "Docket", pc_docket
DO PrintField WITH c_Job, "Court", ALLT( pc_c1Desc)
IF TYPE('pd_term')<>"C"
	pd_term= DTOC(pd_term)
ENDIF
LOCAL c_term as String
	c_term=""
	&&08/29/13 - use month year per Liz 
	c_term=termdate(pd_term)	
DO PrintField WITH c_Job, "Term",c_term
*DO PrintField WITH c_Job, "Term", LEFT(pd_term,10)  

DO PrintField WITH c_Job, "AttyType", IIF( pl_plisrq, "P", "D")
**07/11/2013 - use new release date : HoldPrint project
**10/18/13 - added pl_UpdHoldReqst
**12/23/13 - reissie prints an original tags' dates

	LOCAL d_send as Date	
	oGenMed2.closealias("SendDocs")
	IF pl_Reissue
	  ntg=pn_SuppTo
	 ELSE
	  ntg=pn_tag
	ENDIF
	
		C_STR="exec  [dbo].[getSendDate] '" + fixquote(pc_clcode) + "','" + STR(ntg) + "'"
		L_OK=oGenMed2.SQLEXECUTE (C_STR,"SendDocs")

		IF NOT L_OK
			d_send=pd_RpsPrint
		ELSE
			d_send= SendDocs.send_date
		ENDIF




DO PrintField WITH c_Job, "BirthDate", IIF ( pl_1st_req OR pl_UpdHoldReqst,DTOC(pd_RpsPrint),DTOC( d_send))
DO PrintField WITH c_Job, "Id", pc_ScanSg
RELEASE oGenMed2
RETURN c_Job
