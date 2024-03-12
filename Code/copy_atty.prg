**************************************************************************************
**	Copy_Atty program
**  copy all participating attorney info to a new case 
**************************************************************************************
PROCEDURE copyatty
LPARAMETERS c_oldclcode,c_newclcode,c_newid


ogen=CREATEOBJECT('medgeneric')
**10/01/18 SL #109598
*c_sql="SELECT * FROM tblBill WITH (index (ix_tblbills_2)) WHERE cl_code='&c_oldclcode.' AND active=1 AND deleted IS null"
c_sql="SELECT * FROM tblBill WHERE cl_code='&c_oldclcode.' AND active=1 AND deleted IS null"
*--n=sqlexec(n_conn,c_sql,'tabills')
ogen.sqlexecute(c_sql,'tabills')
SELECT tabills

SCAN
    lcSQLLine="exec dbo.InsertBillRecord '"+ALLTRIM(tabills.id_tblBills)+"', "+;
    "'"+ALLTRIM(fixquote(c_newclcode))+"', '"+ALLTRIM(c_newid)+"', '"+DTOC(DATE())+"', "+;
    "'"+ALLTRIM(goApp.CurrentUser.ntlogin)+"'"
    ogen.sqlexecute(lcSQLLine)
    
*!*		c_sql="INSERT INTO tblbill "+;
*!*			"(Cl_code,At_Code,[Response],Date_Req,[Code],"+;
*!*			"[Plan],Plan_type,BillCat,NumCopy,Acct_mgr,Sales_per,"+;
*!*			"bill_to, adjuster, insured, claim_no, file_no, ordered_by,"+; 
*!*			"active,createdBy,created,id_tbldefendant,id_tblmaster) "+;
*!*			"VALUES "+;
*!*			"('"+;
*!*			c_newclcode+"',"+;
*!*			cleanstring(tabills.at_code)+",'"+;
*!*			tabills.response+"','"+;
*!*			c_today+"','"+;
*!*			tabills.code+"','"+;
*!*			tabills.plan+"','"+;
*!*			tabills.plan_type+"','"+;
*!*			tabills.billcat+"',"+;
*!*			STR(tabills.numcopy)+",'"+;
*!*			tabills.acct_mgr+"','"+;
*!*			tabills.sales_per+"','"+;
*!*			fixquote(tabills.bill_to)+"','"+;
*!*			fixquote(tabills.adjuster)+"','"+;
*!*			fixquote(tabills.insured)+"','"+;
*!*			fixquote(tabills.claim_no)+"','"+;
*!*			fixquote(tabills.file_no)+"','"+;
*!*			fixquote(tabills.ordered_by)+"',"+;
*!*			"1"+",'"+;
*!*			goApp.CurrentUser.ntlogin+"','"+;
*!*			c_today+"','"+;
*!*			tabills.id_tbldefendant+"','"+;
*!*			c_newid+"'"+;
*!*			")"

*!*	*--		n=sqlexec(n_conn,c_sql)

*!*		ogen.sqlexecute(c_sql)

	*-- Up date the case level attorney ship ment data
	*-- first check if there is already a record there

	c_sql="select * from tblShip "+;
		" where cl_code='"+c_oldclcode+"' and at_code="+cleanstring(tabills.at_code)+;
		" and active=1 and deleted IS null"

*--	n=sqlexec(n_conn,c_sql,'gtaship')
	ogen.sqlexecute(C_SQL,"gtaship")
	SELECT gtaship
	IF RECCOUNT("gtaship")>0
	    c_SQL="SELECT id_tblBills FROM tblbill WHERE cl_code='"+c_newclcode+"'"+;
			" and at_code="+cleanstring(tabills.at_code)+" and active=1 and deleted IS null"

*--		n=sqlexec(n_conn,c_sql,'newtabills')
		ogen.sqlexecute(c_sql,'newtabills')

		c_sql="Insert into tblShip (cl_code, at_code,rpapernum,"+;
			"rcdnum, rvsnum, rdsnum, rshipftp, rcdtype,rdstype, rftptype,"+;
			"rcdincrem,rcdfile,rsinglepg,"+;
			"mpapernum, mcdnum, mvsnum, mdsnum, mshipftp, mcdtype,"+;
			"mdstype, mftptype,mcdincrem,mcdfile,msinglepg,id_tblbills, created, createdby, active, retire)"+;
			" values ("+;
			"'"+c_newclcode+"',"+;
			cleanstring(tabills.at_code)+","+;
			"'"+NVL(IIF(gtaship.rpapernum > 0, "1", "0"),"0")+"',"+;
			"'"+NVL(IIF(gtaship.rcdnum > 0, "1","0"),"0")+"',"+;
			"'"+NVL(IIF(gtaship.rvsnum > 0, "1","0"),"0")+"',"+;
			"'"+NVL(IIF(gtaship.rdsnum > 0, "1","0"),"0")+"',"+;
			"'"+NVL(IIF(gtaship.rshipftp, "1","0"),"0")+"',"+;
			"'"+NVL(gtaship.rcdtype,'')+"',"+;
			"'"+NVL(gtaship.rdstype,'')+"',"+;
			"'"+NVL(gtaship.rftptype,'')+"',"+;
			NVL(STR(gtaship.rcdincrem),'0')+","+;
			"'"+NVL(gtaship.rcdfile,'')+"',"+;
			NVL(IIF(gtaship.rsinglepg,"1","0"),"0")+","+;
			"'"+NVL(IIF(gtaship.mpapernum > 0, "1", "0"),"0")+"',"+;
			"'"+NVL(IIF(gtaship.mcdnum > 0, "1", "0"),"0")+"',"+;
			"'"+NVL(IIF(gtaship.mvsnum > 0, "1", "0"),"0")+"',"+;
			"'"+NVL(IIF(gtaship.mdsnum > 0, "1", "0"),"0")+"',"+;
			"'"+NVL(IIF(gtaship.mshipftp, "1", "0"),"0")+"',"+;
			"'"+NVL(gtaship.mcdtype,"")+"',"+;
			"'"+NVL(gtaship.mdstype,"")+"',"+;
			"'"+NVL(gtaship.mftptype,"")+"',"+;
			NVL(STR(gtaship.mcdincrem),"0")+","+;
			"'"+NVL(gtaship.mcdfile,"")+"',"+;
			NVL(IIF(gtaship.msinglepg,"1","0"),"0")+","+;
			"'"+newtabills.id_tblBills+"',"+;
			"'"+c_today+"','"+;
			goApp.CurrentUser.ntlogin+"',"+;
			"'1','0')"

*--			"'"+goApp.CurrentUser.ntlogin+"',"+;

*--		n=sqlexec(n_conn,c_sql)
		ogen.sqlexecute(c_sql)
	ENDIF
	SELECT tabills
ENDSCAN
*--SQLDISCONNECT(n_conn)

******************************************************
FUNCTION cleanstring
PARAMETERS c_string
PRIVATE cRetVal


IF AT("'",c_string)=0
	cRetVal =getsqllstring(c_string,.F.)
ELSE	
	cRetVal= '"'+ c_string + '"'
	sqlexec(n_conn,"SET QUOTED_IDENTIFIER OFF")
*--	this.sqlexecute("SET QUOTED_IDENTIFIER OFF")
ENDIF

RETURN cRetVal

******************************************************
FUNCTION getsqllstring

PARAMETERS c_string, l_comma
l_comma = IIF( PCOUNT() < 2, .F., l_comma)
c_string = "'" + c_string + "'" + IIF(l_comma, ",", "")
RETURN c_string