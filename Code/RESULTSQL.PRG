
**FUNCTION Resultsql
PARAMETERS lcSQLLine, lcCursor

LOCAL lnCurArea, loConn, lnConnHandle
lnCurArea=ALIAS()
loConn=CreateObject("RTS.Data.SQLConnection", "")

lnConnHandle=SQLSTRINGCONNECT(loConn.ConnectionString)

IF lnConnHandle>0
   SQLEXEC(lnConnHandle,lcSQLLine,lcCursor)
ENDIF 

SQLDISCONNECT(lnConnHandle)
IF NOT EMPTY(lnCurArea)
SELECT (lnCurArea)
ENDIF
RETURN lnConnHandle
