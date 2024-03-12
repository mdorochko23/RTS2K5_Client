**07/05/2017: validate TX courts data for the docs. #60359
PARAMETERS lcCourt
LOCAL l_Retval, l_continue,  c_TxType, c_msg
LOCAL oSqlCon AS OBJECT
oSqlCon = CREATEOBJ("generic.medgeneric")
STORE "" TO c_sql, c_TxType, c_msg
l_Retval=.T. && ASSUME ALL DATA IS CORRECT

IF pl_txcourt

	IF EMPTY(ALLTRIM( lcCourt))
		c_msg= "Please pick a valid court for that case or Exit."
	ELSE





&& Rule #1 TX court should have a courtype
		oSqlCon.closealias ("TxType")
		c_sql="select [dbo].[GetTXcourttype] ('" + lcCourt + "')"
		l_ok=oSqlCon.sqlexecute(c_sql,"TxType")
		IF  l_ok  AND !EOF()
			c_TxType=TxType.EXP
		ENDIF


&& Rule #2 TX court should have a county

		c_county=fixquote(NVL(pc_c1Cnty,''))

&& Rule #3 TX cases need District on the case

		c_distrct=NVL(pc_distrct,'')


		DO CASE

		CASE EMPTY(c_TxType)
			c_msg="Tag cannot be created the court is missing the TX Court Type. Please edit the court."
		CASE EMPTY(c_county)
			c_msg="The Court Selected is missing the County. Please edit the court."
		CASE EMPTY(c_distrct)
			c_msg="The court number must be added to the District field to continue adding this request.  Please edit the case."

		OTHERWISE
			c_msg=""
		ENDCASE

	ENDIF

	IF !EMPTY(c_msg)
		o_message = CREATEOBJECT('rts_message',c_msg)
		o_message.SHOW
		l_Retval=.F.
	ENDIF
ENDIF

RELEASE oSqlCon
RETURN  l_Retval
