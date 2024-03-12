PROCEDURE CourtSet2
**********************************************************************
** EF 01/81/2014- Added new frmfilings screen

**********************************************************************
PRIVATE lc_Alias, ln_Ok, c_extramsg, ;
	c_Scan, c_Order_h , 	c_PrintJob, c_Print, ll_Retval, d_NotDate, ;
	d_WaivDate, d_IssDate, lc_curpr, icnt, l_Pccp, n_spec, iSets
PUBLIC ld_DateFrom, ld_Dateto, ln_RT, ln_TagFrom, ln_tagTo, c_client, pl_ReleaseTag
LOCAL checkScannedG
STORE "" TO c_PrintJob, c_Scan, c_extramsg
STORE 0 TO ln_RT, ln_TagFrom, ln_tagTo, n_spec, iSets
STORE .F. TO ll_Retval , l_Pccp, pl_UpdHoldReqst, pl_OrigFilings
ln_Ok = 1
ld_dateCourtset=DATE()
*  11/30/2009 - MD make sure the documents don't go to batch printer
pc_BatchRq=""
l_Ok = goapp.openform("utility.frmfiling", "M")
IF NOT l_Ok
	gfmessage("Cancelling printing." )
	WAIT CLEAR
	RETURN
ENDIF
_SCREEN.MOUSEPOINTER=11
lc_Alias = ALIAS() 
oMed = CREATEOBJECT("generic.medgeneric")
ld_dateCourtset=ld_DateFrom && 12/2/ 15 per Liz (#23914) use court set's date when naming an excel
*ld_DateFrom =gotopast(ld_DateFrom-1, .F., .F.)  && 1/14/14- make a reprint look a day back as we use a release date now on the entry form
*  12/27/2017 MD replace wtih SP # 75996 
*----------------------
ld_DateFrom=getLastBusinessDate(ld_DateFrom)
*------------------------------------			
IF pl_OrigFilings
	iSets=2
	c_Order_h=" courtset"
ELSE

	iSets=1
	DO CASE
	CASE  NOT EMPTY(ln_RT)
		c_Order_h=     " clTag"
	OTHERWISE
		c_Order_h=" courtset"	&& 1/14/14 added an ability to reprint all for a date
	ENDCASE

ENDIF
ld_Dateto =ld_DateFrom

pd_dateCourtset=ld_DateFrom

FOR iSET = 1 TO iSets
	IF !pl_OrigFilings
		l_holdreq=filings(2)  && REPRINT
	ELSE
		l_holdreq=filings(iSET-1)

	ENDIF

	IF NOT l_holdreq
		RETURN
	ELSE
		REPLACE ALL WAIVR_DATE WITH {  /  /    } FOR ISNULL(WAIVR_DATE)
		REPLACE ALL OBJCT_DATE WITH {  /  /    }  FOR ISNULL(OBJCT_DATE)
		INDEX ON CL_CODE+STR(TAG) TAG CLTAG ADDITIVE
		INDEX ON ALLTRIM(COURT_NAME)+CL_CODE+DTOC(ISSUE_DATE)+DTOC(WAIVR_DATE) UNIQUE   TAG CourtSet ADDITIVE

	ENDIF
	SELECT holdreq 
	GO top

	c_Scan = "(BETWEEN (Issue_Date, ld_dateFrom, ld_dateTo) OR " + ;
		"BETWEEN (waivr_date, ld_dateFrom, ld_dateTo)) "  + c_RTTag


***** added report
	IF   pl_OrigFilings  AND iSET=1

		DO  getFfile WITH DTOC(ld_dateCourtset), DTOC(pd_dateCourtset) IN flgreport
	ENDIF
***** added report

	SELECT HoldReq
	IF EOF()
		ll_Retval=.F.
	ENDIF

	IF !EOF()
		SET ORDER TO &c_Order_h

		SCAN FOR &c_Scan
			l_Pccp=.F.

			c_PrintJob = ""
			d_NotDate =CTOD(RIGHT(DTOC(HoldReq.notic_date),10))
			d_WaivDate = CTOD(RIGHT(DTOC(HoldReq.WAIVR_DATE),10))
			d_IssDate = CTOD(RIGHT(DTOC(HoldReq.ISSUE_DATE),10))

			gcCl_code = HoldReq.CL_CODE
			gntag = HoldReq.TAG
			STORE d_null TO  pd_startNot
			pd_startNot=CTOD(RIGHT(DTOC(HoldReq.due_DATE),10))
			n_spec=0
			******************************	******************************	******************************	******************************	
			**06/13/2016- remove all tags with waivesr<enddateon the SQL side
			*SELECT HoldReq
			*IF CTOD(RIGHT(DTOC(HoldReq.WAIVR_DATE),10)) < ld_DateFrom AND NOT EMPTY( WAIVR_DATE)
				&&  a set was already printed on 'waiver date', so we can skip it now
				*LOOP
			*ENDIF
		**06/13/2016- remove all tags with waivesr<enddateon the SQL side
		
****mail date ( new send-date )  +1*************************************************************	******************************			
			oMed.closealias("MailDate")
			c_sql = " SELECT [dbo].[GetTagMailDate] ('" +HoldReq.CL_CODE + "','" +STR(HoldReq.TAG) +"')"
			l_Ok=oMed.sqlexecute (c_sql,"MailDate")

			IF l_Ok AND NOT EOF()
				d_Maild =CTOD(LEFT(DTOC(MailDate.EXP),10))

				IF d_Maild>DATE()
					cAlias2=ALIAS()
					oMed.closealias("ReqDate")
					SELECT DISTINCT TOP 1 TAG FROM HoldReq WHERE TAG<>gntag  INTO CURSOR ReqDate ORDER BY TAG

					oMed.closealias("MailDate")
					c_sql = " SELECT [dbo].[GetTagMailDate] ('" +HoldReq.CL_CODE + "','" +STR(ReqDate.TAG) +"')"
					l_Ok=oMed.sqlexecute (c_sql,"MailDate")
					IF l_Ok AND NOT EOF()
						d_Maild =CTOD(LEFT(DTOC(MailDate.EXP),10))
					ENDIF
					IF NOT EMPTY(cAlias2)
						SELECT (cAlias2)
					ENDIF
				ENDIF



			ENDIF
***********************************************************
			ll_Retval = GetCase ( HoldReq.CL_CODE, HoldReq.TAG )
			
			*-- 03/03/2021 MD #225921 the case public variables are set in getcase function
			*-- update released, releasedBy in tblRequest if "G" doc is scanned and the filings are printed
			IF pl_OrigFilings  && exclude reprints				
				checkScannedG="NONE"
				IF pc_RpsForm="KOPGeneric" OR pl_WebForm
					checkScannedG=SubRiderPcx( HoldReq.TAG, "G", 1)
				ENDIF 
				IF LEN(ALLTRIM(checkScannedG))>0	&& do not update release date if the G subpoena is not scanned yet 				
					lcSQL="exec dbo.UpdateReleaseDate 0," + ALLTRIM(STR(NVL(HoldReq.TAG,0)))+",'"+ALLTRIM(fixquote(NVL(goApp.CurrentUser.orec.LOGIN,"")))+"', '"+ALLTRIM(NVL(HoldReq.cl_code,""))+"'"
					oMed.sqlexecute(lcSQL)
				ELSE
					lcSQL="exec dbo.UpdateReleaseDateLog 0," + ALLTRIM(STR(NVL(HoldReq.TAG,0)))+",'"+ALLTRIM(fixquote(NVL(goApp.CurrentUser.orec.LOGIN,"")))+"', '"+;
					ALLTRIM(NVL(HoldReq.cl_code,""))+"', 'G Subpoena is not scanned yet'"
					oMed.sqlexecute(lcSQL)
				ENDIF 
			ENDIF 
			*-- 03/03/2021 -----------------


			IF ll_Retval
				WAIT WINDOW "Printing. Please wait." NOWAIT NOCLEAR

** 11/07/12 - add Efiling to tblCourt since more courts want to get emails

				C_STR =" select dbo.CourtEfiling ('" + ALLTRIM(UPPER(HoldReq.COURT_NAME)) + "')"
				oMed.sqlexecute(C_STR,"Efiling")
				IF USED("Efiling")
					l_Pccp=Efiling.EXP
				ELSE
					l_Pccp=.F.
				ENDIF

				mclass =IIF(l_Pccp, "PDFCOURT", "CourtSet")

				IF NOT l_Pccp
**1. Print a Court Cover Letter Page
					c_cov = CourtCov(d_Maild)
					c_PrintJob = c_PrintJob + c_cov
**01/15/2009-EF- DO NOT PRINT A COPY OF A SET TO THE PCCP COURTS
				ENDIF

				IF l_Pccp
					icnt =1
				ELSE
					icnt =2
				ENDIF
				pl_SkipBatchPRT=.T.
**01/15/2009-EF- DO NOT PRINT A COPY OF A SET TO THE PCCP COURTS
				FOR iCount = 1 TO icnt                    && print the next set twice for all but PCCP courts
**2. Court Certificate

					*c_Prer = PrtPrere ( iCount, d_Maild)
					&&06/27/16- added  a new court prereq page #43585
					c_Prer =kopcert2 ( iCount, d_Maild,.f.)
					c_PrintJob = c_PrintJob + c_Prer
					ACTION = "0"                  && Do not print a court prerequisite from subp_pa
					C_STR ="Exec [dbo].[GetRequestByMasterIdAndTag] '" + MASTER.ID_TBLMASTER + "','" + STR(HoldReq.TAG) + "'"

					l_gotReq=oMed.sqlexecute(C_STR,"Request")
					IF  NOT l_gotReq
						gfmessage('Cannot get the notices. Try later or contact IT dept.')
						pl_SkipBatchPRT=.F.
						RETURN

					ENDIF
**3. Notices + Subpoena
					DO TheNotic WITH .T., pc_SSNLst4, d_NotDate, .T., d_IssDate
					c_PrintJob = c_PrintJob + mv
					IF EMPTY(ALLTRIM(MV))
						gfmessage('Cannot get the notices.  Please check case settings (3.1) for the RT ' + ALLTRIM(pc_lrsno)  + ' and try again.')
					ENDIF
					gntag = HoldReq.TAG

**4. Print Subpoenas
					STORE "" TO mv , c_Job
					DO AttachSubp WITH ln_TagFrom, ln_tagTo, iCount


					c_PrintJob = c_PrintJob + mv


					IF  EMPTY( c_PrintJob) && MEANING SOME OF THE SCANNED IMAGES WERE NOT FOUND FOR THE KOP GENERIC
	
 						gfmessage( "The documents have NOT been sent to the RPS Server.  Contact helpdesk with RT #" + ALLTRIM(pc_lrsno) )	&&07/07/2016				
 						
						SELECT HoldReq
						ll_Retval=.F.
						EXIT
					ENDIF 
					IF l_Pccp=.F. and LEFT(ALLTRIM(UPPER(HoldReq.COURT_NAME)),3)=="PA-" AND !EMPTY(ALLTRIM(c_PrintJob))
** 5. print PA Cert Compliance page #76949 03/20/2018 
						mv=PACertCompl(MASTER.ID_TBLMASTER)
						c_PrintJob = c_PrintJob + mv
					ENDIF 					
					IF !EMPTY(ALLTRIM(c_PrintJob))
**6. Print a 'Supress' page when needed
						IF  pl_OrigFilings  OR pl_ReleaseTag&& PRINT SUPRESS PAGE ONLY WITH ORIGINALS- WHEN RE[PRINT IS DONE IT IS NOT NEEDED?
							c_Job=suppress()
						ENDIF
						c_PrintJob=c_PrintJob+c_Job
&&08/28/13 - print to test RPS till test cycle is on for Hold_Print2 project
						SET PROCEDURE TO TA_LIB ADDITIVE

						DO prtenqa WITH c_PrintJob, IIF(l_Pccp,"PDFCOURT","CourtSet"), "1" , ""

**10/18/13 resubmit Hold requests now
						IF USED ('SubpOrd')
							SELECT SubpOrd
							SCAN
							
							
								IF  specid>0 &&3/20/15
									oMed.sqlexecute(" exec rpswork.dbo.ResubmitOnHoldJobwithCourtSet '" +  STR(SubpOrd.specid)+ "'")
								ENDIF 
								&&- show all tags enen 'Noprint' per Liz but make sure we do not resubmit them
&& 12/27/13- mark the tags for the report that wie genarate at the end of the process
									c_alias=ALIAS()
									IF USED("Setsdata")
										SELECT Setsdata
										REPLACE INCLUDE WITH .T.   FOR rtnum=VAL(pc_lrsNo) AND tagnum =SubpOrd.DepTag
										
									ENDIF
									SELECT (c_alias)
							*	ENDIF && resubmit only jobs that has specid>0
*************update as printed 12/19/2013 ***********************************************

								_SCREEN.MOUSEPOINTER= 11

								IF USED ('RECORD')
									SELECT RECORD
									USE
								ENDIF

								WAIT WINDOW " Getting Records.. wait" NOWAIT NOCLEAR
								pl_GotDepo = .F.
								DO gfGetDep WITH fixquote(pc_clcode),SubpOrd.DepTag



								C_STR=""
								IF pl_OrigFilings OR pl_ReleaseTag
									C_STR= "Exec dbo.gfAddTxn_CourtSet44 '" + DTOC(DATE())+  " ', '" ;
										+ ALLTRIM("Subpoena Release Date") + "' ,'" +HoldReq.CL_CODE + "',' " ;
										+ ALLTRIM(STR(44)) + "','"  + ALLTRIM(STR(SubpOrd.DepTag)) + "','" ;
										+ RECORD.MAILID_NO + "','" + STR(0) + "','" ;
										+ ALLTRIM(STR(0)) + "','" +  IIF(SubpOrd.specid>0,'','1') + "','" ;
										+ ALLTRIM(STR(0)) + "', '"  + "" + "','" ;
										+ RECORD.TYPE + "','" ;
										+ ALLTRIM(pc_UserID) + "','" ;
										+ RECORD.id_tblRequests +"'"
									l_done=oMed.sqlexecute(C_STR,"")
									_SCREEN.MOUSEPOINTER= 0
									IF NOT l_done

										WAIT WINDOW "The txn 44 was not added." NOWAIT

									ENDIF



								ENDIF




*************update as printed 12/19/2013 ***********************************************
							ENDSCAN


							SELECT SubpOrd
							USE
						ENDIF
**resubmit requets now

					ENDIF
				NEXT

			ENDIF
			SELECT MASTER
			USE


			SELECT HoldReq
			IF !pl_OrigFilings
				IF NOT pl_ReleaseTag
**If no jobs to resubmit and it is a reprint  go to the very last tag in the holdreq
					SELECT HoldReq
					GO BOTTOM
				ENDIF
			ENDIF


************************************************************************************************

		ENDSCAN


		pl_SkipBatchPRT=.F.
		pl_noticng=.F.

	ENDIF &&&11/20/13
	IF NOT ll_Retval
		WAIT WINDOW "No data was found." NOWAIT NOCLEAR
	ELSE
		IF pl_OrigFilings
			IF iSET=1
				gfmessage( "The non-electronic filings have been sent to the RPS Printer ")
			ELSE
				gfmessage( "The E-filings have been sent to the CivilCases Email Box. ")
			ENDIF
		ELSE
			gfmessage( "The reprints have been generated.")
		ENDIF
	ENDIF


NEXT  && TWO SETS BY DATE : ELECTRONIC AND NON -ELECTRONIC


*****12/27/13 -email a report at the end of the process
IF   pl_OrigFilings
	DO sendFfile WITH DTOC(ld_dateCourtset) IN flgreport
ENDIF
*****08/09/13- added report





_SCREEN.MOUSEPOINTER=0
pd_dateCourtset=""
IF USED('HoldReq')
	USE IN HoldReq
ENDIF


WAIT CLEAR
RETURN
************************************************************************
PROCEDURE CourtCov
** Prints a 'Court Filing' Cover Letter Page
**09/26/13- added   d_sendrequest
************************************************************************
PARAMETERS d_sendrequest
PRIVATE c_Print
c_Print = ""

SET PROCEDURE TO TA_LIB ADDITIVE
IF TYPE ("d_sendrequest")<>"D"
	d_sendrequest=IIF( NOT EMPTY(WAIVR_DATE), DTOC(WAIVR_DATE), DTOC(ISSUE_DATE))
ENDIF

SELECT HoldReq
DO printgroup WITH c_Print, "CourtCov"
DO printfield WITH c_Print, "Loc", IIF( pc_offcode = "G", "P", pc_offcode)
DO printfield WITH c_Print, "ControlDate", DTOC( d_sendrequest)
*IIF( Not Empty(WAIVR_DATE), Dtoc(WAIVR_DATE), Dtoc(ISSUE_DATE))
DO printfield WITH c_Print, "CourtAdd", PROPER( ALLTRIM( pc_C1Addr2))
DO printfield WITH c_Print, "CourtCSZ", ;
	(ALLTRIM( PROPER( pc_c1City)) + ", " + pc_c1State + SPACE(2) + pc_c1Zip)
DO printfield WITH c_Print, "County", PROPER( ALLTRIM( pc_c1Cnty))
DO printfield WITH c_Print, "AMName", PROPER( pc_amgr_nm)
DO printfield WITH c_Print, "AMPhone", pc_amgr_ph
RETURN c_Print

*************************************************************************
PROCEDURE GetCase
** Gets data regarding selected case/tag
*************************************************************************
PARAMETERS c_client, n_tag

PRIVATE c_alias, c_Order1, c_order2, l_Retval

c_alias = ALIAS()
l_Retval = .T.
IF NOT USED('MASTER')
	oMed.sqlexecute(" EXEC [dbo].[GetMasterByclcode] '" + HoldReq.CL_CODE + "'",'Master')
ENDIF

pn_tag=n_tag

SELECT MASTER
pl_GotCase = .F.
DO gfGetCas
**Exclude test cases

&&	 Use test for Ellen
IF  ALLTRIM(goapp.CurrentUser.orec.LOGIN) ='ELLEN'
	pl_testcas=.F.
ENDIF
IF pl_testcas
	l_Retval = .F.
	RETURN l_Retval
ENDIF

IF pc_offcode = "T" OR NOT pl_CrtFlng
	l_Retval = .F.
	RETURN l_Retval
ENDIF


c_RqAtty=fixquote(pc_rqatcod)
pl_GetAt = .F.
DO gfatinfo WITH c_RqAtty, "M"

IF NOT EMPTY(c_alias)
	SELECT (c_alias)
ENDIF

RETURN l_Retval
********************************************************************************************************************
PROCEDURE AttachSubp
**EF 03/30/04 Print subps after notices
*******************************************************************************************************************
PARAMETERS n_tagFrom, n_tagTo, 	i_Count
PRIVATE cScan
pl_noticng = .T.

IF USED( "autosubp")
	SELECT AutoSubp
	GO TOP
	IF EOF()
		c_PrintJob=""
		RETURN
	ENDIF
ELSE
	
	gfmessage('Cannot get the SUBPOENAS.')					
	c_PrintJob=""
	RETURN
ENDIF

*10/18/13 - store specid with tags where we need to resubmit a request

SELECT  000000000 AS specid , a.* FROM AutoSubp a INTO CURSOR SubpOrd ORDER BY DepTag READWRITE
SELECT SubpOrd
GO TOP

IF NOT EMPTY(n_tagFrom)

	nTag1=TRANSFORM(n_tagFrom,'999')	
	*-- 04/12/2018 MD #84151
    IF TYPE("n_tagTo")="C"
		IF EMPTY(ALLTRIM(n_tagTo))
			n_tagTo="999"
		ENDIF
	ENDIF 
	nTag2=TRANSFORM(n_tagTo,'999')
	cScan = " BETWEEN( DepTag, &nTag1, &nTag2) "
ELSE
	cScan = " NOT DELETED() "
ENDIF
LOCAL C_STR AS STRING , c_Desc AS STRING , ccl_code AS STRING, l_done AS Boolean
oMed1 = CREATE("generic.medgeneric")
c_Desc="Subpoena Release Date"
PRIVATE n_tagnum AS INTEGER, n_HOLDrec AS INTEGER


SCAN FOR &cScan
* 11/30/2009 MD movied open Spec_ins in the loop
* the table is reset in subp_pa for one tag only
	IF USED("spec_ins")
		USE IN Spec_ins
	ENDIF
	l_SpecIns=oMed.sqlexecute(" Exec dbo.GetSpec_InsbyClCode '" + fixquote(pc_clcode) + "'", "Spec_ins")

	IF NOT l_SpecIns
		gfmessage('Cannot get the Special Instruction File. Try later or contact IT dept.')
		RETURN
	ENDIF
	n_tagnum=SubpOrd.DepTag
	pn_tag =n_tagnum

	IF USED ('RECORD') AND RECORD.TAG <>pn_tag
		SELECT RECORD
		USE
		_SCREEN.MOUSEPOINTER= 11

		WAIT WINDOW " Getting Records.. wait" NOWAIT NOCLEAR
		pl_GotDepo = .F.
		DO gfGetDep WITH fixquote(pc_clcode), n_tagnum
		_SCREEN.MOUSEPOINTER= 0
	ENDIF


	DO Subp_Pa WITH .T., 2, SubpOrd.DepTag, .T., .F., .T., "S"




***1/19/09- add txn 44 for each tag that we released
	IF i_Count=1
		c_alias=ALIAS()

		STORE "" TO C_STR,  ccl_code
		l_done=.F.
		ccl_code=fixquote(pc_clcode)
		SELECT HoldReq
		c_Order_h=ORDER()
		n_HOLDrec = RECNO()
		SET ORDER TO CLTAG
		IF SEEK(HoldReq.CL_CODE+ STR(n_tagnum))
			pn_tag =n_tagnum
******************************

&&08/26/2015 Added WEBFORM for PCCP
&&7/16/2013 	 Check if a rps has a job in a queue  that is set to be printer today	: "HoldPrint" Project-start
      
			IF pc_RpsForm="KOPGeneric" OR pl_WebForm
				c_scanG=SubRiderPcx( n_tagnum, "G", 1)
				IF EMPTY(ALLTRIM(c_scanG))
					SELECT HoldReq
					SET ORDER TO (c_Order_h)
					mv=""
					gfmessage("Cannot find a scanned subpoena ('G' image for RT.tag: " + pc_lrsno+ "." + ALLTRIM(STR(n_tagnum)) + " ). Please, check the scanning system and try again.")
					c_PrintJob="" && DO NOT GENERATE a court set as there is no SCANNED SUB YET to go with it
					EXIT
				ELSE
				**------------- 01/18/2016 - MD update log_fld in tblRequest that the subpoena has been scanned
				lcSQLLine="exec dbo.UpdateWaivrPend '"+ALLTRIM(ccl_code)+"', "+ALLTRIM(STR(n_tagnum))+", '"+ALLTRIM(UPPER(pc_UserID))+"'"
				oMed.sqlexecute(lcSQLLine)
				**-------------
				ENDIF
			ENDIF
			oMed.closealias("ReprintSet")
			oMed.sqlexecute("select [dbo].[ReprintCourtSet] ('" + ccl_code + "','" + ALLTRIM(STR(n_tagnum)) + "')","ReprintSet")

			oMed.closealias("HoldJob")
			SELECT HoldReq
			oMed.sqlexecute("select dbo.ChkRpsHoldQueuebyCourtSet2 ('" +pc_lrsNo + "','" + STR(n_tagnum) + "','" + IIF(NOT EMPTY( WAIVR_DATE),DTOC(d_WaivDate), DTOC(ld_DateFrom)) + "')","HoldJob")

**11/15/13 Added SKIP FOR OLD JOBS -ISSUED BEFORE WE RELEASED THE HOLD PRINT INTO A PRODUCTION*!*
			l_oldset=.F.
			LOCAL l_NoPrtTg AS Boolean
			l_NoPrtTg=.F.
			oMed.closealias("Suppress")
			oMed.sqlexecute("select [dbo].[WasTagSuppressed] ('" + ccl_code + "','" +  ALLTRIM(STR(n_tagnum) )+ "')", "Suppress")
			IF NVL(suppress.EXP,.F.)=.T.
				l_NoPrtTg=.T. && no print tag
			ENDIF
			
			
			IF l_NoPrtTg
				c_alias=ALIAS()
				IF USED("Setsdata")
					SELECT Setsdata										
					REPLACE  Suppress WITH .t.   FOR rtnum=VAL(pc_lrsNo) AND tagnum =n_tagnum  
				ENDIF
				SELECT (c_alias)
			ENDIF
			
			
**11/15/13 Added SKIP FOR OLD JOBS -ISSUED BEFORE WE RELEASED THE HOLD PRINT INTO A PRODUCTION
			IF USED('HoldJob')
				n_spec=NVL(HoldJob.EXP,0)
				DO CASE
				CASE  n_spec=0 AND  !ReprintSet.EXP
**11/15/13 Added SKIP FOR OLD JOBS -ISSUED BEFORE WE RELEASED THE HOLD PRINT INTO A PRODUCTION
					IF USED('OldSet')
						l_oldset=IIF(NVL(OldSet.EXP,0)=0,.F.,.T.)
					ENDIF
**11/15/13 Added SKIP FOR OLD JOBS -ISSUED BEFORE WE RELEASED THE HOLD PRINT INTO A PRODUCTION
					IF NOT l_oldset AND NOT l_NoPrtTg
						gfmessage('Cannot find a pending request in the RPS Hold Print Queue for RT# ' + pc_lrsNo + ' and Tag# '+ ALLTRIM(STR(n_tagnum)) + '. Try later or contact IT dept.')
						SELECT HoldReq
						SET ORDER TO (c_Order_h)

						mv=""
						c_PrintJob="" && DO NOT GENERATE a court set as there is no first request to go with it
						LOOP
					ENDIF
				CASE   n_spec<>0 AND ReprintSet.EXP
					gfmessage('There is a pending request in the RPS Hold Print Queue for RT# ' + pc_lrsNo + ' and Tag# '+ ALLTRIM(STR(n_tagnum)) + '. Cannot do a reprint yet..')
					SELECT HoldReq
					SET ORDER TO (c_Order_h)
					mv=""
					c_PrintJob="" && DO NOT GENERATE a court set as there is no first request to go with it
					LOOP
				OTHERWISE

					n_spec=NVL(HoldJob.EXP,0)
					c_al =ALIAS()
					SELECT SubpOrd
					REPLACE specid WITH n_spec  &&FOR DepTag=N_TAGNUM
					SELECT (c_al)
				ENDCASE
			ENDIF

*ENDIF &&1 IF

		ENDIF




		SELECT HoldReq
		GO n_HOLDrec
		SET ORDER TO (c_Order_h)

		SELECT (c_alias)
	ENDIF


***1/19/09 -end
	SELECT SubpOrd
ENDSCAN



SELECT AutoSubp
USE
*!*	Select SubpOrd
*!*	Use
IF USED('Spec_ins')
	SELECT Spec_ins
	USE
ENDIF
SELECT REQUEST
USE
SELECT RECORD
USE
CLEAR WINDOW
RETURN

******************************************************************************
******************************************************************************
FUNCTION suppress
* edited 12/11/13- to list all ( 'Noprint' )suppressed requests on one page

LOCAL l_cmemo AS STRING, l_cAlias AS STRING, c_tag AS STRING
l_cmemo=""
l_cAlias=ALIAS()
IF USED("NoPrt")
	SELECT NoPrt
	USE

ENDIF
SELECT  DepTag  FROM SubpOrd WHERE specid =0 ORDER BY DepTag  INTO CURSOR NoPrt
SELECT NoPrt
c_tag=""
SCAN

	oMed.closealias("SuppressJob")
	oMed.sqlexecute("select [dbo].[WasTagSuppressed] ('" + pc_clcode+ "','" +  ALLTRIM(STR(NoPrt.DepTag ))+ "')", "SuppressJob")
	IF NVL(SuppressJob.EXP,.F.)=.T.
		c_tag = c_tag +IIF(EMPTY(c_tag),"", "; " )+  ALLTRIM(STR(NoPrt.DepTag ))
	ENDIF

	SELECT NoPrt
ENDSCAN


IF !EMPTY(ALLTRIM(c_tag))
	DO printgroup WITH l_cmemo, "Suppress"
	DO printfield WITH l_cmemo, "RT",  pc_lrsNo
	DO printfield WITH l_cmemo, "Tag", ALLTRIM(c_tag)
ENDIF
IF NOT EMPTY(l_cAlias)
	SELECT(l_cAlias)
ENDIF

RETURN l_cmemo


******









***********************************************************************************
FUNCTION GetClient
** Gets a cl_code from RT #
***********************************************************************************
PARAMETERS cRt
PRIVATE cClient, cAlias, cOrder
STORE "" TO cClient, cAlias, cOrder
cAlias = ALIAS()

c_sql=" Exec[dbo].[GetMasterbyRT] '" + cRt + "'"
l_found=oMed.sqlexecute(c_sql,'Master')

IF l_found
	cClient = ALLTRIM(MASTER.CL_CODE)
ELSE
	gfmessage( "RT # " + ALLTRIM(cRt) + " does not exist. Try another one.")
ENDIF

IF NOT EMPTY(cAlias)
	SELECT (cAlias)
ENDIF
RETURN cClient
**************************************************************************************
FUNCTION getLastBusinessDate
PARAMETERS  ldLastDate
LOCAL lnCurArea, lcSQLLine2
lnCurArea=SELECT()
SELECT 0 
IF EMPTY( ldLastDate)
	 ldLastDate=DATE()
ENDIF 	 
omed.closeAlias("lastBusDate")
lcSQLLine2 = " SELECT [dbo].[getLastBusinessDate] ('" +DTOC( ldLastDate) +"')"
oMed.sqlexecute (lcSQLLine2 ,"lastBusDate")
SELECT lastBusDate
 ldLastDate= TTOD(lastBusDate.exp)
omed.closeAlias("lastBusDate")
SELECT (lnCurArea)
RETURN  ldLastDate
**************************************************************************************
PROCEDURE PACertCompl
LPARAMETERS tblMasterID
LOCAL lnCurArea, mv, lcSQLLine2
IF ISNULL(tblMasterID)
   RETURN
ENDIF 
mv=""
lnCurArea=SELECT()
SELECT 0
omed.closeAlias("CompAttyInfo")   
lcSQLLine2 = "exec dbo.getCertCompInfo '"+ALLTRIM(tblMasterID)+"'"
oMed.sqlexecute (lcSQLLine2 ,"CompAttyInfo")
select CompAttyInfo
IF RECCOUNT()=0
    SELECT (lnCurArea)
    RETURN ""
ENDIF   
IF EMPTY(ALLTRIM(NVL(CompAttyInfo.name_inv,"")))  AND EMPTY(ALLTRIM(NVL(CompAttyInfo.barnumber,"")))
   SELECT (lnCurArea)
   RETURN ""
ENDIF  
DO PrintGroup WITH mv, "CertComp"
Do PrintField With mv, "CaseAttyName", PROPER(ALLTRIM(CompAttyInfo.name_inv))
Do PrintField With mv, "BarNo", ALLTRIM(CompAttyInfo.barnumber)
omed.closeAlias("CompAttyInfo")   
RETURN mv

