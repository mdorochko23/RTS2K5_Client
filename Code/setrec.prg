PROCEDURE SetRec
*** Setrec.prg - Sets or updates the information from the CaseDeponent file
*** in array RecArr (one row per deponent)
***  RecArr[*, 1] holds deponent info in a single character string
***  RecArr[*, 2] holds physical CaseDeponent # of matching data in CaseDeponent.dbf
***  RecArr[*, 3] holds tag number (for sorting)
***  RecArr[*, 4] holds MailID (for sorting)
*
*    Assumes that TAMaster is open to the case being processed,
*            that gfGetCas has been called for the case,
*            that CaseDeponent is open to the specific request being displayed,
*            and that the appropriate EntryX file is open.
*
* Called by DepOpts, AddTxn21, StatReq, DepStat, Incoming, AddRec
*           New4Scr, StatNRS, SortDep
* Calls StatDesc, StatQual, gfDtSkip
* 03/07/05 EF  -- Add Zicam/Reissue "else" block
* 02/10/05 EF  -- Add 'Zicam' Issues
* 01/19/04 DMA -- Use pl_NoHold and eliminate lookup in Instruct.dbf
* 09/23/03 EF  -- Hold pl_MdlHold for 15 days
* 08/12/03 DMA -- Use new Berry & Berry fields in CaseDeponent.dbf
* 08/07/03 kdl -- Add new parameter "CaseDeponent.inc" to the call to statdesc
* 07/01/03 EF  -- Removed 10 days hold for Propulsid Subpoena issues
* 06/27/03 EF  -- Add 10 days to issue date for Baycol FromRev Auth
* 04/11/03 kdl -- Update the 1st look public variables (merged 8/01/03)
* 04/08/03 DMA -- Remove CA "Retrieving tag..." message per Dan Guarnaccia
* 04/02/03 IZ  -- Remove holding period if tag is Reissue
* 10/02/02 DMA -- Handle situation where both Reissue and Psych Hold flags
*                 apply to same CaseDeponent
* 05/02/02 DMA -- Ensure that Reissue and Psych Hold flags are computed for
*                 all situations
* 03/28/02 MNT -- if not on hold and Type = "S"
*                 use issue date + hold days otherwise use just issue date only.
* 01/10/02 EF  -- Add adjustment for Propulsid NJ PA cases & Subp. issues
* 12/10/01 DMA -- Use public variables to identify office
* 11/14/01 DMA -- Use PCOUNT() to handle optional parameters
* 11/08/01 EF  -- Show future issue dates for Texas subpoenas
* 09/12/01 EF  -- 3-char. litigation code
* 06/20/01 DMA -- Update call to StatDesc to include NRS code
* 02/27/01 DMA -- Move status-qualifier code to external function for reuse
* 01/23/01 DMA -- Add display of WAIT.. F/L for first-look CaseDeponents
* 09/21/00 DMA -- Speed up by eliminating needless array references
* 09/30/99 DMA -- Y2K Changes

PARAMETERS ncnt, holddays, lnFRDays, lnIssDays
* REQUIRED
* ncnt = Current row in RecArr = current deponent being processed
* holddays = days on hold
* OPTIONAL
* lnFrDays = days on From-Review status
* lnIssDays = days since issue of request

PRIVATE c_workstr, lcDesc, c_StatQual, l_PropCases, l_FRBaycol

c_StatQual = SPAC(6)
IF PCOUNT() < 3
	lnFRDays = 0
	lnIssDays = 0
ENDIF

IF RecArr[ncnt, 2] <> 0
	SELECT CaseDeponent
	GOTO RecArr[ncnt, 2]
ENDIF

* 04/08/03 DMA Message removed per discussion w/Dan Guarnaccia
*IF pl_CAVer
*   WAIT WINDOW "Retrieving tag " + ALLTRIM( STR( CaseDeponent.Tag)) ;
*      + "." NOWAIT
*ENDIF

*--4/11/03 kdl start: update the 1st look public variables
pl_Frstlook  = CaseDeponent.first_look
pc_TflAtty   = CaseDeponent.FL_Atty
*--4/11/03 kdl end:

c_workstr = SPACE(80)
STORE .F. TO l_PropCases, l_PropSubp, l_FRBaycol

l_FRBaycol = getpub("pl_baycol") AND CaseDeponent.FromRev AND CaseDeponent.TYPE = "A" AND NOT CaseDeponent.Reissue

IF getpub("pc_litcode") = "3  "
	IF CaseDeponent.TYPE = "S"
		l_PropSubp = .T.
	ELSE
		l_PropCases = INLIST( ALLTRIM( UPPER( getpub("pc_area"))), "PENNSYLVANIA", ;
			"NEWJERSEY")
		* 01/19/04 DMA Eliminate unnecessary IIF
		*      l_PropCases = IIF( INLIST( ALLTRIM( UPPER( pc_area)), "PENNSYLVANIA", ;
		*         "NEWJERSEY"), .T., .F.)
	ENDIF
ENDIF

* 01/19/04 DMA Get Txn 11 date here to avoid repeated code below
SELECT F
SET ORDER TO cl_txn
ldtxn11 = IIF( SEEK( ;
	pc_clcode + "*" + STR(11) + "*" + STR( CaseDeponent.TAG)), ;
	F.txn_date, d_today)
SELECT F
SET ORDER TO Cl_Code
SELECT CaseDeponent
*
*   For Texas-office subpoenas, adjust due date to future
*   when appropriate
*

IF getpub("pl_OfcHous")
	ldBusOnly = gfDtSkip( ldtxn11, IIF( getpub("pc_TxCtTyp") = "FED", 16, 20))

	*** 03/28/2002 - MNT - if not on hold and Type = "S"
	*** use issue date + hold days, otherwise just use issue date.
	* 01/19/04 DMA Use public global variable and eliminate file activity
	duedate = IIF( F.TYPE = "S" AND NOT getpub("pl_nohold"), ldBusOnly, ldtxn11)

	** 04/02/03 IZ remove holding period if reissue
	IF CaseDeponent.Reissue
		duedate = CaseDeponent.Req_date
	ENDIF
	** end IZ
	SELECT CaseDeponent
	c_workstr = STUFF( c_workstr, 1, 10, DTOC( duedate))
ENDIF **TX cases

* EF 06/27/03 Baycol FromRev Auth issue
IF l_FRBaycol
	duedate = gfChkDat((ldtxn11 + 10), .F., .F.)
	SELECT CaseDeponent
	c_workstr = STUFF( c_workstr, 1, 10, DTOC( duedate))
ENDIF

**EF 09/23/03 add Rezulin MDL-Hold
IF getpub("pl_MdlHold")
	duedate = gfChkDat((ldtxn11 + 15), .F., .F.)
	SELECT CaseDeponent
	c_workstr = STUFF( c_workstr, 1, 15, DTOC( duedate))
ENDIF
***end 9/23/03

*EF 07/01/03 remove propulsid subp
*IF l_PropSubp

*ldBusonly = gfChkDat((ldtxn11+ 10),.f.,.f.)
*duedate = IIF( F.Type = "S", ldBusOnly, F.Txn_Date)
** 04/02/03 IZ remove holding period if reissue
*IF CaseDeponent.Reissue
*duedate = F.Txn_Date
*ENDIF
** end IZ
*SELECT CaseDeponent
*c_workstr = STUFF( c_workstr, 1, 10, DTOC( duedate))
*ENDIF
*EF 07/01/03  end propulsid subp

IF l_PropCases
	ldBusOnly = ldtxn11
	FOR i = 0 TO 13
		ldBusOnly = ldBusOnly + 1
		ldBusOnly = gfChkDat( ldBusOnly, .F., .F.)
	NEXT
	duedate = ldBusOnly
	** 04/02/03 IZ remove holding period if reissue
	IF CaseDeponent.Reissue
		duedate = CaseDeponent.Req_date
	ENDIF
	** end IZ
	SELECT CaseDeponent
	c_workstr = STUFF( c_workstr, 1, 10, DTOC( duedate))
ELSE
	IF NOT getpub("pl_OfcHous") AND NOT l_FRBaycol AND NOT getpub("pl_MdlHold") AND NOT getpub("pl_Zicam")
		c_workstr = STUFF( c_workstr, 1, 10, DTOC( CaseDeponent.Req_date))
		IF NOT EMPTY( CaseDeponent.Req_date) AND NOT EMPTY( getpub("pc_Court1"))
			IF CaseDeponent.TYPE <> "A"
				IF holddays > 0
					c_workstr = STUFF( c_workstr, 1, 10, ;
						DTOC( CaseDeponent.Req_date + holddays))
				ENDIF
			ELSE
				IF CaseDeponent.FromRev
					c_workstr = STUFF( c_workstr, 1, 10, ;
						DTOC( CaseDeponent.Req_date + lnFRDays))
				ELSE
					c_workstr = STUFF( c_workstr, 1, 10, ;
						DTOC( CaseDeponent.Req_date + lnIssDays))
				ENDIF
			ENDIF
		ENDIF
	ENDIF
	** 04/02/03 IZ remove holding period if reissue
	IF CaseDeponent.Reissue
		c_workstr = STUFF( c_workstr, 1, 10, DTOC(CaseDeponent.Req_date))
	ENDIF
	** end IZ
	*--- End changes
ENDIF
DO CASE
CASE CaseDeponent.Reissue AND CaseDeponent.HoldPsy
	c_workstr = STUFF( c_workstr, 11, 1, "#")

CASE CaseDeponent.Reissue
	c_workstr = STUFF( c_workstr, 11, 1, "*")

CASE CaseDeponent.HoldPsy
	c_workstr = STUFF( c_workstr, 11, 1, "!")
ENDCASE
**EF 02/10/05 "Zicam" cases   -start
IF getpub("pl_Zicam")

	IF NOT CaseDeponent.Reissue
		DO GetObjct WITH getpub("pc_clcode") , CaseDeponent.TAG, .T.
		duedate = gfChkDat((ldtxn11 + pn_ObjDay), .F., .F.)
		SELECT CaseDeponent
		c_workstr = STUFF( c_workstr, 1, getpub("pn_ObjDay"), DTOC( duedate))

	ELSE
		SELECT CaseDeponent
		c_workstr = STUFF( c_workstr, 1, 10, DTOC( CaseDeponent.Req_date))
	ENDIF
ENDIF
c_workstr = STUFF( c_workstr, 12, 3, TRANSFORM( CaseDeponent.TAG, "999"))


**EF 02/10/05  -end

lcDesc = ALLT( CaseDeponent.DESCRIPT)

* 08/12/03 DMA Use new Berry & Berry information
IF getpub("pl_BBCase") AND NOT EMPTY( CaseDeponent.ASB_Round)
	lcDesc = IIF( SUBS( CaseDeponent.ASB_Round, 2, 1) = "C", ;
		SUBS( CaseDeponent.ASB_Round, 3, 1), SUBS( CaseDeponent.ASB_Round, 2, 2)) ;
		+ "-" + lcDesc
ENDIF

lcDesc = IIF( LEN( lcDesc) <= 29, PADR( lcDesc, 29), ;
	LEFT( lcDesc, 22) + ".." + RIGHT( lcDesc, 5) )
c_workstr = STUFF( c_workstr, 16, 29, lcDesc)

*--08/07/03 kdl start: add new parameter "CaseDeponent.inc" to the call to statdesc
c_workstr = STUFF( c_workstr, 46, 7, ;
	PADR( StatDesc( CaseDeponent.STATUS, CaseDeponent.NRS_Code, CaseDeponent.Inc), 7))
*--kdl out 8/07/03: c_workstr = STUFF( c_workstr, 46, 7, ;
*--   PADR( StatDesc( CaseDeponent.Status, CaseDeponent.NRS_Code), 7))
*--08/07/03 kdl end:

c_workstr = STUFF( c_workstr, 54, 6, StatQual())

c_workstr = STUFF( c_workstr, 61, 10, DTOC( CaseDeponent.Fin_Date))
c_workstr = STUFF( c_workstr, 72, 4, TRANSFORM( CaseDeponent.PAGES, "9999"))
RecArr[nCnt, 1] = c_workstr
RecArr[nCnt, 3] = CaseDeponent.TAG
RecArr[nCnt, 4] = CaseDeponent.MailID_No
RETURN
