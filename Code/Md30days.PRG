**Function  Md30days
**Print Md 30 Letter letter
**c_deponent - description, c_dept -department
PARAMETERS c_deponent, c_dept, c_rt, c_tg, c_mailid, c_request
PRIVATE c_attn AS STRING, mv1 AS STRING
STORE "" TO c_attn, mv1
calias=ALIAS()
IF TYPE('pc_deptype')<>"C"
	IF NOT ISDIGIT( LEFT( ALLT( c_mailid), 1))
		PC_DEPTYPE = LEFT( ALLT( c_mailid), 1)
	ELSE
		PC_DEPTYPE = "D"
	ENDIF
ENDIF
IF PC_DEPTYPE = "H"
	IF NOT EMPTY(c_dept)
		DO CASE
		CASE c_dept == "E"
			c_attn= "ATTN: ECHOCARDIOGRAM DEPARTMENT"
		CASE c_dept == "R"
			c_attn= "ATTN: RADIOLOGY DEPARTMENT"
		CASE c_dept == "P"
			c_attn= "ATTN: PATHOLOGY DEPARTMENT"
		CASE c_dept == "B"
			c_attn=  "ATTN: BILLING DEPARTMENT"
		CASE c_dept == "C"
			c_attn=  "ATTN: CARDIAC CATHS DEPARTMENT"
		OTHERWISE
			c_attn= "ATTN: MEDICAL RECORDS DEPARTMENT"
		ENDCASE
	ELSE
		c_attn= ""

	ENDIF                                        && not empty cdept

ENDIF

IF TYPE ("c_request")="D" OR TYPE ("c_request")="T"
	IF  TYPE ("c_request")="T"
		c_request=TTOD(c_request)
	ENDIF
ELSE
	c_request=CTOD(c_request)
ENDIF


* 06/17/03 DMA Add precise location of PrintDep routine
IF LEFT( ALLT( c_mailid), 1)="D"
	c_drname=gfdrformat(c_deponent)
	c_depname = IIF(NOT "DR."$c_drname,"DR. "+ALLTRIM(c_drname),c_drname)
ELSE
	c_depname = ALLTRIM(c_deponent)

ENDIF

SET PROCEDURE TO TA_LIB ADDITIVE
DO PrintGroup WITH mv1, "Md30Days"
DO PrintField WITH mv1, "ReqDate", DTOC( gfChkDat( c_request + 1, .F., .F.) ) &&5/26/15- ADD 1 DAY
DO PrintField WITH mv1, "Loc", "P"

DO PrintGroup WITH mv1, "Deponent"
DO PrintField WITH mv1, "Name",c_depname
DO PrintField WITH mv1, "Addr", ;
	IIF(EMPTY(ALLTRIM(pc_depofile.add2)), pc_depofile.add1, ALLTRIM(pc_depofile.add1) + CHR(13)  + ALLTRIM(pc_depofile.add2))
DO PrintField WITH mv1, "City", pc_depofile.city
DO PrintField WITH mv1, "State", pc_depofile.state
DO PrintField WITH mv1, "Zip", pc_depofile.zip
DO PrintField WITH mv1, "Extra", IIF(ISNULL(c_attn),"",c_attn)

DO PrintGroup WITH mv1, "Plaintiff"
DO PrintField WITH mv1, "FirstName", pc_plnam
DO PrintField WITH mv1, "MidInitial", ""
DO PrintField WITH mv1, "LastName", ""
DO PrintField WITH mv1, "Addr1", pc_pladdr1
DO PrintField WITH mv1, "Addr2", pc_pladdr2
IF TYPE('pd_pldob')<>"C"
	pd_pldob=DTOC(pd_pldob)
ENDIF
IF TYPE('pd_pldod')<>"C"
	pd_pldod=DTOC(pd_pldod)
ENDIF
DO PrintField WITH mv1, "BirthDate", LEFT(pd_pldob,10)
DO PrintField WITH mv1, "SSN", ALLT( pc_plssn)
DO PrintField WITH mv1, "DeathDate",  LEFT(pd_pldod,10)
DO PrintField WITH mv1, "Extra", ""


DO PrintGroup WITH mv1, "Case"
DO PrintField WITH mv1, "Plaintiff", ALLTRIM( pc_plcaptn)
DO PrintField WITH mv1, "Defendant", ALLTRIM( pc_dfcaptn)
DO PrintField WITH mv1, "Docket",  ""

DO PrintGroup WITH mv1, "Control"
DO PrintField WITH mv1, "Date", DTOC( DATE())
DO PrintField WITH mv1, "LrsNo", c_rt
DO PrintField WITH mv1, "Tag", c_tg


**5/26/15- STOP FAXING PER LIZ
*!*	DO CASE
*!*	CASE  LEN(ALLTRIM(pc_depofile.fax_no))=10 AND NOT INLIST(ALLTRIM(pc_depofile.fax_no),'1111111111','2222222222','3333333333','4444444444','5555555555','6666666666','7777777777','8888888888','9999999999','0000000000')
*!*		c_class="FaxReleaseLtr"
*!*	OTHERWISE
*!*	c_class="ReleaseLtr"
*!*	*!*	ENDCASE
*!*	DO prtenqa WITH mv1, c_class, "1" ,""

*DO prtenqa WITH mv1, c_class, "1" ,ALLTRIM(pc_depofile.fax_no)


IF NOT EMPTY(calias)
	SELECT(calias)
ENDIF
RETURN mv1
