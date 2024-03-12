**Print Avandia1 letter
**c_deponent - description, c_dept -department
PARAMETERS c_deponent, c_dept
PRIVATE c_attn AS STRING
c_attn=""
IF pc_deptype = "H"
	IF NOT EMPTY(c_dept)
		DO CASE
			CASE c_dept == "E"
				c_Attn= "ATTN: ECHOCARDIOGRAM DEPARTMENT"
			CASE c_dept == "R"
				c_Attn= "ATTN: RADIOLOGY DEPARTMENT"
			CASE c_dept == "P"
				c_Attn= "ATTN: PATHOLOGY DEPARTMENT"
			CASE c_dept == "B"
				c_Attn=  "ATTN: BILLING DEPARTMENT"
			CASE c_dept == "C"
				c_Attn=  "ATTN: CARDIAC CATHS DEPARTMENT"
			OTHERWISE
				c_Attn= "ATTN: MEDICAL RECORDS DEPARTMENT"
		ENDCASE
	ELSE
		c_Attn= ""

	ENDIF                                        && not empty cdept

ENDIF   
IF TYPE("pd_MailDte")='D'
	d_MailDte=pd_MailDte
ELSE
	d_MailDte=DATE()
ENDIF
                                        && pc_deptype = H


DO PrintGroup WITH mv, "AV1Letter"
DO PrintField WITH mv, "Date",  DTOC(d_MailDte)
DO PrintField WITH mv, "Loc", "P"
DO PrintGroup WITH mv, "Deponent"
DO PrintField WITH mv, "Name", c_deponent
DO PrintField WITH mv, "Addr", ;
IIF(EMPTY(ALLTRIM(pc_depofile.add2)), pc_depofile.add1, ALLTRIM(pc_depofile.add1) + CHR(13)  + ALLTRIM(pc_depofile.add2))
DO PrintField WITH mv, "City", pc_depofile.city
DO PrintField WITH mv, "State", pc_depofile.state
DO PrintField WITH mv, "Zip", pc_depofile.zip
DO PrintField WITH mv, "Extra", IIF(ISNULL(c_Attn),"",c_Attn)
DO PrintGroup WITH mv, "Plaintiff"
DO PrintField WITH mv, "FirstName", pc_plnam
DO PrintField WITH mv, "MidInitial", ""
DO PrintField WITH mv, "LastName", ""
DO PrintField WITH mv, "Addr1", pc_pladdr1
DO PrintField WITH mv, "Addr2", pc_pladdr2
IF TYPE('pd_pldob')<>"C"
	pd_pldob=DTOC(pd_pldob)
ENDIF
IF TYPE('pd_pldod')<>"C"
	pd_pldod=DTOC(pd_pldod)
ENDIF

DO PrintField WITH mv, "BirthDate", LEFT(pd_pldob,10)
DO PrintField WITH mv, "SSN", ALLT( pc_plssn)
DO PrintField WITH mv, "DeathDate",  LEFT(pd_pldod,10)
DO PrintField WITH mv, "Extra", ""



RETURN


