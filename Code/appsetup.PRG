#Include app.h

*____________________________________________________________________
*____________________________________________________________________
* PROGRAM - AppSetup
*
*
*	Note :
*		This corresponds in large part to the setup.prg from the original
*		FoxPro 2.6 application.
*
*____________________________________________________________________
Local lbOK

*//Default values
lbOK = .T.

*!*	_Screen.Caption = "NYSBG / CAI  v3.0"
_Screen.Caption = GetSysData("NYSBG", "title")


*!*	do ErorSet in FPWERROR
*!*	set procedure to Funcs
*!*	set default to \nysbg\dbfs

*!*	public Testing
*!*	Testing = .T.

*!*	public AppDone								&& keeps app running
*!*	AppDone = .F.

*!*	public NumRows								&& for browse window sizing
*!*	NumRows = srows() - 4

*!*	public NoteAdded							&& If a CSR note was added
*!*	NoteAdded = .F.

*!*	public PlanRebuilt							&& If plans have been rebuilt, okay to update from plan2
*!*	PlanRebuilt = .F.

*!*	public Sdate, Edate
*!*	Sdate = fixdate(date())
*!*	Edate = gomonth(Sdate,1) - 1

*!*	public User, UserName, Level, Password, SeeTimes, Dept 	&& User Name for logging and E-Mail
*!*	public Permit1, Permit2, Permit3, Permit4, Permit5, Permit6, Permit7, Permit8, Permit9
*!*	Public Permit10, EnterNotes
public Office2OK, Office3OK, Office4OK, ActiveOffice, Office1, Office2, Office3, Office4
public PLockbox, LLockbox
public GrpNumMethod, ReconPath, DuesOffice, MDNYOffice, MainMenuCalls, CurrBillNote


* User = User Logon ID in Password table PASS.dbf
* Username = Name of User that is logging on from PASS.dbf
* Level = Security level of the user in PASS.dbf
* PASSWORD = Password of User in PASS.dbf
* Permit1  	is used to restrict/allow access to Financial Reports Menu
* Permit2  	is used to restrict/allow access to Accounting Reports Menu
* Permit3  	is used to restrict/allow access to Open Daily.dbf
* Permit4  	is used to restrict/allow access to Approve Transaction Forms
* Permit5  	is used to restrict/allow access to Override Billing Flag
* Permit6  	is used to restrict/allow access to Lockbox Access - Payments Menu
* Permit7  	is used to restrict/allow access to Delete Notes.
* Permit8  	is used to restrict/allow access to Recon Notes.
* Permit9  	is used to restrict/allow access to Customized Renewals in both the C_CSR and
*			C_MENU menus.
* Permit10 	is used to restrict/allow access to Update Company NoCall Status
* EnterNotes is used to require users to enter CSR/UW notes to companies.
*	TRUE means they MUST enter a note.
* DEPT     is the Department of the user in PASS.dbf
* Active Office - indicates which office is active, and is used when switching offices.
* Office2OK is used to indicate if data from the other office is asccessible or not.
* Office3OK is  used to indicate if data from the Dues office area is asccessible or not.
* Office4OK is used to indicate if data from the Elite office (Office4) is asccessible or not.
* Office1 is the complete path name for the dbfs directory for the office that the user resides at.
* Office2 is the complete path name for the dbfs directory for the other office that the user DOES NOT resides at.
* Office3 is the complete path name for the dbfs directory for the Dues Office data.
* Office4 is the complete path name for the dbfs directory for the Elite Office data.
* PLockbox is used to restrict access from the LockBox Selection of the Mainmenu for users logged 
*		in to the Patchogue data.
* LLockbox is used to restrict access from the LockBox Selection of the Mainmenu for users logged 
*		in to the Latham data.
* ReconPath is the default path, including Drive letters for the Reconciliation Summary file
*  	(RecSumm.dbf) and Reconciliation Detail File (ALLGHI.dbf).    This will be in the default
*	directory of the Patchogue Office - as specified in SYSDATA.dbf .   
* 	Where sysdata.File = "NYSBG" and sysdata.Key = 1, the pathname is in sysdata.Call_Who.
* 	This path will be the same as OFFICE1 or OFFICE2 depending on which office the use
*	originates from.
* DuesOffice is set to true when the user has switched to the Dues Office and is 
*	currently still in the Dues Office - where sysdata.File = "NYSBG" and sysdata.Key = 3.
*	This is initialized here in Setup.prg and must be also changed each time the user 
*	switches offices.  See SWITCH, SWITCHELITE, SWITCHDUES in Funcs.prg.
* MDNYOffice is set to true when the user has switched to the MDNY Office and is 
*	currently still in the MDNY Office - where sysdata.File = "NYSBG" and sysdata.Key = 4.
*	This is initialized here in Setup.prg and must be also changed each time the user 
*	switches offices.  See SWITCH, SWITCHELITE, SWITCHDUES in Funcs.prg.
* CurrBillNote is the current Billnote Key# used for Messages printed on the bills.


* GRPNUMMETHOD is used to determine the method of calculating group numbers for GHI MGAPLANS.
* See the program GROUP.prg for more explanation.


*GRPNUMMETHOD = 1							&& Plan BASED, group number comes from PLANFILE
GRPNUMMETHOD = 2							&& Universal #, uses Universal Group # from IMFACT 
  
If (goApp.CurrentUser.oRec.Level == 0)

	lbOK = .F.
	= MessageBox("SECURITY VIOLATION!", ;
							 MB_ICONSTOP, ;
							 "System Administrator")
	= LogIt(NULL, NULL, ">> Access Attempt <<")

Endif

*!*	if not OpenFile()
*!*		release window logo
*!*		close databases
*!*		cancel
*!*	endif


*!*	* Only open Daily for users who will access it.
*!*	* if Level >= 7
*!*	if Permit3
*!*		if .not. OpenDBF("DAILY")
*!*			close database
*!*			return
*!*		endif
*!*	endif


*!*	* 05/04/2005
*!*	* Only open Recon Notes for users who will access it.  These are not AutoOpen.
*!*	if Permit8
*!*		if !OpenDBF("RECNOTES") or !OpenDbf("RECREASN")
*!*			close database
*!*			return
*!*		endif
*!*	endif

*!*	* - Now, get the office specific info
*!*	select SYSDATA

*!*	* - This office
*!*	locate for File = "NYSBG"
*!*	Office1 = trim(sysdata.Call_Who)
*!*	PLockBox = iif(sysdata.Key = 1, .T., .F.)		&& Only allow Patchogue to do Patchogue Lockbox
*!*	LLockBox = iif(sysdata.Key = 2, .T., .F.)		&& Only allow Latham to do Latham Lockbox

*!*	* - Are we in Dues or MDNY Offices?
*!*	m.DuesOffice = iif(sysdata.Key = 3, .T., .F.)		&& IS this the dues office?
*!*	m.MDNYOffice = iif(sysdata.Key = 4, .T., .F.)		&& IS this the MDNY office?

*!*	* - Other Office info
*!*	skip											
*!*	Office2OK = .T.
*!*	Office2 = trim(sysdata.Call_Who)
*!*	ActiveOffice = 1
*!*	TempFlag = sysdata.Multi_User
*!*	if !file(Office2+'\COMPANY.DBF')
*!*		Office2OK = .F.
*!*	endif
*!*	* - Don't allow switching offices if other office data is inaccessible.
*!*	if not TempFlag									
*!*		Office2OK = .F.
*!*	endif

*!*	* - Determine path of Reconciliation files
*!*	if sysdata.Key = 1
*!*		ReconPath = Office2							&& Current sysdata record is Office2
*!*	else
*!*		ReconPath = Office1
*!*	endif sysdata.Key = 1


*!*	* - Dues Office at Albany area
*!*	skip											
*!*	Office3Ok = .T.
*!*	Office3 = trim(sysdata.Call_Who)
*!*	TempFlag = sysdata.Multi_User
*!*	if !file(Office3+'\ACCREC.DBF')
*!*		Office3OK = .F.
*!*	endif
*!*	* - Don't allow switching to Dues office if Dues office data is inaccessible.
*!*	if not TempFlag									
*!*		Office3OK = .F.
*!*	endif


*!*	* - Elite Office at Patchogue Area
*!*	skip											
*!*	Office4OK = .T.
*!*	Office4 = trim(sysdata.Call_Who)
*!*	TempFlag = sysdata.Multi_User
*!*	if !file(Office4+'\ACCREC.DBF')
*!*		Office4OK = .F.
*!*	endif
*!*	* - Don't allow switching to Elite office if Elite office data is inaccessible.
*!*	if not TempFlag									
*!*		Office4OK = .F.
*!*	endif

If lbOK

	**************************************************************
	* - 02/21/2003 - Mandatory UW reports
	Public UWRepsOK, UWMyRepOnly	
	* m.UWRepsOK is true if UnderWriter has run all required reports for today.
	* m.UWMyRepOnly is true if the current user is only allowed to print the Underwriter
	*	reports for their cases only.   False means they can print UW Reports for all users.
	*   This is passed in as the 2nd parameter to the UW Reports

	m.UWRepsOK = IIf(goApp.CurrentUser.oRec.UnderWrite And goApp.CurrentUser.oRec.MustRunRep And (IsNull(goApp.CurrentUser.oRec.UWRepDate) Or goApp.CurrentUser.oRec.UWRepDate < Date()), .F., .T.)
	m.UWMyRepOnly = iif(goApp.CurrentUser.oRec.UnderWrite And goApp.CurrentUser.oRec.MustRunRep, .T., .F.)

	* - Also, if they have not met all requirements for the day, reset the # they have done
	* - to be 0, in Pass.UWRepsDone.    This is the best place I can think of to do it.
	If !m.UWRepsOK 
		= SQLExecute("[dbo].[usp_UserSetUWReportsDone] " + SQLConvToStr(goApp.CurrentUser.oRec.passkey) + ", " + SQLConvToStr(0))
	Endif
		
	If !m.UWRepsOk 

		= MessageBox(("As an Underwriter, you must run all Mandatory Underwriter Reports " + ;
							    "before you will be allowed into the system." + CRLF + "They are under " + ;
							    "Reports/Underwriter Reports/Mandatory Underwriter Reports."), ;
							   MB_ICONINFORMATION, ;
							   "Important")

	Endif
	*****************************************************************

Endif

*!*	* BWV THIS NEEDS TO BE REWORKED - !INCOMPLETE!
*!*	* 7/21/2003 - If user is an agent, where level <= 3, setup a filter now, so we only
*!*	* show companies that they are an agent on.  This means the browse window will not
*!*	* not show any company that they are not 1 of the 7 broker positions.
*!*	do C_AgentFilter in Company 
*!*		
*!*	* 7/21/2003 - If user is an agent, where level <= 3, setup a filter now, so we only
*!*	* show brokers that they are the wholesaler of, and themself as an agent.  This means the 
*!*	* browse window will not not show any broker that they are not wholesaler of.
*!*	do B_AgentFilter in Salesmen 
*!*	* BWV THIS NEEDS TO BE REWORKED - !INCOMPLETE!


public MaxLines								&& max # employees on an invoice page
* was 19
* was 14  
* changed to 09  08/25/1999
* changed to 10 09/28/1999
* changed to 13 02/23/2000
* changed to 12 05/25/2000  
* changed to 10 06/28/2000  
* changed to 12 08/23/2000  
* changed to 12 02/26/2001 - for dues and other offices.
* changed to 08 06/05/2001 - for Health 
* changed to 11 06/28/2001 - for Health 
* changed to 12 07/27/2001 - for Health 
* changed to 07 10/31/2001 - for Health 
* changed to 12 11/30/2001 - for Health 
* changed to 09 07/01/2002 - for Health 
* changed to 12 09/04/2002 - for Health 
* changed to 10 10/30/2002 - for Health 
* changed to 12 11/19/2002 - for Health 
* changed to 11 12/04/2002 - for Health (Retiree Note) 
* changed to 13 01/06/2003 - for Health 
* changed to 10 07/02/2003 - for Health 
* changed to 07 08/02/2003 - for Health 
* changed to 18 09/02/2003 - for Health 
* changed to 13 10/31/2003 - for Health (New Previous Payment Section on the Bills) 
* changed to 07 03/01/2004 - for Health (MDNY Office).
* changed to 13 03/01/2004 - for Health (After MDNy Bills Done).
* changed to 07 06/01/2004 - for Health (July 2004 Bills.  Message about old phone #s).
* changed to 06 06/25/2004 - for Health (Aug  2004 Bills.  Message Renewals 6 Weeks in Advance).
* NOTE:   Maxlines may be different for the dues office.   So the value of MAXLINES needs to 
* be maintained each time the user switches offices.   See SWITCHDUES in Funcs.prg.
* NOTE:  Maxlines must also be changed in both SWITCHDUES and SWITCH of FRUNCS.prg. 
if m.DuesOffice
	MaxLines = 12 
else
	MaxLines = 6		
endif

*!*	* BWV THIS NEEDS TO BE REWORKED - !INCOMPLETE!
*!*	* - BILLNOTE
*!*	* - 07/01/2002, which invoice message will we print from BILLNOTE?   
*!*	* - #1, go top just to make sure we're on the right record.
*!*	* - 10/30/2002 - Use #6.
*!*	* - 12/04/2002 - Use #15.
*!*	* - 07/02/2003 - Use #30.
*!*	* - 08/04/2003 - Use #31.
*!*	* - 02/03/2004 - Use #42.   (For MDNY Only).
*!*	* - 03/01/2004 - Use #43.   (For MDNY Only).
*!*	* - 03/24/2004 - Use #45.   (For Albany 4/1/2004 Quarterly reprints Only).
*!*	* - 03/24/2004 - Use #43.   Back to default.
*!*	* - 06/01/2004 - Use #46.   July 2004.  Old Phone Number message.
*!*	* - 06/25/2004 - Use #47.   August 2004.  Renewals 6 weeks in advance.
*!*	m.CurrBillNote = 47
*!*	select BILLNOTE
*!*	go top
*!*	locate for billnote.Key = m.CurrBillNote
*!*	* BWV THIS NEEDS TO BE REWORKED - !INCOMPLETE!

If lbOK

	public Billing								&& .T. if billing in progress
	m.Billing = GetSysData("BILLING", "Key")
	
	*//BwV - Temporary
	m.Billing = 0
	*//BwV - Temporary
	
	if goApp.CurrentUser.oRec.Permit5
		m.Billing = 0
	endif
	if m.Billing <> 0
		= MessageBox("Calculating bills - no changes are allowed at this time", ;
								 MB_ICONINFORMATION, ;
								 "Important")
	endif

Endif

*************************************
*************************************
*************************************
Return lbOK
*************************************
*************************************
*************************************

go top
locate for File = 'NYSBG'
modify window screen ;
	title alltrim(sysdata.Title)

* - set default indexes
set order to Key in PLANFILE
set order to Key in PLANRATE


release window Logo

do MainMenu.mpr

AppDone = .T.
clear read all
close databases
set procedure to
set library to
on key
on error
select 1
pop menu _mSysMenu
pop key
clear all
clear




*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴*
* Procedure...: Def_Reports
* Called by...: None
*
* Abstract....: Dummy procedure to list all reports used
* 				so they are included in the project when 
*				it is rebuilt.  Using Xreport in Funcs, 
*				reports are sometimes excluded from the project.
*
* Parameters..:
*
* Notes.......:
*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴*
procedure Def_Reports


report form Accrec 		preview
report form AccrecTR	preview
report form Actlives 	preview
report form AD&DBill 	preview
report form Aeg_form	preview
report form Affil 		preview
report form AffilBil	preview
report form Affilmem 	preview
report form Affilsum 	preview
report form AffCompL 	preview
report form AffSize		preview
report form Agent2 		preview
report form AgentHld	preview
report form AgentLic	preview
report form Agents 		preview
report form Agents2		preview
report form Agesex 		preview
report form AgeTrBal	preview
report form AgtVSGrp	preview
report form Allplan     preview
report form Alloc1 		preview
report form anniver2	preview
report form Annivers	preview
report form Ant_form	preview
report form AntPaid		preview
report form Aps_bill 	preview
report form Ardetail 	preview
report form Assoc 		preview
report form Assoc2 		preview
report form Assoc3 		preview
report form Assocfee 	preview
report form BadData2 	preview
report form BadDates 	preview
report form BadDate 	preview
report form BadOnes 	preview
report form BadSsno 	preview
report form Balances 	preview
report form BalList 	preview
report form Bilhis1 	preview
report form BillMail	preview
report form BillsWS		preview
report form BrokAssc	preview
report form	Brokincr	preview
report form Brokrinc	preview
report form BrokSSSI	preview
report form BrokTask	preview
report form BusSumm 	preview
report form CAIBrokr	preview
report form CAIBrok2	preview
report form Camp 		preview
report form Cancel 		preview
report form CancList	preview
report form CancLis2	preview
report form Canstat		preview
report form CarLives	preview
report form CarrBill	preview
report form CarrBils 	preview
report form CaseRecv	preview
report form CashSub		preview
report form CashSum		preview
report form CatCarr		preview
report form COBRA		preview
report form CF_Back		preview
report form CF_Cover	preview
report form CF_Covr2	preview
report form CF_Revw		preview
report form CF_Rpt		preview
report form ComGAs		preview
report form Comm_AP 	preview
report form Comm_ST		preview
report form CommCarr	preview
report form CommCar2	preview
report form CommModA	preview
report form CommOne 	preview
report form CommSumm	preview
report form CommSum2	preview
report form CompAff1	preview
report form CompAff2	preview
report form CompFone	preview
report form CompLst1	preview
report form CompLst2	preview
report form CompMod		preview
report form CompMod2	preview
report form CompMod3	preview
report form CoreTran	preview
report form CorePaid	preview
report form CostRate	preview
report form CR     		preview
report form CRAlloc		preview
report form CSL    		preview
report form csrcoden    preview
report form currbill   	preview
report form databad   	preview
report form Deals  		preview
report form Deals2 		preview
report form Deals3 		preview
report form DealChek	preview
report form Deposits 	preview
report form DepositC	preview
report form Detail 		preview
report form Detcomm 	preview
report form Detcomms    preview
report form Detlist	    preview
report form DTCRecv	    preview
report form DueBonus	preview
report form DueBonu2	preview
report form DuesID		preview
report form DuesID2		preview
report form DuesMHID	preview
report form DuesPaid	preview
report form DuesTerm	preview
report form DupInv	    preview
report form DupSubs	    preview
report form Earnings	preview
report form Emisdisk	preview
report form Emisdsk2	preview
report form EmpGroup	preview
report form Endorse		preview
report form FaxCover	preview
report form FBCash 		preview
report form FBDental	preview
report form FBHealth	preview
report form FBProfil	preview
report form Financal	preview
report form Formltr		preview
report form Formltr2	preview
report form Formltr3	preview
report form Formltr4	preview
report form Formltr5	preview
report form FormltrQ	preview
report form GAPrem		preview
report form GAPrem2		preview
report form GLChart		preview
report form ganame		preview
report form GHI_Form	preview
report form GHI_List	preview
report form GHILives	preview
report form GHIAppro	preview
report form GHIAppr2	preview
report form GoodTwos	preview
report form GroupAnn	preview
report form GAGRPANN	preview
report form HIP_Bill	preview
report form HIPBill2	preview
report form HIPgood		preview
report form HIPgood2	preview
report form HIP_Form	preview
report form HIPMemb		preview
report form HIPRest		preview
report form HPBILLD		preview
report form HPBILLS		preview
report form HPX_form	preview
report form IncRpt1		preview
report form ImfChang	preview
report form IncRpt2		preview
report form IncRpt3		preview
report form IncRpt4		preview
report form InHouse		preview
report form InvJour		preview
report form Invtot		preview
report form Journal		preview
report form Late_aff	preview
report form LByMonth	preview
report form Listcomp    preview
report form ListBBal    preview
report form ListStat	preview
report form Listterm	preview
report form LostReas	preview
report form MastHIP		preview
report form MDN_Form	preview
report form MDNYPaid	preview
report form MDNYrep1	preview
report form MDNYREST	preview
report form MedSubs		preview
report form MissRate	preview
report form MMedAge		preview
report form ModMove		preview
report form ModMoveA	preview
report form ModRegn		preview
report form ModRegn2	preview
report form Movement	preview
report form Multtwos	preview
report form Naibonus	preview
report form Newemp		preview
report form NewGHI		preview
report form NewLost		preview
report form NewLost2	preview
report form NewLost3	preview
report form NewLos21	preview
report form NewLos22	preview
report form NewLosW2	preview
report form NewSubs		preview
report form NoBenef		preview
report form NoBills		preview
report form NoMoney		preview
report form NoNewBus	preview
report form Notactiv	preview
report form NoteBdId	preview
report form NoteBrkD	preview
report form NoteBrkR	preview
report form NoteBrkT	preview
report form NoteBrkU	preview
report form BrokTask	preview
report form NoLicens	preview
report form NoteCCSR	preview
report form NoteGHI		preview
report form Noterptd	preview
report form Noterptt	preview
report form Noterptu	preview
report form Noterptv	preview
report form Notestat	preview
report form Notetask	preview
report form NotetasU	preview
report form NotPaid2	preview
report form NYS4ATT		preview
report form OneOnTwo	preview
report form PaidOne 	preview
report form PaidStat	preview
report form PayBillS	preview
report form PremComm	preview
report form Produce		preview
report form Produc21	preview
report form Produc22	preview
report form Produc3		preview
report form Produc31	preview
report form Produc32	preview
report form Produc33	preview
report form Prod31GA	preview
report form Prod32GA	preview
report form ProduceS	preview
report form P_Roster	preview
report form Proster2	preview
report form Proster3	preview
report form Purge		preview
report form REAB		preview
report form REC_Form	preview
report form REC999CR	preview
report form RECSumm1	preview
report form RECSumm2	preview
report form ReinCom2	preview
report form ReinPay		preview
report form RenewalA	preview
report form RenewalB	preview
report form RenewalC	preview
report form Reptop		preview
report form ReqCan03	preview
report form ReqCancl	preview
report form ReqStat		preview
report form Requal03	preview
report form Resign		preview
report form Resp2003	preview
report form RetireID	preview
report form RQNoResp	preview
report form S_Region	preview
report form SAddress	preview
report form SAddres2	preview
report form SAGACOST	preview
report form SAGASELC	preview
report form SAGASELL	preview
report form SD_Form		preview
report form SellRate	preview
report form Short 		preview
report form SR_B		preview
report form SR_B_E		preview
report form SR_W		preview
report form SR_W_E		preview
report form SR_GA		preview
report form SR_GA_E		preview
report form SRCover		preview
report form SRCoverG	preview
report form SREMList	preview
report form Srpartne	preview
report form Sub_Form	preview
report form TermCnts	preview
report form TermCom2	preview
report form TermComp	preview
report form TermDent	preview
report form TermMDNY	preview
report form TermSuba	preview
report form TermSubs	preview
report form TUCA_CNC	preview
report form TUCCAid		preview
report form Turn65		preview
report form Unpaid		preview
report form UnSent		preview
report form UnumSum		preview
report form USL_form	preview
report form USLAge70	preview
report form UWTrack1	preview
report form VP			preview
report form VP2			preview
report form VP3			preview
report form W_Approv	preview
report form W_County	preview

label  form AD&DCert	preview
label  form agent3		preview
label  form brokers		preview
label  form brokers2	preview
label  form Complbl		preview
label  form Complbl2	preview
label  form Complbl3	preview
label  form EmpLbl3		preview
label  form FileLab		preview
label  form FileLab2	preview
label  form TALABEL		preview


Return lbOK

*EOP Def_Reports
