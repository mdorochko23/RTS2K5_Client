***********************************************************************
* EF 10/05/2016 : edited per #49106
* EF 06/08/2016: checks if  we allow to edit a bill date
***********************************************************************
PARAMETERS c_clcode, n_tag, c_Atcode
LOCAL omedbill AS OBJECT
LOCAL d_transdte , l_change, n_curarea, c_user, c_sql
n_curarea = SELECT()
l_change = .T. && allow by default
omedbill=CREATEOBJ("medgeneric")
c_user =ALLTRIM( NVL(pc_Userid,''))
omedbill.closealias('EdtBill')
c_sql= ""
c_sql= "SELECT [dbo].[EditBilledDates] ('" + fixquote(c_clcode) + "','" + STR(n_tag) + "','" + fixquote(c_Atcode)+ "','" + c_user  + "')"
omedbill.sqlexecute(c_sql,'EdtBill')
l_change=NVL(EdtBill.EXP,.F.)
RELEASE omedbill
SELECT (n_curarea)
RETURN l_change
