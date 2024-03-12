#INCLUDE App.h
*____________________________________________________________________
*____________________________________________________________________
* PROGRAM - Action Taker
*
*	Note :
*		Set TAB width to 2 for viewing this & all other files in this 
*		project
*
*		This Program fires code based on a menu selection
*
*____________________________________________________________________
LParameters tsPad, tnBar
Local llAvail, loMediator

*//Setup
llAvail = .T.
tsPad = AllTrim(Upper(tsPad))

*//Take Action
DO CASE

	*//-------------
	*//FILE menu pad
	*//-------------
	CASE (tnBar == MENU_BAR_CASE_DATA_CASE_INSTRUCTIONS)
		goApp.OpenForm("caseinstructions.frminstructions", "S")

	CASE (tnBar == MENU_BAR_DEPREQ_ADD_NEW_NO_ISSUE)
		goApp.OpenForm("deponents.frmAddDeponent","S")

	CASE (tnBar == MENU_BAR_FILE_LOGIN_USER)
		= AppLogin()
	CASE (tnBar == MENU_BAR_CASE_DATA_PRIMARY_CASE_INFO)
		goApp.OpenForm("tamaster.frmtamasteredit")
	CASE (tnBar == MENU_BAR_CASE_DATA_ADDITIONAL_CASE_INFO)
		goApp.OpenForm("additionalcaseinfo.frmadditionalcaseinfo")
	CASE (tnBar == MENU_BAR_DEPREQ_ADD_NEW_ISSUE_SUBPOENA)
		goApp.OpenForm("issueSubpoena.frmIssueSubpoena")
	CASE (tnBar == MENU_BAR_DEPREQ_ADD_NEW_ISSUE_AUTH)
		goApp.OpenForm("issueAuth.frmIssueAuth")
	CASE (tnBar == MENU_BAR_DEPREQ_DEP_SUM)
		goApp.OpenForm("depSummary.frmDepSummary")
	CASE (tnBar == MENU_BAR_DEPREQ_VIEW_TAG_0)
		goApp.OpenForm("viewTag0.frmviewTag0")
	CASE (tnBAr == MENU_BAR_DEPREQ_VIEW_ALL)
		goApp.OpenForm("viewAllTransactions.frmViewAllTrans")
	CASE (tnBar == MENU_BAR_DEPREQ_VIEW_RECEIVED_MATERIALS)
		goApp.OpenForm("viewrecmat.frmviewrecmat")
	CASE (tnBar == MENU_BAR_DEPREQ_VIEW_DEP_CAT)
		goApp.OPenForm("viewdepCat.frmViewDepCat")
	CASE (tnBar == MENU_BAR_DEPREQ_VIEW_DEL_DEP)
		goApp.OpenForm("viewrecalledDep.frmViewrecalledDep")
	CASE (tnBar == MENU_BAR_COURT_DOC_WAV_REC)
		goApp.OpenForm("wavierrec.frmWavierRec")
	CASE (tnBar == MENU_BAR_COURT_DOC_PRINT_NOTICES)
		goApp.openform("printNotices.frmPrintNotices")
	CASE (tnBar == MENU_BAR_ATT_ORDER_PART_ATT)
		goApp.openForm("partAttorney.frmpartattorney")
	CASE (tnBar == MENU_BAR_ATT_ORDER_ASBESTOS_COST_SHARING)
		goApp.OpenForm("asbestosca.frmasbestosca")
	CASE (tnBar == MENU_BAR_CODE_PRINT_AUTH OR ;
		  tnBar == MENU_BAR_CODE_PRINT_INTERROGATORY OR ;
		  tnBar == MENU_BAR_CODE_PRINT_ATT_CORRES OR ;
		  tnBar == MENU_BAR_CODE_PRINT_STATUS_COUNSEL OR ;
		  tnBar == MENU_BAR_CODE_PRINT_RECS_RECEIVED)
		goApp.OpenForm("barCodePrint.frmBarCodePrint")
	CASE (tnBar == MENU_BAR_BATES_PRINT_LABELS OR ;
	      tnBar == MENU_BAR_BATES_ADD_TAGS)
	      goApp.openForm("batesInfo.frmBatesInfo")
	CASE (tnBar == MENU_BAR_FILE_EXIT)
	  goApp.ExitSystem()

OTHERWISE

	= MLMsg("Invalid Option: " + CHR(13) + tsPad + " - " + AllTrim(Str(tnBar)))

ENDCASE

RETURN

** EOF **
