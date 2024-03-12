PARAMETERS c_client, n_tag
LOCAL oSql AS OBJECT, l_Got11 AS Boolean, l_txn11 as Boolean
l_Got11=.F.
l_txn11=.f.
oSql = CREATEOBJ("generic.medgeneric")

*DO addlogline  WITH n_Tag, "-get txn11: " , "get11txn.pr"

IF USED('Timesheet')
	SELECT Timesheet
	USE	
ENDIF

c_sql="exec [dbo].[GetTxn11Line] '" + fixquote(c_client) + "','" + STR(n_Tag) + "' "

l_Got11=oSql.sqlexecute(c_sql,'Timesheet')

IF NOT l_Got11 and EOF()
	gfmessage("No txn 11 was found. ")
ELSE
	l_txn11=.t.
ENDIF
RELEASE oSql

RETURN  l_txn11
