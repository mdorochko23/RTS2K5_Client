******************************************************************
**calls a screen for a fax cover page
PARAMETERS N_TAG
PRIVATE l_OK AS Boolean, cAlias AS STRING
PRIVATE OMED3 AS OBJECT
OMED3=CREATEOBJECT("generic.medgeneric")

cAlias=ALIAS()
l_OK=.F.
IF TYPE('nTAG')='U'
	ntag=N_TAG
ENDIF
PRIVATE szdate, szcase, bproc, szproc, szpgcnt, c_faxdept,lc_Order, lc_Order2, lc_key, lc_key2, c_faxtrans
c_faxtrans = "(999) 999-9999"
c_faxtran="@R (999)999-9999"

STORE "" TO szpgcnt, lc_Order, lc_Order2, lc_key, lc_key2, lc_ReqText
szdate = CMONTH(d_today) + " " + ALLT(STR(DAY(d_today))) + ;
	", " + ALLT(STR(YEAR(d_today)))

IF NOT(TYPE( "szKey")="U") AND (NOT EMPTY(szkey))
	szdesc = UPPER(ALLT(timesheet.DESCRIPT))
ENDIF

SELECT pc_depofile

IF NOT EOF()
	szfaxnum = 	TRANSFORM( ALLTRIM(pc_depofile.fax_no), c_faxtran)
ELSE
	IF TYPE( "szFaxNum") = "C"
		szfaxnum = TRANSFORM( VAL( szfaxnum), c_faxtran)
	ELSE
		szfaxnum = TRANSFORM( szfaxnum, c_faxtran)
	ENDIF
ENDIF

szcase = pc_plnam
pc_FaxAttn = " "
btnchoice = 0
mv=""
***

IF NOT  USED("REQUEST")
	ccl_code=pc_clCode
	OMED3.sqlexecute("  exec [dbo].[GetRequestByMasterId] '" + MASTER.ID_TBLMASTER +"'", "REQUEST")
ENDIF


****
mv=goApp.OpenForm("issued.frmfax2cov", "M", REQUEST.id_tblRequests ,REQUEST.id_tblRequests, ;
	MASTER.ID_TBLMASTER, szfaxnum, ALLTRIM(REQUEST.DESCRIPT))

szfaxnum= cleanfax ( ALLTRIM(szfaxnum))
REPLACE fax_no WITH szfaxnum IN pc_depofile && 2/22/13 -MAKE SURE THE EDITED FAX# USED TO FAX A 2ND REQUEST
IF (ISNULL(mv))
	mv = ''
ENDIF
IF !EMPTY(mv)
	l_OK=.F.
	l_Phonetxn = .T.
	IF l_Phonetxn
&&5/8/17 #61920/21
		DO FaxMemo WITH IIF(pl_1st_Req	, 1,2), N_TAG
	ENDIF
ELSE
	l_OK =.T. &&CANCEL FAX
ENDIF

RELEASE OMED3
IF !EMPTY(cAlias)

	SELECT (cAlias)
ENDIF

RETURN l_OK
******************************************************************
