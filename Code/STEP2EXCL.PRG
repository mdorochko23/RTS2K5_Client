*****************************************************************************
**10/26/10: step 2 qc excel - check cases( existing or new )

*****************************************************************************

PARAMETERS c_origrt, c_origAtty, c_lit, c_plcaption, c_defcaption, c_cfile, c_areapick
PRIVATE pn_errors,c_userid,c_today , c_tempFile , l_Continue AS Boolean, l_newform AS Boolean, c_aka AS STRING,  c_comm AS STRING,;
	c_defncap AS STRING, c_plaincap AS STRING, c_court AS STRING, c_ssn1 AS STRING, c_ssn2 AS STRING, 	c_ssn3 AS STRING, c_casename AS STRING
PRIVATE omed AS OBJECT
STORE "" TO c_defncap , c_plaincap , c_ssn1, c_ssn2, c_ssn3, c_casename
omed=CREATEOBJECT("medmaster")
c_today=DTOC(DATE())
STORE .F. TO pn_errors,l_newform
l_CopyAttorneys=.T.
l_newform=.T.

IF NOT USED('MAster') && get a master for a template RT case
	c_SQL="exec dbo.GetMasterbyRTNumber "+c_origrt
	omed.sqlexecute(c_SQL,"Master")
ENDIF
SELECT MASTER
n_currArea = SELECT()
ID_OrigCase=MASTER.id_tblmaster
c_origclcode=MASTER.cl_code
c_litigation=MASTER.litigation
IF ALLTRIM(UPPER(c_litigation))<>ALLTRIM(UPPER(c_lit))
	WAIT WINDOW "Wrong litigation."
	RETURN
ENDIF


c_userid=ALLTRIM(pc_UserID)

c_acctmgr=ALLTRIM(MASTER.acct_mgr)

c_SQL="exec dbo.GetInstructionRecord '&ID_OrigCase.'"
omed.sqlexecute(c_SQL,"instruct")
id_tblinstruct = INSTRUCT.id_tblinstruct
&& get atty's list

c_SQL = " EXEC [dbo].[QCGetBills]'" + ID_OrigCase + "' "
omed.sqlexecute(c_SQL,"AttyList")

IF RECCOUNT("AttyList") = 0 THEN
	WAIT WINDOW 'Original case has no participating attorneys.'
	RETURN .F.
ENDIF

IF  EMPTY(ALLTRIM(c_cfile))
	RETURN .F.
ELSE
	DO indxthefile &&WITH ALLTRIM(c_cfile)
ENDIF



USE &c_cfile ALIAS casesToAdd IN 0
REPLACE ALL AZ WITH .F.  FOR AY=0&& TO START WITH  ASSUME ALL THE CASES EXIST

***get unique cases from an excel's list of the orders
IF l_newform
	SELECT  DISTINCT UPPER(a) AS pl_first_n ,UPPER(b) AS pl_last_n, aa AS pl_mid, D AS ssn , s AS executor,;
		E AS dob, Q AS DOD,   AY AS lrs_no,  ak AS Clmatno, aq AS fileno, al AS docket, c AS aka, am AS court,;
		an AS depodate, ax AS trial, ba AS groupno, bc AS reqpara, aw AS duedate, ad AS Bill3rd,;
		ap AS lawfno,  ag AS insured, ah AS claim, ai AS adjuster, ;
		af AS orderedby, ae AS billto, aj AS accdate, ar AS pladd1, ;
		ALLTRIM(casesToAdd.AS) + ', ' + casesToAdd.AT + '  ' + casesToAdd.au  AS pladd2, casesToAdd.av + ' ' + ALLTRIM(casesToAdd.BB) AS ploldadd ;
		FROM casesToAdd  WHERE  AZ =.F. ;
		INTO CURSOR newcase READWRITE ORDER BY b,a

ENDIF


**\\Now loop through table of cases to add
SELECT newcase
IF EOF()
	WAIT WINDOW 'File is empty.'
	RETURN .F.
ENDIF
**3/14/2011 - RT can be added by Am


SCAN FOR lrs_no=0
******************************check dubplcate cases within litigation by SSN# first****************************************

	IF TYPE("newcase.dob")="C"
		c_dob=ALLTRIM(newcase.dob)
	ELSE
		c_dob=ALLTRIM(DTOC(newcase.dob))
	ENDIF

	IF TYPE("newcase.doD")="C"
		c_doD=ALLTRIM(newcase.DOD)
	ELSE
		c_doD=ALLTRIM(DTOC(newcase.DOD))
	ENDIF

	c_socsec=ALLTRIM(NVL(newcase.ssn,''))
	c_origSSN=c_socsec && 03/20/17 - added to keep track of the original data so later we repalce a  correct records in the cursor
	***06/28/16- TREAT '000-00-0000' AS EMPTY #43652
	IF c_socsec='000-00-0000'
		c_socsec=''
	ENDIF
***06/28/16- TREAT '000-00-0000' AS EMPTY #43652

************************************check dubps RT************************************************
	STORE "" TO c_add1, c_add2, c_SQL, c_Docket, c_aka, c_comm, c_casename
	c_lname=UPPER(ALLTRIM(newcase.pl_last_n))
	c_lname=UPPER(IIF(RIGHT(c_lname,3)==' SR',STRTRAN(c_lname,' SR',' ,SR'),c_lname))
	c_lname=UPPER(IIF(RIGHT(c_lname,3)==' JR',STRTRAN(c_lname,' JR',' ,JR'),c_lname))
	c_plaintiff=UPPER(c_lname+" ;"+ALLTRIM(newcase.pl_first_n)+;
		IIF(NOT EMPTY(ALLTRIM(newcase.pl_mid))," "+ALLTRIM(newcase.pl_mid)+".",""))
	c_casename=	UPPER(ALLTRIM(newcase.pl_first_n)+;
		IIF(NOT EMPTY(ALLTRIM(newcase.pl_mid))," "+ALLTRIM(newcase.pl_mid)+"."," ")) + c_lname


	IF NOT EMPTY(c_socsec)
***2/18/2011- check for '-' in the SSN
		IF  NOT "-"$c_socsec
			c_ssn1= LEFT(c_socsec,3)
			c_ssn2= SUBSTR(c_socsec,4,2)
			c_ssn3= RIGHT(c_socsec,4)
			c_socsec= ALLTRIM(c_ssn1) +"-" + ALLTRIM(c_ssn2)+"-"+ ALLTRIM(c_ssn3)
		ENDIF
	ENDIF
***2/18/2011- check for '-' in the SSN


	IF NOT EMPTY(c_socsec) 
		n_select=SELECT()
		IF EMPTY(ALLTRIM(c_areapick))
			c_SQL=" exec [dbo].[qc_GetExl2CaseData] '" + c_lit + "','" + c_socsec + "', 1,'','',''"
**4/21/15- added area to chcek for duplicate cases
		ELSE
			c_SQL=" exec  [dbo].[GetExl2CaseDataLitArea] '" + c_lit + "','" + c_socsec + "', 1,'','','','" + c_areapick + "' "
		ENDIF

		omed.sqlexecute(c_SQL,"viewss")


		IF RECCOUNT('viewss')>0 AND NVL(viewss.soc_sec,'')=c_socsec
			REPLACE ALL AY WITH viewss.lrs_no FOR ALLTRIM(D)==c_origSSN IN casesToAdd
			SELECT newcase
			LOOP
		ENDIF
		SELECT (n_select)
	ELSE

		IF NOT EMPTY(ALLTRIM(c_dob)) AND EMPTY(ALLTRIM(c_socsec))
			n_select=SELECT()
			c_SQL=""
			IF EMPTY(ALLTRIM(c_areapick))
			
			c_SQL=" exec [dbo].[qc_GetExl2CaseData]  '" + c_lit + "','" + c_socsec + "', 2,'" + c_dob+ "','" + ;
				FIXQUOTE(c_lname) + "','" +  FIXQUOTE(ALLTRIM(newcase.pl_first_n)) + "'"
			ELSE
			
			c_SQL=" exec  [dbo].[GetExl2CaseDataLitArea] '" + c_lit + "','" + c_socsec + "', 2,'" + c_dob+ "','" + ;
				FIXQUOTE(c_lname) + "','" +  FIXQUOTE(ALLTRIM(newcase.pl_first_n)) + "','" +  c_areapick + "' "
			
*!*				c_SQL=" exec [dbo].[qc_GetExl2CaseData]  '" + c_lit + "','" + c_socsec + "', 2,'" + c_dob+ "','" + ;
*!*					FIXQUOTE(c_lname) + "','" +  FIXQUOTE(ALLTRIM(newcase.pl_first_n)) + "',' " +  c_areapick + "' "
			ENDIF
			
			omed.sqlexecute(c_SQL,"viewdob")

			IF RECCOUNT('viewdob')>0 AND NVL(TTOC(viewDOB.dob),'')=c_dob
				REPLACE ALL AY WITH viewDOB.lrs_no FOR E=CTOD(c_dob) IN casesToAdd
				SELECT newcase
				LOOP
			ENDIF
			SELECT (n_select)

		ENDIF
	ENDIF
************************************extra data to store************************************************
	c_court=""
	IF !EMPTY(ALLTRIM(newcase.court))&&court may come with an excel order
		c_court=ALLTRIM(newcase.court)

	ELSE
		c_court=ALLTRIM(MASTER.court)
	ENDIF

	IF TYPE("newcase.docket")="C" &&docket
		c_Docket=ALLTRIM(newcase.docket)

	ELSE
		c_Docket=MASTER.docket
	ENDIF

	IF TYPE("newcase.Aka")="C" &&aka
		c_aka=ALLTRIM(newcase.aka)

	ELSE
		c_aka=ALLTRIM(NVL(MASTER.maiden_nam,''))
	ENDIF

	IF TYPE("newcase.pladd1")="C" &&pl address 1
		c_add1=ALLTRIM(newcase.pladd1)
	ELSE
		c_add1=""
	ENDIF

	IF TYPE("newcase.pladd2")="C" &&pl address 2
		c_add2=ALLTRIM(newcase.pladd2)
	ELSE
		c_add2=""
	ENDIF

	IF TYPE("newcase.ploldadd")="C" &&pl comments
		c_comm=ALLTRIM(newcase.ploldadd)
	ELSE
		c_comm=""
	ENDIF

	IF EMPTY(ALLTRIM(c_plcaption))
		c_plaincap =c_plaintiff
	ELSE
		c_plaincap=c_plcaption
	ENDIF
	IF EMPTY(ALLTRIM(c_defcaption))
		c_defncap =""
	ELSE
		c_defncap=c_defcaption
	ENDIF



***create a case by mirror and the new values from an excel
	STORE "" TO c_SQL, c_SQL1,c_SQL2, c_SQL3, c_SQL4, c_SQL5, c_SQL6, c_SQL7
	c_SQL1="exec dbo.MirrorMasterRecord "+;
		"'"+ID_OrigCase+"', "+;
		"'"+MASTER.id_tbloffice+"', '"+MASTER.lrs_nocode+"', "+;
		"'"+IIF(MASTER.testcase=.T.,"0","0")+"', '"+IIF(MASTER.template=.T.,"0","0")+"', "+;
		"'"+FIXQUOTE(c_plaintiff)+"', '"+FIXQUOTE(c_lname)+"', '"+FIXQUOTE(newcase.pl_first_n)+"', "+;
		"'"+FIXQUOTE(newcase.pl_mid)+"', '"+FIXQUOTE(c_add1)+"', '"+FIXQUOTE(c_add2)+ "', "+;
		"'"+FIXQUOTE(newcase.executor)+"', '"  && + ;

	c_SQL2=	c_socsec+"', "+ IIF(EMPTY(NVL(newcase.dob,{})),"null","'"+ALLTRIM(DTOC(newcase.dob))+"'")+", "+;
		IIF(EMPTY(NVL(newcase.DOD,{})),"null","'"+ALLTRIM(DTOC(newcase.DOD))+"'")+", "+;
		"'"+FIXQUOTE(NVL(MASTER.attorney,''))+"', '"+FIXQUOTE(NVL(MASTER.attyfirst,''))+"', '"+FIXQUOTE(NVL(c_court,''))+"', "+;
		"'"+FIXQUOTE(c_Docket)+"', '"+FIXQUOTE(NVL(MASTER.district,''))+"', '"+FIXQUOTE(NVL(MASTER.division,''))+"', "+;
		"'"+FIXQUOTE(MASTER.court2)+"', '"+FIXQUOTE(MASTER.cclnumber)+"', '"+IIF(MASTER.interrog=.T.,"1","0")+"', "+;
		"'"+FIXQUOTE(MASTER.req_atty)+"', '"  && +;

	c_SQL3	=FIXQUOTE(MASTER.req_atf)+"', '"+FIXQUOTE(newcase.reqpara)+"', "+;
		"'"+FIXQUOTE(MASTER.employ)+"', "+IIF(EMPTY(NVL(MASTER.sempdate,{})),"null","'"+TTOC(MASTER.sempdate)+"'")+", "+;
		IIF(EMPTY(NVL(MASTER.eempdate,{})),"null","'"+TTOC(MASTER.eempdate)+"'")+", "+;
		"'"+IIF(MASTER.mta_expect=.T.,"1","0")+"', "+;
		IIF(EMPTY(NVL(MASTER.settled,{})),"null","'"+TTOC(MASTER.settled)+"'")+", '"+FIXQUOTE(MASTER.worker)+"', "+;
		"'"+IIF(MASTER.chosen=.T.,"1","0")+"', "+;
		IIF(EMPTY(NVL(newcase.trial,{})),"null","'"+TTOC(newcase.trial)+"'")+", " &&+;

	c_SQL4=IIF(EMPTY(NVL(newcase.depodate,{})),"null","'"+TTOC(newcase.depodate)+"'")+", '" +;
		c_today+"', " +;
		IIF(EMPTY(NVL(newcase.duedate,{})),"null","'"+TTOC(newcase.duedate)+"'")+", '"+FIXQUOTE(c_comm)+"', "+;
		"'"+ALLTRIM(STR(0))+"', '"+FIXQUOTE(MASTER.pldeal)+"', '"+FIXQUOTE(MASTER.proj_codec)+"', "+;
		"'"+ALLTRIM(STR(MASTER.proj_coden))+"', ;
		'"+FIXQUOTE(MASTER.area)+"', '"+FIXQUOTE(MASTER.area_id)+"', "+;
		"'"+FIXQUOTE(NVL(MASTER.condition,''))+"', '"+FIXQUOTE(c_litigation)+"', '"+FIXQUOTE(ALLTRIM(STR(NVL(newcase.groupno,0))))+"', "+;
		"'"+FIXQUOTE(NVL(MASTER.rq_at_codE,''))+  "', '"+FIXQUOTE(NVL(MASTER.pl_at_code,''))+"', '"+FIXQUOTE(NVL(MASTER.sim_first,''))+"', "+;
		"'"+FIXQUOTE(c_acctmgr)+ "', '"+FIXQUOTE(c_aka)+"', '"+FIXQUOTE(NVL(MASTER.maiden_na2,''))+"', "+;
		"'"+FIXQUOTE(NVL(MASTER.manufactur,''))+  "', '"+FIXQUOTE(NVL(MASTER.sex_first,''))+ "', " &&+;

	c_SQL5=	IIF(EMPTY(NVL(MASTER.term_date,{})),"null","'"+TTOC(MASTER.term_date)+"'")+", "+;
		"'"+FIXQUOTE(NVL(MASTER.category,''))+ "', '"+NVL(MASTER.lot_no,'')+"', '"+FIXQUOTE(NVL(MASTER.occupation,''))+"', "+;
		"'"+FIXQUOTE(NVL(MASTER.county,''))+"', '"+FIXQUOTE(c_casename )+"', '"+FIXQUOTE(c_defncap)+"', "+;
		"'"+FIXQUOTE(NVL(MASTER.device_num,''))+  "', "+;
		IIF(EMPTY(NVL(MASTER.enter_date,{})),"null","'"+TTOC(MASTER.enter_date)+"'")+", "+;
		IIF(EMPTY(NVL(MASTER.edit_date,{})),"null","'"+TTOC(MASTER.edit_date)+"'")+", " &&+;

	c_SQL6=	"'"+NVL(MASTER.bb_rnd,'')+"', '"+NVL(MASTER.bb_no,'')+  "', '"+NVL(MASTER.plan,'')+"', "+;
		"'"+NVL(MASTER.alien_code,'')+  "', "+;
		"'"+NVL(MASTER.proc_code,'')+"', '"+NVL(MASTER.bill_code,'')+ "', '"+ALLTRIM(STR(MASTER.wf_amount,20,4))+"', "+;
		"'"+""+ "', "+IIF(EMPTY(NVL(MASTER.dol,{})),"null","'"+TTOC(MASTER.dol)+"'")+ ", "+;
		"'"+FIXQUOTE(NVL(MASTER.complaint,''))+"', '"+FIXQUOTE(NVL(MASTER.reparea,''))+"', "+;
		"'"+FIXQUOTE(NVL(MASTER.firmcode,''))+ "', '"+FIXQUOTE(NVL(MASTER.CASE,''))+"', '"+FIXQUOTE(c_acctmgr)+"', "+;
		"'"+NVL(MASTER.sales_per,'')+"', '"+NVL(MASTER.asb_case,'')+"', " &&+;

	c_SQL7=	IIF(EMPTY(NVL(MASTER.ssc_date,{})),"null","'"+TTOC(MASTER.ssc_date)+"'")+", "+;
		IIF(EMPTY(NVL(MASTER.mta_date,{})),"null","'"+TTOC(MASTER.mta_date)+"'")+", "+;
		"'"+TTOC(DATETIME())+ "', '"+c_userid+"', "+;
		"'"+FIXQUOTE(MASTER.SOURCE)+"', '"+IIF(l_CopyAttorneys=.T.,"1","0")+"'"




	c_SQL=c_SQL1+c_SQL2+ c_SQL3+c_SQL4 +c_SQL5 +c_SQL6 +c_SQL7


*!*					PN_LRSNO=11112
*!*					DO addlogline  WITH  0 , c_SQL , " sql_1"

	pn_errors=omed.sqlexecute(c_SQL,"viewIDs")
	IF pn_errors
		IF l_CopyAttorneys && copy/mirror atty's data + new values from an excel columns


**09/23/2011- added indirect billing column .ad

			DO copy_atty WITH c_origclcode,viewIDs.cl_code,viewIDs.id_tblmaster,  + ;
				IIF(l_newform,LEFT(ALLTRIM(newcase.Clmatno),16),""), + ;
				IIF(l_newform,LEFT(ALLTRIM(newcase.lawfno),50),""), + ;
				IIF(l_newform,LEFT(ALLTRIM(newcase.fileno),50),""), + ;
				IIF(l_newform,LEFT(ALLTRIM(newcase.claim),16),""),IIF(l_newform,LEFT(ALLTRIM(newcase.insured),20),"") , + ;
				IIF(l_newform,LEFT(ALLTRIM(newcase.adjuster),20),"") , + ;
				IIF(l_newform,LEFT(ALLTRIM(newcase.orderedby),20),"") , + ;
				IIF(l_newform,LEFT(ALLTRIM(newcase.billto),8),"") , + ;
				IIF(l_newform,LEFT(ALLTRIM(newcase.Bill3rd),100),""), + ;
				IIF(EMPTY(NVL(newcase.accdate,{})),"",ALLTRIM(DTOC(newcase.accdate)))


		ENDIF

		SELECT viewIDs
		IF RECCOUNT()>0
			IF EMPTY(c_socsec)
				IF 	NOT EMPTY(c_dob)
					REPLACE ALL AY WITH viewIDs.lrs_no  FOR E==CTOD(c_dob) IN casesToAdd &&lrs_no
					REPLACE ALL AZ WITH .T.  FOR E==CTOD(c_dob) IN casesToAdd &&lrs_no
				ENDIF
			ELSE
				REPLACE ALL AY WITH viewIDs.lrs_no  FOR ALLTRIM(D)==c_origSSN IN casesToAdd &&lrs_no
				REPLACE ALL AZ WITH .T.  FOR ALLTRIM(D)==c_origSSN IN casesToAdd &&lrs_no
			ENDIF
		ENDIF

	ENDIF

	SELECT newcase

ENDSCAN
RELEASE omed
RETURN

**************************************************************************************
**	Copy_Atty program
**  copy all participating attorney info to a new case
**************************************************************************************
PROCEDURE copy_atty
LPARAMETERS c_oldclcode,c_newclcode,c_newid, c_filenoreq, c_claimreq, c_fileno, c_claim, c_insur, c_adj, c_ordby, ;
	c_billto, c_3rdbill, c_accdate
IF TYPE('omed') <>"O"
	omed= CREATEOBJECT("generic.medgeneric")
ENDIF
l_newform=.T.
c_userid=ALLTRIM(pc_UserID)

c_SQL=" EXEC [dbo].[GetBills] '" +c_oldclcode + "'"
omed.sqlexecute(c_SQL,"tabills")

SELECT tabills

SCAN
	lcSQLLine="exec dbo.InsertBillRecord '"+ALLTRIM(tabills.id_tblBills)+"', "+;
		"'"+ALLTRIM(FIXQUOTE(c_newclcode))+"', '"+ALLTRIM(c_newid)+"', '"+DTOC(DATE())+"', "+;
		"'"+c_userid+"'"
	pn_errors=omed.sqlexecute(lcSQLLine,"")

**10/25/2010 GSK1 needs the 3rd pty billing info on 'A042911P'
	IF tabills.at_code ='A042911P' AND l_newform
		c_SQL=""

		c_SQL="exec	[dbo].[qc_Update3rdBillParty]  '" +NVL(c_fileno,'') + ;
			"','" + NVL(c_claim,'') +  "','" + NVL(c_insur,'') + "','"  + ;
			NVL(c_adj,'')  + "','" + FIXQUOTE(c_newclcode) + ;
			"','" + FIXQUOTE(tabills.at_code)+"','" + NVL(c_ordby,'') + "','"  + ;
			NVL( c_billto,'') + "','" + NVL(c_accdate,'') + "'"


		omed.sqlexecute(c_SQL,"")


	ENDIF


	c_SQL =" exec [dbo].[GetShipbyClcodeAtcode] '" + c_oldclcode + "','" + FIXQUOTE(tabills.at_code) + "'"

	omed.sqlexecute(c_SQL,"gtaship")


	SELECT gtaship
	IF RECCOUNT("gtaship")>0
*!*			c_SQL="SELECT id_tblBills FROM tblbill WHERE cl_code='"+c_newclcode+"'"+;
*!*				" and at_code='"+fixquote(tabills.At_Code)+"' and active=1 "
		c_SQL=" EXEC [dbo].[GetBillsByClCodeAtCode] '" + c_newclcode+"','" + FIXQUOTE(tabills.at_code)+"'"
		omed.sqlexecute(c_SQL,"newtabills")
		c_SQL=" exec [dbo].[InsertShipMethodRecord] '" + c_newclcode+"','" + ;
			FIXQUOTE(tabills.at_code)+"','" +;
			NVL(IIF(gtaship.rpapernum > 0, "1", "0"),"0")+"',"+;
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
			"'"+newtabills.id_tblBills+"','"+;
			c_userid+"'"



		omed.sqlexecute(c_SQL,"")


	ENDIF
	SELECT tabills
ENDSCAN
************************

**only rq atty get 3rd party bill data when .ad is empty
IF TYPE('c_3rdbill')<>'C'
c_3rdbill=""
endif
IF l_newform  AND EMPTY(c_3rdbill)&&
	c_SQL=""

	c_SQL="exec	[dbo].[qc_Update3rdBillParty]  '" +NVL(c_filenoreq,'') + ;
		"','" + NVL(c_claimreq,'') +  "','" + NVL(c_insur,'') + "','"  + ;
		NVL(c_adj,'')  + "','" + FIXQUOTE(c_newclcode) +	"','" + FIXQUOTE(MASTER.rq_at_codE) + ;
		"','" + NVL(c_ordby,'') + "','"  + ;
		NVL( c_billto,'') + "','" + NVL(c_accdate,'') + "'"



	omed.sqlexecute(c_SQL,"")

ENDIF


RETURN
************************************************************************
************************************************************************
PROCEDURE  indxthefile
LOCAL lcFileN AS STRING
************************************************************************
IF USED ('TODOFILE')
	SELECT TODOFILE
	USE
ENDIF

SELECT 0

lcFileN="'" + PC_TODOFILE + "'"
USE &lcFileN  ALIAS TODOFILE  EXCLUSIVE

GO TOP
DELETE NEXT 1
DELETE FOR EMPTY(ALLTRIM(a)) AND EMPTY(ALLTRIM(b))
INDEX ON AY TAG lrs_no ADDITIVE
USE


RETURN
************************************************************************



