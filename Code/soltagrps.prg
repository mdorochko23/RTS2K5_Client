*// soltagrps program
* 09/18/2014 - MD added pc_litcode setting
* 12/16/15 - KDL name case change
PARAMETERS cjobno,cuser,cuseremail,ltestrun,dtcreated

*!*	IF PCOUNT()<5
*!*		dtcreated=DATE()
*!*	ENDIF

*--test settings
*!*	cjobno="SOL00000091"
*!*	snid= "156441"
*!*	*"127818"
*!*	*"156441"
*!*	*"156254"
*!*	*"160310"
*!*	cuser="NICOLE_R"
*!*	cuseremail="clientorders@recordtrak.com"
*!*	ltestrun=.T.
*!*	 dtcreated = date()
*!*	pc_offcode  = 'P'
*!*	 set classlib to C:\rts2k5\CLIENT\Class\generic additive
*!*	pc_BatchRq=""
*!*	pl_Noticng = .f.
*!*	pl_StopPrtIss = .f.
*!*	pl_TestRPS = .t.
*!*	pl_1st_Req = .f.
*!*	pl_UpdHoldReqst = .f.
*!*	pl_PdfReprint =.f.
*!*	pl_EditReq = .f.
*!*	set classlib to C:\rts2k5\CLIENT\Class\dataconnection additive
*!*	set classlib to C:\rts2k5\CLIENT\Class\app additive
*!*	set step on
*--end test setttings

LOCAL lr,omed,cdefcap,cpltcap,lc_FaxNum,c_Addr,c_fax,c_temp,c_temp2,c_sql,mv,mgroup,mclass;
	,l_faxsolicit ,cPlaintiff,lc_RAtFax,lcd,lds,lvs,ldv,lp,c_soltype,cjobspecid,n_jobs;
	,n_jobcnt,c_time,l_hidefindate,c_phone,l_noprice,l_ShowStatus, cStatus, objconn

pl_CADBatch=.F.

lc_RAtFax="484-801-0642"   && "610-354-8946"
l_hidefindate=.F.

*omed=CREATEOBJECT("generic.medgeneric")
objconn=CREATEOBJECT("dataconnection.cntdataconn")

IF ALLTRIM(cjobno)=="0"
	c_sql="SELECT * from tblsolicitjob WHERE isnull(email,'')='' and isnull(fax_num,'')<>'' and emailreturn='&cuseremail.' and " + ;
		"created between '" + DTOC(dtcreated) +"' and '" + DTOC(dtcreated + 1) +"' and dtdone is null and active=1"
ELSE
	IF ltestrun = .F.
		c_sql="SELECT * from tblsolicitjob WHERE jobno='&cjobno.' and isnull(email,'')='' and isnull(fax_num,'')<>'' and dtdone is null and active=1"
	ELSE
		c_sql="SELECT * from tblsolicitjob WHERE nid =" + snid &&jobno='&cjobno.' and isnull(email,'')='' and isnull(fax_num,'')<>'' and active=0"
	ENDIF
ENDIF

lr=objconn.sqlpassthrough(c_sql,'solrpsjob')
*lr=omed.sqlexecute(c_sql,'solrpsjob')

n_jobs=RECCOUNT('solrpsjob')
n_jobcnt=0

IF n_jobs>0

*--test set
loTherm=CREATEOBJECT("app.appfrmthermometer")
loTherm.updatedisplay( n_jobcnt, n_jobs, "Sending solcitation jobs to RPS", "Please wait")

	c_sql="select top 1 * FROM tbluserctrl WITH (NOLOCK)  where login='&cuser.' and active=1"
	lr=objconn.sqlpassthrough(c_sql,'userctrl')
	c_fullname=''
	c_phone='610-992-5000'
	IF RECCOUNT('userctrl')>0
		c_fullname=ALLTRIM(userctrl.FULLNAME)
		c_phone=IIF(EMPTY(NVL(ALLTRIM(userctrl.directdial),'')),c_phone,ALLTRIM(userctrl.directdial))
	ENDIF
	SET PROCEDURE TO ta_lib ADDITIVE
	SELECT solrpsjob
	SCAN
		mv=""
		l_hidefindate=NVL(solrpsjob.bhidefindate,.F.)
		l_noprice=NVL(solrpsjob.bnoprice,.F.)
		l_ShowStatus = NVL(solrpsjob.bshowstatus,.F.)
		c_sql="SELECT * from tblsolicititem WHERE jobid =" + solrpsjob.nid + " and active=1"
		lr=objconn.sqlpassthrough(c_sql,'solrpsitem')
		IF RECCOUNT('solrpsitem')<1
			SELECT solrpsjob
			LOOP
		ENDIF

		SELECT DISTINCT shiptype AS shiptype INTO CURSOR curstype FROM solrpsitem
		STORE .F. TO lcd,lds,lvs,ldv,lp
		SELECT curstype
		SCAN
			IF lcd=.F. AND 	"CD"$curstype.shiptype
				lcd=.T.
			ENDIF
			IF lds=.F. AND 	"DS"$curstype.shiptype
				lds=.T.
			ENDIF
			IF lvs=.F. AND 	"VS"$curstype.shiptype
				lvs=.T.
			ENDIF
			IF ldv=.F. AND 	"DV"$curstype.shiptype
				ldv=.T.
			ENDIF
			IF lp=.F. AND 	"P"$curstype.shiptype
				lp=.T.
			ENDIF
			IF lcd AND lds AND lvs AND ldv AND lp
				EXIT
			ENDIF
		ENDSCAN
		c_recformat="electronically through our website"
		DO CASE
		CASE (lds OR lvs OR ldv) AND lp=.F. AND lcd=.F.
			c_recformat="electronically through our website"
		CASE (lds OR lvs OR ldv) AND lp=.T. AND lcd=.F.
			c_recformat="in paper format and/or electronically through our website"
		CASE (NOT (lds OR lvs OR ldv)) AND lp=.T. AND lcd=.F.
			c_recformat="in paper format"
		CASE (lds OR lvs OR ldv) AND lp=.F. AND lcd=.T.
			c_recformat="on CD and/or electronically through our website"
		CASE (lds OR lvs OR ldv) AND lp=.T. AND lcd=.T.
			c_recformat="in paper format, on CD and/or electronically through our website"
		CASE (NOT (lds OR lvs OR ldv)) AND lp=.T. AND lcd=.T.
			c_recformat="in paper format and/or on CD"
		CASE (NOT (lds OR lvs OR ldv)) AND lp=.F. AND lcd=.T.
			c_recformat="electronically through our website"
*c_recformat="on CD"
		ENDCASE

		lc_FaxNum=ALLTRIM(NVL(solrpsjob.fax_num,""))

		STORE "" TO cdefcap,cpltcap
		c_sql="exec dbo.getmasterbyrt " + ALLTRIM(STR(solrpsjob.lrs_no))
		lr=objconn.sqlpassthrough(c_sql,'solmaster')
		STORE '' TO pc_clcode,cdefcap,cpltcap
		IF RECCOUNT('solmaster')>0
			pc_clcode=solmaster.cl_code
			cdefcap=ALLTRIM(solmaster.defcap)
			cpltcap=ALLTRIM(solmaster.plcap)
			PC_LITCODE=ALLTRIM(UPPER(NVL(solmaster.litigation,'')))
		ENDIF

		IF l_ShowStatus = .F.
			DO CASE
			CASE l_hidefindate AND l_noprice
				c_rpsdoc="Soltags2wop"
			CASE l_hidefindate AND NOT l_noprice
				c_rpsdoc="Soltags2"
			CASE NOT l_hidefindate AND l_noprice
				c_rpsdoc="Soltagswop"
			CASE NOT l_hidefindate AND NOT l_noprice
				c_rpsdoc="Soltags"
			ENDCASE
		ELSE
			DO CASE
			CASE l_hidefindate AND l_noprice
				c_rpsdoc="Soltags2wopst"
			CASE l_hidefindate AND NOT l_noprice
				c_rpsdoc="Soltags2st"
			CASE NOT l_hidefindate AND l_noprice
				c_rpsdoc="Soltagswopst"
			CASE NOT l_hidefindate AND NOT l_noprice
				c_rpsdoc="Soltagsst"
			ENDCASE

		ENDIF

		DO PrintGroup WITH mv, c_rpsdoc
*DO PrintGroup WITH mv, IIF(l_hidefindate,"Soltags2","Soltags")
		DO PrintField WITH mv, "Billplan",ALLTRIM(solrpsjob.at_code)+":"+ALLTRIM(solrpsjob.planname)+;
			":"+ALLTRIM(solrpsjob.billcat)
		DO PrintField WITH mv, "FaxNo", lc_RAtFax
		DO PrintField WITH mv, "Recform", c_recformat
		*--test set
		DO PrintField WITH mv, "Name", plName2PC(ALLTRIM(solrpsjob.plaintiff))
		DO PrintField WITH mv, "RetEmail", cuseremail
		DO PrintField WITH mv, "LrsNo", ALLTRIM(STR(solrpsjob.lrs_no))

		DO PrintGroup WITH mv, "Case"
		IF NOT EMPTY(cpltcap) AND NOT EMPTY(cdefcap)
*--1/14/2016 -- new defendant caption format
			*cPlaintiff=ALLTRIM(cpltcap) + " vs " + ALLTRIM(cdefcap)
			DO PrintField WITH mv, "Plaintiff", ALLTRIM(cpltcap)
			DO PrintField WITH mv, "Defendant", ALLTRIM(cdefcap)
*//DO PrintField WITH mv, "Plaintiff", mrpltcap
*//DO PrintField WITH mv, "Defendant", mrdefcap
		ENDIF
		DO PrintField WITH mv, "Docket", solrpsjob.docket

		DO PrintGroup WITH mv, "Contact"
		DO PrintField WITH mv, "Name", c_fullname
		DO PrintField WITH mv, "Phone", c_phone

		DO PrintGroup WITH mv, "Atty"
		DO PrintField WITH mv, "Name_inv", atName2PC(ALLTRIM(UPPER(solrpsjob.attyname)))
		DO PrintField WITH mv, "Ata1", PROPER(ALLTRIM(solrpsjob.firmname))
		DO PrintField WITH mv, "Ata2", PROPER(ALLTRIM(solrpsjob.address1))
		DO PrintField WITH mv, "Ata3", PROPER(ALLTRIM(solrpsjob.address2))
		DO PrintField WITH mv, "Atacsz",CityZip2PC(ALLTRIM(solrpsjob.cityzip))

*// table loop  -------------------------------------------

		SELECT solrpsitem
		GO TOP IN solrpsitem

		DO CASE
		CASE c_rpsdoc=="Soltags2" OR c_rpsdoc=="Soltags2st"
			DO WHILE NOT EOF("solrpsitem")
				DO PrintGroup WITH mv, "Item"
				DO PrintField WITH mv, "Col1", ""
				DO PrintField WITH mv, "Col2", ALLTRIM(STR(solrpsjob.lrs_no))+"."+ALLTRIM(STR(solrpsitem.TAG))
				DO PrintField WITH mv, "Col3", ALLTRIM(solrpsitem.DESCRIPT)
				DO PrintField WITH mv, "Col4", ""
				DO PrintField WITH mv, "Col5", ALLTRIM(STR(solrpsitem.PAGES))
				DO PrintField WITH mv, "Col6", ""
				DO PrintField WITH mv, "Col7", ALLTRIM(STR(solrpsitem.price,8,2))

				IF c_rpsdoc=="Soltags2st"
					cStatus = IIF(UPPER(ALLTRIM(NVL(solrpsitem.STATUS,"R")))=="N","No Records Received", "Records Received")
					DO PrintField WITH mv, "Col8", ""
					DO PrintField WITH mv, "Col9", cStatus
				ENDIF

				SELECT solrpsitem
				SKIP
			ENDDO
		CASE c_rpsdoc=="Soltags2wop" OR c_rpsdoc=="Soltags2wopst"
			DO WHILE NOT EOF("solrpsitem")
				DO PrintGroup WITH mv, "Item"
				DO PrintField WITH mv, "Col1", ""
				DO PrintField WITH mv, "Col2", ALLTRIM(STR(solrpsjob.lrs_no))+"."+ALLTRIM(STR(solrpsitem.TAG))
				DO PrintField WITH mv, "Col3", ALLTRIM(solrpsitem.DESCRIPT)
				DO PrintField WITH mv, "Col4", ""
				DO PrintField WITH mv, "Col5", ALLTRIM(STR(solrpsitem.PAGES))

				IF c_rpsdoc=="Soltags2wopst"
					cStatus = IIF(UPPER(ALLTRIM(NVL(solrpsitem.STATUS,"R")))=="N","No Records Received", "Records Received")
					DO PrintField WITH mv, "Col6", ""
					DO PrintField WITH mv, "Col7", cStatus
				ENDIF

				SELECT solrpsitem
				SKIP
			ENDDO
		CASE c_rpsdoc=="Soltags" OR c_rpsdoc=="Soltagsst"
			DO WHILE NOT EOF("solrpsitem")
				DO PrintGroup WITH mv, "Item"
				DO PrintField WITH mv, "Col1", ""
				DO PrintField WITH mv, "Col2", ALLTRIM(STR(solrpsjob.lrs_no))+"."+ALLTRIM(STR(solrpsitem.TAG))
				DO PrintField WITH mv, "Col3", ALLTRIM(solrpsitem.DESCRIPT)
				DO PrintField WITH mv, "Col4", ""
				DO PrintField WITH mv, "Col5", ALLTRIM(STR(solrpsitem.PAGES))
				DO PrintField WITH mv, "Col6", ""
				DO PrintField WITH mv, "Col7", DTOC(solrpsitem.fin_date)
				DO PrintField WITH mv, "Col8", ""
				DO PrintField WITH mv, "Col9", ALLTRIM(STR(solrpsitem.price,8,2))

				IF c_rpsdoc=="Soltagsst"
					cStatus = IIF(UPPER(ALLTRIM(NVL(solrpsitem.STATUS,"R")))=="N","No Records Received", "Records Received")
					DO PrintField WITH mv, "Col10", ""
					DO PrintField WITH mv, "Col11",  cStatus
				ENDIF

				SELECT solrpsitem
				SKIP
			ENDDO
		CASE c_rpsdoc=="Soltagswop" OR c_rpsdoc=="Soltagswopst"
			DO WHILE NOT EOF("solrpsitem")
				DO PrintGroup WITH mv, "Item"
				DO PrintField WITH mv, "Col1", ""
				DO PrintField WITH mv, "Col2", ALLTRIM(STR(solrpsjob.lrs_no))+"."+ALLTRIM(STR(solrpsitem.TAG))
				DO PrintField WITH mv, "Col3", ALLTRIM(solrpsitem.DESCRIPT)
				DO PrintField WITH mv, "Col4", ""
				DO PrintField WITH mv, "Col5", ALLTRIM(STR(solrpsitem.PAGES))
				DO PrintField WITH mv, "Col6", ""
				DO PrintField WITH mv, "Col7", DTOC(solrpsitem.fin_date)

				IF c_rpsdoc=="Soltagswopst"
					cStatus = IIF(UPPER(ALLTRIM(NVL(solrpsitem.STATUS,"R")))=="N","No Records Received", "Records Received")
					DO PrintField WITH mv, "Col8", ""
					DO PrintField WITH mv, "Col9",  cStatus
				ENDIF

				SELECT solrpsitem
				SKIP
			ENDDO
		ENDCASE

		mgroup = "3"

		l_faxsolicit =.F.
		lc_Faxno=ALLTRIM(NVL(solrpsjob.fax_num,"0"))
		DO CASE
		CASE NOT EMPTY(lc_Faxno) AND LEN(ALLTRIM(lc_Faxno))>=10
*// 6/21/11 do not print failed faxes
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
		mclass = IIF(ltestrun,"KOPTEST",mclass)
		c_sql="select getdate() as sysdate"
		lr=objconn.sqlpassthrough(c_sql,"curdate")
		c_time=TTOC(CURDATE.sysdate)

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

*!*				c_sql="select top 1 jobspecid from rpswork..prqjobspec with (nolock,INDEX (lrs_no,ix_prqjobspecclcodetag)) where "+;
*!*					" lrs_no=&pc_lrsno. and cl_code='&pc_clcode.' and tag=0 order by jobspecid desc"

		lr=objconn.sqlpassthrough(c_sql,"jobspec")

		IF RECCOUNT("jobspec")>0
			cjobspecid=ALLTRIM(STR(jobspec.jobspecid))
		ENDIF

		c_sql="UPDATE tblsolicitjob SET soltype='&c_soltype.',rps_jobid=&cjobspecid.,dtdone=getdate() WHERE nid="+solrpsjob.nid
		lr=objconn.sqlpassthrough(c_sql)

		IF USED('solrpsitem')
			USE IN solrpsitem
		ENDIF
		SELECT solrpsjob
		n_jobcnt=n_jobcnt+1

*--test set
		loTherm.updatedisplay(n_jobcnt, n_jobs, ;
			"Sending solcitation jobs to RPS", "Processed "+;
			ALLTRIM(STR(n_jobcnt))+" primary TAG(s) of "+ALLTRIM(STR(n_jobs)))

	ENDSCAN   && soljobs (documents)
ENDIF

RELEASE loTherm

IF USED('solrpsjob')
	USE IN solrpsjob
ENDIF

RELEASE objconn &&omed

RETURN

*-------------------------------------------
*--handles last name last format
FUNCTION atName2PC
PARAMETERS sText
LOCAL sReturn, sText2
sText = ALLTRIM(sText)
sReturn = ""
nRows = ALINES(laData, STRTRAN(sText," ",CHR(13)))
DO CASE
CASE LEN(sText) <=2
	sReturn=PROPER(sText)
CASE UPPER(LEFT(laData(ALEN(laData,1)),2))=="MC"
	sText2 =ALLT(laData(ALEN(laData,1)))
	sText2 = RIGHT(sText2, (LEN(sText2) - 2))
	sText2 = "Mc" + PROPER(ALLTRIM(sText2))
	FOR icnt = 1 TO (ALEN(laData,1) - 1)
		sReturn = sReturn + IIF(not EMPTY(sreturn), " " , "") +	PROPER(ALLTRIM(laData(icnt)))
	NEXT
	sReturn = ALLTRIM(sReturn + IIF(not EMPTY(sreturn), " " , "") + sText2)
CASE AT("'",sText) > 0
	sReturn = STRTRAN(sText,"'", " XXXXX ")
	sReturn = PROPER(sReturn)
	sReturn = STRTRAN(sReturn, " Xxxxx ", "'")
OTHERWISE
	sReturn = PROPER(sText)
ENDCASE
RETURN sReturn

*-------------------------------------------
*--handles last name first format
FUNCTION plName2PC
PARAMETERS sText
LOCAL sReturn, sText2
sText = ALLTRIM(sText)
sReturn = ""
nRows = ALINES(laData, STRTRAN(sText,";",CHR(13)))
DO CASE
CASE LEN(sText) <=2
	sReturn=PROPER(sText)
CASE UPPER(LEFT(laData(1),2))=="MC"
	sText2 =ALLTRIM(laData(1))
	sText2 = RIGHT(sText2, (LEN(sText2) - 2))
	sText2 = "Mc" + PROPER(ALLTRIM(sText2))
	FOR icnt = 2 TO (ALEN(laData,1))
		sReturn = sReturn + IIF(not EMPTY(sreturn), " " , "") +	PROPER(ALLTRIM(laData(icnt)))
	NEXT
	sReturn = alltrim(sText2 + IIF(not EMPTY(sreturn), " ;" , "") + sReturn )
CASE AT("'",sText) > 0
	sText2 = STRTRAN(ALLTRIM(laData(1)),"'", " XXXXX ")
	sText2 = PROPER(sText2)
	sText2 = STRTRAN(sText2, " Xxxxx ", "'")
	sReturn = sText2 + " ;" + PROPER(ALLTRIM(laData(2)))
OTHERWISE
	sReturn = PROPER(ALLTRIM(laData(1))) + " ;" + PROPER(ALLTRIM(laData(2)))

ENDCASE
RETURN sReturn

*-------------------------------------------
FUNCTION CityZip2PC
PARAMETERS sText
LOCAL sReturn
sText = ALLTRIM(sText)
nRows = ALINES(laData, STRTRAN(sText,",",CHR(13)))
IF nRows = 2
	sReturn=PROPER(ALLTRIM(laData(1))) + ", " + ALLTRIM(laData(2))
ELSE
	sReturn=PROPER(ALLTRIM(sText))
ENDIF
RETURN sReturn




