**set dates based on SQL Server date
LOCAL o_date as Object

o_date=CREATEOBJECT('dataconnection.cntdataconn')
o_date.sqlpassthrough("exec dbo.getsqldate","curdate")

*!*	o_date=CREATEOBJECT('medgeneric')
*!*	n=o_date.sqlexecute("exec dbo.getsqldate","curdate")

IF USED("curdate")
	d_today=TTOD(curdate.exp)
	c_today=DTOC(d_today)
	t_today=(curdate.exp)
	ct_today=TTOC(curdate.exp)
	USE IN curdate
ENDIF

RELEASE o_date