*****************************************************************************
* PrintCan.PRG Print cancel letter
*   Calling parameters:
*      1-2) client code and tag of deponent being cancelled
*         3) automatic flag -- .T. if a batch cancel is in process
*                                     (called from CaseFlt2)
*                              .F. if this is a manual, one-deponent cancel
*                                     (all other calls)
*
*   Called from programs Depopts, CaseFlt2, CashLog, OrdCancl
*   Called from screens Covlet, NewCover, BBCovLet
*
* History :
* Date      Name  Comment
* 01/18/10  EF  Get rps by a dept's category
* 12/04/07  EF  Added Acdamnumber
* 04/24/07  EF  Added Rpslitdata
* 04/09/07  EF  Added a new phone for Propulsid
* 03/19/07  EF  Added a new phone for the SRQ lit cases.
* 10/10/06  EF  Renamed the prtEnqa to prtEnq_2 in Global.prg
* 11/28/05  kdl	Modified to work in converted system
* ---------------------------------------------------------------------------
*****************************************************************************
*
**************************************************************************************
* plZDontAskPrintQuestion is set to .T. in the function that called printcan.prg if you
* know that the user has selected to print a cancellation so the question is not necessary.
* plZDontAskQuestion can also be set to false which has the same effect as plZDontAskPrintQuestion
* being undefined.  The only difference is that plZDontAskPrintQuestion will be returned with a
* .T. to indicate that the question has been asked.
* This variable can also be set if you are doing a group cancel and you only want the question
* to be asked the first time.  After the first call to printcan this variable would be created and
* set.  PlZPrintWasSelected will indicate that the individual has chosen to print or not print a
* cancellation letter.  You need to initialize this variable in the procedure calling printcan.
* Ex: transactions.frmcovlet.cmdPrintCanclLetter
***************************************************************************************
*
PARAMETER lcClient, lnTag, llAuto, lFaxLtr
LOCAL lcAlias, llRecord, lcTxn, ldTxn7, c_key, lcExact, L_TXN19
IF PCOUNT() < 3
	llAuto = .F.
ENDIF
o = CREATEOBJECT("generic.medgeneric")
*---------------------------------------------------------------------------------------------
* 11 11/26/2018 MD #
*!*	&&09/24/15: allow a letter if txn 19 is not alone but follows with txn 11
*!*	o.closealias('Issuedby')
*!*	o.sqlexecute("select dbo.IssuedBY ('" +FIXQUOTE(lcClient)+"', '"+ALLTRIM(STR(lnTag))+"')", "Issuedby")

*!*	IF USED('Issuedby')
*!*		SELECT Issuedby
*!*		IF !EMPTY(ALLTRIM(Issuedby.EXP))
*!*			plZPrintWasSelected = .T.
*!*		ELSE
*!*	&&11/07/14 - ALLOW CANCEL FOR TXN 19's TAGS BUT NO LETTER SHODUL BE DONE PER ALEC/LIZ
*!*			L_TXN19=.F.
*!*			L_TXN19=ChkTxn19(lcClient ,lnTag)
*!*			IF L_TXN19
*!*				plZPrintWasSelected=.F.
*!*				RETURN
*!*			ENDIF
*!*	&&11/07/14 - ALLOW CANCEL FOR TXN 19's TAGS BUT NO LETTER SHODUL BE DONE

*!*		ENDIF

*!*	ENDIF
*---------------------------------------------------------------------------------------------
*-- Do not print cancelation lettter if there is txn19 without txn11
		L_TXN19=ChkTxn19(lcClient ,lnTag)
		IF L_TXN19		  
		    *-- check if there is txn11  
		    o.closealias('Issuedby')
			o.sqlexecute("select dbo.IssuedBY ('" +FIXQUOTE(lcClient)+"', '"+ALLTRIM(STR(lnTag))+"')", "Issuedby")
			IF USED('Issuedby')
				SELECT Issuedby
				IF EMPTY(ALLTRIM(Issuedby.EXP))
				   RETURN 
			    ENDIF 
		    ENDIF
    	ENDIF
*---------------------------------------------------------------------------------------------
pl_UpdHoldReqst=.f.
PL_1ST_REQ=.F.
IF (TYPE("plZDontAskPrintQuestion") = "U" OR ;
		!plZDontAskPrintQuestion)
	plZDontAskPrintQuestion = .T.
	llPrintCancelLetter = lf_yesno("Do you want to print a cancellation letter for this location?")
	plZPrintWasSelected = IIF (!llPrintCancelLetter,.F.,.T.)
ENDIF
IF (TYPE("plZPrintWasSelected") = "U")
	plZPrintWasSelected = .T.
ENDIF
IF (!plZPrintWasSelected)
	WAIT CLEAR
	RETURN
ENDIF
WAIT WINDOW "Preparing Cancellation letter." NOWAIT NOCLEAR
PUBLIC gnWFee, bill
pl_StopPrtIss=.F.

c_key = lcClient + "*" + STR(lnTag)
ldTxn7={ / /   }
lcAlias = ALIAS()
o.sqlexecute("exec dbo.GetCaseDeponentTimesheet '"+FIXQUOTE(lcClient)+"', '"+ALLTRIM(STR(lnTag))+"'", "TimeSheet")
SELECT TimeSheet
SCAN WHILE TimeSheet.cl_code = lcClient AND TimeSheet.TAG = lnTag
	IF TimeSheet.txn_code=7
		ldTxn7=TimeSheet.txn_date
	ENDIF
ENDSCAN

IF EMPTY(NVL(RECORD.req_date,{}))
	IF NOT llAuto
		=gfMsg("The request letter date is invalid." + CHR(13) +;
			"No cancellation letter will be printed.")
	ELSE
		o.sqlexecute("select dbo.gfcc2lrs('" + FIXQUOTE(lcClient)+ "')", "gfcc2lrs")
		gfmessage( "Request Date invalid for RT #: " + ;
			ALLT(STR(gfcc2lrs.EXP)) + "  Tag: " + ALLT(STR(lnTag)) ;
			+ CHR(13) + "Please cancel manually.")
	ENDIF
ELSE
	o.sqlexecute("exec dbo.getDepInf '"+ALLTRIM(UPPER(RECORD.mailid_no))+"'", "viewDep")
	IF RECCOUNT("viewDep") > 0
		IF "INCORRECT" $ UPPER(comments)
			IF NOT llAuto
				=gfMsg("Incorrect address for this deponent! Cancel letter will not be printed.")
				USE IN viewDep
				RETURN
			ENDIF
		ELSE
			USE IN viewDep


*****10/11/13-START: do not send a letter to  Validated    /          Out of Business and Unconfirmed     /  Unconfirmed
			LOCAL  L_STOP AS Boolean
			L_STOP=.F.
			o.closealias('ChkDepo')

			o.sqlexecute("exec [dbo].[ChkDepoCategoryStatusForCancelLetter] '"+FIXQUOTE(lcClient)+"', '"+ALLTRIM(STR(lnTag))+"'", "ChkDepo")
			IF USED('ChkDepo')
				IF !EOF()
					DO CASE
					CASE ALLTRIM(ChkDepo.category)="O" AND !EMPTY(NVL(ChkDepo.validated,''))
						L_STOP=.T.
						plZPrintWasSelected=.F.
						gfmessage("Cannot send a letter: Mail id marked as [Out of Business].")
					CASE ALLTRIM(ChkDepo.category)="U" AND EMPTY(NVL(ChkDepo.validated,''))
						L_STOP=.T.
						plZPrintWasSelected=.F.
						gfmessage("Cannot send a letter: Mail id is unconfirmed.")
					OTHERWISE
						L_STOP=.F.
					ENDCASE


				ENDIF
			ENDIF
***10/11/13-end
			IF NOT L_STOP
				DO lfPrnCancel WITH ldTxn7
			ENDIF
		ENDIF
	ELSE
		USE IN viewDep
		IF NOT llAuto
			=gfMsg("Invalid mail id:" + ALLTRIM(RECORD.mailid_no) + CHR(13) + ;
				" Client:" + ALLTRIM(RECORD.cl_code) + " Tag:" + ALLTRIM(STR(RECORD.TAG)))
		ELSE
			o.sqlexecute("select dbo.gfcc2lrs('" + FIXQUOTE(lcClient) + "')", "gfcc2lrs")
			gfmessage("Invalid Mail id for RT #: " + ALLT(STR(gfcc2lrs.EXP)) + ;
				"  Tag: " + ALLT(STR(lnTag)) + CHR(13) + "Please cancel manually.")
		ENDIF
	ENDIF
ENDIF

RELEASE o
WAIT CLEAR

RETURN

* ---------------------------------------------------------------------------
* Print cancel letter
* ---------------------------------------------------------------------------
PROCEDURE lfPrnCancel
PARAMETERS ldTxn7

LOCAL lcMailId, n_faxno, c_fax, c_PrintQ, lcLtr, l_continue
LOCAL lcLtr, lcAction, lnWorkArea, lcProcedure , l_rps31 
LOCAL lcDesc, lcAttn, lcAdd1, lcAdd2, lcCity, lcState, lcZip, llSpecIns


STORE RECORD.mailid_no TO lcMailId, pc_MailId
l_rps31=.F.
C_dept = " "

IF SUBSTR(lcMailId, 1, 1) = "H"
	IF NOT llAuto
		PUBLIC lc_dept AS STRING
			&&11/27/2017:  allow to pick the dept that exist in our Rolodex #67478
			lc_dept = validdept(ALLTRIM(lcMailId)	)	
*!*			DO gethospdept.mpr
*!*			IF TYPE("lc_dept")!="C" OR ISNULL(lc_dept)=.T.
*!*				gfmessage("Please pick a Department for your request.")
*!*				llexit=.F.
*!*				DO WHILE  llexit=.F.
*!*					DO gethospdept.mpr
*!*					IF TYPE("lc_dept")="C" AND ISNULL(lc_dept)=.F.
*!*						llexit=.T.
*!*					ENDIF
*!*				ENDDO
*!*			ENDIF
		C_dept=lc_dept
		RELEASE lc_dept
	ELSE
		o.sqlexecute("exec dbo.GetSpec_Ins '"+FIXQUOTE(MASTER.cl_code)+"', '"+ALLTRIM(STR(lnTag))+"'", "Spec_Ins")
		IF RECCOUNT("Spec_Ins")>0
			SCAN WHILE Spec_ins.cl_code == lcClient AND ;
					Spec_ins.TAG = lnTag
				IF !EMPTY(Dept)
					C_dept = Spec_ins.Dept
				ENDIF
			ENDSCAN
		ENDIF
	ENDIF
ENDIF

DO setDeponentInfo WITH C_dept
lcAttn =pc_MAttn
lcAdd1 = pc_MAdd1
lcAdd2 = pc_MAdd2
lcCity = pc_MailCity
lcZip =IIF( ALLTRIM(pc_MailZip)='00000','',pc_MailZip)
lcState = pc_MailSt
lcDesc = RECORD.DESCRIPT

&&gnWFee = NVL(RECORD.wit_fee,0)
gnWFee = 0
c_sql="Select dbo.getWitFeeCustodianOnly('" + FIXQUOTE(ALLTRIM(MASTER.cl_code))+"', "+ALLTRIM(STR(lnTag))+")" 
o.sqlexecute(c_sql,"WFeeCust")
IF USED("WFeeCust")
	SELECT WFeeCust
	IF NOT EOF()
		gnWFee=NVL(WFeeCust.EXP,0)
	ENDIF
ENDIF
o.closealias("WFeeCust")



IF EMPTY(lcAttn)
	lcAttn = SPACE(30)
ENDIF
l_continue=.T.
IF NOT llAuto
	frmPrntCan=CREATEOBJECT("transactions.frmPrintCanInfo")
	frmPrntCan.SHOW
	l_continue=IIF(frmPrntCan.exit_mode='CANCEL',.F.,.T.)
	RELEASE frmPrntCan
ENDIF
IF l_continue
	lcProcedure = SET("Procedure")
	SET PROCEDURE TO GLOBAL ADDITIVE
	lcLtr = ""

	DO lfPrnRps WITH lcLtr, lcDesc, lcAdd1, lcAdd2, ;
		lcCity, lcState, lcZip, lcAttn, gnWFee, ldTxn7

	n_faxno = pn_MailFax


	IF TYPE("n_faxno")="C"
		c_fax= ALLTRIM(n_faxno)
	ELSE
		c_fax= ALLTRIM(STR(n_faxno))
	ENDIF



**EF-10/06/2010 - Do not fax to the invalid fax numbers
	lFaxLtr=IIF(c_fax = "111" OR INLIST(c_fax,'2222222222','3333333333','4444444444','5555555555','6666666666','7777777777','8888888888','9999999999','0000000000'), .F.,lFaxLtr)

	lcExact=SET("Exact")
	SET EXACT OFF
	SET EXACT &lcExact

	gcCl_code =RECORD.cl_code

	IF NOT  lFaxLtr
		c_fax='' &&**EF-03/02/11 - Do not fax to the invalid fax numbers
	ENDIF

	IF LEN(c_fax)=10 AND pl_KoPVer
		c_PrintQ="FaxCancel"
	ELSE
		c_PrintQ="Cancel"
	ENDIF
	
**#57344 - - added government's printer to a mix
	IF pl_KoPVer
		o.closealias("RpsGov")
		o.sqlexecute("select [dbo].[getDepCategory] ('"  + FIXQUOTE(ALLTRIM(MASTER.cl_code))+"', '"+ALLTRIM(STR(lnTag))+"')" ,"RPSGov")
		IF USED("RPSGov")
			IF INLIST(NVL(RPSGov.EXP,''),'G','I', 'P')  AND  pc_offcode='P'
				l_rps31=.T.
			ENDIF
		ENDIF
	ENDIF 
**#57344 - - added government's printer to a mix
		DO PrtEnQ_2 WITH lcLtr, ALLTRIM(c_PrintQ+ IIF(l_rps31,'31','')),  "1", c_fax,MASTER.cl_code,lnTag,pc_userid

	ELSE
		gfmessage('Print cancelled')
	ENDIF
	RETURN
*----------------------------------------------------------------------------
* return valid date string
*----------------------------------------------------------------------------
FUNCTION lfValDate
PARAMETER lcDate
PRIVATE lcValid
IF TYPE("lcDate")="C"
	IF ! EMPTY(CTOD(NVL(lcDate,"")))
		lcValid = DTOC(CTOD(lcDate))
	ELSE
		lcValid = " "
	ENDIF
ENDIF
IF INLIST(TYPE("lcDate"),"D","T")
	IF !EMPTY(NVL(lcDate,{}))
		lcValid = DTOC(lcDate)
	ELSE
		lcValid=""
	ENDIF
ENDIF
RETURN lcValid

*----------------------------------------------------------------------------
* set up common fields in the cancel letter
*----------------------------------------------------------------------------
PROCEDURE lfCommon
PARAMETER lnTag, ldTxn, lcLtr2, ldCanDate
PRIVATE lcName, lcPhone, c_offlocation
c_offlocation=""
*EF 02/28/02 Do not ask for TX checks for $1.00.
IF MASTER.lrs_nocode="T"
	pl_OfcHous=.T.
ENDIF
IF pl_OfcHous AND gnWFee=1
	gnWFee=0
ENDIF
&&09/19/14- do not ask back if the witfee <=$10.00
IF   gnWFee<=10
	gnWFee=0
ENDIF
DO PrintGroup WITH lcLtr2, "CancelLetter" + IIF( gnWFee <> 0, "WF", "")
DO printfield WITH lcLtr2, "Line1", IIF(MASTER.litigation='SRQ',"","This request is being cancelled.")
DO printfield WITH lcLtr2, "Line2", IIF(MASTER.litigation='SRQ',"","For that reason, no additional fees can be accepted.")
DO printfield WITH lcLtr2, "Line3", IIF(MASTER.litigation='SRQ',"The records are currently not needed, but RecordTrak will contact you should the situation change.","")

IF gnWFee <> 0
	DO printfield WITH lcLtr2, "WFee", STR(gnWFee, 6, 2)
	DO printfield WITH lcLtr2, "ReqDate", ldTxn7
ENDIF
DO printfield WITH lcLtr2, "ReqLtrDate", DTOC(NVL(ldTxn,{}))

*!*	DO CASE
*!*	CASE INLIST(MASTER.lrs_nocode, "P", "M", "G")
*!*		l_GetRps= Acdamnumber (pc_amgr_id)
*!*		IF l_GetRps
*!*			c_offlocation= IIF(ISNULL(LitRps.RpsOffCode) OR EMPTY(LitRps.RpsOffCode), 'P', LitRps.RpsOffCode)
*!*		ENDIF

*!*	OTHERWISE
*!*		c_offlocation=MASTER.lrs_nocode
*!*	ENDCASE
**08/21/2017: New ACD Lines #67249
c_offlocation=RpsLoc()
**08/21/2017: New ACD Lines #67249
IF EMPTY(ALLTRIM(c_offlocation))
	c_offlocation=pc_Offcode
ENDIF

DO printfield WITH lcLtr2, "Loc",	c_offlocation


DO PrintGroup WITH lcLtr2, "Plaintiff"
c_fullnam = ALLT( MASTER.Plaintiff)
STORE "" TO c_plfname, c_pllname, c_plminit, c_plgiven
DO gfBrkNam WITH c_fullnam, ;
	c_pllname, c_plfname, c_plminit, c_plgiven
c_plnam = IIF( NOT EMPTY( c_plgiven), c_plgiven + " ", "") ;
	+ c_pllname
DO printfield WITH lcLtr2, "FirstName", ALLT( c_plnam)
DO printfield WITH lcLtr2, "MidInitial", ""
DO printfield WITH lcLtr2, "LastName", ""
DO printfield WITH lcLtr2, "Addr1", ALLTRIM(NVL(MASTER.add1,''))
DO printfield WITH lcLtr2, "Addr2", ALLTRIM(NVL(MASTER.add2,''))
IF EMPTY(NVL(MASTER.soc_sec,''))
	DO printfield WITH lcLtr2, "SSN", ""
ELSE
	DO printfield WITH lcLtr2, "SSN", "###-##-" + RIGHT( ALLT(MASTER.soc_sec), 4) &&ALLTRIM(NVL(MASTER.soc_sec,''))
ENDIF
DO printfield WITH lcLtr2, "BirthDate", lfValDate(NVL(MASTER.brth_date,DTOC({})))
DO printfield WITH lcLtr2, "DeathDate", lfValDate(NVL(MASTER.dth_date,DTOC({})))
DO printfield WITH lcLtr2, "Extra", " "

* --- do not use acc mgr. fixed for cancel letter ---
lcName = "RecordTrak Representative"
 **08/22/2017: New ACD Lines #67249
  ***************************************
   lcPhone1= ACDPhone(pc_offcode ,UPPER(pc_Litcode), UPPER( pc_area) , "")
***************************************

IF !EMPTY(ALLTRIM(   lcPhone1))
	   lcPhone= "1-" +  lcPhone1
ELSE 



DO CASE
CASE MASTER.lrs_nocode="G"
	lcPhone = "1-412-338-6480"
CASE MASTER.lrs_nocode = "M"
	lcPhone ="1-800-220-1291"  &&EF 03/16/04 remove "MD" phone "1-800-845-0413"
CASE MASTER.lrs_nocode = "S"
	lcPhone = "1-626-685-2878"
CASE MASTER.lrs_nocode = "C"
	lcPhone = "1-800-220-3200"
OTHERWISE
	lcPhone = IIF(MASTER.litigation='SRQ',"1-888-801-7649","1-800-220-1291")
ENDCASE

endif


DO PrintGroup WITH lcLtr2,"Control"

IF EMPTY(ldCanDate)
	DO printfield WITH lcLtr2,"Date", DTOC(DATE())
ELSE
	DO printfield WITH lcLtr2,"Date", DTOC(ldCanDate)
ENDIF

lcLrsNo=MASTER.lrs_no
IF TYPE("lcLrsNo")="N"
	lcLrsNo=STR(lcLrsNo)
ENDIF
DO printfield WITH lcLtr2, "LrsNo", ALLTRIM(lcLrsNo)
DO printfield WITH lcLtr2, "Tag", STR(lnTag)

DO PrintGroup WITH lcLtr2, "Contact"
DO printfield WITH lcLtr2, "Name", lcName
DO printfield WITH lcLtr2, "Phone", lcPhone
RETURN
*----------------------------------------------------------------------------
* print to RPS
*----------------------------------------------------------------------------
PROCEDURE lfPrnRps
PARAMETER lcLtr1, lcDesc, lcAdd1, lcAdd2, lcCity, lcState, lcZip, ;
	lcAttn, gnWFee, ldTxn7

IF INLIST(TYPE("ldTxn7"),"D","T")
	ldTxn7=NVL(ldTxn7,{})
	ldTxn7=DTOC(ldTxn7)
ELSE
	ldTxn7=NVL(ldTxn7,"")
ENDIF

DO lfCommon WITH RECORD.TAG, NVL(RECORD.req_date,d_today), lcLtr1, NVL(RECORD.Fin_date,d_today)

DO PrintGroup WITH lcLtr1, "Deponent"
DO printfield WITH lcLtr1, "Name", lcDesc
DO printfield WITH lcLtr1, "Addr", ;
	IIF(EMPTY(lcAdd2), lcAdd1, lcAdd1+CHR(13) + lcAdd2)
DO printfield WITH lcLtr1, "City", lcCity
DO printfield WITH lcLtr1, "State", lcState
DO printfield WITH lcLtr1, "Zip", lcZip
DO printfield WITH lcLtr1, "Extra", IIF(ISNULL(lcAttn),'',lcAttn)

DO printfield WITH lcLtr1, "WFee", STR(gnWFee, 6, 2)
DO printfield WITH lcLtr1, "ReqDate", ldTxn7
RETURN
*--------------------------------------------------------------------------------------------------------------
PROCEDURE setDeponentInfo
LPARAMETERS lcDept
LOCAL n_dec

STORE "" TO pc_MAdd1, pc_MAdd2, pc_MailCity, pc_MailSt, ;
	pc_MailZip, pc_FaxSub, pc_FaxAuth, pc_GovtLoc, pc_MailFName, ;
	pc_MailLName, pc_RadDpt, pc_PathDpt, pc_EchoDpt, pc_EFaxSub, ;
	pc_EFaxAuth, pc_PFaxSub, pc_PFaxAuth, pc_RFaxSub, pc_RFaxAuth, ;
	pc_BFaxSub, pc_BFaxAuth, pc_MAttn, pc_BatchRq
STORE 0 TO pn_MailPhn, pn_MailFax, pn_RadFax, pn_PathFax, ;
	pn_EchFax, pn_BillFax
STORE .F. TO pl_MailFax, pl_FaxOrig, pl_EFax, pl_EFaxOrg, ;
	pl_PFax, pl_PFaxOrg, pl_RFax, pl_RFaxOrg, pl_BfaxOrg, ;
	pl_CallOnly, pl_MCall, pl_BCall, pl_PCall, pl_RCall, ;
	pl_ECall,  pl_SpecRpsSrv


IF USED("viewDepoFile")
	USE IN viewDepoFile
ENDIF

IF NOT EMPTY( pc_MailId)
	o.sqlexecute("exec dbo.GetDepInf '"+pc_MailId+"'", "viewDepoFile")

	SELECT viewDepoFile

	IF TYPE('lcDept')='C'
		IF lcDept<>"Z" AND !EMPTY(lcDept) AND UPPER( LEFT( pc_MailId, 1))="H"
			LOCAL lnXXX, lcField
			lcField=""
			=AFIELDS(laDeptFlds)
			FOR lnXXX=1 TO ALEN(laDeptFlds,1)
				IF ALLTRIM(UPPER(laDeptFlds[lnXXX,1]))=="DEPT_CODE"
					lcField="DEPT_CODE"
				ENDIF
				IF ALLTRIM(UPPER(laDeptFlds[lnXXX,1]))=="DEPTCODE"
					lcField="DEPTCODE"
				ENDIF
				IF ALLTRIM(UPPER(laDeptFlds[lnXXX,1]))=="CODE"
					lcField="CODE"
				ENDIF
			NEXT
			IF !EMPTY(ALLTRIM(lcField))
				LOCATE FOR ALLTRIM(UPPER(&lcField))= ALLTRIM(UPPER(lcDept))
				IF NOT FOUND()
**EF 3/20/07- make sure it finds master record.
					LOCATE FOR &lcField= 'Z'
				ENDIF

			ENDIF
		ENDIF
	ENDIF
	pc_MailDesc = NAME
	pc_MAdd1    = add1
	pc_MAdd2    = add2
	pc_MailCity = City
	pc_MailSt   = State
	pc_MailZip  = Zip
	n_dec=SET('DECIMALS')
	SET DECIMALS TO 0
	pn_MailPhn  = IIF(TYPE('Phone')='N',Phone,VAL(Phone))
	SET DECIMALS TO n_dec
***11/29/07 - DO NOT FAX WHEN A BATCH REQUEST'S MAIL ID IS USED
**01/18/10- get rps by a dept's category -start
	IF pc_offcode="P"
		l_oK=o.sqlexecute("SELECT dbo.GetRpsQueueNamebyDept ('" + pc_MailId + "','" + lcDept + "','" + pc_offcode +"')", "RpsQ")
		IF l_oK
			pl_SpecRpsSrv=NVL(RpsQ.EXP,.F.)
			pc_BatchRq=IIF(pl_SpecRpsSrv,"RpsBatch"	,"")
			SELECT viewDepoFile
		ENDIF
	ELSE
		pl_SpecRpsSrv=.F.
		pc_BatchRq=""
	ENDIF

	pl_FaxOrig  = IIF(EMPTY(pc_BatchRq),FaxOrig,.F.)
	pc_FaxSub   = IIF(EMPTY(pc_BatchRq),Fax_Sub,"")
	pc_FaxAuth  = IIF(EMPTY(pc_BatchRq),Fax_Auth,"")
	pn_MailFax  = IIF(EMPTY(pc_BatchRq),Fax_no,0)
	pl_MailFax  = IIF(EMPTY(pc_BatchRq),Fax,.F.)

	pc_GovtLoc  = Govt
	pl_CallOnly = Callonly

	pc_MailFName = NAME
	pc_MailLName = ""
	pc_MAttn     = ALLTRIM( attn)


	pc_RadDpt   = ""
	pc_PathDpt  = ""
	pc_EchoDpt  = ""
	pn_RadFax   = IIF(EMPTY(pc_BatchRq),Fax_no,0)
	pn_PathFax  = IIF(EMPTY(pc_BatchRq),Fax_no,0)
	pn_EchFax   = IIF(EMPTY(pc_BatchRq),Fax_no,0)
	pl_EFax     = IIF(EMPTY(pc_BatchRq),Fax,.F.)
	pl_EFaxOrg  = IIF(EMPTY(pc_BatchRq),FaxOrig,.F.)
	pl_PFax     = IIF(EMPTY(pc_BatchRq),Fax,.F.)
	pl_PFaxOrg  = IIF(EMPTY(pc_BatchRq),FaxOrig,.F.)
	pl_RFax     = IIF(EMPTY(pc_BatchRq),Fax,.F.)
	pl_RFaxOrg  = IIF(EMPTY(pc_BatchRq),FaxOrig,.F.)
	pc_EFaxSub  = IIF(EMPTY(pc_BatchRq),Fax_Sub,"")
	pc_EFaxAuth = IIF(EMPTY(pc_BatchRq),Fax_Auth,"")
	pc_PFaxSub  = IIF(EMPTY(pc_BatchRq),Fax_Sub,"")
	pc_PFaxAuth = IIF(EMPTY(pc_BatchRq),Fax_Auth,"")
	pc_RFaxSub  = IIF(EMPTY(pc_BatchRq),Fax_Sub,"")
	pc_RFaxAuth = IIF(EMPTY(pc_BatchRq),Fax_Auth,"")
	pn_BillFax  = IIF(EMPTY(pc_BatchRq),Fax_no,0)
	pl_BfaxOrg  = IIF(EMPTY(pc_BatchRq),FaxOrig,.F.)
	pc_BFaxSub  = IIF(EMPTY(pc_BatchRq),Fax_Sub,"")
	pc_BFaxAuth = IIF(EMPTY(pc_BatchRq),Fax_Auth,"")
	pl_MCall    = Callonly
	pl_BCall    = Callonly
	pl_PCall    = Callonly
	pl_RCall    = Callonly
	pl_ECall    = Callonly




ENDIF

pl_Mail = .T.

RETURN
*
*****************************************************************************
* FUNCTION: lf_yesno
*
*-- Abstract: Prompt user for yes or no answer
*****************************************************************************
*
FUNCTION lf_yesno
PARAMETERS lc_message

LOCAL l_response

lo_message = CREATEOBJECT('rts_message_yes_no',lc_message)
lo_message.SHOW
l_response=IIF(lo_message.exit_mode="YES",.T.,.F.)
lo_message.RELEASE
RELEASE lo_message

RETURN l_response
ENDFUNC

