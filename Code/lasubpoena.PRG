*PROCEDURE lasubpoena
***  LA  batch issues
********************************************************************************
** EF 12/05/07
*********************************************************************************

***************************************************************************

PUBLIC gcCl_code AS STRING ,gnTag AS INTEGER, ;
pcScanSg AS STRING, pcamgr_nm AS STRING, pcamgr_ml AS STRING , mv_1 AS strung,  mv_2   AS strring,  ;
mv_3 AS STRING, mv_4 AS STRING, mv_5 AS STRING, mv_6 AS STRING, mv_8 AS STRING, ;
pcamgr_ph AS STRING, pcInitials AS STRING, pcphone AS STRING, pc_Attn AS STRING, n_seqid as Integer
PRIVATE ld_Date AS DATE, 
pc_Attn="MEDICAL RECORD CUSTODIAN"
STORE "" TO 		mv_1,mv_2 ,mv_3,mv_4 ,mv_5, mv_7,mv_6, mv_8
 n_seqid=0
PUBLIC  oMed AS OBJECT
_SCREEN.MOUSEPOINTER= 11
IF TYPE("mv") = "U"
	PUBLIC mv
	mv = ""
ENDIF
WAIT WINDOW "Looking for tags to process...." NOWAIT NOCLEAR

SET ESCAPE ON
**pd_Date=DATE() &&+1
oMed = CREATEOBJECT("generic.medgeneric")
SET PROCEDURE TO ta_lib ADDITIVE

c_logical=.T.


DO WHILE  c_logical =.T.
	ON ESCAPE   c_logical =.F.	    
		C_STR="select dbo.ReturnMaxSeqId( )"
		l_done=oMed.sqlexecute(C_STR, "MaxCount")
		n_seqid=maxcount.exp
		
		

		SELECT MaxCount
		use
		c_sql="exec dbo.RPSTodoList "
		oMed.sqlexecute(c_sql,'Listtodo')	
	SELECT listtodo
	REPLACE ALL dtdocprocessed WITH ''
	GO TOP
	SCAN FOR  !EMPTY(Dttagprocessed ) AND EMPTY(dtdocprocessed)
		c_mailid=Listtodo.mailid_no
		n_count =Listtodo.occurEnces
		ld_Date=CTOD(Listtodo.dttagprocessed)
		n_seqid=n_seqid+1
	
		DO  SendToRps WITH c_mailid, .F., n_seqid, ld_Date, n_count
		
		DO  SendToRps WITH c_mailid, .T.,n_seqid, ld_Date, n_count
				
		
		SELECT listtodo
		REPLACE dtdocprocessed WITH DTOC(DATE())
		
		c_sql="Update tblrlaqueue  set dtdocprocessed ='" + DTOC( ld_Date) + "',  seqid='" + STR(n_seqid) + "'  where mailid_no ='" + c_mailid + "'"
		oMed.sqlexecute(c_sql)

		SELECT listtodo

	ENDSCAN
	SELECT  listtodo
	use

ENDDO

WAIT CLEAR 
_SCREEN.MOUSEPOINTER=0
gfmessage("Done.")
SET ESCAPE OFF
*****************************************************************************************************
PROCEDURE  SendToRps
PARAMETERS c_mailid,  lNoticeset, nId, ddate, ncount

LOCAL l_cancel AS Boolean, l_gotReq AS Boolean, cProvider as String
STORE .F. TO l_cancel, l_gotReq
STORE "" TO 		mv_1, mv_2 , mv_3,  mv_4 ,mv_5, mv_7, mv_6,  mv_8, cProvider

gcCl_code=IIF( lNoticeset,"LANOT_","LASUB_") + ALLTRIM(STR(nid))
gnTag=1

mclass=IIF (lNoticeset , 'LANotice','LASubp')

WAIT WINDOW "Working on..." + STR(nid)  NOWAIT NOCLEAR

c_sql="exec  [dbo].[GetLARequest]  '" + c_mailid + "','" + DTOC(ddate) + "'"
oMed.sqlexecute(c_sql,'Request')

pc_offcode="P"

C_STR="Exec dbo.GetLAServiceProvider '" + c_mailid + "'"

l_done=oMed.sqlexecute(C_STR, "DepInfo")
SELECT depinfo
cProvider=DepInfo.provider
pc_amgr_id='Alec'
DO getsign WITH pc_amgr_id

**Page1
IF NOT lNoticeset
	MV_1= larqcover (c_mailid, dDate)
**Page2
	MV_2=getinstruct()
ELSE
	MV_1= lanotcover (c_mailid, dDate)
ENDIF
**page3
MV_3=LASubpoena (c_mailid, dDate)
****SEPARATE INTO FEW QUEUES
mv=mv_1+mv_2 +mv_3
DO prtenqa WITH mv, mclass, "5", ""
****SEPARATE INTO FEW QUEUES

**page4 -exhibit

IF   ncount >=250
	*FOR icn =200  TO 1058  STEP 200
	FOR icn =200  TO 1058  STEP 200
		MV_4=""
		MV_4= maketable( c_mailid, dDate, icn)
		IF EMPTY(ALLTRIM(MV_4))
		EXIT FOR
		ENDIF
			DO prtenqa WITH MV_4, mclass, "5", ""
	ENDFOR
ELSE
    MV_4= maketable( c_mailid, dDate, icn)
ENDIF

**page5
IF  lNoticeset
	MV_5=getscanpage ()
ENDIF
**page6
MV_6= Laproof( dDate)
**page7
****SEPARATE INTO FEW QUEUES
mv=mv_4+mv_5 +mv_6

DO prtenqa WITH mv, mclass, "5", ""
****SEPARATE INTO FEW QUEUES


IF  NOT  lNoticeset
	SELECT REQUEST
	RECALL ALL
	GO TOP
	MV_8=''
	SCAN
		MV_7=LAcert (cProvider)
		
		IF ncount>190
			DO prtenqa WITH mv_7, mclass, "5", ""
		ELSE		
		  mv_8 = MV_8+MV_7
		ENDIF
		
		SELECT REQUEST
	ENDSCAN

ENDIF

**mv=mv_1+mv_2 +mv_3+mv_4 +mv_5+ mv_6+ mv_8
mv=mv_8
*mclass=IIF (lNoticeset , 'LANotice','LASubp')
*mclass='TestJob'
IF NOT EMPTY(mv)
DO prtenqa WITH mv, mclass, "5", ""
endif

_SCREEN.MOUSEPOINTER=0
RELEASE mv
WAIT CLEAR 
**gfmessage("The Requests have been sent to the RPS.")

RETURN
******************************************************************************************
*!*	PROCEDURE OpenLAcases
*!*	PARAMETERS c_mailid
*!*	LOCAL l_RetVal AS Boolean, l_done AS Boolean, C_STR AS STRING, c_Alias AS STRING
*!*	c_Alias=ALIAS()

*!*	STORE .F. TO l_RetVal, l_done

*!*	C_STR="Exec [dbo].[GetLaCases] '" + c_mailid + "'"

*!*	l_done=oMed.sqlexecute(C_STR, "Lacases")
*!*	IF l_done THEN
*!*		l_RetVal=.T.
*!*		=CURSORSETPROP("KeyFieldList", "Mailid_no", "Lacases")
*!*		INDEX ON cl_code TAG  Mailid_no UNIQUE ADDITIVE

*!*	ENDIF


*!*	SELECT (c_Alias)
*!*	RETURN l_RetVal

*****************************************************************
FUNCTION LARqCover
**************************************************************************

PARAMETER  c_mailid, d_date

MV1=''
c_name=DepInfo.provider
c_address=DepInfo.add1
c_city=DepInfo.city
c_st=DepInfo.state
c_zip=LEFT(ALLTRIM(DepInfo.zip),5)
*c_Attn=DepInfo.attN

DO PrintGroup WITH mv1, "LARqCover"
DO PrintField WITH mv1, "DeponentName", c_name
DO PrintField WITH mv1, "DeponentAddress", c_Address
DO PrintField WITH mv1, "DeponentCity", c_city
DO PrintField WITH mv1, "DeponentST", c_st
DO PrintField WITH mv1, "DeponentZip", c_zip
DO PrintField WITH mv1, "DeponentAttn", pc_attn
DO PrintField WITH mv1, "IssueDate", DTOC(d_date)


RETURN MV1




*****************************************************************
FUNCTION LASubpoena
**************************************************************************

PARAMETER  c_mailid, d_date

MV1=''
*pc_amgr_id='Lisa'
*DO getsign WITH pc_amgr_id

c_name=DepInfo.provider
c_address=DepInfo.add1
c_city=DepInfo.city
c_st=DepInfo.state
c_zip=LEFT(ALLTRIM(DepInfo.zip),5)


DO PrintGroup WITH mv1, "LASubpoena"


DO PrintField WITH mv1, "DeponentName", c_name
DO PrintField WITH mv1, "DeponentAddress", c_Address
DO PrintField WITH mv1, "DeponentCity", c_city
DO PrintField WITH mv1, "DeponentST", c_st
DO PrintField WITH mv1, "DeponentZip", c_zip
DO PrintField WITH mv1, "DeponentAttn", pc_attn
DO PrintField WITH mv1, "IssueDate", DTOC(d_date)
DO PrintField WITH mv1, "DueDate", DTOC(gfChkDat(d_date +30, .F.,.F.))
DO PrintGroup WITH mv1, "Contact"
DO PrintField WITH mv1, "Name", pcamgr_nm
DO PrintField WITH mv1, "Phone", pcamgr_ph
DO PrintField WITH mv1, "Id", pcScanSg



RETURN MV1
*********************************************************************
PROCEDURE maketable
PARAMETERS  c_mailid, d_date, nrec
PRIVATE c_servpr AS STRING
mv1=''
**1/2/08 - PRINT A PORTION OF TEH EXHIBIT
nrec=200
C_SELECT =" TOP " + STR(nrec)
**1/2/08 - PRINT A PORTION OF TEH EXHIBIT

SELECT REQUEST

DO PrintGroup WITH mv1, "LAExhibitA"


SELECT &C_SELECT   DISTINCT LRS_NO,  CASENAME, brth_date, CLAIM_NO FROM REQUEST WHERE NOT DELETED() INTO CURSOR  ;
REQUEST2 ORDER BY LRS_NO

SELECT REQUEST2


IF NOT EOF()

	SCAN  
		c_servpr=""
		DO PrintGroup WITH mv1, "Item"

***********PRINT SERVICE PROVIDER

*!*		select DISTINCT  serv_prov, lrs_no into cursor DEPINFO2
*!*		from DEPINFO
*!*		group by lrs_no,serv_prov
*!*		SELECT DEPINFO2


		SELECT DEPINFO
		
		C_LRS=REQUEST2.LRS_NO
		SCAN FOR LRS_NO =C_LRS
			c_servpr= c_servpr+ALLTRIM(DEPINFO.SERV_PROV) +CHR(13)
			SELECT DEPINFO
		ENDSCAN
		
		SELECT REQUEST2
*****************

		DO PrintField WITH mv1, "Col1", "  "
		DO PrintField WITH mv1, "Col2",ALLTRIM(CaseName)
		DO PrintField WITH mv1, "Col3", NVL(DTOC( brth_date),'')
		DO PrintField WITH mv1, "Col4",NVL( ALLTRIM(Claim_no),'') &&+CHR(13) + c_servpr
		DO PrintField WITH mv1, "Col5", c_servpr

		SELECT REQUEST2
	ENDSCAN
ELSE
mv1=''
ENDIF

**1/2/08 - PRINT A PORTION OF TEH EXHIBIT
DELETE NEXT 200 IN REQUEST
**
RETURN mv1

**************************************************************************
PROCEDURE getsign
PARAMETERS c_amgr_id
IF  NOT EMPTY( c_amgr_id)
	IF TYPE("oMedGen")!="O" OR ISNULL(oMedGen)=.T.
		oMedGen=CREATEOBJECT("generic.medgeneric")
	ENDIF
	oMedGen.sqlexecute("exec dbo.GetUserByLogin '" + fixquote(ALLTRIM( c_amgr_id)) + "'", "UserCtrl")
	SELECT UserCtrl
	pcamgr_nm = ALLT( UserCtrl.FULLNAME)
	pcamgr_ml = ALLT( UserCtrl.Email)
	pcamgr_ph = ALLT( UserCtrl.DirectDial)
	pcScanSg = ALLT( UserCtrl.SigFile)
	pcInitials =getInitials(c_amgr_id)
	pcphone = ALLT( UserCtrl.DirectDial)


ENDIF

RETURN
************************************************************************
FUNCTION getscanpage
mv1=''
DO PrintGroup WITH mv1, "LAPrOrd"

RETURN mv1


**************************************************************************
FUNCTION LAproof
PARAMETER  d_date

MV1=''


DO PrintGroup WITH mv1, "LAProof"
DO PrintField WITH mv1, "IssueDate", DTOC(d_date)
DO PrintGroup WITH mv1, "Contact"
DO PrintField WITH mv1, "Name", pcamgr_nm
DO PrintField WITH mv1, "Phone", pcamgr_ph
DO PrintField WITH mv1, "Id", pcScanSg


RETURN MV1
***************************************************************************
PROCEDURE Lacert
PARAMETERS  c_name


mv1=""
pc_litcode='RLA'
DO PrintGroup WITH mv1, "LACert"
DO PrintField WITH mv1, "DeponentName",  ALLTRIM(c_name)

DO PrintField WITH mv1, "Tag",  STR(REQUEST.TAG)
DO PrintField WITH mv1, "RecipientName",  REQUEST.casename
DO PrintField WITH mv1, "RecipientRT",  STR(REQUEST.Lrs_no)
DO PrintField WITH mv1, "RecipientDOB",  NVL(DTOC( REQUEST.brth_date),'')
DO PrintField WITH mv1, "RecipientSSN",   NVL(ALLTRIM(REQUEST.Claim_no),"")

c_Specmark=ALLTRIM(UPPER(NVL(pc_litcode,"")))+"."+ALLTRIM(UPPER(NVL(pcInitials,"")))

DO PrintField WITH mv1, "SpecMark", c_Specmark

DO PrintGroup WITH mv1, "Control"
DO PrintField WITH mv1, "Date",''
DO PrintField WITH mv1, "LrsNo", STR(REQUEST.lrs_no)
DO PrintField WITH mv1, "Tag", STR(REQUEST.TAG)






RETURN mv1
***********************************************************************************
FUNCTION  getinstruct
mv1=""
DO PrintGroup WITH mv1, "LAInst"

RETURN mv1


**************************************************************************
FUNCTION LANotCover
PARAMETER  c_mailid, D_DATE

MV1=''
c_name=DepInfo.provider


DO PrintGroup WITH mv1, "LANotCov"
DO PrintField WITH mv1, "DeponentName", c_name
DO PrintField WITH mv1, "IssueDate", DTOC(d_date)
DO PrintGroup WITH mv1, "Contact"
DO PrintField WITH mv1, "Name", pcamgr_nm
DO PrintField WITH mv1, "Phone", pcphone


RETURN MV1



