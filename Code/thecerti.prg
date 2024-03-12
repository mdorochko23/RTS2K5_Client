PROCEDURE TheCerti
******************************************************************
* Print certification documents for various types of records
**EF 06/29/16 - added a  new page : kopcert2.prg #43585
**EF 5/10/06 - added to tHE project.
*****************************************************************
*  EF  08/02/04  Fix a bug
*  DMA 07/23/04  Use long plaintiff names
*  DMA 04/03/02  Add in three new diet-drug litigations (E1, E2, E3)
** EF  09/12/01  3-char. litigation code
*
* Called by CourtCer
******************************************************************
PARAMETER ntag, dthisdate, lcTemp
PRIVATE llCourt, llCourtCert
PRIVATE  nbal,  c_proc, c_mv
c_mv=""
WAIT WINDOW "Printing Certificate. Please wait." NOWAIT NOCLEAR

IF TYPE("mv")="U"
	PUBLIC mv
	mv = ""
ENDIF

bcourt =ALLTRIM(pc_c1Desc)
nbal = 0
IF NOT USED('Courtc')
	USE &lcTemp AGAIN ALIAS CourtC
ENDIF
SELECT CourtC

GO TOP
SCAN FOR SELECTED
	mclass = "Reprint"
	mgroup = "1"
	REPLACE SELECTED WITH .F. FOR TAG=ntag
	*DO doCertif
	pn_tag=ntag
	c_mv= kopcert2 (1, dthisdate, .t.)
	mv=mv+c_mv
	pn_tag=0
	SELECT CourtC
ENDSCAN


SELECT CourtC
USE
WAIT CLEAR

RETURN

**************************************************************************
**************************************************************************
PROCEDURE doCertif
PRIVATE crpltcap, c_defcap, c_docket, c_term, szSpcIns, lcTagName



SELECT MASTER

IF NOT EOF()
	IF NOT INLIST( MASTER.litigation, "D  ", "E  ", "E1 ", "E2 ", "E3 ")
		crpltcap  = ALLTRIM(MASTER.plcap)
	ELSE                                         && Special for National Diet Drugs
* DMA 07/23/04 Use long plaintiff names
		c_fullnam = ALLT( MASTER.Plaintiff)
		STORE "" TO c_plfname, c_pllname, c_plminit, c_plgiven
		DO gfBrkNam WITH c_fullnam, ;
			c_pllname, c_plfname, c_plminit, c_plgiven
		c_plnam = IIF( NOT EMPTY( c_plgiven), c_plgiven + " ", "") ;
			+ c_pllname
		crpltcap = ALLT( c_plnam)

	ENDIF

	c_defcap  = ALLTRIM(MASTER.defcap)
	c_docket  = IIF(ISNULL(MASTER.docket),'',ALLTRIM(MASTER.docket))
	IF TYPE('pd_term')<>"C"
		pd_term= DTOC(pd_term)
	ENDIF
*   c_term    = LEFT(ALLTRIM(pd_term),10)

	c_term=""
&&08/29/13 - use month year per Liz
	c_term=termdate(pd_term)



	mrrqattype = IIF( ;
		ALLTRIM(MASTER.pl_at_code) == ALLTRIM(MASTER.rq_at_code), ;
		"Plaintiff", "Defendant")

	DO printgroup WITH mv, "RepCourtCertif"

	DO printgroup WITH mv, "Case"
	DO printfield WITH mv, "LRS", ""
	DO printfield WITH mv, "Plaintiff", crpltcap
	DO printfield WITH mv, "Defendant", c_defcap
	DO printfield WITH mv, "AttyName", m.reqatty
	DO printfield WITH mv, "Court", bcourt
	DO printfield WITH mv, "Term", c_term
	DO printfield WITH mv, "Docket", c_docket
	DO printfield WITH mv, "AttyType", ;
		IIF(MASTER.rq_at_code=MASTER.pl_at_code, "P", "D")

**get a send_date for reissue tags
	PRIVATE OMED_C AS OBJECT
	LOCAL d_send as Date
	OMED_C = CREATEOBJECT("generic.medgeneric")
	OMED_C.closealias("SendDocs")
	IF pl_Reissue
		C_STR="exec  [dbo].[getSendDate] '" + fixquote(MASTER.cl_code) + "','" + STR(pn_SuppTo) + "'"
		L_OK=OMED_C.SQLEXECUTE (C_STR,"SendDocs")

		IF NOT L_OK
			d_send=pd_RpsPrint
		ELSE
			d_send= SendDocs.send_date
		ENDIF
	ELSE
		d_send=pd_RpsPrint
	ENDIF


	DO printfield WITH mv,"BirthDate", IIF ( pl_1st_req OR pl_UpdHoldReqst,DTOC(d_send),dthisdate) && 10/18/13 added pl_UpdHoldReqst
	DO printfield WITH mv, "Id", pc_ScanSg
	DO printenq  IN ta_lib WITH mv, mclass, mgroup
ELSE
	gfmessage("No records.")
ENDIF
RELEASE OMED_C
RETURN
