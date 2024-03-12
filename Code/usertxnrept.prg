******************************************************************************
* Daily user transaction 5 and 11 report
******************************************************************************
LOCAL c_date,nc,nr,n_curarea,omed
n_curarea=SELECT()
c_date=DTOC(DATE())
pc_userid=ALLTRIM(GOAPP.currentuser.orec.login)

odate=CREATEOBJECT ('utility.frmjustgetdate')
odate.show
l_continue=IIF(odate.exit_mode='SAVE',.t.,.f.)
c_date=DTOC(odate.d_date)
odate.release
IF l_continue
	WAIT WINDOW "Collecting daily timesheet data. Please wait." NOWAIT NOCLEAR 
	omed= CREATEOBJECT('medgeneric')
	c_sql="exec dbo.gettransactionrpt 5,11,'"+c_Date+"','"+pc_userid+"'"
	nr=omed.sqlexecute(c_sql,'viewtrans')
	WAIT CLEAR 
	IF RECCOUNT('viewtrans')>0
		INDEX ON STR(txn_code)+STR(lrs_no)+STR(tag) tag rept
		REPORT FORM usertxnrpt.frx NOEJECT NOCONSOLE TO PRINTER
	ELSE
		gfmessage("No daily timesheet transactions located.")
	ENDIF
ENDIF
IF USED('viewtrans')
	USE IN viewtrans
ENDIF
SELECT (n_curarea)