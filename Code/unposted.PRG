#Include App.h

*<cai_fpw26>
* Program....:	UNPOSTED.PRG
* Version....:	2.0
* Author.....:	Robert A. Perritt
* Date.......:	August 16, 1995
* Notice.....:	Copyright (c) 1995 NYSBG / CAI, All Rights Reserved.
* Compiler...:	FoxProW 2.6
* Abstract...:	Print unposted new enrollments
* Changes....:	
*			 :
*
* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Local lcTitle, loForm, lsSQL, loMediator

*//Build report title
lcTitle = "Unposted New Enrollments"

*//Display wait form
loForm = goApp.OpenForm("app.frmWait", "O", "", "Searching for Unposted New Enrollments....")

*//Build SQL statement
lsSQL = "[dbo].[usp_AdminDailyPostGetUnposted]"

*//Get results
loMediator = Create("medAdministration")
loMediator.SQLExecute(lsSQL, loMediator.MasterAlias)

*//Close wait form
loForm.CloseForm(.T.)

*//Process results
goApp.Forms.OpenForm("Report.frmPrintReport", "M", "", "UnPosted", lcTitle)

Return



do SystemHeader

set talk on

select Lname, Fname, SSNO, B_Date1 as Effective, Company, U_ID, U_Date ;
	from DAILY ;
	where daily.Type = "N" ;
	order by 4, 1, 2;
	into cursor QUERY
	
set talk off

m.Title = "Unposted New Enrollments"

select QUERY
go top
if reccount() = 0
	=Alert("No unposted new enrollments were found", "ok", "info", "Daily Posting")
else
	do while .T.
		m.ExitFlag = 0
		do GetDest.spr
		if lastkey() = 27
			exit
		endif
	
		do case
			case m.ExitFlag = 1
				report form UnPosted preview
	
			case m.ExitFlag = 2
				report form UnPosted to print prompt noconsole
				wait window nowait "Now printing..."
	
			otherwise
				exit
		endcase
	enddo
endif

use
select COMPANY
return
