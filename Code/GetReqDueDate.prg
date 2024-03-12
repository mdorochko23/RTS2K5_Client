**************************************************************
**Function GetReqDueDate
PARAMETERS  c_cl, n_tag, d_due
LOCAL o_med as Object, c_sql as String, l_recupdt as Boolean, d_storeddt as Datetime, c_alias as String
c_alias =ALIAS()
o_med = CREATEOBJ("generic.medgeneric")
l_recupdt=.f.
c_sql = "select Reqduedate as Due from tblRequest " + ;
				" WHERE cl_code = '" + fixquote(c_cl) +"' and tag ='" + STR(n_tag) + "' and active =1" 
				
l_recupdt= o_Med.sqlexecute (c_sql,"DueDt")

IF NOT l_recupdt OR EMPTY(NVL(DueDt.Due,''))	
	*gfmessage("Note: The Request's Duedate was not stored.")
	d_storeddt=d_due
ELSE
	SELECT DueDt	
	d_storeddt=CTOD(LEFT(DTOC(DueDt.Due),10))
use
	
ENDIF
IF NOT EMPTY(c_Alias)
SELECT (c_Alias)
endif
RELEASE o_med
RETURN d_storeddt