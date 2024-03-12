
*****************************************************************************************************************
*PROCEDURE IssueProcess
* 01/11/11 EF - check for faxn like nnnnnnnnnnnnn
* 11/08/10 EF - Add rush by case's setting and then 'Y' column's for all litigations per ALec.
* 09/02/10 EF - Added 'BL' provider type for AVA 
* 04/21/10 EF - skipp adding phone calls for supressed issues( PL_STOPPRTISS=.t.)
* 04/15/10 EF - Added pl_BalDgtk
* 04/09/10 EF - Added med provider id for ava1 cases
* 03/05/10 EF - Add notices to GSK lit issues
* 02/16/10 EF - Add litgation/exctract department/ cert
* 01/18/10 EF - Define RPS batch by a dept's category
* 10/12/09 EF - Use "Med" department's address for Hospital locations.
* 10/02/09 EF - use pd_pldob when assembling a scope for "*" dates
* 09/28/09 EF - add a  call to loadexcel with teh step "2"
* 09/11/09 EF - Fill a request's due date
* 08/28/09 EF - Added Court Order page for Ava plaintiff cases
* 07/01/09 EF - Added Phone call txns
**06/24/09 EF - Check if LOR was selected but does not exists yet
**06/08/09 EF - Removed a question about 'Printing ALL'
**06/03/09 EF - Added BAL/SRQ (orderid + rush)
**05/28/09 EF - added ENE issues
**04/20/09 EF - issues tags from a client's excel list
**Called from :
** a) issued.vcx/frmBatch for the first part: add not-issued tags (l_preissue=.t.)
** b) from Main menu: part 2- adding txn 11/printing requests
*****************************************************************************************************************
PARAMETERS  C_FILE, L_PREISSUE
LOCAL LORECORDORD AS VOID, LD_TODAY AS DATE, LCTAGTYPE AS STRING,;
	L_ENTRYID AS BOOLEAN, C_PARAMETER AS STRING, L_CONFIRM AS BOOLEAN, L_CONTINUE AS BOOLEAN, ;
	L_PRINTRPS AS BOOLEAN, C_ADDTONAME AS STRING, C_SCAN AS STRING, C_LOR AS STRING, l_addphnone as Boolean, c_addtodesc as String
PUBLIC MV
STORE "" TO LCTAGTYPE, C_SCAN, MV, PC_BATCHRQ, c_addtodesc
STORE .F. TO L_PRINTRPS, LCONFIRM, pl_SpecRpsSrv, PL_RUSHCAS
STORE .T. TO PL_AIPPROC,L_CONTINUE

_SCREEN.MOUSEPOINTER=11
PRIVATE OMED AS OBJECT
OMED=CREATEOBJECT("generic.medgeneric")
SELECT 0


*!*	IF ALLTRIM(goApp.CurrentUser.orec.LOGIN) ='ELLEN'
*!*	l_test =.f.
*!*	ELSE
l_test=.f.
*!*	endif

IF NOT L_PREISSUE
	GOAPP.OPENFORM("issued.frmpicklit", "S")
ENDIF
IF EMPTY(PC_LITCODE)
	GFMESSAGE( 'Invalid Litigation' )
	RETURN
ENDIF

IF TYPE("PC_USERID")<>"C"
	PC_USERID=ALLTRIM(goApp.CurrentUser.orec.LOGIN)
ENDIF

IF  EMPTY(C_FILE)
	C_FILE=GETTHEFILE(L_PREISSUE)
ELSE
	C_FILE="'"+ALLTRIM(C_FILE)+"'"
ENDIF
SET DELETED ON
DO CLEARTMP

IF  EMPTY(C_FILE)
WAIT WINDOW "No excel file selected.."
RETURN
endif

USE &C_FILE ALIAS LISTISSUE IN 0
*********************************** get settings for LOR ************************************************************************

IF USED('TheSettings')
	C_LOR=THESETTINGS.LORTYPE
ELSE
	C_STR="exec [dbo].[GetAIPSettings] '" + PC_LITCODE + "'"
	L_OK=OMED.SQLEXECUTE( C_STR,"TheSettings")
	IF NOT L_OK
		C_LOR='A'
	ELSE
		C_LOR=THESETTINGS.LORTYPE

	ENDIF
ENDIF
**** ask if a phone call txn is needed 2/22/2010
l_addphnone=.f.
IF NOT L_PREISSUE
lc_message = "Do you want to Add a Phone Call Transaction for the issues?"
		o_message = CREATEOBJECT('rts_message_yes_no',lc_message)
		o_message.SHOW
		l_Confirm=IIF(o_message.exit_mode="YES",.T.,.F.)
		o_message.RELEASE
		IF l_Confirm
			l_addphnone=.T.
		ENDIF
ENDIF
**2/22/2010

SELECT  LISTISSUE
SCAN
 IF TYPE("LISTISSUE.AD")="C" OR TYPE ("LISTISSUE.AF") ="C"
	 LGOTTAG=OMED.SQLEXECUTE("SELECT dbo.IfIssuedone('" + ALLTRIM(LISTISSUE.AD) + "',' " +  ALLTRIM(LISTISSUE.AF ) + "')", "Timesheet2")
 ELSE
	LGOTTAG=OMED.SQLEXECUTE("SELECT dbo.IfIssuedone('" + STR(LISTISSUE.AD) + "',' " +  STR(LISTISSUE.AF ) + "')", "Timesheet2")
 ENDIF
	
	IF LGOTTAG AND NOT EOF()
		IF !EMPTY(NVL(DTOC(TIMESHEET2.EXP),""))
			
			IF TYPE("LISTISSUE.AH")="C"
			REPLACE AH WITH "T" IN LISTISSUE
			ELSE
			REPLACE AH WITH .T. IN LISTISSUE
			ENDIF
			LOOP
		ENDIF
	ENDIF

ENDSCAN

SELECT  LISTISSUE

SET ORDER TO MAILID   && [S] column

IF TYPE ("LISTISSUE.AF") ="C" 
	C_SCAN =IIF(L_PREISSUE, " NOT EMPTY(ListIssue.S)"," NOT EMPTY(ListIssue.S)  AND  AH ='F' AND AF <>'0'")
ELSE
	C_SCAN =IIF(L_PREISSUE, " NOT EMPTY(ListIssue.S)"," NOT EMPTY(ListIssue.S)  AND NOT AH AND AF <>0")
ENDIF


SCAN FOR &C_SCAN
	
	IF TYPE("LISTISSUE.AD")="C"
		N_RTTODO= VAL(LISTISSUE.AD)
	
	ELSE
		N_RTTODO= LISTISSUE.AD
	
	ENDIF
	PC_LRSNO=N_RTTODO
	IF N_RTTODO=0
		DO GETMASTER_SSN WITH ALLTRIM(LISTISSUE.D)
		N_RTTODO= PN_LRSNO
	ELSE
*** Get MAster/public vars
	PL_RUSHCAS=.f.	
		DO GETMASTERTABLE WITH N_RTTODO
	ENDIF
	C_MAILID= LISTISSUE.S &&(mailid )
	IF NOT L_PRINTRPS
				
		SELECT COUNT(AF) AS CNT1  FROM LISTISSUE WHERE S= C_MAILID   INTO CURSOR CNTMAIL &&group BY s HAVING cnt1>=10
	
		IF CNTMAIL.CNT1>=10
			L_PRINTRPS=.T.

		ENDIF
	ENDIF
	SELECT  LISTISSUE

	IF L_PREISSUE
*** create a new tag
		NTAG= NEWTAG()
		IF NTAG =0
			GFMESSAGE( 'Invalid Tag Number' )
			SKIP
		ELSE
**upadate a list with TAG#
		
			REPLACE AF WITH NTAG IN  LISTISSUE
		ENDIF
	ELSE
&& for printing get a tag# from a list
		
		IF TYPE("LISTISSUE.AF")="C"
		NTAG=VAL(LISTISSUE.AF)
		ELSE
		NTAG=LISTISSUE.AF
		ENDIF
		IF  NTAG =0
			SKIP
			LOOP
		ENDI
	ENDIF
	L_RUSHDEPO= .F.


	IF USED("Request")
		SELECT REQUEST
		USE
	ENDIF
	IF USED("PC_depofile")
		SELECT PC_DEPOFILE
		USE
	ENDIF
	
	PC_ISSTYPE="A"
	
c_addtodesc=""	
IF LEN(ALLTRIM(LISTISSUE.P )) >=2	AND LEFT(ALLTRIM(LISTISSUE.P ),1) ="H"
	CDEPT2=getdept(LISTISSUE.P )
	c_addtodesc=getdescript(CDEPT2)
	
*** get deponent's data by mailid/dept
ELSE
	CDEPT2="Z"
endif
	DO GETDEPONENT WITH C_MAILID, CDEPT2

&&5/19/09- do not add a record for invalid mailis
	IF EMPTY(NVL(PC_DEPOFILE.ID_TBLDEPONENTS,""))

		REPLACE AG WITH "Not Valid Mail ID" IN LISTISSUE
		REPLACE AF WITH 0 IN LISTISSUE
		LOOP
	ENDIF
&&5/19/09 --

	IF NOT L_PREISSUE
	IF TYPE('OMED')<>'O'
		PRIVATE OMED AS OBJECT
		OMED=CREATEOBJECT("generic.medgeneric")
	endif
** get specific pharmacy locations
**01/18/10-  define RPS by a  dept's category-start		
		pl_SpecRpsSrv=.f.
		PC_BATCHRQ=""
		l_oK=OMED.SQLEXECUTE("SELECT dbo.GetRpsQueueNamebyDept ('" + C_MAILID + "','" + CDEPT2 + "','" + pc_offcode +"')", "RpsQ")
		IF l_oK		
		 pl_SpecRpsSrv=NVL(RpsQ.exp,.F.)
		 PC_BATCHRQ=IIF(pl_SpecRpsSrv,"RpsBatch"	,"")
		 SELECT PC_DEPOFILE	 
		ENDIF
		

**fax/print
		C_FAXTRAN="@R (999)999-9999"
		SZFAXNUM = 	TRANSFORM( ALLTRIM(PC_DEPOFILE.FAX_NO), C_FAXTRAN)
		C_FAX = STRTRAN( SZFAXNUM, " ", "")
		C_TEMP = STRTRAN( C_FAX, "-", "")
		C_TEMP2 = STRTRAN( C_TEMP, "(", "")
		SZFAXNUM = STRTRAN( C_TEMP2, ")", "")

		IF !EMPTY(PC_BATCHRQ) OR LEN(SZFAXNUM) <10 OR  INLIST(SZFAXNUM,'2222222222','3333333333','4444444444','5555555555','6666666666','7777777777','8888888888','9999999999','0000000000')
		
			L_PRINTRPS=.T.
		ELSE
			L_PRINTRPS=.F.
		ENDIF
	ENDIF
*************Deponent's data **********************************************************
	LCDEPNAME=PC_DEPOFILE.NAME
	IF LEFT(ALLTRIM(UPPER(C_MAILID)),1) == "D"
		C_DRNAME=GFDRFORMAT(LCDEPNAME)
		LCDEPNAME = IIF(NOT "DR."$C_DRNAME,"DR. "+ALLTRIM(C_DRNAME),C_DRNAME)
	ENDIF
	STORE "" TO LC_FORMTYPE, C_STR, C_REV, D_EMPTY
	D_NULL=NULL
	LD_TODAY=D_TODAY
	IF TYPE ('pd_revstop')<>"U"
		PD_REVSTOP=D_EMPTY
	ENDIF
	PD_REVSTOP=IIF(ISNULL(PD_REVSTOP), DTOC(D_EMPTY), PD_REVSTOP)

	IF PD_REVSTOP<>"  /  /    " OR  PD_REVSTOP<>""
		C_REV =IIF( PL_REVIEW AND DTOC(LD_TODAY) <= PD_REVSTOP, 'U', 'N')
	ENDIF

** add names into a description for non-Doctor locations:
	IF LEFT(ALLTRIM(UPPER(C_MAILID)),1) <>"D"
		C_ADDTONAME=IIF(!EMPTY( LISTISSUE.G), "(" + ALLTRIM( LISTISSUE.G) + " " + ALLTRIM( LISTISSUE.H)  + ")" , "")
	ELSE
		C_ADDTONAME=""
	ENDIF
	C_DESC=FIXQUOTE(ALLTRIM(LCDEPNAME) + IIF(!empty(c_addtodesc), c_addtodesc,"") + C_ADDTONAME)
	IF LEN(C_DESC)>50 && we only store 50 char string
		C_DESC= LEFT(C_DESC,50)
	ENDIF
**- add request---- pre-issue process
	IF  L_PREISSUE
		WAIT WINDOW "Add New Request..RT#:"  + ALLTRIM(PC_LRSNO)  + " Tag #:" + ALLTRIM( STR(NTAG)) NOWAIT
		C_STR=""
		C_STR= "Exec dbo.AddNewRequest '" +  MASTER.ID_TBLMASTER + "','" ;
			+ IIF(ISNULL(PC_DEPOFILE.ID_TBLDEPONENTS),'',PC_DEPOFILE.ID_TBLDEPONENTS) + "','" ;
			+ FIXQUOTE(PC_CLCODE) + "','" ;
			+ STR(NTAG) + "','T','" ;
			+ ALLTRIM(C_MAILID) + "','" ;
			+ ""+ "','" ;
			+ PC_USERID + "','" ;
			+ LEFT(FIXQUOTE(C_DESC) ,50)+ "'  ,'','' ,"   ;
			+ STR(0) + ",'" ;
			+  D_EMPTY + "','" ;
			+ "A" + "','"  ;
			+ C_REV + "'," ;
			+ STR(0) + "," ;
			+ STR(0) + "," ;
			+ STR(0) + ",'" ;
			+ '' + "','" ;
			+ '' + "',null ,'" ;
			+ '' + "','" ;
			+ '' + "','" ;
			+ STR(0) + "','" ;
			+ STR(0) + "'," ;
			+ STR(1) + ",'" ;
			+ ALLTRIM(LC_FORMTYPE) + "'," ;
			+ STR(0) 	+ ",0,null "

**get new record's id
		LREQUEST=OMED.SQLEXECUTE(C_STR,"")
		L_RQID=OMED.SQLEXECUTE( "select dbo.fn_GetID_tblRequest ('" + FIXQUOTE(MASTER.CL_CODE) + "','" +  STR(NTAG) + "')", "ReqsId")
		IF NOT LREQUEST
			=GFMESSAGE("A tag was not added. Contact IT.")
			RETURN
		ELSE
**update Tag count in Master
			C_STR= "Update tblMaster set subcnt='" +  STR(NTAG) + "' Where cl_code = '" + FIXQUOTE(MASTER.CL_CODE) + "' and active =1"
			L_TAGCNTUPD=OMED.SQLEXECUTE(C_STR , "")
			IF NOT L_TAGCNTUPD
				=GFMESSAGE("Tag count was not updated(Master). Contact IT dept.")
			ENDIF
		ENDIF

		*REPLACE ISSUEDEP WITH C_DESC IN LISTISSUE
		REPLACE AG WITH C_DESC IN LISTISSUE
	ENDIF &&& preissue end

	PC_MAILID=C_MAILID
	PL_STOPPRTISS=IIF(LISTISSUE.AA="Y" AND LISTISSUE.V="N", .T.,.F.)
	PL_STOPPRTISS=IIF(ALLTRIM(UPPER(LISTISSUE.V))="N" AND ALLTRIM(UPPER(LISTISSUE.W))="N", .T.,PL_STOPPRTISS)

	** YS 05/29/18 RPS No Print Job Logging [#88327]	
	IF PL_STOPPRTISS
		lcSQLLine=" exec [dbo].[AddTrackStopPrint]   '" + convertToChar(pc_lrsno,1) + "','" + convertToChar(fixquote(pc_clcode),1) + "','" + convertToChar(NTAG,1) + "','";
			+ convertToChar(pc_isstype,1) + "','" + convertToChar(fixquote(PC_USERID),1) + "','issueprocess.prg(1)',''"		
		*lcSQLLine=" exec [dbo].[AddTrackStopPrint]   '" + ALLTRIM(pc_lrsno) + "','" + ALLTRIM(pc_clcode) + "','" + ALLTRIM(STR(NTAG)) + "','";
			+ pc_isstype + "','" + ALLTRIM(PC_USERID) + "','issueprocess.prg(1)',''"
		OMED.SQLEXECUTE(lcSQLLine,'')
	ENDIF

	STORE "" TO LCSQLLINE
	IF NOT L_PREISSUE &&get record's id
**6/24/09 before we start to print check if LOR was selected but does not exists yet"
		IF C_LOR="A"
			C_LORNAME=""
			C_LORNAME = PRINTLOR('A')
			IF EMPTY(C_LORNAME)
				LC_MESSAGE = "Please Note that this batch does not have any LOR page. Continue anyway?"
				O_MESSAGE = CREATEOBJECT('rts_message_yes_no',LC_MESSAGE)
				O_MESSAGE.SHOW
				L_CONFIRM=IIF(O_MESSAGE.EXIT_MODE="YES",.T.,.F.)
				O_MESSAGE.RELEASE
				IF L_CONFIRM
					C_LOR=""

				ELSE
					L_CONTINUE=.F.
					C_FILE=""
					
					EXIT
				ENDIF

			ENDIF
		ENDIF
**6/24/09*****************************************************************************
		
		L_RQID=OMED.SQLEXECUTE( "select dbo.fn_GetID_tblRequest ('" + FIXQUOTE(MASTER.CL_CODE) + "','" +  STR(NTAG) + "')", "ReqsId")
		IF NOT L_RQID
			RETURN
		ENDIF
** 6/3/09 added an OID data for SRQ lit cases
N_ORDERId=0
C_EXTRADATA=""
		DO CASE
		CASE PC_LITCODE='AV1' OR pl_BalDgtk OR pl_CMSWag  OR pl_ReiMesh  OR pl_ReiSSRI&& 04/05/13 - added Vag/CMS/Wagstaff + 6/24/13  added pl_ReiMesh + 10/18/13 added pl_ReiSSRI
			N_ORDERID=LISTISSUE.Ao
			IF TYPE('N_ORDERID')<>"N"
				N_ORDERId=VAL(LISTISSUE.ao)
			endif
			C_EXTRADATA="Med Provider Id"
			
		CASE PC_LITCODE='BAL'  AND NOT pl_BalDgtk
			N_ORDERID=LISTISSUE.AC
			C_EXTRADATA="OrderID"

		OTHERWISE
			N_ORDERID=0
			C_EXTRADATA=""
		ENDCASE
		d_duedate=gfChkDat( ld_today + 10, .F., .F.) && 9/11/09 - add 10 days to an issue date
		LCSQLLINE="update tblRequest set  num_fld=" +STR(N_ORDERID) + ", char_fld='" + C_EXTRADATA + "', status='W', PrintOrigReq =" +  IIF(PL_STOPPRTISS, STR(1),STR(0)) + ;
			" , REQ_DATE='" + DTOC(LD_TODAY) + "', SEND_DATE ='"+ DTOC(LD_TODAY)+ "'" + ;
			", reqduedate ='" + DTOC(d_duedate) + "', descript= '" + LEFT(FIXQUOTE(C_DESC) ,50) + "' where id_tblrequests='"+REQSID.EXP+"' and active =1"
			
			
			

		OMED.SQLEXECUTE(LCSQLLINE)
	ENDIF

	PC_ISSTYPE="A"
	PN_TAG =NTAG
**- add orders
	IF  NOT L_PREISSUE 
		WAIT WINDOW 'Add Orders..Timesheet..SpecIns..Notice..' NOWAIT
	IF  NOT l_test &&test 9/28/09
		DO SETORDTG WITH NTAG
		
**-add txn 11
		DO ADDTIMESHEET WITH 11, NTAG, C_DESC, C_MAILID
**txn 5 if paralegal time is entered on a spreadsheet
		IF NOT EMPTY(ALLTRIM(LISTISSUE.AB) )
			DO ADDTIMESHEET WITH 5, NTAG, C_DESC, C_MAILID
		ENDIF
ENDIF &&test 9/28/09
**6/3/09 rush for Baily/SRQ
**04/15/10 added pl_BalDgtk
**11/08/10 - add rush by case's setting and then 'Y' column's for all litigations per ALec.
IF PL_RUSHCAS OR NOT EMPTY(ALLTRIM(LISTISSUE.Y) )
		*IF PC_LITCODE='BAL' OR pl_BalDgtk
			*IF NOT EMPTY(ALLTRIM(LISTISSUE.Y) )
				DO ADDTIMESHEET WITH 14, NTAG, C_DESC, C_MAILID
			*ENDIF
		*ENDIF
ENDIF 		
		
		IF USED('EntryID')
			SELECT ENTRYID
			USE
		ENDIF
		L_ENTRYID= OMED.SQLEXECUTE("select dbo.fn_GetID_tblTimesheet ('" + FIXQUOTE(MASTER.CL_CODE) + "','" ;
			+ STR(NTAG) +"','" + STR(11)+ "','" +DTOC(DATE()) +"')", "EntryId")
		IF L_ENTRYID

&&5/28/09 added ene lit issues
			DO CASE
			CASE	PC_LITCODE='ENE'
				C_BLURB= ADD_BLURB_DEPT(  LISTISSUE.R, LISTISSUE.P, ALLTRIM(LISTISSUE.U) )
				CDEPT2=ALLTRIM(BLURBS.DEPARTMENT)
				PC_CERTTYP=ALLTRIM(BLURBS.CERTTYPE)
				DO ADDSPECINS2 WITH ENTRYID.EXP, PC_CLCODE, NTAG, ALLTRIM(C_DESC),"A", ALLTRIM(C_MAILID), IIF (!EMPTY(CDEPT2),CDEPT2,"Z"),C_BLURB

			OTHERWISE
**-add spec inst- blurb /AVA lit right now
				C_BLURB= GETBLURB(  LISTISSUE.R, LISTISSUE.P, ALLTRIM(LISTISSUE.U) )
				*PC_CERTTYP="R"
							
				PC_CERTTYP=getcert(ALLTRIM(LISTISSUE.P))
				IF  NOT l_test &&test 9/28/09
				DO ADDSPECINS2 WITH ENTRYID.EXP, PC_CLCODE, NTAG, ALLTRIM(C_DESC),"A", ALLTRIM(C_MAILID), IIF (!EMPTY(CDEPT2),CDEPT2,"Z"),C_BLURB
				ENDIF &&test 9/28/09
			ENDCASE
**-add notices
IF  NOT l_test &&test 9/28/09
			LC_STR="Exec dbo.sp_AddNotice '" ;
				+ PC_CLCODE + "','" ;
				+ STR(NTAG) + "','" ;
				+ DTOC(D_TODAY) + "','" ;
				+  DTOC(D_TODAY +10) + "','" ;
				+ FIXQUOTE(C_DESC) + "','" ;
				+ FIXQUOTE(C_BLURB) + "','" ;
				+ ALLT(PC_RQATCOD) + "','" ;
				+ PC_LITCODE + "','" ;
				+ "0"  + "','" ;
				+ ALLTRIM(C_MAILID) + "','" ;
				+ "A" + "'," ;
				+ STR(0) + " ," ;
				+ STR(0) + "," ;
				+ STR(0) + ", null, '','', '', '" ;
				+ PC_USERID + "'," + STR(0) ;
				+ ",''"
			L_NOTICE=OMED.SQLEXECUTE(LC_STR,"")
ENDIF &&9/28/09
		ENDIF
	ELSE
&&pre-issue: add txn 4
		DO ADDTIMESHEET WITH 4, NTAG, C_DESC,C_MAILID
	ENDIF

***************************************** Part 2 **************************************************************
***************************************** Print requests ******************************************************
	IF NOT L_PREISSUE
		_SCREEN.MOUSEPOINTER=11
		WAIT WINDOW "Printing request .." NOWAIT

		IF PL_STOPPRTISS		 
		IF TYPE("LISTISSUE.AH")="C"
		REPLACE AH WITH "T" IN LISTISSUE
		ELSE
		REPLACE AH WITH .T. IN LISTISSUE
		ENDIF
		ENDIF
		LC_STR=""
		LC_STR ="Exec dbo.Getrequestbylrsno '" + STR(N_RTTODO)+ "','" + STR(NTAG) + "'"

		L_GOTREQ=OMED.SQLEXECUTE(LC_STR,"Request")
		IF  NOT L_GOTREQ
			GFMESSAGE('Cannot get the REQUEST. Try later or contact IT dept.')
			RETURN

		ENDIF

		GNHOLD=0
		L_AUTOCOV=.T.
		PL_1ST_REQ=.T.
		CDEPT=CDEPT2
		PD_ISSDTE=DATE()
		IF NOT ISDIGIT( LEFT( ALLT( C_MAILID), 1))
			PC_DEPTYPE = LEFT( ALLT( C_MAILID), 1)
		ELSE
			PC_DEPTYPE = "D"
		ENDIF
		STORE 'A' TO C_ISSTYPE,CREQTYPE
		STORE "" TO SZEDTREQ,  SZREQUEST
		MDEP=FIXQUOTE(C_DESC)
**1-COVER PAGE
		IF  USED('Spec_ins')
			SELECT SPEC_INS
			USE
		ENDIF
		L_DONE=OMED.SQLEXECUTE("Exec  dbo.GetSpec_InsbyRTTAG '" + PC_LRSNO+ "', '" + STR(NTAG)+ "'", "Spec_ins")
		IF L_DONE AND NOT EOF() THEN
			=CURSORSETPROP("KeyFieldList", "id_tblSpec_ins,Cl_code, TAG", "Spec_ins")
			INDEX ON CL_CODE +STR(TAG) TAG CLTAG ADDITIVE
		ELSE

			WAIT WINDOW "No cert: RT # " +  PC_LRSNO  + " Tag " + ALLTRIM(STR(NTAG))
			RETURN
		ENDIF
		MV=""
		gnFRDays=0
		DO COVRLETR IN SUBP_PA

**2-CERT PAGE
		IF  USED ('Timesheet')
			SELECT TIMESHEET
			USE
		ENDIF
		LDTXN11 = GFCHKDAT( FORIGISS(NTAG), .F., .F.)
		DO PRINTCER WITH NTAG, 1, SPEC_INS.ID_TBLSPEC_INS

**3-LOR
		IF C_LOR="A"
			C_DOCNAME = PRINTLOR('A')
			WAIT WINDOW "Printing LOR..." NOWAIT
			DO PRINTGROUP WITH MV, C_DOCNAME

		ENDIF
*3-a -Court Order for Ava plaintiff cases as 8/28/09
** added pl_AV1Fed  below on 3/10/2010
		IF pl_AVAPltf OR pl_AV1Fed
			DO getAvaPlOrder  
		ENDIF
*3-b - Preservation Letter -3/23/2010
		IF pl_Ava1 
			DO AV1Letter  WITH mdep, cdept
		ENDIF

**4-authorizations
		PL_SCANSUB=.T.
		WAIT WINDOW "Printing Authorization..." NOWAIT
		DO PSCNAUTH  IN SUBP_PA
		SET SAFETY OFF

		IF L_PRINTRPS
			MCLASS = IIF(!EMPTY(PC_BATCHRQ),PC_BATCHRQ +"_1st",IIF(EMPTY(ALLTRIM(LISTISSUE.T)) , "FLRBatch","Batch1_1st"))
			
		ELSE

			IF LEN(ALLTRIM(SZFAXNUM)) <10 OR ;
			 INLIST(ALLTRIM(SZFAXNUM),'1111111111','2222222222','3333333333','4444444444','5555555555','6666666666','7777777777','8888888888','9999999999','0000000000')
				
				SZFAXNUM=""
				MCLASS = IIF(EMPTY(ALLTRIM(LISTISSUE.T)) , "FLRBATCH","Batch1_1st")
			ELSE
				
				MCLASS = IIF(EMPTY(ALLTRIM(LISTISSUE.T)) , "BatchFaxA","Batch1_1st")
			ENDIF
		ENDIF

	
	** phone call added on 7/1/09-start
	IF l_addphnone AND NOT PL_STOPPRTISS && do not add phone calls to  NEW LIT  2/19/2010
		DO addConfrmCall
	endif
	IF MCLASS="BatchFax" AND NOT PL_STOPPRTISS
		*DO AddPhnTx WITH 1, ntag
		DO FaxMemo WITH 1, ntag &&5/8/17 #61920/21
		
	ENDIF
	
	**7/1/09 -end


		GNTAG = NTAG
*!*			**remove after aylstock 
*!*			l_skip=.f.
*!*			l_skip= supress2(pn_lrsno, ntag)
*!*			
*!*			***7/1/09 remove
*!*			IF NOT l_skip
			DO PRTENQA WITH MV, MCLASS, "1", ALLTRIM(SZFAXNUM)			
*!*			endif
		*REPLACE ISSUED WITH .T. IN LISTISSUE
		IF TYPE("LISTISSUE.AH")="C"
		REPLACE AH WITH "T" IN LISTISSUE
		ELSE
		REPLACE AH WITH .T. IN LISTISSUE
		ENDIF

	ENDIF &&PRINT end

	SELECT LISTISSUE

ENDSCAN


IF L_PREISSUE
&& create an excel file (step2) for users to review RT and Tags.
	IF NOT EMPTY(ALLTRIM( C_FILE))
		C_TEMPFILE=LEFT(ALLTRIM( C_FILE),LEN(ALLTRIM( C_FILE))-5) + "_step2.xls"
	ELSE
		C_TEMPFILE=SYS(5) +SYS(3) + "_step2.xls"
	ENDIF
	SELECT LISTISSUE
	GO TOP
	IF NOT EOF()
		COPY TO (STRTRAN(C_TEMPFILE,"'","")) TYPE XL5

		GFMESSAGE("Look at the " + C_TEMPFILE + " file.")

	ENDIF
	GFMESSAGE('Cases and Not-Issued Tags had been added. Please exit.')
ELSE
	GFMESSAGE( "The BATCH was" + IIF(L_CONTINUE," sent", " not sent" ) + " to the RPS Servers.")
*!*		SELECT LISTISSUE
*!*		USE
ENDIF
*** 03/11/2010 MD added loop to go through all cl_codes 
***03/05/2010 	- NOTICES FOR THE LITIGATIONS/AREA THAT HAD BEEN SET TO GET THE NOTICES IN THE RTS SYSTEM
IF NOT  L_PREISSUE
	SELECT ad as lrs_no FROM listissue GROUP BY ad INTO CURSOR tempMastList
	SELECT tempMastList
SCAN 
    DO GETMASTERTABLE WITH tempMastList.lrs_no
    DO GETREQUEST WITH MASTER.CL_CODE
    pc_isstype="A"
	IF NOT nonotice( pc_area, pc_Litcode, pc_Court1, IIF(pc_isstype="S","7","8"), .F.)
		pl_prtnotc = IIF(pl_NJSpec, .F., .T.)	
		_SCREEN.MOUSEPOINTER=11
		
		IF NOT INLIST( pc_platcod, "A14604P", "A14622P", "A14637P", ;
		"A14638P", "A14753P", "A16078P", "A16124P", "A16486P")

	IF pl_prtnotc
		IF USED('UserCtrl')
		SELECT UserCtrl
		c_SSN=RIGHT( UserCtrl.SSN, 4)
		ENDIF
			DO TheNotic WITH .F., c_SSN, d_today, .F.
		ENDIF
	endif
		pl_prtnotc = .F.
		_SCREEN.MOUSEPOINTER=0		
	ENDIF
***03/05/2010 	-NOTICES	END	
   SELECT tempMastList
ENDSCAN 
ENDIF 	    
PL_AIPPROC=.F.
PL_1ST_REQ=.F.
RELEASE OMED
_SCREEN.MOUSEPOINTER=0

*********************************************************************************************
*********************************************************************************************
PROCEDURE GETMASTERTABLE
*********************************************************************************************
PARAMETERS LN_RTTODO
IF USED("master")
   USE IN master
ENDIF    
PRIVATE OMED2 AS OBJECT
IF TYPE("LN_RTTODO")<>"N"
   LN_RTTODO=VAL(LN_RTTODO)
ENDIF 
OMED2=CREATEOBJECT("generic.medgeneric")
OMED2.SQLEXECUTE("exec dbo.GetMasterbyRTNumber '"+STR(LN_RTTODO) + "'" ,"Master")

PL_GOTCASE =.F.
DO GFGETCAS &&WITH .T.

RELEASE OMED2
RETURN
**********************************************************************************************
PROCEDURE GETREQUEST
*********************************************************************************************
lPARAMETERS lcClCode
IF USED("request")
   USE IN request
ENDIF    
PRIVATE OMED2 AS OBJECT
OMED2=CREATEOBJECT("generic.medgeneric")
OMED2.SQLEXECUTE("select * from tblrequest where cl_code='"+ALLTRIM(lcClCode) + "' and active=1" ,"Request")

RELEASE OMED2
RETURN
**********************************************************************************************
PROCEDURE GETDEPONENT

PARAMETERS LC_MAILID, LCDEPT
PRIVATE OMED1 AS OBJECT
OMED1=CREATEOBJECT("generic.medgeneric")
WAIT WINDOW "Getting Deponent's information" NOWAIT NOCLEAR

L_MAIL=OMED1.SQLEXECUTE("exec dbo.GetDepInfoByMailIdDept  '" + ALLTRIM(LC_MAILID)  +"','" + LCDEPT + "' ", "pc_DepoFile")
SELECT PC_DEPOFILE
IF EOF()
	L_MAIL=OMED1.SQLEXECUTE("exec dbo.GetDepInfoByMailIdDept  '" + ALLTRIM(LC_MAILID)  +"','" + LCDEPT + "' ", "pc_DepoFile")
ENDIF

=CURSORSETPROP("KeyFieldList", "Code, id_tbldeponents", "pc_DepoFile")
_SCREEN.MOUSEPOINTER=0
RETURN

*******************************************************************************************
PROCEDURE ADDTIMESHEET
PARAMETERS NTXN_CODE, NTAGNUM, CDESCRIPT,CMAILID

PRIVATE CSQL AS STRING, C_TXNCODE AS STRING
N_UNITS=STR(0)

IF NTXN_CODE=5 AND NOT EMPTY(ALLTRIM(LISTISSUE.AB))
	N_UNITS=GETPARALEGALTIME(1, LISTISSUE.AB)
	N_UNITS= STR(N_UNITS,6,2)

ELSE
	N_UNITS=STR(0)
ENDIF
IF NTXN_CODE=5
	IF VAL(ALLTRIM(N_UNITS))=VAL("0")
		RETURN
	ENDIF
ENDIF

CSQL =""
CSQL= "Exec dbo.gfAddTxn '" + DTOC(DATE())+  " ', '" ;
	+ LEFT(FIXQUOTE(CDESCRIPT) ,50)+ "','" + PC_CLCODE + "',' " ;
	+ ALLTRIM(STR(NTXN_CODE)) + "','"  + ALLTRIM(STR(NTAGNUM)) + "','" ;
	+ NVL(ALLTRIM(CMAILID),"") + "','" + N_UNITS + "','" ;
	+ ALLTRIM(STR(0)) + "','" +  "" + "','" ;
	+ ALLTRIM(STR(0)) + "', '"  + "" + "','" ;
	+ "A" + "','" ;
	+ PC_USERID + "','" ;
	+ REQSID.EXP +"'"
L_OK=OMED.SQLEXECUTE(CSQL,"")

RETURN

*******************************************************************************************
FUNCTION GETBLURB
*******************************************************************************************
PARAMETERS  C_DATE , C_SCOPE, S_EXTRA
PRIVATE CTEXT3 AS STRING, C_ADDITION AS STRING
C_ADDITION=""
CTEXT1=""
CTEXT2=""
&& specific blurbs
IF NOT USED('blurbs')
	LCBLURB=ALLTRIM(ADDBS(MLPRIPRO("R", "RTS.INI", "Data","GLOABL", "\"))) + ALLTRIM(PC_LITCODE) + "blurbs.dbf"
**USE 'T:\VFPFree\Global\AVAblurbs.dbf' IN 0 ALIAS BLURBS
	USE &LCBLURB  IN 0 ALIAS BLURBS
ENDIF
SELECT BLURBS
SET ORDER TO SCOPE
IF SEEK(ALLTRIM(C_SCOPE))
	CTEXT1 =ALLTRIM(BLURBS.PART1)
	CTEXT2 =ALLTRIM(BLURBS.PART2)
ENDIF
IF ALLTRIM(UPPER(C_DATE))="ALL DATES"
	C_DATE=""
ENDIF
&& 04/06/2010  skip a scope for the Avandia1 lit issues
IF EMPTY(C_DATE) OR ALLTRIM(C_DATE)="*"
	
	C_DATE= IIF(pl_Ava1, "",ALLTRIM(DTOC(pd_pldob)) +  " - " + DTOC(DATE()) )
ENDIF

CTEXT3 = IIF(pl_Ava1, "",C_DATE)
IF !EMPTY(S_EXTRA)
	C_ADDITION=CHR(13) + S_EXTRA
ENDIF
CTEXT=CTEXT1 + " " + ALLTRIM(CTEXT3) + " " +  CTEXT2 + C_ADDITION
RETURN CTEXT

*-----------------------------------------------------------------------------------------
FUNCTION ADDSPECINS2
PARAMETERS C_TSID, C_CLCODE,N_TAG, C_DESCRIPT, C_REQTYPE, C_MID, C_DEPT, C_REQUEST
LOCAL L_SPECID AS BOOLEAN
IF TYPE("pcPublicBlurb")!="C"
	PCPUBLICBLURB=""
ENDIF
IF EMPTY(ALLTRIM(C_REQUEST))
	IF EMPTY(ALLTRIM(PCPUBLICBLURB))
		GFMESSAGE("Blurb is missing.  Please notify IT department!")
	ELSE
		C_REQUEST=ALLTRIM(PCPUBLICBLURB)
	ENDIF
ENDIF

OMED1 = CREATEOBJECT("generic.medgeneric")
C_STR="Exec dbo.EditSpecIns  NULL " + ",'" + C_TSID	+ ;
	"', '" + FIXQUOTE(C_CLCODE) + "','" + STR(N_TAG) + "','" + ;
	FIXQUOTE(C_REQUEST)+ "','"  + FIXQUOTE(C_DESCRIPT) + "','" + ;
	DTOC(D_TODAY) + "','" +  C_REQTYPE + "'," + STR(0)+ ",'"  + ;
	C_MID + "','" + C_DEPT + "','" +	PC_CERTTYP + "','" +STR(0) + "','" + ;
	DTOC(D_TODAY)+ "','" + PC_USERID + "'," +	STR(1) + "," + STR(0) + ",'" + "" + "'"

L_SPECID=OMED1.SQLEXECUTE(C_STR,"EditSp")
RELEASE OMED1
RETURN L_SPECID

************************************************************************
FUNCTION GETTHEFILE
PARAMETERS L_PREISS
************************************************************************
LNCURAREA=SELECT()
*lcDefault=SYS(5) + SYS(2003)
LCCURR=SYS(5) +SYS(2003)
LCDEFAULT=ALLTRIM(ADDBS(MLPRIPRO("R", "RTS.INI", "Data","AUTOMATEDISSUE", "\")))

SET DEFAULT TO &LCDEFAULT
LCFILE=GETFILE("XLS","Load Batch List")
*LCFILE="'"+ALLTRIM(LCFILE)+"'"

IF NOT EMPTY(ALLTRIM(LCFILE))
*9/28/09---------------
LOCAL n_div as Integer, c_dir as String
n_div=0
c_dir =""
n_div =RAT("\",lcfile,1) 
c_dir =LEFT(lcfile, n_div)
lcFile="'"+ALLTRIM(lcFile)+"'" 
SET DEFAULT TO &LCCURR
DO LOADEXCEL WITH &lcFile, c_dir, "2"

lcFileName=DBF()
	
	USE
	LCFILENAME="'"+ALLTRIM(LCFILENAME)+"'"
	USE &LCFILENAME ALIAS TODOFILE EXCLUSIVE	
	INDEX ON S FOR .NOT.EMPTY(S) TAG MAILID ADDITIVE	
	INDEX ON AD TAG LRS_NO ADDITIVE

	SELECT TODOFILE

	GO TOP
	
	DELETE NEXT 1
	
	USE
ENDIF && EMPTY FiLE
IF NOT EMPTY(LNCURAREA)
	SELECT (LNCURAREA)
ENDIF
SET DEFAULT TO &LCCURR

IF TYPE('LCFILENAME')<>"C"
RETURN ""
else
RETURN (LCFILENAME)
endif

*********************************************************************************************
PROCEDURE GETMASTER_SSN
*********************************************************************************************
PARAMETERS C_SSN
** only check with
OMED.SQLEXECUTE("SELECT * FROM TBLMASTER WHERE LITIGATION ='" + PC_LITCODE + "' AND SOC_SEC= '"+ C_SSN + "' AND ACTIVE =1" ,"Master")
SELECT MASTER
IF NOT EOF()
	PL_GOTCASE =.F.
	DO GFGETCAS &&WITH .T.
	
	REPLACE AD WITH PN_LRSNO IN LISTISSUE
ELSE

	WAIT WINDOW "No case found" NOWAIT
	RETURN

ENDIF

RETURN

********************************************************
FUNCTION GETPARALEGALTIME
LPARAMETERS LN_TYPE, LC_VALUE
LOCAL LSUNITS, LC_TIME
IF TYPE('lc_value')="C"
	LC_VALUE=VAL(LC_VALUE)
ENDIF


IF LN_TYPE=1
	LSUNITS=LC_VALUE
	LC_MINUTES=ALLTRIM(STR(LSUNITS-INT(LSUNITS),10,2))
	IF INLIST( RIGHT( LC_MINUTES, 1), "1", "2", "3", "4")
		LSUNITS=ROUND(LSUNITS,1)+0.1
	ELSE
		LSUNITS=ROUND(LSUNITS,1)
	ENDIF
ENDIF
IF LN_TYPE=2
	LSUNITS=IIF(LC_VALUE>0, LC_VALUE/60, 0)
ENDIF
RETURN LSUNITS
*********************************************************************************************
FUNCTION GETTMPFILE
PARAMETERS CTEMPFILE
PRIVATE C_FILE AS STRING
*c_tempFile="\ListIssue_1.xls"
C_ROOT=SYS(5) + "\"
N_NUM1=1

N_FILES = ADIR(A_FILES, C_ROOT +ALLTRIM(UPPER(CTEMPFILE)))
IF N_FILES > 0
	=ASORT(A_FILES)
	N_NUM1 =GETNUMBER(A_FILES(ALEN(A_FILES,1), 1), LEN(ALLTRIM("ListIssue_")))
ENDIF
C_FILE=LEFT(CTEMPFILE,LEN(CTEMPFILE)-5) + ALLTRIM(STR(N_NUM1+1)) +".xls"
RETURN C_FILE

*****************************************************************************************
FUNCTION GETNUM
PARAMETER C_DOCUMENT, N_LENCASE
LOCAL N_POS , C_NUM
N_POS = AT( "_", C_DOCUMENT)
N_LENCASE = N_LENCASE + 1
C_NUM = SUBSTR(C_DOCUMENT, N_LENCASE, N_LENCASE-2 )
RETURN VAL(C_NUM)

***8/28/09 - added to get blurbs with the ene lit

*******************************************************************************************
FUNCTION ADD_BLURB_DEPT
*******************************************************************************************
PARAMETERS   CSCOPE, CEXTRA, CDEPART
PRIVATE CTEXT1 AS STRING, C_ADDITION AS STRING, L_OK AS BOOLEAN
C_ADDITION=""
CTEXT1=""

IF NOT USED('blurbs')
	LCBLURB=ALLTRIM(ADDBS(MLPRIPRO("R", "RTS.INI", "Data","GLOABL", "\"))) + ALLTRIM(PC_LITCODE) + "blurbs.dbf"
	USE &LCBLURB  IN 0 ALIAS BLURBS
ENDIF
SELECT BLURBS
SET ORDER TO SCOPEDEPT
IF SEEK(ALLTRIM(C_SCOPE)+ALLTRIM(CDEPART) )
	CTEXT1 =ALLTRIM(BLURBS.PART1)

	CDEPART=ALLTRIM(BLURBS.CERTTYPE)
ENDIF


IF !EMPTY(S_EXTRA)
	C_ADDITION=CHR(13) + S_EXTRA
ENDIF
CTEXT=CTEXT1  + C_ADDITION
RETURN  CTEXT
PROCEDURE CLEARTMP
IF USED('casesToAdd')
	SELECT CASESTOADD
	USE
ENDIF
IF USED('ListIssue')
	SELECT  LISTISSUE
	USE
ENDIF

RETURN
************************************************
FUNCTION getdept
************************************************
PARAMETERS cdepartment
LOCAL lcdepart as String
lcdepart="M" && default
IF LEN(ALLTRIM(cdepartment)) >2 AND LEFT(cdepartment,1) ="H"
lcdepart=RIGHT(ALLTRIM(cdepartment),1)

endif
RETURN lcdepart
************************************************
FUNCTION getcert
************************************************
PARAMETERS c_dept
**04/13/2010 - print "R" for P,E,C hospital dept per Julie's email "Avandia1 AIP Excel blurbs"
LOCAL lc_cert as String	
lc_cert="R"


IF LEFT(c_dept,1)="H"	AND  LEN(ALLTRIM(c_dept)) >2
** This is filled in only if a hospital!!		
	lc_cert=RIGHT(c_dept,1) 
	
ENDIF
**09/01/2010- BL provider in ava lit should print "B" cert page (Julie/Sarah)
IF PC_LITCODE='AVA' AND c_dept='BL'
	lc_cert="B"
ENDIF
**09/01/2010- BL provider in ava lit should print "B" cert page (Julie/Sarah)
RETURN	IIF(INLIST(lc_cert	,'M', 'P','E','C'), 'R', lc_cert)		


************************************************

***skipped the 6/30/09 faxed job for Aylstock/Avandia when a batch was 
**reprocessed on 7/2/09 again: NOt needed for any other processes
*!*	FUNCTION supress2
*!*	PARAMETERS nRt1, ntag1
*!*	calias=ALIAS()
*!*	IF USED('ayktemp')
*!*	SELECT ayktemp
*!*	USE
*!*	ENDif
*!*	USE 't:\vfpfree\ayktemp.dbf' IN 0
*!*	SELECT ayktemp
*!*	SET ORDER TO RTTAG   && STR(RT)+STR(TAG)
*!*	l_found=.f.
*!*	IF SEEK(STR(nRT1)+STR(nTAG1))
*!*		l_found=.t.
*!*	replace done WITH .t.
*!*	ENDIF
*!*	IF NOT empty(calias)
*!*	SELECT (calias)
*!*	endif
*!*	RETURN l_found

