PROCEDURE MRCCover
PARAMETERS  n_rt, n_tag, lc_dnamE
PRIVATE mv_1, c_MrcType AS STRING
PRIVATE OMED_mrc AS OBJECT
OMED_mrc=CREATEOBJECT("generic.medgeneric")
c_alias =SELECT()
STORE "" TO mv_1, c_MrcType
*RETURN ""
*3/24/14 : added Mom's  (hold) cover letter
*c_MrcType=MRCType(n_rt)
*IF c_MrcType="MO"
*DO PrintGroup WITH mv_1,"MRC_Mom"
*else
DO PrintGroup WITH mv_1,"MRCCover"
*endif
DO PrintGroup WITH mv_1 ,"Control"



DO PrintField WITH mv_1, "Date",   "" &&DTOC(DATE())
DO PrintField WITH mv_1, "LrsNo", STR(n_rt)
DO PrintField WITH mv_1, "Tag", STR(n_tag)
lcFaxNo=""
lcFaxNo=	TRANSFORM( ALLTRIM(pc_depofile.fax_no), "@R (999)999-9999")
DO PrintField WITH mv_1, "Fax_no", ;
	IIF( LEN(ALLTRIM( lcFaxNo)) < 10, "", "Fax #: " + lcFaxNo)


DO PrintField WITH mv_1, "Loc", "G"



DO PrintGroup WITH mv_1, "Deponent"

c_dep=DepToPrint (ALLTRIM(NVL(pc_depofile.NAME,lc_dnamE)))

DO PrintField WITH mv_1, "Name", c_dep  &&+ IIF(pc_deptype = "H"  ,"",c_addition) &&lc_dname

DO PrintField WITH mv_1, "Addr", ;
	IIF(EMPTY(ALLTRIM(pc_depofile.add2)), ALLTRIM(pc_depofile.add1), ALLTRIM(pc_depofile.add1) + CHR(13) + ALLTRIM(pc_depofile.add2))
DO PrintField WITH mv_1, "City", ALLTRIM(pc_depofile.city)
DO PrintField WITH mv_1, "State", ALLTRIM(pc_depofile.state)
DO PrintField WITH mv_1, "Zip", ALLTRIM(pc_depofile.zip)


**03/21/14 - atten line as on the Request cover page:
IF TYPE('pc_deptype') <>'C'
	pc_deptype= UPPER( LEFT( pc_MailID, 1))
	IF NOT INLIST( pc_deptype, "H", "E", "A", "D")
		pc_deptype = "D"
	ENDIF
ENDIF

OMED_mrc.closealias('Hdept')
lc_sql="select  [dbo].[ShowDept_txn11] ('" + pc_clcode + "','" + STR(n_tag) + "')"
OMED_mrc.SQLEXECUTE(lc_sql, "Hdept")
IF USED('Hdept')
	lc_dept=ALLTRIM(NVL(Hdept.EXP, ''))
ENDIF

&&05/29/14 - for non hospitals use certs as a departments
IF lc_dept="Z" AND pc_deptype <> "H"
	lc_cert="R"
	lc_sql="select  [dbo].[ShowCert_MRCNonHospTag] ('" + pc_clcode + "','" + STR(n_tag) + "')"
	OMED_mrc.SQLEXECUTE(lc_sql, "Cert")
	IF USED('Cert')
		lc_cert=ALLTRIM(NVL(cert.EXP, ''))
		DO CASE
		CASE   lc_cert="B"
			lc_dept="B"
		CASE   lc_cert="D"
			lc_dept="R"
		OTHERWISE
			lc_dept=""
		ENDCASE
	ENDIF
	
ENDIF
&&05/29/14 - for non hospitals use certs as a departments

*IF pc_deptype = "H"
c_attn=""
IF NOT EMPTY(lc_dept)
** This is filled in only if hospital!!
	DO CASE
	CASE lc_dept == "E"
		c_attn = "ECHOCARDIOGRAM"

	CASE lc_dept == "R"
		c_attn = "RADIOLOGY"

	CASE lc_dept == "P"
		c_attn = "PATHOLOGY"

	CASE lc_dept == "B"
		c_attn =  "BILLING"

	CASE lc_dept == "C"
		c_attn =  "CARDIAC CATHS"

	OTHERWISE
		c_attn =IIF(  pc_deptype = "H" ,"MEDICAL RECORDS","")

	ENDCASE
	IF !EMPTY(c_attn )
		szattn = "ATTN: " + c_attn + " DEPARTMENT"
	ENDIF
ELSE
	szattn = ""

ENDIF                                        && not empty lc_dept
*ELSE

*szattn = ""
*ENDIF                                           && pc_deptype = H
&&07/17/2012 -added rolodex's attn line
szattn=IIF(!EMPTY(ALLTRIM(szattn)),szattn , ALLTRIM(UPPER(pc_MAttn)))

*szattn=IIF(EMPTY(ALLTRIM(pc_MAttn)),szattn , ALLTRIM(UPPER(pc_MAttn)))

**3/21/14-end





DO PrintField WITH mv_1, "Extra", IIF(ISNULL(szattn),"",szattn)
DO PrintGroup WITH mv_1, "Plaintiff"

DO PrintField WITH mv_1, "FirstName", pc_plnam
DO PrintField WITH mv_1, "MidInitial", ""
DO PrintField WITH mv_1, "LastName", ""
DO PrintField WITH mv_1, "Addr1", pc_pladdr1
DO PrintField WITH mv_1, "Addr2", pc_pladdr2
IF TYPE('pd_pldob')<>"C"
	pd_pldob=DTOC(pd_pldob)
ENDIF
IF TYPE('pd_pldod')<>"C"
	pd_pldod=DTOC(pd_pldod)
ENDIF
IF NOT EMPTY(pc_maiden1)                        && AND UPPER(a.Litigation) == "I  "
	szAKA = "A.K.A.: " + TRIM( pc_maiden1)
ELSE
	szAKA = ""
ENDIF
DO PrintField WITH mv_1, "BirthDate", LEFT(pd_pldob,10)
DO PrintField WITH mv_1, "SSN", ALLT( pc_plssn)
DO PrintField WITH mv_1, "DeathDate",  LEFT(pd_pldod,10)
DO PrintField WITH mv_1, "Extra", szAKA
IF !EMPTY(c_alias)
	SELECT ( c_alias)
ENDIF
RELEASE OMED_mrc
RETURN mv_1
