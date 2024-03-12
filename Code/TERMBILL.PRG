#Include app.h

*<cai_fpw26>
* Program....:	TERMBILL.PRG
* Version....:	1.0
* Author.....:	Robert A. Perritt
* Date.......:	July 24, 1994
* Notice.....:	Copyright (c) 1994 Conference Associates, Inc., All Rights Reserved.
* Compiler...:	FoxProW 2.6
* Abstract...:	Terminations
* Changes....:	10/31/1996 - Changed it to use FindPlan and bill what CC is active each month,
*				regardless of what cc is in daily.dbf
*
* Changes....:  07/22/1997 - It will only delete the record from daily for future dates 
*				IF and ONLY IF - it was not done at the company level. (daily.Emis_ID <> 0).  
*				If no invoice was needed, it deleted the record and did not process emis,
*				but it should always process emis.  
*
* Changes....:  06/23/2000:  Per GHI, effective 06/26/2000, we will no longer do EMIS for
*   			terminations when the Company is terminated on IMFACT.   Their system will 
*				generate the EMIS once they term them on IMFACT.  For any companies terminatd 
*				at the company level, the EMIS is created here - at posting time.   Now we need 
*				to see if this is a term for an MGAPLAN.   If for an MGAPLAN, don't do EMIS. 
*				If not an MGAPLAN, do the EMIS. 
*				NOTE:  A company may also be terminated at the subscriber level - by terminating
*				the last active employee on the company.   That is done in E_PLAN3.prg.
*				See E_Plan.prg for further documentation.
*
* Changes....:	06/23/2000:  Only do EMIS for GHI carriers also.
*				We have to look in Carrier to see if this is an MGAPLAN or not.
*   			As long as were here, we can tell if this is a GHI carrier.
*   			So, only do EMIS if it's GHI AND an MGAPLAN.  
*
* Notes.......: 04/13/2000 - now uses company.Bill_Date1 as DueDate.
* 				02/15/2002 - now uses company.Bill_Date1 as DueDate for Health.
*							And uses 1 month prior to Company.BIll_Date1 as DueDate for Dues.
*				02/22/2002.  Dues Due Date is back to same as health - company.Bill_Date1.
* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

*//Create billing file
= Daily1()
#IF .F.

*//Post Invoices - load GHI EMIS file
= Daily5()

#ENDIF

Return
 
*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴*
* Procedure...: Daily1
* Called by...: Main
*
* Abstract....: Create billing file
*
* Parameters..:
*
* Notes.......:
*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴*
Procedure Daily1
Local loTherm, lsThermStr, lnCount, lnTotal, lbContinue, ;
			lnXmittal, lbErrorState, lsLastCompany, lnListInvoice, ;
			lnMasterInvoice, ldStart
			

private LastCompany, Invoice, List_Invoice, S_Date, BalForward, N, Xmittal, CC
private Days, DaysInMonth, EndOfMonth

* List_Invoice is the master invoice number for this affiliation.

* Days is the number of days to bill for - for prorating purposes
* DaysInMonth is the number of days in the current month.
* EndofMonth is the last day of the current month.

*//Default values
lbErrorState = .F.
lsLastCompany = Replicate("9", 36)  && 36 is length of GUID PK
lnCount = 0
lnListInvoice = 0

*//Initialiaze thermometer
lsThermStr = "TERMINATIONS: Building Invoice File"
loTherm = goApp.OpenForm("app.appfrmThermometer", "O")
loTherm.UpdateDisplay(,, lsThermStr)

*//Get current EMIS transmittal
lnXmittal = GetSysData("EMISXMIT", "key")

*//Get all daily terminations
SQLExecute("[dbo].[usp_TermBillGetDailyTerminations]", "c_dailyterm")
lnTotal = Reccount("c_dailyterm")

*//Clear out DAYBILL
SQLExecute("[dbo].[usp_TermBillClearDayBill]")

Select c_dailyterm
Scan
	
	*//Reset flag for current record
	lbContinue = .T.

	*//Do we have a valid company?
	If IsNull(c_dailyterm.companyname)
	
		*//Dispay error and move onto next record
		MessageBox("Invalid company: " + DisplayKey(c_dailyterm.companykey), ;
							 MB_ICONEXCLAMATION, ;
							 ("Daily: " + DisplayKey(c_dailyterm.dailykey)))
		lbContinue = .F.
	
	Endif
	
	If lbContinue

		*//New company?
		If (c_dailyterm.companykey <> lsLastCompany)
		
			*//Did an error occur for the last company?
			If lbErrorState
			
				*//Clear DAYBILL for the last company
				SQLExecute("[dbo].[usp_TermBillClearDayBillOneCompany] " + SQLConvToStr(lsLastCompany))
			
			Endif
		
			*//Get the affiliation record
*!*				SQLExecute("[dbo].[usp_TermBillGetAffil] " + SQLConvToStr(c_dailyterm.affilkey), "c_affil")
			*//BwV - 10-22-2004 - Change this to use the Affil mediator
			
			*//Did we get back an affiliation?
			If (Reccount("c_affil") == 0)

				*//Dispay error and move onto next record
				MessageBox("Invalid affiliation: " + DisplayKey(c_dailyterm.affilkey), ;
									 MB_ICONEXCLAMATION, ;
									 ("Daily: " + DisplayKey(c_dailyterm.dailykey)))
				lbContinue = .F.

			Endif
		
			If lbContinue
		
				*//Get Affiliation Master Invoice for Affiliations setup for LISTBILLS
				If ((c_affil.type == "L") And (c_affil.list_inv == 0))
				
					lnListInvoice = AffilGetNextInvoice(c_dailyterm.affilkey)
					
				Endif
				
				*//Do we need a master invoice #?
				If (c_dailyterm.master_inv == 0)
				
					lnMasterInvoice = CompanyGetNextInvoice(c_dailyterm.companykey)
					
				Endif

				*//Update some tracking info
				lsLastCompany = c_dailyterm.companykey
				lbErrorState = .F.

			Endif

		Endif  && (c_dailyterm.companykey <> lsLastCompany)

		*//Hold onto working date
		ldStart = TToD(c_dailyterm.b_date1)
		
	#IF .F.

		* --- Only delete for future dates if emis has already been done, 
		* --- ie, not a term or rein at company level.
		* --- If daily.Emis_Id = 0, it was done at company level. 
		if daily.B_Date1 > company.Bill_Date2 and daily.Emis_Id <> 0
			delete
			skip
			=UpGauge(1)
			loop
		endif	

		* - Process each month to be billed.  Because plan changes & rates may have changed,
		*	seek CLASCODE and PROFILE for each month processed.
		
		do while m.S_Date <= daily.B_Date2
		
			select DAYBILL
			set order to NewBill
			seek "T" + str(daily.Company, 6) + dtos(m.S_Date)
			if found()
				m.Invoice = daybill.Invoice
			else
				do while .T.
					m.Invoice = autokey("ACCREC")
					if !empty(m.Invoice)
						exit
					endif
					do Alert with "Failed to assign Invoice #","ok","info","New Invoice"
				enddo .T.
				m.Invoice = val(m.Invoice)
			endif
			go bottom
			select DAILY
			=seek(daily.Number, "EMPLOYEE")  			&& Findplan requires emplyoyee to be postioned properly
		

			* Find what clascode we should be billing for each month.  This is tricky when dealing
			* with terminated plans.  We need to use FindPlan, but Findplan finds the active cc
			* for a date.  We will be looking at canceled plans, but we still need to know what 
			* cc to give credit for.

			=seek(daily.ClasCode, "CLASCODE")
			=seek(clascode.Key, "PLANFILE")				&& FindPlan needs to know the plan (1=health, 2=dental, 7=life)
					 
			m.CC = Findplan(planfile.Plan, m.S_Date)

			=seek(daily.ClasCode, "CLASCODE")
			=seek(clascode.Key, "PLANFILE")				&& FindPlan changes position of planfile & clascode
					 
			* if cancelled and after last edate in plan, use clascode in daily, 
			* since we still need to give credit for the remaining months.
			if m.CC = 0 and m.S_date >= LastEdate(daily.Number, planfile.Plan)
				m.CC = daily.Clascode
			endif

		
				
			
			* - get the rates and commissions for this clascode and date
			
			if !FindRate(daily.Company, m.CC, m.S_Date)
				do Alert with "Unable to get Plan Rates for ClassCode [" + alltrim(str(m.CC)) ;
						+ "]  Company " + transform(daily.Company, "99-9999") ;
						+ " Employee <" + alltrim(daily.Fname) + " " + alltrim(daily.Lname) + ">" ;
						+ " for " + dtoc(m.S_Date), ;
						"ok", "stop", "Terminations"
				m.ErrFlag = .T.
				exit
			endif
			


			* --- Calculate days in each month/ amount to prorate.
			m.EndOfMonth 	= gomonth(fixdate(m.S_Date),1)-1
			m.Days 			= m.EndOfMonth - m.S_Date + 1
			m.DaysInMonth	= gomonth(fixdate(m.S_Date),1)-1 - fixdate(m.S_Date) + 1

			insert into DAYBILL ;
				(Type, Affil, AffilType, Company, Number) values ;
				("T", daily.Affil, daily.AffilType, daily.Company, daily.Number)
				
			replace daybill.B_Date		with daily.B_Date
			replace daybill.B_Date1		with m.S_Date
			replace daybill.B_Date2		with m.EndOfMonth
			replace daybill.Cov_Date1	with m.S_Date
			replace daybill.Cov_Date2	with m.EndOfMonth
			replace daybill.ClasCode	with m.CC
			replace daybill.Invoice		with m.Invoice
			replace daybill.Master_Inv	with company.Master_Inv
			replace daybill.List_Inv	with Affil.List_Inv

			* - 02/22/2002.   Due date for Dues office is same as health - company.Bill_Date1
			replace daybill.DueDate		with company.Bill_Date1
			
			 
			replace daybill.Plan		with planfile.Plan
			replace daybill.PlanType 	with planfile.PlanType
			replace daybill.Sell		with -planrate.Sell*m.Days/m.DaysInMonth
			replace daybill.Amount		with -planrate.Sell*m.Days/m.DaysInMonth
			replace daybill.GL_Cost 	with planfile.GL_Cost
			replace daybill.GL_Sell 	with planfile.GL_Sell
			replace daybill.Dis			with trim(planfile.Dis1) + " " + dtoc(m.S_Date) ;
										 + " - " + dtoc(daybill.Cov_Date2)
										 
			* - 04/02/2002: Use new function CostJan02() to get the right cost.
			* - That uses either cost or Sell * new remit % for GHI.  Still prorate # days.
			replace daybill.Cost 		with -1* CostJan02(daybill.Clascode, daybill.company, ;
												daybill.Cov_Date1, planrate.Sell, ;
												planrate.Cost)*m.Days/m.DaysInMonth

			replace daybill.Broker		with profile.Broker
			replace daybill.B_Fee		with -profile.B_Fee*m.Days/m.DaysInMonth
			replace daybill.Wholesaler	with profile.Wholesaler
			replace daybill.W_Fee		with -profile.W_Fee*m.Days/m.DaysInMonth
			replace daybill.Supervisor	with profile.Supervisor
			replace daybill.S_Fee		with -profile.S_Fee*m.Days/m.DaysInMonth
			replace daybill.Broker4		with profile.Broker4
			replace daybill.B4_Fee		with -profile.B4_Fee*m.Days/m.DaysInMonth
			replace daybill.Broker5		with profile.Broker5
			replace daybill.B5_Fee		with -profile.B5_Fee*m.Days/m.DaysInMonth
			replace daybill.Broker6		with profile.Broker6
			replace daybill.B6_Fee		with -profile.B6_Fee*m.Days/m.DaysInMonth
			replace daybill.Broker7		with profile.Broker7
			replace daybill.B7_Fee		with -profile.B7_Fee*m.Days/m.DaysInMonth
			replace daybill.MGA			with profile.MGA
			replace daybill.MGA_Fee		with -profile.MGA_Fee*m.Days/m.DaysInMonth
				
			replace daybill.U_ID	with daily.U_ID
			replace daybill.U_Date	with daily.U_Date
			replace daybill.U_Time	with daily.U_Time
			
			* --- In case we are prorating the first month, always pick the first of the next month.
			m.S_Date = fixdate(gomonth(m.S_Date,1))					&& next month
				
		enddo while m.S_Date <= daily.B_Date2

		* - EMIS
		*
		*	Note that Int_Xfer is true for internal transfers (change of employer).  We
		*	don't want the carrier to know about this!!
		*
		* - 06/23/2000:  Per GHI, effective 06/26/2000, we will no longer do EMIS for
		*   terminations when the Company is terminated on IMFACT.   Their system will generate
		*   the EMIS once they term them on IMFACT.  For any companies terminatd at the company 
		*	level, the EMIS is creatded here - at posting time.   Now we need to see if this
		*	is a term for an MGAPLAN.   If for an MGAPLAN, don't do EMIS.   If not an MGAPLAN,
		*   do the EMIS.  MGAPLANS are the ones on IMFACT.
		
		if !daily.Int_Xfer and !m.ErrFlag and daily.EMIS_ID = 0 and !daily.No_Send
			if seek(daily.Clascode, "CLASCODE")				&& do emis from clascode that was termed
				=seek(clascode.Key, "PLANFILE")
				=seek(planfile.Carrier, "CARRIER")
				=seek(daily.Number, "EMPLOYEE")
				set order to ID in PLAN
				=seek(daily.Planhist, "PLAN")
				
				* - We have to look in Carrier to see if this is an MGAPLAN or not.
				* - As long as were here, we can tell if this is a GHI carrier.
				* - So, only do EMIS if it's GHI and NOT an MGAPLAN.  
				
	       		* - 06/26/2000:  NOTE - GHI is not ready yet - so this will be commented out - 
	       		* - until they are ready.

				* - 07/17/2000: - the UNDO of last note on 6/26/2000 was done wrong. 
				* - It was encased in an if.f. statement, so none of it executed.
				* - Instead - just comment out this below statement.
				
				*			if !carrier.MGAPLAN and carrier.Dis1 = "GHI"
				* - When we go live with this - we can put this statement down below.
							 

				* - 09/12/2000: - Okay, GHI is ready for this.   Go live with it.
				* - Put the below IF statement back in
				if !carrier.MGAPLAN and carrier.Dis1 = "GHI"
				

					* - Put this here - if !carrier.MGAPLAN and carrier.Dis1 = "GHI"
					do EMIS with 055, daily.B_Date1
				
					* Now do EMIS for any dependants terminated same date & reason as employee
					* and only for GHI carriers
					select DEPEND
					seek employee.Number
					do while not eof() 

						if depend.Xmittal = m.Xmittal					&& only 1 emis transmittal per dependent
							exit
						endif

						if depend.Number <> employee.Number
							exit
						endif
					
						if depend.Terminated = employee.Terminated and depend.TermCode = employee.ResCode
							* - Parameter True means emis is put into EMISHOLD table, not EMIS table.
							* - IE, EMIS transactions will be created at Posting time.
							do TermDep2 in EMIS with .T.
						endif
					
						skip
					enddo while not eof()
					select DAILY
				endif carrier.MGAPLAN and carrier.Dis1 = "GHI"
			endif seek(daily.Clascode, "CLASCODE")
		endif !daily.Int_Xfer and !m.ErrFlag and daily.EMIS_ID = 0 and !daily.No_Send

		* --- if at company level, must delete here.  It wil not be deleted
		*		above.
		select DAILY
		if daily.B_Date1 > daily.B_Date2 and daily.Emis_Id = 0
			delete
		endif	

		=UpGauge(1)

#ENDIF

	Endif

	InKey(.25, "H")
	
	*//Update the thermometer
	lnCount = (lnCount + 1)	
	loTherm.UpdateDisplay(lnCount, lnTotal, lsThermStr)

EndScan

#IF .F.
=DeactGauge()

if m.ErrFlag											&& last company had boo-boo's
	select DAYBILL
	delete all for daybill.Company = m.LastCompany
endif
		

select DayBill
wait window nowait 'Calculating Invoice Totals...'

select Invoice,sum(Amount);
	from DayBill;
	where Type = "T";
	group by Invoice;
	into cursor Query
select Query
index on Invoice tag Invoice
select DayBill
set relation to Invoice into Query
replace all BillTotal with query.Sum_Amount
set relation to
select Query
use
wait clear

#ENDIF

return

*EOP Daily1





*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴*
* Procedure...: Daily5
* Called by...: Main
*
* Abstract....: Post Invoices - load GHI EMIS file
*
* Parameters..:
*
* Notes.......:
*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴*
procedure Daily5

private N, LastCompany, LastEmp, LastCC, LastInvoice

* - The following (created via CEE) is used to copy a record from DAYBILL into BILLHIST
private TYPE, AFFIL, AFFILTYPE, COMPANY, NUMBER, B_DATE, B_DATE1, B_DATE2, ;
        COV_DATE1, COV_DATE2, DUEDATE, CLASCODE, DIS, SELL, COST, GL_SELL, ;
        GL_COST, INVOICE, LIST_INV, PLAN, PLANTYPE, TRANSACT, POSTDATE, AMOUNT, ;
        BALFORWARD, BROKER, B_FEE, WHOLESALER, W_FEE, ;
        SUPERVISOR, S_FEE, BROKER4, B4_FEE, ;
        SEQ, BILLTOTAL

select DAYBILL
set order to 0
count to N for type = "T"
if N = 0
	select COMPANY
	return
endif

set order to COMPANY2
go top
seek "T"
LastCompany = 999999
LastInvoice = 9999999

set order to Number in CLASCODE
set order to Number in CARRIER
set order to Number in EMPLOYEE

=ActGauge("TERMINATIONS: Posting Invoices", N) 

do while not eof()
	
	if daybill.Type <> "T"
		exit
	endif daybill.Type <> "T"
	
	=UpGauge(1)
	
	if daybill.Company <> m.LastCompany or daybill.Invoice <> m.LastInvoice
	
		if m.LastCompany <> 999999
			select DAILY
			delete all for Type = "T" and str(Company,6) = str(LastCompany,6)
			select DAYBILL
		endif m.LastCompany <> 999999
		
		insert into ACCREC ;
			(Company, Type, Date, Desc, Invoice, Master_Inv, List_Inv, B_Date1, B_Date2,  ;
			 DueDate, Ref) values ;
			(daybill.Company, "B", date(), "Termination Bill: "+dtoc(daybill.B_Date1), ;
			 daybill.Invoice, daybill.Master_Inv, daybill.List_Inv, daybill.B_Date1, ;
			 daybill.B_Date2, daybill.DueDate, "T")
		
		m.LastCompany = daybill.Company
		m.LastInvoice = daybill.Invoice
		m.LastEmp = 0
	endif daybill.Company <> m.LastCompany
	
	replace accrec.Amount with accrec.Amount + daybill.Amount
	replace accrec.Bill_Amt with accrec.Amount

	scatter memvar
	select BILLHIST
	append blank
	gather memvar
	
	
	select DAYBILL
	delete	
	skip
enddo not eof()

if m.LastCompany <> 999999
	select DAILY
	delete all for Type = "T" and str(Company,6) = str(LastCompany,6)
	select DAYBILL
endif m.LastCompany <> 999999

=DeActGauge()
do Logit with 0,0,"Posted Termination Invoices"


return



*EOP Daily5

*____________________________________________________________________
*____________________________________________________________________
* Procedure: AffilGetNextInvoice
*
*	Description: Updates the specified AFFIL record with a new invoice
*							 number.
*
* Returns: Integer - Newly generated invoice number.
*
* Parameters: psAffilKey - Affiliation key.
*____________________________________________________________________
Procedure AffilGetNextInvoice
LParameters psAffilKey
Local	lnInvoiceNumber, lsSQL

*//Default valeus
lsSQL = "EXEC [dbo].[usp_TermBillUpdateAffilListInvoice] " + SQLConvToStr(psAffilKey) + ", NULL"

*//Run stored procedure
SQLExecute(lsSQL, "c_result")

*//Grab return value
lnInvoiceNumber = c_result.ListInvoiceNumber

*//Cleanup
CloseAlias("c_result")

Return lnInvoiceNumber

*____________________________________________________________________
*____________________________________________________________________
* Procedure: CompanyGetNextInvoice
*
*	Description: Updates the specified COMPANY record with a new invoice
*							 number.
*
* Returns: Integer - Newly generated invoice number.
*
* Parameters: psCompanyKey - Company key.
*____________________________________________________________________
Procedure CompanyGetNextInvoice
LParameters psCompanyKey
Local	lnInvoiceNumber, lsSQL

*//Default valeus
lsSQL = ("EXEC [dbo].[usp_TermBillUpdateCompanyMasterInvoice] " + SQLConvToStr(psCompanyKey) + ", NULL")

*//Run stored procedure
SQLExecute(lsSQL, "c_result")

*//Grab return value
lnInvoiceNumber = c_result.MasterInvoiceNumber

*//Cleanup
CloseAlias("c_result")

Return lnInvoiceNumber