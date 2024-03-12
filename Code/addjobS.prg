**10/21/09  EF :  Added s_pass parameter: folder's code for a pdf file ( such as 'S01'- second req -revision 1)
**09/02/09  EF :  Added the SubmitRPSMainJobStream (pdf) instead of an old one
**02/13/09 	EF :  Pass variant number of child records / re-orderd parameters (addded [DBO].[SubmitRPSJobStreams])
**10/14/08 	EF:  Added strings 4 and 5
**10/10/08    	EF:  set a RetryRps based on the tblRpsList data
**06/06/08       EF : adds a record to a RPSWORK db for a new RPS app to process.
*******************************************************************************************
PARAMETERS c_server, c_job, c_createdby, c_faxno, c_email, c_SubRps, c_clcode, n_tag, n_rt, c_class, c_IDSTC
*!*	c_server="RpsTest"
*!*	c_job =ADATA
*!*	c_createdby =pc_userid
*!*	c_faxno=zAddress
*!*	c_email=""
*!*	c_SubRps="Rps8"
*!*	c_clcode= fixquote(pc_clcode)
*!*	n_tag =pn_tag
*!*	n_rt =pn_lrsNo
*!*	c_class="TestJob"/zclass
IF EMPTY(NVL(c_job,''))
	RETURN
ENDIF
IF TYPE("c_IDSTC")="L"
	c_IDSTC=""
ENDIF

PRIVATE c_Alias AS STRING, l_done AS Boolean, l_ok AS Boolean, c_sql3 AS STRING
STORE .F. TO l_ok, l_done
c_Alias=ALIAS()
LOCAL oSqlCon AS OBJECT
oSqlCon = CREATEOBJ("generic.medgeneric")
STORE "" TO c_sql,c_sql3
IF TYPE('pc_isstype')<>"C"
	pc_isstype=""
ENDIF

IF !pl_TestRPS
IF pl_1st_Req  OR pl_UpdHoldReqst
	c_noprint = IIF(pl_StopPrtIss, STR(1), STR(0))
	c_class= IIF(pl_StopPrtIss  AND  c_class<>'OrigSubp'	, "NoPrint" + ALLTRIM(pc_isstype), ALLTRIM(c_class))
	** YS 05/29/18 RPS No Print Job Logging [#88327]	
	IF AT( UPPER("NoPrint"), UPPER(c_class)) > 0
		lcSQLLine=" exec [dbo].[AddTrackStopPrint]   '" + convertToChar(pc_lrsno,1) + "','" + convertToChar(fixquote(pc_clcode),1) + "','" + convertToChar(n_tag,1) + "','";
			+ convertToChar(pc_isstype,1) + "','" + convertToChar(fixquote(PC_USERID),1) + "','addjobs.prg(1)','"+ ALLTRIM(c_class) +"'"
		*lcSQLLine=" exec [dbo].[AddTrackStopPrint]   '" + ALLTRIM(pc_lrsno) + "','" + ALLTRIM(pc_clcode) + "','" + ALLTRIM(STR(n_tag)) + "','";
			+ pc_isstype + "','" + ALLTRIM(PC_USERID) + "','addjobs.prg(1)','" + c_class + "'"
		oSqlCon.sqlexecute(lcSQLLine,'')
	ENDIF

ELSE
	c_noprint =STR(0)
	c_class= ALLTRIM(c_class)
ENDIF


ELSE
	c_noprint =STR(0)
	c_class= ALLTRIM(c_class)
ENDIF




IF TYPE("pc_offcode")="U"
	IF USED("Master")
		PC_OFFCODE= MASTER.LRS_NOCODE
	ELSE
		PC_OFFCODE="P"
	ENDIF
ENDIF

PRIVATE c_varname, c_varname2,csql,csql2,c_string1 AS STRING
STORE "" TO c_varname,c_varname2,  csql2,c_string1
PRIVATE n_lastone AS INT,  i_loop2 AS INT
IF TYPE("pd_rpsprint ")="U" OR TYPE('d_holddate') ="U"
	PUBLIC pd_rpsprint  AS DATE
	PRIVATE d_holdDate AS DATE
	d_holdDate=DATE()
ENDIF


**03/12/2013- hold 1st requests till release date +1 : "HoldPrint" Project.


IF   PC_OFFCODE="P"  AND NOT pl_StopPrtIss &&9/11/14 - ALLOW SUPRESS HERE

	IF ( pl_1st_Req  AND   c_class<>'OrigSubp'	) OR pl_UpdHoldReqst

		PRIVATE d_ReqMail  AS DATE, ln_spec  AS INTEGER
		ln_spec =0
		DO CASE
		CASE  TYPE ("pd_ReqMail")="D"
			d_ReqMail =pd_ReqMail
		CASE TYPE ("pd_ReqMail")="T"
			d_ReqMail =TTOD(pd_ReqMail)
		OTHERWISE
			d_ReqMail=CTOD(pd_ReqMail)
		ENDCASE
**10/18/13 - ADDED UPDATE HOLD REQUESTS pl_UpdHoldReqst
		IF  pl_UpdHoldReqst  AND ! pl_1st_Req
			ln_spec =canchold ( n_rt,n_tag,   d_ReqMail)
			d_holdDate	=d_ReqMail
			IF  ln_spec=0
				RETURN
			ENDIF

**04/15/16: For Objected tags  add 1 extra day to give them time to order subpoenas (G)
			LOCAL  l_xday AS Boolean
			l_xday=.F.
&&  we add 1 day to a release date for the pl_ObjLifted=.t. only ( when no court set is done, as well)#40860 05/12/16 ( pl_ObjLifted is set in the frmadd51txn /casedeponent.vcx)
			IF TYPE('pl_ObjLifted')<>'L'
				pl_ObjLifted=.F.
			ENDIF

**Check if filing are done ( subps on hold only); if not done add an extra day to a new request as it has to wait to be released
**#43519 ON 6/22/16
			lc_type=""
			oSqlCon.closealias("ReqType")
			oSqlCon.sqlexecute("select [dbo].[TagTypebyClTag] ('" + fixquote(c_clcode) + "','" + ALLTRIM(STR(n_tag)) + "')","ReqType")
			IF USED("ReqType")
				lc_type= NVL(ReqType.EXP,"A")
			ELSE
				lc_type="A"
			ENDIF
**#43519 ON 6/22/16
			IF gnHold<>0  AND 	lc_type="S"  AND !PL_REISSUE
				oSqlCon.closealias("ReprintSet")
				oSqlCon.sqlexecute("select [dbo].[ReprintCourtSet] ('" + fixquote(c_clcode) + "','" + ALLTRIM(STR(n_tag)) + "')","ReprintSet")
				IF !NVL(ReprintSet.EXP,.F.)
					l_xday =.T.
				ENDIF
			ENDIF
			IF pc_isstype='S' AND ln_spec<>0
				DO CASE
				
				CASE   !pl_UpdHoldReqst  &&11/18/15 -Do not add extra day when update /cancel original
					d_holdDate=gfChkDat(d_ReqMail+1, .F., .F.)
				CASE 	l_xday  AND pl_ObjLifted
					d_holdDate=gfChkDat(d_ReqMail+1, .F., .F.)
**05/05/2016- added 1 day to a release date as a court set is not done yet so a tag has to wait a day #40472
					oSqlCon.sqlexecute("exec [dbo].[setReleaseDateXday] '" + c_clcode+ "','" + ALLTRIM(STR(n_tag)) + "', 1","")


				ENDCASE
				pd_rpsprint =d_holdDate
			ENDIF


*!*			5/22/17: #62945-see if an extra day is needed when an update is on day x  but  a waver recived 	on x-1 and no "G" is added yet: may need to add a check for scanned 'g' - Select  dbo.ChkGtypeRider (court, rt, tga) 
** if returns 0 then no "G" exists and we need b_sday =.t.
		ELSE

			IF TYPE('gnHold') ="U"
				gnHold=0
			ENDIF
			IF NOT pl_noticng
				IF gnHold<>0 AND pc_isstype='S'    AND pl_1st_Req   OR ( PL_RISPCCP AND  pc_isstype = "A") &&04/28/15- added PL_RISPCCP/A
					d_holdDate=gfChkDat(d_ReqMail+1, .F., .F.)

				ENDIF
			ENDIF
			pd_rpsprint =d_holdDate
		ENDIF  &&10/18/13
	ENDIF
ENDIF    && tester
**03/12/2013- hold 1st requests till release date +1
&&1/19/17- added pl_pdfOnly #56025-part2
IF TYPE('pl_pdfOnly')="U"
	pl_pdfOnly=.F.
ENDIF
IF pl_pdfOnly AND !pl_TestRPS
	
	c_class= "NoPrintQ"   +IIF(pl_1st_Req, "1",  	"2"  )
	** YS 05/29/18 RPS No Print Job Logging [#88327]	
	IF AT( UPPER("NoPrint"), UPPER(c_class)) > 0
		lcSQLLine=" exec [dbo].[AddTrackStopPrint]   '" + convertToChar(pc_lrsno,1) + "','" + convertToChar(fixquote(pc_clcode),1) + "','" + convertToChar(n_tag,1) + "','";
			+ convertToChar(pc_isstype,1) + "','" + convertToChar(fixquote(PC_USERID),1) + "','addjobs.prg(2)','"+ ALLTRIM(c_class) +"'"
		*lcSQLLine=" exec [dbo].[AddTrackStopPrint]   '" + ALLTRIM(pc_lrsno) + "','" + ALLTRIM(pc_clcode) + "','" + ALLTRIM(STR(n_tag)) + "','";
			+ pc_isstype + "','" + ALLTRIM(PC_USERID) + "','addjobs.prg(2)','" + c_class + "'"
		oSqlCon.sqlexecute(lcSQLLine,'')
	ENDIF
	c_server=c_class
     d_holdDate=DATE()
ENDIF
&&1/19/17- added pl_pdfOnly #56025 -end
*--------------------------
*------- 01/11/2021 MD #217122
IF pl_1st_Req AND !pl_TestRPS 
	oSqlCon.closeAlias("viewCheckDraft")
 	lcSQLLine=" exec [dbo].[checkDraft]   '" + convertToChar(fixquote(pc_clcode),1) + "'," + convertToChar(n_tag,1)
 	oSqlCon.sqlexecute(lcSQLLine,'viewCheckDraft')
 	IF NVL(viewCheckDraft.draft,0)=1
 		c_class= "NoPrintS"
 	ENDIF 
ENDIF  	
 	
*------- 01/11/2021 MD #217122
*--------------------------
nRec = LEN(ALLTRIM(c_job))
n_limit =7000
n_lastone= CEILING(nRec/n_limit)

nrec2=0
c_string1=LEFT(ALLTRIM(c_job),n_limit) && main one
i_loop=0
DO WHILE .T.
	i_loop=i_loop+1
	IF (nRec -(n_limit*i_loop))<=0
		EXIT
	ENDIF
	nrec2=nrec2+n_limit
	c_varname="c_string"+  ALLTRIM(STR(i_loop+1))
	IF NOT EMPTY(c_varname)
		IF TYPE( (c_varname)) = "U"
			PRIVATE  (c_varname) AS STRING
			STORE "" TO (c_varname)
		ENDIF
	ENDIF
	&c_varname = SUBSTR(c_job, nrec2+1 , n_limit) && child ones
ENDDO
IF TYPE('pc_EmailAdd')<>'C'
	pc_EmailAdd=''
	c_email =""
ENDIF

IF !EMPTY(pc_EmailAdd)
	c_email=ALLTRIM(pc_EmailAdd)
ENDIF


*!*		IF INLIST(UPPER( ALLTRIM( Pc_UserID)), "ELLEN")
*!*		c_class='TestSET'
*!*		ENDIF

************************EF- 10/10/08- Get a retry Rps***************************
c_sql="select  RPSWORK.DBO.GetRetryServerRpsName (  '" +  	c_class  + "', '" + PC_OFFCODE +"')"
l_ok=oSqlCon.sqlexecute(c_sql,"getsubrps")
IF  l_ok  AND !EOF()
	c_SubRps=ALLTRIM(getsubrps.EXP)
ENDIF
IF ISNULL(c_SubRps)
	gfmessage(" No job to add, check the RPS retry server.")
	RETURN
ENDIF
**************************10/10/08- Get a retry Rps***************************
c_sql=""
*!*EF 	02/13/2009-- MULITPLE CHILDS RECORDS -UP TO 15 + re-order parameters
STORE "" TO  csql2, csql
**09/02/2009: use pl_PdfReprint
**10/20/09 : pass a pdf folder's code to the RPS
*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*
*!*	1.Print a request:
*!*	a) needs to be stored as pdf:
*!*	    All “FIRST”/”SECOND” class jobs ( PDFFolder in the tblRPSLIST)
*!*	    will be stored as pdf files, either at FISRT or SECOND/Revn folders
*!*		( the jobs that have prqJobSpec AttachfromPdf=‘F00’  will be skipped)
*!*	b) no need to store:
*!*	    All jobs printed/faxed
*!*	2.Print from an existing PDF:
*!*	If a job has ‘F00’ in AttachfromPdf ([prqJobSpec] table)
*!*	it needs a pdf attached which will the very last on the case/tags that can be found.

*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*	*!*

PRIVATE c_folder AS STRING, c_revnum AS STRING, c_pass AS STRING, c_sqlq AS String
c_folder='' && default is  EMPTY
STORE "" TO c_revnum,c_pass

&&2/5/15 : stop using  followup with pdfs
IF TYPE ("pn_RpsMerge")="U"
	pn_RpsMerge=0
ENDIF
IF pn_RpsMerge>0

	c_sql3=  ALLTRIM(STR(pn_RpsMerge))  + ", '"

*!*	IF pl_PdfReprint AND NOT pl_EditReq
*!*		c_folder= LEFT(patemplist(1,5),1)
*!*		c_revnum=SUBSTR(ALLTRIM(patemplist(1,3)), LEN(ALLTRIM(patemplist(1,3)))-2 , 2)
*!*		c_pass =c_folder +IIF(c_revnum="ST", "00",c_revnum)
*!*		c_sql3= c_pass + ", '"
*!*	** F- means attach an origianl PDF file (First Requests)
*!*		RELEASE patemplist
ELSE
	c_sql3= " '', '"
ENDIF
csql=""
	IF TYPE("PC_USERID") ="U"
		PC_USERID=c_createdby
	ENDIF
	IF UPPER( ALLTRIM( Pc_UserID))= "ELLEN" and !pl_ofcOak
	 c_server='TestSet'
	c_class ='TestSet'
	c_SubRps=''
	Endif

**2/17/15 BabyLetter c_server='Rps5'

csql="EXEC [RPSWork].[dbo].[SubmitRPSMainJobStream_65] " +c_sql3 + c_server + "','" +fixquote(c_string1)	+"','" + ALLTRIM(c_createdby) +"','" ;
	+ c_faxno + "' ,'" + c_email + "','" ;
	+ c_SubRps + "','" + c_clcode + "','"+ STR(n_tag) + "','" + STR(n_rt) +"','" ;
	+ c_class  + "'," + c_noprint  + ",'" + PC_OFFCODE   + "'," +;
	IIF(EMPTY(ALLTRIM(NVL(c_IDSTC,''))),"NULL","'"+ALLTRIM(c_IDSTC)+"'")+", '"+	DTOC(d_holdDate)

i_loop2=1

DO WHILE  .T.
	IF  i_loop2=n_lastone
		IF n_lastone=1
			csql2=" ' "
		ENDIF
		EXIT
	ENDIF
	i_loop2=i_loop2+1
	c_line ="c_string" +  ALLTRIM(STR(i_loop2))
	DO CASE
	CASE i_loop2=n_lastone  && the very last child
		csql2= csql2+  "', '" +  fixquote( &c_line) +"'"
	OTHERWISE
		csql2= csql2+  "', '" +  fixquote(&c_line)
	ENDCASE

ENDDO


c_sql=csql+csql2

*!*	SUSPEND
*!*	DO addlogline  WITH  n_tag , c_sql, "{TEST}"


*** part1 : Unknown Deponent  : no job to add if it is not a notices
oSqlCon.closealias("ClassGrp")
c_sqlq=""
c_sqlq="select  RPSWORK.DBO.GetClassGroup2 ( 0,'" +  	c_class  +"')"
l_ok=oSqlCon.sqlexecute(c_sqlq,"ClassGrp")
IF USED("ClassGrp")
	IF  INLIST(ALLTRIM(UPPER(NVL(ClassGrp.EXP,''))), "FIRST","SECOND", "ITTEST")
		oSqlCon.closealias("NoJob")
		oSqlCon.sqlexecute("select [dbo].[getDepCategory] ('"  + fixquote(ALLTRIM(c_clcode))+"', '"+ALLTRIM(STR(n_tag))+"')" ,"NoJob")
		IF USED("NoJob")
			IF NVL(NoJob.EXP,'')="Q"
			gfmessage(" [Unknown Deponent]: no paperwork to print/fax.")
			l_done=.t.
			
			DO addlogline  WITH  n_tag , c_sql, "[Unknown Deponent]"
			RETURN
			ENDIF
		ENDIF

	ENDIF
ENDIF
*** part1 : Unknown Deponent  : no job to add  #56025-END

l_done=oSqlCon.sqlexecute(c_sql,"")

IF NOT l_done
**1/16/14 -add a log to see if we can trap an error for missig holdqueue jobs

	IF TYPE("PC_USERID") ="U"
		PC_USERID=c_createdby
	ENDIF
	DO addlogline  WITH  n_tag , c_sql, "RPSSQLFailed"
	LOCAL c_rttag AS STRING
	c_rttag=""
	c_rttag = ALLTRIM(pc_lrsno )+ "." + ALLTRIM(STR(n_tag))
	gfmessage("Failed to submit a job to the RPS. Contact IT or helpdesk with RT and Tag: " + c_rttag )
	DO SEND4HELP WITH c_createdby, c_rttag
ELSE

ENDIF
IF !EMPTY(c_Alias)
	SELECT (c_Alias)
ENDIF
RELEASE oSqlCon
RETURN

*****************************************
PROCEDURE SEND4HELP
PARAMETERS C_USER, C_CASE

LOCAL n_OK AS Boolean, c_Temp, C_TMP
PRIVATE O_TMP AS OBJECT
O_TMP=CREATEOBJECT("generic.medgeneric")
n_OK=.F.
O_TMP.closealias("UserN")
n_OK=O_TMP.sqlexecute("exec  DBO.[GetUserByLogin] '" +	ALLTRIM( C_USER) + "'", "UserN")
IF n_OK
	SELECT UserN
	IF NOT EOF()
	     && 08/23/2019 MD #141723 Added reference to the log file.
	     c_Temp = ADDBS(MLPriPro("R", "RTS.INI", "Data","JTEMP", "\")) + "TEMP\"		  
		 C_TMP=c_Temp +ALLTRIM(PC_USERID) + STRTRAN(ALLTRIM(C_CASE),".","_") +".TXT"
         &&

		c_SendTo=STRTRAN(ALLT( UserN.Email),";",",")
		c_CopyTo="HELPDESK@recordtrak.com"
		c_FromName=ALLTRIM(UserN.FULLNAME )
		c_FromEmail=STRTRAN(ALLT( UserN.Email),";",",")
		c_Subject=ALLTRIM("Notification: Failed RPS Job  for RT.Tag :" +C_CASE + " on " +  DTOC(DATE())+ "."   )
		c_Message=ALLTRIM("Failed to submit a job to the RPS/Print/Fax. Please re-generate the paperwork on : "  +C_CASE)+CHR(13)+CHR(10)+;
		"Please refer to "+ALLTRIM(c_tmp)   && 08/23/2019 MD #141723
		STORE "" TO c_attachment,c_bCCList
		DO sendwwemail WITH c_FromEmail, c_FromName, c_SendTo,c_CopyTo, c_bCCList, c_Subject, c_Message, c_attachment
		O_TMP.closealias("UserN")
	ENDIF
ENDIF
RELEASE O_TMP
RETURN
