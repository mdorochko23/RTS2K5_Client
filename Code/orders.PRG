*PROCEDURE orders
**************************************************************************
*** EF #43637 : orders
**************************************************************************
PARAMETERS n_tagno
** pc_clcode = cl_code of case receiving orders
** n_tagno = deponent number for item receiving orders
WAIT CLEAR
PRIVATE ordused, tabused, attused, n_CurFile, c_OrdResp, d_Ordered, ;
	d_Declined, l_hold, c_Response, tasused, n_Pcopies , n_Pcopies3   &&c_Shiptype
LOCAL lcSQLLine AS STRING, oMed AS OBJECT
l_hold = .F.
lDSOrd=.F.
n_CurFile = SELECT()
oMed=CREATEOBJECT("generic.medgeneric")
oMed.closealias("viewBills")
**list of participating attys on a case
lcSQLLine="exec dbo.getBills2Order '"+ALLTRIM(fixquote(pc_clcode))+"'"
oMed.sqlexecute(lcSQLLine,"viewBills")

SELECT viewBills
IF RECCOUNT()=0 OR EMPTY(ALLTRIM(pc_clcode))
	gfmessage("Attorney list for client code="+ALLTRIM(UPPER(pc_clcode))+" is empty!"+CHR(13)+;
		"Can't add any orders.  Please notify IT department")
	RETURN
ENDIF
WAIT WINDOW  "Adding Orders. Please wait." NOWAIT NOCLEAR

SCAN
	c_Response = UPPER(ALLTRIM(viewBills.Response))
	c_Atty=fixquote(viewBills.at_code)
** check if the shipment methods are
	oMed.sqlexecute("SELECT [dbo].[NeedsShipSetting] ('" +ALLTRIM(fixquote(pc_clcode)) + "','" +  c_Atty + "')", "ChkShip")
	IF ChkShip.EXP
		gfmessage("Can not find a proper shipment setting for this attorney("  + ALLTRIM(c_Atty) +  "). Please note the atty code and update it manually." )
	ENDIF
** credit hold status
	l_hold = .F.
	IF c_Response = "T"
		l_hold=viewBills.bhold
	ENDIF

** check the orders

	l_ord=getorders (pc_clcode, viewBills.at_code, n_tagno)


	SELECT ORDER
	SEEK ALLTRIM(UPPER(pc_clcode))+ALLTRIM(UPPER(viewBills.at_code))+ALLTRIM(STR( n_tagno))
	IF FOUND()
		IF ALLTRIM(UPPER(ORDER.Cl_Code))==ALLTRIM(UPPER(pc_clcode)) AND ;
				ALLTRIM(UPPER(ORDER.at_code))== ALLTRIM(UPPER(viewBills.at_code)) AND ;
				ORDER.TAG == n_tagno
** update orders
			lcSQLLine=""
			lcSQLLine="Exec dbo.UpdateOrdersbyTag '" + viewBills.id_tblBills + "','" + c_Response + "'," +IIF(l_hold=.T.,"1","0")+  ",'" + STR (NVL(viewBills.NumCopy,0)) + "','"  +;
				",'" + ALLTRIM(fixquote(pc_clcode)) + "','" + c_Atty + "','" + STR(n_tagno) + "','" +viewBills.billcat + "','" + ;
				IIF(viewBills.FedEx=.T.,"1","0")+", '"+ALLTRIM(UPPER(NVL(viewBills.Handling,"")))+"', '" +  ALLTRIM(UPPER(NVL(pc_userid,"")))+"','" + ;
				ALLTRIM(UPPER(NVL(viewBills.Acct_Mgr,""))) + "','" + ALLTRIM(UPPER(NVL(viewBills.Sales_per,"")))  + "'"


			oMed.sqlexecute(lcSQLLine)


		ENDIF
	ELSE
** add orders
		lcSQLLine=""
		lcSQLLine="Exec dbo.AddOrdersbyTag '" + viewBills.id_tblBills + "','" + c_Response + "'," +IIF(l_hold=.T.,"1","0")+  ",'" + STR (NVL(viewBills.NumCopy,0)) + "','"  +;
			ALLTRIM(fixquote(pc_clcode)) + "','" + c_Atty + "','" + STR(n_tagno) + "','" +viewBills.billcat + "'," + ;
			IIF(viewBills.FedEx=.T.,"1","0")+", '"+ALLTRIM(UPPER(NVL(viewBills.Handling,"")))+"', '" +  ALLTRIM(UPPER(NVL(pc_userid,"")))+"','" + ;
			ALLTRIM(UPPER(NVL(viewBills.Acct_Mgr,""))) + "','" + ALLTRIM(UPPER(NVL(viewBills.Sales_per,"")))  + "'"


		oMed.sqlexecute(lcSQLLine)


	ENDIF
	SELECT viewBills
ENDSCAN

WAIT CLEAR
IF NOT EMPTY( n_CurFile)
	SELECT ALIAS( n_CurFile)
ENDIF
RELEASE oMed
RETURN


***********************************************************************************************************************************************
PROCEDURE  getorders 
PARAMETERS c_clcode, c_Attycode, n_tagno
LOCAL l_RetVal as Boolean, l_done as Boolean, C_STR as String, c_code as String, c_Atty as String
LOCAL oMed as Object 
STORE .f. to l_RetVal, l_done

oMed = CREATEOBJECT("generic.medgeneric")
c_code=oMed.cleanstring(c_clcode)
c_Atty=oMed.cleanstring(c_Attycode)
C_STR=""
C_STR=" EXEC DBO.OrdersbyClTagAtty " + c_code + "," +  c_Atty  + ",'" + 	STR(n_tagno) + "'"	
l_done=oMed.sqlexecute(C_STR, "Order")
IF l_done 
	l_RetVal=.T.		
	INDEX on ALLTRIM(UPPER(cl_code))+ALLTRIM(UPPER(at_code))+ALLTRIM(STR(tag)) tag clatu additive	
ENDIF
RELEASE oMed
RETURN l_RetVal
	



