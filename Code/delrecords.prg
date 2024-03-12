*PROCEDURE DelRecords
PARAMETERS cAlias
LOCAL c_Alias as String
c_Alias=ALIAS()
oMed = CREATE("generic.medgeneric")
SELECT (cAlias)

SCAN FOR action="D" AND NOT EMPTY(TBLKEY)
SCATTER memvar
*omed.sqlexecute("Delete " + m.tblname  + " where id_" + m.tblName  + "='"  + m.tblKey + "'"  ,"")
lcSQLLine="update "+m.tblname + " set active=0, deleted='"+TTOC(DATETIME())+"', "+;
"deletedby='CANCELED BY "+ALLTRIM(goApp.CurrentUser.ntlogin)+"'"+;
" where id_" + ALLTRIM(m.tblName)  + "='"  + m.tblKey + "'"
omed.sqlexecute(lcSQLLine)
ENDSCAN
SELECT (c_Alias)

RETURN 
