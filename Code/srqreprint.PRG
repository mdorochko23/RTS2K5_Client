PUBLIC gcCl_code AS STRING ,gnTag AS INTEGER

PUBLIC  oMed AS OBJECT

_SCREEN.MOUSEPOINTER= 11
IF TYPE("mv") = "U"
	PUBLIC mv
	mv = ""
ENDIF
c_nodate=DTOC({})
*WAIT WINDOW "Looking for tags to process...." NOWAIT NOCLEAR
SET ESCAPE ON
oMed = CREATEOBJECT("generic.medgeneric")
SET PROCEDURE TO ta_lib ADDITIVE
c_sql="SELECT top 800 * from tblSRQLetter WHERE PRINTED =0"
oMed.sqlexecute(c_sql,'FileSource')
SCAN
c_sql="SELECT TOP 1 LRS_NOCODE,Plaintiff,Name_First,Name_Last,Name_Init, Add1, Add2, Soc_sec, Brth_date, Dth_dAte from tblMASTER WHERE LRS_NO='" + ALLTRIM(STR(FileSource.LRS_NO)) + "' AND ACTIVE=1"
oMed.sqlexecute(c_sql,'Master')
gcCl_code=FileSource.CL_CODE
gnTag=FileSource.tag
pc_offcode='P'
pc_fullnam = ALLT( MASTER.Plaintiff)
STORE "" TO pc_plfname, pc_pllname, pc_plminit, pc_plgiven
IF EMPTY( pc_fullnam)
	pc_plfname = ALLTRIM( MASTER.Name_First)
	pc_pllname = ALLTRIM( MASTER.Name_Last)
	pc_plminit = MASTER.Name_Init
	IF NOT EMPTY ( pc_plfname + pc_pllname + pc_plminit)
		pc_plgiven = ALLT( IIF( EMPTY( pc_plfname), "", pc_plfname) + ;
		IIF( EMPTY( pc_plminit), "", " " + pc_plminit + ;
		IIF( ISALPHA( pc_plminit), ".", "")) )
		pc_fullnam = pc_pllname + " ;" + pc_plgiven
		
	ENDIF
ELSE
	DO gfBrkNam WITH pc_fullnam, ;
	pc_pllname, pc_plfname, pc_plminit, pc_plgiven
ENDIF
pc_plnam = IIF( NOT EMPTY( pc_plgiven), pc_plgiven + " ", "") + pc_pllname

pc_pladdr1 = ALLT( MASTER.Add1)
pc_pladdr2 = ALLT( MASTER.Add2)
pc_plssn   = TRANSFORM( MASTER.Soc_Sec, pc_ssnpic)
pd_pldob   = NVL(MASTER.Brth_date,c_nodate)
pd_pldod   = NVL(MASTER.Dth_date,c_nodate)
PC_CLCODE=FileSource.cl_code
PN_TAG=FileSource.TAG

	DO srqprint WITH FileSource.lrs_no, FileSource.TAG, FileSource.cl_code
	
	
	c_sql="UPDATE tblSRQLetter SET PRINTED =1, PRINTDATE='" + DTOC(DATEtime()) + "' WHERE cl_code ='" + fixquote(FileSource.cl_code) +"' and tag ='" +STR(FileSource.TAG) + "'"
	oMed.sqlexecute(c_sql)



	SELECT FileSource
ENDSCAN
RELEASE OMED

WAIT WINDOW "Done process...." 
_SCREEN.MOUSEPOINTER= 0
RETURN
*********************************************************************************
PROCEDURE SRQPrint

PARAMETERS  n_lrsno, nTag, c_clcode

LOCAL l_cancel AS Boolean, l_gotReq AS Boolean, c_id AS STRING
STORE .F. TO l_cancel, l_gotReq
c_id=""

LOCAL ots AS medtimesheet OF timesheet
ots = CREATEOBJECT("medtimesheet")


gcCl_code=c_clcode
gnTag=nTag


mclass="SRQLetter"

c_sql=" select TOP 1 id_tblTimesheet, TXN_DATE from tbltimesheet  where cl_code ='" + ;
fixquote(c_clcode) +"' and tag ='" +ALLTRIM(STR(nTag)) + "' and txn_code =11 and deleted is null"

ots.sqlexecute(c_sql,"txn11")

c_id =txn11.id_tblTimesheet
IF !EMPTY(alLtrim(c_id))
D_DATE=CTOD(LEFT(DTOC(TXN11.TXN_DATE),10))
IF D_DATE <{02/26/2008}
	c_sql="SELECT TOP 1 descript, tag, dept, mailid_no from tblspec_ins  where id_tblTIMEsheet='" + ;
	c_id + "' and active =1"
	*DO  c:\test\SQLSTRING.prg WITH c_sql
	ots.sqlexecute(c_sql,"SpecReq")
	WAIT WINDOW "Printing SRQ letter..." NOWAIT NOCLEAR
	
	WAIT WINDOW "Checking deponent's data. Please wait."  NOWAIT NOCLEAR
	pl_Mail = .F.
	pc_MailID=alltrim(SpecReq.mailid_no)
	
	IF NOT EMPTY( pc_MailID)
   		pc_deptype = upper( left( pc_MailID, 1))
   IF NOT INLIST( pc_deptype, "H", "E", "A", "D")
        pc_deptype = "D"
   ENDIF
   ENDIF
	DO gfDepInf WITH SpecReq.dept
	_SCREEN.MOUSEPOINTER=0
	DO srqletter WITH SpecReq.desCript, ALLTRIM(SpecReq.dept), .T.
ENDIF
	**no txn 11
endif
RELEASE OTS
RETURN
