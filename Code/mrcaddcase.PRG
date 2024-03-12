*****************************************************************************
**********************************************************************
*// get the list of plaintiffs to be used for new cases

PARAMETERS c_mirRt as String
PRIVATE OMED AS OBJECT
LOCAL lcSQLLine as String
lcSQLLine=""
OMED=CREATEOBJECT("REQUEST.medREQUEST")
*lcSQLLine="Exec DBO.GetMRCCases"
**4/28/14 - added GetMRCCases_WV,  [dbo].[GetMRCCases_MDL], and [dbo].[GetMRCCases_State] to add three new batches 
*lcSQLLine="Exec  [dbo].[GetMRCCases_MDL]"
*lcSQLLine="Exec [dbo].[GetMRCCases_State]"
*lcSQLLine="Exec[dbo].[GetMRCCases_WV]"
*lcSQLLine="Exec [dbo].[GetMRCCases_AreaNone]"
*lcSQLLine="Exec [dbo].[GetMRCCases_NoPlAtty]" && no pl attys and use group number 163
*lcSQLLine="Exec  dbo.GetMRCCases_ProSe"
*lcSQLLine="Exec  dbo.GetMRCCases_Rest" &&227 last cases with  '10-Active', '82-Cient Review' rrstatus
*lcSQLLine="Exec  [dbo].[GetMRCCases_60LastCases] " && 60 cases per excel's list
lcSQLLine="Exec dbo.GetMRC_Case "
L_OK=DIRECTSQL(lcSQLLine,"NewCase2") 


SELECT pl_first_n,	pl_last_n	,pl_mid ,dob,	dod	,MRCFile,TRIALDATE,	depo_DATE,	PlCaption,	PLAKA,	soc	,Pla1,	pla2,	plCity,	PlState	,PlZip,	Court,	County,	Division, ;
	District	,Docket	,RalatedId,	caseLevel	,Jurisd	,DefMatter	,SubjGrp, 000000 as  CaseExist, 000000 as lrs_no , order1, pl_at_code, 0000000 as RalatedRT ;
from newcase2  ordeR by order1  INTO CURSOR newcase  READWRITE 


*// add new cases
SCAN  


pl_suppressprint=0
c_plaintiff=UPPER(newcase.pl_last_n+" ;"+ALLTRIM(newcase.pl_FIRST_N)+;
		IIF(NOT EMPTY(ALLTRIM(newcase.pl_mid))," "+ALLTRIM(newcase.pl_mid)+".",""))
		
c_casename=	c_plaintiff  &&UPPER(ALLTRIM(newcase.pl_FIRST_N)+;
		IIF(NOT EMPTY(ALLTRIM(newcase.pl_mid))," "+ALLTRIM(newcase.pl_mid)+"."," ")) + c_lname
		
		

DO mrccase WITH c_mirRt
WAIT WINDOW 'Done.'
ENDSCAN

RELEASE omed
RETURN

***************************************************



PROCEDURE mrccase
PARAMETERS c_origrt
*!*	IF PCOUNT()<8
*!*		gfmessage("Problem with set-up data.Contact IT.")
*!*		return
*!*	ENDIF 
c_lit='ZOL'
PRIVATE pn_errors,c_userid,c_today , c_tempFile , l_Continue AS Boolean ;
	,omed AS OBJECT,c_softfilepath,c_readyname,n_pagecnt,c_user,c_mailid ;
	,c_provtype,l_ocr,c_group,c_priority,c_casesource

LOCAL nct,nitems,ncurrow,c_savlname,c_plaintiff,c_lname,nicnt

c_softfilepath=''&&ADDBS(ALLTRIM(cpath))

c_group='520' &&ALLTRIM(cgroup)

omed=CREATEOBJECT("medrequest")
c_today=DTOC(DATE())
pn_errors=.F.
l_CopyAttorneys=.T.


	IF NOT USED('MAster') && get a master for a template RT case

		c_SQL="EXEC dbo.GetMasterbyRTNumber " + c_origrt
		DIRECTSQL(C_SQL, 'Master')
		&&omed.sqlexecute(c_SQL,"Master")
	ENDIF

	SELECT MASTER

	n_currArea = SELECT()

	ID_OrigCase=MASTER.id_tblmaster
	c_origclcode=MASTER.cl_code
	c_litigation=MASTER.litigation
	C_AREA =MASTER.AREA
	IF ALLTRIM(UPPER(c_litigation))<>ALLTRIM(UPPER(c_lit))
		gfmessage("Original case has wrong litigation")
		RETURN
	ENDIF

	c_acctmgr=MASTER.acct_mgr

	c_SQL="dbo.GetInstructionRecord '&ID_OrigCase.'"
	omed.sqlexecute(c_SQL,"instruct")
	id_tblinstruct = INSTRUCT.id_tblinstruct

&& get atty's list
	**10/01/18 SL #109598
	*c_SQL = "SELECT id_tblBills, at_code FROM tblBill with (INDEX(ix_tblBills)) " + 
	c_SQL = "SELECT id_tblBills, at_code FROM tblBill " + ;
		"WHERE id_tblMaster = '" + ID_OrigCase + "' " + ;
		"AND Active = 1 ORDER BY at_code"
	omed.sqlexecute(c_SQL,"AttyList")

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
	
	SCAN
	*DO WHILE NOT EOF()
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

*!*			IF EMPTY(c_socsec) AND EMPTY(c_dob)
*!*				SELECT newcase
*!*				ncnt=ncnt+1
*!*				SKIP
*!*				LOOP
*!*			ENDIF

*// check dubp by ss
		IF NOT EMPTY(c_socsec)
			n_select=SELECT()
			**10/01/18 SL #109598
			c_SQL="SELECT lrs_no, soc_sec, plaintiff,brth_date as dob, name_last,name_first From " + ;
				*" tblmaster with (nolock,index (ix_tblmaster_4)) WHERE ISNULL(soc_sec,'')='"+c_socsec+"' and litigation ='&c_lit.' " + 
				" tblmaster with (nolock) WHERE ISNULL(soc_sec,'')='"+c_socsec+"' and litigation ='&c_lit.' " + ;
				IIF(NOT UPPER(ALLTRIM(c_area))=='NONE'," and area='&c_area.' ","") + ;
				" and LTRIM(RTRIM(name_last))='" + fixquote(ALLTRIM(newcase.pl_last_n)) + "' and  LTRIM(RTRIM(name_first))='" + fixquote(ALLTRIM(newcase.pl_first_n)) + "'" +;
				" AND active=1 order by lrs_no desc"
			omed.sqlexecute(c_SQL,"viewss")

			IF RECCOUNT('viewss')>0 AND NVL(viewss.soc_sec,'')=c_socsec
				GO TOP IN viewss
				IF TYPE("newcase.soc")="C"
					REPLACE ALL CaseExist WITH viewss.lrs_no FOR ALLTRIM(newcase.soc)==c_socsec IN newcase
				ELSE 
					REPLACE ALL CaseExist WITH viewss.lrs_no FOR soc=VAL(newcase.c_socsec) IN newcase
				ENDIF 
				
				GO (ncurrow) IN newcase
				SKIP
			*	csuffix=fncssuffix(viewss.plaintiff)
				*REPLACE pl_last_n WITH ALLTRIM(pl_last_n)+csuffix IN newcase
				LOOP
			ENDIF
			SELECT  newcase
		ELSE

*// check dubp by dob and name
			IF NOT EMPTY(dob) AND EMPTY(c_socsec)
				n_select=SELECT()
				**10/01/18 SL #109598
				c_SQL="SELECT  lrs_no, soc_sec, plaintiff,brth_date as dob, name_last,name_first " + ;
					*" from tblmaster with (nolock,index (ix_tblmaster_6)) WHERE ISNULL(brth_date,'')='&c_dob.'" + 
					" from tblmaster with (nolock) WHERE ISNULL(brth_date,'')='&c_dob.'" + ;
					" and litigation ='&c_lit.' " + ;
					IIF(NOT UPPER(ALLTRIM(c_area))=='NONE'," and area='&c_area.' ","") + ;
					" and LTRIM(RTRIM(name_last))='" + fixquote(ALLTRIM(newcase.pl_last_n)) + "' and  LTRIM(RTRIM(name_first))='" + fixquote(ALLTRIM(newcase.pl_first_n)) + "'" +;
					" AND active=1 order by lrs_no desc"


				omed.sqlexecute(c_SQL,"viewdob")

				IF RECCOUNT('viewdob')>0 AND NVL(DTOC(viewdob.dob),'')=c_dob
					GO TOP IN viewdob
					SELECT newcase
					IF TYPE("newcase.dob")="C"
						REPLACE ALL CaseExist WITH viewdob.lrs_no FOR ALLTRIM(newcase.dob)==c_dob IN newcase
					ELSE 
						REPLACE ALL CaseExist WITH viewdob.lrs_no FOR newcase.dob=CTOD(c_dob) IN newcase
					ENDIF 
					GO (ncurrow) IN newcase
					SKIP
*!*						csuffix=fncssuffix(viewdob.plaintiff)
*!*						REPLACE pl_last_n WITH ALLTRIM(pl_last_n)+csuffix IN newcase
					LOOP
				ENDIF
				SELECT  newcase
			ENDIF
		ENDIF

		STORE "" TO c_add1, c_add2, c_SQL
		c_add1=NVL(newcase.Pla1,'')
		c_add2=ALLTRIM(newcase.plCity)	+ " " + ALLTRIM(newcase.PlState)	+ ", " + ALLTRIM(PlZip)


		c_lname=UPPER(ALLTRIM(newcase.pl_last_n))
		c_lname=UPPER(IIF(RIGHT(c_lname,3)==' SR',STRTRAN(c_lname,' SR',' ,SR'),c_lname))
		c_lname=UPPER(IIF(RIGHT(c_lname,3)==' JR',STRTRAN(c_lname,' JR',' ,JR'),c_lname))
		c_plaintiff=UPPER(c_lname+" ;"+ALLTRIM(newcase.pl_first_n)+;
			IIF(NOT EMPTY(ALLTRIM(newcase.pl_mid))," "+ALLTRIM(newcase.pl_mid)+".",""))
		c_SQL=""
		c_rttype =""
		 c_rtlink=""
		
		l_chk=.f.
		DO case
		
		CASE LEFT(NEWcase.SubjGrp,10)='Mother'
		c_rttype ='MO'
		l_chk=.F.
		c_babycase=""
		
		CASE LEFT(newcase.SubjGrp,10)='Infant'
		c_rttype ='BA'		
		l_chk=.t.
		
		c_babycase=newcase.RalatedId
		OTHERWISE
		c_rttype ='DA'
		l_chk =.F.
		c_babycase=""
		
		ENDCASE
		
		c_linkedrt=""
		


STORE "" TO c_SQL, c_SQL2, c_SQL3, c_SQL4, c_SQL5, c_SQL1, C_SQL41

		c_SQL1="exec dbo.MRCMasterRecord"+;
			"'"+ID_OrigCase+"', "+;
			"'"+MASTER.id_tbloffice+"', '"+MASTER.lrs_nocode+"', "+;
			"'"+IIF(MASTER.testcase=.T.,"0","0")+"', '"+IIF(MASTER.template=.T.,"0","0")+"', "+;
			"'"+fixquote(c_plaintiff)+"', '"+fixquote(c_lname)+"', '"+fixquote(newcase.pl_first_n)+"', "+;
			"'"+fixquote(NVL(newcase.pl_mid,''))+"', '"+fixquote(c_add1)+"', '"+fixquote(NVL(c_add2,''))+ "', "+;
			"'"+fixquote(MASTER.executor)+"', " &&+
			
			c_SQL2="'"+c_socsec+"', "+ IIF(EMPTY(NVL(newcase.dob,{})),"null","'"+ALLTRIM(newcase.dob)+"'")+", "+;
			IIF(EMPTY(NVL(newcase.doD,{})),"null","'"+ALLTRIM(newcase.doD)+"'")+", "+;
			"'"+fixquote(MASTER.attorney)+"', '"+fixquote(MASTER.attyfirst)+"', '"+fixquote(newcase.court)+"', "+;
			"'"+fixquote(newcase.docket)+"', '"+fixquote(Master.district)+"', '"+fixquote(Master.division)+"', "+;
			"'"+fixquote(MASTER.court2)+"', '"+fixquote(MASTER.cclnumber)+"', '"+IIF(MASTER.interrog=.T.,"1","0")+"', "+;
			"'"+fixquote(MASTER.req_atty)+"',	'"+fixquote(MASTER.req_atf)+"', '"+fixquote(MASTER.req_para)+"', "+;
			"'"+fixquote(MASTER.employ)+"', "+IIF(EMPTY(NVL(MASTER.sempdate,{})),"null","'"+TTOC(MASTER.sempdate)+"'")+", "+;
			IIF(EMPTY(NVL(MASTER.eempdate,{})),"null","'"+TTOC(MASTER.eempdate)+"'")+", "+;
			"'"+IIF(MASTER.mta_expect=.T.,"1","0")+"', " &&+
			
			c_SQL3=IIF(EMPTY(NVL(MASTER.settled,{})),"null","'"+TTOC(MASTER.settled)+"'")+", '"+fixquote(MASTER.worker)+"', "+;
			"'"+IIF(MASTER.chosen=.T.,"1","0")+"', "+;
			IIF(EMPTY(NVL(newCase.trialdate,{})),"null","'"+(newcase.trialdate)+"'")+", "+;
			IIF(EMPTY(NVL(newcase.depo_date,{})),"null","'"+(newcase.depo_date)+"'")+", "+;
			IIF(EMPTY(NVL(MASTER.assn_date,{})),"null","'"+TTOC(MASTER.assn_date)+"'")+", "+;
			IIF(EMPTY(NVL(MASTER.req_date,{})),"null","'"+TTOC(MASTER.req_date)+"'")+", '"+MASTER.COMMENT+"', "+;
			"'"+ALLTRIM(STR(MASTER.subcnt))+"', '"+fixquote(MASTER.pldeal)+"', '"+fixquote(MASTER.proj_codec)+"', "+;
			"'"+ALLTRIM(STR(MASTER.proj_coden))+"', ;
			'"+fixquote(MASTER.area)+"', '"+fixquote(MASTER.area_id)+"', "+;
			"'"+fixquote(MASTER.condition)+"', '"+fixquote(c_litigation)+"', '"+fixquote(IIF(c_group=="0",ALLTRIM(STR(MASTER.GROUP)),c_group))+"', " &&+
			C_SQL4=""
			
			C_SQL4="'"+fixquote(MASTER.rq_at_code)+  "', '"+fixquote(NVL(newcase.pl_at_code,''))+"', '"+fixquote(MASTER.sim_first)+"', "+;
			"'"+fixquote(c_acctmgr)+ "', '"+fixquote(NEWCASE.plaka)+"', '"+fixquote(MASTER.maiden_na2)+"', "+;
			"'"+fixquote(MASTER.manufactur)+  "', '"+fixquote(MASTER.sex_first)+ "', "+;
			IIF(EMPTY(NVL(MASTER.term_date,{})),"null","'"+TTOC(MASTER.term_date)+"'")+", "+;
			"'"+fixquote(MASTER.category)+ "', '"+fixquote(MASTER.lot_no)+"', '"+fixquote(MASTER.occupation)+"', "+;
			"'"+fixquote(newCASE.county)+"', '"+fixquote(MASTER.plcap)+"', '"+fixquote(MASTER.defcap)+"', "+;
			"'"+fixquote(MASTER.device_num)+  "', " 
			
			C_SQL41=			IIF(EMPTY(NVL(MASTER.enter_date,{})),"null","'"+TTOC(MASTER.enter_date)+"'")+", "+;
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
			"'"+TTOC(DATETIME())+ "', '"+Pc_userid+"', " &&+
			
			C_SQL5="'"+fixquote(MASTER.SOURCE)+"', '"+IIF(l_CopyAttorneys=.T.,"1","0")+"','" + c_rttype + "','" +c_linkedrt + "'"
			c_sql=""
			c_sql=c_sql1+c_sql2+c_sql3+c_sql4+ C_SQL41 + c_sql5
*DO addlogline  WITH 9999 , c_sql, "RPSSQL"
		pn_errors=omed.sqlexecute(c_SQL,"viewIDs")
		*pn_errors=.T.
		IF pn_errors
		  c_SQL=""
		**add record to mrccase :
			c_SQL="insert into tblMRCCase (rt, mrcfile, pl_first_n,pl_last_n) values ('" + STR(viewIDs.lrs_no ) + "','" +   newcase.mrcfile + "','" + fixquote(newcase.pl_first_n) + "','" + fixquote(c_lname) + "')"
			omed.sqlexecute(c_SQL,"")

		
		
			IF l_CopyAttorneys && copy/mirror atty's data
				DO copy_atty WITH c_origclcode,viewIDs.cl_code,viewIDs.id_tblmaster
			
			ENDIF

			SELECT viewIDs
*!*				IF RECCOUNT()>0
*!*					IF EMPTY(c_socsec)
*!*						IF NOT EMPTY(c_dob)
*!*							IF TYPE( "newcase2.dob")="C"
*!*								REPLACE ALL lrs_no WITH viewIDs.lrs_no,cl_code WITH viewIDs.cl_code   ;
*!*									FOR CTOD(dob)=CTOD(c_dob) AND ALLTRIM(pl_last_n) = ALLTRIM(newcase.orig_lname) IN  newcase2
*!*							ELSE
*!*								REPLACE ALL lrs_no WITH viewIDs.lrs_no,cl_code WITH viewIDs.cl_code   ;
*!*									FOR dob=CTOD(c_dob) AND ALLTRIM(pl_last_n) = ALLTRIM(newcase.orig_lname) IN newcase2

*!*							ENDIF
*!*						ENDIF
*!*					ELSE
*!*						IF TYPE("newcase2.soc")="C"
*!*							REPLACE ALL lrs_no WITH viewIDs.lrs_no,cl_code WITH viewIDs.cl_code FOR ALLTRIM(soc)==c_socsec IN newcase2
*!*						ELSE
*!*							REPLACE ALL lrs_no WITH viewIDs.lrs_no,cl_code WITH viewIDs.cl_code FOR soc=VAL(c_socsec) IN  newcase2
*!*						ENDIF
*!*					ENDIF
*!*				ENDIF
			
			
				**add plaintiff's atty
			IF !EMPTY(NVL(newcase.pl_AT_CODE,''))
			c_sql3=" exec [dbo].[insertMRCPlaintiffBill] '" + viewIDs.cl_code + "','" + viewIDs.Id_tblMaster + "','" + Pc_userid + "','" + newcase.pl_AT_CODE + "'"
			omed.sqlexecute(c_SQL3,"")
			ENDIF
			
			
				IF ! l_chk				
				*replace ALL RelatedRt WITH  viewIDs.lrs_no FOR RalatedId= c_babycase  IN newcase
				*C_SQL2="SELECT  LRS_NO FROM  tblMRCCase WHERE  MRCFILE='"+ NEWCASE.MRCfILE + "'"
				C_SQL2="exec  [dbo].[LinktoBabycase] '"+  newcase.mrcfile  + "' "
				pn_errors=omed.sqlexecute(c_SQL2,"")
				
			ENDIF
	
		ENDIF

		ncnt=ncnt+1

		SELECT newcase
		GO (ncurrow)
		ENDSCAN
		*SKIP
	*ENDDO 
**endIF




*!*		SELECT DISTINCT lrs_no,cl_code,descript,c_path, c_mailid FROM newcase2 INTO CURSOR newtag READWRITE ;
*!*			WHERE NOT EMPTY(NVL(lrs_no,0)) ORDER BY lrs_no



*!*	nicnt=1
*!*	nitems=RECCOUNT('newtag')
*!*	IF nitems>0
*!*		SELECT newtag

*!*		SCAN
*!*			WAIT WINDOW "Processing new tags"
*!*			c_path =""
*!*			c_blurb=""
*!*			
*!*			
*!*			IF newtag.lrs_no<>0
*!*				DO mrcwtag WITH lrs_no,descript, c_path, c_mailid, c_blurb
*!*			ENDIF 
*!*			nicnt=nicnt+1
*!*		ENDSCAN
*!*	ENDIF

*!*	*!*	gfmessage("Processing complete")

RETURN

**************************************************************************************
**	Copy_Atty program
**  copy all participating attorney info to a new case
**************************************************************************************
PROCEDURE copy_atty
LPARAMETERS c_oldclcode,c_newclcode,c_newid

**10/01/18 SL #109598
*c_SQL="SELECT * FROM tblBill WITH (index (ix_tblbills_2)) WHERE cl_code='&c_oldclcode.' AND active=1 "
c_SQL="SELECT * FROM tblBill WHERE cl_code='&c_oldclcode.' AND active=1 "
omed.sqlexecute(c_SQL,"tabills")

SELECT tabills

SCAN
	lcSQLLine="exec dbo.InsertBillRecord '"+ALLTRIM(tabills.id_tblBills)+"', "+;
		"'"+ALLTRIM(fixquote(c_newclcode))+"', '"+ALLTRIM(c_newid)+"', '"+DTOC(DATE())+"', "+;
		"'"+Pc_userid+"'"
	pn_errors=omed.sqlexecute(lcSQLLine,"")


	c_SQL="select * from tblShip "+;
		" where cl_code='"+c_oldclcode+"' and at_code='"+fixquote(tabills.At_Code)+;
		"' and active=1 and deleted IS null"
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
			Pc_userid+"',"+;
			"'1','0')"

		omed.sqlexecute(c_SQL,"")


	ENDIF
	SELECT tabills
ENDSCAN
RETURN
****
PROCEDURE DIRECTSQL
PARAMETERS lcSQLLine, lcCursor
LOCAL lnCurArea, loConn, lnConnHandle
lnCurArea=SELECT()
loConn=CreateObject("RTS.Data.SQLConnection", "")
lnConnHandle=SQLSTRINGCONNECT(loConn.ConnectionString)
IF lnConnHandle>0
   SQLEXEC(lnConnHandle,lcSQLLine,lcCursor)
ENDIF 
SQLDISCONNECT(lnConnHandle)
SELECT (lnCurArea)
RETURN lnConnHandle
