***************************************************************************
**Print SRQ letter
**c_deponent - description, c_dept -department, l_onepage- .t. if printed as a stand alone doc.
PARAMETERS c_deponent, c_dept, l_onepage
PRIVATE c_attn AS STRING
c_attn=""
IF pc_deptype = "H"
	IF NOT EMPTY(c_dept)
** This is filled in only if hospital!!
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

ENDIF                                           && pc_deptype = H




DO PrintGroup WITH mv, "SRQLetter"
DO PrintField WITH mv, "Date",  DTOC(DATE())
DO PrintField WITH mv, "Loc", "P"
DO PrintGroup WITH mv, "Deponent"
DO PrintField WITH mv, "Name", c_deponent
DO PrintField WITH mv, "Addr", ;
IIF(EMPTY(pc_depofile.add2), pc_depofile.add1, pc_depofile.add1 + CHR(13) + pc_depofile.add2)
DO PrintField WITH mv, "City", pc_depofile.city
DO PrintField WITH mv, "State", pc_depofile.state
DO PrintField WITH mv, "Zip", pc_depofile.zip
DO PrintField WITH mv, "Extra", IIF(ISNULL(c_Attn),"",c_Attn)
DO PrintGroup WITH mv, "Plaintiff"

* DMA 05/25/04 Switch to long plaintiff name
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
IF  l_onepage
gcCl_code=pc_clcode
gnTag=pn_tag
	DO prtenqa IN ta_lib WITH mv, "SRQLetter", "2",  ALLTRIM(pc_depofile.fax_no)
ENDIF
WAIT WINDOW "SRQ Letter .. printing.." NOWAIT

RETURN


