

*****************************************************************************************
*-- add case and tags to system from table created from a user populated excel spreadsheet
*****************************************************************************************

PARAMETERS c_origrt,c_lit,c_area,cgroup,cpath,cplaintiff,locr,ccasesource,btagstatus,bMailid,bBates,bDirectCopy

IF PCOUNT()<8
	gfmessage("Problem with set-up data.Contact IT.")
	RETURN
ENDIF

PRIVATE pn_errors,c_userid,c_today , c_tempFile , l_Continue AS Boolean ;
	,omed AS OBJECT,c_softfilepath,c_readyname,n_pagecnt,c_user,c_mailid ;
	,c_provtype,l_ocr,c_group,c_priority,c_casesource,l_Testuser,c_user,objconn,bFirstlook,cLitigation,cArea

cLitigation = c_lit
cArea =c_area
*--- set up flags for data to use from excel
PRIVATE bUsetagstatus,bUseMailid,bUseBates,bUseDirectCopy
bUsetagstatus = btagstatus
bUseMailid = bMailid
bUseBates = bBates
bUseDirectCopy = bDirectCopy
LOCAL nct,nitems,ncurrow,c_savlname,c_plaintiff,c_lname,nicnt

c_softfilepath=ADDBS(ALLTRIM(cpath))
c_readyname=''
n_pagecnt=0
*c_user=ALLTRIM(goApp.CurrentUser.ntlogin)
c_provtype=NVL(cplaintiff,'P')
c_mailid='A456475'
l_ocr=NVL(locr,.F.)
c_group=ALLTRIM(cgroup)
c_priority='6'
omed=CREATEOBJECT("medrequest")
objconn=CREATEOBJECT('cntdataconn')
c_today=DTOC(DATE())
pn_errors=.F.
l_CopyAttorneys=.T.
c_userid='BatchAdd_' + c_lit

c_user=ALLTRIM(goApp.CurrentUser.orec.login)
c_sql="[dbo].[GettestrSSimagestate] '"+c_user+"'"
nr=objconn.sqlpassthrough(c_sql,'viewrss')
l_Testuser=.F.
IF nr
	l_Testuser=NVL(viewrss.state,.F.)
ENDIF


IF NVL(ccasesource,'T')<>"C"

	IF NOT USED('MAster') && get a master for a template RT case

		c_sql="dbo.GetMasterbyRTNumber "+ ;
			IIF(ccasesource="C",ALLTRIM(STR(newcase.base_rt)),c_origrt)
		objconn.sqlpassthrough(c_sql,"Master")
*omed.sqlexecute(c_SQL,"Master")
	ENDIF

	SELECT MASTER

	n_currArea = SELECT()

	ID_OrigCase=MASTER.id_tblmaster
	c_origclcode=MASTER.cl_code
	c_litigation=MASTER.litigation
	IF ALLTRIM(UPPER(c_litigation))<>ALLTRIM(UPPER(c_lit))
		gfmessage("Original case has wrong litigation")
		RETURN
	ENDIF

	c_acctmgr=MASTER.acct_mgr

	c_sql="dbo.GetInstructionRecord '&ID_OrigCase.'"
	objconn.sqlpassthrough(c_sql,"instruct")
	id_tblinstruct = INSTRUCT.id_tblinstruct

&& get atty's list
	**10/01/18 SL #109598
	*c_sql = "SELECT id_tblBills, at_code FROM tblBill with (INDEX(ix_tblBills)) " + 
	c_sql = "SELECT id_tblBills, at_code FROM tblBill " + ;
		"WHERE id_tblMaster = '" + ID_OrigCase + "' " + ;
		"AND Active = 1 ORDER BY at_code"
	objconn.sqlpassthrough(c_sql,"AttyList")

	IF RECCOUNT("AttyList") = 0 THEN
		gfmessage('Original case has no participating attorneys. Processing cancelled')
		IF ccasesource="C"
			ncnt=ncnt+1
			LOOP
		ELSE
			RETURN .F.
		ENDIF
	ENDIF

	SELECT newcase
	ncnt=1
	nitems=RECCOUNT('newcase')
	SELECT newcase
	GO TOP
	DO WHILE NOT EOF()
		SELECT newcase
		ncurrow=RECNO()
		IF NOT EMPTY(newcase.lrs_no)
			SKIP
			LOOP
		ENDIF
		WAIT WINDOW "Processing new case:"+ALLTRIM(STR(ncnt))+" of "+ALLTRIM(STR(nitems)) NOWAIT NOCLEAR
*// check dubplcate cases within litigation by soc# first
		IF TYPE("newcase.soc")="C"
			c_socsec=ALLTRIM(NVL(newcase.soc,''))
		ELSE
			c_socsec=NVL(ALLTRIM(STR(newcase.soc)),'')
		ENDIF

		IF TYPE("newcase.dob")="C"
			c_dob=ALLTRIM(newcase.dob)
		ELSE
			c_dob=ALLTRIM(DTOC(newcase.dob))
		ENDIF

		IF TYPE("newcase.doD")="C"
			c_doD=ALLTRIM(newcase.doD)
		ELSE
			c_doD=ALLTRIM(DTOC(newcase.doD))
		ENDIF

		IF EMPTY(c_socsec) AND EMPTY(c_dob)
			SELECT newcase
			ncnt=ncnt+1
			SKIP
			LOOP
		ENDIF

*// check dubp by ss
		IF NOT EMPTY(c_socsec)
			n_select=SELECT()
			**10/01/18 SL #109598
			*" tblmaster with (nolock,index (ix_tblmaster_4)) WHERE ISNULL(soc_sec,'')='"+c_socsec+"' and litigation ='&c_lit.' " + 
			c_sql="SELECT lrs_no, soc_sec, plaintiff,brth_date as dob, name_last,name_first From " + ;
				" tblmaster with (nolock) WHERE ISNULL(soc_sec,'')='"+c_socsec+"' and litigation ='&c_lit.' " + ;
				IIF(NOT UPPER(ALLTRIM(c_area))=='NONE'," and area='&c_area.' ","") + ;
				" and LTRIM(RTRIM(name_last))='" + fixquote(ALLTRIM(newcase.pl_last_n)) + "' and  LTRIM(RTRIM(name_first))='" + fixquote(ALLTRIM(newcase.pl_first_n)) + "'" +;
				" AND active=1 order by lrs_no desc"
			objconn.sqlpassthrough(c_sql,"viewss")

			IF RECCOUNT('viewss')>0 AND NVL(viewss.soc_sec,'')=c_socsec
				GO TOP IN viewss
				IF TYPE("newcase.soc")="C"
					REPLACE ALL CaseExist WITH viewss.lrs_no FOR ALLTRIM(newcase.soc)==c_socsec IN newcase
				ELSE
					REPLACE ALL CaseExist WITH viewss.lrs_no FOR soc=VAL(newcase.c_socsec) IN newcase
				ENDIF
				GO (ncurrow) IN newcase
				csuffix=fncssuffix(viewss.plaintiff)
				REPLACE pl_last_n WITH ALLTRIM(pl_last_n)+csuffix IN newcase
				LOOP
			ENDIF
			SELECT (n_select)
		ELSE

*// check dubp by dob and name
			IF NOT EMPTY(dob) AND EMPTY(c_socsec)
				n_select=SELECT()
				**10/01/18 SL #109598
				*" from tblmaster with (nolock,index (ix_tblmaster_6)) WHERE ISNULL(brth_date,'')='&c_dob.'" + 
				c_sql="SELECT  lrs_no, soc_sec, plaintiff,brth_date as dob, name_last,name_first " + ;			
					" from tblmaster with (nolock) WHERE ISNULL(brth_date,'')='&c_dob.'" + ;
					" and litigation ='&c_lit.' " + ;
					IIF(NOT UPPER(ALLTRIM(c_area))=='NONE'," and area='&c_area.' ","") + ;
					" and LTRIM(RTRIM(name_last))='" + fixquote(ALLTRIM(newcase.pl_last_n)) + "' and  LTRIM(RTRIM(name_first))='" + fixquote(ALLTRIM(newcase.pl_first_n)) + "'" +;
					" AND active=1 order by lrs_no desc"

*!*						" and LTRIM(RTRIM(name_last))='" + fixquote(ALLTRIM(newcase.pl_last_n)) + "' and  LTRIM(RTRIM(name_first))='" + fixquote(ALLTRIM(newcase.pl_first_n)) + ;
*!*						"'  AND active=1  order by lrs_no desc"

				objconn.sqlpassthrough(c_sql,"viewdob")

				IF RECCOUNT('viewdob')>0 AND NVL(DTOC(viewdob.dob),'')=c_dob
					GO TOP IN viewdob
					SELECT newcase
					IF TYPE("newcase.dob")="C"
						REPLACE ALL CaseExist WITH viewdob.lrs_no FOR ALLTRIM(newcase.dob)==c_dob IN newcase
					ELSE
						REPLACE ALL CaseExist WITH viewdob.lrs_no FOR newcase.dob=CTOD(c_dob) IN newcase
					ENDIF
					GO (ncurrow) IN newcase
					csuffix=fncssuffix(viewdob.plaintiff)
					REPLACE pl_last_n WITH ALLTRIM(pl_last_n)+csuffix IN newcase
					LOOP
				ENDIF
				SELECT (n_select)
			ENDIF
		ENDIF

		STORE "" TO c_add1, c_add2, c_sql

		c_lname=UPPER(ALLTRIM(newcase.pl_last_n))
		c_lname=UPPER(IIF(RIGHT(c_lname,3)==' SR',STRTRAN(c_lname,' SR',' ,SR'),c_lname))
		c_lname=UPPER(IIF(RIGHT(c_lname,3)==' JR',STRTRAN(c_lname,' JR',' ,JR'),c_lname))
		c_plaintiff=UPPER(c_lname+" ;"+ALLTRIM(newcase.pl_first_n)+;
			IIF(NOT EMPTY(ALLTRIM(newcase.pl_mid))," "+ALLTRIM(newcase.pl_mid)+".",""))
		c_sql=""

*////// restore this statment after testing!!!! "IIF(MASTER.testcase=.T.,"0","0")	"


		c_sql="exec dbo.MirrorMasterRecord "+;
			"'"+ID_OrigCase+"', "+;
			"'"+MASTER.id_tbloffice+"', '"+MASTER.lrs_nocode+"', "+;
			"'"+IIF(MASTER.testcase=.T.,"0","0")+"', '"+IIF(MASTER.template=.T.,"0","0")+"', "+;
			"'"+fixquote(c_plaintiff)+"', '"+fixquote(c_lname)+"', '"+fixquote(newcase.pl_first_n)+"', "+;
			"'"+fixquote(newcase.pl_mid)+"', '"+fixquote(c_add1)+"', '"+fixquote(c_add2)+ "', "+;
			"'"+fixquote(MASTER.executor)+"', "+;
			"'"+c_socsec+"', "+ IIF(EMPTY(NVL(newcase.dob,{})),"null","'"+ALLTRIM(DTOC(newcase.dob))+"'")+", "+;
			IIF(EMPTY(NVL(newcase.doD,{})),"null","'"+ALLTRIM(DTOC(newcase.doD))+"'")+", "+;
			"'"+fixquote(MASTER.attorney)+"', '"+fixquote(MASTER.attyfirst)+"', '"+fixquote(MASTER.court)+"', "+;
			"'"+fixquote(MASTER.docket)+"', '"+fixquote(MASTER.district)+"', '"+fixquote(MASTER.division)+"', "+;
			"'"+fixquote(MASTER.court2)+"', '"+fixquote(MASTER.cclnumber)+"', '"+IIF(MASTER.interrog=.T.,"1","0")+"', "+;
			"'"+fixquote(MASTER.req_atty)+"', ;
		'"+fixquote(MASTER.req_atf)+"', '"+fixquote(MASTER.req_para)+"', "+;
			"'"+fixquote(MASTER.employ)+"', "+IIF(EMPTY(NVL(MASTER.sempdate,{})),"null","'"+TTOC(MASTER.sempdate)+"'")+", "+;
			IIF(EMPTY(NVL(MASTER.eempdate,{})),"null","'"+TTOC(MASTER.eempdate)+"'")+", "+;
			"'"+IIF(MASTER.mta_expect=.T.,"1","0")+"', "+;
			IIF(EMPTY(NVL(MASTER.settled,{})),"null","'"+TTOC(MASTER.settled)+"'")+", '"+fixquote(MASTER.worker)+"', "+;
			"'"+IIF(MASTER.chosen=.T.,"1","0")+"', "+;
			IIF(EMPTY(NVL(MASTER.trial_date,{})),"null","'"+TTOC(MASTER.trial_date)+"'")+", "+;
			IIF(EMPTY(NVL(MASTER.depo_date,{})),"null","'"+TTOC(MASTER.depo_date)+"'")+", "+;
			IIF(EMPTY(NVL(MASTER.assn_date,{})),"null","'"+TTOC(MASTER.assn_date)+"'")+", "+;
			IIF(EMPTY(NVL(MASTER.req_date,{})),"null","'"+TTOC(MASTER.req_date)+"'")+", '"+MASTER.COMMENT+"', "+;
			"'"+ALLTRIM(STR(MASTER.subcnt))+"', '"+fixquote(MASTER.pldeal)+"', '"+fixquote(MASTER.proj_codec)+"', "+;
			"'"+ALLTRIM(STR(MASTER.proj_coden))+"', ;
		'"+fixquote(MASTER.area)+"', '"+fixquote(MASTER.area_id)+"', "+;
			"'"+fixquote(MASTER.condition)+"', '"+fixquote(c_litigation)+"', '"+fixquote(IIF(c_group=="0",ALLTRIM(STR(MASTER.GROUP)),c_group))+"', "+;
			"'"+fixquote(MASTER.rq_at_code)+  "', '"+fixquote(MASTER.pl_at_code)+"', '"+fixquote(MASTER.sim_first)+"', "+;
			"'"+fixquote(c_acctmgr)+ "', '"+fixquote(MASTER.maiden_nam)+"', '"+fixquote(MASTER.maiden_na2)+"', "+;
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

		pn_errors=objconn.sqlpassthrough(c_sql,"viewIDs")
*pn_errors=.T.
		IF pn_errors
			IF l_CopyAttorneys && copy/mirror atty's data
				DO copy_atty WITH c_origclcode,viewIDs.cl_code,viewIDs.id_tblmaster
			ENDIF

			SELECT viewIDs
			IF RECCOUNT()>0
				IF EMPTY(c_socsec)
					IF NOT EMPTY(c_dob)
						IF TYPE("tmpexcelxyz.dob")="C"
							REPLACE ALL lrs_no WITH viewIDs.lrs_no,cl_code WITH viewIDs.cl_code   ;
								FOR CTOD(dob)=CTOD(c_dob) AND ALLTRIM(pl_last_n) = ALLTRIM(newcase.orig_lname) IN tmpexcelxyz
						ELSE
							REPLACE ALL lrs_no WITH viewIDs.lrs_no,cl_code WITH viewIDs.cl_code   ;
								FOR dob=CTOD(c_dob) AND ALLTRIM(pl_last_n) = ALLTRIM(newcase.orig_lname) IN tmpexcelxyz

						ENDIF
					ENDIF
				ELSE
					IF TYPE("tmpexcelxyz.soc")="C"
						REPLACE ALL lrs_no WITH viewIDs.lrs_no,cl_code WITH viewIDs.cl_code FOR ALLTRIM(soc)==c_socsec IN tmpexcelxyz
					ELSE
						REPLACE ALL lrs_no WITH viewIDs.lrs_no,cl_code WITH viewIDs.cl_code FOR soc=VAL(c_socsec) IN tmpexcelxyz
					ENDIF
				ENDIF
			ENDIF

		ENDIF

		ncnt=ncnt+1

		SELECT newcase
		GO (ncurrow)
		SKIP
	ENDDO
ENDIF


DO CASE
CASE ccasesource<>"C"
	SELECT DISTINCT lrs_no, cl_code, doc_type, file_name, 000 AS TAG, tag_Status, mailid_no, fl_Atty, bates_strt, bates_end, mrcitemid, mrcreqid, RECNO() AS rowid FROM tmpexcelxyz INTO CURSOR newtag READWRITE ;
		WHERE NOT EMPTY(NVL(lrs_no,0)) ORDER BY lrs_no,nid
CASE ccasesource="C"
	SELECT DISTINCT base_rt AS lrs_no, cl_code, doc_type, file_name, 000 AS TAG, tag_Status, mailid_no, fl_Atty, bates_strt, bates_end, mrcitemid, mrcreqid, RECNO() AS rowid  FROM tmpexcelxyz INTO CURSOR newtag READWRITE ;
		WHERE NOT EMPTY(NVL(base_rt,0)) ORDER BY lrs_no,nid
ENDCASE


*!*	IF ccasesource<>"C"
*!*		SELECT DISTINCT lrs_no,cl_code,doc_type,file_name,000 AS TAG FROM tmpexcelxyz INTO CURSOR newtag READWRITE ;
*!*			WHERE NOT EMPTY(NVL(lrs_no,0)) ORDER BY lrs_no,nid  &&,doc_type
*!*	ELSE
*!*		SELECT DISTINCT base_rt AS lrs_no,cl_code,doc_type,file_name,000 AS TAG FROM tmpexcelxyz INTO CURSOR newtag READWRITE ;
*!*			WHERE NOT EMPTY(NVL(base_rt,0)) ORDER BY lrs_no,nid &&,doc_type
*!*	ENDIF

nicnt=1
nitems=RECCOUNT('newtag')

IF nitems>0
	SELECT newtag
	SCAN
		WAIT WINDOW "Processing new tags:"+ALLTRIM(STR(nicnt))+" of "+ALLTRIM(STR(nitems)) NOWAIT NOCLEAR
*DO additemjob WITH newtag.lrs_no,newtag.tag
		IF NOT newtag.lrs_no=0
			IF bUseBates
*-- check that the provided bates data is properly formated (has correct number of segments)
				LOCAL aBates(2),iCnt, lOk
				aBates(1) = ALLTRIM(newtag.bates_strt)
				aBates(2) = ALLTRIM(newtag.bates_end)
				lOk = .T.
				FOR iCnt = 1 TO 2
					nbatescnt = 1
					DO WHILE .T.
						nloc =AT("_",ALLTRIM(aBates(iCnt)),nbatescnt)
						IF nloc > 0
							nbatescnt = nbatescnt + 1
						ELSE
							EXIT
						ENDIF
					ENDDO
					IF nbatescnt < 3
						lOk = .F.
					ENDIF
				NEXT
				IF lOk = .F.
					REPLACE serror WITH "BAD BATES STRING" ;
						FOR RECNO() = newtag.rowid IN tmpexcelxyz
					SELECT newtag
					LOOP

*!*						IF ccasesource<>"C"
*!*							REPLACE serror WITH "BAD BATES STRING" ;
*!*								FOR lrs_no=newtag.lrs_no AND ALLTRIM(UPPER(doc_type))==ALLTRIM(UPPER(newtag.doc_type)) IN tmpexcelxyz
*!*						ELSE
*!*							REPLACE serror WITH "BAD BATES STRING" ;
*!*								FOR base_rt=newtag.lrs_no AND ALLTRIM(UPPER(doc_type))==ALLTRIM(UPPER(newtag.doc_type)) IN tmpexcelxyz
*!*						ENDIF

				ENDIF
			ENDIF
			DO addtags WITH newtag.lrs_no,ALLTRIM(newtag.doc_type),ALLTRIM(ccasesource),ALLTRIM(tag_Status),ALLTRIM(mailid_no), ALLTRIM(fl_Atty), ALLTRIM(bates_strt), ;
				ALLTRIM(bates_end), ALLTRIM(mrcitemid), ALLTRIM(mrcreqid), newtag.rowid
		ENDIF
		SELECT newtag
		nicnt=nicnt+1
	ENDSCAN
ENDIF
WAIT CLEAR
gfmessage("Processing complete")

RELEASE objconn,omed
RETURN

**************************************************************************************
**	Copy_Atty program
**  copy all participating attorney info to a new case
**************************************************************************************
PROCEDURE copy_atty
LPARAMETERS c_oldclcode,c_newclcode,c_newid

**10/01/18 SL #109598
*c_sql="SELECT * FROM tblBill WITH (index (ix_tblbills_2)) WHERE cl_code='&c_oldclcode.' AND active=1 "
c_sql="SELECT * FROM tblBill WHERE cl_code='&c_oldclcode.' AND active=1 "
objconn.sqlpassthrough(c_sql,"tabills")

SELECT tabills

SCAN
	lcSQLLine="exec dbo.InsertBillRecord '"+ALLTRIM(tabills.id_tblBills)+"', "+;
		"'"+ALLTRIM(fixquote(c_newclcode))+"', '"+ALLTRIM(c_newid)+"', '"+DTOC(DATE())+"', "+;
		"'"+c_userid+"'"
	pn_errors=objconn.sqlpassthrough(lcSQLLine,"")


	c_sql="select * from tblShip "+;
		" where cl_code='"+c_oldclcode+"' and at_code='"+fixquote(tabills.At_Code)+;
		"' and active=1 and deleted IS null"
	objconn.sqlpassthrough(c_sql,"gtaship")


	SELECT gtaship
	IF RECCOUNT("gtaship")>0
		c_sql="SELECT id_tblBills FROM tblbill WHERE cl_code='"+c_newclcode+"'"+;
			" and at_code='"+fixquote(tabills.At_Code)+"' and active=1 "
		objconn.sqlpassthrough(c_sql,"newtabills")

		c_sql="Insert into tblShip (cl_code, at_code,rpapernum,"+;
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

		objconn.sqlpassthrough(c_sql,"")


	ENDIF
	SELECT tabills
ENDSCAN
RETURN

**********************************************************************
FUNCTION fncssuffix
PARAMETERS c_plaintiff
npos=AT(";",c_plaintiff)
c_lname=ALLTRIM(SUBSTR(c_plaintiff,1,npos-1))
c_suffix="1"
IF BETWEEN(ASC(RIGHT(c_lname,1)),48,57)
	c_suffix=ALLTRIM(STR(VAL(RIGHT(c_lname,1))+1))
ENDIF
RETURN c_suffix


**********************************************************************
PROCEDURE addtags
LPARAMETERS nrt,cdescript,ccsource,ctagstaus,cmailid,cflatty,cBates_strt,cBates_end,cmrcitemid,cmrcreqid,nRowid
LOCAL lcSQLLine, lcIDTblTimeSheet, lcReqType,ncurarea,cclcode,cFile,cCurMailid,cSubjectid,dtDCreqdate,dtDCrelqdate,dtrelease,sItemtype,cSubjectid
STORE CTOD('1/1/1900') TO dtDCreqdate,dtDCrelqdate

cmrcreqid = ALLTRIM(cmrcreqid)
cmrcitemid= ALLTRIM(cmrcitemid)
cSubjectid = ""
cCurMailid = IIF(bUseMailid = .T. AND NOT EMPTY(cmailid),cmailid,c_mailid )


bFirstlook = .F.
ncurarea=SELECT()
cFile =ADDBS(c_softfilepath)+ALLTRIM(newtag.file_name)

IF NOT FILE(cFile)
*gfmessage("Add tag cancelled. Soft copy file not found.")
	RETURN .F.
ENDIF

*// Request Type
lcReqType='RT'

lcSQLLine="exec dbo.getmasterbyrt " + ALLTRIM(STR(nrt))
nr=objconn.sqlpassthrough(lcSQLLine,"master")

IF RECCOUNT("master")=0
	RETURN .F.
ENDIF

cclcode=MASTER.cl_code

*// Request
lcSQLLine="exec  dbo.InsertQuickRequest '"+ALLTRIM(MASTER.id_tblmaster)+"', "+;
	"'"+fixquote(ALLTRIM(cclcode))+"', '"+ALLTRIM(cCurMailid)+"', "+;
	"'"+LEFT(fixquote(ALLTRIM(UPPER(cdescript))),50)+"', "+;
	"'"+c_today+"', 'R', "+;
	'1'+", '(AR) "+ALLTRIM(c_userid)+"'"
nr=objconn.sqlpassthrough(lcSQLLine,"viewReq")
SELECT viewReq
IF RECCOUNT()=0
	RETURN .F.
ENDIF

**10/01/18 SL #109598
*lcSQLLine="SELECT * FROM tblrequest with (nolock,index (pk_tblrequests)) WHERE id_tblrequests ='"+viewReq.id_tblrequests+"'"
lcSQLLine="SELECT * FROM tblrequest with (nolock) WHERE id_tblrequests ='"+viewReq.id_tblrequests+"'"
nr=objconn.sqlpassthrough(lcSQLLine,"viewRequest")

*// due date
c_due = DTOC(gfChkDat( d_today +10, .F., .F.))
lcSQLLine="update tblRequest set tag_type='"+ALLTRIM(UPPER(lcReqType))+"' , reqduedate='" + c_due + "' where "+;
	"id_tblrequests='"+ALLTRIM(viewRequest.id_tblrequests)+"'"
nr=objconn.sqlpassthrough(lcSQLLine)

*//Set Public Var
pl_GotCase=.F.
DO gfGetCas
pl_GotDepo=.F.
DO gfGetDep WITH MASTER.cl_code,viewRequest.TAG

*// TXN 11
lcIDTblTimeSheet=objconn.addtxnrec("I",d_today,;
	fixquote(ALLTRIM(UPPER(cdescript))), ALLTRIM(cclcode),11,;
	viewRequest.TAG,ALLTRIM(cCurMailid), 0,0.0000, 0, "","","",0, ;
	"",NVL(viewRequest.TYPE,''),c_userid, viewRequest.id_tblrequests, "")

*// SpecIns
lcSQLLine="Exec dbo.EditSpecIns  NULL, '"+lcIDTblTimeSheet+"', "+;
	"'"+fixquote(ALLTRIM(cclcode))+"', '"+ALLTRIM(STR(viewRequest.TAG))+"',"+;
	"'','"+LEFT(fixquote(ALLTRIM(UPPER(cdescript))),50)+"',"+;
	"'"+DTOC(convrtDate(d_today))+ "', 'A', 1, '"+ALLTRIM(cCurMailid)+"', "+;
	"'Z', '', 0, '"+DTOC(convrtDate(d_today))+ "', '"+c_userid+"', 1, 0, ''"
nr=objconn.sqlpassthrough(lcSQLLine)

IF bDirectCopy
	c_sql = "exec [dbo].[Mrcgetitembyrequestid]  '&cmrcreqid.','&cmrcitemid.'"
	nr=objconn.sqlpassthrough(c_sql,"mrcdata")
	IF RECCOUNT("mrcdata") > 0
		cSubjectid = ALLTRIM(NVL(mrcdata.subjectid,""))
		dtDCreqdate = mrcdata.dtRequestSent
		dtDCreldate = mrcdata.dtrelease
	ELSE
		RETURN .F.
	ENDIF
ENDIF

*// TXN 1 or 41
IF bUsetagstatus = .T.
	DO CASE
	CASE UPPER(ALLTRIM(ctagstaus)) == "N"
*--Add NRS
		c_sql="Update tblrequest set status='N',hstatus='' where "+;
			"id_tblrequests='"+ALLTRIM(viewRequest.id_tblrequests)+"'"
		nr=objconn.sqlpassthrough(c_sql)

		lcIDTblTimeSheet=objconn.addtxnrec("I",d_today,;
			fixquote(ALLTRIM(UPPER(cdescript))), fixquote(ALLTRIM(cclcode)),41,;
			viewRequest.TAG,ALLTRIM(cCurMailid), 0,0.0000, 0, "","","",0, ;
			"", "","(AR)"+c_userid, viewRequest.id_tblrequests, "")
	CASE UPPER(ALLTRIM(ctagstaus)) == "F"
*-- Add first-look
		LOCAL ldReturn AS DATE ,ldSentDate AS DATE, sItemtype AS CHARACTER
		ldReturn = CTOD('1/1/1900')
		ldSentDate = CTOD('1/1/1900')
		nDaysDiff = 0
		sItemtype = "RECORD"
		IF bDirectCopy
			IF RECCOUNT("mrcdata") > 0
				dtrelease = mrcdata.dtrelease
				sItemtype = UPPER(ALLTRIM(NVL(mrcdata.sItemtype,"")))
				cSubjectid = ALLTRIM(NVL(mrcdata.subjectid,""))
			ENDIF
			IF NOT ISNULL(dtrelease) AND NOT EMPTY(dtrelease)
*-- calculate release date
				nDaysDiff = VAL(SYS(11,dtrelease)) - VAL(SYS(11,CTOD('1/17/2014')))
				IF nDaysDiff > 0
					ldReturn=DATE()+(nDaysDiff)
				ENDIF
			ELSE
*-- default release date is set to 20 days from current date
				ldReturn=DATE()+ (20)
			ENDIF
*-- the delivery date has to be a buisiness day
			ldReturn = gfChkDat(ldReturn,.F.,.F.)
		ENDIF
		IF ldReturn <> CTOD('1/1/1900')
			ldSentDate = DATE() &&CTOD('1/1/1900')
			cSentDate= IIF(ISNULL(ldSentDate),"null", "'"+ DTOC(ldSentDate)+"'"  )
			cduedate = IIF(ISNULL(ldReturn),"null", "'"+ DTOC(ldReturn) + "'")
			c_sql="Update tblrequest set status='F',first_look=1,fl_atty ='&cflatty',datedlv_88=&cSentDate.,datedue_88=&cduedate.,hstatus='' where "+;
				"id_tblrequests='"+ALLTRIM(viewRequest.id_tblrequests)+"'"
			nr=objconn.sqlpassthrough(c_sql)
		ENDIF
		c_typeday=''
		bFirstlook = .T.
*-- add txn 1 to flentry table or txn 41 to timesheet table
		IF (ALLTRIM(UPPER(sItemtype))=="NO RECORD" OR ALLTRIM(UPPER(sItemtype))=="NRS")

*--5/29/15 add hidden Txn 41
			DO flAddTxn IN flproc WITH MASTER.cl_code,viewRequest.TAG,41,ALLTRIM(cCurMailid),ALLTRIM(UPPER(cdescript)),.F.,.F.,;
				0, ""

*!*				lcIDTblTimeSheet=objconn.addtxnrec("I",d_today,;
*!*					fixquote(ALLTRIM(UPPER(cdescript))), fixquote(ALLTRIM(cclcode)),41,;
*!*					viewRequest.TAG,ALLTRIM(cCurMailid), 0,0.0000, 0, "","","",0, ;
*!*					"", "","(AR)"+c_userid, viewRequest.id_tblrequests, "")

		ELSE
			DO flAddTxn IN flproc WITH MASTER.cl_code,viewRequest.TAG,1,ALLTRIM(cCurMailid),ALLTRIM(UPPER(cdescript)),.F.,.F.,;
				0, ""
		ENDIF

*--add 88 txn
		cIDTblTimeSheet=objconn.addtxnrec("I",DATE(), ;
			"First Look: Deliver " + DTOC(ldSentDate) + ", Due back " + DTOC(ldReturn), ;
			pc_clcode, 88, pn_tag, cCurMailid, 0, 0, nDaysDiff, ;
			"","",0,0, "FIRSTLOOK2","",goApp.CurrentUser.ntlogin,viewRequest.id_tblrequests,"")

* update tblRequest
		c_sql="update tblrequest set datedlv_88='"+DTOC(ldSentDate)+"', datedue_88='"+;
			DTOC(ldReturn)+"' where id_tblRequests='"+viewRequest.id_tblrequests+"' and active=1"
		nr=objconn.sqlpassthrough(c_sql)

	OTHERWISE
*-- Add record
		c_sql="Update tblrequest set status='R',hstatus='' where "+;
			"id_tblrequests='"+ALLTRIM(viewRequest.id_tblrequests)+"'"
		nr=objconn.sqlpassthrough(c_sql)

		lcIDTblTimeSheet=objconn.addtxnrec("I",d_today,;
			fixquote(ALLTRIM(UPPER(cdescript))), fixquote(ALLTRIM(cclcode)),1,;
			viewRequest.TAG,ALLTRIM(cCurMailid), 0,0.0000, 0, "","","",0, ;
			"", "","(AR)"+c_userid, viewRequest.id_tblrequests, "")
	ENDCASE
ELSE
	c_sql="Update tblrequest set status='R',hstatus='' where "+;
		"id_tblrequests='"+ALLTRIM(viewRequest.id_tblrequests)+"'"
	nr=objconn.sqlpassthrough(c_sql)

	lcIDTblTimeSheet=objconn.addtxnrec("I",d_today,;
		fixquote(ALLTRIM(UPPER(cdescript))), fixquote(ALLTRIM(cclcode)),1,;
		viewRequest.TAG,ALLTRIM(cCurMailid), 0,0.0000, 0, "","","",0, ;
		"", "","(AR)"+c_userid, viewRequest.id_tblrequests, "")
ENDIF

*// Add Admissn categories
IF c_provtype="P"
	lcStatment="'Documents produced by plaintiff counsel are attached.'"
ELSE
	lcStatment="'Documents produced by defense counsel are attached.'"
ENDIF
lcSQLLine="exec dbo.insertAdmissnRecord '"+fixquote(ALLTRIM(cclcode))+"', "+;
	ALLTRIM(STR(viewRequest.TAG))+", '1', 'R', '!',"+;
	ALLTRIM(lcStatment)+", '"+c_userid+"'"
nr=objconn.sqlpassthrough(lcSQLLine)

*// Add Orders, distBill
DO SetOrdTg WITH viewRequest.TAG, .T.

*// Post jobs to DistToDo
IF bUsetagstatus = .T. AND UPPER(ALLTRIM(ctagstaus)) == "F"
	DO postfljob WITH cflatty,nrt,viewRequest.TAG
ELSE
	DO postdsjob WITH cclcode,viewRequest.TAG
ENDIF

*// update request and recieve dates
IF bDirectCopy
	IF dtDCreqdate > CTOD('1/1/1900')
		lcSQLLine= "update tblrequest set open_date ='" + DTOC(dtDCreqdate) + "', req_date ='" + DTOC(dtDCreqdate) + "', send_date ='" + DTOC(dtDCreqdate)+ "'" + ;
			" where id_tblrequests='"+ALLTRIM(viewRequest.id_tblrequests)+"'"
		nr=objconn.sqlpassthrough(lcSQLLine)

		lcSQLLine= "update tbltimesheet set txn_date ='" + DTOC(dtDCreqdate) + "'" + ;
			" WHERE txn_code=11 AND id_tblrequests='"+ALLTRIM(viewRequest.id_tblrequests)+"'"
		nr=objconn.sqlpassthrough(lcSQLLine)
	ENDIF
	IF dtDCrelqdate > CTOD('1/1/1900')
		lcSQLLine= "update tbltimesheet set txn_date ='" + DTOC(dtDCreldate) + "'" + ;
			" WHERE txn_code IN (1,41) AND id_tblrequests='"+ALLTRIM(viewRequest.id_tblrequests)+"'"
		nr=objconn.sqlpassthrough(lcSQLLine)
	ENDIF
ENDIF


*// Add Bates
IF bUseBates = .T.
	bResult = tbaddbates(nrt, viewRequest.TAG, cBates_strt, cBates_end)
	IF bResult = .F.

		REPLACE serror WITH "FAILED TO CREATED BATES DATA" ;
			FOR RECNO() = nRowid IN tmpexcelxyz
*--FOR lrs_no=nrt AND ALLTRIM(UPPER(doc_type))==ALLTRIM(UPPER(cdescript)) IN tmpexcelxyz
	ENDIF
ELSE
	DO addbates WITH viewRequest.TAG,MASTER.cl_code,MASTER.id_tblmaster,cdescript
ENDIF

*//make cover page
IF bUseDirectCopy=.F.
	STORE .T. TO pl_autosc,pl_Softimg,pl_addcasetag
	DO CovLet WITH .T.,"","P","",.T.
ENDIF

STORE .F. TO pl_autosc,pl_Softimg,pl_addcasetag

*// add soft copy job and process image file
DO additemjob WITH nrt,viewRequest.TAG,cclcode,ALLTRIM(cmrcreqid),cSubjectid,ALLTRIM(cmrcitemid)


REPLACE TAG WITH viewRequest.TAG ;
	FOR RECNO() = nRowid IN tmpexcelxyz

*!*	IF ccsource<>"C"
*!*		REPLACE TAG WITH viewRequest.TAG ;
*!*			FOR lrs_no=nrt AND ALLTRIM(UPPER(doc_type))==ALLTRIM(UPPER(cdescript)) IN tmpexcelxyz
*!*	ELSE
*!*		REPLACE TAG WITH viewRequest.TAG ;
*!*			FOR base_rt=nrt AND ALLTRIM(UPPER(doc_type))==ALLTRIM(UPPER(cdescript)) IN tmpexcelxyz
*!*	ENDIF

IF NOT EMPTY(ncurarea)
	SELECT (ncurarea)
ENDIF

************************************************************************
PROCEDURE additemjob
PARAMETERS nlrsno,ntag,c_clcode,c_mrcreqid,c_Subjectid, c_mrcitemid
LOCAL ctype,c_sql,nr,s_Now,o_tif,c_readyname,cfilename
IF bUseDirectCopy=.F.
	c_readyname=""
	cfilename=ADDBS(c_softfilepath)+ALLTRIM(newtag.file_name)
	o_tif=CREATEOBJECT("issued.frmautoimage",nlrsno,ntag,cfilename)
	n_pagecnt=o_tif.itotalpages
	c_readyname=o_tif.workfile
	RELEASE o_tif
ELSE
	cfilename=ADDBS(c_softfilepath)+ALLTRIM(newtag.file_name)
	c_readyname = "Zol DC:" + ALLTRIM(newtag.file_name)
	c_sql = "exec [dbo].[FilemoverAddjob] 'MOVE'" + ;
		"," + ALLTRIM(STR(nlrsno)) + ;
		"," + ALLTRIM(STR(ntag))  + ;
		"," +  IIF(bFirstlook = .T.,"1","0") + ;
		",'" + gfstrclean(NVL(cfilename,''))+"'" +;
		",''" + ;
		",'" + gfstrclean(c_userid)+"'" + ;
		",'" + gfstrclean(NVL(c_Subjectid,''))+"'" + ;
		",'" + gfstrclean(NVL(c_mrcreqid,''))+"'" + ;
		",'" + gfstrclean(NVL(c_mrcitemid,''))+"'"

	nr=objconn.sqlpassthrough(c_sql)

	IF NOT EMPTY(c_mrcreqid)
		lcSQLLine="exec dbo.addmrcwtags " + ;
			"'" + fixquote(ALLTRIM(c_Subjectid))+"'" + ;
			"," +ALLTRIM(STR(nlrsno)) + ;
			",'" + fixquote(ALLTRIM(c_clcode))+"'" + ;
			"," + ALLTRIM(STR(ntag)) + ;
			",'" + gfstrclean(ALLTRIM(c_mrcreqid))+"'"
		nr=objconn.sqlpassthrough(lcSQLLine)
	ENDIF
ENDIF

IF EMPTY(c_readyname)
*gfmessage("ERROR: soft copy file not saved!")
ENDIF

c_sql = "Select top 1 nid From tblTagTrack where lrs_no=" + ALLTRIM(STR(nlrsno)) + " ;
	And tag=" + ALLTRIM(STR(ntag)) + " And deleted is null and active=1"
nr=objconn.sqlpassthrough(c_sql,'Tagtrack')

IF RECCOUNT('Tagtrack')<1
	IF NOT USED('viewrequest')
		c_sql="exec dbo.getrequestbylrsno "+ALLTRIM(STR(nlrsno)) + "," +ALLTRIM(STR(ntag))
		nr=objconn.sqlpassthrough(c_sql,'viewrequest')
	ENDIF

	c_sql="Insert Into tblTagTrack " +;
		"(lrs_no,tag,req_date,mailid_no,litigation,rush,created,createdby,active) values (" +;
		ALLTRIM(STR(nlrsno)) + "," + ;
		ALLTRIM(STR(ntag)) + "," + ;
		IIF(EMPTY(NVL(viewRequest.req_date,{})),'null',"'"+DTOC(TTOD(viewRequest.req_date))+"'") + "," +;
		"'"+NVL(viewRequest.mailid_no,'')+"'" + "," +;
		"'"+NVL(MASTER.litigation,'')+"'"+ "," +;
		IIF(viewRequest.expedite,'1','0') + "," +;
		"getdate()" + "," +;
		"'"+c_userid+"'"+ "," +;
		"1)"
	nr=objconn.sqlpassthrough(c_sql)

	c_sql = "Select top 1 nid From tblTagTrack where lrs_no=" + ALLTRIM(STR(nlrsno)) + " ;
		And tag=" + ALLTRIM(STR(ntag)) + " And deleted is null and active=1"
	nr=objconn.sqlpassthrough(c_sql,'Tagtrack')
ENDIF

s_Now=TTOC(DATETIME())

ctype='R'

c_sql="Insert Into tblTagItem " + ;
	"(nid_tblTagTrack,lrs_no,tag,doc_type,rec_mode,created,createdby,preproc_done,preproc_user"+;
	",softcopy_assign,softcopy_user,active,softcopy_infolder,prov_client,softcopy_done) values (" + ;
	tagtrack.nid + "," + ;
	ALLTRIM(STR(nlrsno)) + "," + ;
	ALLTRIM(STR(ntag)) + "," + ;
	"'&cType.','A'," + ;
	"'"+s_Now+ "'," + ;
	"'"+c_userid+"'" + "," +;
	"'"+s_Now+ "'," +;
	"'"+c_userid+"'" + "," +;
	"getdate()" + "," +;
	"'"+c_userid+"'"+ "," +;
	"1," +;
	"'" + gfstrclean(c_readyname) + "'" +;
	",'" + '' + "'" + "," +;
	"getdate()" +;
	")"
nr=objconn.sqlpassthrough(c_sql)

IF USED('viewjobS')
 USE IN viewjobS
ENDIF
cJob = "0"
c_sql = ""
c_sql="select *,doc_type as doctype from tbltagitem where "+;
	"nid_tbltagtrack="+tagtrack.nid + " and " + ;
	"lrs_no="+ALLTRIM(STR(nlrsno)) + " and " + ;
	"tag="+ALLTRIM(STR(ntag)) + " and doc_type='&cType.' and " + ;
	"rec_mode='A' and created=cast('"+s_Now+"' as datetime)"
nr=objconn.sqlpassthrough(c_sql,'viewjobS')
IF nr=.T.
	IF USED('viewjobS')
		cJob = ALLTRIM(viewjobS.nid)
		USE IN viewjobS
	ENDIF
ENDIF

IF bUseDirectCopy=.F.
	IF NOT ALLTRIM(NVL(cJob,"0")) =="0" 		&& RECCOUNT('viewjobS')>0
		IF INLIST(ctype,'R','IR')
			c_sql="update tblrequest set nid_tbltagitem=" + ALLTRIM(cJob) + ;
				" ,pages=" + ALLTRIM(STR(n_pagecnt)) + ;
				" where cl_code=dbo.getclcodebylrs(" + ALLTRIM(STR(nlrsno)) + ")" + ;
				" And tag=" + ALLTRIM(STR(ntag)) + " And deleted is null and active=1"
*!*				c_sql="update tblrequest set nid_tbltagitem=" + ALLTRIM(viewjobS.nid) + ;
*!*					" ,pages=" + ALLTRIM(STR(n_pagecnt)) + ;
*!*					" where cl_code=dbo.getclcodebylrs(" + ALLTRIM(STR(nlrsno)) + ")" + ;
*!*					" And tag=" + ALLTRIM(STR(ntag)) + " And deleted is null and active=1"
			nr=objconn.sqlpassthrough(c_sql)
		ENDIF
	ENDIF

	DO addtorss WITH nlrsno,ntag,cJob,c_readyname
	*--DO addtorss WITH nlrsno,ntag,viewjobS.nid,c_readyname
ENDIF

*************************************************************************
PROCEDURE addtorss
PARAMETERS nlrsno,ntag,nid,cthefile
LOCAL cpath,cFile,ccovpath
cpath=JUSTPATH(cthefile)
cFile=JUSTFNAME(cthefile)
ccovpath=''

l_needqa=.F.
c_rtpages=ALLTRIM(STR(n_pagecnt))
crsstest=IIF(l_Testuser,"1","0")
crsstable=IIF(l_Testuser,"playground..tblRssjobs","tblRssjobs")

c_sql = "INSERT INTO " + crsstable + ;
	" (dtCreated, sRt, nTag, sPath, sFile, sCovPath, sDeletePages,npriority,suser" + ;
	",bneedqa,sqcqueue,nid_tbltagitem,NRTPAGES,brsstest)" + ;
	" Values " + ;
	"(" + ;
	"'"+TTOC(DATETIME())+"'"+;
	","+ALLTRIM(STR(nlrsno))+;
	","+ALLTRIM(STR(ntag))+;
	",'"+gfstrclean(cpath)+"'"+;
	",'"+gfstrclean(cFile)+"'"+;
	",'"+gfstrclean(ccovpath)+"'"+;
	",'"+''+"'"+;
	","+c_priority+;
	",'"+c_userid+"'"+;
	","+IIF(l_needqa,"1","0")+;
	",'"+c_userid+"'"+;
	","+ALLTRIM(nid)+;
	","+c_rtpages+;
	","+crsstest+;
	")"

nr=objconn.sqlpassthrough(c_sql)

***************************************************************************
PROCEDURE addbates
LPARAMETERS lnTag,cclcode,idtblmaster,cdesc
LOCAL lnCurArea
lnCurArea=SELECT()
nr=objconn.sqlpassthrough("SELECT specbates FROM tblinstruct WITH (nolock) "+;
	"WHERE cl_code='"+cclcode+"' AND active=1",'viewInstruct')
SELECT viewInstruct

IF RECCOUNT()>0 AND UPPER(ALLTRIM(NVL(viewInstruct.specbates,"")))=="S"
	goApp.OpenForm("case.frmbateslist", "M",NULL,idtblmaster, ;
		cclcode, .T., lnTag, ALLTRIM(UPPER(cdesc)), .T., c_provtype)
ENDIF
*NVL(viewInstruct.bates,.F.)=.T.
USE IN viewInstruct
SELECT (lnCurArea)

***************************************************************************
PROCEDURE postdsjob
PARAMETERS c_clcode,ntag
LOCAL n_curarea,c_shiptype,sDonotocr,n_dsid
n_curarea=SELECT()
SELECT 0
**10/01/18 SL #109598
*c_sql="select * from tblorder WITH (nolock,index (ix_tblorder_1)) where "+
c_sql="select * from tblorder WITH (nolock) where "+;
	"cl_code='&c_clcode.' and tag="+STR(ntag)+;
	"AND date_order is not null AND date_decln IS null AND date_cancl is null "+;
	"AND active=1 and deleted is null"
objconn.sqlpassthrough(c_sql,'actorders')

IF RECCOUNT('actorders')>0
	SELECT actorders
	DIMENSION a_types[6]
	a_types[1]="P"
	a_types[2]="D"
	a_types[3]="V"
	a_types[4]="C"
	a_types[5]="F"
	a_types[6]="W"
	n_Alen=ALEN(a_types, 1)
	sDonotocr=IIF(l_ocr,"0","1")
	SCAN
		c_Ordtypes = IIF( actorders.NumCopy > 0 AND ;
			INLIST(actorders.shiptype, " ", "P"), "P", actorders.shiptype)

		lcSQLLine="Exec dbo.call_dsordertype '"+c_clcode+"', "+ALLTRIM(STR(ntag))+","+ ;
			"'"+fixquote(actorders.At_Code)+"', '"+""+"', '"+actorders.shiptype+"', '1', "+;
			"'"+actorders.id_tblOrders+"', '', '&c_Ordtypes.',2"
		objconn.sqlpassthrough(lcSQLLine,"viewShipTypes")
		SELECT viewShipTypes
		IF RECCOUNT()>0
			GO TOP IN viewShipTypes
			c_Ordtypes=ALLTRIM(NVL(viewShipTypes.ordtypes,''))
		ENDIF
		USE IN viewShipTypes
		lcshiptype=IIF(EMPTY(c_Ordtypes),"P",c_Ordtypes)
		FOR EACH c_shiptype IN a_types
			IF c_shiptype $ lcshiptype
				IF c_shiptype<>"P"
					IF gfsendds(actorders.At_Code)
						n_dsid=gfdsjobid()
						c_sql= "EXEC dbo.dspost '&c_clcode.',"+STR(ntag)+",'"+;
							fixquote(actorders.At_Code)+"','"+fixquote(pc_Area)+"',0,'"+;
							c_shiptype+"','',1,1,NULL,'&n_dsid.',&sDonotocr."
						objconn.sqlpassthrough(c_sql)
					ENDIF
				ENDIF
			ENDIF
		ENDFOR
		SELECT actorders
	ENDSCAN
ENDIF
IF USED('actorders')
	USE IN actorders
ENDIF
SELECT (n_curarea)

*****************************************************************************************************
PROCEDURE postfljob
PARAMETERS cflatty,nrt,ntag
LOCAL n_curarea,c_shiptype,sDonotocr,n_dsid
n_curarea=SELECT()
l_Sendmail = .T.
n_dsid=gfdsjobid()
c_sql="exec dbo.dsjob '"+ALLTRIM(STR(nrt))+"', '"+ALLTRIM(STR(ntag))+"', '"+;
	ALLTRIM(fixquote(cflatty))+"', 'KF', '"+IIF(l_Sendmail=.T.,"1","0")+"', '"+;
	"ZOL"+"', 1, 0, '', '', '', 0"+", '"+ALLTRIM(STR(2))+"'"+",'&n_dsid.'"
objconn.sqlpassthrough(c_sql)

c_sql = "select top 1 job_id from tbldisttodo where lrs_no = " + ALLTRIM(STR(nrt)) + ;
	" and tag = " + ALLTRIM(STR(ntag)) + ;
	" and at_code = '" + ALLTRIM(fixquote(cflatty)) + "' " + ;
	" and rectype = 'KF' and rem_date is null order by sequenceid desc"
nr = objconn.sqlpassthrough(c_sql, "curjob")
IF nr
	IF RECCOUNT("curjob") > 0
		sJobid = NVL(curjob.job_id,'')
		c_sql="[dbo].[AddemailjobZol] 'KF','" + sJobid + "'," + ;
			ALLTRIM(STR(nrt)) + "," + ALLTRIM(STR(ntag)) + ",'" + ALLTRIM(fixquote(cflatty)) +"',''"
		objconn.sqlpassthrough(c_sql)

	ENDIF
ENDIF

IF USED("curjob")
	USE IN curjob
ENDIF

SELECT (n_curarea)

******************************************************************************************************
FUNCTION tbaddbates
PARAMETERS nRTcur, nTagcur, cBates_strt, cBates_end
cBates = "CASL_BABY_FDLRC_205"
LOCAL aTagBates(2)
aTagBates(1) = cBates_strt
aTagBates(2) = cBates_end
LOCAL aBates(1)
LOCAL ncnt,nCurLoc,nbatescnt AS NUMBER
LOCAL cBatesCas, cBatesTagstr, cbatesnum, cRt,c_litcode,c_area,lbatescase,tbcaseid
STORE "" TO cBatesCase,cBatesTagstr,cbatesnum
cRtcur = ALLTRIM(STR(nRTcur))
FOR nbatescnt = 1 TO 2
	DIMENSION aBates(1)
	cBates = aTagBates(nbatescnt)
	ncnt = 1
	nCurLoc = 1
	DO WHILE .T.
		nloc =AT("_",cBates,ncnt)
		IF nloc > 0
			DIMENSION aBates(ncnt)
			aBates(ncnt) = SUBSTR(cBates,nCurLoc, nloc-nCurLoc)
			nCurLoc = nloc + 1
			ncnt = ncnt + 1
		ELSE
			DIMENSION aBates(ncnt)
			aBates(ncnt) = SUBSTR(cBates,nCurLoc, LEN(ALLTRIM(cBates))-(nCurLoc - 1))
			EXIT
		ENDIF
	ENDDO
	IF ALEN(aBates,1) >= 3
		IF nbatescnt = 1
			IF ALEN(aBates,1) > 3
				cBatesCase= ALLTRIM(aBates(1)) + "_" + ALLTRIM(aBates(2))
			ELSE
				cBatesCase = aBates(1)
			ENDIF
			cBatesTagstr = ALLTRIM(aBates(ALEN(aBates,1) - 1))
			cbatesnumStrt=ALLTRIM(aBates(ALEN(aBates,1)))
		ELSE
			cbatesnumEnd=ALLTRIM(aBates(ALEN(aBates,1)))
		ENDIF
	ENDIF
NEXT
c_litcode = cLitigation
c_area=cArea
lbatescase = .F.
tbcaseid = 0
*--check for litigation level row in tblbatescase
**10/01/18 SL #109598
*c_sql="select * from tblbatesdef with (nolock, index (ix_tblbatesdef_1)) where slit='&c_litcode.' "+
c_sql="select * from tblbatesdef with (nolock) where slit='&c_litcode.' "+;
	"and ISNULL(sarea,'')='' and active=1"
nr=objconn.sqlpassthrough(c_sql,'batdef')

IF RECCOUNT('batdef')<1
	**10/01/18 SL #109598
	*c_sql="select * from tblbatesdef with (nolock, index (ix_tblbatesdef_1)) where slit='&c_litcode.' "+
	c_sql="select * from tblbatesdef with (nolock) where slit='&c_litcode.' "+;
		"and ISNULL(sarea,'')='&c_area.' and active=1"
	nr= objconn.sqlpassthrough(c_sql,'batdef')
ENDIF

IF RECCOUNT('batdef')<1
*--if no default return error
	RETURN .F.
ENDIF

*--check for case level row in tblbatescase
**10/01/18 SL #109598
*c_sql="select * from tblbatescase with (nolock, index (ix_tblbatescase_1)) where nbatesdefid="+ ALLTRIM(STR(batdef.nid)) +
c_sql="select * from tblbatescase with (nolock) where nbatesdefid="+ ALLTRIM(STR(batdef.nid)) + ;
	" and nRt=&cRtcur. and active=1"
nr=objconn.sqlpassthrough(c_sql,'batcase')

**10/01/18 SL #109598
*c_sql="select * from tblbatescase with (nolock, index (ix_tblbatescase_1)) where nbatesdefid="+ ALLTRIM(STR(batdef.nid)) + 
c_sql="select * from tblbatescase with (nolock) where nbatesdefid="+ ALLTRIM(STR(batdef.nid)) + ;
	" and nRt=&cRtcur. and active=1"
nr=objconn.sqlpassthrough(c_sql,'batcase')
lccaseid = "0"
IF RECCOUNT('batcase')<1
	**10/01/18 SL #109598
	*c_sql="select * from tblbatescase with (nolock, index (ix_tblbatescase_1)) where nRt=&cRtcur. and active=1"
	c_sql="select * from tblbatescase with (nolock) where nRt=&cRtcur. and active=1"
	nr=objconn.sqlpassthrough(c_sql,'batcase')
	IF RECCOUNT('batcase')<1
		c_sql= "exec dbo.addtblbatescase &pc_lrsno.,'" + gfstrclean(cBatesCase) + "'," +;
			ALLTRIM(STR(batdef.nid)) + ", 1"
		nr=objconn.sqlpassthrough(c_sql,'batcaseid')
		IF nr
			lbatescase=.T.
			lccaseid=ALLTRIM(STR(batcaseid.nid))
		ENDIF
		IF USED('batcaseid')
			USE IN batcaseid
		ENDIF
	ELSE
*gfmessage("Case already In use for different Litigation/Area conbination. Process cancelled.")
		RETURN .F.
	ENDIF
ELSE
	lccaseid=ALLTRIM(STR(batcase.nid))
ENDIF

*--accomodate user reversing order of bates strings in excel spreadsheet
IF VAL(cbatesnumStrt)>VAL(cbatesnumEnd )
	cHold = cbatesnumStrt
	cbatesnumStrt=cbatesnumEnd
	cbatesnumEnd = cHold
ENDIF

lctag=ALLTRIM(STR(nTagcur))
lcstagbates=ALLTRIM(cBatesTagstr)
lcfirstpage=ALLTRIM(cbatesnumStrt)
lclastpage=ALLTRIM(cbatesnumEnd)
*--lccaseid=ALLTRIM(STR(batcase.nid))
lccreated=DTOC(DATE())
lcuser="(AR) "+ALLTRIM(c_userid)
lcplaintiff="0"
lcfactsheet="0"
lcsupplementalto="0"
lcfactsheetstartpage="0"

IF NOT ALLTRIM(lccaseid) == "0"
	c_sql= "INSERT INTO tblbatestag " + ;
		"(ntag,stagbates,nfirstpage,nlastpage,ncaseid,dtcreated,suser" + ;
		",bplaintiff,bfactsheet,nsupplementalto,nfactsheetstartpage) " + ;
		" values (" + ;
		lctag + ;
		",'" + gfstrclean(lcstagbates) + "'" + ;
		"," + lcfirstpage + ;
		"," + lclastpage + ;
		"," + lccaseid + ;
		",getdate() " + ;
		",'" + lcuser + "'" + ;
		"," + lcplaintiff + ;
		"," + lcfactsheet + ;
		"," + lcsupplementalto + ;
		"," + lcfactsheetstartpage + ;
		")"
	lr= objconn.sqlpassthrough(c_sql)
ELSE
	RETURN .F.
ENDIF


IF USED('batdef')
	USE IN batdef
ENDIF
IF USED('batcase')
	USE IN batcase
ENDIF

RETURN .T.

************************************************************************
*!*	FUNCTION getthefile
*!*	************************************************************************
*!*	lnCurArea=SELECT()

*!*	lcCURR=SYS(5) +SYS(2003)
*!*	***
*!*	lcDefault=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","AUTOMATEDISSUE", "\")))
*!*	gfMessage("Please make sure the file is as a TEMPLATE one at T:\AVANDIA - PL\ folder.")


*!*	SET DEFAULT TO &lcDefault
*!*	**
*!*	*lcDefault="t:\avandia"
*!*	lcFile=GETFILE("XLS","Load Batch List")

*!*	IF NOT EMPTY(ALLTRIM(lcFile))

*!*		LOCAL n_div AS INTEGER, c_dir AS STRING
*!*		n_div=0
*!*		c_dir =""
*!*		n_div =RAT("\",lcFile,1)
*!*		c_dir =LEFT(lcFile, n_div)

*!*		lcFile="'"+ALLTRIM(lcFile)+"'"
*!*	**8/11/09 CALL LOADEXCEL INSTEAD OF IMPORT
*!*		SET DEFAULT TO &lcCURR
*!*		DO LOADEXCEL WITH &lcFile, c_dir, "1"
*!*	*IMPORT FROM &lcFile xl5
*!*		lcFileName=DBF()
*!*		USE
*!*		lcFileName="'"+ALLTRIM(lcFileName)+"'"
*!*		pc_ToDoFile=lcFileName
*!*		USE &lcFileName ALIAS TodoFile EXCLUSIVE
*!*		GO TOP
*!*		DELETE NEXT 1
*!*		DELETE FOR EMPTY(ALLTRIM(A)) AND EMPTY(ALLTRIM(B))

*!*		ALTER TABLE TodoFile ADD COLUMN lrs_no N(6)
*!*		ALTER TABLE TodoFile ADD COLUMN CaseExist N(6)
*!*		ALTER TABLE TodoFile ADD COLUMN TAG N(4)
*!*		ALTER TABLE TodoFile ADD COLUMN ISSUEDEP c(50)
*!*		ALTER TABLE TodoFile ADD COLUMN ISSUED L
*!*		ALTER TABLE TodoFile ADD COLUMN page1 L
*!*		ALTER TABLE TodoFile ADD COLUMN page2 L

*!*		INDEX ON S FOR .NOT.EMPTY(S) TAG MAILID ADDITIVE
*!*	*INDEX ON MAIL_ID FOR .NOT.EMPTY(MAIL_ID) TAG MAILID ADDITIVE
*!*		INDEX ON lrs_no TAG lrs_no ADDITIVE
*!*		SELECT TodoFile


*!*		USE
*!*	ENDIF && EMPTY
*!*	IF NOT EMPTY(lnCurArea)
*!*		SELECT (lnCurArea)
*!*	ENDIF
*!*	*SET DEFAULT TO &lcCURR
*!*	RETURN (lcFileName)

