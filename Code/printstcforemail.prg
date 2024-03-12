* --------------------------------------------------------------------------
* Store Status Letter to Counsel for future review/send through email
* --------------------------------------------------------------------------
PARAMETER lcAtCode, lcClCode, lnTag, llAll, llRqAtty, llPlAtty
LOCAL lnCurArea
lnCurArea=SELECT()

SET PROCEDURE TO GLOBAL ADDITIVE
IF opendata()<>.T.
	RETURN .F.
ENDIF

DO EmailLocationHeader
DO emailAttyADdress
IF pl_KoPVer
	DO EmailGroupInfo
	IF NOT EMPTY(viewBill.file_no)
		DO emailFileNo
	ENDIF
ENDIF
DO EmailReqDate
DO EmailCaseName
DO EmailLrsNo
DO EmailPltName
DO EmailInfoItem
DO EmailEndText
DO EmailAcctMgrInfo
DO emailCCText
DO emailArea

SELECT tempPrintSTS
GO TOP
IF NVL(viewCode30.item_1,.F.)=.F.
	REPORT FORM "PrintSTCLetter" TO PRINTER NOCONSOLE
ELSE
	REPORT FORM "PrintSTCLetter2" TO PRINTER NOCONSOLE
ENDIF


USE IN viewCode30
USE IN MASTER
USE IN viewAtty
USE IN REQUEST
USE IN viewBill
USE IN tempPrintSTS

RETURN





*-----------------------------------------------------------------------------
FUNCTION opendata
LOCAL lcSQLLine
LOCAL oGen AS medGeneric OF generic
oGen=CREATEOBJECT("medGeneric")

SELECT 0
** 04/15/2021 MPS SD#232294 Expanded Area from C(14) to C(30)
**CREATE CURSOR tempPrintSTS(;
**loclH1 c(254), loclH2 c(254), loclH3 c(254), loclH4 c(254), loclH5 c(254),;
**loclHBox c(254), loclHPhone c(20),loclHAmFax c(20),;
**Name_inv c(254), Ata1 c(254), Ata2 c(254), Ata3 c(254), AtaCSZ c(254), faxNo c(20), ;
**req_date c(10), lrsNo c(10), tagNo c(3), pltName c(254), CaseName c(254),;
**CaseArea c(254), FileNo c(254),GroupName c(254),gCaseName c(254),CaseNum c(254),;
**depName c(254), infoItem m, ENDTEXT m, contactNM c(254), contactPh c(20), ccTxt c(254), area c(14))

CREATE CURSOR tempPrintSTS(;
loclH1 c(254), loclH2 c(254), loclH3 c(254), loclH4 c(254), loclH5 c(254),;
loclHBox c(254), loclHPhone c(20),loclHAmFax c(20),;
Name_inv c(254), Ata1 c(254), Ata2 c(254), Ata3 c(254), AtaCSZ c(254), faxNo c(20), ;
req_date c(10), lrsNo c(10), tagNo c(3), pltName c(254), CaseName c(254),;
CaseArea c(254), FileNo c(254),GroupName c(254),gCaseName c(254),CaseNum c(254),;
depName c(254), infoItem m, ENDTEXT m, contactNM c(254), contactPh c(20), ccTxt c(254), area c(30))

SELECT tempPrintSTS
APPEND BLANK

SELECT 0
lcSQLLine="exec dbo.getLatestCode30 '"+ALLTRIM(fixquote(lcClCode))+"', "+ALLTRIM(STR(lntag))
llRetval=oGen.sqlexecute(lcSQLline,"viewCode30")
IF RECCOUNT("viewCode30")=0
	gfmessage("Can't open tblCode30")
	RETURN .F.
ENDIF

SELECT 0
lcSQLLine="select * from tblMaster where cl_code='"+ALLTRIM(fixquote(lcClCode))+"' and active=1"
llRetval=oGen.sqlexecute(lcSQLline,"Master")
IF RECCOUNT("Master")=0
	gfmessage("Can't open tblMaster")
	RETURN .F.
ENDIF
pl_GotCase=.F.
DO gfGetCas WITH .F.

SELECT 0
lcSQLLine="exec dbo.GetAttyAddressByAtCodeAndAddType '" + ALLTRIM(lcAtCode) + "','M'"
llRetval=oGen.sqlexecute(lcSQLline,"viewAtty")
IF RECCOUNT("viewAtty")=0
	gfmessage("Can't open tblAttorney")
	RETURN .F.
ENDIF

SELECT 0
lcSQLLine="select * from tblRequest with (nolock) where cl_code='"+ALLTRIM(pc_clcode)+"' and tag='"+;
ALLTRIM(STR(lnTag))+"' and active=1"
oGen.sqlexecute(lcSQLLine,"request")
IF RECCOUNT("request")=0
	gfmessage("Can't open tblRequst")
	RETURN .F.
ENDIF

SELECT 0
lcSQLLine="select * from tblBill where cl_code='"+ALLTRIM(fixquote(lcClCode))+"' and at_code='"+ALLTRIM(lcAtCode)+"' and active=1"
oGen.sqlexecute(lcSQLline,"viewBill")
IF RECCOUNT("viewBill")=0
	gfmessage("Can't open tblBill")
	RETURN .F.
ENDIF
SELECT 0
lcOffCode=IIF( INLIST( pc_offcode, "G"), "P", pc_offcode)
lcSQLLine="select * from tblOfficeLocation where code='"+ALLTRIM(lcOffCode)+"' and active=1"
oGen.sqlexecute(lcSQLLine, "viewOfficeLocation")
IF RECCOUNT("viewOfficeLocation")=0
	gfmessage("Can't open tblOfficeLocation")
	RETURN .F.
ENDIF
RELEASE oGen
RETURN .T.
*-----------------------------------------------------------------------------
PROCEDURE EmailLocationHeader
LOCAL lnCurArea, lcOffCode, c_FaxCode, l_AMFaxCode
lnCurArea=SELECT()
l_AMFaxCode=.f.
**4/14/08 -added AM Fax Number form civil lit cases only -start
c_FaxCode="P"
IF ALLTRIM(pc_litcode) ="C"  AND pl_KoPVer
	l_AMFaxCode= GetAMFaxCode (pc_amgr_id)
	IF l_AMFaxCode
		c_FaxCode=IIF(ISNULL(AMFax.RpsAMFaxCode), 'P', AMFax.RpsAMFaxCode)
	ENDIF
ENDIF

**4/14/08 -added AM Fax Number form civil lit cases only-end

SELECT tempPrintSTS
REPLACE loclH1 WITH NVL(viewOfficeLocation.loclH1,""), loclH2 WITH NVL(viewOfficeLocation.loclH2,""), ;
loclH3 WITH NVL(viewOfficeLocation.loclH3,""), loclH4 WITH NVL(viewOfficeLocation.loclH4,""), ;
loclH5 WITH NVL(viewOfficeLocation.loclH5,""), loclHBox WITH NVL(viewOfficeLocation.loclHBox,""), ;
loclHPhone WITH NVL(viewOfficeLocation.loclHPhone,""), loclHAmFax WITH NVL(IIF(c_FaxCode="P",  viewOfficeLocation.loclHAmFax,viewOfficeLocation.loclHCivAmFax ) ,"")
SELECT (lnCurArea)
*------------------------------------------------------------------------------
PROCEDURE emailAttyADdress
LOCAL lnCurArea, lcSAttn
lnCurArea=SELECT()
DIMENSION laAddr[5]
STORE SPACE(1) TO laAddr
lcSAttn=""
SELECT viewAtty
lnAddr = 0
IF NOT EMPTY(NewLast+newfirst)
	lnAddr = lnAddr + 1
	laAddr(lnAddr) = ALLTRIM(ALLTRIM(newfirst) + " " + ;
	IIF(EMPTY(NewInit), "", NewInit + ".")) + " " + ALLTRIM(NewLast)
ENDIF
IF NOT EMPTY(Printable_firm)
	lnAddr = lnAddr + 1
	laAddr[lnAddr] = Printable_firm
ENDIF
IF NOT EMPTY(Add1)
	lnAddr = lnAddr + 1
	laAddr[lnAddr] = Add1
ENDIF
IF NOT EMPTY(Add2)
	lnAddr = lnAddr + 1
	laAddr[lnAddr] = Add2
ENDIF
IF NOT EMPTY(City)
	lnAddr = lnAddr + 1
	laAddr[lnAddr] = ALLTRIM(City) + " " + State + "  " + Zip
ENDIF

IF EMPTY(Fax_no)
	lcFaxNo = "-"
ELSE
	lcFaxNo = gfPhoneToChar(Fax_no) &&(AtFax)
ENDIF
IF pl_CAVer
	SELECT viewCode30
	lcSAttn = NVL(viewCode30.attention,"")
	lcSEmail= NVL(viewCode30.email,"")
	oFrm=CREATEOBJECT("casedeponent.frmGetSTCAttention",lcSAttn,lcSEmail,lcAtCode)
	oFrm.SHOW
	lcSAttn=ALLTRIM(ofrm.txtAttention.VALUE)
	lcSEmail=ALLTRIM(ofrm.cboEmail.VALUE)
	RELEASE oFrm
	LOCAL oGen AS medGeneric OF generic
	oGen=CREATEOBJECT("medGeneric")
	lcSQLLine="update tblCode30 set attention='"+ALLTRIM(lcSAttn)+"', email='"+ALLTRIM(UPPER(lcSEmail))+"'"+;
	" where id_tblCode30='"+viewCode30.id_tblCode30+"'"
	oGen.sqlexecute(lcSQLline)
	RELEASE oGen
ELSE
	lcSAttn=laAddr[1]
ENDIF


SELECT tempPrintSTS
REPLACE name_inv WITH NVL(lcSAttn,""), ata1 WITH NVL(laAddr[2],""), ata2 WITH NVL(laAddr[3],""), ata3 WITH NVL(laAddr[4],""), AtaCSZ WITH NVL(laAddr[5],""), ;
faxNo WITH IIF( LEN( NVL(lcFaxNo,"")) < 10, "", "Fax #: " + lcFaxNo)
SELECT (lnCurArea)
*------------------------------------------------------------------------------
PROCEDURE EmailGroupInfo
LOCAL lnCurArea, lnCurDS
lnCurArea=SELECT()
SELECT tempPrintSTS
REPLACE groupName WITH IIF( pl_noGroup, "", "Group: " + PROPER(NVL(pc_grpname,"")))
REPLACE GCaseName WITH IIF( pl_noGroup, "", "Main Case Name: " + PROPER(NVL(pc_casname,"")))
REPLACE CaseNum WITH IIF( pl_noGroup, "", "Case Number: " + PROPER(NVL(pc_casenum,"")))
SELECT (lnCurArea)
*-------------------------------------------------------------------------------

PROCEDURE EmailFileNo
LOCAL lnCurArea
lnCurArea=SELECT()
SELECT tempPrintSTS
IF !EMPTY(ALLTRIM(NVL(viewBill.file_no,"")))
	REPLACE FileNo WITH "Your File #:" + ALLTRIM(viewBill.file_no)
ENDIF
SELECT (lnCurArea)
*-------------------------------------------------------------------------------------
PROCEDURE EmailReqDate
LOCAL lnCurArea
lnCurArea=SELECT()
SELECT tempPrintSTS
REPLACE req_Date WITH DTOC(NVL(viewCode30.txn_date,{}))
SELECT (lnCurArea)
*-------------------------------------------------------------------------------------
PROCEDURE EmailCaseName
LOCAL lnCurArea
lnCurArea=SELECT()
SELECT tempPrintSTS
REPLACE CaseName WITH ALLTRIM(NVL(pc_plnam,""))
SELECT (lnCurArea)
*-------------------------------------------------------------------------------------
PROCEDURE EmailLrsNo
LOCAL lnCurArea
lnCurArea=SELECT()
IF NOT pl_BBCase
	STORE "" TO pc_BBRound, pc_BBWebNo, pc_BBLocNo, pc_BBNuRCA
	SELECT tempPrintSTS
	REPLACE lrsNo WITH ALLTRIM(NVL(pc_lrsno,"")), tagNo WITH NVL(ALLTRIM(STR(viewCode30.TAG)),0), depName WITH NVL(viewCode30.DESCRIPT,"")
	SELECT (lnCurArea)
	RETURN
ENDIF

pc_BBRound = NVL(REQUEST.ASB_Round,"")
pc_BBWebNo = NVL(REQUEST.Web_Order,"")
pc_BBLocNo = NVL(REQUEST.BB_Locator,"")
pc_BBNuRCA = ALLTRIM(NVL(pc_plbbASB,"")) + "." + ALLTRIM(NVL(pc_BBRound,""))

SELECT tempPrintSTS
REPLACE lrsNo WITH " ASB #:" + pc_BBNuRCA, tagNo WITH NVL(ALLTRIM(STR(viewCode30.TAG)),0), depName WITH NVL(viewCode30.DESCRIPT,"")
SELECT (lnCurArea)
RETURN
*------------------------------------------------------------------------------------
PROCEDURE EmailPltName
LOCAL lnCurArea
lnCurArea=SELECT()
lcTmp = ALLTRIM(NVL(pc_plcaptn,""))
IF NOT EMPTY( pc_dfcaptn)
	lcTmp = lcTmp + "   VS   " + ALLTRIM(NVL(pc_dfcaptn,""))
ENDIF
SELECT tempPrintSTS
REPLACE PltName WITH lcTmp
SELECT (lnCurArea)
RETURN
*-----------------------------------------------------------------------------------
PROCEDURE EmailInfoItem
LOCAL lnCurArea
lnCurArea=SELECT()
SELECT viewCode30
lcTmp = ""
IF viewCode30.Item_1
	lcTmp = lcTmp + "The above-named deponent requires a fee approval "
	lcTmp = lcTmp + "in the amount of $" + TRANSFORM(NVL(fee_amt,0), "9999.99")
	lcTmp = lcTmp + " for " + LOWER(ALLTRIM(page_cnt))
	lcTmp = lcTmp + pc_eol + pc_eol
ENDIF
IF viewCode30.item_2
	lcTmp = lcTmp + "The above-named deponent requires the dates of service "
	lcTmp = lcTmp + LOWER(ALLTRIM(TYPE))
	lcTmp = lcTmp + " before they can research for the requested material."
	lcTmp = lcTmp + pc_eol + pc_eol
ENDIF
** DMA  05/05/03  Add HIPAA-compliant Authorization option to Code30 file
IF viewCode30.item_3 OR viewCode30.item_4 OR viewCode30.HIPAA_Auth OR viewCode30.nrsfrec
	DO CASE
		CASE viewCode30.item_3
			lcTmp = lcTmp + "An Authorization:" + pc_eol
		CASE viewCode30.item_4
			lcTmp = lcTmp + "A Subpoena:" + pc_eol
		CASE viewCode30.HIPAA_Auth
			lcTmp = lcTmp + "A HIPAA-Compliant Authorization:" + pc_eol
	ENDCASE
	c_info = ""

** Make sure only one Eol character per line for proper spacing.
	IF NOT EMPTY(NVL(viewCode30.comm1,""))
		c_info = STRTRAN(STRTRAN(ALLTRIM(viewCode30.comm1), CHR(13)), CHR(10)) + pc_eol
	ENDIF
	IF NOT EMPTY(NVL(viewCode30.comm2,""))
		c_info = c_info + STRTRAN(STRTRAN(ALLTRIM(viewCode30.comm2), CHR(13)), CHR(10)) + pc_eol
	ENDIF
	IF NOT EMPTY(NVL(viewCode30.comm3,""))
		c_info = c_info + STRTRAN(STRTRAN(ALLTRIM(viewCode30.comm3), CHR(13)), CHR(10)) + pc_eol
	ENDIF
	IF NOT EMPTY(NVL(viewCode30.comm4,""))
		c_info = c_info + STRTRAN(STRTRAN(ALLTRIM(viewCode30.comm4), CHR(13)), CHR(10)) + pc_eol
	ENDIF
	IF NOT EMPTY(NVL(viewCode30.comm5,""))
		c_info = c_info + STRTRAN(STRTRAN(ALLTRIM(viewCode30.comm5), CHR(13)), CHR(10)) + pc_eol
	ENDIF
	IF NOT EMPTY(NVL(viewCode30.comm6,""))
		c_info = c_info + STRTRAN(STRTRAN(ALLTRIM(viewCode30.comm6), CHR(13)), CHR(10)) + pc_eol
	ENDIF
	IF NOT EMPTY(NVL(viewCode30.comm7,""))
		c_info = c_info + STRTRAN(STRTRAN(ALLTRIM(viewCode30.comm7), CHR(13)), CHR(10)) + pc_eol
	ENDIF
	c_info = ALLT(c_info)
	lcTmp = lcTmp + c_info + pc_eol + pc_eol
ENDIF
IF viewCode30.item_5
	SET MEMOWIDTH TO 70
	FOR x = 1 TO MEMLINES(NVL(viewCode30.OTHER,""))
		lcTmp = lcTmp + MLINE(NVL(viewCode30.OTHER,""), x) + pc_eol
	NEXT x
ENDIF
IF EMPTY(lcTmp)
	lcTmp = " "
ENDIF

SELECT tempPrintSTS
REPLACE InfoItem WITH lcTmp
SELECT (lnCurArea)
RETURN
*---------------------------------------------------------------------------------------
PROCEDURE EmailEndText
LOCAL lnCurArea
lnCurArea=SELECT()
lcTmp = "If RecordTrak does not receive a response to our requests "
lcTmp = lcTmp + "within one month from date above, we will "
lcTmp = lcTmp + "terminate all efforts in the procurement of this "
lcTmp = lcTmp + "record for the above-named deponent."

SELECT tempPrintSTS
REPLACE ENDTEXT WITH lcTmp
SELECT (lnCurArea)
RETURN
*--------------------------------------------------------------------------------------
PROCEDURE EmailAcctMgrInfo
LOCAL lnCurArea
lnCurArea=SELECT()
lcPhone = pc_amgr_ph
IF EMPTY(NVL(lcPhone,""))
	lcPhone = "1-800-" + ;
	IIF( pc_litcode == "C  ", "686-0658", "220-1291")
ENDIF

SELECT tempPrintSTS
REPLACE contactNM WITH IIF( NOT EMPTY(NVL(pc_amgr_nm,"")), pc_amgr_nm, "RecordTrak Representative"), contactPh WITH lcPhone
SELECT (lnCurArea)
RETURN
*-----------------------------------------------------------------------------------------
PROCEDURE emailCCText
LOCAL lnCurArea, lc_CCList, lcUser
lnCurArea=SELECT()
lc_CCList=""
IF pc_litcode="C  "
	IF llAll AND ALLTRIM(UPPER(pc_rqatcod))=ALLTRIM(UPPER(lcAtCode))
		lc_CCList="A COPY OF THIS DOCUMENT HAS BEEN PROVIDED TO ALL COUNSEL IN THIS CASE"
	ELSE
		IF (llRqAtty AND llPlAtty) AND ALLTRIM(UPPER(pc_rqatcod))=ALLTRIM(UPPER(lcAtCode))
			lc_CCList= "A COPY OF THIS DOCUMENT HAS BEEN PROVIDED TO PLAINTIFF'S COUNSEL IN THIS CASE"  + CHR(13)
		ENDIF
	ENDIF
ENDIF
lcUser= IIF(!EMPTY(ALLTRIM(goApp.currentuser.orec.Dept)), ;
ALLTRIM(goApp.currentuser.orec.Dept) + "/" +  LEFT( goApp.currentuser.orec.Name_First, 1) + ;
LEFT( goApp.currentuser.orec.Name_Last, 1), "UNKNOWN")

SELECT tempPrintSTS
REPLACE CcTxt WITH IIF( pc_litcode == "I  ", "cc: Defense Counsel"+CHR(13)+lcUser, lcUser) + CHR(13)+ ;
IIF( !EMPTY(lc_CCList), CHR(13)+lc_CCList, "")

SELECT (lnCurArea)
RETURN
*------------------------------------------------------------------------------------------------
PROCEDURE emailArea
LOCAL lnCurArea, lcArea
lnCurArea=SELECT()
IF pl_KoPVer
	lcArea = IIF( INLIST( pc_litcode, "D  ", "E  ", "G  "), "Area: " + ALLTRIM(NVL(pc_area,"")), "  ")
	SELECT tempPrintSTS
	REPLACE area WITH lcArea
ENDIF
SELECT (lnCurArea)
RETURN



