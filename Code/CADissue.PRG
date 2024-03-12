*******************************************************************************************
** EF ACD Batch Issue -4/30/10 -Adaptd from FLR issue process
*******************************************************************************************
***********************Add Tags First*******************************************************
PROCEDURE StartIt
PRIVATE oMed_B AS OBJECT
PUBLIC MV
pl_CADBatch=.t.
PRIVATE l_c AS STRING
PRIVATE c_Retval
oMed_B=CREATEOBJECT("medmaster")
c_Retval="O"
l_c= INPUTBOX("Please Pick - (B(ills), R(ecords), P(athology), X(Radiology), O(ther), S(kip)) or C(ancel)", "Pick a department to add Tags ")
LOCAL lcpath AS STRING
lcpath=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","CADLit", "\")))

DO CASE
CASE l_c ="P"
	c_file="Plisttodo.DBF"
CASE l_c ="B"
	c_file="Blisttodo.DBF"
CASE l_c ="R"
	c_file="Rlisttodo.DBF"
CASE l_c ="X"
	c_file="Xlisttodo.DBF"
CASE l_c ="O"
	c_file="listtodo.DBF"
CASE l_c ="S"
* skip the first step
OTHERWISE
	RETURN
ENDCASE
IF ALLTRIM(UPPER(l_c)) <>"S"
	c_file=ADDBS(ALLTRIM(lcpath))+ALLTRIM(c_file)
	SELECT 0
	USE &c_file ALIAS listTodo
	COUNT TO lnNotPrinted FOR printed=.F.
	IF lnNotPrinted>0
		IF gfMessage("There are some tags that were not printed from the previous run.  Do you want to continue to load the new file and loose not printed tags?",.T.)=.F.
			RETURN
		ENDIF
	ENDIF
	USE IN listtodo


	IF loadFile2Proc(c_file)=.F.
		RETURN
	ENDIF
	SELECT 0

	USE &c_file ALIAS listTodo
	SELECT listTodo
	SET ORDER TO NEWMAILID   && NEWMAILID

	SCAN FOR EMPTY(donedate)
		c_mailid =NEWMAILID
		DO  GenerateBatch  WITH listTodo.rt, listTodo.origtag, listtodo.NEWMAILID, ALLTRIM(listtodo.certtype), ;
			listTodo.received, ALLTRIM(listTodo.fax), ALLTRIM(listTodo.line11), ALLTRIM(listTodo.COMMENT)
		REPLACE listtodo.donedate WITH DATE()

	ENDSCAN
ENDIF
***********************Now Print*******************************************************
** change parameters "B" to "R" for Hospital's batches and "O" (Others) when done with Hospitals B and R.
**HAVE TO DO IT TWICE IN TWO PALCES:  #1 BELOW
***********************************************************************

MV=""

**#1

PRIVATE l_c AS STRING
PRIVATE c_Retval
c_Retval="O"
l_c= INPUTBOX("Please Pick -(B(ills), R(ecords), P(athology), X(Radiology), O(ther)) or C(ancel)", "Pick a department to Print Documents")
DO CASE
CASE l_c ="P"
	c_Retval= "P"
	c_file="Plisttodo.DBF"
CASE l_c ="B"
	c_Retval= "B"
	c_file="Blisttodo.DBF"
CASE l_c ="R"
	c_Retval="R"
	c_file="Rlisttodo.DBF"
CASE l_c ="X"
	c_Retval="X"
	c_file="Xlisttodo.DBF"
CASE l_c ="O"
	c_Retval= "O"
	c_file="listtodo.DBF"
OTHERWISE
	gfMessage("The documents will not be printed")
	RETURN
ENDCASE

IF !USED("listtodo")
	SELECT 0
	USE &c_file ALIAS listTodo
	SELECT listTodo
	SET ORDER TO NEWMAILID   && NEWMAILID
ENDIF
SELECT listtodo

DO GETSETS WITH c_Retval

WAIT WINDOW 'DONE'
pl_CADBatch=.f.
RELEASE oMed_B
RETURN

*******************************************************************************************

PROCEDURE GETSETS
PARAMETERS c_hdep
_SCREEN.MOUSEPOINTER=11
LOCAL lcpath1 AS STRING
pc_offcode='P'
PRIVATE C_CERTTYPE AS STRING, c_file AS STRING
C_CERTTYPE=""
IF USED ('LISTTODO')
	SELECT LISTTODO
	USE
ENDIF
pc_offcode="P"
lcpath1=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","CADLit", "\")))
DO CASE
CASE c_hdep ="P"
	c_file= lcpath1 + "Plisttodo.DBF"
CASE c_hdep ="B"
	c_file= lcpath1 + "Blisttodo.DBF"
CASE c_hdep ="R"
	c_file=lcpath1 + "Rlisttodo.DBF"
CASE c_hdep ="X"
	c_file=lcpath1 + "Xlisttodo.DBF"
OTHERWISE
	c_file=lcpath1 + "listtodo.DBF"
ENDCASE
SELECT 0
USE (c_file) ALIAS  listTodo

SELECT listtodo
SET ORDER TO PRINTMAILI
IF EOF()
	RETURN
ENDIF
SELECT DISTINCT NEWMAILID FROM listtodo  INTO CURSOR uMAIL WHERE NOT DELETED() AND printed=.F.
SELECT uMAIL
SCAN
	LC_uMAIL=uMAIL.NEWMAILID

	SELECT listtodo
	IF SEEK (LC_uMAIL)

		SCAN FOR NEWMAILID=LC_uMAIL
			C_CERTTYPE=ALLTRIM(listtodo.CERTTYPE)


****** GET DEPT FOR HOSPITALS
			cdept="Z"
			IF LEFT(LC_uMAIL ,1)== "H"
				IF LEN(ALLTRIM(CERTTYPE))=1
					DO CASE
					CASE ALLTRIM(CERTTYPE)="P"
						cdept="P"
					CASE ALLTRIM(CERTTYPE)="R"
						cdept="M"
					CASE ALLTRIM(CERTTYPE)="B"
						cdept="B"
					CASE ALLTRIM(CERTTYPE)="X"
						cdept="R"
					ENDCASE
				ELSE

					cdept="M"


				ENDIF

			ENDIF

			DO GetDeponent WITH LC_uMAIL, cdept

			SELECT listtodo
** "b", "r", "o" , "p" FOR four BATCHES: c_hdep

			DO PRINTFLRSET WITH NEWMAILID, listtodo.rt, listtodo.donedate, c_hdep

		***
	SELECT listtodo
	ENDSCAN
	
****		
		
**fax or print+ batch rps
**default is print
		
		LOCAL c_faxnum  AS STRING, C_TEMP AS STRING, C_TEMP2 AS STRING, c_FAXSend AS STRING
		STORE "" TO c_FAXSend, c_faxnum, C_TEMP, C_TEMP2
		pl_SkipBatchPRT=.F.
		pl_Noticng=.f.
		
	  	MCLASS = IIF(!EMPTY(PC_BATCHRQ), PC_BATCHRQ,"FLRBatch") 
	
       SELECT LISTTODO 
       LOCATE FOR NEWMAILID=LC_uMAIL
       IF FOUND()
       
		IF LISTTODO.fax="Y"
			C_FAXTRAN="@R (999)999-9999"
			c_faxnum = 	TRANSFORM( ALLTRIM(DEPINFO.FAX_NO), C_FAXTRAN)
			IF LEN(c_faxnum)>=10
				
				
				C_FAX = STRTRAN( c_faxnum, " ", "")
				C_TEMP = STRTRAN( C_FAX, "-", "")
				C_TEMP2 = STRTRAN( C_TEMP, "(", "")
				c_FAXSend = STRTRAN( C_TEMP2, ")", "")

				MCLASS = IIF(!EMPTY(PC_BATCHRQ), PC_BATCHRQ,"BatchFaxCAD")
				*MCLASS = "BatchFaxA"
		

			ENDIF
		ENDIF
		ENDIF
				
				
		IF TYPE('Pc_clcode') <>'C'
		oMed_B.sqlexecute("select  [DBO].[getClCodeByLrs](  '" + ALLTRIM(STR(listtodo.rt)) +"')" , "Casecl")		
		Pc_clcode=Casecl.exp		
		ENDIF
		GNtag =0
		pn_lrsno =listtodo.rt

	&&05/19/2010 - SPLIT RPSBATCH QUEUE AS THESE ONES SHOULD NOR BE STORED AS PDF FILES
		
		
		DO prtenqa WITH MV, MCLASS, '1', c_FAXSend

	ENDIF
	SELECT listtodo
	REPLACE PRINTED WITH .T. FOR NEWMAILID=LC_uMAIL
	SELECT uMAIL
ENDSCAN

_SCREEN.MOUSEPOINTER=0
RELEASE oMed_B
RELEASE OREQUEST

RETURN

*************************GET PAGES INTO A SET PART****************************
PROCEDURE PRINTFLRSET
PARAMETERS C_MAIL, nRTNum, DDONE, c_depttodo
SET PROCEDURE TO ta_lib ADDITIVE
PRIVATE MV_TAGLEVEL
WAIT WINDOW 'Print Request..' NOWAIT
STORE "" TO mv1, mv2, mv3


*--- one per set---------------------------------
mv1= flrcover(DDONE)
mv2=flrpage2(ALLTRIM(C_MAIL), c_depttodo)
*mv3=flrlor()

**********************tag level*************************************

MV_TAGLEVEL=""
DO CASE

CASE  LEFT(ALLTRIM(C_MAIL) ,1)== "H" AND c_depttodo="P"
	lc_str= "exec [dbo].[GetCADSetHosp]'" + ALLTRIM(C_MAIL )+ "','P'"
CASE  LEFT(ALLTRIM(C_MAIL) ,1)== "H" AND c_depttodo="B"
	lc_str= "exec [dbo].[GetCADSetHosp]'" + ALLTRIM(C_MAIL )+ "','B'"
CASE  LEFT(ALLTRIM(C_MAIL) ,1)== "H" AND c_depttodo="R"
	lc_str= "exec [dbo].[GetCADSetHosp]'" + ALLTRIM(C_MAIL )+ "', 'M'"
CASE  LEFT(ALLTRIM(C_MAIL) ,1)== "H" AND c_depttodo="X"
	lc_str= "exec [dbo].[GetCADSetHosp]'" + ALLTRIM(C_MAIL )+ "','R'"
OTHERWISE

	lc_str= "exec [dbo].[GetCADSet]'" + ALLTRIM(C_MAIL )+ "'"

ENDCASE
oMed_B.sqlexecute(lc_str,"FLRSet")
** get all the details (certs + authorizations)

SELECT FlrSet
SCAN
**********CERTS
	STORE "" TO mv4,mv5
	N_REC=RECNO()

	N_PROCRT=FlrSet.lrs_no
	DO GetMaster WITH  N_PROCRT
****
	SELECT FlrSet
	n_certtag=FlrSet.TAG
***GET SPEC_INS
	l_done=oMed_B.sqlexecute("Exec  dbo.GetSpec_InsbyRTTAG '" + STR(N_PROCRT)+ "', '" + STR(n_certtag)+ "'", "Spec_ins")
	IF l_done THEN
		=CURSORSETPROP("KeyFieldList", "id_tblSpec_ins,Cl_code, TAG", "Spec_ins")
		INDEX ON CL_CODE +STR(TAG) TAG clTAG ADDITIVE
	ENDIF

	SELECT Spec_ins
	N_SPID=FlrSet.id_tblSpec_ins
	szrequest=ALLTRIM(Spec_ins.SPEC_INST)
&&CERTIFICATIONS
	mv4= flrPrintCer (n_certtag, 1,	N_SPID, .T.)

	SELECT FlrSet
	GOTO N_REC
&&AUTHORIZATIONS
	mv5= ScannedImg(N_PROCRT, n_certtag)
** MD 04/07/2009 close records that already printed
	lcSQLLine=("update tblSpec_Ins set printed=1 where cl_code='"+ALLTRIM(FlrSet.cl_code)+"' and tag="+ALLTRIM(STR(FlrSet.TAG))+" and active=1 and printed=0")
	oMed_B.sqlexecute(lcSQLLine)
	SELECT FlrSet

	MV_TAGLEVEL=MV_TAGLEVEL+(mv4+mv5)
ENDSCAN

MV=mv1+ mv2	+mv3 +MV_TAGLEVEL




RETURN MV
*****************************************************************************************************************
PROCEDURE GenerateBatch
PARAMETERS   n_rttodo, n_origtag, c_mailid, c_ctype, ;
	d_received, c_fax, c_line11, c_comment
LOCAL loRecordord AS void, ld_Today AS DATE, lcTagType AS STRING,;
	l_EntryID AS Boolean, c_parameter AS STRING, calias as String
lcTagType="CL" &&CAD LIT
_SCREEN.MOUSEPOINTER=11
*** Get MAster
DO GetMaster WITH n_rttodo
*** Get a new tag
ntag= newtag()
IF ntag =0
	gfmessage( 'Invalid Tag Number' )
	RETURN
ENDIF
c_parameter=""
WAIT WINDOW "Copy original scanned documents.." NOWAIT
n_lrsno=STR(pn_lrsno)
*** create an image based on a base autho
*** do not use that as it copies an old image: DO cscandoc WITH  STR(ntag), n_lrsno, STR(n_origtag)
l_n=1
IF l_n<=1
	c_parameter=ALLTRIM(n_lrsno)+' '+ ALLTRIM(STR(ntag))+' '+"A"+' '+ALLTRIM(c_mailid)+ ;
		' AUTHO X X X P'

	RUN /N c:\vfp\tiffauto.EXE &c_parameter
ENDIF
l_rushdepo= .F.
IF USED("Request")
	SELECT REQUEST
	USE
ENDIF
IF USED("PC_depofile")
	SELECT PC_depofile
	USE
ENDIF
pl_RushCas=.F.
pc_Isstype="A"
*** get deponent by mailid
** make sure a hospital  department is by a certtyp: B- billing,  R- med, if BR-medical dept

cdept="Z"
IF LEFT(c_mailid ,1)== "H"
	IF LEN(c_ctype)=1

		DO CASE
		CASE c_ctype="P"
			cdept="P"
		CASE c_ctype="R"
			cdept="M"
		CASE c_ctype="B"
			cdept="B"
		CASE c_ctype="X"
			cdept="R"
		ENDCASE
	ELSE
** two dept togethrs
		IF c_ctype=="RB" OR c_ctype=="BR"
			cdept="M"
		ENDIF

	ENDIF

ENDIF


DO GetDeponent WITH c_mailid, cdept


*************ADD DATA**********************************************************
lcDepName=DepInfo.NAME
IF LEFT(ALLTRIM(UPPER(c_mailid)),1) == "D"
	pc_deptype="D"
	c_drname=gfdrformat(lcDepName)
	lcDepName = IIF(NOT "DR."$c_drname,"DR. "+ALLTRIM(c_drname),c_drname)
ELSE
	pc_deptype=""
ENDIF

lc_formtype=""
d_null=NULL
d_empty=""
LHoldPsy=.F.
ld_Today=d_today
pd_revstop=IIF(ISNULL(pd_revstop), DTOC(d_empty), pd_revstop)
c_str=""
c_rev=""
IF pd_revstop<>"  /  /    " OR  pd_revstop<>""
	c_rev =IIF( pl_Review AND DTOC(ld_Today) <= pd_revstop, 'U', 'N')
ENDIF
DO CASE
CASE ALLTRIM(UPPER(cdept))=="P"
	cDeptAdd="PATH-"
CASE ALLTRIM(UPPER(cdept))=="B"
	cDeptAdd="Bills-"
CASE ALLTRIM(UPPER(cdept))=="R"
	cDeptAdd="RAD-"
OTHERWISE
	cDeptAdd=""
ENDCASE
C_DESC=LEFT(ALLTRIM(fixquote(lcDepName)) + " ("  + ALLTRIM(cDeptAdd)+ "Update) "  + IIF(EMPTY(c_line11),"","( " + fixquote(c_line11) + " )"),50)
**- add request
WAIT WINDOW 'Add New Request..' NOWAIT
c_str= "Exec dbo.AddNewRequest '" +  MASTER.id_tblMaster + "','" ;
	+ IIF(ISNULL(DepInfo.id_tbldeponents),'',DepInfo.id_tbldeponents) + "','" ;
	+ FIXQUOTE(pc_clcode) + "','" ;
	+ STR(ntag) + "','W','" ;
	+ ALLTRIM(c_mailid) + "','" ;
	+ ""+ "','" ;
	+ "CADBATCH" + "','" ;
	+ C_DESC + "'  ,'" + DTOC(ld_Today)  + "','" + DTOC(ld_Today) + "' ,"   ;
	+ STR(0) + ",'" ;
	+  d_empty + "','" ;
	+ "A" + "','"  ;
	+ c_rev + "'," ;
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
	+ ALLTRIM(lc_formtype) + "'," ;
	+ IIF(LHoldPsy, STR(1),STR(0)) 	+ ",0,null "

**get new record's id
lRequest=oMed_B.sqlexecute(c_str,"")
l_RqId=oMed_B.sqlexecute( "select dbo.fn_GetID_tblRequest ('" + FIXQUOTE(MASTER.CL_CODE) + "','" +  STR(ntag) + "')", "ReqsId")
IF NOT lRequest
	=gfmessage("A tag was not added. Contact IT.")

	RETURN
ELSE
**update Tag count in master
	c_str= "Update tblMaster set subcnt='" +  STR(ntag) + "' Where cl_code = '" + FIXQUOTE(MASTER.CL_CODE) + "' and active =1"
	l_TagCntUpd=oMed_B.sqlexecute(c_str , "")
	IF NOT l_TagCntUpd
		=gfmessage("Tag count was not updated. Contact IT dept.")
	ENDIF
ENDIF
pc_mailid=c_mailid
pl_StopPrtIss=.F.
STORE "" TO lcSQLLine,C_TYPE


C_TYPE=GETTRUECERT(c_ctype)
D_date =  (d_received-30)
*** - fill a true cert type in char_fld, scope beg date in date_fld and fld_name as "CADBatch" to identify that data when printing
lcSQLLine="update tblRequest set tag_type='"+ALLTRIM("CL")+"', PrintOrigReq =" +  IIF(pl_StopPrtIss, STR(1),STR(0)) + ;
	" , REQ_DATE='" + DTOC(ld_Today) + "', SEND_DATE ='"+ DTOC(ld_Today)+ "'," ;
	+ " char_fld = '" + ALLTRIM(C_TYPE) + "', date_fld='" + DTOC(D_date) +"', fld_name='CADBATCH'" ;
	+ " where "+;
	"id_tblrequests='"+ReqsId.EXP+"'"
oMed_B.sqlexecute(lcSQLLine)
*------------------------------get the tag type-------------------------------------------

pc_Isstype="A"
pn_TAG =ntag
**- add orders

WAIT WINDOW 'Add Orders..SpecIns..Notice' NOWAIT
DO SetOrdTg WITH ntag

**-add txn 11


c_str= "Exec dbo.gfAddTxn '" + DTOC(DATE())+  " ', '" ;
	+ ALLTRIM(NVL(FIXQUOTE(lcDepName)  ,"")) +  " (UPDATE)','" + pc_clcode + "',' " ;
	+ ALLTRIM(STR(11)) + "','"  + ALLTRIM(STR(ntag)) + "','" ;
	+ NVL(ALLTRIM(c_mailid),"") + "','" + STR(0) + "','" ;
	+ ALLTRIM(STR(0)) + "','" +  "" + "','" ;
	+ ALLTRIM(STR(0)) + "', '"  + "" + "','" ;
	+ "A" + "','" ;
	+ ALLTRIM("CADBATCH") + "','" ;
	+ ReqsId.EXP +"'"

l_done=oMed_B.sqlexecute(c_str,"")
IF USED('EntryID')
	SELECT EntryID
	USE
ENDIF

l_EntryID= oMed_B.sqlexecute("select dbo.fn_GetID_tblTimesheet ('" + pc_clcode + "','" ;
	+ STR(ntag) +"','" + STR(11)+ "','" +DTOC(DATE()) +"')", "EntryId")

	
IF l_EntryID



**-add spec inst/merge a blurb

	pc_CertTyp=""
	c_certType=""
	c_certType2=""
	c_certType1=""
	c_certType3=""

	IF LEN(ALLTRIM(listtodo.certtype))>1
		c_certType1=GetCertType (ALLTRIM(listtodo.certtype), 1)
		c_blurb1= getflrblurb( d_received, c_certType1, c_comment)
		IF  c_certType1="I" OR c_certType1= "W" OR c_certType1= "Y" OR c_certType1= "D"
			c_certType1="R"
		ENDIF

		c_certType2=GetCertType (ALLTRIM(listtodo.certtype), 2)
		c_blurb2= getflrblurb( d_received, c_certType2, c_comment)
		IF  c_certType2="I" OR c_certType2= "W" OR c_certType2= "Y" OR c_certType1= "D"
			c_certType2="R"
		ENDIF
		c_blurb= c_blurb1+ CHR(13) + c_blurb2

		c_certType3=GetCertType (ALLTRIM(listtodo.certtype), 3)
		IF LEN(ALLTRIM(c_certType3))>0
			c_blurb3= getflrblurb( d_received, c_certType3, c_comment)
			IF  c_certType3="I" OR c_certType3= "W" OR c_certType3= "Y" OR c_certType1= "D"
				c_certType3="R"
			ENDIF
			c_blurb= c_blurb1+ CHR(13) + c_blurb2+ CHR(13) + c_blurb3
		ENDIF
	ELSE
		c_certType1=GetCertType (ALLTRIM(listtodo.certtype), 1)
		c_blurb1= getflrblurb( d_received, c_certType1, c_comment)
		IF  c_certType1="I" OR c_certType1= "W" OR c_certType1= "Y" OR c_certType1= "D"
			c_certType1="R"
		ENDIF

		c_blurb= c_blurb1
	ENDIF
	
	c_certType=c_certType1+IIF (NOT EMPTY(ALLTRIM(c_certType2)),c_certType2, '')+IIF (NOT EMPTY(ALLTRIM(c_certType3)),c_certType3, '')
	pc_CertTyp=c_certType
	pc_UserID="CADBATCH"
	DO AddSpecIns2 WITH EntryID.EXP, pc_clcode, ntag, ALLTRIM(lcDepName),"A", ALLTRIM(c_mailid), IIF (!EMPTY(cdept),cdept,"Z"),c_blurb
**-add notices
	lc_str="Exec dbo.sp_AddNotice '" ;
		+ pc_clcode + "','" ;
		+ STR(ntag) + "','" ;
		+ DTOC(d_today) + "','" ;
		+  DTOC(d_today +10) + "','" ;
		+ FIXQUOTE(lcDepName) + "','" ;
		+ FIXQUOTE(c_blurb)+ "','" ;
		+ ALLT(pc_rqatcod) + "','" ;
		+ pc_Litcode + "','" ;
		+ "0000"  + "','" ;
		+ ALLTRIM(c_mailid) + "','" ;
		+ "A" + "'," ;
		+ STR(0) + " ," ;
		+ STR(0) + "," ;
		+ STR(0) + ", null, '','', '', '" ;
		+ "CADBatch" + "'," + STR(0) ;
		+ ",''"
	l_Notice=oMed_B.sqlexecute(lc_str,"")

** add a fax transaction (66) --5/6/2010	
IF ALLTRIM(LISTTODO.fax)="Y" AND LEN(ALLTRIM(DEPINFO.FAX_NO))=10
IF  NOT INLIST(NVL(DEPINFO.CATEGORY1,''),'G' ,'P')


&&ReqsId.EXP
IF USED('Request')
	SELECT request
	USE
endif			
	*DO AddPhnTx WITH 1, ntag	
	&&5/8/17 #61920/21		
	DO FaxMemo WITH  1, ntag
endif		
** add a fax transaction (66) --5/6/2010		

ENDIF
ENDIF &&skip 66 for batch requests 5/20/2010
_SCREEN.MOUSEPOINTER=0


*******************************************************************************************
FUNCTION getflrblurb
*******************************************************************************************
PARAMETERS  ddate , c_cert, c_comm
PRIVATE cText3 AS STRING, cText1 AS STRING, cText2 AS STRING, ctext AS STRING
STORE "" TO cText1,cText2,cText3, ctext
&& specific blurbs
IF NOT USED('cadblurbs')
	USE 'T:\VFPFree\Global\cadblurbs.dbf' IN 0
ENDIF
SELECT cadblurbs
SET ORDER TO certtype   && CERTTYPE
IF SEEK(c_cert)
	cText1 =ALLTRIM(cadblurbs.part1)
	cText2 =ALLTRIM(cadblurbs.part2)

**D_date = gfChkDat( (ddate-30), .F., .F.)
	cText3 = " " + DTOC(ddate -30) + " "
	ctext=cText1 + cText3 + cText2  + ' ' + c_comm
ELSE
	gfmessage("No blurb is found for that issue. Contact IT dept.")
ENDIF

RETURN ctext
************************************************************
FUNCTION GetCertType
************************************************************
PARAMETERS ccerttype, n_id
*!*	IF n_id=1 AND LEN(ALLTRIM(ccerttype))=2
*!*		C_TYPE=RIGHT(ALLTRIM(ccerttype), 1)
*!*	ELSE
*!*		C_TYPE=LEFT(ALLTRIM(ccerttype), 1)
*!*	ENDIF
C_TYPE=SUBSTR(ALLTRIM(ccerttype), n_id,1)
RETURN C_TYPE

*****************************************************************
FUNCTION flrcover
PARAMETERS DISSUE
**************************************************************************
PRIVATE  MV_1
MV_1=''
lcDepName=DepInfo.NAME
IF LEFT(ALLTRIM(UPPER(DepInfo.mailid_no)),1) == "D"
	c_drname=gfdrformat(lcDepName)
	lcDepName = IIF(NOT "DR."$c_drname,"DR. "+ALLTRIM(c_drname),c_drname)
ENDIF
c_name=ALLTRIM(lcDepName)
c_address=ALLTRIM(DepInfo.add1)
c_address2=ALLTRIM(DepInfo.add2)
c_city=ALLTRIM(DepInfo.city)
c_st=ALLTRIM(DepInfo.state)
c_zip=LEFT(ALLTRIM(DepInfo.zip),5)
c_Attn=ALLTRIM(DepInfo.attN)

DO PrintGroup WITH MV_1, "FLRCover"
DO PrintField WITH MV_1, "DeponentName", c_name
DO PrintField WITH MV_1, "DeponentAddress", c_address
DO PrintField WITH MV_1, "DeponentAddress2", c_address2
DO PrintField WITH MV_1, "DeponentCity", c_city
DO PrintField WITH MV_1, "DeponentST", c_st
DO PrintField WITH MV_1, "DeponentZip", c_zip
DO PrintField WITH MV_1, "DeponentAttn", c_Attn
DO PrintField WITH MV_1, "IssueDate", DTOC(DISSUE)


RETURN MV_1
******************************************************************************
FUNCTION flrpage2
******************************************************************************
PARAMETERS cmail, c_depttodo
PRIVATE  MV_2
MV_2=""
IF USED("tempRT")
	USE IN tempRT
ENDIF
SELECT 0
CREATE CURSOR tempRT (rt N(10))
INDEX ON rt TAG rt

SELECT listtodo

DO PrintGroup WITH MV_2, "FLR2Page"

SCAN FOR ALLTRIM(UPPER(NEWMAILID))=ALLTRIM(UPPER(cmail))
	SELECT tempRT
	SEEK listtodo.rt
	IF FOUND()
		LOOP
	ELSE
		INSERT  INTO tempRT VALUES(listtodo.rt)
	ENDIF
	SELECT listtodo

	n_rt=rt

	DO CASE
	CASE  LEFT(ALLTRIM(cmail) ,1)== "H" AND c_depttodo="P"
		lc_str="EXEC [dbo].[GetCADBatchRequestH]' " +STR(n_rt) + "','" + cmail + "', 'P'"
	CASE  LEFT(ALLTRIM(cmail) ,1)== "H" AND c_depttodo="B"
		lc_str="EXEC [dbo].[GetCADBatchRequestH]' " +STR(n_rt) + "','" + cmail + "', 'B'"
	CASE  LEFT(ALLTRIM(cmail) ,1)== "H" AND c_depttodo="R"
		lc_str="EXEC [dbo].[GetCADBatchRequestH]' " +STR(n_rt) + "','" + cmail + "', 'M'"
	OTHERWISE
		lc_str="EXEC [dbo].[GetCADBatchRequest]' " +STR(n_rt) + "','" + cmail + "'"

	ENDCASE


	oMed_B.sqlexecute(lc_str,"FLRRequest")
	SELECT FLRRequest

	IF NOT EOF()
		SELECT FLRRequest
		IF NOT EOF()
			SCAN
				DO PrintGroup WITH MV_2, "Item"

				DO PrintField WITH MV_2, "Col1", STR(n_rt)
				DO PrintField WITH MV_2, "Col2", STR(FLRRequest.TAG)
				DO PrintField WITH MV_2, "Col3", ALLTRIM(CaseName)
				DO PrintField WITH MV_2, "Col4",ALLTRIM(FLRRequest.aka)&&"###-##-" + RIGHT( ALLT( soc_sec), 4)
				DO PrintField WITH MV_2, "Col5","###-##-" + RIGHT( ALLT( soc_sec), 4)
				DO PrintField WITH MV_2, "Col6", FLRRequest.truecert
				c_date =getdaterange(FLRRequest.scopedate)
				DO PrintField WITH MV_2, "Col7", c_date
				DO PrintField WITH MV_2, "Col8", ""
				DO PrintField WITH MV_2, "Col9", ""
				SELECT FLRRequest
			ENDSCAN
		ELSE
			MV_2=""
		ENDIF
	ENDIF  && NOT EMPTY

	SELECT listtodo
*SELECT ISDONE
ENDSCAN
SELECT listtodo
RETURN MV_2
*******************************************************************
FUNCTION flrlor
*******************************************************************
PRIVATE  MV_3
MV_3=''
*!*	c_DocName = PrintLOR('A')
*!*	DO PrintGroup WITH MV_3, c_DocName
RETURN MV_3

*******************************************************************
FUNCTION GETTRUECERT
*******************************************************************
PARAMETERS l_cCertType
PRIVATE l_cWhat AS STRING

l_cWhat=""
nRec = LEN( ALLTRIM(l_cCertType))
l_nCnt = 1
DO WHILE .T.
	IF l_nCnt > nRec
		EXIT
	ENDIF
	l_cDblLtr = SUBSTR( l_cCertType, l_nCnt, 1)
	l_cDblLtr2 = STRTRAN( l_cCertType, l_cDblLtr, "", 2,  1)
	l_cCert = SUBSTR( l_cDblLtr2, l_nCnt, 1)
	l_cCertType = l_cDblLtr2

	DO CASE
	&&5/7/2010 added "D" per Julie
	CASE l_cCert == "D"
		IF l_nCnt=1
			l_cWhat="Disability"
		ELSE
			l_cWhat =l_cWhat + ","  + " Disability Records"
		ENDIF

	CASE l_cCert == "Y"
		IF l_nCnt=1
			l_cWhat="Pharmacy"
		ELSE
			l_cWhat =l_cWhat + ","  + " Pharmacy Records"
		ENDIF
	CASE l_cCert == "W"
		IF l_nCnt=1
			l_cWhat="Workers Comp."
		ELSE
			l_cWhat =l_cWhat + ","  + " Workers Comp."
		ENDIF
	CASE l_cCert == "I"
		IF l_nCnt=1
			l_cWhat="Insurance"
		ELSE
			l_cWhat =l_cWhat + ","  + " Insurance"
		ENDIF


	CASE l_cCert == "P"
		IF l_nCnt=1
			l_cWhat="Pathology"
		ELSE
			l_cWhat =l_cWhat + ","  + " Pathology"
		ENDIF
	CASE l_cCert == "B"
		IF l_nCnt=1
			l_cWhat="Billing"
		ELSE

			l_cWhat = l_cWhat + "," +  " Billing"
		ENDIF
	CASE l_cCert == "X"
		IF l_nCnt=1
			l_cWhat="Radiology"
		ELSE

			l_cWhat = l_cWhat + "," +  " Radiology"
		ENDIF
	OTHERWISE
		IF l_nCnt=1
			l_cWhat ="Medical"
		ELSE

			l_cWhat = l_cWhat + "," + " Medical"
		ENDIF
	ENDCASE

	l_nCnt = l_nCnt + 1
ENDDO

RETURN l_cWhat
*****************************************************************
FUNCTION getdaterange
*****************************************************************
PARAMETERS ddate
*D_SCOPE=gfChkDat(ddate -30,.F.,.F.)
c_tx =DTOC(ddate  )+  " To Present"

RETURN c_tx
*****************************************************************
FUNCTION ScannedImg
******************************************************************
PARAMETERS n_lrsno, n_tag
PRIVATE  MV_5
MV_5 =""
creqType="A"
pl_scansub=.F.
MV_5=  ScnAuth (STR(n_lrsno), n_tag)
RETURN MV_5


**********************************************************************
PROCEDURE ScnAuth
**********************************************************************
PARAMETERS lcLrs,ntag
SET SAFETY OFF
PRIVATE filehand, i,  lcSource, lcDest, lcSPath, lcDPath, lFileExt
PUBLIC  mv_a
mv_a=""
lFileExt = ".TIF"
F_PCX=IIF(pl_ofcoaK, goApp.capcx ,goApp.pcxpath)
F_PCXARCH=IIF(pl_ofcoaK,goApp.capcxarch,goApp.pcxarchpath)
lcLrs = ALLT( lcLrs)

lcSPath = F_PCX + lcLrs
lcDPath = F_PCXARCH + RIGHT(lcLrs,1) + "\" + lcLrs

****** Send single autho page if it exists (lllll.TIF) ******
lcSource = lcSPath + lFileExt
lcDest   = lcDPath + lFileExt

IF NOT Send_Pg( lcSource, lcDest)

	IF (pl_ofcKOP OR pl_ofcMD OR pl_ofcPgh)
		lcSource = lcSPath + ".PCX"
		lcDest   = lcDPath + ".PCX"
		= Send_Pg( lcSource, lcDest)
	ENDIF
ENDIF
****** Send autho pages for the case (llllCn.TIF)
FOR i = 1 TO 9
	lcSource = lcSPath + "C" + TRANS(i, "9") + lFileExt
	lcDest   = lcDPath + "C" + TRANS(i, "9") + lFileExt

	IF NOT Send_Pg(lcSource, lcDest)
		IF pl_ofcKOP OR pl_ofcMD OR pl_ofcPgh
			lcSource = lcSPath + "C" + TRANS(i, "9") + ".PCX"
			lcDest   = lcDPath + "C" + TRANS(i, "9") + ".PCX"
			= Send_Pg( lcSource, lcDest)
		ENDIF
*EXIT
	ENDIF
ENDFOR

****** Send autho pages for this specific tag (llllTn.ttt)
FOR i = 1 TO 9
	lcSource = lcSPath + "T" + TRANS(i, "9") + "." + TRANS(ntag, "@L 999")
	lcDest   = lcDPath + "T" + TRANS(i, "9") + "." + TRANS(ntag, "@L 999")

	IF NOT Send_Pg( lcSource, lcDest)
		EXIT
	ENDIF
ENDFOR


IF  NOT EMPTY(creqType)
****** Send pages for this specific tag (llllTnc.ttt)
	FOR i = 1 TO 9
		lcSource = lcSPath + "T" + TRANS(i, "9") + ;
			creqType + "." + TRANS(ntag, "@L 999")
		lcDest   = lcDPath + "T" + TRANS(i, "9") + ;
			creqType + "." + TRANS(ntag, "@L 999")
		IF NOT Send_Pg(lcSource, lcDest)
			EXIT
		ENDIF
	ENDFOR


	FOR i = 1 TO 9
		lcSource = lcSPath + creqType + TRANS(i, "9") + ;
			"." + TRANS(ntag, "@L 999")
		lcDest   = lcDPath + creqType + TRANS(i, "9") + ;
			"." + TRANS(ntag, "@L 999")
		IF NOT Send_Pg(lcSource, lcDest)
			EXIT
		ENDIF
	ENDFOR


	FOR i = 1 TO 9
		lcSource = lcSPath + "B" + TRANS(i, "9") + "." + TRANS(ntag, "@L 999")
		lcDest   = lcDPath + "B" + TRANS(i, "9") + "." + TRANS(ntag, "@L 999")
		Send_Pg( lcSource, lcDest)
	ENDFOR

ENDIF



* -- SET SAFETY ON && 03/10/2021 MD #230210  
RETURN mv_a


*******************************************************************************************
PROCEDURE sendauth
*******************************************************************************************
PARAMETERS thepcx
lcDepName=DepInfo.NAME
IF LEFT(ALLTRIM(UPPER(DepInfo.mailid_no)),1) == "D"
	c_drname=gfdrformat(lcDepName)
	lcDepName = IIF(NOT "DR."$c_drname,"DR. "+ALLTRIM(c_drname),c_drname)
ENDIF
dep_date = d_today
dep_date = gfChkDat( dep_date, .F., .F.)
DO PrintGroup WITH mv_a,  "Authorization"
DO PrintField WITH mv_a, "Id", thepcx

DO PrintField WITH mv_a, "Loc", ;
	IIF(pl_ofcMD OR pl_ofcPgh, "P", pc_Offcode)
DO PrintGroup WITH mv_a, "Deponent"
DO PrintField WITH mv_a, "Name", lcDepName
DO PrintField WITH mv_a, "Addr", DepInfo.add1
DO PrintField WITH mv_a, "City", DepInfo.city
DO PrintField WITH mv_a, "State",DepInfo.state
DO PrintField WITH mv_a, "Zip", LEFT(ALLTRIM(DepInfo.zip),5)
DO PrintGroup WITH mv_a, "Control"
DO PrintField WITH mv_a, "Date", DTOC( dep_date)

RETURN


*******************************************************************************************
FUNCTION Send_Pg
*******************************************************************************************
PARAMETERS lcFrom, lcTo

PRIVATE n_Pos, n_FileLen
n_Pos = AT("\", lcFrom, 2)
n_FileLen = LEN(ALLTRIM(lcFrom)) - n_Pos
IF n_FileLen > 12
	RETURN .T.
ENDIF

filehand = FOPEN(lcFrom)
IF filehand <> -1
	=FCLOSE(filehand)
	COPY FILE (lcFrom) TO (lcTo)
	DELETE FILE (lcFrom)
	DO sendauth WITH lcTo
ELSE
	filehand = FOPEN(lcTo)
	IF filehand <> -1
		=FCLOSE(filehand)
		DO sendauth WITH lcTo
	ELSE
		RETURN .T.
	ENDIF
ENDIF
RETURN .T.
**********************************************************************************************
PROCEDURE GetDeponent
**********************************************************************************************
PARAMETERS lc_mailid, lcdept

WAIT WINDOW "Getting Deponent's information" NOWAIT NOCLEAR
pc_BatchRq=""

l_mail=oMed_B.sqlexecute("exec dbo.GetDepInfoByMailIdDept  '" + ALLTRIM(lc_mailid)  +"','" + lcdept + "' ", "DepInfo")
SELECT DepInfo
IF EOF()
	l_mail=oMed_B.sqlexecute("exec dbo.GetDepInfoByMailIdDept  '" + ALLTRIM(lc_mailid)  +"','" + "Z" + "' ", "DepInfo")
ENDIF


pc_BatchRq=IIF(INLIST(NVL(CATEGORY1,''),'G', 'P'), "CADRPSBATCH","")


=CURSORSETPROP("KeyFieldList", "Code, id_tbldeponents", "DepInfo")
_SCREEN.MOUSEPOINTER=0
RETURN

*************************************************************************************************
PROCEDURE GetMaster
**************************************************************************************************
PARAMETERS ln_rttodo

oMed_B.sqlexecute("exec dbo.GetMasterbyRTNumber '"+STR(ln_rttodo) + "'" ,"Master")
pl_GotCase =.F.
DO gfgetcas

RETURN


*------------------------------------------------
FUNCTION AddSpecIns2
**Called from the subp_pa.

PARAMETERS c_TSID, c_clcode,n_tag, c_descript, c_reqType, c_mid, c_dept, c_request
LOCAL l_specid AS Boolean oMed2 as object
*--d_today=DATE()
IF TYPE("pcPublicBlurb")!="C"
	pcPublicBlurb=""
ENDIF
IF EMPTY(ALLTRIM(c_request))
	IF EMPTY(ALLTRIM(pcPublicBlurb))
		gfmessage("Blurb is missing.  Please notify IT department!")
	ELSE
		c_request=ALLTRIM(pcPublicBlurb)
	ENDIF
ENDIF

oMed2 = CREATEOBJECT("generic.medgeneric")
C_STR="Exec dbo.EditSpecIns  NULL " + ",'" + c_TSID	+ ;
	"', '" + fixquote(c_clcode) + "','" + STR(n_tag) + "','" + ;
	fixquote(c_request)+ "','"  + fixquote(c_descript) + "','" + ;
	DTOC(d_today) + "','" +  c_reqType + "'," + STR(0)+ ",'"  + ;
	c_mid + "','" + c_dept + "','" +	pc_CertTyp + "','" +STR(0) + "','" + ;
	DTOC(d_today)+ "','" + pc_UserID + "'," +	STR(1) + "," + STR(0) + ",'" + "" + "'"

l_specid=omed2.sqlexecute(C_STR,"EditSp")

RETURN l_specid
*--------------------------------------------------------------------------------------------------
PROCEDURE loadFile2Proc
LPARAMETERS lcProcFile
LOCAL lcCur, lcFile,lcDefault, lcFileName, lcretVal
lcCur=SYS(5) +SYS(2003)
lcDefault="c:\temp\"
lcretVal=.F.
SET DEFAULT TO &lcDefault
lcFile=GETFILE("XLS","Load Batch List")

IF NOT EMPTY(ALLTRIM(lcFile))
	lcFile="'"+ALLTRIM(lcFile)+"'"
	SET DEFAULT TO &lcCur
	USE &lcProcFile EXCLUSIVE
	ZAP
	USE
	DO loadXLS WITH &lcFile, lcProcFile
	lcFileName=DBF()
	USE
	USE &lcProcFile ALIAS TodoFile EXCLUSIVE
	GO TOP
	DELETE NEXT 1
	DELETE FOR EMPTY(ALLTRIM(origMailID)) AND EMPTY(ALLTRIM(NewMailID))
	SELECT 0
	USE IN TodoFile
	lcretVal=.T.
	lcRenameFile="'"+ADDBS(JUSTPATH(lcFile))+"load_"+JUSTFNAME(lcFile)+"'"
	IF FILE(lcRenameFile)
		DELETE FILE &lcRenameFile
	ENDIF
	RENAME &lcFile TO &lcRenameFile
ENDIF
RETURN lcretVal


*------------------------------------------------------------------------------------------------------
PROCEDURE loadXLS
PARAMETERS c_file,  lcTemplate

USE &lcTemplate IN 0 ALIAS template

oleApp = CREATEOBJECT("Excel.Application")    && Launch Excel.
oleApp.VISIBLE=.F.                            && Display Excel.
oleApp.Workbooks.OPEN(c_file)        && Open the template

FOR lnrowCnt=1 TO oleApp.ROWS.COUNT

	SELECT  template
	APPEND BLANK
	FOR lnFldCnt=1 TO oleApp.cells.COUNT
		lcField=ALLTRIM(FIELD(lnFldCnt))

		IF EMPTY(NVL(lcField,""))
			EXIT
		ENDIF && no more columns

		lcValue=  oleApp.Cells(lnrowCnt,lnFldCnt).VALUE

		IF !EMPTY(ALLTRIM(lcField)) AND ISNULL(lcValue)<>.T.
			REPLACE &lcField WITH convertField(&lcField, lcValue)

		ENDIF


	NEXT

	IF EMPTY(NVL(oleApp.Cells(lnrowCnt+1,1).VALUE,"")) AND  EMPTY(NVL(lcValue,""))
		oleApp.DisplayAlerts = 0
		oleApp.QUIT
		RETURN  &&eof
	ENDIF

NEXT && go to the next row

oleApp.DisplayAlerts = 0

*oleApp.ActiveWorkbook.SAVE

oleApp.QUIT


RETURN



*--------------------------------------

FUNCTION convertField
LPARAMETERS lxInField, lxOutField
DO CASE
CASE TYPE("lxInField")="C"
	lxOutField=convertToChar(lxOutField,1)
CASE TYPE("lxInField")="N"
	lxOutField=convertToNum(lxOutField)
CASE TYPE("lxInField")="D"
	lxOutField=convertToDate(lxOutField)
CASE TYPE("lxInField")="T"
	lxOutField=convertToDate(lxOutField)
CASE TYPE("lxInField")="L"
	lxOutField=convertToBool(lxOutField,2)

ENDCASE

RETURN lxOutField

PROCEDURE getRequestbyRTtag

lPARAMETERS lcClCode, lnTag
IF USED("request")
   USE IN request
ENDIF    
PRIVATE OMED2 AS OBJECT
OMED2=CREATEOBJECT("generic.medgeneric")
OMED2.SQLEXECUTE("select * from tblrequest where cl_code='"+ALLTRIM(lcClCode) + "' and tag ='" +ALLTRIM(STR(lntag)) + "' and active=1" ,"Request")

RELEASE OMED2
RETURN

