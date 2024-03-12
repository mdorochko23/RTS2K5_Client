PARAMETERS n_RT, n_tagn, d_Date
**01/29/16  Added "A" hold to that process #20026
 

LOCAL  oMed1 AS OBJECT, cAlias AS STRING
cAlias =ALIAS()
oMed1 = CREATEOBJECT("generic.medgeneric")
oMed1.CLOSEALIAS("HoldJob")

DO CASE
CASE  PC_ISSTYPE='S'
	oMed1.sqlexecute("select dbo.ChkRpsHoldQueuebyCourtSet ('" +STR(n_RT) + "','" + STR(n_tagn) + "','" + DTOC(d_Date) + "')","HoldJob")
OTHERWISE
	oMed1.sqlexecute("select dbo.ChkRpsHoldAuthorization('" +STR(n_RT) + "','" + STR(n_tagn) + "','" + DTOC(d_Date) + "')","HoldJob")
ENDCASE

IF USED('HoldJob')
	n_spec=NVL(HoldJob.EXP,0)
	IF n_spec=0
		gfmessage('Cannot find a pending request in the RPS Hold Print Queue for RT# ' + STR(n_RT)  + ' and Tag# '+ ALLTRIM(STR(n_tagn)) + '. Try update Hold Request later or contact IT dept.')
		mv=""
		c_PrintJob="" && cancel
	ELSE
		n_spec=NVL(HoldJob.EXP,0)

		oMed1.sqlexecute(" exec rpswork.dbo.ResubmitOnHoldJobFromUpdateHoldRequest '" + + STR(n_spec)+ "','" + ALLTRIM(pc_userid)+ "'" )
			
		
		**02/24/16: added txn 4 #32204
		DO updhld4 WITH n_tagn
	ENDIF
ENDIF


IF NOT EMPTY(cAlias)
	SELECT (cAlias)
ENDIF
RELEASE oMed1
RETURN n_spec
