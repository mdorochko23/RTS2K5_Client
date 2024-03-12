***********************************************************************
* EF 10/05/2016 : edited per  #49106
* EF 06/08/2016: checks if we allow to edit a SHIP METHOD
***********************************************************************
PARAMETERS c_clcode, n_tag, c_Atcode, c_user,  c_method
LOCAL omedbill AS OBJECT
LOCAL d_transdte , l_change, n_curarea, c_sql
n_curarea = SELECT()
l_change = .T. && allow by default
omedbill=CREATEOBJ("medgeneric")

omedbill.closealias('Edtok')

c_sql= ""
c_sql= "SELECT [dbo].[EditShipMethod] ('" + fixquote(c_clcode) + "','" + STR(n_tag) + "','" + fixquote(c_Atcode)+ "','" + c_user + "','" +  c_method + "')"
omedbill.sqlexecute(c_sql,'Edtok')
l_change=NVL(Edtok.EXP,.F.)
RELEASE omedbill
SELECT (n_curarea)
RETURN l_change
