*PROCEDURE USDCPLNOT
** USDC Plaintiff Notice
** For USDC, title is "Notice"
PARAMETERS c_ThisAtty, c_clcode, n_tag
PRIVATE dbInit, dbCANotice, lcAttyAdd, c_atcsz, c_Scan

dbInit = SELECT()
IF NOT USED ('CANOTICE')
	l_CANot=GetCANot(c_clcode, n_tag)
	IF NOT l_CANot
		gfmessage('Cannot get the Notice file. Try again..or contact the IT dept')
		RETURN

	ENDIF
ENDIF

SELECT CANotice
LC_ORDER =ORDER()


DO PrintGroup WITH mv, "CAUSDCPLN"
DO PrintField WITH mv, "Title", IIF( hs_notice, "HAND SERVED", " ")
DO PrintField WITH mv, "ExtraCap", ""
DO PrintField WITH mv, "DocDate", DTOC( TXN_DATE)
DO PrintField WITH mv, "DepDate", DTOC( due_date)
DO PrintField WITH mv, "Loc", ALLTRIM( pc_offcode)
DO PrintField WITH mv, "When", IIF( pl_BBCase, "A", "N")
DO PrintField WITH mv, "RT", pc_lrsno
DO PrintField WITH mv, "CourtCounty", ALLTRIM( pc_c1Desc) && ALLTRIM( pc_c1Cnty)

lcOrdText = IIF( pc_LitCode = "A  ", "PLEASE FAX OR MAIL ALL ORDERS TO: " ;
	+ CHR(13) + "RECORDTRAK, INC. " + CHR(13) + ;
	"651 Allendale Rd." + CHR(13) + ;
	"P.O. Box 61591" + CHR(13) + "King of Prussia, PA 19406 " + ;
	CHR(13) + "Phone: (610) 354-8344  Fax: (610) 992-1416" , "")
DO PrintField WITH mv, "OrdDirect",  lcOrdText
DO PrintField WITH mv, "PlaintiffFirstName", pc_plnam


c_Atty=fixquote(pc_rqatcod)
pl_GetAt = .F.
DO gfatinfo WITH c_Atty, "M"

DO PrintGroup WITH mv, "ReqAtty"
IF pl_BBCase
**06/05/2015- added 3rd BB set
	LOCAL ln_bbset AS INTEGER,  c_name AS STRING
	c_name="LAURA PRZETAK, ESQ"
	IF TYPE ('oMed')<>'O'
		oMed= CREATEOBJECT("generic.medgeneric")
	ENDIF

	oMed.closealias("BBsign")
	c_sql="Select dbo.GetBBSignatureSet  ('" + DTOC(TXN_DATE) + "')"
	oMed.sqlexecute(c_sql,"BBsign")
	LOCAL ln_bbset AS INTEGER, c_rpsdoc AS STRING
	ln_bbset=3 && default is a new (latest set)
	c_rpsdoc="CA3BBDepSubpoena"
	IF USED("BBsign")
		ln_bbset =NVL(BBsign.EXP,3)
	ENDIF

	DO CASE
	CASE ln_bbset =1
		c_name="LEONARDO J. VACCHINA, ESQ"
	CASE  ln_bbset =2
		c_name ="PETER GILBERT, ESQ"
	OTHERWISE
		c_name ="LAURA PRZETAK, ESQ"
	ENDCASE
**06/05/2015- added 3rd BB set  -end




	DO PrintField WITH mv, "Ata1", "LAW OFFICES OF SPANOS | PRZETAK"
	DO PrintField WITH mv, "Name_inv",  		c_name + "    PHONE NO.: (510) 250-0200"
ELSE
	DO PrintField WITH mv, "Ata1", ALLT( pc_atyFirm)
	DO PrintField WITH mv, "Name_inv", ALLT( pc_Atysign) + ;
		"     PHONE NO.: " + pc_AtyPhn
ENDIF

lcAttyAdd = ""
lcAttyAdd= PrintAtyData ( c_ThisAtty)

DO PrintGroup WITH mv, "PltAtty"
DO PrintField WITH mv, "Ata1", lcAttyAdd

* Case Identification Data
DO PrintGroup WITH mv, "Case"
IF EMPTY( ALLT( pc_plcaptn)) AND EMPTY( ALLT( pc_dfcaptn))
	DO PrintField WITH mv, "Case", ALLT( pc_casenam)
ELSE
	DO PrintField WITH mv, "Case", ALLT( pc_plcaptn) + " VS. " + ;
		ALLT( pc_dfcaptn) + IIF( EMPTY( pc_casenam), "", ;
		CHR(13) + ALLT(pc_casenam))
ENDIF
DO PrintField WITH mv, "Docket", ALLT( pc_docket)
* Court Location
*DO PrintGroup WITH mv, "Court"



SELECT CANotice
USE
SELECT (dbInit)
RETURN
** ---------------------------------------------------------------------------------------------

FUNCTION GetCANot

PARAMETERS ccl, ntg
LOCAL l_RetVal AS Boolean, l_done AS Boolean, C_STR AS STRING, oMedN AS OBJECT
oMedN = CREATEOBJECT("generic.medgeneric")
STORE .F. TO l_RetVal, l_done



C_STR="SELECT * FROM tblPSnotice P WITH (NOLOCK)" ;
	+ " INNER JOIN TBLMASTER T WITH (NOLOCK) ON P.CL_CODE=T.CL_CODE " ;
	+ " where p.cl_code ='" + fixquote(ccl) + "' and p.tag ='" + STR(ntg) ;
	+ "' and T.active =1 "



l_done=oMedN.sqlexecute(C_STR, "CANotice")
IF l_done THEN
	l_RetVal=.T.
	=CURSORSETPROP("KeyFieldList", "ID_Tblpsnotice,Cl_code, TXN_DATE,tag,RQ_AT_CODE,USER_CODE,PRINTED ", "CANotice")
*!*		INDEX ON ALLTRIM(USER_CODE)+ALLTRIM(CL_CODE) FOR .NOT.PRINTED TAG TOPRINT ADDITIVE
*!*		INDEX ON ALLTRIM(USER_CODE)+ALLTRIM(CL_CODE) TAG REPRINT ADDITIVE
*!*		INDEX ON DTOC( Txn_Date) + Cl_Code 	UNIQUE FOR NOT Printed TAG ca_cases
*!*		INDEX ON DTOC( Txn_Date) + Cl_Code 	UNIQUE FOR NOT Printed AND hs_notice TAG ca_hscases
*!*		INDEX ON DTOC(TXN_DATE)+CL_CODE FOR .NOT.PRINTED TAG CA_COUNT ADDITIVE
*!*		INDEX ON DTOC(TXN_DATE)+CL_CODE FOR .NOT.PRINTED.AND.RIGHT(ALLTRIM(CL_CODE),1)=="C".AND.HS_NOTICE TAG CA_HSCOUNT ADDITIVE
	INDEX ON CL_CODE+"*"+STR(TAG) TAG CLTAG ADDITIVE


ENDIF
RETURN l_RetVal
RELEASE oMedN

