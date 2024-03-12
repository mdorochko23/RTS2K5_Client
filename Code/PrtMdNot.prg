****************************************************************
FUNCTION PrtMdNot
****************************************************************
PARAMETERS d_send,  c_clcode, c_mailid, c_tag, lc_dname
LOCAL c_Print AS strring , d_txn19 AS DATE, c_send45 AS STRING, c_email1 AS STRING
STORE "" TO c_Print, c_email1

LOCAL  omed_i AS OBJECT
omed_i= CREATEOBJECT("generic.medgeneric")
IF NOT USED ('MASTER')
	DO GetCase WITH  c_clcode IN courtset2
ENDIF
c_RqAtty=fixquote(pc_rqatcod)
pl_GetAt = .F.
DO gfatinfo WITH c_RqAtty, "M"

omed_i.closealias('RqEmail1')
omed_i.sqlexecute("select dbo.GetNoticeAttyEmail ('" + c_RqAtty + "',1) " , "RqEmail1")
IF USED('RqEmail1') AND NOT EOF()
	c_email1=NVL(RqEmail1.EXP,'')
ENDIF

lc_RqAtType = IIF( pl_plisrq, "Plaintiff", "Defendant")

**get the latest deponent data
DO getdeponent WITH c_mailid,'Z' IN qcissue&& c_hdept
* dbo.GetDeptCode

SELECT pc_depofile
IF EOF()
	RETURN ""
ENDIF

SET PROCEDURE TO TA_LIB ADDITIVE
DO printgroup WITH c_Print, "MDDefNot2" && 6/9/15- added  more atty's data



DO printgroup WITH c_Print, "Case"
DO PrintField WITH  c_Print, "LRS", ""
DO PrintField WITH  c_Print, "Name", ALLTRIM(PC_PLCAPTN)
DO PrintField WITH  c_Print, "Plaintiff", ALLTRIM(pc_plnam)
DO PrintField WITH  c_Print, "Defendant",ALLTRIM( pc_dfcaptn)
DO PrintField WITH c_Print, "AttyName",ALLTRIM(pc_AtySign) + CHR(13) + ALLTRIM(NVL(pc_AtyFirm,''))
DO PrintField WITH c_Print, "AttyType", IIF( lc_RqAtType = "Defendant", "D", "P")
DO PrintField WITH c_Print, "Court",""
DO PrintField WITH c_Print, "Term", ""
DO PrintField WITH c_Print, "Docket", ALLTRIM(NVL(PC_DOCKET,""))


DO printgroup WITH c_Print, "Deponent"
SELECT pc_depofile
pc_mailid = c_mailid
c_addition= getdescript(NVL(pc_depofile.CODE,'Z'))
c_dep=DepToPrint (ALLTRIM(NVL(pc_depofile.NAME,lc_dname)))
IF pc_deptype='D'
	c_name=" the office of "  + c_dep
ELSE
	c_name=c_dep  + IIF(pc_deptype = "H"  ,"",c_addition)
ENDIF


DO PrintField WITH c_Print, "Name", c_dep  + IIF(pc_deptype = "H"  ,"",c_addition)
DO PrintField WITH c_Print, "Addr", ;
	IIF(EMPTY(ALLTRIM(pc_depofile.add2)), ALLTRIM(pc_depofile.add1), ALLTRIM(pc_depofile.add1) + " " +ALLTRIM(pc_depofile.add2))
DO PrintField WITH c_Print, "City", ALLTRIM(pc_depofile.city)
DO PrintField WITH c_Print, "State", ALLTRIM(pc_depofile.state)
DO PrintField WITH c_Print, "Zip", IIF(ALLTRIM(pc_depofile.zip)='00000','', ALLTRIM(pc_depofile.zip))
DO PrintField WITH c_Print, "Extra", ""

DO printgroup WITH c_Print, "Plaintiff"
DO PrintField WITH c_Print, "FirstName", pc_plnam
DO PrintField WITH c_Print, "MidInitial", ""
DO PrintField WITH c_Print, "LastName", ""
DO PrintField WITH c_Print, "Addr1", pc_pladdr1
DO PrintField WITH c_Print, "Addr2", pc_pladdr2
IF TYPE('pd_pldob')<>"C"
	pd_pldob=DTOC(pd_pldob)
ENDIF
IF TYPE('pd_pldod')<>"C"
	pd_pldod=DTOC(pd_pldod)
ENDIF

DO PrintField WITH c_Print, "BirthDate", LEFT(pd_pldob,10)
DO PrintField WITH c_Print, "SSN", ALLT( pc_plssn)
DO PrintField WITH c_Print, "DeathDate",  LEFT(pd_pldod,10)
DO PrintField WITH c_Print, "Extra", ""

**USE TXN 19'S DATE WHEN FIND
d_txn19=Get19Date ( c_clcode,c_tag)
IF EMPTY(NVL(d_txn19,"") )
	c_send45=DTOC( gfChkDat( d_send+45,.F.,.F.))
ELSE
	c_send45=DTOC( gfChkDat( d_txn19+45,.F.,.F.))
ENDIF

DO PrintField WITH c_Print, "Notice40", c_send45
DO PrintField WITH c_Print, "RqAtty",  ALLTRIM(pc_AtySign)
DO PrintField WITH c_Print, "AtPhone", ALLTRIM(NVL(pc_AtyPhn,''))
DO PrintField WITH c_Print, "AtEmail", ALLTRIM(c_email1)
lcFaxNo=ALLTRIM(pc_AtyFax)
DO printgroup WITH c_Print, "Atty"
DO PrintField WITH c_Print, "Name_inv", ALLTRIM(pc_AtySign) + CHR(13) + ALLTRIM(NVL(pc_AtyFirm,''))
DO PrintField WITH c_Print, "Ata1",  ALLTRIM(PC_ATY1AD)
DO PrintField WITH c_Print, "Ata2",ALLTRIM(PC_ATY2AD)
DO PrintField WITH c_Print, "Ata3",""
DO PrintField WITH c_Print, "Atacsz",ALLTRIM(PC_ATYCSZ)
DO PrintField WITH c_Print, "FaxNo", IIF( LEN( lcFaxNo) < 10, "", "Fax #: " + lcFaxNo)
RELEASE omed_i
RETURN c_Print
