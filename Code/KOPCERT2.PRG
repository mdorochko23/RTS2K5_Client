*PROCEDURE KopCert2
* Added a  new page : kopcert.doc #43585
PARAMETERS iCount,  dDate, l_reprint
**iCount - a designator for Original/Copy page
PRIVATE lCopy, c_attysign, MV1 AS STRING, c_alias as String, 	c_rest
c_alias=ALIAS()
PRIVATE OMED_C AS OBJECT
OMED_C = CREATEOBJECT("generic.medgeneric")
c_rest=""
SET PROCEDURE TO TA_LIB ADDITIVE
IF TYPE('dDate')='L'
	dDate=DATE()
ENDIF
PRIVATE crpltcap, c_defcap, c_docket, c_term,  lcTagName, c_barno, c_clcode
STORE  "" TO  MV1,  crpltcap, c_defcap, c_docket, c_term,  lcTagName, c_barno, c_clcode
lCopy = (iCount = 2)
LOCAL d_send AS DATE
*---------------------------------------------------------------------------------------------------------------------------------------------
SELECT MASTER
IF NOT EOF()
	IF l_reprint
		IF NOT INLIST( MASTER.litigation, "D  ", "E  ", "E1 ", "E2 ", "E3 ")
			crpltcap  = ALLTRIM(MASTER.plcap)
		ELSE                                         && Special for National Diet Drugs
			c_fullnam = ALLT( MASTER.Plaintiff)
			STORE "" TO c_plfname, c_pllname, c_plminit, c_plgiven
			DO gfBrkNam WITH c_fullnam, ;
				c_pllname, c_plfname, c_plminit, c_plgiven
			c_plnam = IIF( NOT EMPTY( c_plgiven), c_plgiven + " ", "") ;
				+ c_pllname
			crpltcap = ALLT( c_plnam)

		ENDIF

		c_docket  = IIF(ISNULL(MASTER.docket),'',ALLTRIM(MASTER.docket))
		c_defcap  = ALLTRIM(MASTER.defcap)
		c_clcode=MASTER.CL_CODE

		***  *mail date ( send-date ) 
	
			d_send=dDate
	****
	



	ELSE
		crpltcap= ALLT( pc_plcaptn)
		c_defcap=ALLT( pc_dfcaptn)
		c_docket=PC_DOCKET
		c_clcode=Pc_clcode
	ENDIF

	IF TYPE('pd_term')<>"C"
		pd_term= DTOC(pd_term)
	ENDIF
	c_term=""
	**06/29/16: not used on the new page
	&&08/29/13 - use month year per Liz
	*c_term=termdate(pd_term)
	*mrrqattype = IIF( ;
		ALLTRIM(MASTER.pl_at_code) == ALLTRIM(MASTER.rq_at_code), "Plaintiff", "Defendant")
	**06/29/16: not used on the new page
	l_Ok=OMED_C.sqlexecute("SELECT dbo.AttySignature('" + fixquote(pc_rqatcod) + "')", "AttySign")

	IF NOT l_Ok
		c_attysign=pc_AtySign
	ELSE
		c_attysign=fixquote(AttySign.EXP)
	ENDIF

**get a send_date for reissue tags
IF !l_reprint  
	OMED_C.closealias("SendDocs")
	
	IF pl_Reissue
		ntg=pn_SuppTo
	ELSE
		ntg=pn_tag
	ENDIF
	C_STR="exec  [dbo].[getSendDate] '" + fixquote(c_clcode) + "','" + STR(ntg) + "'"
	l_Ok=OMED_C.sqlexecute (C_STR,"SendDocs")

	IF NOT l_Ok
		d_send=pd_RpsPrint
	ELSE
		d_send= SendDocs.send_date
	ENDIF
ENDIF 
**get a send_date for reissue tags
	DO printgroup WITH MV1, "KOPCertif"
	DO printgroup WITH MV1, "Case"
	DO printfield WITH MV1, "LRS", IIF(lCopy, "**C O P Y**", "")
	DO printfield WITH MV1, "Plaintiff", crpltcap
	DO printfield WITH MV1, "Defendant", c_defcap
	DO printfield WITH MV1, "AttyName", c_attysign

	DO printfield WITH MV1, "Court", PROPER(ALLTRIM(pc_c1Cnty))
	DO printfield WITH MV1, "Term", c_term
	DO printfield WITH MV1, "Docket", c_docket

	DO printfield WITH MV1, "BirthDate", IIF ( ( pl_1st_req  AND ! pl_Reissue) OR pl_UpdHoldReqst,DTOC(pd_RpsPrint),DTOC( d_send))

	DO printfield WITH MV1, "AttyType", ;
		IIF(MASTER.rq_at_code=MASTER.pl_at_code, "P", "D")
	c_rqAtty =fixquote(pc_rqatcod)
	
	DO printfield WITH MV1, "Division", ""
	*DO printfield WITH MV1, "Firm", ALLTRIM(pc_AtyFirm )
	*DO printfield WITH mv1, "Id", pc_ScanSg
	c_rest=AttyData (C_rqAtty)
		
	DO printgroup WITH MV1, "Atty"
	DO printfield WITH MV1, "Name_inv", ALLTRIM(c_attysign)
	DO printfield WITH MV1, "Ata1", '' &&ALLTRIM(PC_ATY1AD)
	DO printfield WITH MV1, "Ata2",'' &&ALLTRIM(PC_ATY2AD)
	*DO printfield WITH MV1, "Ata3", IIF( !EMPTY(c_barno),'PA Bar No.: ' + c_barno, '')
	DO printfield WITH MV1, "Ata3",ALLTRIM(c_rest)
	
	DO printfield WITH MV1, "Atacsz",'' &&C_ATYCSZ
	DO printfield WITH MV1, "FaxNo",'' && IIF( LEN( pc_AtyPhn) < 10, "", pc_AtyPhn)
	

	
	


	IF l_reprint
		DO printenq  IN TA_LIB WITH MV1, mclass, mgroup
	ENDIF
ELSE
	gfmessage("No records.")
ENDIF
RELEASE OMED_C
IF !EMPTY(c_alias)
SELECT (c_alias)
ENDIF

RETURN MV1
******************************************************************
FUNCTION getbarno
PARAMETERS  lc_RqAtty
PRIVATE OMED_2 AS OBJECT
lcAlias = SELECT()
LOCAL 	lc_BarNum AS STRING
OMED_2 = CREATEOBJECT("generic.medgeneric")
OMED_2.closealias("AtBarNum")


l_BarNum=OMED_2.sqlexecute("SELECT dbo.fn_AttyBarNum('" +  fixquote(lc_RqAtty )+ "')", "AtBarNum")
lc_BarNum=IIF(l_BarNum,AtBarNum.EXP, "")
IF !EMPTY(lcAlias)
	SELECT ( lcAlias)
ENDIF
RELEASE OMED_2
RETURN 	lc_BarNum
******************************************************************
PROCEDURE AttyData
PARAMETERS c_atty
LOCAL c_barno as String, c_city as String, c_st as string, c_zip as String,    c_Address  as String, C_ATYCSZ as String
STORE "" TO  c_barno , c_city , c_st ,c_zip , c_Address, C_ATYCSZ
pl_GetAt = .F.
DO gfatinfo WITH c_Atty, "M"
c_barno =ALLTRIM(getbarno(	c_Atty))

lcAlias = SELECT()
LOCAL 	lc_BarNum AS STRING
OMED_2 = CREATEOBJECT("generic.medgeneric")
*------------------------city -----------------------
OMED_2.closealias("AtyCity")
l_ok=OMED_2.sqlexecute("SELECT dbo.GetAttyAddress('" +  fixquote(c_atty )+ "',1)", "AtyCity")
c_city=ALLTRIM(IIF(l_ok,AtyCity.EXP, ""))
*-----------------------state -----------------------
OMED_2.closealias("Atyst")
l_ok=OMED_2.sqlexecute("SELECT dbo.GetAttyAddress('" +  fixquote(c_atty )+ "',2)", "Atyst")
c_st=ALLTRIM(IIF(l_ok,Atyst.EXP, ""))
*-----------------------zip -----------------------
OMED_2.closealias("Atyzip")
l_ok=OMED_2.sqlexecute("SELECT dbo.GetAttyAddress('" +  fixquote(c_atty )+ "',3)", "Atyzip")
c_zip=ALLTRIM(IIF(l_ok,Atyzip.EXP, ""))


IF LEN(ALLTRIM(c_zip)) <9
		C_ATYCSZ= LEFT(ALLTRIM(c_zip),5)
ELSE
		C_ATYCSZ=ALLTRIM(c_zip)
ENDIF

c_Address = c_Address + IIF( NOT EMPTY( ALLTRIM( c_barno)),      ALLTRIM(  "PA Bar No.: "+c_barno) + CHR(13), "")
c_Address =c_Address + ALLTRIM(pc_AtyFirm ) +CHR(13)
c_Address =c_Address +ALLTRIM(PC_ATY1AD) +CHR(13)
c_Address = c_Address + IIF( NOT EMPTY( ALLTRIM( pc_Aty2Ad)),       ALLTRIM( pc_Aty2Ad) + CHR(13), "")
c_Address =c_Address + c_city + " " + c_st + ",   " + c_atycsz +CHR(13)
c_Address = c_Address + IIF( LEN( pc_AtyPhn) < 10, "", pc_AtyPhn) + CHR(13)
IF !EMPTY(lcAlias)
	SELECT ( lcAlias)
ENDIF
RELEASE OMED_2
RETURN  c_Address
