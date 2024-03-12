*****************************************************************************
**10/25/10: GSK 'A042911P'- add file # and claim #
**04/09/10: Add gsk lit extra columns
**08/11/09: use loadexcel.prg
**04/17/09: Adds cases from an Excel File

*****************************************************************************

PARAMETERS c_origrt, c_origAtty, c_lit
PRIVATE pn_errors,c_userid,c_today , c_tempFile , l_Continue as Boolean, l_newform as Boolean, c_aka as String,  c_comm as String
PRIVATE omed as Object
*********************************************
IF TYPE('PC_LITCODE')<>"C"
	WAIT WINDOW "Wrong litigation." 
RETURN
endif
********************************************

omed=CREATEOBJECT("medmaster")
c_today=DTOC(DATE())
STORE .f. to pn_errors,l_newform
l_CopyAttorneys=.T.

IF NOT USED('MAster') && get a master for a template RT case
	c_SQL="dbo.GetMasterbyRTNumber "+c_origrt
	omed.sqlexecute(c_SQL,"Master")
ENDIF
SELECT master
n_currArea = SELECT()

ID_OrigCase=MASTER.id_tblmaster
c_origclcode=MASTER.cl_code
c_litigation=master.litigation
IF ALLTRIM(UPPER(c_litigation))<>ALLTRIM(UPPER(c_lit))
	WAIT WINDOW "Wrong litigation." 
RETURN
endif
c_userid='BatchAdd_' + c_litigation

IF USED('TheSettings')
	l_newform=THESETTINGS.newformat

ELSE

	C_STR="exec [dbo].[GetAIPSettings] '" + PC_LITCODE + "'"
	L_OK=OMED.SQLEXECUTE( C_STR,"TheSettings")
	IF  L_OK
		l_newform=THESETTINGS.newformat
	

	ENDIF
ENDIF



c_acctmgr=master.acct_mgr

c_SQL="dbo.GetInstructionRecord '&ID_OrigCase.'"
omed.sqlexecute(c_SQL,"instruct")	
id_tblinstruct = INSTRUCT.id_tblinstruct
&& get atty's list
c_SQL = "SELECT id_tblBills, at_code FROM tblBill with (INDEX(ix_tblBills)) " + ;
	"WHERE id_tblMaster = '" + ID_OrigCase + "' " + ;
	"AND Active = 1 ORDER BY at_code"
	omed.sqlexecute(c_SQL,"AttyList")

IF RECCOUNT("AttyList") = 0 THEN
	WAIT WINDOW 'Original case has no participating attorneys.' 
	RETURN .f.
ENDIF

****Get the data from an excel file
c_file=getthefile()


IF  EMPTY(ALLTRIM(c_file)) 
	RETURN .F.
endif

Use &c_file alias casesToAdd in 0

***get unique cases from a supplied list
IF l_newform
SELECT  distinct UPPER(a) AS pl_first_n ,UPPER(b) as pl_last_n,SPACE(1) AS pl_mid, D as ssn ,;
	E as dob, Q AS DOD,   000000 as lrs_no, 0000000 as caseexist, ak, al, c as aka, ap, aq,ar, ;
	 CasesToAdd.as AS pladd2, CasesToAdd.at as ploldadd FROM CasesToAdd   ;
	 INTO CURSOR newcase READWRITE ORDER BY b,a
else

SELECT  distinct UPPER(a) AS pl_first_n ,UPPER(b) as pl_last_n,SPACE(1) AS pl_mid, D as ssn ,;
	E as dob, Q AS DOD,   000000 as lrs_no, 0000000 as caseexist FROM CasesToAdd   ;
	 INTO CURSOR newcase READWRITE ORDER BY b,a
endif	 
	 
	 
**\\Now loop through table of cases to add
SELECT newcase
SCAN FOR EMPTY(lrs_no)
******************************check dubplcate cases within litigation by SSN# first****************************************
	c_socsec=alltrim(NVL(newcase.ssn,''))
	IF TYPE("newcase.dob")="C"
		c_dob=alltrim(newcase.dob)
	ELSE	
		c_dob=alltrim(DTOC(newcase.dob))
	ENDIF
	
	IF TYPE("newcase.doD")="C"
		c_doD=alltrim(newcase.doD)
	ELSE	
		c_doD=alltrim(DTOC(newcase.doD))
	ENDIF
	
	
	IF EMPTY(c_socsec) AND EMPTY(c_dob)
	SELECT newcase
	LOOP
	ENDIF
	
	
	IF NOT EMPTY(c_socsec)
		n_select=SELECT()		
		c_SQL="SELECT lrs_no, soc_sec, plaintiff,brth_date as dob, name_last,name_first From " + ;
		" tblmaster WHERE ISNULL(soc_sec,'')='"+c_socsec+"' and litigation ='" + c_lit + "'  AND active=1"
		omed.sqlexecute(c_SQL,"viewss")			
	
		IF RECCOUNT('viewss')>0 AND NVL(viewss.soc_sec,'')=c_socsec
			replace ALL AE WITH viewss.lrs_no FOR ALLTRIM(d)==c_socsec IN CasesToAdd
			REPLACE ALL AD WITH viewss.lrs_no  FOR ALLTRIM(d)==c_socsec IN CasesToAdd
*!*				replace ALL CaseExist WITH viewss.lrs_no FOR ALLTRIM(d)==c_socsec IN CasesToAdd
*!*				REPLACE ALL lrs_no WITH viewss.lrs_no  FOR ALLTRIM(d)==c_socsec IN CasesToAdd
			SELECT newcase
			LOOP
		ENDIF
		SELECT (n_select)
	ELSE
	
	IF NOT EMPTY(dob) AND EMPTY(c_socsec)
		n_select=SELECT()		
		c_SQL="SELECT  lrs_no, soc_sec, plaintiff,brth_date as dob, name_last,name_first " + ;
		"  from tblmaster WHERE ISNULL(brth_date,'')='"+ c_dob  + ;		
		"' and litigation ='" + c_lit + ;
		"' and LTRIM(RTRIM(name_last))='" + alltrim(pl_last_n) + "' and  LTRIM(RTRIM(name_first))='" + alltrim(pl_first_n) + ;
		"'  AND active=1"
		omed.sqlexecute(c_SQL,"viewdob")		
	
		IF RECCOUNT('viewdob')>0 AND NVL(DTOC(viewdob.dob),'')=c_dob 
		 IF TYPE("NEWCASE.e")="C"
			replace ALL AE WITH viewdob.lrs_no FOR ALLTRIM(e)==c_dob IN CasesToAdd
			REPLACE ALL AD WITH viewdob.lrs_no  FOR ALLTRIM(e)==c_dob IN CasesToAdd
		  ELSE
		  	replace ALL AE WITH viewdob.lrs_no FOR e=CTOD(c_dob) IN CasesToAdd
			REPLACE ALL AD WITH viewdob.lrs_no  FOR e=CTOD(c_dob) IN CasesToAdd
		  ENDIF	
			SELECT newcase
			LOOP
		ENDIF
		SELECT (n_select)
		
	ENDIF
	ENDIF
	
	************************************check dubp by dob and name************************************************
	STORE "" TO c_add1, c_add2, c_SQL, c_Docket, c_aka, c_comm
	c_lname=UPPER(ALLTRIM(newcase.pl_LAST_N))
	c_lname=UPPER(IIF(RIGHT(c_lname,3)==' SR',STRTRAN(c_lname,' SR',' ,SR'),c_lname))
	c_lname=UPPER(IIF(RIGHT(c_lname,3)==' JR',STRTRAN(c_lname,' JR',' ,JR'),c_lname))
	c_plaintiff=UPPER(c_lname+" ;"+ALLTRIM(newcase.pl_FIRST_N)+;
		IIF(NOT EMPTY(ALLTRIM(newcase.pl_mid))," "+ALLTRIM(newcase.pl_mid)+".",""))
		
	
	IF l_newform
		IF TYPE("newcase.AL")="C"
			c_Docket=alltrim(newcase.al)
		ENDIF
	
	ELSE
		c_Docket=MASTER.docket
	ENDIF
	
	IF l_newform &&3/16/2010 - added aka
		IF TYPE("newcase.Aka")="C"
			c_aka=ALLTRIM(newcase.aka)
		ENDIF
	ELSE
			c_aka=ALLTRIM(NVL(MASTER.maiden_nam,''))
	ENDIF
	***04/09/2010 - more gsk columns added-start

	IF l_newform &&pl address 1
		IF TYPE("newcase.ar")="C"
			c_add1=ALLTRIM(newcase.ar)
		ENDIF	
	ENDIF
	
	IF l_newform &&pl address 1
		IF TYPE("newcase.pladd2")="C"
			c_add2=ALLTRIM(newcase.pladd2)
		ENDIF	
	ENDIF
	
	IF l_newform &&pl comments
		IF TYPE("newcase.ploldadd")="C"
			c_comm=ALLTRIM(newcase.ploldadd)
		ENDIF	
	ENDIF
	
	***04/09/2010 - more gsk columns added -end
	c_SQL=""
	c_SQL="exec dbo.MirrorMasterRecord "+;
		"'"+ID_OrigCase+"', "+;
		"'"+MASTER.id_tbloffice+"', '"+MASTER.lrs_nocode+"', "+;
		"'"+IIF(MASTER.testcase=.T.,"0","0")+"', '"+IIF(MASTER.template=.T.,"0","0")+"', "+;
		"'"+fixquote(c_plaintiff)+"', '"+fixquote(c_lname)+"', '"+fixquote(newcase.pl_FIRST_N)+"', "+;
		"'"+fixquote(newcase.pl_mid)+"', '"+fixquote(c_add1)+"', '"+fixquote(c_add2)+ "', "+;
		"'"+fixquote(MASTER.executor)+"', "+;
		"'"+c_socsec+"', "+ IIF(EMPTY(NVL(newcase.dob,{})),"null","'"+ALLTRIM(DTOC(newcase.dob))+"'")+", "+;
		IIF(EMPTY(NVL(newcase.DOD,{})),"null","'"+ALLTRIM(DTOC(newcase.DOD))+"'")+", "+;
		"'"+fixquote(MASTER.attorney)+"', '"+fixquote(MASTER.attyfirst)+"', '"+fixquote(MASTER.court)+"', "+;
		"'"+fixquote(c_Docket)+"', '"+fixquote(MASTER.district)+"', '"+fixquote(MASTER.division)+"', "+;
		"'"+fixquote(MASTER.court2)+"', '"+fixquote(MASTER.cclnumber)+"', '"+IIF(MASTER.interrog=.T.,"1","0")+"', "+;
		"'"+fixquote(MASTER.req_atty)+"', ;
		'"+fixquote(MASTER.req_atf)+"', '"+fixquote(MASTER.req_para)+"', "+;
		"'"+fixquote(MASTER.employ)+"', "+IIF(EMPTY(NVL(MASTER.sempdate,{})),"null","'"+TTOC(MASTER.sempdate)+"'")+", "+;
		IIF(EMPTY(NVL(MASTER.eempdate,{})),"null","'"+TTOC(MASTER.eempdate)+"'")+", "+;
		"'"+IIF(MASTER.mta_expect=.T.,"1","0")+"', "+;
		IIF(EMPTY(NVL(MASTER.settled,{})),"null","'"+TTOC(MASTER.settled)+"'")+", '"+fixquote(MASTER.worker)+"', "+;
		"'"+IIF(MASTER.chosen=.T.,"1","0")+"', "+;
		IIF(EMPTY(NVL(MASTER.trial_date,{})),"null","'"+TTOC(MASTER.trial_date)+"'")+", "+;
		IIF(EMPTY(NVL(MASTER.depo_date,{})),"null","'"+TTOC(MASTER.depo_date)+"'")+", '"+;		
		c_today+"', "+; &&*IIF(EMPTY(NVL(MASTER.assn_date,{})),"null","'"+TTOC(MASTER.assn_date)+"'")+", "+
		IIF(EMPTY(NVL(MASTER.req_date,{})),"null","'"+TTOC(MASTER.req_date)+"'")+", '"+fixquote(c_comm)+"', "+;
		"'"+ALLTRIM(STR(0))+"', '"+fixquote(MASTER.pldeal)+"', '"+fixquote(MASTER.proj_codec)+"', "+;
		"'"+ALLTRIM(STR(MASTER.proj_coden))+"', ;
		'"+fixquote(MASTER.area)+"', '"+fixquote(MASTER.area_id)+"', "+;
		"'"+fixquote(MASTER.condition)+"', '"+fixquote(c_litigation)+"', '"+fixquote(ALLTRIM(STR(MASTER.GROUP)))+"', "+;
		"'"+fixquote(MASTER.rq_at_code)+  "', '"+fixquote(MASTER.pl_at_code)+"', '"+fixquote(MASTER.sim_first)+"', "+;
		"'"+fixquote(c_acctmgr)+ "', '"+fixquote(c_aka)+"', '"+fixquote(MASTER.maiden_na2)+"', "+;
		"'"+fixquote(MASTER.manufactur)+  "', '"+fixquote(MASTER.sex_first)+ "', "+;
		IIF(EMPTY(NVL(MASTER.term_date,{})),"null","'"+TTOC(MASTER.term_date)+"'")+", "+;
		"'"+fixquote(MASTER.category)+ "', '"+fixquote(MASTER.lot_no)+"', '"+fixquote(MASTER.occupation)+"', "+;
		"'"+fixquote(MASTER.county)+"', '"+fixquote(MASTER.plcap)+"', '"+fixquote(MASTER.defcap)+"', "+;
		"'"+fixquote(MASTER.device_num)+  "', "+;
		IIF(EMPTY(NVL(MASTER.enter_date,{})),"null","'"+TTOC(MASTER.enter_date)+"'")+", "+;
		IIF(EMPTY(NVL(MASTER.edit_date,{})),"null","'"+TTOC(MASTER.edit_date)+"'")+", "+;		
		"'"+fixquote(MASTER.bb_rnd)+"', '"+fixquote(MASTER.bb_no)+  "', '"+fixquote(MASTER.plan)+"', "+;
		"'"+fixquote(MASTER.alien_code)+  "', "+;
		"'"+fixquote(MASTER.proc_code)+"', '"+fixquote(MASTER.bill_code)+ "', '"+ALLTRIM(STR(MASTER.wf_amount,20,4))+"', "+;
		"'"+""+ "', "+IIF(EMPTY(NVL(MASTER.dol,{})),"null","'"+TTOC(MASTER.dol)+"'")+ ", "+;
		"'"+fixquote(MASTER.complaint)+"', '"+fixquote(MASTER.reparea)+"', "+;
		"'"+fixquote(MASTER.firmcode)+ "', '"+fixquote(MASTER.CASE)+"', '"+fixquote(c_acctmgr)+"', "+;
		"'"+MASTER.sales_per+"', '"+MASTER.asb_case+"', "+;
		IIF(EMPTY(NVL(MASTER.ssc_date,{})),"null","'"+TTOC(MASTER.ssc_date)+"'")+", "+;
		IIF(EMPTY(NVL(MASTER.mta_date,{})),"null","'"+TTOC(MASTER.mta_date)+"'")+", "+;
		"'"+TTOC(DATETIME())+ "', '"+c_userid+"', "+;
		"'"+fixquote(MASTER.SOURCE)+"', '"+IIF(l_CopyAttorneys=.T.,"1","0")+"'"


pn_errors=omed.sqlexecute(c_SQL,"viewIDs")
IF pn_errors	
	IF l_CopyAttorneys && copy/mirror atty's data
	**c_oldclcode,c_newclcode,c_newid, c_fileno, c_claim, c_insur
		DO copy_atty WITH c_origclcode,viewIDs.cl_code,viewIDs.id_tblmaster, IIF(l_newform,LEFT(ALLTRIM(newcase.AK),16),""), IIF(l_newform,LEFT(ALLTRIM(newcase.Ap),50),""),"" &&IIF(l_newform,newcase.Aq,"")
	ENDIF

		SELECT viewIDs
		IF RECCOUNT()>0
		IF EMPTY(c_socsec)
			IF 	NOT EMPTY(c_dob) 
				REPLACE ALL AD WITH viewIDs.lrs_no  FOR e==CTOD(c_dob) IN CasesToAdd &&lrs_no
			endif
		else		
				REPLACE ALL AD WITH viewIDs.lrs_no  FOR ALLTRIM(D)==c_socsec IN CasesToAdd &&lrs_no
		ENDIF
		endif
		
ENDIF

	
	SELECT newcase
	
ENDSCAN
l_Continue=.f.
lc_message = "Do you want to Add the [NOT-ISSUED] Tags for that batch?"
		o_message = CREATEOBJECT('rts_message_yes_no',lc_message)
		o_message.SHOW
		l_Confirm=IIF(o_message.exit_mode="YES",.T.,.F.)
		o_message.RELEASE
		IF l_Confirm
			l_Continue=.T.
		ENDIF
**WAIT WINDOW "Done adding cases. Hit any key to continue adding [Not-Issued ]Tags."


***********ADD NOT -ISSUED TAGS for newly added cases
IF l_Continue
	DO ISSUEPROCESS WITH &c_file, .T. &&pre-issue (f2)
endif
*gfMessage("Done.")
RETURN

**************************************************************************************
**	Copy_Atty program
**  copy all participating attorney info to a new case
**************************************************************************************
PROCEDURE copy_atty
LPARAMETERS c_oldclcode,c_newclcode,c_newid, c_fileno, c_claim, c_insur
**08/18/2010- Replaced direct sql below by a stored proc
c_SQL=" EXEC [dbo].[GetBills] '" +c_oldclcode + "'" 
*c_SQL="SELECT * FROM tblBill WITH (index (ix_tblbills_2)) WHERE cl_code='&c_oldclcode.' AND active=1 "
omed.sqlexecute(c_SQL,"tabills")

SELECT tabills

SCAN
	lcSQLLine="exec dbo.InsertBillRecord '"+ALLTRIM(tabills.id_tblBills)+"', "+;
		"'"+ALLTRIM(fixquote(c_newclcode))+"', '"+ALLTRIM(c_newid)+"', '"+DTOC(DATE())+"', "+;
		"'"+c_userid+"'"
		pn_errors=omed.sqlexecute(lcSQLLine,"")

	**10/25/2010 GSK1 needs the 3rd pty billing info on 'A042911P'
	IF tabills.at_code ='A042911P' AND l_newform 
			c_SQL=""
			c_SQL="Update tblbill set file_no ='" +NVL(c_fileno,'') + ;
			"',claim_no ='" + NVL(c_claim,'') + ;
			"',insured ='" + NVL(c_insur,'') + ;
			"' WHERE cl_code='"+c_newclcode+"'"+;
			" and at_code='"+fixquote(tabills.at_code)+"' and active=1 "
			omed.sqlexecute(c_SQL,"")
			
	
	ENDIF
	
		
	c_sql ="[dbo].[GetShipbyClcodeAtcode] '" + c_oldclcode + "','" + fixquote(tabills.At_Code) + "'"

	omed.sqlexecute(c_SQL,"gtaship")
	

	SELECT gtaship
	IF RECCOUNT("gtaship")>0
		c_SQL="SELECT id_tblBills FROM tblbill WHERE cl_code='"+c_newclcode+"'"+;
			" and at_code='"+fixquote(tabills.At_Code)+"' and active=1 "
			omed.sqlexecute(c_SQL,"newtabills")
		
		c_SQL="Insert into tblShip (cl_code, at_code,rpapernum,"+;
			"rcdnum, rvsnum, rdsnum, rshipftp, rcdtype,rdstype, rftptype,"+;
			"rcdincrem,rcdfile,rsinglepg,"+;
			"mpapernum, mcdnum, mvsnum, mdsnum, mshipftp, mcdtype,"+;
			"mdstype, mftptype,mcdincrem,mcdfile,msinglepg,id_tblbills, created, createdby, active, retire)"+;
			" values ("+;
			"'"+c_newclcode+"','"+;
			fixquote(tabills.At_Code)+"',"+;
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
			c_userid+"',"+;
			"'1','0')"

		omed.sqlexecute(c_SQL,"")
		

	ENDIF
	SELECT tabills
ENDSCAN
************************	
**04/09/2010 added Insured and Claim_no for gsk
IF l_newform &&08/09/2010 add file number for gsk lit
c_SQL=""
			c_SQL="Update tblbill set file_no ='" +NVL(c_fileno,'') + ;
			"',claim_no ='" + NVL(c_claim,'') + ;
			"',insured ='" + NVL(c_insur,'') + ;
			"' WHERE cl_code='"+c_newclcode+"'"+;
			" and at_code='"+fixquote(MASTER.rq_at_code)+"' and active=1 "
			omed.sqlexecute(c_SQL,"")
			

ENDIF
************************
return
************************************************************************
FUNCTION getthefile
************************************************************************
LOCAL llok as Boolean
lnCurArea=SELECT()

lcCURR=SYS(5) +SYS(2003)
***
lcDefault=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","AUTOMATEDISSUE", "\")))
gfMessage("Please make sure the file is as a TEMPLATE one at T:\AVANDIA - PL\ folder.")


SET DEFAULT TO &lcDefault
**
*lcDefault="t:\avandia"
* Fix for Fatal RTS Error RT# 45134/Tag # /MEGAN - 3/3/2010- HelpDesk - 2:30PM
lcFileName = ''
lcFile=GETFILE("XLS","Load Batch List")
IF NOT EMPTY(ALLTRIM(LCFILE))
  LOCAL n_div as Integer, c_dir as String
  n_div=0
  c_dir =""
  n_div =RAT("\",lcfile,1) 
  c_dir =LEFT(lcfile, n_div)
  lcFile="'"+ALLTRIM(lcFile)+"'" 
**8/11/09 CALL LOADEXCEL INSTEAD OF IMPORT
  SET DEFAULT TO &lcCURR 

  
  llok=.T.
  llok= LOADEXCEL(&lcFile, c_dir, "1")
  IF NOT llok
    	IF NOT EMPTY(lnCurArea)
      	 SELECT (lnCurArea)  
    	endif 
    RETURN ""
   ENDIF  
*IMPORT FROM &lcFile xl5
  lcFileName=DBF()
  USE
  lcFileName="'"+ALLTRIM(lcFileName)+"'"
  pc_ToDoFile=lcFileName
  USE &lcFileName ALIAS TodoFile EXCLUSIVE
  GO TOP 
  DELETE NEXT 1
  DELETE FOR EMPTY(ALLTRIM(A)) AND EMPTY(ALLTRIM(B))


  INDEX ON S FOR .NOT.EMPTY(S) TAG MAILID ADDITIVE
  INDEX ON AD TAG lrs_no ADDITIVE
  *INDEX ON lrs_No TAG lrs_no ADDITIVE
  SELECT TodoFile
  USE
ELSE  
* Fix for Fatal RTS Error RT# 45134/Tag # /MEGAN - 3/3/2010- HelpDesk - 2:30PM
  SET DEFAULT TO &lcCURR  
ENDIF && EMPTY
IF NOT EMPTY(lnCurArea)
  SELECT (lnCurArea)  
endif 
*SET DEFAULT TO &lcCURR 
RETURN (lcFileName)




