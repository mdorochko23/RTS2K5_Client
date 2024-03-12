**************************************************************************************
** EF- Reprint a Request as a Follow-Up Letter and a PDF file
**  05/21/12 EF - ADDED DepToPrint.PRG
**  03/21/12 EF - added OMRPage and edited to have the same logic when calculating due date for all USDC CA courts
**  12/27/11 EF - added [AutofaxCaption] var
**  05/25/11 EF - new or old BB set-
**  01/18/10 EF - Get rps by a dept's category
**  11/18/09 EF - DUEDATE: RECALCULATE FROM AN ORIGINAL when no DATE is STORED
**  11/02/09 EF - For CA isues, if a scanend POS exists and it is a first reprint ;
**				of a request include a POS into a PDF
**************************************************************************************
PROCEDURE reppdfreq
PARAMETERS nRTNum, nTagNum, lautocov, cIssType, dtxndate, cdept,  cdeponent
**lautocov set to true when do a SmartFax
PRIVATE c_alias AS STRING
PRIVATE mv_f   AS MEMO
LOCAL o_Followup AS OBJECT
IF TYPE('TheInfo')="U"
	PUBLIC TheInfo, TheInfo2
	STORE "" TO TheInfo, TheInfo2
ENDIF
c_alias =ALIAS()
o_Followup=CREATEOBJECT('medrequest')
o_Followup.closealias("MailDate")
c_sql = " SELECT [dbo].[GetTagMailDate] ('" +fixquote(pc_clcode) + "','" +STR(nTagNum) +"')"
l_ok= o_Followup.sqlexecute (c_sql,"MailDate")

IF l_ok AND NOT EOF()
	pd_MailDte=CTOD(LEFT(DTOC(MailDate.EXP),10))
ELSE
	pd_MailDte=dtxndate
ENDIF
pd_Maild    =pd_MailDte


pd_duedate=  GetReqDueDate ( pc_clcode, nTagNum, {  /  /    })
IF TYPE( "pd_duedate") = "D"
	IF  EMPTY( pd_duedate)
** RECALCULATE FROM AN ORIGINAL
**KOP ISSUES
		DO CASE

		CASE pc_OFFCODE ="P"
			pd_duedate=getduedate(pd_MailDte,  dtxndate ,cIssType, dtxndate, lnComply , gnHold, .F., .F.)
		CASE pc_OFFCODE ="C"
			l_ok= o_Followup.sqlexecute (" select [dbo].[IfHandServerSub] ('" +fixquote(pc_clcode) + "','" + STR(nTagNum) + "')" , "HS_Subp" )
			IF l_ok AND NOT EOF()
				l_HandSrv=HS_Subp.EXP
			ELSE
				l_HandSrv=.F.
			ENDIF
			IF cIssType="S"
				l_HandSdate =IIF(LEFT( PC_COURT1, 4) = "USDC", dtxndate,getservd(dtxndate, l_HandSrv )     )
				* ------04/04/2018 MD #77675	
				*pd_duedate =gfChkDat(l_HandSdate +15, .F.,.F.)
				IF Left( Alltrim(PC_COURT1), 4) == "USDC"
					pd_duedate =gfChkDat(l_HandSdate +20, .F.,.F.)
				ELSE
					*-- 03/13/2019 MD #126908
		      		*pd_duedate =gfChkDat(l_HandSdate +15, .F.,.F.)
		      		*-- 04/08/2019 MD ##126908 added check for handserv
		      		IF l_HandSrv
			      		pd_duedate =gfChkDat(l_HandSdate +15, .F.,.F.)
			      	ELSE 
			      	    pd_duedate =gfChkDat(l_HandSdate +16, .F.,.F.)
			      	ENDIF 
		 		ENDIF 
				*------------------------------
			ELSE

				pd_duedate =gfChkDat(pd_MailDte +10, .F.,.F.)
			ENDIF
		ENDCASE
** no date was found or re-calculated so a default is +10 to an issue date
		IF  EMPTY( pd_duedate)
			pd_duedate=gfChkDat(dtxndate+10, .F.,.F.)
		ENDIF

	ENDIF
ENDIF


**7/20/2015  Md needs a 30-days release letter: START
mv_md=""
IF   pc_c1Name = "MD-BaltimoCity" AND cIssType="S"
	dRequestDate=pd_MailDte
** add a '30 days letter'  if a 30 days objection is over
	IF 	D_TODAY >=gfChkDat(dRequestDate+30, .F.,.F.)
		cmailid_NO=pc_mailid
		mv_md= Md30days(   cdeponent,cdept,nRTNum, nTagNum, cmailid_NO,dRequestDate)
	ENDIF
ENDIF
**7/20/2015  Md needs a 30-days release letter: END

mv_f = FollupCov ()
*-- 04/12/2018 MD 
IF TYPE("mv")<>"C"
	mv=""
ENDIF 	
mv=mv+mv_md+ mv_f

*02/26/2018 - MD # 75726/78152 
If Type( "mvScanDocsOnly")="U"
	Public mvScanDocsOnly
	mvScanDocsOnly=""
ENDIF
If Type( "mvScanDocsOnly")<>"C"
   mvScanDocsOnly=""
ENDIF    
mvScanDocsOnly=mvScanDocsOnly+FollupCov2()

RELEASE o_Followup

IF NOT EMPTY(c_alias)
	SELECT (c_alias)
ENDIF
RETURN

*******************************************************************************************************************************************************************
PROCEDURE FollupCov2
* - 02/19/2018 MD 75726/78152 
* - FollowUp cover page to use with scanned documents only

LOCAL mv_f, cdept, szattn, c_faxnum, c_sql, c_addition, c_dep, oReq
STORE "" TO  mv_f, cdept, szattn

IF LEFT(timesheet.MAILID_NO ,1)="H"
	cdept=deptbydesc(timesheet.DESCRIPT)
ELSE
	cdept = "Z"
ENDIF
DO DepInfoLetter WITH cdept
c_faxnum = 	TRANSFORM( ALLTRIM(pc_depofile.fax_no), "@R (999)999-9999")
oReq=CREATEOBJECT('medrequest')
c_sql="select dbo.GetDeptCode2('" +fixquote(pc_clcode) +"',"+ALLTRIM(STR(nTagNum))+") as deptcode"
oReq.sqlexecute(c_sql, "Dept")
c_addition= getdescript(NVL(Dept.deptcode,'Z'))
c_dep=DepToPrint ( ALLTRIM(NVL(pc_depofile.NAME,cdeponent)))

DO PrintGroup WITH mv_f, "FollUpC2"
DO PrintField WITH mv_f, "PrintDate" , DTOC(DATE())
DO PrintField WITH mv_f , "DeponentFax", c_faxnum
DO PrintGroup WITH mv_f, "Deponent"
DO PrintField WITH mv_f, "Name", c_dep + IIF(pc_deptype = "H" AND NOT pl_CaVer ,"",c_addition)
DO PrintField WITH mv_f, "Addr", 	IIF(EMPTY(pc_depofile.add2), pc_depofile.add1, pc_depofile.add1 + CHR(13) + pc_depofile.add2)
DO PrintField WITH mv_f, "City", pc_depofile.city
DO PrintField WITH mv_f, "State", pc_depofile.state
DO PrintField WITH mv_f, "Zip", IIF(ALLTRIM(pc_depofile.zip)='00000','', ALLTRIM(pc_depofile.zip))
DO PrintField WITH mv_f, "Extra", IIF(ISNULL(szattn),"",szattn)

RELEASE oReq
RETURN mv_f
*******************************************************************************************************************************************************************
PROCEDURE FollupCov
**8/17/2010 MAKE SURE IT IS ALWAYS A CORRECT REQUEST'S DATA when called from a Login system
**9/14/09 added a var to a caption
**11/23/09 compare A due date to the Hold date (txn51)
**11/23/09 add an attention line for all requests where that data exists
LOCAL c_attn AS STRING, c_Save AS STRING, c_offlocation AS STRING, c_faxnum  AS STRING, ld_HDate AS DATE, c_caption AS STRING, c_addition AS STRING

c_Save = SELECT()
STORE "" TO c_offlocation, mv_f, c_attn, c_faxnum, c_caption, c_addition
ld_HDate=CTOD(LEFT(DTOC(DATE()),10))

**02/02/2010 - pull the right ACD number
*!*	DO CASE
*!*	CASE pl_ofcMD OR pl_ofcPgh OR pl_OfcKop
*!*		l_GetRps= Acdamnumber (pc_amgr_id)
*!*		IF l_GetRps
*!*			c_offlocation=IIF(ISNULL(LitRps.RpsOffCode), 'P', LitRps.RpsOffCode)
*!*			IF EMPTY(ALLTRIM(c_offlocation))
*!*				c_offlocation=pc_OFFCODE
*!*			ENDIF
*!*		ENDIF
*!*	OTHERWISE
*!*		c_offlocation=pc_OFFCODE
*!*	ENDCASE


**08/21/2017: New ACD Lines #67249
c_offlocation=RpsLoc()
**08/21/2017: New ACD Lines #67249
IF EMPTY(ALLTRIM(c_offlocation))
	c_offlocation=pc_Offcode
ENDIF



szattn = ""
TheInfo = "OTHER"
o_LETTER=CREATEOBJECT('medrequest')

IF LEFT(timesheet.MAILID_NO ,1)="H"
	cdept=deptbydesc(timesheet.DESCRIPT)
ELSE
	cdept = "Z"
*pc_MAttn="" && 07/16/12 - use attention line plus department when attention is empty in the Depo Rolodex
ENDIF


DO DepInfoLetter WITH cdept
**07/16/12
*!*	IF EMPTY(ALLTRIM(szattn)) &&attention line
*!*		szattn=ALLTRIM(pc_depofile.Attn)
*!*	ENDIF

WAIT WINDOW "Printing a Follow-up Cover Page" NOWAIT

DO PrintGroup WITH mv_f, "FollUpCov"
&&07/19/17- Arizona subps in KOP for the CA office
&&03/10/17 -#58943
IF (pc_Litcode = "A" AND pc_area    = "WEITZ CAL" AND pl_OfcKop) OR (pl_CAinKOP AND cIssType="S")
	DO PrintField WITH mv_f, "Loc", "M"
ELSE
**MRC phone 2/15/14
	DO PrintField WITH mv_f, "Loc", IIF(pc_Litcode="ZOL", "G", c_offlocation)
ENDIF

c_sql=""
c_sql= "select dbo.fn_GetID_tblRequest  ('" +fixquote(pc_clcode) + "','" + STR(nTagNum) + "')"
o_LETTER.sqlexecute(c_sql, "ReqId")
IF !EMPTY(NVL(ReqId.EXP,""))
	c_sql=""
	c_sql = "select [dbo].[getLastTxn51] ('" + ReqId.EXP + "')"
	l_ok= o_LETTER.sqlexecute (c_sql,"HoldDate")

	IF l_ok AND NOT EOF()
		IF EMPTY(NVL(ld_HDate,""))
			ld_HDate=CTOD(LEFT(DTOC(DATE()),10))
		ENDIF
		ld_HDate=CTOD(LEFT(DTOC(HoldDate.EXP),10))

	ENDIF
ENDIF

IF pd_duedate<ld_HDate
	c_caption ="Past Due"
ELSE
	c_caption= "Follow Up"
ENDIF
DO PrintField WITH mv_f, "CapVar" , c_caption
**12/27/2011- added autofax caption
**06/07/2012- International caption
o_LETTER.closealias("notUS")
o_LETTER.sqlexecute("select [dbo].[getDepCategory] ('"  + fixquote(ALLTRIM(pc_clcode))+"', '"+ALLTRIM(STR(nTagNum))+"')" ,"NotUS")
IF NVL(NotUS.EXP,'')='I' AND  pc_OFFCODE='P'
	c_xtra="International Address"
ELSE
	c_xtra=""
ENDIF


DO PrintField WITH mv_f, "CapAFax" , c_xtra
DO PrintField WITH mv_f, "IssueDate" , DTOC(pd_MailDte)
DO PrintField WITH mv_f, "DueDate" , DTOC(pd_duedate)
c_faxnum = 	TRANSFORM( ALLTRIM(pc_depofile.fax_no), "@R (999)999-9999")
DO PrintField WITH mv_f , "DeponentFax", c_faxnum
DO PrintField WITH mv_f, "RequestCode", IIF(cIssType="S", "SUBP", "AUTH")
**10/04/2011- added usedverb
DO PrintField WITH mv_f, "UsedVerb", IIF(cIssType="S", "SUBP", "AUTH")
DO PrintField WITH mv_f, "Info", TheInfo
DO PrintGroup WITH mv_f, "Control"
DO PrintField WITH mv_f, "Date", DTOC( DATE())
DO PrintField WITH mv_f, "LrsNo", pc_lrsno
DO PrintField WITH mv_f, "Tag", STR( nTagNum)

DO PrintGroup WITH mv_f, "Deponent"
*DO PrintField WITH mv_f, "Name", cdeponent

**05/21/2012- print deponent's name on a KOP cover page insted of txn 11 line ( per Alec)
c_sql="select dbo.GetDeptCode2('" +fixquote(pc_clcode) +"',"+ALLTRIM(STR(nTagNum))+") as deptcode"
o_LETTER.sqlexecute(c_sql, "Dept")
c_addition= getdescript(NVL(Dept.deptcode,'Z'))
c_dep=DepToPrint ( ALLTRIM(NVL(pc_depofile.NAME,cdeponent)))


DO PrintField WITH mv_f, "Name", c_dep + IIF(pc_deptype = "H" AND NOT pl_CaVer ,"",c_addition)
**05/21/2012- print deponent's name on a KOP cover page insted of txn 11 line ( per Alec)



DO PrintField WITH mv_f, "Addr", ;
	IIF(EMPTY(pc_depofile.add2), pc_depofile.add1, pc_depofile.add1 + CHR(13) + pc_depofile.add2)
DO PrintField WITH mv_f, "City", pc_depofile.city
DO PrintField WITH mv_f, "State", pc_depofile.state

DO PrintField WITH mv_f, "Zip", IIF(ALLTRIM(pc_depofile.zip)='00000','', ALLTRIM(pc_depofile.zip))
DO PrintField WITH mv_f, "Extra", IIF(ISNULL(szattn),"",szattn)

DO PrintGroup WITH mv_f, "Plaintiff"
DO PrintField WITH mv_f, "FirstName", remnonasci(pc_plnam)
DO PrintField WITH mv_f, "MidInitial", ""
DO PrintField WITH mv_f, "LastName", ""
DO PrintField WITH mv_f, "Addr1", remnonasci(pc_pladdr1)
DO PrintField WITH mv_f, "Addr2", remnonasci(pc_pladdr2)
IF TYPE('pd_pldob')<>"C"
	pd_pldob=DTOC(pd_pldob)
ENDIF
IF TYPE('pd_pldod')<>"C"
	pd_pldod=DTOC(pd_pldod)
ENDIF

DO PrintField WITH mv_f, "BirthDate", LEFT(pd_pldob,10)
DO PrintField WITH mv_f, "SSN", ALLT( pc_plssn)
DO PrintField WITH mv_f, "DeathDate",  LEFT(pd_pldod,10)
DO PrintField WITH mv_f, "Extra", IIF(NOT EMPTY(pc_maiden1)  ,   "A.K.A.: " + TRIM( pc_maiden1), "")

IF NOT EMPTY(c_Save)
	SELECT (c_Save)
ENDIF
RELEASE o_LETTER
WAIT CLEAR
RETURN mv_f


*****************************************************************************************************
PROCEDURE genFollowUp
PARAMETERS n_lrsno, tagreq, l_updauth
LOCAL  l_got11 AS Boolean, n_Opt AS INTEGER, l_Canc2Fax AS Boolean, l_GetPOS AS Boolean, c_grname AS STRING, l_continue AS Boolean, lcRequest
STORE .F. TO pl_PdfReprint,  l_got11, l_Fax1Req , l_PrtFax,  l_Fax2Req, l_Canc2Fax, l_GetPOS, pl_CANotc
l_Prt2Req=.T. && 11/10/09- DEFAULT IS PRINT A 2ND REQUEST
pl_PrtOrigSubp=.F.
pl_2ndQue=.T.
PL_STOPPRTISS=.F.
pl_1st_Req=.F.
PRIVATE  c_fax AS STRING, c_faxnum1 AS STRING,c_pickdept AS STRING, c_POSStatus AS STRING
STORE "" TO c_fax, c_faxnum1, PC_ISSTYPE,c_pickdept, c_POSStatus
LOCAL ots2 AS medtimesheet OF timesheet
ots2 = CREATEOBJECT("medtimesheet")
n_Opt=0
STORE "" TO szfaxnum, MCLASS, c_grname, c_queue

*02/26/2018 - MD # 75726/78152  ------------------------------
If Type( "mvScanDocsOnly")="U"
	Public mvScanDocsOnly
ENDIF
mvScanDocsOnly=""

LOCAL scanDocsOnly
scanDocsOnly=0
ots2.closealias("SDCheck")
ots2.sqlexecute("select dbo.ChkScanDocsOnly ('" +STR(n_lrsno )+ "','" + STR(tagreq) + "')","SDCheck")
IF USED("SDCheck")
	scanDocsOnly=NVL(VAL(ALLTRIM(SDCheck.EXP)),0)
ENDIF 
ots2.closealias("SDCheck")	
*-------------------------------------------------------

************************************************************************************************

&&3/18/2013 	 Check if a rps job printed already for HOLD Requests	-start:		"HoldPrint" Project.
IF checktest("HOLD_PRINT2")=.F.	 AND pc_OFFCODE='P' &&and pc_RpsForm="KOPGeneric" && 07/16/13
*IF !INLIST(ALLTRIM(goApp.CurrentUser.ntlogin) ,"ELLEN")
	LOCAL ld_MAIL AS DATETIME, n_spec AS INTEGER
	ld_MAIL=PD_REQMAIL
	n_spec=0
	ots2.closealias("HoldJob")
	ots2.sqlexecute("select dbo.ChkRpsHoldQueue ('" +STR(n_lrsno )+ "','" + STR(tagreq) + "')","HoldJob")
	IF USED('HoldJob')
		n_spec=NVL(HoldJob.EXP,0)
	ENDIF



	IF n_spec>0
		IF NVL(pd_RpsPrint,DATE())>DATE()
			gfmessage('Cannot do a Follow-up for RT# ' +ALLTRIM(STR(n_lrsno))  + ' and Tag# '+ ALLTRIM(STR(tagreq)) + '. The First Request is on Hold till '+  DTOC(NVL(ld_MAIL,DATE()) ) +'.')
			RETURN
		ENDIF
	ENDIF
ENDIF
&&3/18/2013 	 Check if a rps has a job in a queue  that is set to be printer today	-end
************************************************************************************************

IF NOT l_updauth
&&2/5/15 : stop using  followup with pdfs
*!*		pl_PdfReprint=IIF (pl_EditReq, .F., getpdffile (n_lrsno, tagreq))
**show a form when user wants to reprint an existing PDF request
*!*		IF pl_PdfReprint AND NOT pl_EditReq
*!*			n_Opt=GOAPP.OpenForm("Issued.frmreprintpdf", "M", MASTER.id_tblMAster,MASTER.id_tblMAster,REQUEST.id_tblrequests, .T.)
*!*			IF NVL(n_Opt,0)=0 THEN
*!*				gfmessage("Cancel Follow-Up Request.")
*!*				RETURN
*!*			ENDIF
*!*			DO CASE
*!*			CASE n_Opt=1
*!*				l_Prt2Req=.T.
*!*				l_Fax2Req=.F.
*!*			CASE n_Opt=2
*!*				l_Prt2Req=.F.
*!*				l_Fax2Req=.T.
*!*			ENDCASE
*!*		ELSE
*!*			IF NOT pl_EditReq
*!*				WAIT WINDOW "No PDF file to view. " NOWAIT
*!*			ENDIF
*!*		ENDIF
ELSE
***upadte authorization : does not need to cheCk for pdf
	pl_PdfReprint=.F.
	pl_EditReq=.T.
ENDIF

****TXN11
_SCREEN.MOUSEPOINTER=11
l_got11=ots2.sqlexecute(" exec dbo.GetTxn11Line '" + fixquote(pc_clcode)+ "','" + STR(tagreq ) + "'" ,"Timesheet")

IF NOT l_got11 OR EOF()
	RETURN
ENDIF
IF NOT EMPTY(timesheet.id_tbltimesheet)
	ots2.getitem(timesheet.id_tbltimesheet)
	SELECT timesheet
	PC_ISSTYPE=ALLTRIM(timesheet.TYPE)
	IF EMPTY(NVL(PC_ISSTYPE,''))
		PC_ISSTYPE=REQUEST.TYPE
	ENDIF
ENDIF



** 04/25/12 - START: wcab subp need a scanned imageas "S"  or "B" tag level file found
IF (pl_wcabkop AND PC_ISSTYPE="S") AND NOT wcabimg(pc_lrsno,tagreq)
	gfmessage( "Please note that there is no scanned WCAB SUBPOENA file for a tag #." + ALLTRIM(STR(tagreq)) + "." )


ENDIF
* 04/25/12 -END: wcab subp need a scanned imageas "S"  or "B" tag level file found
********LATEST SPEC INST
IF USED("Spec_ins")
	SELECT Spec_ins
	USE
ENDIF
ots2.sqlexecute("Exec [dbo].[GetTheLatestBlurb] '" + timesheet.CL_code + "',' " + STR(tagreq) + "'", "Spec_ins")

********DEPONENT'S DATA
IF USED("pc_DepoFile")
	SELECT pc_depofile
	USE
ENDIF


IF   UPPER( LEFT( timesheet.MAILID_NO, 1))="H"
	c_pickdept= NVL(Spec_ins.Dept,"Z")
ELSE
	c_pickdept="Z"
ENDIF
WAIT WINDOW "Getting Deponent's information" NOWAIT
l_mail=ots2.sqlexecute("exec dbo.GetDepInfoByMailIdDept  '" + timesheet.MAILID_NO +"','" + c_pickdept + "' ", "pc_DepoFile")

=CURSORSETPROP("KeyFieldList", "Code, id_tbldeponents", "pc_DepoFile")

SELECT pc_depofile
IF EOF()
	WAIT WINDOW "No Deponent's information has been found."
	RETURN
ENDIF

*DO DeptInfo
_SCREEN.MOUSEPOINTER=0
pl_Mail=.F.
DO gfDepInf WITH c_pickdept

** 06/01/2018 MD move variable settings out of IF statements
*----------------------------------------------
IF TYPE ('MCLASS')='U'
	PUBLIC MCLASS
	*MCLASS=""
ENDIF
MCLASS=""
IF TYPE ('MV')='U'
	PUBLIC mv
	*mv=""
ENDIF
mv=""
IF TYPE( "mgroup")="U"
	PUBLIC mgroup
	*mgroup = "1"
ENDIF
mgroup = "1"
*----------------------------------------------
**01/13/2010 - Reset l_Prt2Req to false If a valid fax number exists
IF LEN(ALLTRIM(pc_depofile.fax_no))=10 AND NOT INLIST(ALLTRIM(pc_depofile.fax_no),'1111111111','2222222222','3333333333','4444444444','5555555555','6666666666','7777777777','8888888888','9999999999','0000000000')
	l_Prt2Req=.F.
ENDIF

SET PROCEDURE TO ta_lib ADDITIVE
*IF NOT pl_EditReq
IF LEN(ALLTRIM(pc_depofile.fax_no))=10 AND NOT l_Prt2Req
*!*	**fax cover page
	lc_message = "Do you want to print a Fax Cover Sheet?"
	o_message = CREATEOBJECT('rts_message_yes_no',lc_message)
	o_message.SHOW
	l_Confirm=IIF(o_message.exit_mode="YES",.T.,.F.)
	o_message.RELEASE
	IF l_Confirm
		l_Fax2Req=.T.
		l_Prt2Req=.F.
		l_Canc2Fax= FAX2REQST (tagreq)
	ELSE
		l_Canc2Fax=.T.
		l_Fax2Req=.F.
		l_Prt2Req=.T.
	ENDIF
	IF l_Canc2Fax && CANCEL FAX so PRINT INSTEAD
		l_Fax2Req=.F.
		l_Prt2Req=.T.
	ENDIF

ELSE &&05/18/20210 - invalid fax #
	l_Prt2Req=.T.
ENDIF


*ENDIF &&NOT pl_EditReq

IF l_Prt2Req && if fax was canceled or the fax# does not exist ASK ABOUT SPEC HANDLING
	l_spechand = .F.
	IF (NOT l_Fax2Req   )
	
		l_Confirm=gfmessage("Do you want to add a Special Handling Instruction?",.T.)
		
		IF l_Confirm
			l_spechand = .T.
			DO SpecHand	IN subp_pa
		ENDIF
	ENDIF
	l_Fax2Req=.F.
	l_Prt2Req=.T.
	l_Canc2Fax=.T.
ENDIF




gnHold = IIF( pl_nohold, 0, pn_c1Hold)
SELECT COURT
C_ORDER =ORDER()
IF EMPTY(ALLTRIM(C_ORDER))
	SET ORDER TO COURT
ENDIF
lnComply = IIF( SEEK( PC_COURT1), gnHold + comply, 10)
mcounty = pc_c1Cnty
gnFRDays = pn_litfday
gnIssDays = pn_litiday
llFromRev = IIF (gnFRDays<>0, .T.,.F.)
mcourt = PC_COURT1
mcourt2 = pc_Court2
bNotcall=.F.
c_Action =IIF( PC_ISSTYPE="S","7","8")
b1streq=2
gdBlankDt={  /  /    }
bNotcall =.F.
l_continue=.T.
pn_RpsMerge=0
&&2/5/15 : stop using  followup with pdfs


DO CASE
**1) Orig?-Yes, Edit Blurb?- No
*!*	CASE pl_PdfReprint  AND NOT pl_EditReq
*!*		DO TXN44_2RQ WITH  ALLT(timesheet.DESCRIPT), timesheet.CL_code, 44, tagreq, pc_mailid, PC_ISSTYPE, pc_UserID,	REQUEST.id_tblrequests, NVL(Spec_ins.Dept,"Z"), .F. &&IIF(pl_EditReq, .t.,.f.)
*!*		DO reppdfreq WITH n_lrsno, tagreq, .F. , PC_ISSTYPE, CTOD(timesheet.Txn_date), NVL(Spec_ins.Dept,"Z"), UPPER(ALLT(timesheet.DESCRIPT))
**2) Orig?-No, Edit Blurb?- No
CASE NOT pl_PdfReprint  AND NOT pl_EditReq
*----a) check for the rps spec id on txn 11 and 44, whatever is latest
	LOCAL n_RpsId AS INTEGER
	n_RpsId=0
	ots2.closealias("RpsId")
	c_sql="Select dbo.JobSpecTxn11and44 ('" + fixquote(timesheet.CL_code) + "','" + STR(tagreq)+ "')"
	ots2.sqlexecute(c_sql,"RpsId")
	IF USED("RpsId")
		SELECT RpsId
		IF NOT EOF()
			n_RpsId=NVL(RpsId.EXP,0)
		ENDIF
	ENDIF
	IF n_RpsId>0
		pn_RpsMerge=n_RpsId
		DO reppdfreq WITH n_lrsno, tagreq, .F. , PC_ISSTYPE, CTOD(timesheet.Txn_date), NVL(Spec_ins.Dept,"Z"), UPPER(ALLT(timesheet.DESCRIPT))
**add txn 44 and attach a followup letter to an existing rps
		DO TXN44_2RQ WITH  ALLT(timesheet.DESCRIPT), timesheet.CL_code, 44, tagreq, pc_mailid, PC_ISSTYPE,  "(F)" + ALLTRIM(pc_UserID),	REQUEST.id_tblrequests, NVL(Spec_ins.Dept,"Z"), .F. &&IIF(pl_EditReq, .t.,.f.)
	ELSE


*-------------------------
		n_revision=1
		DO reppdfreq WITH n_lrsno, tagreq, .F. , PC_ISSTYPE, CTOD(timesheet.Txn_date), NVL(Spec_ins.Dept,"Z"), UPPER(ALLT(timesheet.DESCRIPT))
		DO TXN44_2RQ WITH  ALLT(timesheet.DESCRIPT), timesheet.CL_code, 44, tagreq, pc_mailid, PC_ISSTYPE, ALLTRIM(pc_UserID),	REQUEST.id_tblrequests, NVL(Spec_ins.Dept,"Z"), .F. &&IIF(pl_EditReq, .t.,.f.)
		l_continue= PrintReqst ( .F., n_revision, tagreq, UPPER(ALLT(timesheet.DESCRIPT)))
		IF ! l_continue && 7/16/ 14 delete txn 44
			ots2.sqlexecute("Exec [dbo].[deleteLatestCode44]  '" + fixquote(timesheet.CL_code )+ "',' " + STR(tagreq) + "','" +ALLTRIM(pc_UserID) +"'" )

		ENDIF
	ENDIF
**3)  Edit Blurb?- yes - does not matter if a pdf exists or not
CASE  pl_EditReq    &&l_updauth follows that path as well
*!*	***05/25/2011 - new or old BB set- DO NOT ALLOW to print an old set after a new signature had been released

**6/13/13- Tag's Rq Atty
	pl_GotCase=.F.
	DO gfgetcas
**6/13/13- Tag's Rq Atty


	IF pl_BBCase  AND PC_ISSTYPE="S"&&BBCASE
		ots2.closealias("MailDate")
		LOCAL l_oldbbset AS Boolean, d_MailDte2 AS DATE, n_bbset AS INTEGER
		l_oldbbset=.F.
		n_bbset =3 && default is the latest bb set
		c_sql = " SELECT [dbo].[GetTagMailDate] ('" +fixquote(pc_clcode) + "','" +STR(tagreq) +"')"
		ots2.sqlexecute (c_sql,"MailDate")
		IF  NOT EOF()
			d_MailDte2=CTOD(LEFT(DTOC(MailDate.EXP),10))
		ELSE
			d_MailDte2=CTOD(timesheet.Txn_date)
		ENDIF
		ots2.closealias("BBsign")
*c_sql="Select dbo.NewBBSignature ('" + DTOC(d_MailDte2) + "')"
**06/05/2015- added 3rd BB set
		c_sql="Select dbo.GetBBSignatureSet ('" + DTOC(d_MailDte2) + "')"
		ots2.sqlexecute(c_sql,"BBsign")
		IF USED("BBsign")
			SELECT BBsign
			IF NOT EOF()
				n_bbset=NVL(BBsign.EXP,0)
			ENDIF

		ENDIF
		IF n_bbset<3
			gfmessage("Cannot do a Follow-Up Request. An original subpoena was signed by " + IIF( n_bbset=1, "LEONARDO J. VACCHINA", "PETER GILBERT" ) + " , who has retired." + CHR(13) + "Either use a stored PDF request or generate a new one. Thank you.")
			_SCREEN.MOUSEPOINTER=0
			RETURN

		ENDIF
	ENDIF && BBCASE 5/25/2011 -end
	n_revision=2
	bNotcall=.F.
	l_autosub=.F.
	l_autocov=.T.


**5/26/15 - STOP FAXING MD SUBPS PER LIZ

	l_retval= Edit2Req ( n_lrsno, tagreq,  NVL(Spec_ins.Dept,"Z"),IIF( pc_c1Name = "MD-BaltimoCity" AND PC_ISSTYPE="S", .T.,l_Fax2Req))
	IF NOT l_retval && NOT CANCELED
***Add txn 44 and a spec inst record
		IF TYPE("pc_userid")<>"C"
			pc_UserID="RepPdfPrg"
		ENDIF

		IF USED("Spec_ins")
			SELECT Spec_ins
			USE
		ENDIF
********LATEST SPEC INST
**01/11/2012 -ADDED TXN 44 BACK WITH AN EDITED BLURB
		ots2.closealias("SPECDEPT")
		c_sql = " SELECT [dbo].[GetDeptCode2] ('" +fixquote(pc_clcode) + "','" +STR(tagreq) +"')"
		ots2.sqlexecute (c_sql,"SPECDEPT")


&&05/02/14- Zoloft followup with no pdf needs all MRC docs -start
		IF pc_Litcode ='ZOL' AND pl_ZOLMDL
			IF pl_EditReq AND !pl_PdfReprint

				pl_MRCLetter= IIF (l_updauth,.F.,.T.)

**06/03/14- check if previous follow up was with updated auths   (UpdAuthDone set to 1 in tblMRCTags)-start
				ots2.closealias("MRCTags")
				c_sql = " SELECT [dbo].[ReturnMRCPrint]  ('" +pc_lrsno+ "','" +STR(tagreq) +"')"
				ots2.sqlexecute (c_sql,"MRCTags")
				IF USED("MRCTags")
					l_exist=.F.  && follow up with updated auth was not done - default
					SELECT MRCTags
					IF NOT EOF()
						l_exist= NVL(MRCTags.EXP,.F.)
						pl_MRCLetter = IIF(l_exist,.F.,pl_MRCLetter )
					ENDIF
				ENDIF


**06/03/14- check if previous follow up was with updated auths   (UpdAuthDone set to 1 in tblMRCTags)-start
			ELSE
				pl_MRCLetter=.F.
			ENDIF
		ELSE
			pl_MRCLetter=.F.
		ENDIF
&&05/02/14- Zoloft followup with no pdf needs all MRC docs -END


		DO TXN44_2RQ WITH  ALLT(timesheet.DESCRIPT), timesheet.CL_code, 44, tagreq, pc_mailid, PC_ISSTYPE, ALLTRIM(pc_UserID),	REQUEST.id_tblrequests, NVL(SPECDEPT.EXP,"Z"), IIF(pl_EditReq, .T.,.F.)
		SELECT timesheet	&& 12/20/18 YS #122685		
		ots2.sqlexecute("Exec [dbo].[GetTheLatestBlurb] '" + fixquote(timesheet.CL_code) + "',' " + STR(tagreq) + "'", "Spec_ins")
&&2/5/15 : stop using  followup with pdfs
*!*			l_continue= PrintReqst ( IIF(pl_EditReq,.F., pl_PdfReprint), n_revision, tagreq, UPPER(ALLT(timesheet.DESCRIPT)))
		l_continue= PrintReqst ( IIF(pl_EditReq,.F., .F.), n_revision, tagreq, UPPER(ALLT(timesheet.DESCRIPT)))
		IF !l_continue && delete txn44 and blurb 7/16/14
			ots2.sqlexecute("Exec [dbo].[deleteLatestCode44]  '" +fixquote( timesheet.CL_code )+ "',' " + STR(tagreq) + "','" +ALLTRIM(pc_UserID) +"'" )
		ENDIF

**06/03/14- store a follow up with updated auths for mrc future follow ups  (UpdAuthDone set to 1 in tblMRCTags)-start
		IF l_updauth AND pl_ZOLMDL
			c_sql = " exec [dbo].[StoreMRCPrint] '" +pc_lrsno + "','" +STR(tagreq) +"' "
			ots2.sqlexecute (c_sql)
		ENDIF
**06/03/14- store a follow up with updated auths for mrc future follow ups  (UpdAuthDone set to 1 in tblMRCTags)-end

	ELSE
		RETURN
	ENDIF


	IF EMPTY(ALLTRIM(mv)) && zol ADDITION 2/5/14
		RETURN
	ENDIF  && zol ADDITION 2/5/14


ENDCASE
IF EMPTY(MCLASS) OR ALLTRIM(MCLASS)="SPC"
	DO queueclass WITH l_Fax2Req ,l_Prt2Req , ALLTRIM(GOAPP.userdepartment)
ENDIF


&&11/18/14- USDC SUBPS GET A SEPARATE RPS PRINT CLASS-START
&&2/5/15 : stop using  followup with pdfs

IF   PL_KOPVER AND (LEFT( ALLTRIM(PC_COURT1), 4) = "USDC" AND PC_ISSTYPE='S' ) AND   l_Prt2Req
	MCLASS="SecondCiv"
*!*		MCLASS=IIF (pl_PdfReprint, 'SecCivFromPdf', "SecondCiv")
ENDIF


&&11/18/14- USDC SUBPS GET A SEPARATE RPS PRINT CLASS-END


SET SAFETY OFF
**01/18/10- get rps by a dept's category -start
pc_BatchRq=""
pl_SpecRpsSrv=.F.
** 6/7/12 -added international requests to that RPS + 3/7/16 added Corp Pharm #34447
ots2.closealias("RpsGov")
ots2.sqlexecute("select [dbo].[getDepCategory] ('"  + fixquote(ALLTRIM(pc_clcode))+"', '"+ALLTRIM(STR(tagreq))+"')" ,"RPSGov")
IF INLIST(NVL(RPSGov.EXP,''),'G','I','P') AND  pc_OFFCODE='P'

	MCLASS= "RpsGov"
ENDIF

IF pc_OFFCODE="P" AND MCLASS<> "RpsGov"
	l_ok=ots2.sqlexecute("SELECT dbo.GetRpsQueueNamebyDept ('" + pc_mailid + "','" + NVL(Spec_ins.Dept,"Z")+ "','" + pc_OFFCODE +"')", "RpsQ")
	IF l_ok
		pl_SpecRpsSrv=NVL(RpsQ.EXP,.F.)
		pc_BatchRq=IIF(pl_SpecRpsSrv,"RpsBatch","")

	ENDIF
ENDIF
**01/18/10- get rps by a dept's category -end


DO CASE
CASE !EMPTY(NVL(pc_BatchRq,""))
	c_queue=pc_BatchRq
OTHERWISE
	c_queue=MCLASS
ENDCASE


c_grname=mgroup
&&03/23/2016 removed  OMRPage #36180
&&07/13/2012 OMRPAGE only for a brand new requests (a ones with attached Pdf will have that page as a part of pdf)(removed OMRPAGe -End-802 from rpswork..tblDocstoStrip)
*!*	IF pl_EditReq
*!*	*01/17/2013  added it to the IL-cookcounty subps
*!*		LOCAL  l_addomr AS Boolean
*!*		l_addomr=.F.
*!*		l_addomr=addomrpage ( PC_ISSTYPE, l_Fax2Req )

*!*		IF  l_addomr
*!*			DO OmrPage
*!*		ENDIF

*!*	ENDIF
&&03/23/2016 removed  OMRPage #36180

*--------------------------------------------------------------
* 02/22/2018 MD #78152 replace rps stream with scanned docs only
IF scanDocsOnly=1
    LOCAL sdClCode, sdTag, sdIssueType,sdPrintAll, sdReqDept, sdReqDescript, sdHiTech
    sdClCode=pc_clcode
    sdTag=tagreq
    SDIssueType=PC_ISSTYPE
    sdPrintAll=1
    sdReqDept=NVL(Spec_ins.Dept,"Z")
    sdReqDescript=ALLTRIM(fixquote(NVL(timesheet.descript,"")))
    SELECT 0
    * -- 01/08/2020 MD #157507 Get the data as the record table is not always opened
    ots2.CLOSEalias("viewHiTechCode")
    ots2.sqlexecute("select hitech from tblrequest where cl_code='" + fixquote(timesheet.cl_code) + "' and tag=" + STR(tagreq) + " and active=1", "viewHiTechCode")
    sdHiTech=ALLTRIM(NVL(viewHiTechCode.hitech,"0"))
    ots2.CLOSEalias("viewHiTechCode")
    *-- 12/11/2019 #146658 MD added sdReqDept, sdReqDescript, sdHiTech
	DO printScannedDocs WITH sdClCode, sdTag, sdIssueType,sdPrintAll,sdReqDept,sdReqDescript,sdHiTech
ENDIF 
*--------------------------------------------------------------
DO prtenqa WITH mv,  c_queue, c_grname, IIF( l_Fax2Req, ALLTRIM( szfaxnum), "")
DO RetProc IN subp_pa
IF l_continue
	gfmessage("A Follow-Up request has been generated.")
ELSE
	gfmessage("A Follow-Up request has NOT been generated.")

ENDIF

RELEASE ots2
pc_CertTyp = ""
pn_RpsMerge=0
IF USED('pc_DepoFile')
	SELECT pc_depofile
	USE
ENDIF

RETURN


******************************************************************************************
PROCEDURE DeptInfo
**07/16/12 -attention line modifications
LOCAL  c_DepAttn AS STRING


IF LEFT(timesheet.MAILID_NO ,1)="H"
	DO CASE
	CASE "(CATH)" $ UPPER(ALLT(timesheet.DESCRIPT))
		c_deptype = "C"

	CASE "(ECHO)" $ UPPER(ALLT(timesheet.DESCRIPT))
		c_deptype = "E"

	CASE "(RAD)" $ UPPER(ALLT(timesheet.DESCRIPT))
		c_deptype= "R"

	CASE "(PATH)" $ UPPER(ALLT(timesheet.DESCRIPT))
		c_deptype = "P"

	CASE "(BILL)" $ UPPER(ALLT(timesheet.DESCRIPT)) OR ;
			"(BILLING)" $ UPPER(ALLT(timesheet.DESCRIPT))
		c_deptype = "B"

	CASE "(MED)" $ UPPER(ALLT(timesheet.DESCRIPT))
		c_deptype= "M"

	OTHERWISE
		c_deptype = "Z"

	ENDCASE
ELSE
	c_deptype = "Z"


ENDIF




RETURN  c_deptyp
**********************************************************************
PROCEDURE DepInfoLetter
PARAMETERS c_dept
LOCAL c_attn2 AS STRING
STORE "" TO c_attn2, c_attn
IF pc_deptype = "H" 
	IF NOT EMPTY(c_dept)
** This is filled in only if hospital!!
		DO CASE
		CASE c_dept == "E"
			c_attn = "ECHOCARDIOGRAM"
			STORE  "ECHO" TO TheInfo, TheInfo2
		CASE c_dept == "R"
			c_attn = "RADIOLOGY"
			STORE  "RAD" TO TheInfo, TheInfo2
		CASE c_dept == "P"
			c_attn = "PATHOLOGY"
			STORE  "PATH" TO TheInfo, TheInfo2
		CASE c_dept == "B"
			c_attn =  "BILLING"
			STORE  "BILLS" TO TheInfo, TheInfo2
		CASE c_dept == "C"
			c_attn =  "CARDIAC CATHS"
			STORE  "CATH" TO TheInfo, TheInfo2
		OTHERWISE
			c_attn = "MEDICAL RECORDS"
			STORE  "MED" TO TheInfo, TheInfo2
		ENDCASE
		c_attn2 = "ATTN: " + c_attn + " DEPARTMENT"
	ELSE
		c_attn2 = ""
		STORE  "MED" TO TheInfo, TheInfo2
	ENDIF                                        && not empty cdept
ELSE
	TheInfo = "OTHER"
	TheInfo2 = "MED"
ENDIF                                           && pc_deptype = H

&&07/16/12-ATTENTION LINE FROM ROLODEX
IF TYPE("pc_MAttn")<>"C"
	pc_MAttn=""
ENDIF 
szattn=IIF(EMPTY(ALLTRIM(pc_MAttn)),c_attn2 , ALLTRIM(UPPER(pc_MAttn)))

RETURN

