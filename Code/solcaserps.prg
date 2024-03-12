*// solcase program

PARAMETERS cjobno,cuser,cuseremail,ltestrun

*// test settings
*!*		cuser="KIRK"
*!*		cuseremail="klamartin@recordtrak.com"
*!*		cjobno="SOL00000034"


LOCAL lr,omed,cdefcap,cpltcap,lc_FaxNum,c_Addr,c_fax,c_temp,c_temp2,c_sql,mv,mgroup,mclass;
	,l_faxsolicit ,cPlaintiff,lc_RAtFax,lcd,lds,lvs,ldv,lp,c_soltype,cjobspecid,n_jobs;
	,n_jobcnt,c_phone,c_time

pl_CADBatch=.F.

lc_RAtFax="484-801-0642"   && "610-992-1416"

omed=CREATEOBJECT("generic.medgeneric")

c_sql="SELECT * from tblsolicitjob WHERE jobno='&cjobno.' and isnull(email,'')='' and isnull(fax_num,'')<>'' and active=1"
lr=omed.sqlexecute(c_sql,'solrpsjob')

n_jobs=RECCOUNT('solrpsjob')
n_jobcnt=0

IF n_jobs>0
	loTherm=CREATEOBJECT("app.appfrmthermometer")
	loTherm.updatedisplay( n_jobcnt, n_jobs, "Sending solcitation jobs to RPS", "Please wait")
	c_sql="select top 1 * FROM tbluserctrl WITH (NOLOCK)  where login='&cuser.' and active=1"
	lr=omed.sqlexecute(c_sql,'userctrl')
	c_fullname=''
	c_phone='610-992-5000'
	IF RECCOUNT('userctrl')>0
		c_fullname=ALLTRIM(userctrl.FULLNAME)
		c_phone=ALLTRIM(userctrl.directdial)
	ENDIF
	SET PROCEDURE TO ta_lib ADDITIVE
	SELECT solrpsjob
	SCAN
		mv=""
		c_sql="SELECT * from tblsolicititem WHERE jobid =" + solrpsjob.nid + " and active=1"
		lr=omed.sqlexecute(c_sql,'solrpsitem')
		IF RECCOUNT('solrpsitem')<1
			SELECT solrpsjob
			LOOP
		ENDIF

		lc_FaxNum=ALLTRIM(NVL(solrpsjob.fax_num,""))

		DO PrintGroup WITH mv, "Solcase"
		DO PrintField WITH mv, "FaxNo", lc_RAtFax
		DO PrintField WITH mv, "RetEmail", cuseremail
		DO PrintField WITH mv, "Atcode", ALLTRIM(solrpsjob.at_code)

		DO PrintGroup WITH mv, "Contact"
		DO PrintField WITH mv, "Name", c_fullname
		DO PrintField WITH mv, "Phone", c_phone


		DO PrintGroup WITH mv, "Atty"
		DO PrintField WITH mv, "Name_inv", ALLTRIM(UPPER(solrpsjob.attyname))
		DO PrintField WITH mv, "Ata1", ALLTRIM(solrpsjob.firmname)
		DO PrintField WITH mv, "Ata2", ALLTRIM(solrpsjob.address1)
		DO PrintField WITH mv, "Ata3", ALLTRIM(solrpsjob.address2)
		DO PrintField WITH mv, "Atacsz",ALLTRIM(solrpsjob.cityzip)

*// table loop  -------------------------------------------

		SELECT solrpsitem
		GO TOP IN solrpsitem
		DO WHILE NOT EOF("solrpsitem")

			STORE "" TO cpltcap
			c_sql="exec dbo.getmasterbyrt " + ALLTRIM(STR(solrpsitem.lrs_no))
			lr=omed.sqlexecute(c_sql,'solmaster')
			IF RECCOUNT('solmaster')>0

				DO PrintGroup WITH mv, "Item"
				DO PrintField WITH mv, "Col1", ""
				DO PrintField WITH mv, "Col2", ALLTRIM(solmaster.plaintiff)
				DO PrintField WITH mv, "Col3", ALLTRIM(STR(solrpsitem.lrs_no))
				DO PrintField WITH mv, "Col4", ""
				DO PrintField WITH mv, "Col5", ALLTRIM(solmaster.plcap)
				DO PrintField WITH mv, "Col6", ""
				DO PrintField WITH mv, "Col7", ALLTRIM(solmaster.court)
				DO PrintField WITH mv, "Col8", ""
				DO PrintField WITH mv, "Col9", ALLTRIM(solmaster.docket)

			ENDIF
			IF USED('solmaster')
				USE IN solmaster
			ENDIF

			SELECT solrpsitem
			SKIP
		ENDDO

		mgroup = "3"
		l_faxsolicit =.F.
		lc_Faxno=ALLTRIM(NVL(solrpsjob.fax_num,"0"))
		DO CASE
		CASE NOT EMPTY(lc_Faxno) AND LEN(ALLTRIM(lc_Faxno))>=10
			*// do not print failed faxes
			*mclass="FaxSolct"
			mclass="FaxSolctNoPrnt"
			pc_EmailAdd=""
			c_Addr=IIF (LEN(ALLTRIM(lc_Faxno))<10,"",lc_Faxno)
			c_fax = STRTRAN( c_Addr, " ", "")
			c_temp = STRTRAN( c_fax, "-", "")
			c_temp2 = STRTRAN( c_temp, "(", "")
			c_Addr = STRTRAN( c_temp2, ")", "")
			l_faxsolicit =.T.
		OTHERWISE
			mclass='FaxSolct'
			pc_EmailAdd=""
			c_Addr=""
		ENDCASE

		pc_clcode=IIF(EMPTY(pc_clcode),solrpsjob.at_code,pc_clcode)
		pc_lrsno=ALLTRIM(STR(solrpsjob.lrs_no))
		pn_lrsno=solrpsjob.lrs_no
		pn_tag=0
		pc_tag="0"
		mclass = IIF(ltestrun,"testjob",mclass)

		c_sql="select getdate() as sysdate"
		lr=omed.sqlexecute(c_sql,"curdate")
		c_time=TTOC(curdate.sysdate)

		IF l_faxsolicit
			IF ltestrun
				c_Addr='6109920808'
			ENDIF
			DO PrtEnQa WITH mv, mclass, "2", c_Addr
			c_soltype='F'
		ELSE
			DO printenq WITH mv, mclass, mgroup
			c_soltype='P'
		ENDIF

*// update solicitation job data
		cjobspecid='999'
		
		**10/01/18 SL #109598
		*" from  RPSWORK..prqJobSpec s with (nolock,INDEX (ix_prqjobspecclcodetag)) " +
		c_sql= "SELECT top 1 s.jobspecid " + ;
			" from  RPSWORK..prqJobSpec s with (nolock) " + ;
			" left outer join RPSWORK..prqJobq q  with (nolock) on s.jobspecid=q.jobspecid " + ;
			" where s.cl_code='&pc_clcode.' and s.tag=0 " + ;
			" and Q.ENQUEUED>=cast('" + c_time + "' as datetime) ORDER BY Q.ENQUEUED DESC"

*!*			c_sql="select top 1 jobspecid from rpswork..prqjobspec with (nolock,INDEX (lrs_no,ix_prqjobspecclcodetag)) where "+;
*!*				" lrs_no=&pc_lrsno. and cl_code='&pc_clcode.' and tag=0 order by jobspecid desc"

		lr=omed.sqlexecute(c_sql,"jobspec")
		
		IF RECCOUNT("jobspec")>0
			cjobspecid=ALLTRIM(STR(jobspec.jobspecid))
		ENDIF

		c_sql="UPDATE tblsolicitjob SET soltype='&c_soltype.',rps_jobid=&cjobspecid.,dtdone=getdate()  WHERE nid="+solrpsjob.nid
		lr=omed.sqlexecute(c_sql)

		IF USED('solrpsitem')
			USE IN solrpsitem
		ENDIF
		SELECT solrpsjob
		n_jobcnt=n_jobcnt+1
		loTherm.updatedisplay(n_jobcnt, n_jobs, ;
			"Sending solcitation jobs to RPS", "Processed "+;
			ALLTRIM(STR(n_jobcnt))+" primary TAG(s) of "+ALLTRIM(STR(n_jobs)))
	ENDSCAN   && soljobs (documents)
ENDIF

RELEASE loTherm

IF USED('solrpsjob')
	USE IN solrpsjob
ENDIF

RELEASE omed

RETURN
