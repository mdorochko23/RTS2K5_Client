#Include App.h

*<cai_fpw26>
* Program....:	POST.PRG
* Version....:	2.0
* Author.....:	Robert A. Perritt
* Date.......:	October 14, 1995
* Notice.....:	Copyright (c) 1995 NYSBG / CAI, All Rights Reserved.
* Compiler...:	FoxProW 2.6
* Abstract...:	Daily posting program
* Changes....:	07/17/1997 - If user does not have access to daily.dbf, ie if
*					PASS.Permit3 = .F., stop there.
*				10/02/1997 - Turns on and off a flag when posting begins and finishes
*				in SYSDSTA.key for file = "POSTING".  
*				1 = posting in process.
*				2 = posting is done.
*			 
*				NOTE:  POSTING and EMIS BEING SENT should not be allowed at the same time.
*				This program will now check to see if emis is being sent.
*
*				11/18/1999 - Changed it so it adds all EMIS records to the table EMISHOLD.
*				If posting completes properly, then EMISHOLD is appended to EMIS.
*				EMIS can be created from terms or reinstates at the company level.  
*				It was found that if posting crashed during TermBill - while EMIS was
*				being created, there would be duplicate entries in EMIS.   Once Posting
*				was resumed, EMIS would be created all over again for the terms, including
*				and that were already created.   This will insure that EMIS is only created
*				once.   Each time posting is started, it ZAPS EMISHOLD.   EMIS is created
*				by addind records to EMISHOLD, not EMIS.   Once posting reaches a certain point
*				of completion, the records in EMISHOLD are appended to EMIS.   THis change was 
*				done in EMIS.prg, but it is worth noting here also.
*
*				03/09/2000 - Changed it so it now zaps EMISHOLD befire TERMS start posting, 
*				appends EMISHOLD to EMIS after TERMS finishposting, Zaps EMISHOLD before 
*				Reinstates start posting, and append EMISHOLD to EMIS after Reinstates 
*				Finish Posting.   It used to only append after Reinstates were done posting.
*
* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Local lbOK, lsSQL, loMediator, loWait

*//Default values
lbOK = .T.

lbOK = goApp.CurrentUser.oRec.Permit3
If !lbOK

	= MessageBox("You do not have sufficient access to Post!", ;
							 (MB_ICONSTOP + MB_OK), ;
							 "Posting")
Endif

If lbOK

	lbOK = (MessageBox("Perform daily posting now?", ;
								 		 (MB_YESNO + MB_ICONQUESTION), ;
								 		 "Post Transactions") == IDYES)
Endif

If lbOK

	*//Instantiate our Administration mediator
	loMediator = Create("medAdministration")

	* Check to see if EMIS is currently being sent.  If so, do not continue.
	* This is checked here, at the last possible moment before posting.
	If SENDEMIS()
	
		lbOK = .F.
		= MessageBox("Cannot Post - EMIS is being Sent.!", ;
								 MB_ICONSTOP, ;
								 "Posting")
	
	Endif

	* Once posting starts, set flag in SYSDATA.  1 = posting has started.
	= ChgSysData("POSTING", "key", 1)

	* - Occasionally, records in DAILY.dbf have no ending bill date (B_DATE2), so no invoices
	* - get generated.   Before posting, check for any blank dates, and fill them in from the
	* - AFFIL table.

	*//Display wait form
	loWait = goApp.OpenForm("app.frmWait", "O", "", "Fixing Blank Billing Dates......")

	*//Execute stored procedure
	loMediator.SQLExecute("[dbo].[usp_AdminDailyPostFixBadBillingDates]")

	* - Before posting, make sure all companies have correct Billing dates.   
	* - Update the billing dates of all companies with those on the Affil.

	*//Update wait form
	loWait.UpdateMessage("Updating Company Billing Dates.....")

	*//Execute stored procedure
	loMediator.SQLExecute("[dbo].[usp_AdminDailyPostFixCompanyBillingDates]")

	* - Only TERMBILL and REINBILL create EMIS Transactions during posting.  Zap EMISHold
	* - Before starting TERMS, append to EMIS when terms done.   Zap EMISHOLD right before
	* - Reinsates start, and eppend EMISHOLD to EMIS when done with Rreinstates.

	* - Zap the EMIS Hold file before we start adding any new records to it.
	* - EMISHOLD was opened exclusively up above.

	*//Update wait form
	loWait.UpdateMessage("Clearing EMISHOLD......")

	*//Execute stored procedure
	loMediator.SQLExecute("[dbo].[usp_AdminDailyPostClearEMISHold]")
	
	*//Hide our wait form
	loWait.Hide()

#IF .F.

	* - now perform posting
	wait window nowait "Starting Posting Process......"
	Do TermBill

#ENDIF

	*//Start posting
	Do TermBill

#IF .F.

	* - Now that posting TERMS has completed safely, append the records in EMISHOLD to EMIS.

	*//Update wait form
	loWait.UpdateMessage("Posting EMIS TERMS....")

	*//Execute stored procedure
	loMediator.SQLExecute("[dbo].[usp_AdminDailyPostAppendEMIS]")

#ENDIF

#IF .F.

	* - Post Plan Changes and New Enrollments.   No EMIS created here.
	do ChgBill
	do NewBill

	* - Zap EMISHIOLD before starting Reinstates.   Somehow, EMISHOLD is getting opened up in 
	* - SHARED mode, since the last ZAP statement about 10 lines up.  
	* - Open it Exclusively again here.
	select EMISHOLD
	use
	=OpenDBF("EMISHOLD", "", .T.)
	zap
	do ReinBill

	* - Now that posting REINSTATES has completed safely, append the records in EMISHOLD to EMIS.
	wait window  "Posting EMIS REINSTATEMENTS...." TIMEOUT 2
	select EMIS
	append from EMISHOLD


	* - Cleanup.   Close files, increment current EMISXMIT in SYSDATA, and restore menus.
	select DAYBILL
	use
	select DAILY
	use
	select EMIS
	use
	=opendbf("DAILY")
	select SYSDATA
	locate for UPPER(ALLTRIM(File)) == "EMISXMIT"
	replace Key with Key + 1
	pop menu _mSysMenu
	select COMPANY
	
#ENDIF

	* Once posting finishes, turn off flag in SYSDATA.  0 = posting has finished.
	= ChgSysData("POSTING", "key", 0)

	*//Close wait form
	loWait.CloseForm(.T.)
	
	= MessageBox("Daily Posting completed", ;
							 MB_ICONEXCLAMATION, ;
							 "Posting")

Endif

RETURN
****End of File  Post.prg