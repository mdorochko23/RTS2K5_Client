LOCAL l_Retval, l_continue
LOCAL oSqlCon AS OBJECT
oSqlCon = CREATEOBJ("generic.medgeneric")
STORE "" TO c_sql
l_Retval =.F.
STORE .f. TO l_skip && skip checking empty caps for Asb NYC if a new case's order has that data
DO CASE
CASE EMPTY( pc_rqatcod)

	lc_message = "Requesting Attorney is missing from case! Go to 1 screen."
	o_message = CREATEOBJECT('rts_message',lc_message)
	o_message.SHOW
	DO UpdToPreIssue IN SUBP_PA WITH "4"
	l_Retval=.T.
&&07/22/2011 DO NOT ALLOW WITH AN ISSUE TILL CAPS ARE FILLED
CASE EMPTY( ALLTRIM(pc_plcaptn)) OR EMPTY( ALLTRIM(pc_dfcaptn))
&&08/20/2013  pl_NYCAsb=.T. and pl_NJAsb=.T.  use casecap1 and casecap2 even before the case is released (per Alec)
IF tyPe ('pl_F2newway')="U"
pl_F2newway=.f.
endif
	IF pl_F2newway AND (pl_NYCAsb OR pl_NJAsb )
		l_continue=.F.
		c_sql="select [dbo].[NYCGetQCCaseCaptions] ('" + pc_lrsno + "')"
		l_ok=oSqlCon.sqlexecute(c_sql,"CaseCaps")
		IF  l_ok  AND !EOF()
			l_skip =NVL(CaseCaps.EXP,.F.)
		ENDIF
	ENDIF

	
IF NOT l_skip
	lc_message = IIF(EMPTY( pc_plcaptn),"Plaintiff Caption is missing. Please edit the case.", "Defense Caption is missing. Please edit the case.")
	o_message = CREATEOBJECT('rts_message',lc_message)
	o_message.SHOW
	l_Retval=.T.
endif

ENDCASE
RELEASE oSqlCon
RETURN  l_Retval
