**************************************************************************************
* PROGRAM: GFDSPOST
* Programmer: kdl
* Date: 4/19/04
* Abstract: Post a DS job to gfdisjob and to the distbill table
* Called by: printcov.prg, orders.prg, incoming.prg
* Calls: gfuse.prg, gfunuse.prg, gfdisjob.prg
* Modifications:
* 01/31/2006 - MD modified for VFP
**************************************************************************************
PARAMETERS c_Clcode, n_Tag, c_Atcode, c_type, c_Jobemail, l_email, d_Order, n_Idno, d_billdate, n_jpriorty
n_Params = PARAMETERS()
PRIVATE n_Curarea, c_Userid, l_lit, c_ImageDb, l_sendmail, l_distbill, ;
	l_tamaster c_Jobtype, n_lrsno, c_Db, l_addedjob, n_cnt, l_record, c_ordrec, ;
	d_actdate, l_order, l_hold, d_today

d_today = DATE()
STORE "" TO c_Db
l_addedjob = .F. 				&& flag to track if new job added to disttodo
IF INLIST(TYPE('c_Jobemail'), "U", "L")
	c_Jobemail = ""
ENDIF
IF n_Params < 6
	l_email = .T.
ENDIF
IF n_Params < 7
	d_Order = d_nul
ENDIF
IF n_Params < 8
	n_Idno = 0
ENDIF
IF n_Params < 9
	d_billdate = {}
ENDIF
IF TYPE("n_jpriorty") <> "N"
	*set default priority to 6 for non rush case,
	*4 for  rush cases
	n_jpriorty = IIF( pl_rushcas, 4, 6)
ENDIF

n_Curarea = SELECT()

IF TYPE("oGen")!="O"
   oGen=CREATEOBJECT("medgeneric")
ENDIF

c_Jobtype = gfdstype(c_Type)    

*--post job to distribution server
c_Userid  = goApp.currentUser.NtLogin
pc_UserId = "DS_RECEIVED"

oGen.sqlexecute("select * from tblMaster WITH (nolock) where cl_code='"+ALLTRIM(c_clcode)+"' and active=1", "viewMaster")
SELECT viewMaster
IF RECCOUNT()>0
	n_Lrsno = viewmaster.lrs_no
	c_litcode = viewmaster.litigation
ELSE
	RETURN
ENDIF
USE 

oGen.sqlexecute("select * from tblLit WITH (nolock) where code='"+ALLTRIM(fixquote(c_litcode))+"' and active=1", "viewLit")
SELECT viewLit
IF RECCOUNT()>0
   c_Db = ALLTRIM(viewlit.imagedb)
ENDIF
USE 

c_ImageDb = "WEJ1"
c_ImageDb2 = "RTS4"
setImageDbs(@c_ImageDb, @c_ImageDb2)

l_sendmail = IIF( INLIST( c_Jobtype,"DS", "DV") AND l_email, .T., .F.)

IF NOT l_sendmail
	c_Jobemail = ""
ENDIF

d_actdate=setActDate(@d_ActDate)

l_hold=setHold()

n_dsid=gfdsjobid()

lcSQLLine="exec dbo.dsjob '"+ALLTRIM(STR(n_lrsno))+"', '"+ALLTRIM(STR(n_tag))+"', '"+;
ALLTRIM(fixquote(c_AtCode))+"', '"+ALLTRIM(c_JobType)+"', '"+IIF(l_SendMail=.T.,"1","0")+"', '"+;
ALLTRIM(c_imageDb)+"', '1', '"+ALLTRIM(STR(n_IdNo))+"', '"+ALLTRIM(c_JobEMail)+"', '"+;
ALLTRIM(c_imageDb2)+"', '"+DTOC(d_actdate)+"', '"+IIF(l_hold=.T.,"1","0")+"', '"+;
ALLTRIM(STR(n_jpriority))+"','&n_dsid.'"

oGen.sqlexecute(lcSQLLine)

pc_UserId = (c_Userid)

DO updatedistbill

*--send email notification
IF c_Jobtype = "CD" AND l_addedjob = .T. AND NOT EMPTY(d_actdate)
*--IF c_Jobtype = "CD" AND l_addedjob = .T.
	DO lpEmail
ENDIF

RELEASE ogen

SELECT (n_Curarea)

***************************************************************************
PROCEDURE lpEmail
*--check if users copy of email.exe needs to be updated
PRIVATE n_Email, d_Email, c_String, c_Message, c_Sendto, c_CopyTo, ;
   c_Subject, l_Sent, n_cnt, lcMail
lcMail=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","EMAIL", "\")))+"email.exe"
n_Email = ADIR(a_Email, lcMail)
IF n_Email > 0 AND FILE("c:\email.exe")
   d_Email = a_Email[1, 3]
   n_Email = ADIR(a_Email, "c:\email.exe")
   IF n_Email > 0
      IF d_Email > a_Email[1, 3]
         COPY FILE &lcMail TO c:\email.exe
      ENDIF
   ENDIF
ELSE
   COPY FILE l&cMail TO c:\email.exe
ENDIF

*--now prepare the email data and call the VFP email app
c_SendTo    = "cdorders@recordtrak.com"
*--suppress email copies per Megan's request
c_CopyTo    = 	"NONE"	
c_FromName  = "Regular Orders System"
c_FromEmail = "Regular_Orders@RecordTrak.com"
c_Subject   = "Notification of CD Copy Job(s)"
c_Message1  = "New CD orders have been placed for the following:" ;

c_File = "c:\" + SYS(3) +".txt"
n_File = FCREATE(c_File)
IF n_File > 0
   = FPUT(n_File, pc_UserId)
   = FPUT(n_File, c_SendTo)
   = FPUT(n_File, c_CopyTo)
   = FPUT(n_File, c_FromName)
   = FPUT(n_File, c_FromEmail)
   = FPUT(n_File, c_Subject)
   = FPUT(n_File, c_Message1)
   *--list of new cd jobs
   c_message2 = " Attorney " + ALLTRIM(c_atcode) + " - " + ;
      ALLTRIM(STR(n_Lrsno)) + "." + PADL(ALLTRIM(STR(n_Tag)), 3, "0") + ;
         "," + "1" + " Copy(ies)"
   = FPUT(n_File, c_Message2)
   = FCLOSE(n_File)
ENDIF

*--call the VFP email generator
c_String = '"' + c_File + '"'
*--6/30/04 kdl start: add configuation file to prg call
lsOrgErrHandler=ON("ERROR")
RUN c:\email.exe -ct:txttiff\config.fpw &c_file
ON ERROR &lsOrgErrHandler
RETURN 
***************************************************************************
*-- FUNCTION LF_ACTDTE
*-- Abstract: compute the hold date for a job
***************************************************************************
FUNCTION lf_Actdte
PARAMETERS lc_Clcode, ln_tag
LOCAL n_curarea, d_holddt, d_start, l_record, l_recspec, lcSQLLine
IF TYPE("oGen")!="O"
   oGen=CREATEOBJECT("medgeneric")
ENDIF
n_curarea = SELECT()
IF dshold.active
	*--get the start date
	c_start = ALLTRIM(dshold.hold_start)
	lcSQLLine="select * from tblRequest WITH (nolock) where cl_code='"+;
	ALLTRIM(lc_clCode)+"' and tag='"+ALLTRIM(STR(ln_tag))+"'"
	oGen.sqlexecute(lcSQLLine, "viewRequest")
	SELECT viewRequest
	IF RECCOUNT()>0		
		IF dshold.orig_date AND viewRequest.reissue
			d_start=lporgiss(c_start, ln_tag)			
		ELSE
			d_start = IIF( NOT EMPTY( &c_start), &c_start, d_today)
		ENDIF
	ELSE
		d_start = DATE()
	ENDIF
	SELECT viewRequest
	USE 
	*--compute the active date
	IF dshold.day_Type = "B"
		 d_holddt = gfdtskip( d_start, dshold.hold_Days)
	ELSE
		 d_holddt = d_start + dshold.hold_Days
	ENDIF
ELSE
	d_holddt = {}
ENDIF

d_holddt = IIF( d_holddt > d_today, d_holddt, {})

SELECT (n_curarea)
RETURN (d_holddt)

***************************************************************************
*-- FUNCTION LPORGISS
*-- Abstract: locate the original issue tag associated with a reissued tag
*-- 	using a recursive procedure
***************************************************************************
PROCEDURE lporgiss
LPARAMETERS lnTag, lcField
LOCAL n_tag, lcSQLLine, lnCurArea, d_start
lnCurArea=SELECT()
IF TYPE("oGen")!="O"
   oGen=CREATEOBJECT("medgeneric")
ENDIF
lcSQLLine="select * from tblRequest WITH (nolock) where cl_code='"+;
ALLTRIM(lc_clCode)+"' and tag='"+ALLTRIM(STR(lnTag))+"'"
oGen.sqlexecute(lcSQLLine, "viewReq")
SELECT viewReq
IF RECCOUNT()>0 
   IF viewReq.reissue=.T.
   	  SELECT viewReq
      lnRTag=viewReq.reIss_tag
      use		
      DO lporgiss WITH lnRTag, lcField		
   ELSE      
	 d_start = IIF( NOT EMPTY( &lcField), &lcField, d_today)
   ENDIF 
ELSE
   d_start=DATE()   	
ENDIF
IF USED("viewReq")
   USE
ENDIF 
SELECT (lnCurArea)
RETURN d_Start
***************************************************************************
*-- Procedure: lpnotify
*-- Abstract: send email notification if no email address found for attorney
***************************************************************************
PROCEDURE lpNotify
PARAMETER ln_lrsno, ln_Tag, lc_atcode, lc_userid
*--check if users copy of email.exe needs to be updated
PRIVATE n_Email, d_Email, c_String, c_Message, c_Sendto, c_CopyTo, ;
   c_Subject, l_Sent, n_cnt,c_emailadr,l_userctrl, lcMail
lcMail=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","EMAIL", "\")))+"email.exe"   
n_Email = ADIR(a_Email,lcMail)
IF n_Email > 0 AND FILE("c:\email.exe")
   d_Email = a_Email[1, 3]
   n_Email = ADIR(a_Email, "c:\email.exe")
   IF n_Email > 0
      IF d_Email > a_Email[1, 3]
         COPY FILE &lcMail TO c:\email.exe
      ENDIF
   ENDIF
ELSE
   COPY FILE &lcMail TO c:\email.exe
ENDIF
*--now prepare the email data and call the VFP email app
*--get email addresss
IF !EMPTY(ALLTRIM(NVL(goApp.CurrentUser.oRec.EmailAddrs,"")))
   c_emailadr=ALLTRIM(goApp.CurrentUser.oRec.EmailAddrs)
ELSE
	IF SEEK('MEGAN','userctrl')
		c_emailadr=ALLTRIM(userctrl.emailaddrs)
	ELSE
		c_emailadr="programmers@recordtrak.com"
	ENDIF
ENDIF


c_emailadr="programmers@recordtrak.com"

c_SendTo    = c_emailadr
c_CopyTo    = 	"NONE"
c_FromName  = "DS Job Request Error Notification"
c_FromEmail = "Distribution_Server@RecordTrak.com"
c_Subject   = "DS Job Request Error Notification"
c_Message1  = "A distribution Server job was not posted for tag " + ALLTRIM(STR(ln_Lrsno)) + "." + PADL(ALLTRIM(STR(ln_Tag)), 3, "0") + ;
	" - Attorney code: " + lc_atcode
c_Message2  = "Scanned images for the subject record are not available to the Distibution Server. You must print this record to obtain a copy of it."
c_File = "c:\" + SYS(3) +".txt"
n_File = FCREATE(c_File)
IF n_File > 0
   = FPUT(n_File, " Distribution Server")
   = FPUT(n_File, c_SendTo)
   = FPUT(n_File, c_CopyTo)
   = FPUT(n_File, c_FromName)
   = FPUT(n_File, c_FromEmail)
   = FPUT(n_File, c_Subject)
   = FPUT(n_File, c_Message1)
   = FPUT(n_File, c_Message2)
   = FCLOSE(n_File)
ENDIF
*--call the VFP email generator
c_String = '"' + c_File + '"'
lsOrgErrHandler=ON("ERROR")
RUN c:\email.exe -ct:txttiff\config.fpw &c_file
ON ERROR &lsOrgErrHandler
c_email=c_sendto
***************************************************************************
PROCEDURE setImageDbs
LPARAMETERS c_ImageDb, c_ImageDb2, lloGen
LOCAL lnCurArea
lnCurArea=SELECT()
IF TYPE("oGen")!="O"
   oGen=CREATEOBJECT("medgeneric")
   lloGen=.T.
ENDIF
oGen.sqlexecute("select * from tblRequest WITH (nolock) where cl_code='"+ALLTRIM(c_clcode)+;
" and tag='"+ALLTRIM(STR(n_tag))+"' and LEN(RTRIM(LTRIM(fin_date)))>0 and active=1", "viewRequest")
SELECT viewRequest
IF RECCOUNT()>0
	IF viewRequest.fin_date < {05/18/1998}
		DO lpnotify WITH n_Lrsno, n_tag, c_Atcode, c_Userid
		RETURN
	ENDIF
	IF EMPTY(viewRequest.scan_table)
		DO CASE
			CASE c_Db = "LRS"
				DO CASE
					CASE BETWEEN(viewRequest.fin_date, {05/18/1998}, {12/15/2001})
						c_ImageDb = "RTS1"
						c_ImageDb2 = "RTS2"
					CASE BETWEEN(viewRequest.fin_date, {12/15/2001}, {03/29/2002})
						c_ImageDb = "RTS2"
						c_ImageDb2 = "RTS3"
					CASE BETWEEN(viewRequest.fin_date, {04/01/2002}, {05/30/2003})
						c_ImageDb = "RTS3"
						c_ImageDb2 = "RTS4"
					CASE BETWEEN(viewRequest.fin_date, {05/31/2003}, {11/14/2004})
						c_ImageDb = "RTS4"
						c_ImageDb2 = "WEJ1"
					OTHERWISE
						*--use default values
				ENDCASE
		   CASE c_Db = "STAT"
				c_ImageDb = IIF(viewRequest.fin_date < {11/14/2004}, "STAT", "WEJ1")
			CASE c_Db = "DIET"
				c_ImageDb = IIF(viewRequest.fin_date < {11/14/2004}, "PHEN", "WEJ1")
		ENDCASE
	ELSE
		c_ImageDb = viewRequest.scan_table
	ENDIF
ENDIF
SELECT viewRequest
USE 
IF lloGen=.T.
   RELEASE oGen
ENDIF 
SELECT (lnCurArea)
RETURN
****************************************************************
PROCEDURE setActDate
LOCAL lcSQLLine, lnCurArea, d_actdate, lloGen
d_actdate={}
lnCurArea=SELECT()
IF TYPE("oGen")!="O"
   oGen=CREATEOBJECT("medgeneric")
   lloGen=.T.
ENDIF
lcSQLLine="select * from tblDsHold WITH (nolock) where at_code='"+;
ALLTRIM(fixquote(c_atCode))+"' or litigation='"+ALLTRIM(fixquote(pc_litcode))+"' or area='"+ALLTRIM(pc_area)+"'"
oGen.sqlexecute(lcSQLLine,"cDsHold")

lcSQLLine="select * from tblDsHold WITH (nolock)"
oGen.sqlexecute(lcSQLLine,"DsHold")

SELECT cDsHold
IF RECCOUNT()>0
   SCAN
		*--values have to be entered in at least one of the columns
		DO CASE
			CASE EMPTY(dshold.at_code)
				DO CASE
					CASE EMPTY(dshold.litigation)
						*--check for area match
						IF pc_area = dshold.area
							d_actdate = lf_Actdte( c_Clcode, n_tag)
						ENDIF
					CASE EMPTY(dshold.area)
						*--check for litigation match
						IF pc_litcode = dshold.litigation
							d_actdate = lf_Actdte( c_Clcode, n_tag)
						ENDIF
					OTHERWISE
						*--check for litigation and area match
						IF pc_area = dshold.area AND pc_litcode = dshold.litigation
							d_actdate = lf_Actdte( c_Clcode, n_tag)
						ENDIF
				ENDCASE
			CASE EMPTY(dshold.litigation)
				DO CASE
					CASE EMPTY(dshold.area)
						*--check for at_code match
						IF c_atcode = dshold.at_code
							d_actdate = lf_Actdte( c_Clcode, n_tag)
						ENDIF
					OTHERWISE
						*--check for area and at_code match
						IF pc_area = dshold.area AND c_atcode = dshold.at_code
							d_actdate = lf_Actdte( c_Clcode, n_tag)
						ENDIF
				ENDCASE
			CASE EMPTY(dshold.area)
					*--check for litigation and at_code match
					IF c_atcode = dshold.at_code AND pc_litcode = dshold.litigation
							d_actdate = lf_Actdte( c_Clcode, n_tag)
					ENDIF
			OTHERWISE
				*--all criteria are entered
				IF c_atcode = dshold.at_code AND pc_litcode = dshold.litigation AND ;
					pc_area = dshold.area
						d_actdate = lf_Actdte( c_Clcode, n_tag)
				ENDIF
		ENDCASE
	ENDSCAN
ENDIF
SELECT cdshold
USE
SELECT dshold
USE
IF lloGen=.T.
   RELEASE oGen
ENDIF 
SELECT (lnCurArea)   
RETURN d_actdate
*********************************************************************************
PROCEDURE setHold
*--Check for AM review status of order
LOCAL lcSQLLine, lnCurArea, lloGen, l_hold
lnCurArea=SELECT()
IF TYPE("oGen")!="O"
   oGen=CREATEOBJECT("medgeneric")
   lloGen=.T.
ENDIF
lcSQLLine="select * from tblOrder WITH (nolock) where cl_code='"+;
ALLTRIM(c_clcode)+"' and tag='"+ALLTRIM(STR(n_tag))+;
"' and at_code='"+ALLTRIM(fixquote(c_atcode))+"' and handling='R'"
oGen.sqlexecute(lcSQLLine,"viewOrder")
SELECT viewOrder
IF RECCOUNT()>0
	l_hold = .T.
ELSE
	l_hold = .F.
ENDIF
SELECT viewOrder
USE 
IF lloGen=.T.
   RELEASE oGen
ENDIF 
SELECT (lnCurArea)
RETURN l_hold
***********************************************************************************
PROCEDURE updatedistbill
LOCAL lnCurArea, lcSQLLine, lloGen
lnCurArea=SELECT()
IF TYPE("oGen")!="O"
   oGen=CREATEOBJECT("medgeneric")
   lloGen=.T.
ENDIF
*--accomodate the combined ship type that requires 2 entries in the distbill table, with
*--separated shiptype values
IF c_Jobtype = "DV"
	DIMENSION a_Bill[2]
	a_Bill[1] = "DS"
	a_Bill[2] = "VS"
ELSE
	DIMENSION a_Bill[1]
	a_Bill[1] = c_Jobtype
ENDIF

FOR n_cnt = 1 TO ALEN(a_bill, 1)	
	lcSQLLine="select * from tblDistbill WITH (nolock) where cl_code='"+ALLTRIM(c_clcode)+;
	"' and tag='"+ALLTRIM(STR(n_tag))+"' and at_code='"+ALLTRIM(fixquote(c_atcode))+"' and id='"+;
	ALLTRIM(STR(n_idNo))+"' and shiptype='"+ALLTRIM(a_bill[n_cnt])+"'"
	oGen.sqlexecute(lcSQLLine, viewDistBill)
	SELECT viewDistBill
	IF RECCOUNT()=0		
	   lcSQLLine="insert into tblDistBill (Cl_code, Tag, Date_order, Id, At_code,"+;
       "Shiptype, Shipnum, Date_Add, date_bill, created, createdby, active, retire) values("+;
	   "'"+ALLTRIM(c_clcode)+"', '"+ALLTRIM(STR(n_tag))+"', '"+dtoc(d_Order)+"', "+;
	   "'"+ALLTRIM(STR(n_Idno))+"', '"+ALLTRIM(fixquote(c_atcode))+"', '"+ALLTRIM(a_bill[n_cnt])+"', "+;
	   "'1', '"+DTOC(d_today)+"', '"+dtoc(d_billdate)+"', '"+TTOC(DATETIME())+"', "+;
	   "'"+goApp.CurrentUser.ntLogin+"', 1, 0"
	   oGen.sqlexecute(lcSQLLine)
	ELSE
		*check if the distbill order date needs to be updated
		IF viewDistBill.date_order <> d_Order
			lcSQLLine="update tblDistBill set date_order='"+dtoc(d_order)+"' "+;
			"where cl_code='"+ALLTRIM(c_clcode)+;
	        "' and tag='"+ALLTRIM(STR(n_tag))+"' and at_code='"+ALLTRIM(fixquote(c_atcode))+;
	        "' and id='"+ALLTRIM(STR(n_idNo))+"' and shiptype='"+ALLTRIM(a_bill[n_cnt])+"'"
			oGen.sqlexecute(lcSQLLine)
		ENDIF
	ENDIF
ENDFOR
SELECT viewDistBill
USE 
IF lloGen=.T.
   RELEASE oGEn
ENDIF
SELECT (lnCurArea)   
RETURN
