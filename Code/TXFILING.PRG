
*PROCEDURE TXFiling
**07/10/2017 : a set includes
*Notice
*Subpoena
*Exhibit A as 8/8/2017
*Redacted DWQ
*Cert of Serv
PARAMETERS n_Tag,  c_Deponent, c_MailID, d_Notice
* n_Tag       Tag number of item for which subpoena is to be generated
* c_Deponent  Deponent name
* c_MailID    Deponent Mail ID
* d_Notice    Date on which subpoena/notice is being produced

PRIVATE dbInit AS STRING, c_cl  AS STRING, oMEDf AS OBJECT, c_info as String
dbInit = SELECT()
WAIT WINDOW "Printing TX Court Letter(s)." NOWAIT NOCLEAR
SELECT 0
_SCREEN.MOUSEPOINTER=11
IF TYPE ('D_TODAY')<>"D"
	d_today = DATE()
ENDIF
STORE "" TO mv, c_info
SET PROCEDURE TO TA_LIB ADDITIVE
c_cl =""
oMEDf=CREATEOBJECT("medgeneric")

c_cl =fixquote(pc_clcode)

oMEDf.sqlexecute(" exec dbo.GetRequestRecordbyClcodeTag '" + c_cl + "','" + STR(n_Tag) + "' ", "Record")

IF USED("Spec_ins")
	SELECT Spec_ins
	USE
ENDIF
oMEDf.sqlexecute("Exec [dbo].[GetTheLatestBlurb] '" +c_cl  + "',' " + STR(N_TAG) + "'", "Spec_ins")


IF   UPPER( LEFT( c_MailID, 1))="H"
	c_pickdept= NVL(Spec_ins.Dept,"Z")
ELSE
	c_pickdept="Z"
ENDIF




l_mail=oMEDf.sqlexecute("exec dbo.GetDepInfoByMailIdDept '" + ALLTRIM(c_MailID) + ;
	"','" + ALLTRIM(c_pickdept) + "' ", "pc_DepoFile")
=CURSORSETPROP("KeyFieldList", "Code, id_tbldeponents", "pc_DepoFile")
_SCREEN.MOUSEPOINTER=0


LOCAL l_COURT AS STRING, l_COURT2 AS STRING, l_AtName AS STRING, l_nameinv AS STRING, l_reqType AS STRING, l_county AS STRING, ;
	l_dep AS STRING, l_mid AS STRING, c_quest  AS STRING
STORE "" TO l_COURT , l_COURT2, l_AtName, l_nameinv , l_reqType , l_county,l_dep ,l_mid, c_quest  


TXNOTFED=.F.
IF NOT EMPTY( pc_rqatcod)
	pl_GetAt = .F.
	*DO gfatinfo WITH fixquote(pc_rqatcod), "M"
	DO AtyMixed WITH fixquote(pc_rqatcod), "M", .T.
	c_AtName = pc_AtyName
	c_nameinv = pc_AtySign
	c_ratadd1 = pc_Aty1Ad
	c_ratadd2 = pc_Aty2Ad
	c_ratcsz = pc_Atycsz
	c_phone = pc_AtyPhn
	c_Firm = pc_Atyfirm
	c_AtyFax=pc_AtyFax
	c_EmailAdd= TxRqemail(0,pc_rqatcod)
ENDIF


l_COURT=pc_Court1
l_COURT2=pc_Court2
l_AtName=pc_AtyName
l_nameinv=pc_AtyFirm
l_reqType= ALLTRIM(NVL(RECORD.TYPE,'A'))
l_county=pc_c1Cnty
l_dep=c_Deponent
l_mid=c_MailID
pc_tagdist=ALLTRIM(NVL(RECORD.District,""))
pn_tag=n_Tag
ldDueDate= GetReqDueDate(c_cl , n_Tag, IIF(TYPE("dep_date")="T", TTOD(dep_date),dep_date))
pd_Depsitn=ldDueDate
pd_dateCourtset=DATE()
c_quest= GetTxDWQ(c_cl , n_tag)
c_info = GFADDCR( SPEC_INS.SPEC_INST)
*ALLTRIM(viewTXNoticeTex.text1)
*-- 06/27/2022 MD  #277503
DO Txnot1 WITH n_Tag, ALLTRIM(l_dep), ALLTRIM(l_mid),.T.

*10/12/2021 WY #251233 (when printing subpoena from filing redact(hide), ssn and dob values)
*DO subprint WITH n_Tag, l_COURT, l_COURT2,  l_AtName, l_nameinv,  l_reqType,l_county, l_dep, l_mid
DO subprint WITH n_Tag, l_COURT, l_COURT2,  l_AtName, l_nameinv,  l_reqType,l_county, l_dep, l_mid, .T.

**09/07/17- upper names as 9.7.17
DO SUBPATTCH WITH MV, c_info, n_Tag,UPPER( ALLTRIM(l_dep))
DO Txquest WITH n_Tag, ALLTRIM(l_dep), ALLTRIM(l_mid), c_quest,.T.
DO TxCert WITH n_Tag, ALLTRIM(l_dep), ALLTRIM(l_mid)
pd_dateCourtset=NULL
RELEASE pd_dateCourtset 

mclass='TXFiling'
DO prtenqa WITH mv, mclass, "1", ""

*oMEDf.closealias("Record")
*oMEDf.closealias("Spec_Ins")
RELEASE oMEDf
SELECT ( dbInit)
WAIT CLEAR
RETURN
