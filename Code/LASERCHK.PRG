PROCEDURE LaserChk
*****************************************************************************
**02/03/09 -EF-  USE dbo.GetStatusDescription function
**06/20/07 -EF - Replaced SQL by Stored Proc to get Record.
**08/31/06 -EF - Remove a call for the prtchk, use the same print check process in
** all four offices per John M. request.
**04/24/06 -EF - added to the project.
*****************************************************************************
* LaserChk.prg check printing program
*
*  Called by RTS Main Program
*  Calls StatDesc, gfAtLast, gfRStat, gfMsg, gfBrkNam, gfHold, gfHServe
*  Uses screens Office, Printchk, LaserChk
*
* History :
* Date      Name  Comment
* ---------------------------------------------------------------------------
* 02/23/06  DMA   Allow cancelled tags to have checks print with future dates
* 09/19/05  DMA   Add SET PRINTER TO after print is complete to close spooler
* 06/20/05  DMA   Switch Oakland to new-format check stock
* 06/16/05  DMA   Do not allow Hold/S to override Waiver Received
* 06/09/05  DMA   Display "WaivRcv" status when appropriate; add record locking
*                 Update global record as well as local
* 04/12/05  DMA   Handle situation with missing invoice #
* 04/04/05  DMA   Move ID info down one line, center invoice #, per John McT.
* 06/10/04  DMA   Use laser-printer codes from PUBLIC.PRG
* 05/03/04  IZ    suppress checking of qualifier for reissue tags
* 04/15/04  IZ    check if qualifier should be "HOLD_S"
*                 remove () from Deponent description
* 04/14/04  DMA   Use long plaintiff names
* 01/19/04  HN    Adjust spacing on Chk#, Amount and Address for KoP.
*                 Print Attn line only if present.
* 01/12/04  HN    Moved Payee line one above ATTN line.
* 01/09/04  HN    Removed old Laserchk.prg from Develop\Rts directory.
*                 Renamed routines to 8 characters to avoid Fox confusion.
* 01/08/04  HN    Moved ATTN line up after Deponent, moved Check # up,lined up Address for KoP
* 12/14/03  HN    For Oakland, add the Subpoena Serve date on stub
* 12/03/03  HN    Move some fields around on the check for KoP only
*                 Create separate print Check routine for KoP so as not
*                 to disturb other offices now and for future placement changes.
*
* 08/14/03  kdl   Change mail date to 20 days after check is generated for
*                 first-look
* 03/04/03  HN    Removed blank spaces in Date print and changed date/Amount to
*                 a one-line print.(Possible Fix for amount overlap problem)
*                 Added Createdby on Stub instead of Worker. Moved Amount below AMOUNT title
* 02/20/02  HN    Adapted from Printchk.prg
* 02/19/02  HN    Allow checks to print on laser printer.

*****************************************************************************
PRIVATE n_chkoffc, llTam, llEntry1, llEntry2, llEntry3, llEntry4, lnToPrint, ;
n_PrtCheck
n_PrtCheck = 1
n_chkoffc  = 1                                  && Default to Philadelphia
lnButton=1
l_ok=goApp.OpenForm("generic.frmlaserchk", "M")
IF NOT l_ok
	RETURN
ENDIF

RETURN

**************************************************************
PROCEDURE ProcChk

PARAMETERS lnStart, lnEnd, lcOffice
PRIVATE lnGood, lnBad
lnGood = 0
lnBad = 0
gdBlankDt={  /  /    }

LOCAL oGen
oGen=CREATEOBJECT("generic.medgeneric")
lcOffCode=IIF( INLIST(lcOffice, "G","T"), "P", lcOffice)
lcSQLLine="select * from tblOfficeLocation where code='"+ALLTRIM(lcOffCode)+"' and active=1"
oGen.sqlexecute(lcSQLLine, "viewOfficeAddr")
RELEASE oGen

SET PRINT ON
SET CONSOLE OFF
CLEAR

_SCREEN.MOUSEPOINTER=11
FOR lnCounter = lnStart TO lnEnd
	WAIT WINDOW "Printing checks. Please wait." NOWAIT NOCLEAR


	STORE 0 TO lnTag, lnCheck, lnAmount, lnLrs
	STORE "" TO lcCode, lcRqAtC, lcRqName, lcChkName, lcWorker, ;
	lcCourt, lcInvoice, lcDepon, lcAdd1, lcAdd2, lcAdd3, lcAdd4, lcAtten, ;
	c_last, c_first, c_init, c_given
	STORE .F. TO llChkBad, llPrepay
	ldCheck = gdBlankDt
	LOCAL ots AS medtimesheet OF timesheet
	ots = CREATEOBJECT("medtimesheet")
	SELECT Checks
*SET ORDER TO check_no
	LOCATE FOR check_no=lnCounter
* IF SEEK( lnCounter)
	IF FOUND()
		IF Checks.check_no <> lnCounter
			gfmessage(  "Checks file is bad. Please notify IT Department.")
			CANCEL
		ELSE
			lcCode = Checks.cl_code
			lnTag = Checks.TAG
			lnCheck = Checks.check_no
			lnAmount = Checks.check_amt
			lcInvoice = Checks.Invoice_no
			ldCheck = Checks.check_date
			lcDepon = Checks.deponent
			lcAdd1 = Checks.add1
			lcAdd2 = Checks.add2
			lcAdd3 = Checks.add3
			lcAdd4 = Checks.add4
			lcAtten = Checks.attention
			llPrepay = Checks.prepay

			IF void OR NOT EMPTY( void_date)
				llChkBad = .T.
			ENDIF
		ENDIF
	ELSE
		llChkBad = .T.
		lcEntry = ""

		IF USED('Timesheet')
			SELECT timesheet
			USE
		ENDIF


		ots.sqlexecute("exec dbo.GetChkFromTimeSheet '" + ;
		STR(lnCounter) + "','"  +  ;
		fixquote(checks.cl_code) +  "','" + ;
		STR(checks.TAG) + "'", "Timesheet")


		SELECT timesheet
		GO TOP  && 09/15/2023 MD #330022
		IF NOT EOF()
** The Missing check was found in one of the Entry Files
			lcCode = cl_code
			lnTag = TAG
			lnCheck = COUNT
			lnAmount = wit_Fee
			lcDesc = DESCRIPT
			ldCheck = LEFT(DTOC(Txn_date),10)
* Update check description in timesheet with "VOID"

			IF LEN( ALLTRIM( DESCRIPT)) <= 42
				REPLACE DESCRIPT WITH ALLTRIM( DESCRIPT) + "**VOID**"
			ELSE
				REPLACE DESCRIPT WITH LEFT( ALLTRIM( DESCRIPT), 42) + "**VOID**"
			ENDIF
			REPLACE wit_Fee WITH 0

			ots.Updatedata()
			c_TimesheetID=timesheet.id_tblTimesheet

**********************************
* Update witness fee total in Record
			l_recupd=ots.sqlexecute("exec dbo.UpdWitnessFee '" ;
			+ TRANSFORM(lnAmount,"999999.99") + "','" + ALLTRIM(STR(1)) + "','"    ;
			+ fixquote(timesheet.cl_code) + "','" + STR(timesheet.TAG) + "','" ;
			+ ALLTRIM(pc_userid)+ "'")

			IF  NOT l_recupd

				gfmessage( "Record information not updated." + ;
				CHR(13) + " Please notify the IT Dept.")
			ENDIF

			lc_str=""

			lc_str="Exec dbo.sp_AddChecks '" ;
			+ fixquote(lcCode) + "','" ;
			+ ALLTRIM(pc_userid) + "','" ;
			+ STR(lnCheck) + "','" ;
			+ fixquote(lcDesc) + "','" ;
			+ lcDesc + "','" ;
			+ STR(lnAmount,6,2) +  "','" ;
			+ ldCheck + "','" ;
			+ '' + "','" ;
			+ '' + "','" ;
			+ '' + "','" ;
			+ '' + "','" ;
			+ STR(lnTag) +"','" ;
			+ '' + "','" ;
			+ timesheet.MailID_No + "','" ;
			+ '' + "','" ;
			+ ALLTRIM(pc_userid) + "','"  ;
			+ c_TimesheetID + "'"

			l_Addchk=ots.sqlexecute(lc_str,"")

			IF NOT l_Addchk
				gfmessage( "No Check has been added. Contact IT. " )
			ENDIF


		ELSE
			gfmessage( "Check " + ALLTRIM( STR( lnCounter)) + ;
			" was not found." + CHR(13) + ;
			"Please notify the IT Dept.")

		ENDIF
	ENDIF


	IF NOT EMPTY( lcCode)
		IF USED("master")
			SELECT MASTER
			USE
		ENDIF
		lc_str="Select cl_code,lrs_No,lrs_nocode,rq_at_code, " + ;
		" docket, court, district, plaintiff, litigation, Acct_Mgr, Sim_Last " + ;
		" from tblMaster where cl_code='" + ;
		fixquote(lcCode)+"' and active=1"
		l_Tam= ots.sqlexecute(lc_str,"Master")



		IF NOT l_Tam
			gfmessage( "No Master File. Contact IT dept." )
			RETURN

		ENDIF

		SELECT MASTER
		IF lcCode = MASTER.cl_code
			lnLrs    = MASTER.lrs_No
			lcRqAtC  = MASTER.rq_at_code
			IF NOT EMPTY( lcRqAtC)
				l_at1= ots.sqlexecute("select dbo.GetAttyName('" + lcRqAtC + "'," + STR(2) + ")" , "Ata1")
				IF NOT EMPTY(Ata1.EXP)
					l_at2= ots.sqlexecute("select dbo.GetAttyName('" + lcRqAtC + "'," + STR(1) + ")", "Ata2")
				ENDIF
				IF NOT l_at1 AND NOT l_at2
					lcRqName=''
					WAIT WINDOW "Cannot get an attorney name."  NOWAIT NOCLEAR
				ELSE
					IF USED('Ata2')
					lcRqName=ALLTRIM(Ata1.EXP) +  ", " +ALLTRIM( Ata2.EXP )
					ELSE
					lcRqName=ALLTRIM(Ata1.EXP)
					endif
				ENDIF
			ENDIF
			DO gfBrkNam WITH MASTER.Plaintiff, ;
			c_last, c_first, c_init, c_given

			lcChkName = ALLT( c_given) + " " + ALLT(c_last)
			lcWorker = Checks.createdby
			lcCourt = ALLTRIM( MASTER.court) + " " + ALLTRIM( MASTER.docket) ;
			+ ALLTRIM( MASTER.district)
		ENDIF
	ENDIF

	lnGood = lnGood + IIF( NOT llChkBad, 1, 0)
	lnBad  = lnBad  + IIF( llChkBad, 1, 0)
	WAIT WINDOW "Check Printing Progress:" + CHR(13) + "Normal Checks: " + ALLTRIM(STR(lnGood)) +  CHR(13) +"Voided Checks: " + ALLTRIM(STR(lnBad)) NOWAIT NOCLEAR


	llLastChk = IIF( lnCounter = lnEnd, .T., .F.)
**  remove () from Deponent description
	PRIVATE ln_pos
	ln_pos = 0
	ln_pos = AT( "(", lcDepon)
	IF ln_pos > 0
		lcDepon = LEFT( lcDepon, ln_pos-1)
	ENDIF

	IF USED('Record')
		SELECT RECORD
		USE
	ENDIF

**EF 6/20/07 - replaced sql with a stored proc
	l_rec=ots.sqlexecute(" exec DBO.GetSingleRequestRecord '" + fixquote(lcCode) + "', '" + STR(lnTag) + "'", "Record")

* 06/20/05 DMA Use new layout for Oakland as well as KoP

*IF INLIST( lcOffice, "T", "S")                   && Pasadena and Texas

*DO prtChk WITH lcCode, lnTag, lnCheck, lnAmount, lnLrs, lcOffice, ;
lcRqName, lcChkName, lcWorker, lcCourt, lcInvoice, ldCheck, ;
llChkBad, lcDepon, lcAdd1, lcAdd2, lcAdd3, lcAdd4, lcAtten, ;
llPrepay, llLastChk
*ELSE
	SELECT RECORD
	IF NOT EOF() OR lnTag=0
		DO PrtNew WITH lcCode, lnTag, lnCheck, lnAmount, lnLrs, lcOffice, ;
		lcRqName, lcChkName, lcWorker, lcCourt, lcInvoice, ldCheck, ;
		llChkBad, lcDepon, lcAdd1, lcAdd2, lcAdd3, lcAdd4, lcAtten, ;
		llPrepay, llLastChk
	ENDIF
ENDFOR
_SCREEN.MOUSEPOINTER=0


SET PRINT OFF

SET CONSOLE ON
** 09/19/05 DMA Close printer spool so checks print faster
SET PRINTER TO
**
WAIT CLEAR
gfmessage( "Check printing complete.")

RETURN


************************************************************************
PROCEDURE PrtNew
**used to print checks in all offices
PARAMETERS lcCode, lnTag, lnCheck, lnAmount, lnLrs, lcOffice, lcRqName, ;
lcChkName, lcWorker, lcCourt, lcInvoice, ldCheck, llChkBad, lcDepon, ;
lcAdd1, lcAdd2, lcAdd3, lcAdd4, lcAtten, llPrepay, llLastChk, lcDeponcity , lcTagDesc

PRIVATE lcWords, recstat, maildstr, offstr, ll_holds, l_cityok
LOCAL ots AS medtimesheet OF timesheet
ots = CREATEOBJECT("medtimesheet")
ll_holds = .F.
l_cityok=.f.
IF NOT llChkBad
	lcWords = words(lnAmount)
ELSE
	lcWords = "*** VOID *** VOID *** VOID *** VOID *** VOID ***"
ENDIF

SELECT Checks

?""
?""
?""
? IIF( EMPTY( lcInvoice), " ", "Inv. #: " + UPPER( ALLT( lcInvoice))) AT 50			&&54
?? lnCheck PICT "########" AT 104		&&113
? "RE: " + ALLT( UPPER ( lcChkName)) + " " + ALLT( STR( lnLrs)) + ;
+ "." + TRANS( lnTag, "@L 999") AT 4			&&6


? " "
? ALLTRIM( lcWords) PICT "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" AT 10	&&13
?
? TRANSFORM(ldCheck,"##/##/####")+SPACE(32)+TRANSFORM(lnAmount,"$$$$.##") at 84   &&92
*? lnAmount PICT "$$$$.##" AT 113		&&119

IF llChkBad
	?"*** VOID *** VOID *** VOID *** VOID *** VOID ***"
ELSE
	? " "
ENDIF
? " "
? lcDepon PICT "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" AT 9	&&12
IF NOT EMPTY( lcAtten)
	? SPACE(2) + "Attn:" + SPACE(3) + ALLTRIM( lcAtten) AT 10	&&13
ELSE
	?
ENDIF

nn=0
IF NOT EMPTY( lcAdd1)
	? SPACE(2) + lcAdd1 PICT "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" AT 10		&&13
ELSE
	nn=nn+1
ENDIF
IF NOT EMPTY( lcAdd2)
	? SPACE(2) + lcAdd2 PICT "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" AT 10		&& 13
ELSE
	nn=nn+1
ENDIF

IF NOT llChkBad
	IF NOT EMPTY( lcAdd3)
		? SPACE(2) + lcAdd3 PICT "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" AT 10	&& 13
	ELSE
		nn=nn+1
	ENDIF
ELSE
	? "*** VOID *** VOID *** VOID ***" AT 45
ENDIF

IF NOT EMPTY( lcAdd4)
	? SPACE(2) + lcAdd4 PICT "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" AT 5		&&8
ELSE
	nn=nn+1
ENDIF

DO WHILE nn > 0
	?" "
	nn=nn-1
ENDDO

FOR i=1 TO 5
	? " "
NEXT

******* Print Invoice Information ***************
?
?
?
?
?
*? "DATE:" AT 5, d_today PICT "@d" AT 14&&11
? d_today PICT "@d" AT 4	&&5
? " "
recstat = " "
maildstr = ""

STORE {} TO ld_reqdate, ld_senddate
lc_type = ""
ll_reissue = .F.
* 06/09/05 DMA Add waiver-received flag
ll_waiver = .F.
ll_holds = .F.



IF NOT EMPTY( lcCode) AND NOT EMPTY( lnTag)
* 06/09/05 DMA Add waiver-received flag
	recstat = gfrstat( Checks.cl_code, Checks.TAG, @lc_type, @ld_reqdate, ;
	@ld_senddate, @ll_reissue, @ll_waiver)
ENDIF

*--2/23/06 dma Add cancelled tags to list
*--8/14/03 kdl start: Add first-look to list
IF INLIST( recstat, "R", "N", "F", "C")
	maildstr = "Mail date: " + DTOC(CTOD(ldCheck) + 20)

ENDIF

IF NOT EMPTY( recstat)
	IF EMPTY(NVL(record.hstatus,''))
	**02/03/2009 replace function

	l_RecSt= ots.sqlexecute("SELECT dbo.GetStatusDescription ('" + RECORD.STATUS + "','"  ;
		+ ALLTRIM(NVL(RECORD.nrs_code,'')) + "'," +  IIF(NVL(RECORD.inc,.F.), STR(1),STR(0))+ ",'" ;
		+  NVL(record.hstatus,'') + "'," + IIF(NVL(RECORD.INPROGRESS,.F.), STR(1),STR(0)) +  ",'" ;
		+ DTOC(record.req_date ) + "','" + DTOC(record.req_date )+ "'," + IIF(NVL(RECORD.waivrcvd,.F.), STR(1),STR(0)) + ")", "RecStatus")
	
*!*			l_RecSt= ots.sqlexecute("SELECT dbo.fn_GetStatusDesc ('" + RECORD.STATUS + "','"  ;
*!*			+ ALLTRIM(NVL(RECORD.nrs_code,'')) + "'," +  IIF(NVL(RECORD.inc,.F.), STR(1),STR(0))+ ",'" ;
*!*			+  NVL(record.hstatus,'') + "'," + IIF(NVL(RECORD.INPROGRESS,.F.), STR(1),STR(0)) + ")", "RecStatus")
	ELSE
	l_RecSt= ots.sqlexecute("SELECT  dbo.GetStatusDescription ('" + RECORD.STATUS + "','"  ;
		+ ALLTRIM(NVL(RECORD.nrs_code,'')) + "'," +  IIF(NVL(RECORD.inc,.F.), STR(1),STR(0))+ ",'" ;
		+  NVL(record.hstatus,'') + "'," + IIF(NVL(RECORD.INPROGRESS,.F.), STR(1),STR(0)) +  ",'" ;
		+ DTOC(record.req_date ) + "','" + DTOC(record.req_date )+ "'," + IIF(NVL(RECORD.waivrcvd,.F.), STR(1),STR(0)) + ")", "RecStatus")
*!*			l_RecSt= ots.sqlexecute("SELECT dbo.fn_GetStatusDesc ('" + NVL(RECORD.hSTATUS,'') + "','"  ;
*!*			+ ALLTRIM(NVL(RECORD.hnrs_code,'')) + "'," +  IIF(NVL(RECORD.hinc,.F.), STR(1),STR(0))+ ",'" ;
*!*			+  NVL(record.hstatus,'') + "'," + IIF(NVL(RECORD.INPROGRESS,.F.), STR(1),STR(0)) + ")", "RecStatus")
	ENDIF 

	
	
	IF  l_RecSt
		c_status=ALLTRIM(RecStatus.EXP)
	ENDIF

** 06/09/05 DMA Add handling for "Waiver Received" Status
** 04/15/04 IZ check if this a HOLD_S case
** 05/03/04 IZ no checking for reissue tags
IF lc_type = "S" AND recstat = "W" AND ;
					NOT EMPTY( ld_reqdate) AND NOT ll_reissue 
  *IF NOT EMPTY(NVL(RECORD.SEND_DATE,'')) &&2/3/09
  IF EMPTY(NVL(RECORD.SEND_DATE,'')) OR  RECORD.SEND_DATE >DATE()&&2/3/09
		ll_holds=.F.
		l_gothold=ots.sqlexecute("EXEC dbo.HoldRulesbyCourt  '" + fixquote(lcCode) + "','" +  ALLTRIM(MASTER.court) + "'", "HoldDays")
		IF l_gothold
			ll_holds=IIF(HoldDays.EXP=0,.F.,.T.)
		ELSE
			WAIT WINDOW " No Hold Period has been found" NOWAIT NOCLEAR
		ENDIF

		DO CASE
* 06/16/05 DMA Do not allow Hold/S to override Waiver Received

			CASE ll_holds AND NOT ll_waiver
				recstat = "HOLD_S"

			CASE ll_waiver
				recstat = "WaivRcv"

			OTHERWISE

				recstat = c_status &&StatDesc( recstat, "")
		ENDCASE
	ELSE
		recstat = c_status &&StatDesc( recstat, "")
	ENDIF
	ENDIF &&2/3/09
*ENDIF &&2/3/09
ENDIF

lnEndCntr=8
SELECT checks
IF !EMPTY(ALLTRIM(NVL(checks.payingfor,""))) AND !EMPTY(ALLTRIM(NVL(checks.spoketo,""))) &&AND EMPTY(ALLTRIM(NVL(lcInvoice,"")))
   * option payment from telephone contact was selected when the check was entered
   lcSQLLine="select dbo.getRPSPhoneByClCode('"+ALLTRIM(master.cl_code)+"')"
   ots.sqlexecute(lcSQLLine,"viewRPSPhone")      
   DO printMessage WITH lcChkName, viewRPSPhone.exp
   USE IN viewRPSPhone
   lnEndCntr=0
ENDIF   

SELECT master
lcLitRep=ALLTRIM(UPPER(master.litigation))+"."+ALLTRIM(getInitials(IIF( EMPTY( MASTER.Acct_Mgr), MASTER.Sim_Last, MASTER.Acct_Mgr)))
 
? "Status: " + recstat + "    " + maildstr AT 8 &&11 &&8

offstr = "Office: " + lcOffice

IF ALLTRIM(UPPER(lcOffice))=="C"
   ? "Case:" AT 7, ;
   lcChkName PICT "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" AT 23, ;
   offstr AT 85
ELSE 
   ? offstr AT 85  
ENDIF 

lcTagDesc =ALLTRIM(checks.descript)
? " "
? "COURT: " AT 7, lcCourt PICT "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" AT 27 ,; 
   lcTagDesc aT 75
? "AMOUNT: " AT 7, lnAmount AT 27
IF NOT EMPTY( lcInvoice)
	? "INVOICE: " AT 7, lcInvoice PICT "!!!!!!!!!!!!!!!" AT 27
ELSE
	? " "
ENDIF
? "VOUCHER NUMBER:" AT 7, ;
lnCheck PICT "##########" AT 33, ;
"RT PREPARER:" AT 52, ;
LEFT( lcWorker, 20) AT 75

**09/28/2010 - ADDED A BLOCK BELOW PER JOHN'S REQUEST

lcDeponcity=""
lcDeponcity=checkcity(checks.add3)

ots.sqlexecute("select dbo.CompareCityonCheck ('" + CHECKS.MailID_No + "','" + fixquote(ALLTRIM(lcDeponcity))+ "')", "CompareC")
l_cityok= CompareC.exp

**09/28/2010 - END

? " "
? "RT #:" AT 7, ;
lnLrs PICT "########" AT 14, ;
"Tag:" AT 25, ;
lnTag PICT "###" AT 30, ;
ALLTRIM(UPPER(lcLitRep)) AT 53, ;
"CITYAGREE: "	 + IIF(l_cityok=.T., "Y", "N") AT 75




IF llPrepay
	? "FEE HAS BEEN PREPAID"
ELSE
	? " "
ENDIF

* 06/20/05 DMA Add Oakland Handserv Info to Invoice when needed
IF ALLTRIM(UPPER(lcOffice))=="C"                               && Oakland
	ldHandSrv = gfHServe( lcCode, lnTag)
	? DTOC( ldHandSrv) at 5
	lnEndCntr=lnEndCntr-1
ENDIF 
FOR counter = 1 TO lnEndCntr
	? " "
NEXT


DO ChkUpdate


IF llLastChk
	? _pprnReset
ELSE
	EJECT
ENDIF
WAIT CLEAR
RETURN
*-------------------------------------------------------------------------------
FUNCTION checkcity
PARAMETERS cadd3
LOCAL c_city as String, nlen as Number, nat as Number
STORE 0 TO nlen, nat
c_city=""

nlen =LEN(ALLTRIM(cadd3))
nAt=AT(",",cadd3,1)
c_city=left(cadd3,nat-1)

RETURN c_city


* ---------------------------------------------------------------------------
PROCEDURE ChkUpdate
LOCAL lnArea
lnArea=SELECT()

oMED = CREATEOBJECT("generic.medGeneric")

SELECT Checks
LOCATE FOR Checks.check_no=lnCheck


IF Checks.check_no = lnCheck

	REPLACE Checks.printed WITH .T.
	IF EMPTY(ALLTRIM(Checks.print_date)) && 03/15/2013- 	per Philip's request keep an original print date 
		REPLACE Checks.print_date WITH DTOC(d_today)
	ENDIF
	IF llChkBad
		IF NOT Checks.void
			REPLACE Checks.void WITH .T.
		ENDIF
		IF EMPTY( Checks.void_date)
			REPLACE Checks.void_date WITH DTOC(d_today)
		ENDIF
	ENDIF


*!*		oMED.sqlexecute("Exec dbo.sp_PrintCheck " + IIF(Checks.void,STR(1),STR(0)) + ",'" ;
*!*		+ Checks.id_tblChecks + "','" + ALLTRIM(pc_userid) + "'", "")
		oMED.sqlexecute("Exec dbo.SetPrintCheckByClCodeTag " + IIF(Checks.void,STR(1),STR(0)) + ",'"+ ;
		ALLTRIM(pc_userid) + "', "+ALLTRIM(STR(Checks.check_no))+", '"+ALLTRIM(Checks.cl_code)+"', "+ALLTRIM(STR(Checks.tag)))
ELSE
	gfmessage("Cannot locate the check in the files" )
ENDIF
SELECT (lnArea)
RETURN
************************************************

FUNCTION words
PARAMETER mamt

camt = ""
STORE "     ONE  TWO  THREEFOUR FIVE SIX  SEVENEIGHTNINE " TO ones
STORE "TEN      ELEVEN   TWELVE   THIRTEEN FOURTEEN FIFTEEN  SIXTEEN  "+;
"SEVENTEENEIGHTEEN NINETEEN " TO teen
STORE "TWENTY THIRTY FORTY  FIFTY  SIXTY  SEVENTYEIGHTY NINETY" TO tens
cnum = LEFT( STR( mamt, 9, 2), 6)
IF LEFT( cnum, 1) > " "
	camt = RTRIM( SUBSTR( ones, VAL( LEFT( cnum, 1))*5+1, 5)) + " HUNDRED "
ENDIF
DO CASE
	CASE SUBSTR( cnum, 2, 1) > "1"
		camt = camt + RTRIM( SUBSTR( tens, VAL( SUBSTR( cnum, 2,1))*7-13, 7))
		IF SUBSTR( cnum, 3, 1) > "0"
			camt = camt + "-" + RTRIM( SUBSTR( ones, VAL( SUBSTR( cnum, 3,1))*5+1, 5))
		ENDIF
		camt = camt + " THOUSAND "
	CASE SUBSTR( cnum, 2, 1) = "1"
		camt = camt + RTRIM( SUBSTR( teen, VAL( SUBSTR( cnum, 3, 1))*9+1, 9)) ;
		+ " THOUSAND "
	CASE SUBSTR( cnum, 2, 2) = "00"
		camt = camt + "THOUSAND "
	CASE SUBSTR( cnum, 3, 1) > " "
		camt = camt + RTRIM( SUBSTR( ones, VAL( SUBSTR( cnum, 3, 1))*5+1, 5)) ;
		+ " THOUSAND "
ENDCASE
IF SUBSTR( cnum, 4, 1) > "0"
	camt = camt + RTRIM( SUBSTR( ones, VAL( SUBSTR( cnum, 4, 1))*5+1, 5)) ;
	+ " HUNDRED "
ENDIF
DO CASE
	CASE SUBSTR( cnum, 5, 1) > "1"
		camt = camt + RTRIM( SUBSTR( tens, VAL( SUBSTR( cnum, 5, 1))*7-13, 7))
		IF RIGHT( cnum, 1) > "0"
			camt = camt + "-" + RTRIM( SUBSTR( ones, VAL( RIGHT( cnum, 1))*5+1, 5))
		ENDIF
	CASE SUBSTR( cnum, 5, 1) = "1"
		camt = camt + RTRIM( SUBSTR( teen, VAL( RIGHT( cnum, 1))*9+1, 9))
	CASE RIGHT( cnum, 2) = " 0"
		camt = "ZERO"
	OTHERWISE
		camt = camt + RTRIM( SUBSTR( ones, VAL( RIGHT( cnum, 1))*5+1, 5))
ENDCASE
cents = RIGHT(  STR( mamt, 9, 2), 2)
camt = RTRIM( camt)+ " AND " + cents + "/100 DOLLARS"
STRING = SPACE(62)
LENGTH = LEN( camt)
RETURN camt
*****************************************************
**not used anymore in any of the KOP offices: all checks print the same way
************************************************************************
*!*	PROCEDURE prtChk

*!*		PARAMETERS lcCode, lnTag, lnCheck, lnAmount, lnLrs, lcOffice, lcRqName, ;
*!*			lcChkName, lcWorker, lcCourt, lcInvoice, ldCheck, llChkBad, lcDepon, ;
*!*			lcAdd1, lcAdd2, lcAdd3, lcAdd4, lcAtten, llPrepay, llLastChk

*!*		PRIVATE lcWords, recstat, maildstr, offstr, ldHandSrv
*!*		ots = CREATEOBJECT("medtimesheet")
*!*		IF NOT llChkBad
*!*			lcWords = words(lnAmount)
*!*		ELSE
*!*			lcWords = "*** VOID *** VOID *** VOID *** VOID *** VOID ***"
*!*		ENDIF

*!*		SELECT Checks

*!*		* 04/14/04 DMA Re-format for long plaintiff names
*!*		?""
*!*		?""
*!*		?""
*!*		?""
*!*		? "RE: " + ALLT( UPPER (lcChkName)) + "  " + ALLT( STR( lnLrs)) + ;
*!*			+ "." + TRANS( lnTag, "@L 999") AT 5
*!*		?? lnCheck PICT "########" AT 110
*!*		?" "
*!*		IF NOT EMPTY( lcInvoice)
*!*			?? "Invoice #:" AT 5, ALLTRIM( lcInvoice) PICT "!!!!!!!!!!!!!!!" AT 17
*!*		ENDIF
*!*		? " "
*!*		? ALLTRIM( lcWords) PICT "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" AT 12
*!*		? TRANSFORM( ldCheck, "##/##/##") AT 92

*!*		IF llChkBad
*!*			?"*** VOID *** VOID *** VOID *** VOID *** VOID ***"
*!*		ELSE
*!*			? lcDepon PICT "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" AT 15, ;
*!*				lnAmount PICT "$$$$.##" AT 118
*!*		ENDIF

*!*		nn=0
*!*		?
*!*		IF NOT EMPTY( lcAdd1)
*!*			? " " + lcAdd1 PICT "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" AT 8
*!*		ELSE
*!*			nn = nn + 1
*!*		ENDIF
*!*		IF NOT EMPTY( lcAdd2)
*!*			? " " + lcAdd2 PICT "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" AT 8
*!*		ELSE
*!*			nn = nn + 1
*!*		ENDIF

*!*		IF NOT llChkBad
*!*			IF NOT EMPTY( lcAdd3)
*!*				? " " + lcAdd3 PICT "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" AT 8
*!*			ELSE
*!*				nn = nn + 1
*!*			ENDIF
*!*		ELSE
*!*			? "*** VOID *** VOID *** VOID ***" AT 45
*!*		ENDIF

*!*		IF NOT EMPTY( lcAdd4)
*!*			? " " + lcAdd4 PICT "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" AT 8
*!*		ELSE
*!*			nn = nn + 1
*!*		ENDIF
*!*		DO WHILE nn > 0
*!*			? " "
*!*			nn = nn - 1
*!*		ENDDO
*!*		? "Attn:    " + ALLTRIM( lcAtten) AT 3

*!*		FOR i = 1 TO 4
*!*			? " "
*!*		NEXT

*!*		******* Print Invoice Information ***************
*!*		?
*!*		?
*!*		?
*!*		?
*!*		? "DATE:" AT 5, d_today PICT "@d" AT 14
*!*		? " "
*!*		recstat = " "
*!*		maildstr = ""
*!*		IF NOT EMPTY( lcCode) AND NOT EMPTY( lnTag)
*!*			recstat = gfrstat( Checks.cl_code, Checks.TAG)
*!*		ENDIF

*!*		*--2/23/06 dma Add cancelled tags to list
*!*		*--8/14/03 kdl start: Add first-look to list
*!*		IF INLIST( recstat, "R", "N", "F", "C")
*!*			*IF INLIST( recstat, "R", "N", "F")
*!*			*--kdl out 8/14/03: IF INLIST( recstat, "R", "N")
*!*			maildstr = "Mail date: " + DTOC(CTOD(ldCheck) + 20)
*!*			*   maildstr = "Mail date: " + dtoc(ldCheck + 30)
*!*		ENDIF

*!*		l_RecSt= ots.sqlexecute("SELECT dbo.fn_GetStatusDesc ('" + RECORD.STATUS + "','"  ;
*!*			+ ALLTRIM(RECORD.nrs_code) + "'," +  IIF(RECORD.inc, STR(1),STR(0))+ ")", "RecStatus")
*!*		IF  l_RecSt
*!*			c_status=ALLTRIM(RecStatus.EXP)
*!*		ENDIF

*!*		IF NOT EMPTY( recstat)
*!*			recstat = ALLTRIM(c_status) &&StatDesc( recstat, "")
*!*		ENDIF

*!*		? "Status: " + recstat + "    " + maildstr AT 8

*!*		offstr = "Office: " + lcOffice

*!*		? "Case:" AT 7, ;
*!*			ALLT( lcChkName) PICT "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" AT 18,;
*!*			offstr AT 99

*!*		? " "
*!*		? "COURT: " AT 7, lcCourt PICT "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" AT 22
*!*		? "AMOUNT: " at 7, lnAmount at 22
*!*		IF NOT EMPTY( lcInvoice)
*!*			? "INVOICE: " AT 7, lcInvoice PICT "!!!!!!!!!!!!!!!" AT 22
*!*		ELSE
*!*			? " "
*!*		ENDIF
*!*		? "VOUCHER NUMBER:" AT 7, lnCheck PICT "##########" AT 32,;
*!*			"RT PREPARER:" AT 58, LEFT( lcWorker, 20) AT 85
*!*		? " "
*!*		? "RT #:" AT 7, ;
*!*			lnLrs PICT "########" AT 14, ;
*!*			"Tag:" AT 25, ;
*!*			lnTag PICT "###" AT 30, ;
*!*			"REQUESTING ATT.:" AT 58, ;
*!*			lcRqName PICT "!!!!!!!!!!!!!!!!!!!!" AT 85

*!*		IF llPrepay
*!*			? "FEE HAS BEEN PREPAID"
*!*		ELSE
*!*			? " "
*!*		ENDIF

*!*		IF n_chkoffc = 3                                && Oakland
*!*			ldHandSrv = gfHServe( lcCode, lnTag)
*!*			? DTOC( ldHandSrv)
*!*			FOR counter = 1 TO 7
*!*				? " "
*!*			NEXT
*!*		ELSE
*!*			FOR counter = 1 TO 8
*!*				? " "
*!*			NEXT
*!*		ENDIF
*!*		DO ChkUpdate
*!*		*SELECT Checks
*!*		*IF SEEK( lnCheck)
*!*		*IF Checks.check_no = lnCheck
*!*		* 06/10/05 DMA Add Record Locking
*!*		* DO WHILE NOT RLOCK()
*!*		* ENDDO
*!*		*REPLACE Checks.printed WITH .T.
*!*		*REPLACE Checks.print_date WITH d_today
*!*		*IF llChkBad
*!*		*IF NOT Checks.void
*!*		*  REPLACE Checks.void WITH .T.
*!*		* ENDIF
*!*		*IF EMPTY( Checks.void_date)
*!*		* REPLACE Checks.void_date WITH d_today
*!*		*ENDIF
*!*		*ENDIF
*!*		*UNLOCK
*!*		*ENDIF
*!*		*ENDIF

*!*		IF llLastChk
*!*			? _pprnReset
*!*		ELSE
*!*			EJECT
*!*		ENDIF

*!*		RETURN


PROCEDURE printMessage
LPARAMETERS lcCase, lcPhoneNum
lcFaxNum="610-354-8946 (preferred)"
IF ALLTRIM(UPPER(viewOfficeAddr.code))<>"P"
   lcPhoneNum=ALLTRIM(viewOfficeAddr.loclHPhone)
   lcPhoneNum=STRTRAN(lcPhoneNum,")")
   lcPhoneNum=STRTRAN(lcPhoneNum,"(")
   lcPhoneNum=STRTRAN(lcPhoneNum," ")  
   lcPhoneNum=STRTRAN(lcPhoneNum,"-")  
   lcFaxNum=viewOfficeAddr.loclHAmFax
   lcFaxNum=STRTRAN(lcFaxNum,")")
   lcFaxNum=STRTRAN(lcFaxNum,"(")
   lcFaxNum=STRTRAN(lcFaxNum," ")  
   lcFaxNum=STRTRAN(lcFaxNum,"-")  
   lcFaxNum=SUBSTR(ALLTRIM(lcFaxNum),1,3)+"-"+SUBSTR(ALLTRIM(lcFaxNum),4,3)+"-"+SUBSTR(ALLTRIM(lcFaxNum),7,4)
ENDIF     
 lcPhoneNum=SUBSTR(ALLTRIM(lcPhoneNum),1,3)+"-"+SUBSTR(ALLTRIM(lcPhoneNum),4,3)+"-"+SUBSTR(ALLTRIM(lcPhoneNum),7,4)
 
?
?"Dear "+PROPER(ALLTRIM(checks.spokeTo))+"," at 5
?
?"Thank you for speaking to us today.  Attached is a check, per your instructions, for " at 5
?"the fee associated with the release of "+PROPER(ALLTRIM(checks.payingFor))+" pertaining to "+PROPER(ALLTRIM(lcCase)) at 5
?
?"Please send the requested items and the signed certification as soon as possible." at 5
?" Fax to: "+ALLTRIM(lcFaxNum) at 13
   
?"Mail to: RecordTrak" at 13
IF !EMPTY(ALLTRIM(NVL(viewOfficeAddr.loclH1,""))) or !EMPTY(ALLTRIM(NVL(viewOfficeAddr.loclH2,"")))
   ?ALLTRIM(NVL(viewOfficeAddr.loclH1,""))+" "+ALLTRIM(NVL(viewOfficeAddr.loclH2,"")) at 20
ENDIF 
IF !EMPTY(ALLTRIM(NVL(viewOfficeAddr.loclHBox,"")))
   ?ALLTRIM(viewOfficeAddr.loclHBox) at 20
ENDIF 
IF !EMPTY(ALLTRIM(NVL(viewOfficeAddr.loclH3,""))) OR !EMPTY(ALLTRIM(NVL(viewOfficeAddr.loclH4,""))) OR !EMPTY(ALLTRIM(NVL(viewOfficeAddr.loclH5,"")))
   ?ALLTRIM(NVL(viewOfficeAddr.loclH3,""))+" "+ALLTRIM(NVL(viewOfficeAddr.loclH4,""))+" "+ALLTRIM(NVL(viewOfficeAddr.loclH5,"")) at 20
ENDIF 
?"Please contact us with any questions at "+ALLTRIM(lcPhoneNum) at 5
?
?"Thank you," at 5
?"RecordTrak" at 5
?
?"------------------------------------------------------------------------------------------------------------------------" at 5
?
