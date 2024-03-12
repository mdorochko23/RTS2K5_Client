FUNCTION gfChkPln
* Purpose   Check all billing plans referenced by attorneys in the current
*           case to ensure that none are inactive or missing,
*			and reports problems on screen.

*           Assumes that gfGetCas has been previously called.

*  Called by Master.vcx / frmMasterMirror.Init()
*  Called by gfReOpen, TagMirr, SetOrdTg
*     06/19/2014  EF - added stored procs adn functions
*	12/06/2005	DMA Add check to see if case has no attorneys for fast exit
*					Modify SQL statements to skip deleted/retired attorneys
*	12/05/2005	DMA	Remove message for cases w/o any attorneys
*	08/12/2005	EF	Converted for VFP RTS
*	06/09/2004  EF  When Issuing a new tag, display a warning msg for ordering attys only
*	02/11/2004  DMA Remove checks on case-level plan value
*                   Add handler for missing plans.
*	01/08/2004  DMA Convert to function w/return value
*	12/24/2003  DMA Initial coding in FoxPro 2.6 for old RTS

LPARAMETERS lOrdAtty
** lOrdAtty = .T. if called from subp_pa during issue of new tag. Program will
** only check the plans for ordering attorneys, and skips all others;
** lOrdAtty = .F. in all other situations. Program will examine all attorneys, even
** if they are not ordering.

LOCAL	n_curarea, ;
	c_Msg, ;
	l_Problem AS Boolean, ;
	lcSQLLine, ;
	o_Message AS OBJECT, ;
	oMedr AS medrequest OF REQUEST

* Initialization
l_Problem = .F.
n_curarea = SELECT()
oMedr = CREATEOBJECT( "medrequest")

* Determine if the case has any participants. If not, program can exit
* without doing a lot of work.

SELECT 0
*!*	lcSQLLine = "SELECT COUNT(at_code) AS NumAttys FROM tblBill" + ;
*!*		" WHERE cl_code = '" + pc_clcode + "' AND Active = 1" + ;
*!*		" AND ISNULL(Retire, 0) = 0"

lcSQLLine = "SELECT [dbo].[GetBillAttycnt] ('" +  fixquote(pc_clcode )+ "')"
oMedr.SQLExecute( lcSQLLine, "HaveBill")
IF NVL(HaveBill.EXP,0) = 0 THEN
	SELECT HaveBill
	USE
	SELECT (n_curarea)
	RETURN l_Problem
ENDIF


*!*	lcSQLLine = "SELECT * FROM tblBill WHERE cl_code = '" + ;
*!*		pc_clcode + "' AND Active = 1 AND ISNULL( Retire,0) = 0" + ;
*!*		" ORDER BY at_code"


lcSQLLine = "exec dbo.getparticipatingbyclcode '" +  fixquote(pc_clcode ) + "'"
oMedr.SQLExecute( lcSQLLine, "ChekBill")

IF USED("ChekBill") AND NOT EOF()

* Check all plans listed in TABills for attorneys in this case

	SELECT ChekBill
	SCAN
		IF lOrdAtty AND INLIST( ChekBill.response, "S", "F", "C")
* do nothing
		ELSE
			c_Msg = "This plan is used by attorney " + ;
				ALLT( ChekBill.At_Code) + "."
			l_Problem = ChekPlan( ChekBill.Plan, .F., c_Msg)
		ENDIF
		SELECT ChekBill
	ENDSCAN

* Cleanup and exit
	SELECT HaveBill
	USE
	SELECT ChekBill
	USE

ENDIF
RELEASE oMedr
SELECT( n_curarea)
RETURN l_Problem

******************************************************************************

FUNCTION ChekPlan
LPARAMETER c_PlanID, l_Case, c_Msg
* c_PlanID is the Plan code for lookup
* l_Case is .T. for case-level and .F. for attorney-level

LOCAL oMedr AS medrequest OF REQUEST
LOCAL l_BadPlan AS Boolean, n_curarea

* 12/06/05 DMA Use rts_message instead of wait window
* If no plan was assigned to the attorney, respond now and skip the SQL activity
IF EMPTY( ALLTRIM( c_PlanID)) THEN
	l_BadPlan = .T.
	o_Message = CREATEOBJECT( 'rts_message', ;
		" No billing plan has been specified " ;
		+ IIF( l_Case, "at the case level.", ;
		"for attorney " + ALLT( ChekBill.At_Code) + ".") + CHR(13) + ;
		"Please correct this problem or report the case" + ;
		IIF( l_Case, "", " and attorney") + ;
		+ " to the Billing Department Supervisor.")
	o_Message.CAPTION = "WARNING"
	o_Message.SHOW()
	RETURN l_BadPlan
ELSE
	l_BadPlan = .F.
ENDIF

oMedr = CREATEOBJECT( "medrequest")

SELECT 0
lcSQLLine = "SELECT dbo.fn_GetPlanStatus ('" + c_PlanID + "')"
oMedr.SQLExecute( lcSQLLine, "CheckAct")

SELECT CheckAct

* 12/05/05 DMA Add check for null value; set up CASE statement
* 12/06/05 DMA Use rts_message instead of wait window
DO CASE

CASE ISNULL( CheckAct.EXP)
* Plan was specified in tblBill, but is not in tblPlan.
	l_BadPlan = .T.
	o_Message = CREATEOBJECT( 'rts_message', ;
		"Plan (" + c_PlanID ;
		+ ") is no longer in the system." + CHR(13) + c_Msg ;
		+ CHR(13) + "Please notify the Billing Department Supervisor" + ;
		+ " of the case number" ;
		+ IIF( l_Case, "", ", attorney code,") + " and plan code.")
	o_Message.CAPTION = "WARNING"
	o_Message.SHOW()

CASE CheckAct.EXP = .F.
* Plan is listed in tblPlan, but marked as inactive
	l_BadPlan = .T.
	o_Message = CREATEOBJECT( 'rts_message', "Plan (" + c_PlanID ;
		+ ") is inactive." + CHR(13) + c_Msg ;
		+ CHR(13) + "Please notify the Billing Department Supervisor" + ;
		+ " of the case number" ;
		+ IIF( l_Case, "", ", attorney code,") + " and plan code.")
	o_Message.CAPTION = "WARNING"
	o_Message.SHOW()

CASE CheckAct.EXP = .T.
* Fall through if plan is in the file and is active.
ENDCASE
RELEASE oMedr
IF (USED('checkact'))
	USE IN CheckAct
ENDIF
RETURN l_BadPlan

