***********************************************************************
* EF 07/06/2016: checks if Tag is RUSH #44247
***********************************************************************
PARAMETERS c_clcode, n_tag
LOCAL omedb as Object
LOCAL  l_rush, n_curarea
n_curarea = SELECT()
l_rush = .f. && assume not a RUSH
omedb=createobj("medgeneric")
omedb.closealias('Tgstatus')
c_sql= "SELECT [dbo].[GetTagRushStatus] ('" + fixquote(c_clcode) + "','" + STR(n_Tag) + "')"
omedb.sqlexecute(c_sql,'Tgstatus')	
l_rush =NVL(Tgstatus.exp,.F.)
RELEASE omedb
SELECT (n_curarea)
RETURN l_rush
