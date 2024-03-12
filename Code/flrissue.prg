*******************************************************************************************
** EF FLR Batch Issue/Print -3/27/09
*******************************************************************************************
***********************Add Tags First*******************************************************
PROCEDURE StartIt
PRIVATE omed AS OBJECT
PUBLIC MV
&& listtodo.dbf : Julie's list of the cases/tags
PRIVATE l_c as String, l_cUser as String
l_cUser=""
PRIVATE c_Retval
omed=CREATEOBJECT("medmaster")
c_Retval="O"
l_c= INPUTBOX("Please Pick - (B(ills), R(ecords), X(Radiology), O(ther), S(kip)) or C(ancel)", "Pick a department to add Tags ")
LOCAL lcpath AS String
lcpath=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","GLOBAL", "\")))

DO case
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
 IF ALLTRIM(upper(l_c)) <>"S"
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
	     IF isTagCanceled(listtodo.rt, listtodo.origtag)=.F.		
	        DO  GenerateBatch  WITH listtodo.rt, listtodo.origtag, listtodo.NEWMAILID, ALLTRIM(listtodo.certtype)
	        REPLACE donedate WITH DATE(), comment WITH "" IN listtodo
         ELSE 
            REPLACE donedate WITH DATE(), comment WITH "The tag doesn't have any ordering attorneys", ;
            printed WITH .T., skipissue WITH .T. IN listtodo
         ENDIF 
    ENDSCAN
ENDIF 
***********************Now Print*******************************************************
** change parameters "B" to "R" for Hospital's batches and "O" (Others) when done with Hospitals B and R. 
	**HAVE TO DO IT TWICE IN TWO PALCES:  #1 BELOW
***********************************************************************

MV=""

**#1
**b-BILLING
**r- MEDICAL
**O - ALL OTHER

PRIVATE l_c as String
PRIVATE c_Retval
c_Retval="O"
l_c= INPUTBOX("Please Pick -(B(ills), R(ecords), X(Radiology), O(ther)) or C(ancel)", "Pick a department to Print Documents")
DO CASE 
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
        gfMessage("The documents wil not be printed")
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

RELEASE omed
RETURN

*******************************************

PROCEDURE GETSETS
PARAMETERS c_hdep
_SCREEN.MOUSEPOINTER=11

pc_offcode='P'
PRIVATE C_CERTTYPE AS String, c_file AS String
C_CERTTYPE=""
IF USED ('LISTTODO')
	SELECT LISTTODO
	USE
ENDIF
DO case
 CASE c_hdep ="B"
  	c_file="T:\vfpfree\GLOBAL\Blisttodo.DBF" 
 CASE c_hdep ="R"
 	c_file="T:\vfpfree\GLOBAL\Rlisttodo.DBF" 
 CASE c_hdep ="X"
 	c_file="T:\vfpfree\GLOBAL\Xlisttodo.DBF" 
 OTHERWISE
	c_file="T:\vfpfree\GLOBAL\listtodo.DBF" 
 endcase
SELECT 0
USE (c_file) ALIAS  listTodo
******************************




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
		   	  	    	    
		SCAN FOR NEWMAILID=LC_uMAIL	AND printed=.F.			    
			C_CERTTYPE=ALLTRIM(listtodo.CERTTYPE)
			*IF C_CERTTYPE<>c_hdep
			*loop
			*ENDIF            
		
		
		
****** GET DEPT FOR HOSPITALS
			cdept="Z"
			IF LEFT(LC_uMAIL ,1)== "H"
				IF LEN(ALLTRIM(CERTTYPE))=1
					DO CASE
					CASE ALLTRIM(CERTTYPE)="R"
						cdept="M"
					CASE ALLTRIM(CERTTYPE)="B"
						cdept="B"
				    CASE ALLTRIM(CERTTYPE)="X"
						cdept="R"
					ENDCASE
				ELSE
** two dept together
					*IF ALLTRIM(CERTTYPE)=="RB" OR ALLTRIM(CERTTYPE)=="BR"
						cdept="M"
					*ENDIF

				ENDIF

			ENDIF
*******

			DO GetDeponent WITH LC_uMAIL, cdept
			
			SELECT listtodo
			** "b", "r", "o" FOR THREE BATCHES: c_hdep
			DO PRINTFLRSET WITH NEWMAILID, listtodo.rt, listtodo.donedate, c_hdep
			
			SELECT listtodo
		ENDSCAN
		gntag=0		
		DO prtenqa WITH MV, "FLRBATCH", '1', ""
	ENDIF
	SELECT listtodo
	REPLACE PRINTED WITH .t. FOR NEWMAILID=LC_uMAIL	
	SELECT uMAIL
ENDSCAN

_SCREEN.MOUSEPOINTER=0
RELEASE omed
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
** *** "b", "r", "o" FOR THREE BATCES: c_hdep
mv2=flrpage2(ALLTRIM(C_MAIL), c_depttodo)
mclass="FLRBatch"
mgroup="10"

PL_POPCORN2=.T.
mv3=flrlor()

**********************tag level*************************************

MV_TAGLEVEL=""
*  MD 04/07/2009 pull only records that were not printed tblSpec_Ins.printed=0
DO CASE 
CASE  LEFT(ALLTRIM(C_MAIL) ,1)== "H" AND c_depttodo="B"
	lc_str= "exec [dbo].[GetFLRSetHospB]'" + ALLTRIM(C_MAIL )+ "'"
CASE  LEFT(ALLTRIM(C_MAIL) ,1)== "H" AND c_depttodo="R"
	lc_str= "exec [dbo].[GetFLRSetHospR]'" + ALLTRIM(C_MAIL )+ "'"
CASE  LEFT(ALLTRIM(C_MAIL) ,1)== "H" AND c_depttodo="X"
	lc_str= "exec [dbo].[GetFLRSetHospX]'" + ALLTRIM(C_MAIL )+ "'"	
otherwise

lc_str= "exec [dbo].[GetFLRSet]'" + ALLTRIM(C_MAIL )+ "'"

endcase
omed.sqlexecute(lc_str,"FLRSet")
** get all the details (certs + authorizations)

SELECT FlrSet
SCAN
**********CERTS
	STORE "" TO mv4,mv5
	N_REC=RECNO()

	N_PROCRT=FlrSet.lrs_no
*** if some files are not open- reopen them here??
	DO GetMaster WITH  N_PROCRT
****
   
	SELECT FlrSet
	n_certtag=FlrSet.TAG	
***GET SPEC_INS
	l_done=omed.sqlexecute("Exec  dbo.GetSpec_InsbyRTTAG '" + STR(N_PROCRT)+ "', '" + STR(n_certtag)+ "'", "Spec_ins")
	IF l_done THEN
		=CURSORSETPROP("KeyFieldList", "id_tblSpec_ins,Cl_code, TAG", "Spec_ins")
		INDEX ON CL_CODE +STR(TAG) TAG clTAG ADDITIVE
	ENDIF

	SELECT Spec_ins
*SEEK (c_code) + STR(n_certtag)
	N_SPID=FlrSet.id_tblSpec_ins
	szrequest=ALLTRIM(Spec_ins.SPEC_INST)
&&CERTIFICATIONS    
	mv4= flrPrintCer (n_certtag, 1,	N_SPID, .T.)

	SELECT FlrSet
	GOTO N_REC
&&AUTHORIZATIONS
	mv5= ScannedImg(N_PROCRT, n_certtag)
	** MD 04/07/2009 close records that already printed
    lcSQLLine=("update tblSpec_Ins set printed=1 where cl_code='"+ALLTRIM(FlrSet.cl_code)+"' and tag="+ALLTRIM(STR(FlrSet.tag))+" and active=1 and printed=0")
    omed.sqlexecute(lcSQLLine)
	SELECT FlrSet

	MV_TAGLEVEL=MV_TAGLEVEL+(mv4+mv5)
ENDSCAN

MV=mv1+ mv2	+mv3 +MV_TAGLEVEL




RETURN MV
*****************************************************************************************************************
PROCEDURE GenerateBatch
PARAMETERS   n_rttodo, n_origtag, c_mailid, c_ctype
LOCAL loRecordord AS void, ld_Today AS DATE, lcTagType AS STRING,;
	l_EntryID AS Boolean, c_parameter AS STRING
lcTagType="FL"
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
	c_drname=gfdrformat(lcDepName)
	lcDepName = IIF(NOT "DR."$c_drname,"DR. "+ALLTRIM(c_drname),c_drname)
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
   CASE ALLTRIM(UPPER(cdept))=="B"
       cDeptAdd="Bills-"
   CASE ALLTRIM(UPPER(cdept))=="R"
       cDeptAdd="RAD-"
   OTHERWISE 
       cDeptAdd=""
ENDCASE        
C_DESC=ALLTRIM(fixquote(lcDepName)) + " ("  + ALLTRIM(cDeptAdd)+ "Update)" 
**- add request
WAIT WINDOW 'Add New Request..' NOWAIT
c_str= "Exec dbo.AddNewRequest '" +  MASTER.id_tblMaster + "','" ;
	+ IIF(ISNULL(DepInfo.id_tbldeponents),'',DepInfo.id_tbldeponents) + "','" ;
	+ FIXQUOTE(pc_clcode) + "','" ;
	+ STR(ntag) + "','W','" ;
	+ ALLTRIM(c_mailid) + "','" ;
	+ ""+ "','" ;
	+ "FLRBATCH" + "','" ;
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
lRequest=omed.sqlexecute(c_str,"")
l_RqId=omed.sqlexecute( "select dbo.fn_GetID_tblRequest ('" + FIXQUOTE(MASTER.CL_CODE) + "','" +  STR(ntag) + "')", "ReqsId")
IF NOT lRequest
	=gfmessage("A tag was not added. Contact IT.")

	RETURN
ELSE
**update Tag count in master
	c_str= "Update tblMaster set subcnt='" +  STR(ntag) + "' Where cl_code = '" + FIXQUOTE(MASTER.CL_CODE) + "' and active =1"
	l_TagCntUpd=omed.sqlexecute(c_str , "")
	IF NOT l_TagCntUpd
		=gfmessage("Tag count was not updated. Contact IT dept.")
	ENDIF
ENDIF
pc_mailid=c_mailid
pl_StopPrtIss=.F.
STORE "" TO lcSQLLine,C_TYPE


C_TYPE=GETTRUECERT(listtodo.certtype)
D_date =  (listtodo.received-30)
*** - fill a true cert type in char_fld, scope beg date in date_fld and fld_name as "FLRBatch" to identify that data when printing
lcSQLLine="update tblRequest set tag_type='"+ALLTRIM("FL")+"', PrintOrigReq =" +  IIF(pl_StopPrtIss, STR(1),STR(0)) + ;
	" , REQ_DATE='" + DTOC(ld_Today) + "', SEND_DATE ='"+ DTOC(ld_Today)+ "'," ;
	+ " char_fld = '" + ALLTRIM(C_TYPE) + "', date_fld='" + DTOC(D_date) +"', fld_name='FLRBATCH'" ;
	+ " where "+;
	"id_tblrequests='"+ReqsId.EXP+"'"
omed.sqlexecute(lcSQLLine)
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
	+ ALLTRIM("FLRBATCH") + "','" ;
	+ ReqsId.EXP +"'"

l_done=omed.sqlexecute(c_str,"")
IF USED('EntryID')
	SELECT EntryID
	USE
ENDIF

l_EntryID= omed.sqlexecute("select dbo.fn_GetID_tblTimesheet ('" + pc_clcode + "','" ;
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
		c_blurb1= getflrblurb( listtodo.received, c_certType1)
		IF c_certType1="P" OR c_certType1="I" OR c_certType1= "W" OR c_certType1= "Y"
			c_certType1="R"
		ENDIF		
		
		c_certType2=GetCertType (ALLTRIM(listtodo.certtype), 2)
		c_blurb2= getflrblurb( listtodo.received, c_certType2)
		IF c_certType2="P" OR c_certType2="I" OR c_certType2= "W" OR c_certType2= "Y"
			c_certType2="R"
		ENDIF		
		c_blurb= c_blurb1+ CHR(13) + c_blurb2
		
		c_certType3=GetCertType (ALLTRIM(listtodo.certtype), 3)
		IF LEN(ALLTRIM(c_certType3))>0
			c_blurb3= getflrblurb( listtodo.received, c_certType3)
			IF c_certType3="P" OR c_certType3="I" OR c_certType3= "W" OR c_certType3= "Y"
				c_certType3="R"
			ENDIF		
			c_blurb= c_blurb1+ CHR(13) + c_blurb2+ CHR(13) + c_blurb3
		ENDIF 
	ELSE
		c_certType1=GetCertType (ALLTRIM(listtodo.certtype), 1)
		c_blurb1= getflrblurb( listtodo.received, c_certType1)
		IF c_certType1="P" OR c_certType1="I" OR c_certType1= "W" OR c_certType1= "Y"
			c_certType1="R"
		ENDIF
		
		c_blurb= c_blurb1
	ENDIF
	c_certType=c_certType1+IIF (NOT EMPTY(ALLTRIM(c_certType2)),c_certType2, '')+IIF (NOT EMPTY(ALLTRIM(c_certType3)),c_certType3, '')
	pc_CertTyp=c_certType
	l_cUser="FLRBATCH"
	*pc_UserID="FLRBATCH"
	DO AddSpecIns2 WITH EntryID.EXP, pc_clcode, ntag, ALLTRIM(lcDepName),"A", ALLTRIM(c_mailid), IIF (!EMPTY(cdept),cdept,"Z"),c_blurb
**-add notices
	lc_str="Exec dbo.sp_AddNotice '" ;
		+ pc_clcode + "','" ;
		+ STR(ntag) + "','" ;
		+ DTOC(d_today) + "','" ;
		+  DTOC(d_today +10) + "','" ;
		+ FIXQUOTE(lcDepName) + "','" ;
		+ c_blurb + "','" ;
		+ ALLT(pc_rqatcod) + "','" ;
		+ pc_Litcode + "','" ;
		+ "0000"  + "','" ;
		+ ALLTRIM(c_mailid) + "','" ;
		+ "A" + "'," ;
		+ STR(0) + " ," ;
		+ STR(0) + "," ;
		+ STR(0) + ", null, '','', '', '" ;
		+ "FLRBatch" + "'," + STR(0) ;
		+ ",''"
	l_Notice=omed.sqlexecute(lc_str,"")


ENDIF

_SCREEN.MOUSEPOINTER=0


*******************************************************************************************
FUNCTION getflrblurb
*******************************************************************************************
PARAMETERS  ddate , c_cert
PRIVATE cText3 AS STRING
&& specific blurbs
IF NOT USED('flrblurbs')
	USE 'T:\VFPFree\Global\flrblurbs.dbf' IN 0
ENDIF
SELECT flrblurbs
SET ORDER TO certtype   && CERTTYPE
IF SEEK(c_cert)
	cText1 =ALLTRIM(flrblurbs.part1)
	cText2 =ALLTRIM(flrblurbs.part2)
ENDIF
**D_date = gfChkDat( (ddate-30), .F., .F.)
cText3 = " " + DTOC(ddate -30) + " "
ctext=cText1 + cText3 + cText2
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
c_address=DepInfo.add1
c_address2=DepInfo.add2
c_city=DepInfo.city
c_st=DepInfo.state
c_zip=LEFT(ALLTRIM(DepInfo.zip),5)
c_Attn=DepInfo.attN

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
CREATE CURSOR tempRT (rt n(10))
INDEX ON rt TAG rt

SELECT listtodo 

DO PrintGroup WITH MV_2, "FLR2Page"

SCAN FOR ALLTRIM(UPPER(NEWMAILID))=ALLTRIM(UPPER(cmail))
select tempRT
SEEK listtodo.rt
IF FOUND()
   LOOP
ELSE 
   INSERT  INTO tempRT values(listtodo.rt)
ENDIF  
SELECT listtodo  

*!*	IF ALLTRIM(listtodo.CERTTYPE)<>c_depttodo
*!*		*SKIP
*!*		LOOP
*!*	ENDIF
	n_rt=rt	
	
	DO CASE 
CASE  LEFT(ALLTRIM(cmail) ,1)== "H" AND c_depttodo="B"
	lc_str="EXEC [dbo].[GetFLRBatchRequestHb]' " +STR(n_rt) + "','" + cmail + "'"
CASE  LEFT(ALLTRIM(cmail) ,1)== "H" AND c_depttodo="R"
	lc_str="EXEC [dbo].[GetFLRBatchRequesthr]' " +STR(n_rt) + "','" + cmail + "'"
otherwise

	lc_str="EXEC [dbo].[GetFLRBatchRequest]' " +STR(n_rt) + "','" + cmail + "'"

endcase
	
	
	omed.sqlexecute(lc_str,"FLRRequest")
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
c_DocName = PrintLOR('A')
DO PrintGroup WITH MV_3, c_DocName
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
			l_cWhat="Pulmonary"
		ELSE
			l_cWhat =l_cWhat + ","  + " Pulmonary"
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



*-- SET SAFETY ON 03/25/2021 MD
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

l_mail=omed.sqlexecute("exec dbo.GetDepInfoByMailIdDept  '" + ALLTRIM(lc_mailid)  +"','" + lcdept + "' ", "DepInfo")
SELECT DepInfo
IF EOF()
	l_mail=omed.sqlexecute("exec dbo.GetDepInfoByMailIdDept  '" + ALLTRIM(lc_mailid)  +"','" + "Z" + "' ", "DepInfo")
ENDIF




=CURSORSETPROP("KeyFieldList", "Code, id_tbldeponents", "DepInfo")
_SCREEN.MOUSEPOINTER=0
RETURN

*************************************************************************************************
PROCEDURE GetMaster
**************************************************************************************************
PARAMETERS ln_rttodo

omed.sqlexecute("exec dbo.GetMasterbyRTNumber '"+STR(ln_rttodo) + "'" ,"Master")
pl_GotCase =.F.
DO gfgetcas

RETURN


*------------------------------------------------
FUNCTION AddSpecIns2
**Called from the subp_pa.
			
PARAMETERS c_TSID, c_clcode,n_tag, c_descript, c_reqType, c_mid, c_dept, c_request
LOCAL l_specid as Boolean
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

oMed = CREATEOBJECT("generic.medgeneric")		
C_STR="Exec dbo.EditSpecIns  NULL " + ",'" + c_TSID	+ ;
					"', '" + fixquote(c_clcode) + "','" + STR(n_tag) + "','" + ;
					fixquote(c_request)+ "','"  + fixquote(c_descript) + "','" + ;
					DTOC(d_today) + "','" +  c_reqType + "'," + STR(0)+ ",'"  + ;
					c_mid + "','" + c_dept + "','" +	pc_CertTyp + "','" +STR(0) + "','" + ;
					DTOC(d_today)+ "','" + l_cUser + "'," +	STR(1) + "," + STR(0) + ",'" + "" + "'"

l_specid=omed.sqlexecute(C_STR,"EditSp")

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
	RENAME &lcFile to &lcRenameFile
ENDIF 
RETURN lcretVal


*------------------------------------------------------------------------------------------------------
PROCEDURE loadXLS
PARAMETERS c_file,  lcTemplate
USE &lcTemplate IN 0 ALIAS template

oleApp = CREATEOBJECT("Excel.Application")    && Launch Excel.
oleApp.VISIBLE=.f.                            && Display Excel.
oleApp.Workbooks.OPEN(c_file)        && Open the template

FOR lnrowCnt=1 TO oleApp.Rows.Count

   SELECT  template
   APPEND BLANK 
   FOR lnFldCnt=1 TO oleApp.cells.count   
       lcField=ALLTRIM(FIELD(lnFldCnt))
       
       	IF EMPTY(NVL(lcField,""))
       		exit       	
      	ENDIF && no more columns
      	
       lcValue=  oleApp.Cells(lnrowCnt,lnFldCnt).value         
       IF !EMPTY(ALLTRIM(lcField)) AND ISNULL(lcValue)<>.T.        		
          replace &lcField WITH convertField(&lcField, lcValue)     
        
       ENDIF 
         
         
   NEXT 

 	 IF EMPTY(NVL(oleApp.Cells(lnrowCnt+1,1).value,"")) AND  EMPTY(NVL(lcValue,"")) 	 
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

*-----------------------------------------------------
FUNCTION isTagCanceled
LPARAMETERS lnRT, lnTag
LOCAL lcSQLLine, llRetVal
llRetVal=.F.
lcSQLLine="select count(*) as cnts from tblorder where cl_code=dbo.getclcodebylrs("+ALLTRIM(STR(lnRT))+") and tag="+;
ALLTRIM(STR(lnTag))+" and date_order is not null and date_cancl is null and date_decln is null and active=1"
oMed.sqlExecute(lcSQLLine, "viewCanTag")
SELECT viewCanTag
IF viewCanTag.cnts=0
   llRetVal=.T.
ENDIF 
USE IN viewCanTag
RETURN llRetVal
*--------------------------------------------------------------------------
