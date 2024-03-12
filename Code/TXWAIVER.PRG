PROCEDURE TXWaiver
**
**EF 3/15/06 Added to the project.
***************************************************************************
** 06/23/04 DMA Correct typo in printgroup call -- TXSublist, not TXSubList
** 06/22/04 kdl Fix parameter string passed to printgroup
** 06/09/04 DMA Extracted from TXNotice and converted to stand-alone routine
** 06/14/04 DMA Updated to use global variables for case-level data

** Called by RunTxNot during end-of-day processing for bulk printing
** Called by GenUtils during tag-level reprinting (from general utility menu)
** Called by TXNotice during case-level reprinting (from case-processing menu)
** Assumes that gfGetCas has already been called for case-level globals
** Calls gfTXCour, PrintGroup, PrintField

PARAMETERS lcAtcode, dThisDate
*PARAMETERS lcAtcode, dThisDate, lc_clcode
** lcATCode  == Attorney code of notice recipient
** dThisDate == Date of notices being produced
**                 [This will be the original print date for reprints]

dbInit = ALIAS()
IF NOT USED( "TXnotice")
	*USE (F_TXNOTICE) in 0
	l_TxNot=GetTxNotic(dThisDate)
	IF NOT l_TxNot
		gfmessage( "Cannot get TX Notice file" )
		RETURN
	ENDIF


ENDIF
SET PROCEDURE TO TA_Lib ADDITIVE
SELECT TXNotice
SET ORDER TO UnqCase
IF SEEK( DTOC( dThisDate) + pc_clcode)
	DO PrtNotc WITH ALLTRIM( lcAtcode), "1"
	DO PrtNotc WITH ALLTRIM( lcAtcode), "2"
	SELECT TXNotice
ENDIF
SET ORDER TO NtcList
SELECT (dbInit)
RETURN
*********************************************************************
**************************************************************************
PROCEDURE PrtNotc
PARAMETER mratcode, nPage
PRIVATE mnameinv, mratadd1, mratadd2, mratadd3, mRAtFax
PRIVATE mrterm, szSpcIns, lcTagName, lcNotice


** Get Data for Recipient Attorney!!
STORE "" TO mnameinv, mratadd1, mratadd2, mratadd3, mratcsz, mRAtFax
*SELECT Taatty
pl_GetAt = .F.
DO gfatinfo WITH mratcode, "M"

cNameInv = pc_AtySign
cRAtAdd1 = ALLTRIM( pc_Atyfirm)
cRAtAdd2 = ALLTRIM( pc_Aty1Ad)
cRAtAdd3 = ALLTRIM( pc_Aty2Ad)
cRAtCSZ = ALLTRIM( pc_Atycsz)
cRAtFax = TRANSFORM( pc_AtyPhn, pc_fmtphon)


*IF SEEK( mratcode)
* mNameInv = ALLTRIM( ALLTRIM( NewFirst) + " " + ;
IIF( EMPTY( NewInit), "", NewInit + ".")) + " " + ALLTRIM( NewLast)
*mRAtAdd1 = ALLTRIM( firm)
*mRAtAdd2 = ALLTRIM( NewAdd1)
*mRAtAdd3 = ALLTRIM( NewAdd2)
*mRAtCSZ = ALLTRIM( NewCity + " " + NewState + "  " + NewZip)
*mRAtFax = TRANSFORM( AtFax, pc_fmtphon)
*ENDIF



*** Get Requesting Attorney Type!!
*mrrqattype = IIF( pl_plisrq, "Plaintiff", "Defendant")

*--6/22/04 kdl start: fix parameter string passed to printgroup
DO PrintGroup WITH mv, IIF( nPage = "1", "TXWaiver", "TXSublist")
*--DO PrintGroup WITH IIF( npage = "1", "TXWaiver", "TXSubList")

DO PrintField WITH mv, "RT", pc_lrsno
*DO PrintField WITH mv, "RequestDate", dtoc(TXNotice.Txn_Date)
DO PrintField WITH mv, "Loc", pc_offcode
DO PrintField WITH mv, "PertainsTo", pc_plnam

DO PrintGroup WITH mv, "Case"
DO PrintField WITH mv, "Plaintiff", ALLTRIM( pc_plcaptn)
DO PrintField WITH mv, "Defendant", ALLTRIM( pc_dfcaptn)
DO PrintField WITH mv, "Docket", ALLTRIM( pc_docket)
DO IfNoTxCourt IN pwrquest
** get and print court data
DO gfTXCour                                     && with ALLTRIM( tamaster.court)

DO PrintGroup WITH mv, "Atty"

laRTS = ""
lcRPS = ""
DIMENSION laRTS(5)
DIMENSION laRPS(5)
* Variable names with values previously picked up from file
laRTS[1] = "cNameInv"
laRTS[2] = "cRAtAdd1"
laRTS[3] = "cRAtAdd2"
laRTS[4] = "cRAtAdd3"
laRTS[5] = "cRAtCSZ"
* Field names on RPS document
laRPS[1] = "Name_inv"
laRPS[2] = "Ata1"
laRPS[3] = "Ata2"
laRPS[4] = "Ata3"
laRPS[5] = "Atacsz"
lnRTS = 0
FOR nLoop = 1 TO 5
	lnRTS = lnRTS + 1
	DO WHILE lnRTS < 6
		IF EMPTY(&laRTS[lnRTS].)
			lnRTS = lnRTS + 1
		ELSE
			EXIT
		ENDIF
	ENDDO
	IF lnRTS < 6
		DO PrintField WITH mv, laRPS[nLoop], &laRTS[lnRTS].
	ELSE
		DO PrintField WITH mv, laRPS[nLoop], " "
	ENDIF
NEXT nLoop

DO PrintField WITH mv, "FaxNo", cRAtFax

IF nPage = "2"
	o = CREATE("generic.medgeneric")
	** show all subpoena issues for the specified day and case
	*lcEntry = pc_EntryN
	* SELECT (lcEntry)
	*SET ORDER TO Status
	**10/01/18 SL #109598
	*c_sql="SELECT * FROM tbltimesheet with (index(IX_tblTIMESHEET)) WHERE cl_code='" +
	c_sql="SELECT * FROM tbltimesheet WHERE cl_code='" + ;
		fixquote(pc_clcode) + "' and txn_code='"+ STR(11) + "'"

	o.sqlexecute(c_sql,'Timesheet')
	SELECT Timesheet
	IF NOT EOF()

		SCAN WHILE Timesheet.cl_code = pc_clcode

			IF Timesheet.TYPE <> "A" AND Timesheet.txn_date = dThisDate
				DO PrintGroup WITH mv, "Item"

				DO PrintField WITH mv, "Tag", ALLTRIM( Timesheet.DESCRIPT)
				DO PrintField WITH mv, "Name", "____ " + ALLTRIM( STR( Timesheet.TAG))
			ENDIF

			SELECT Timesheet
		ENDSCAN
	ENDIF
ENDIF

SELECT TXNotice
RETURN
