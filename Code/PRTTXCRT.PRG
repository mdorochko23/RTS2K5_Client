PROCEDURE PrtTXCrt
*******************************************************************
** EF 3/15/06 -Added to the project.
***---------------------------------------------------------------
* Formerly PROCEDURE PrtCrtLtr
* 06/09/2004 DMA Extracted from TXCrtLtr; eliminate parameters
* 06/08/2004 DMA Use global vbls, long plaintiff name
* Called: GenUtils for reprints; TXCrtLtr for end-of-day noticing
* Assumes gfGetCas has already been called
*PARAMETERS lcclcode, lccounty
SET PROCEDURE TO TA_LIB ADDITIVE
dbInit = ALIAS()
DO PrintGroup WITH mv, "TXCourtLtr"

DO PrintField WITH mv, "RT", pc_lrsno
DO PrintField WITH mv, "Loc", pc_offcode
DO PrintField WITH mv, "ControlDate", DTOC( dThisdate)

DO PrintField WITH mv, "PertainsTo", pc_plnam
DO PrintGroup WITH mv, "Case"

DO PrintField WITH mv, "Plaintiff", ALLT( pc_plcaptn)
DO PrintField WITH mv, "Defendant", ALLT( pc_dfcaptn)
DO PrintField WITH mv, "Docket", ALLT( pc_docket)
o = CREATE("generic.medgeneric")
IF NOT USED("TXCourt")
	*USE (f_txcourt) IN 0

	o.sqlexecute("exec GetAllTxCourt", "TxCourt")
	pc_TxCtTyp = SUBS( pc_Court1, 1, 3)
	SELECT TxCourt
	CURSORSETPROP("KeyFieldList", "COURT,CRT_ID,County", "TXCourt")
	INDEX ON COURT TAG COURT
	INDEX ON CRT_ID TAG CRT_ID
	INDEX ON County TAG COUNTY

ENDIF
SELECT TxCourt
IF pc_TxCtTyp = "FED"
	DO PrintField WITH mv, "County", "UNITED STATES DISTRICT COURT"
ELSE
	SET ORDER TO County
	IF SEEK( ALLTRIM( pc_plCnty))
		mcounty = ALLTRIM( TxCourt.County)
		mDesc = ALLTRIM( TxCourt.DESC)
	ELSE
		mcounty = ALLTRIM( pc_plCnty)
		mDesc = ALLTRIM( pc_distrct) + " DISTRICT"
	ENDIF
	DO PrintField WITH mv, "County", ;
		ALLTRIM( UPPER( mcounty)) + " COUNTY"  + " COURTHOUSE"
ENDIF
DO PrintField WITH mv, "CourtAdd", ALLTRIM( pc_c1Addr1)
DO PrintField WITH mv, "CourtCSZ", ALLTRIM( pc_TxCSZ)
DO PrintField WITH mv, "Clerk", ;
	IIF( pc_Court1 = "CCL", "COUNTY", "DISTRICT")
*SELECT TXCourt
*USE

** show all issues for the specified day
*lcEntry = pc_EntryN
*SELECT ( lcEntry)
IF USED('Timesheet')
	SELECT Timesheet
	USE
ENDIF
**10/01/18 SL #109598
*c_sql="SELECT * FROM tbltimesheet with (index(IX_tblTIMESHEET)) WHERE cl_code='" + 
c_sql="SELECT * FROM tbltimesheet WHERE cl_code='" + ;
	fixquote(PC_CLCODE) + "' AND txn_date='" +  ;
	DTOC(dThisdate)+ "' and txn_code=11  Order by tag"

o.sqlexecute(c_sql,'Timesheet')

SELECT Timesheet
*INDEX ON CL_CODE+"*"+STR(TAG) FOR txn_code =11 TAG Status ADDITIVE
*SET ORDER TO Status
*SEEK pc_clcode

SCAN WHILE ALLTRIM( cl_code) == ALLTRIM( PC_CLCODE)
	IF Timesheet.TYPE <> "A" AND Txn_Date = dThisdate
		DO PrintGroup WITH mv, "Item"
		DO PrintField WITH mv, "Tag", ;
			"Location: " + ALLTRIM( Timesheet.DESCRIPT)
		DO PrintField WITH mv, "Name", ;
			"- Tag #:  " + ALLTRIM( STR( Timesheet.TAG))
	ENDIF
	SELECT Timesheet

ENDSCAN

SELECT TXNotice
SELECT ( dbInit)
gcCl_Code = PC_CLCODE
gnTag =Timesheet.TAG
SET PROCEDURE TO ta_lib ADDITIVE
DO prtenqa WITH mv, mclass, "1", ""
RETURN
