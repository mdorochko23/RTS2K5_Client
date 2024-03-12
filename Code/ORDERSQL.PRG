
PARAMETERS c_clcode, c_Attycode, n_tagno
LOCAL l_RetVal as Boolean, l_done as Boolean, C_STR as String, c_code as String, c_Atty as String
LOCAL oMed as Object 
STORE .f. to l_RetVal, l_done

oMed = CREATEOBJECT("generic.medgeneric")
c_code=oMed.cleanstring(c_clcode)
c_Atty=oMed.cleanstring(c_Attycode)
C_STR=""
C_STR=" EXEC DBO.CallOrdersbyClTagAtty " + c_code + "," +  c_Atty  + ",'" + 	STR(n_tagno) + "'"


*!*	C_STR="SELECT o.id_tblorders, o.ID_tblbills, o.cl_code, o.tag, o.at_code, o.response, " ; 
*!*		+ " CONVERT(CHAR(10), o.date_order, 101) as date_order, CONVERT(CHAR(10), o.date_decln, 101) as date_decln, " ; 
*!*		+ " CONVERT(CHAR(10), o.date_cancl, 101) as date_cancl, CONVERT(CHAR(10), o.date_ship, 101) as date_ship, " ; 
*!*		+ " o.handling, CONVERT(CHAR(10), o.date_bill, 101) as date_bill, CONVERT(CHAR(10), o.date_fbreq, 101) as date_fbreq, " ; 
*!*		+ " o.billcat, o.numcopy, o.fedex, o.cred_hold, o.shiptype, o.track_no, o.acct_mgr, o.sales_per, o.pkg_count, " ; 
*!*		+ " CONVERT(CHAR(10), o.created, 101) as created, o.createdby, CONVERT(CHAR(10), o.edited, 101)as edited, " ; 
*!*		+ " CONVERT(CHAR(10), o.deleted, 101) as deleted, o.deletedby, o.editedby, " ; 
*!*		+ " CONVERT(CHAR(10), o.retired, 101) as retired, " ; 
*!*	    + "o.retire, o.retiredby,o.active,o.cdnum,	" ; 
*!*		+ " CONVERT(CHAR(10), o.date_bill, 101) as date_bill " ; 
*!*		+ " FROM tblorder o WITH (nolock,INDEX (ix_tblorder_1)) "  + ;
*!*	    " WHERE cl_code=" + c_code+ " AND at_code=" + c_Atty + " and tag='" + ;
*!*		STR(n_tagno)+ "' AND o.active=1 AND o.deleted is null"
	
l_done=oMed.sqlexecute(C_STR, "Order")
IF l_done 
	l_RetVal=.T.		
	INDEX on ALLTRIM(UPPER(cl_code))+"*"+ALLTRIM(UPPER(at_code))+"*"+ALLTRIM(STR(tag)) tag clatu additive	
ENDIF
RELEASE oMed
RETURN l_RetVal
	







