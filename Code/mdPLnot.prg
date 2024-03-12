
************************************************************************
Function  mdPlNot
** Prints a Notice in Complaince (plaintiff) page 5 in a set + PAGES 4-306/4-307
**04/6/15 
************************************************************************
PARAMETERS d_send, lccode, lcRole
PRIVATE c_Print, c_email1 , lcFaxNo
STORE "" TO c_Print, c_email1, lcFaxNo

LOCAL  omed_i AS OBJECT
omed_i= CREATEOBJECT("generic.medgeneric")

IF TYPE ("d_send")<>"D"
	d_send=DATE()
ENDIF
DO GetCase WITH lccode IN COURTSET2

c_RqAtty=fixquote(pc_rqatcod)
pl_GetAt = .F.
DO gfatinfo WITH c_RqAtty, "M"

lc_RqAtType = IIF( pl_plisrq, "Plaintiff", "Defendant")

omed_i.closealias('RqEmail1')
omed_i.sqlexecute("select dbo.GetNoticeAttyEmail ('" + c_RqAtty + "',1) " , "RqEmail1")
IF USED('RqEmail1') AND NOT EOF()
	c_email1=NVL(RqEmail1.EXP,'')
ENDIF

SET PROCEDURE TO TA_LIB ADDITIVE

DO printgroup WITH c_Print, "MDPlNot"
DO printfield WITH c_Print, "Plaintiff",  ALLTRIM(pc_plnam)
DO printfield WITH c_Print, "CasePlaintiff",  ALLTRIM(PC_PLCAPTN)
DO printfield WITH c_Print, "CaseDefendant",ALLTRIM( pc_dfcaptn)
DO printfield WITH c_Print, "CaseDocket",ALLTRIM(NVL(PC_DOCKET,""))
DO printfield WITH c_Print, "RqAtty",    lc_RqAtType 
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
IF lcRole='P'
**** AHG pages
DO PRINTGROUP WITH c_Print,"AHG4-306"
DO PRINTGROUP WITH c_Print,"AHG4-307"

ENDIF
RELEASE omed_i
RETURN c_print


*************************************************
********************************************************************************
PROCEDURE  AGHPages
PARAMETERS c_name
********************************************************************************
PRIVATE  C_SAVE AS STRING
C_SAVE = SELECT()


DO PRINTGROUP WITH MV,&c_name
SELECT (C_SAVE)
WAIT CLEAR
RETURN
