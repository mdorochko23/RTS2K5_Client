*------------------------------------------------------------*
*//Report testing routine
*//
*// 	E.g. = ReportInit()
*//
*// Note: This is a developer utility.
*//
*------------------------------------------------------------*
Public vsTitle
Local lnConn

lnConn = sqlstringconnect("driver=SQL Server;server=meiudcdburner01;database=CAI_Albany")

If lnConn > 0 

	vsTitle = "Test Report Title"

	Set Procedure To appProcLib Additive

	If Used("sysdata")
		Use In SysData
	Endif
	
	= SQLExec(lnConn, "Select * from sysdata where [file] = 'NYSBG'", "sysdata")
	
	if used("sqlresult")
		select sqlresult
	endif
	
Else

	= MessageBox("Unable to connect to SQL Server.", 16, "Connection Error")

Endif