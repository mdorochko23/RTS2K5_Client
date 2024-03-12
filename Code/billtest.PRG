*<cai_fpw26>
*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴*
* Procedure...: FutureDates
*
* Abstract....: Produce a report showing all key tables that have either ternination or 
*				effective dates more than 500 days from today.    Since Century is now set on,
*				Dates accept 4 digits in the year, users are still inputting only 2.
*				This results in erroneous dates with years such as 9919 instead of 1999. 
*				It will check Effective and Termination dates in Companies, Employees,
*				PLAN, EMPLOYEE, DEPENDENTS, and EMIS.
*
*
* Called by...: M_BILLS, Y_BILLS, Q_BILLS
*
* Calls.......: GETSYSDATA - function in FUNCS.prg to return a value of a field from SYSDATA.
*				XREPORT - procedure in Funcs.prg to process a report form.
*
*
* Output...........:  A report is produced, with the option of printing.
*
* Error Conditions.:  If the data in any tables are incorrect, the results will be in error.
*
* PostConditions...:  Any cursors created are closed, and it selelcts the work area that
*						was current before this routine was invoked. 
*
* Notes.......:
*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴*
Procedure FutureDates
Local lcTitle, loForm, lsSQL, loMediator

*//Build report title
lcTitle = "Future Invalid Effective and Termination Dates"

*//Display wait form
loForm = goApp.OpenForm("app.frmWait", "O", "", "Searching for invalid future dates....")

*//Build SQL statement
lsSQL = "[dbo].[usp_AdminDailyPostFutureDates]"

*//Get results
loMediator = Create("medAdministration")
loMediator.SQLExecute(lsSQL, loMediator.MasterAlias)

*//Close wait form
loForm.CloseForm(.T.)

*//Process results
goApp.Forms.OpenForm("Report.frmPrintReport", "M", "", "baddates.frx", lcTitle)

*EOP FutureDates
***********************************************************************************

