FUNCTION gfChkPln2
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

LOCAL lsLastPlanChk as string, lsPlan as string		&& 01/28/2020, zd #160060, JH
LOCAL lsMissPlans as String, liMissPlans as Integer
lsLastPlanChk = "#%&"
lsMissPlans = ""
liMissPlans = 0										&& 01/28

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
			lsPlan = ALLTRIM(NVL(ChekBill.Plan,''))				&& 01/28/2020, ZD #160060, JH
			IF LEN(lsPlan) = 0									&& 01/28
				IF liMissPlans > 0								&& 01/28
				   lsMissPlans = lsMissPlans+", "
				ENDIF
				lsMissPlans = lsMissPlans+"("+ChekBill.At_Code+")"	&& 01/28
				liMissPlans = liMissPlans+1							&& 01/28
			ELSE	
				IF ((lsPlan <> lsLastPlanChk))   				&& 01/28
					c_Msg = "This plan is used by attorney " + ALLT(ChekBill.At_Code) + "."
					l_Problem = ChekPlan2(lsPlan,.F., c_Msg)		&& 01/28
					lsLastPlanChk = lsPlan							&& 01/28
				ENDIF
			ENDIF
		ENDIF
		SELECT ChekBill
	ENDSCAN
	IF liMissPlans > 0 									&& 01/28/2020, ZD #160060, JH
		c_Msg = lsMissPlans								&& 01/28
		lsPlan = ''										&& 01/28
		l_Problem = ChekPlan2(lsPlan,.F., c_Msg)		&& 01/28
	ENDIF												&& 01/28

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

FUNCTION ChekPlan2
LPARAMETER c_PlanID, l_Case, c_Msg
* c_PlanID is the Plan code for lookup
* l_Case is .T. for case-level and .F. for attorney-level

LOCAL oMedr AS medrequest OF REQUEST
LOCAL l_BadPlan AS Boolean, n_curarea
LOCAL li_RetPlanChk AS Integer	
LOCAL ls_WarnMsg as String

* 12/06/05 DMA Use rts_message instead of wait window
* If no plan was assigned to the attorney, respond now and skip the SQL activity
IF EMPTY( ALLTRIM( c_PlanID)) THEN
	l_BadPlan = .T.
*	o_Message = CREATEOBJECT( 'rts_message', ;
*		" No billing plan has been specified " ;
*		+ IIF( l_Case, "at the case level.", "for attorney " + ALLT( ChekBill.At_Code) + ".") + CHR(13) + ;
*		"Please correct this problem or report the case" + ;
*		IIF( l_Case, "", " and attorney") + ;
*		+ " to the Billing Department Supervisor.")
	o_Message = CREATEOBJECT( 'rts_message', ;
		" No billing plan at the case level has been specified for the following attorneys: "+CHR(13)+c_Msg+"." ;
		+ CHR(13)+ CHR(13) + "Please correct this problem or report the case" + ;
		IIF( l_Case, "", " and attorney(s)") + ;
		+ " to the Billing Department Supervisor.")
	o_Message.CAPTION = "WARNING"
	o_Message.SHOW()
	RETURN l_BadPlan
ELSE
	l_BadPlan = .F.
ENDIF

oMedr = CREATEOBJECT( "medrequest")

SELECT 0
**lcSQLLine = "SELECT dbo.fn_GetPlanStatus ('" + c_PlanID + "')"				&& 11/04/2019, zd 148856, JH
lcSQLLine = "SELECT dbo.fn_GetPlanStatusInactRetDel ('" + c_PlanID + "')"		&& 11/04/2019, zd 148856, JH
oMedr.SQLExecute( lcSQLLine, "CheckAct")

SELECT CheckAct
li_RetPlanChk = CheckAct.EXP													&& 11/04/2019, zd 148856, JH
IF li_RetPlanChk > 0
	l_BadPlan = .T.
	ls_WarnMsg = "Plan (" + c_PlanID + ") "+ gfchkpln2_msg(li_RetPlanChk)+CHR(13)+CHR(13)+"Please notify the Billing Department Supervisor" ;
		+ " with this case number" + IIF(l_Case, "", ", attorney "+ALLT( ChekBill.At_Code)) ;
		+  " and plan code."+CHR(13)+CHR(13) ;
	   + "Other attorneys on this case may also have this same plan and error too."
	o_Message = CREATEOBJECT( 'rts_message', ls_WarnMsg)
	o_Message.CAPTION = "WARNING"
	o_Message.SHOW()
ENDIF																			&& 11/04/2019

* 12/05/05 DMA Add check for null value; set up CASE statement
* 12/06/05 DMA Use rts_message instead of wait window
*DO CASE
*CASE ISNULL( CheckAct.EXP)
** Plan was specified in tblBill, but is not in tblPlan.
*	l_BadPlan = .T.
*	o_Message = CREATEOBJECT( 'rts_message', ;
*		"Plan (" + c_PlanID ;
*		+ ") is no longer in the system." + CHR(13) + c_Msg ;
*		+ CHR(13) + "Please notify the Billing Department Supervisor" + ;
*		+ " of the case number" ;
*		+ IIF( l_Case, "", ", attorney code,") + " and plan code.")
*	o_Message.CAPTION = "WARNING"
*	o_Message.SHOW()
*
*CASE CheckAct.EXP = .F.
** Plan is listed in tblPlan, but marked as inactive*
*	l_BadPlan = .T.
*	o_Message = CREATEOBJECT( 'rts_message', "Plan (" + c_PlanID ;
*		+ ") is inactive." + CHR(13) + c_Msg ;
*		+ CHR(13) + "Please notify the Billing Department Supervisor" + ;
*		+ " of the case number" ;
*		+ IIF( l_Case, "", ", attorney code,") + " and plan code.")
*	o_Message.CAPTION = "WARNING"
*	o_Message.SHOW()
*
*CASE CheckAct.EXP = .T.
* Fall through if plan is in the file and is active.
*ENDCASE

RELEASE oMedr
IF (USED('checkact'))
	USE IN CheckAct
ENDIF
RETURN l_BadPlan

