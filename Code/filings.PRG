**10/21/13-  three modes:  n_mode  =0 , 1, 2
**0) non-electronic sets
**1) electronic sets
**2) by RT
**********************************************************************
PROCEDURE filings
PARAMETERS  n_mode
PRIVATE lc_Alias
PUBLIC  c_RTTag  AS STRING
LOCAL d_date AS DATETIME

_SCREEN.MOUSEPOINTER=11
lc_Alias = ALIAS()
c_RTTag=""
oMedF = CREATEOBJECT("generic.medgeneric")
oMedF.closealias('HoldReq')


**-- check if the specified case and tags have been entered
DO CASE
CASE n_mode =2

	IF  EMPTY(ln_RT) && added reprint by date  1/14/14

*d_date=gotopast(ld_DateFrom-1, .F., .F.)  && 1/14/14- make a reprint look a day back as we use a release date now on the entry form
		l_holdreq=oMedF.sqlexecute("Exec dbo.GetFilings_ReprintAllbyDate2'" + DTOC(ld_DateFrom)+ "','"+  DTOC(ld_DateFrom)+ "'," + STR(n_mode)  ,"HoldReq")

	ELSE


		WAIT WINDOW "Generating sets for  RT " +  ln_RT+ "  requests released on " + DTOC(ld_DateFrom)  NOWAIT
		c_client= GetClient(ln_RT)
		IF EMPTY(c_client)
			RETURN
		ELSE
			c_RTTag = " AND cl_code =   c_client  "

			l_holdreq=oMedF.sqlexecute("Exec dbo.GetHoldRequestsbyclcode '" + fixquote(c_client) + "'","HoldReq")

			IF  NOT EMPTY(ln_TagFrom) AND NOT EMPTY(ln_tagTo)
				c_RTTag = c_RTTag + " AND Tag =" +  TRANSFORM(ln_TagFrom,'999') + " AND req_type = 'S' "

			ENDIF
		ENDIF
	ENDIF && added reprint by date

CASE n_mode <=1
	c_RTTag=""
	WAIT WINDOW "Generating sets for " +  IIF(n_mode=0, "non -electronic", "electronic" )+ "  requests released on " + DTOC(ld_DateFrom)  NOWAIT
**07/07/2016 USE NEW STORED PROC
*l_holdreq=oMedF.sqlexecute("Exec dbo.GetHoldRequestsbydates_EfOrder '" + DTOC(ld_DateFrom)+ "','"+  DTOC(ld_Dateto)+ "'," + STR(n_mode) ,"HoldReq")
*l_holdreq=oMedF.sqlexecute("Exec dbo.GetHoldRequests2 '" + DTOC(ld_DateFrom)+ "','"+  DTOC(ld_Dateto)+ "'," + STR(n_mode) ,"HoldReq")
	l_holdreq=oMedF.sqlexecute("Exec dbo.GetCourtSetUnion'" + DTOC(ld_DateFrom)+ "','"+  DTOC(ld_Dateto)+ "'," + STR(n_mode) ,"HoldReq")
ENDCASE



_SCREEN.MOUSEPOINTER=0
RELEASE oMedF
RETURN l_holdreq
