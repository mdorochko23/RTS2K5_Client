#INCLUDE APP.h
*____________________________________________________________________
*____________________________________________________________________
* PROGRAM - Action Taker
*
*	Note :
*		Set TAB width to 2 for viewing this & all other files in this
*		project
*
*		This Program fires code based on a menu selection
*       Uses method OpenForm in Base.vcx / CusApp, with parameters:
*				psClass - (Class library and Class) [no default]
*					Must be in format "myclasslib.myclass"
*				psFlags - (options string) [defaults to ""]
*					M = Show via modalret method
*					S = Allow only a Single Instance
*					I = Invisible (do not automatically show form)
*					O = Return object reference instead of ID. (Only for non-modal forms)
*				p_xID - (Instance ID) [defaults to ""]
*					If passed and ID already exists, form is shown.
*
*   History
*   DMA   08/17/05  Reorganize and comment for clarity
*                   Some changes to menu bar names in Main and Case menus
*___________________________________________________________________
*
*   08/27/2007 EF - Edited to allow an issue from the Deponent Screen
*   05/23/2006 MD - Added print Bar Code options, Recall Deleted Tag
*   05/18/2006 EF - Added Client Rep. options
*   05/17/2006 EF - Added Review Deponents by Category
*   05/11/2006 EF - Added the "Reprint Texas Request Documnets"
*   05/09/2006 EF - Added 'Reprint certifications'
*   05/09/2006 EF - Activated the 'Update Request Type (Authorization/Subpoena' item.
*   05/05/2006 KL - Added Bates Label file maintenance
*   04/25/2006 EF - Added Checks Ptinting option
*   04/13/2006 EF - Added Checks Void/Clear options
*   04/11/2006 EF - Added 'Notice Production' for the CA offices.
*   03/16/2006 EF - added 'Notice Production' for the Texas office.
*  	02/09/2006 kl - activate the case instructions memu options
*   01/27/2006 EF - activated "Print Notice" menu
*  	01/18/2006 kl - removed otherwise condition do to incorect calls from popups
*	12/30/2005 MD - added RCUWand option to Data\Administrative Utilities Menu
*					added View X-Rays & Pathology Slides to Cases\Document Proc\ Menu
*

LPARAMETERS tsPad, tsPrompt
LOCAL llAvail, loMediator
*//Setup
llAvail = .T.
tsPad = ALLTRIM(UPPER(tsPad))
tsPrompt = ALLTRIM(UPPER(tsPrompt))
SET CENTURY ON
DO getsqldate
*--d_today = DATE()                             && Refresh every pass through loop in case user
*--c_today = DTOC(d_today)                      && left machine on overnight.

SET EXACT OFF
*//Take Action
DO CASE
**4/25/06 -ADDED 'Printing Checks' option
**4/13/06 -added 'Check processing'
CASE tsPad = "CHKPROCESS"
	DO CASE
	CASE (tsPrompt) = "PROCESSING"
		DO clearchk.prg
	CASE (tsPrompt) = "PRINTING"
		DO laserchk.prg
	CASE (tsPrompt) = "RESTORING"
		goApp.OpenForm("Generic.frmRestoreCheck", "S")
	CASE ALLTRIM(UPPER(tsPrompt))==UPPER("Invoice Printing")
		o_frm=CREATEOBJECT('depdisposition.frmprintinvoicerange')
		o_frm.SHOW
	ENDCASE
**4/12/06 - added a new menu
CASE tsPad = "ACCTMGRUTIL"

	DO CASE
	CASE ALLTRIM(UPPER(tsPrompt))="CHARITE DISK UPDATE REQUESTS" && added Charite Disk Update Requests 4/30/2010
		DO StartIt IN cadissue

	CASE ALLTRIM(UPPER(tsPrompt))="FLAVORING REQUEST BATCH"
		DO StartIt IN flrissue

	CASE UPPER(tsPrompt) = "ADD NEW ATTORNEY TO GROUP OF CASES"
		goApp.OpenForm("Generic.frmcasefilt", "S", 1,1)
	CASE ALLTRIM(UPPER(tsPrompt))="EDIT ATTORNEY INFO AND ORDERS"
		goApp.OpenForm("Generic.frmcasefilt", "S", 2,2)
	CASE ALLTRIM(UPPER(tsPrompt))="GLOBAL TAG CANCELLATION"
		DO globalTagCancel
*CASE ALLTRIM(UPPER(tsPrompt))="ADD NEW AREA"
**11/13/2012- disabled per Alec
*goApp.OpenForm("utility.frmAddNewArea", "S")
	CASE ALLTRIM(UPPER(tsPrompt))=UPPER("Post Old CA Images")
		llOldCaExit=.F.
		DO WHILE llOldCaExit=.F.
			DO postOldCAImg
			IF gfMessage("Continue?",.T.)=.F.
				llOldCaExit=.T.
			ENDIF
		ENDDO
	CASE ALLTRIM(UPPER(tsPrompt)) = UPPER("New Tag Solicitation Job")
		IF NOT NVL(goApp.CurrentUser.orec.AcctMgr,.F.)
			gfMessage("You do not have access rights for this option")
			RETURN
		ELSE
			SET CLASSLIB TO UTILITY ADDIT
			o_frm=CREATEOBJECT('utility.frmsolicitation')
			o_frm.SHOW
		ENDIF
	CASE ALLTRIM(UPPER(tsPrompt)) = UPPER("New Case Solicitation Job")
		IF NOT NVL(goApp.CurrentUser.orec.AcctMgr,.F.)
			gfMessage("You do not have access rights for this option")
			RETURN
		ELSE
			SET CLASSLIB TO UTILITY ADDIT
			o_frm=CREATEOBJECT('utility.frmsolicitationcase')
			o_frm.SHOW
*!*				gfmessage("Not available at this time. Under construction")
*!*				return
		ENDIF
	CASE ALLTRIM(UPPER(tsPrompt)) = UPPER("Solicitation Job Status Update")
		SET CLASSLIB TO UTILITY ADDIT
		o_frm=CREATEOBJECT('utility.frmsoljobstatus')
		o_frm.SHOW
	CASE ALLTRIM(UPPER(tsPrompt)) = UPPER("Add Custom Bates Litigation/Area")
		IF NOT NVL(goApp.CurrentUser.orec.AcctMgr,.F.)
			gfMessage("You do not have access rights for this option")
			RETURN
		ELSE
			SET CLASSLIB TO CASE ADDIT
			o_rt= CREATEOBJ("case.frmbatescasesetup")
			o_rt.SHOW
		ENDIF
	CASE ALLTRIM(UPPER(tsPrompt)) = UPPER("Case Image Batch Archive/Un-Archive")
*IF NOT goApp.CurrentUser.ntlogin="KIRK"
		IF NOT NVL(goApp.CurrentUser.orec.AcctMgr,.F.)
			gfMessage("You do not have access rights for this option")
			RETURN
		ELSE
			SET CLASSLIB TO UTILITY ADDIT
			o_rt= CREATEOBJ("utility.frmarchimage")
			o_rt.SHOW
		ENDIF
	CASE ALLTRIM(UPPER(tsPrompt)) = UPPER("Case Image Un-Archive")
		IF NOT NVL(goApp.CurrentUser.orec.AcctMgr,.F.)
			gfMessage("You do not have access rights for this option")
			RETURN
		ELSE
			SET CLASSLIB TO UTILITY ADDIT
			o_rt= CREATEOBJ("utility.frmcaseunarch")
			o_rt.SHOW
		ENDIF
	OTHERWISE
		goApp.OpenForm("Generic.frmcasefilt", "S", 3,3)

	ENDCASE

**5/18/06

CASE tsPad = "GENERALUTI"

	DO CASE
**03/04/16- added Update Rq Atty-
	CASE UPPER(tsPrompt) ="UPDATE REQUESTING ATTY (TAG LEVEL)"
		goApp.OpenForm("generic.frmupdrq ", "M")
**12/7/15- added Add Subpoena Fees -Zendesk#24137
	CASE UPPER(tsPrompt) ="ADD SUBPOENA FEES"
		goApp.OpenForm("utility.frmsubpfee ", "M")
*	02/17/14- MRC bulk processing
	CASE UPPER(tsPrompt) ="LOAD MRC CASES"
		IF NOT (ALLTRIM(NVL(goApp.CurrentUser.orec.DEPT,''))<>'IT')
			gfMessage("You do not have access rights for this option")
			RETURN
		ELSE
			DO mrcaddcase WITH '262514'
		ENDIF
	CASE UPPER(tsPrompt) ="ADD WAIT TAGS (MRC)"
		DO mrcWtag
&&view jobs in the 'HOLDPRINT' queue in the RPS

	CASE UPPER(tsPrompt) ="VIEW RPS JOBS ON HOLD"
*goapp.OpenForm("qcaipjobs.frmRPSHOLDJOBS ", "M", DATE(), DATE())
**04/29/15- added risp/pccp tab
		goApp.OpenForm("issued.frmRPSHOLDJOBS ", "M", DATE(), DATE())
	CASE UPPER(tsPrompt) ="PRINT MD RELEASE LETTERS"
		goApp.OpenForm("UTILITY.frmmdltr ", "M")
	CASE UPPER(tsPrompt) ="REPRINT MD FILINGS"
		goApp.OpenForm("issued.frmmdset ", "M")
&&03/23/2016 removed  OMRPage #36180
&& EF 03/07/2012- added Omrpage
*!*		CASE UPPER(tsPrompt) = "PRINT OMR PAGE"
*!*			DO omrpdfpg
&&03/23/2016 removed  OMRPage #36180
&& EF 11/05/2010- added PRINT PA ORIGINAL SUBPOENA
	CASE UPPER(tsPrompt) = "PRINT PA ORIGINAL SUBPOENA"
		goApp.OpenForm("qcaipjobs.frmorigsubp", "S")
	CASE UPPER(tsPrompt) = "GLOBAL MAIL ID REASSIGNMENT"
		goApp.OpenForm("casedeponent.frmmailidfx", "S")
	CASE UPPER(tsPrompt) = "REPRINT CERTIFICATION PAGE(S)"
		DO reprtcer.prg
	CASE UPPER(tsPrompt) = "KOP COURT FILING LETTER/NOTICES"
		DO courtset2.prg && 1/14/14- new process for getting the KOP filings
	CASE ALLTRIM(UPPER(tsPrompt))=UPPER("OUTSTANDING STATUS-TO-COUNSEL Analysis & Follow-Up")
		goApp.OpenForm("utility.frmCheck30SNew", "S")
	CASE ALLTRIM(UPPER(tsPrompt))="REPRINT TEXAS REQUEST DOCUMENTS"
		IF  (ALLTRIM(NVL(goApp.CurrentUser.orec.DEPT,''))<>'IT')
			gfMessage("You do not have access rights for this option")
			RETURN
		ELSE
			goApp.OpenForm("issued.frmtxdocs", "S")
		ENDIF
	CASE ALLTRIM(UPPER(tsPrompt))="PRINT BILLING COVER LETTER PAGE FOR A SPECIFIC CASE AND TAG"
		goApp.OpenForm("utility.frmGetLrsTag", "S", NULL, "C")
	CASE ALLTRIM(UPPER(tsPrompt))=UPPER("Reprint a Request Cover Letter for a specific case and tag")
		goApp.OpenForm("utility.frmGetLrsTag", "S", NULL, "R")
	CASE ALLTRIM(UPPER(tsPrompt))=UPPER("Print Cover Letters for State Diet Drug Cases by Date Range")
*--6/5/19: remove access to unused option [87505]
		gfMessage(tsPrompt+" not available. Contact IT department.")
		RETURN
*--goApp.OpenForm("utility.frmGetCovPage", "S")
	CASE ALLTRIM(UPPER(tsPrompt))=UPPER("Send STC Letters")
*goApp.OpenForm("utility.frmSelectSTCToSend", "S")
		IF checktest("VER2CODE30")=.T.
			goApp.OpenForm("utility.frmSelectSTCToSend", "S")
		ELSE
			IF checktest("STCNOTE")=.F.
				goApp.OpenForm("stc.frmSelectSTCToSendNote", "S")
			ELSE
				goApp.OpenForm("stc.frmSelectSTCToSend", "S")
			ENDIF
		ENDIF
	CASE ALLTRIM(UPPER(tsPrompt))=UPPER("Print Daily Time Report")
		SET CLASSLIB TO UTILITY ADDIT
		DO usertxnrept
	CASE ALLTRIM(UPPER(tsPrompt))=UPPER("Delete Scanned Images")
		DO delimages
	CASE ALLTRIM(UPPER(tsPrompt))=UPPER("Generate AutoCall Tag List")
		goApp.OpenForm("generic.frmAutoCall", "S")
	CASE ALLTRIM(UPPER(tsPrompt))=UPPER("Release Reserved Soft-Copy Problem Job")
		IF NVL(goApp.CurrentUser.orec.actual_mgr,.F.)
			DO scprobjobrelease
		ELSE
			gfMessage("You do not have access rights for this option")
		ENDIF
	CASE ALLTRIM(UPPER(tsPrompt))=UPPER("Generate Mail Merge File by RT")
		goApp.OpenForm("generic.frmgetlrstags","S",NULL,"MM")

	OTHERWISE

	ENDCASE


CASE tsPad = "NOTIC"
	DO CASE
	CASE tsPrompt = UPPER("GENERATE MD SUBPOENAS (ClIENT MEMO TAGS")
		goApp.OpenForm("generic.frmmdsubps", "M")
	CASE tsPrompt = UPPER("GENERATE KOP SUBP ISSUED REPORT")
		goApp.OpenForm("issued.frmchkkopnot", "M")
	CASE tsPrompt = UPPER("RISPERDAL-PCCP NOTICES")
		goApp.OpenForm("issued.frmEmailNot", "M")
	CASE tsPrompt = UPPER("PRINT KOP BATCH NOTICES")
*CASE tsPrompt = UPPER("PRINT KOP CIVIL NOTICES")
*goApp.OpenForm("generic.frmRunKOPNot", "M")
		goApp.OpenForm("issued.frmnoticebatch", "M")
*CASE tsPrompt = UPPER("Texas Office")
*goApp.OpenForm("Issued.frmRunTxNot", "M")
	CASE tsPrompt =ALLTRIM(UPPER("OAKLAND"))

*DO c:\tsbill\followup_22514.prg
*DO getlist2 IN tempauth
*DO tempauth    WITH 270184, 7, 'HENDERSONVILLE PEDIATRICS (MED)', 'A669774', 'B'
*DO tempauth    WITH 265314, 9, 'ANTHEM BLUE CROSS AND BLUE SHIELD OF OHIO','A636107', 'M'
*DO Converfile_new IN STEP4EXCL WITH  'c:\'  ,'DentalInsCard.PDF'
		DO CA_NOTice WITH "C"
*DO flnotic WITH 202082, {07/11/2013}&& 202080, {11/05/2015}
* DO hsubcourt2 WITH {05/13/2014},  'RUJ266335P'
*DO c:\tsbill\deltagimg.prg
* DO pccptxn WITH  'y:\add7.xls'
*dO  pccp_g
*DO createimg
*DO print21 WITH .t.
*DO y:\temp\followup_22514.prg
*DO getlist2 IN tempauth
*DO tempauth    WITH 270184, 7, 'HENDERSONVILLE PEDIATRICS (MED)', 'A669774', 'B'
*DO tempauth    WITH 265314, 9, 'ANTHEM BLUE CROSS AND BLUE SHIELD OF OHIO','A636107', 'M'
*DO Converfile_BYPAGE IN STEP4EXCL WITH  'c:\aaimg\'  ,'test3.PDF', '202080',1






	OTHERWISE

		DO CANOTice WITH "S"
	ENDCASE
CASE tsPad = "FILE"
	DO CASE
	CASE tsPrompt = "EXIT"
		goApp.ExitSystem()
	OTHERWISE
		= MLMsg("Invalid Option: " + CHR(13) + tsPad + " - " + tsPrompt)
	ENDCASE
CASE tsPad = "MAINDATA"
	DO CASE
	CASE tsPrompt = "CASES"
		goApp.OpenForm("Master.frmMasterSearch", "S")

*/ DMA 08/18/05 Change to one menu entry for combined client/defendant form
	CASE tsPrompt = "CLIENTS AND DEFENDANTS"
		goApp.OpenForm("Client.frmClientSearch", "S", NULL, NULL, "X")

*	Case tsPrompt = "CLIENTS..."
*		goApp.OpenForm("Client.frmClientSearch", "S", Null, Null, "X")

*	Case tsPrompt = "DEFENDANTS..."
*		goApp.OpenForm("Defendant.frmDefendantSearch", "S", Null, Null, Null)

	CASE tsPrompt = "FIRMS"
		goApp.OpenForm("Firm.frmFirmSearch")

	CASE ALLTRIM(UPPER(tsPrompt))=UPPER("Litigation SetUp")
		goApp.OpenForm("litigation.frmlitRules")

	CASE tsPrompt = "ADD CLIENTS TO CASES..."
		DisplayOptionNotSetMessage(tsPad, tsPrompt)
*		goApp.OpenForm("Master.frmMasterSelect", "S")

	CASE tsPrompt = "MANUALLY ADD CLIENTS TO CASES..."
		DisplayOptionNotSetMessage(tsPad, tsPrompt)
*		goApp.OpenForm("Master.frmMasterSelectMan", "S")
** - Main
** -- Data
** --- Admin Utilities
	CASE tsPrompt = UPPER("ADD A PROJECT CHANGE REQUEST")
		goApp.OpenForm("projectMngmt.projectchangerequestform")
	CASE tsPrompt = UPPER("Project Change Request Management")
		IF (NVL(goApp.CurrentUser.orec.CHANGEREQUEST_ACCESS,.F.))
			goApp.OpenForm("projectMngmt.frmrequestmngmt")
		ELSE
			cMessageTitle = 'Validation Error Message'
			cMessageText = 'You are not Validated to access Project Change Request Management'
			nAnswer = MESSAGEBOX(cMessageText,0, cMessageTitle)
		ENDIF
	CASE tsPrompt = UPPER("Project Management Queue")
		IF (NVL(goApp.CurrentUser.orec.CHANGEREQUEST_ACCESS,.F.))
			goApp.OpenForm("projectMngmt.frmjoblist")
		ELSE
			cMessageTitle = 'Validation Error Message'
			cMessageText = 'You are not Validated to access Project Change Request Management'
			nAnswer = MESSAGEBOX(cMessageText,0, cMessageTitle)
		ENDIF
	CASE tsPrompt = UPPER("Reset QC Test Case")
		goApp.OpenForm("utility.frmResetQCTestCase")
	CASE tsPrompt = UPPER("Close a Batch of Cases (under development)")
		DisplayOptionNotSetMessage(tsPad, tsPrompt)
** MEI(PCL) 5/3/2005: Remarked as in legacy code.
* DO caseclos

	CASE tsPrompt = "Witness Fee Rate Schedule"
		DisplayOptionNotSetMessage(tsPad, tsPrompt)
*	DO AcWitFee

	CASE tsPrompt =UPPER("Update Request Type (Authorization/Subpoena)")
*DisplayOptionNotSetMessage(tsPad, tsPrompt)
		DO updtype

	CASE tsPrompt = "Generate PA First-Look Page"
		DisplayOptionNotSetMessage(tsPad, tsPrompt)
*	DO flook_pa

	CASE tsPrompt = "Outstanding Tag Report"
		DisplayOptionNotSetMessage(tsPad, tsPrompt)
*	DO outstand

	CASE tsPrompt = "View and Print Rate Schedules"
		DisplayOptionNotSetMessage(tsPad, tsPrompt)
*   Do RCUWand
	CASE tsPrompt = "RCU LOGIN OF RECEIVED RECORDS"
		goApp.OpenForm("TimeSheet.frmRCUWand", "S")

** MEI(PCL) 5/3/2005: Remarked as in legacy code.
* 12/18/03 DMA Eliminate rate-editing options; retain only view/print options
* DO Ratemain
*  	DO raterept

	CASE tsPrompt = "Assign Cases to 'Template' and 'Test' Categories"
		DisplayOptionNotSetMessage(tsPad, tsPrompt)
*   	DO UpdMirr

	CASE tsPrompt = "UPDATE PSNOTICE FILE"
*DisplayOptionNotSetMessage(tsPad, tsPrompt)
*    	DO CaPSNot
		IF INLIST(goApp.CurrentUser.officecode,"C","S")

			goApp.OpenForm("Generic.frmcapsnot", "S")
		ELSE
			WAIT WINDOW "Only used in the CA offices." NOWAIT NOCLEAR
		ENDIF

	CASE tsPrompt = "SELECT SIGNER FOR TODAY'S PROOF OF SERVICE DOCUMENTS"
**EF 4/11/06 -added to the menu
		DO CASigner
	CASE tsPrompt = "CHANGE TAG COUNT IN A CASE"
* DisplayOptionNotSetMessage(tsPad, tsPrompt)
*    	DO CAUpdTag
**EF 5/01/06
		goApp.OpenForm("generic.frmupdtagcnt", "M")

	CASE tsPrompt = "DEPONENT ROLODEX"
		pl_DLIssueCall=.T. &&EF 8/21/2007 : ONLY TRUE FOR ISSUES FROM THE DEPONENT'S SCREEN
		goApp.OpenForm("Deponent.frmDeponentSearch", "S")
		pl_DLIssueCall=.F.
** - Main
** -- Data
** --- Court Pick Lists

	CASE tsPrompt = "KOP/OAKLAND/PASADENA"
		goApp.OpenForm("Court.frmCourtSearch", "S")

	CASE tsPrompt = "TEXAS"
		goApp.OpenForm("txCourt.frmTxCourtSearch", "S")

** - Main
** -- File
	CASE UPPER(tsPrompt) = "COPY SERVICE"
		goApp.OpenForm("Deponent.frmCopyServ", "S")
	CASE tsPrompt = "EXIT"
		goApp.ExitSystem()
	CASE ALLTRIM(UPPER(tsPrompt)) == ALLTRIM(UPPER("Multiple Tags Soft Copy Reset"))
*--6/5/19: kdl - remove unused menu call?? [87505]
		gfMessage(tsPrompt+" not available. Contact IT department.")
		RETURN
*--DO resetSoftCopy WITH .T.
	CASE ALLTRIM(UPPER(tsPrompt)) == ALLTRIM(UPPER("Single Tag Soft Copy Reset"))
*--6/5/19: kdl - remove unused menu call?? [87505]
		gfMessage(tsPrompt+" not available. Contact IT department.")
		RETURN
*--DO resetSoftCopy WITH .F.
**5/14/09 SEARCH BY INVOICE
	CASE ALLTRIM(UPPER(tsPrompt))== ALLTRIM(UPPER("SEARCH FOR VENDOR INVOICE NUMBER"))


		goApp.OpenForm("issued.frmlistinv", "S")

	CASE tsPrompt = UPPER("Copy on Location (COL) Logistics")
		o_frm=CREATEOBJECT('transactions.frmcolpickupqueue')
		o_frm.SHOW
	OTHERWISE
		= MLMsg("Invalid Option: " + CHR(13) + tsPad + " - " + tsPrompt)
	ENDCASE

CASE tsPad = "CASES"
** This pad is only visible when a case is open and
** one of its forms is active and selected
	DO CASE

** - Main
** -- Case Activities

	CASE tsPrompt = UPPER("Deponent Summary")
		IF (TYPE("_Screen.ActiveForm.cusCaseMgr.Name") = T_CHARACTER)
			_SCREEN.ACTIVEFORM.cusCaseMgr.ViewCaseDepoSummary()
		ENDIF
*03/15/2006 - MD
*!*		Case tsPrompt = Upper("Timesheet/Case Memos (Tag 0)")
*!*	        DisplayOptionNotSetMessage(tsPad, tsPrompt)
*!*			If (Type("_Screen.ActiveForm.cusCaseMgr.Name") = T_CHARACTER)
*!*				_Screen.ActiveForm.cusCaseMgr.viewcasetransactions()
*!*			Endif
*MD

** - Main
** -- Case Activities
** ---- Case Data
	CASE tsPrompt = UPPER("Primary Case Information")
*	        DisplayOptionNotSetMessage(tsPad, tsPrompt)
		IF (TYPE("_Screen.ActiveForm.cusCaseMgr.Name") = T_CHARACTER)
			_SCREEN.ACTIVEFORM.cusCaseMgr.ViewCaseDetails()
		ENDIF

	CASE tsPrompt = UPPER("Additional Case Information")
*--- 07/25/2017 MD moved if condition from case menu to here.   #65636
		IF !(_SCREEN.ACTIVEFORM.caseheader1.medmaster.orec.litigation = 'A' AND _SCREEN.ACTIVEFORM.caseheader1.medmaster.orec.area = 'Ohio')   && 07/25/2017
			gfMessage("This option is only avialable for litigation - Asbestos and area - Ohio")
			RETURN
		ELSE
			SET DATASESSION TO goApp.tempmastercaseformreference.DATASESSIONID
			goApp.OpenForm("case.frmaddinfo", "S",NULL,MASTER.ID_TBLMASTER, MASTER.cl_code)
			SET DATASESSION TO
		ENDIF


*		If (Type("_Screen.ActiveForm.cusCaseMgr.Name") = T_CHARACTER)
*			_Screen.ActiveForm.cusCaseMgr.ViewCaseInfo()
*		Endif

* DMA: Following item should probably be removed
*	        DisplayOptionNotSetMessage(tsPad, tsPrompt)
*	Case tsPrompt = Upper("Additional Case Information")
*		DisplayOptionNotSetMessage(tsPad, tsPrompt)

* DMA 11/28/05 Remove option; mirroring handled from frmCaseSearch
*	Case tsPrompt = Upper("Duplicate Case")
*	        DisplayOptionNotSetMessage(tsPad, tsPrompt)
*		If (Type("_Screen.ActiveForm.cusCaseMgr.Name") = T_CHARACTER)
*			_Screen.ActiveForm.cusCaseMgr.ViewCaseDetailsDup()
*		Endif

** - Main
** -- Case Activities
** ---- Case Data
** ------ Case Instructions
**EF 5/17/06
	CASE tsPrompt = UPPER("Review Deponents by Category")


		goApp.OpenForm("Request.frmDepSummary", ;
			ALLTRIM(_SCREEN.ACTIVEFORM.caseheader1.medmaster.orec.ID_TBLMASTER), ;
			ALLTRIM(_SCREEN.ACTIVEFORM.caseheader1.medmaster.orec.ID_TBLMASTER), ;
			ALLTRIM(_SCREEN.ACTIVEFORM.caseheader1.medmaster.orec.ID_TBLMASTER), "V")

*DisplayOptionNotSetMessage(tsPad, tsPrompt)
	CASE tsPrompt = UPPER("New Case Instructions")
*--		DisplayOptionNotSetMessage(tsPad, tsPrompt)
		IF (TYPE("_Screen.ActiveForm.cusCaseMgr.Name") = T_CHARACTER)
			_SCREEN.ACTIVEFORM.cusCaseMgr.NewCaseInstructions()
		ENDIF

*--2/9/05 kdl start: activate case instructions prompts
	CASE tsPrompt = UPPER("Case Instructions")
*--		DisplayOptionNotSetMessage(tsPad, tsPrompt)
		IF (TYPE("_Screen.ActiveForm.cusCaseMgr.Name") = T_CHARACTER)
			_SCREEN.ACTIVEFORM.cusCaseMgr.ViewCaseInstructions()
		ENDIF

** - Main
** -- Case Activities
** ---- Document Processing

	CASE tsPrompt = UPPER("Waiver Received")
		IF (TYPE("_Screen.ActiveForm.cusCaseMgr.Name") = T_CHARACTER)
*  09/14/2017 MD #69369 move office check from the case menu to here
			IF goApp.CurrentUser.officecode ="C"
* skip for CA office
			ELSE
				_SCREEN.ACTIVEFORM.cusCaseMgr.viewwaiverreceived()
			ENDIF
		ENDIF

	CASE tsPrompt = UPPER("Print Notices")
*DisplayOptionNotSetMessage(tsPad, tsPrompt)
**EF 1/27/06 - activated that option
		DO reprint WITH (ALLTRIM(_SCREEN.ACTIVEFORM.caseheader1.medmaster.orec.ID_TBLMASTER))
	CASE tsPrompt = UPPER("Authorization")
		DO issuereq WITH "A", ALLTRIM(_SCREEN.ACTIVEFORM.caseheader1.medmaster.orec.ID_TBLMASTER)

	CASE tsPrompt = UPPER("Subpoena")
		DO issuereq WITH "S", ALLTRIM(_SCREEN.ACTIVEFORM.caseheader1.medmaster.orec.ID_TBLMASTER)
	CASE tsPrompt = UPPER("Print Court Certificate")
*DisplayOptionNotSetMessage(tsPad, tsPrompt)
		DO courtcer WITH  ALLTRIM(_SCREEN.ACTIVEFORM.caseheader1.medmaster.orec.lrs_no)
	CASE tsPrompt = UPPER("View X-rays and Pathology Slides")
		goApp.OpenForm("Transactions.frmXRayScrn", "S")
*--8/28/2018 YS Renamed to "Delete Uploaded Web Docs" and activated it. #103030
*--7/31/2018 YS Hid the menu of "Delete Documents" by Alec
*--6/14/2018 YS Added Removal of uploaded documents #88304
	CASE tsPrompt = UPPER("Delete Uploaded Web Docs")
		goApp.OpenForm("WebBasedOrders.frmDelUploads", "S")

** - Main
** -- Case Activities
** ---- Order Information

	CASE tsPrompt = UPPER("Participating Clients")
		IF (TYPE("_Screen.ActiveForm.cusCaseMgr.Name") = T_CHARACTER)
			_SCREEN.ACTIVEFORM.cusCaseMgr.ViewCaseParticipating()
		ENDIF

* DMA: Following option should probably be removed or replace above item
	CASE tsPrompt = UPPER("Participating Attorneys")
		DisplayOptionNotSetMessage(tsPad, tsPrompt)

*/ 08/17/05 DMA Eliminate unneeded option and add valid ones
*/	Case tsPrompt = Upper("CA Asbestos Cost-Sharing")
*/		DisplayOptionNotSetMessage(tsPad, tsPrompt)

** - Main
** -- Case Activities
** ---- Order Information
** ------ Berry & Berry Participating Attorneys

	CASE tsPrompt = UPPER("View All Shares") OR tsPrompt = UPPER("View Current Only")
*DisplayOptionNotSetMessage(tsPad, tsPrompt)
		l_BBCase = (_SCREEN.ACTIVEFORM.caseheader1.medmaster.orec.rq_at_code == "BEBE  3C")
		l_BBAsb = l_BBCase AND _SCREEN.ACTIVEFORM.caseheader1.medmaster.orec.litigation == "A  "
		IF NOT l_BBAsb
			gfMessage( "This option is only available for " + ;
				"California Asbestos cases." )
			RETURN
		ENDIF


		DO cashares WITH IIF(tsPrompt = UPPER("View Current Only"),2,1),(ALLTRIM(_SCREEN.ACTIVEFORM.caseheader1.medmaster.orec.ID_TBLMASTER))

*CASE tsPrompt = UPPER("View Current Only")
*DisplayOptionNotSetMessage(tsPad, tsPrompt)


** - Main
** -- Case Activities
** ---- Bar Code Printing

	CASE tsPrompt = UPPER("1) Bar Code Authorization")
		DO printBarCode WITH 1

	CASE tsPrompt = UPPER("2) Interrogatory")
		DO printBarCode WITH 2

	CASE tsPrompt = UPPER("3) Attorney Correspondence")
		DO printBarCode WITH 3

	CASE tsPrompt = UPPER("4) Status to Counsel Attachment")
		DO printBarCode WITH 4

	CASE tsPrompt = UPPER("5) Records Received After Cancellation")
		DO printBarCode WITH 5

** - Main
** -- Case Activities
** ---- Bates Labels

	CASE tsPrompt = UPPER("Print Labels")
		DisplayOptionNotSetMessage(tsPad, tsPrompt)
*		If (Type("_Screen.ActiveForm.cusCaseMgr.Name") = T_CHARACTER)
*			_Screen.ActiveForm.cusCaseMgr.viewcasebateslblinfo()
*		Endif


	CASE tsPrompt = UPPER("Add/Update Tags in Bates-Label File")
		SET DATASESSION TO goApp.tempmastercaseformreference.DATASESSIONID
		goApp.OpenForm("case.frmbateslist", "S",NULL,MASTER.ID_TBLMASTER, MASTER.cl_code)
*--				DO batestxt WITH MASTER.ID_TBLMASTER, MASTER.cl_code
		SET DATASESSION TO
*--		DisplayOptionNotSetMessage(tsPad, tsPrompt)

** DMA 08/17/05 The following items are not on the menu at this time...
**    but they ARE needed to emulate old system!

	CASE tsPrompt = UPPER("Reset Bates")
		SET DATASESSION TO goApp.tempmastercaseformreference.DATASESSIONID
		goApp.OpenForm("case.frmResetBates", "S",NULL,MASTER.ID_TBLMASTER, MASTER.cl_code,"R")
		SET DATASESSION TO

	CASE tsPrompt = UPPER("Set Scanned Date as 1960")
		SET DATASESSION TO goApp.tempmastercaseformreference.DATASESSIONID
		goApp.OpenForm("case.frmResetBates", "S",NULL,MASTER.ID_TBLMASTER, MASTER.cl_code, "S")
		SET DATASESSION TO

	CASE tsPrompt = UPPER("Unlock Bates Text File")
		SET DATASESSION TO goApp.tempmastercaseformreference.DATASESSIONID
		DO batesunlock WITH MASTER.lrs_no
		SET DATASESSION TO


	CASE tsPrompt = UPPER("Update Plaintiff Scanned Name")
		SET DATASESSION TO goApp.tempmastercaseformreference.DATASESSIONID
		goApp.OpenForm("case.frmUpdateScannedName", "S",NULL,MASTER.ID_TBLMASTER, MASTER.cl_code)
		SET DATASESSION TO

	CASE tsPrompt = UPPER("Add New Deponent")
		DisplayOptionNotSetMessage(tsPad, tsPrompt)

*!*	* 03/15/2006 - MD
	CASE tsPrompt = UPPER("View Tag 0 Memos")
		goApp.OpenForm("Transactions.frmViewTransMemo", "S", NULL, "T",.F., 0)

	CASE tsPrompt = UPPER("View All Transactions")
		goApp.OpenForm("Transactions.frmViewTransMemo", "S", NULL, "A",.F., NULL)
*!*	* 03/15/2006 - MD
	CASE tsPrompt = UPPER("Recall Deleted Tag")
		goApp.OpenForm("Transactions.frmRecallDeletedTag", "S", NULL)

	CASE tsPrompt = UPPER("Select Specific Deponent")
		DisplayOptionNotSetMessage(tsPad, tsPrompt)

	CASE tsPrompt = UPPER("View Received Materials")
		DisplayOptionNotSetMessage(tsPad, tsPrompt)

	CASE tsPrompt = UPPER("View Deponents by Category")
		DisplayOptionNotSetMessage(tsPad, tsPrompt)

	CASE tsPrompt = UPPER("View and Recall Deleted Deponents")
		DisplayOptionNotSetMessage(tsPad, tsPrompt)

	CASE tsPrompt = UPPER("No Issue")
		DisplayOptionNotSetMessage(tsPad, tsPrompt)

	CASE tsPrompt = UPPER("Issue Subpoena")
		DisplayOptionNotSetMessage(tsPad, tsPrompt)

	CASE tsPrompt = UPPER("Issue Authorization")
		DisplayOptionNotSetMessage(tsPad, tsPrompt)

*			CASE tsPrompt = UPPER("Additional Case Information")
*				SET DATASESSION TO goApp.tempmastercaseformreference.DATASESSIONID
		goApp.OpenForm("case.frmaddinfo", "S",NULL,MASTER.ID_TBLMASTER, MASTER.cl_code)
*--				DO batestxt WITH MASTER.ID_TBLMASTER, MASTER.cl_code
*				SET DATASESSION TO

	CASE tsPrompt = UPPER("Quick Request")
		WAIT WINDOW "Please use a [Quick Request] through the SoftCopy system."
*SET DATASESSION TO goApp.tempmastercaseformreference.DATASESSIONID
*goApp.OpenForm("transactions.frmQuickRequest", "S",NULL,MASTER.ID_TBLMASTER, MASTER.cl_code,"N")
*SET DATASESSION TO
	CASE tsPrompt = UPPER("Update Page Count For Quick Request")
		SET DATASESSION TO goApp.tempmastercaseformreference.DATASESSIONID
		goApp.OpenForm("transactions.frmQuickRequest", "S",NULL,MASTER.ID_TBLMASTER, MASTER.cl_code,"U")
		SET DATASESSION TO

	CASE tsPrompt = UPPER("Received Items List")
		goApp.OpenForm("Case.frmdisplaytagdocstatus", "S", NULL)
	CASE tsPrompt = UPPER("Reset Received Item Job")
		IF NVL(goApp.CurrentUser.orec.actual_mgr,.F.)
			DO tagitemjobreset
		ELSE
			gfMessage("You do not have access rights for this option")
		ENDIF
	CASE tsPrompt = UPPER("Base Documents")
		SET CLASSLIB TO UTILITY ADDIT
		goApp.OpenForm("utility.frmcallrtsscan", "S", NULL)
	CASE tsPrompt = "ADD EXTENDED FOLLOW UP (OUTSTANDING TAGS)"  && 1/27/2022, ZD #262750, JH
		IF gfMessage("Add extended follow up '68' transactions for all outstanding tags?",.T.)
			SET DATASESSION TO goApp.tempmastercaseformreference.DATASESSIONID
			local sql_Conn As MEDTIMESHEET Of TIMESHEET
			local lnTagsAdded as integer
			lnCurArea=SELECT()
			sql_Conn = Createobject("medtimesheet")
			sql_Conn.SqlExecute("exec [dbo].[addTrans68_TagsWaiting] '"+master.cl_code+"','"+goApp.CurrentUser.ntlogin+"'", "Add68s")
			SELECT Add68s
 			lnTagsAdded = RECCOUNT()
		    IF lnTagsAdded > 0
			    gfMessage("Transactions added for the "+ALLTRIM(STR(lnTagsAdded))+" open tags.")
            ELSE
			    gfMessage("No tags in 'Waiting' status found to add extended follow up transactions.")
            ENDIF
			sql_Conn.closealias("Add68s")
			release sql_Conn, lnTagsAdded
			SELECT(lnCurArea)
		ENDIF													&& 1/27/2022

	OTHERWISE
		= MLMsg("Invalid Option: " + CHR(13) + tsPad + " - " + tsPrompt)
	ENDCASE

*!*
*!*		*//-------------
*!*		*//FILE menu pad
*!*		*//-------------
*!*		CASE (tnBar == MENU_BAR_FILE_CASES)
*!*			goApp.OpenForm("TAMaster.frmTAMasterSearch", "S")
*!*		CASE (tnBar == MENU_BAR_FILE_ATTORNEYS)
*!*			goApp.OpenForm("Client.frmClientSearch")
*!*		CASE (tnBar == MENU_BAR_FILE_DEPO)
*!*			goApp.OpenForm("Deponent.frmDeponentSearch", "S")
*!*		CASE (tnBar == MENU_BAR_FILE_COURT)
*!*			goApp.OpenForm("Court.frmCourtSearch", "S")
*!*		CASE (tnBar == MENU_BAR_FILE_EXIT)
*!*		  goApp.ExitSystem()
*!*		CASE (tnBar == MENU_BAR_FILE_LOGIN_USER)
*!*			= AppLogin()


CASE UPPER(tsPad)="SCSYSTEM"
	IF NOT FILE('c:\rts\tiffprocessor.ocx')
		gfMessage(tsPrompt+" not installed on this machine.")
	ELSE
		SET CLASSLIB TO depdisposition ADDIT
		DO CASE
*--7/6/17: add login tracks [64929]
		CASE tsPrompt = UPPER("Basic Record Log In")
			goApp.OpenForm("DEPDISPOSITION.frmsoftcopy","S",'','TRACK2')
		CASE tsPrompt = UPPER("Record Log In")
			goApp.OpenForm("DEPDISPOSITION.frmsoftcopy","S",'','RECORD')
		CASE tsPrompt = UPPER("Material Log In")
			goApp.OpenForm("DEPDISPOSITION.frmsoftcopy","S",'','MATERIAL')
		CASE tsPrompt = UPPER("Get Next RCU Problem Job")
			goApp.OpenForm("DEPDISPOSITION.frmsoftcopy","S",'','PROBLEM_PJ')
		CASE tsPrompt = UPPER("Get Next Client-Rep Problem Job")
			goApp.OpenForm("DEPDISPOSITION.frmsoftcopy","S",'','PROBLEM_CR')
*--change drop category text [86347]
		CASE tsPrompt = UPPER("Get Next DRU Problem Job")
*--CASE tsPrompt = UPPER("Get Next Copy-Service Problem Job")
			goApp.OpenForm("DEPDISPOSITION.frmsoftcopy","S",'','PROBLEM_FU')
*--add new drop category text [86347]
		CASE tsPrompt = UPPER("Get Next RSCH Problem Job")
*--CASE tsPrompt = UPPER("Get Next Copy-Service Problem Job")
			goApp.OpenForm("DEPDISPOSITION.frmsoftcopy","S",'','PROBLEM_RE')
		CASE tsPrompt = UPPER("Get Next QC-Rejected Job")
			goApp.OpenForm("DEPDISPOSITION.frmsoftcopy","S",'','PROBLEM_QR')
		CASE tsPrompt = UPPER("Get Next QC Job")
			goApp.OpenForm("DEPDISPOSITION.frmsoftcopy","S",'','QC')
*gfmessage(tsPrompt+" not available in"+CHR(13)+"this RTS release.")
		CASE tsPrompt = UPPER("View Deleted Jobs")
			goApp.OpenForm("DEPDISPOSITION.frmsoftcopy","S",'','DELETED')
*goApp.OpenForm("DEPDISPOSITION.frmsoftcopy","S",'','QC')

*--4/1/20: add option for external multi-pg PDF processing: call to post external SC PDF jobs [164402]
		CASE tsPrompt = UPPER("Post External PDF job to RSS")
			goApp.OpenForm("DEPDISPOSITION.frmsoftcopy","S",'','POST2RSS')
*--4/6/21: add option to call the add sc inbound docume nt screen [227955]
		CASE tsPrompt = UPPER("Add SC Inbound Documents")
			DO Callscaddinb
		ENDCASE

	ENDIF
CASE tsPad="FASTTRAK"
	DO CASE
	CASE tsPrompt = UPPER("Add Transaction(s)")
		SET CLASSLIB TO UTILITY ADDIT
		goApp.OpenForm("utility.frmgetrttag", "M", " ")
	CASE tsPrompt = UPPER("Record Login")
		SET CLASSLIB TO UTILITY ADDIT
		goApp.OpenForm("utility.frmgetrttag", "M", " ","DEP_DISPOSITION")
	CASE tsPrompt = UPPER("LA Risperdal Record Return")
*			CASE tsPrompt = UPPER("LA Risperdal Login")
		SET CLASSLIB TO depdisposition ADDIT
		goApp.OpenForm("depdisposition.frmlawandout", "M", " ","DEP_DISPOSITION")
*				goApp.OpenForm("depdisposition.frmwandin", "M", " ","DEP_DISPOSITION")
	CASE tsPrompt = UPPER("Soft Copy System")
		IF FILE('c:\rts\tiffprocessor.ocx')
			SET CLASSLIB TO depdisposition ADDIT
			goApp.OpenForm("DEPDISPOSITION.frmsoftcopy","S",'')
		ELSE
			gfMessage(tsPrompt+" not installed on this machine.")
		ENDIF
*				DO FORM frmsoftcopy
*!*					Set Classlib TO depdisposition ADDIT
*!*					SET STEP ON
*!*					osoftc=CREATEOBJECT('depdisposition.frmsoftcopy')
*!*					osoftc.show
*!*					RELEASE osoftc
*goApp.OpenForm("depdisposition.frmsoftcopy", "M", " ")

	ENDCASE
CASE ALLTRIM(UPPER(tsPad))="AUTPHNE"
	DO CASE
*CASE (ALLTRIM(UPPER(TSPROMPT))=UPPER("Automated Phone Call Queue"))
*	goApp.OpenForm("phonecallautomation.frmphonecallautomationmain")
	CASE ALLTRIM(UPPER(tsPrompt)) = UPPER("Phone Queue")
		goApp.OpenForm("phoneQueue.frmcalltube")
	CASE ALLTRIM(UPPER(tsPrompt)) = UPPER("Call QC")
		goApp.OpenForm("phoneQueue.frmcallQC")
	CASE ALLTRIM(UPPER(tsPrompt)) = UPPER("Previous Calls Display")
		goApp.OpenForm("phoneQueue.frmMadeCalls")
	CASE ALLTRIM(UPPER(tsPrompt)) = UPPER("Create AutoCall Tag List (New)")
		goApp.OpenForm("phoneQueue.frmautocall")
	ENDCASE
CASE tsPad="CAFIRSTLOO"
	DO CASE
	CASE ALLTRIM(UPPER(tsPrompt))=UPPER("Print  Brayton First Look List")
		goApp.OpenForm("utility.frmBraytonFirstLookList", "S")
	CASE ALLTRIM(UPPER(tsPrompt))=UPPER("Post CA First Look")
		DO postCAFL
	CASE ALLTRIM(UPPER(tsPrompt))=UPPER("Reset CA First Look Status")
		DO resetCAFL
	CASE ALLTRIM(UPPER(tsPrompt))=UPPER("Print List of New Brayton First-Look Tags")
		SET CLASSLIB TO UTILITY ADDIT
		DO brayton_newfiles
	CASE ALLTRIM(UPPER(tsPrompt))=UPPER("Brayton First-Look Page Replace")
*--6/5/19: kdl [87505]
		gfMessage(tsPrompt+" not available. Contact IT department.")
		RETURN
*!*			SET CLASSLIB TO UTILITY ADDIT
*!*			goApp.OpenForm("utility.frmbraytonflpdfmodify", "S")
	CASE ALLTRIM(UPPER(tsPrompt))=UPPER("Oakland First-Look Deliverables")
		DO oak_fldeliveries
	ENDCASE
CASE tsPad="WEBBASEDOR"
	DO CASE

**05/05/2011 - ADDED Web Order Request to Edit a Case
	CASE ALLTRIM(UPPER(tsPrompt))=UPPER("Web Order Request to Edit a Case")
		goApp.OpenForm("qcaipjobs.frmmtypewebord ", "M", "")
	CASE ALLTRIM(UPPER(tsPrompt))=UPPER("Process Web Orders (Old System)")
		SET CLASSLIB TO WebBasedOrders ADDIT
		goApp.OpenForm("WebBasedOrders.frmrtorders", "S")
	CASE ALLTRIM(UPPER(tsPrompt))=UPPER("Process One Time Web Orders (New System)")
		SET CLASSLIB TO WebBasedOrders ADDIT
		goApp.OpenForm("WebBasedOrders.frmOneTimeOrders", "S")
	ENDCASE

&&4/22/09 -batch proccesing
CASE ALLTRIM(UPPER(tsPad))="TODOFROMEXCEL"

*!*		PRIVATE omed2 AS OBJECT
*!*		omed2=CREATEOBJECT('cntdataconn') &&CREATEOBJECT("generic.medgeneric")

	DO CASE
*!*		CASE ALLTRIM(UPPER(tsPrompt))=UPPER("Add Cases From Excel")

*!*			pc_ToDoFile=""
*!*			goApp.OpenForm("issued.frmbatch", "S")

*!*		CASE ALLTRIM(UPPER(tsPrompt))=UPPER("Create Base Page(s)")
*!*			c_fileloc=""
*!*			c_img='B'
*!
**08/28/12 ADDED TXN 48/49 THROUGH EXCEL
	CASE ALLTRIM(UPPER(tsPrompt))=UPPER("Add nurse review time")

		IF NOT NVL(goApp.CurrentUser.orec.actual_mgr,.F.)
			gfMessage("You do not have access rights for this option.")
			RETURN
		ELSE
			LOCAL n_txn AS INTEGER
			n_txn=0
			n_txn = goApp.OpenForm("qcaipjobs.frmnrtxn", "M")
			IF n_txn=0 THEN
				RETURN
			ELSE
				gfMessage("The transactions have been added.")
*DO add49NR WITH n_txn
			ENDIF
		ENDIF



	CASE ALLTRIM(UPPER(tsPrompt))="QC/AIP PROCESS"

**10/04/2011- edited qc start (added {back button})
		STORE .F. TO pl_backbtn2 ,pl_backbtn3, pl_exitpick, pl_backbtn1

*12/13/2012 goApp.OpenForm("qcaipjobs.frmqcstartup", "M",3,3)
		goApp.OpenForm("qcaipjobs.frmqcstartup", "M")

	CASE ALLTRIM(UPPER(tsPrompt))=UPPER("Add Tags from Counsel Excel")
		IF NOT NVL(goApp.CurrentUser.orec.actual_mgr,.F.)
			gfMessage("You do not have access rights for this option")
			RETURN
		ELSE
			goApp.OpenForm("issued.frmautorec", "S")
		ENDIF


	ENDCASE
*RELEASE omed2



OTHERWISE

*--1/18/06 kdl out: remove to prevent message when menu called by popups
* = MLMsg("Invalid Option: " + Chr(13) + tsPad + " - " + tsPrompt)

ENDCASE
WAIT CLEAR
RETURN

PROCEDURE DisplayOptionNotSetMessage
LPARAMETERS ltsPad, ltsPrompt
= MLMsg("Feature Not Available At This Time! " + ;
	CHR(13) + ltsPad + " - " + ltsPrompt)
RETURN
** EOF **
