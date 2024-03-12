PROCEDURE RepTXSub
**EF 5/11/06- added to the project
**************************************************************
* 06/15/04 DMA Extracted from TxReprin as stand-alone module
** Called from GenUtils
** gfGetCas has already been called, and pl_OfcHous is always .T.
** Calls pDepInfo in Subp_PA
PRIVATE mnameinv, mratadd1, mratadd2, mratcsz, szPlAtty, llCourt, mdate1, ;
   szAttyType, mratadd1P, mratadd2P, mratcszP, mphone, mCrtDesc, ldtxn11
SET PROCEDURE TO ta_lib additive
dbHold = SELECT()
TxNotFed = .T.
MV=""
IF TYPE('MV')="U"
PUBLIC MV
ENDIF
**Federal subpoenas need originals
*IF pl_OfcHous
*SELECT 0
*USE (f_txcourt)
DO IfNoTxCourt IN pwrquest
                 
SELECT txcourt
SET ORDER TO Crt_ID
IF NOT EMPTY( pc_Court2)
   TxNotFed = ( SEEK( ALLT( pc_Court2)))
ENDIF
*ENDIF
USE
SELECT (dbHold)
dep_date = d_today
mdate = d_today
*lcEnt=gfentryn(alltrim(tamaster.cl_code))
*lcEnt = pc_entryn
*IF pl_OfcHous
SELECT timesheet
*SET ORDER TO cl_txn
*IF SEEK( pc_clcode + "*" + STR(11) + "*" + STR(ntag))
ldtxn11 = timesheet.txn_date
*ENDIF
*SELECT (lcEnt)
*SET ORDER TO cl_code

ldBusonly = gfDtSkip( ldtxn11, 9)
IF timesheet.type = "S"
   mdate = ldBusOnly
   dep_date = mdate + 20
ELSE
   mdate = d_today
   dep_date = ldBusonly
ENDIF
*endif
mdefendant = ALLT( pc_dfcaptn)
szPltName = pc_plnam
*szPltName = IIF( pl_OfcHous, pc_plnam, pc_plcaptn )
IF TYPE('pd_term')="C"
mTerm =pd_term
endif

mRDocket = pc_docket
STORE "" TO szAtName, mnameinv, mratadd1, mratadd2, mratcsz, mphone, mCrtDesc
	IF NOT EMPTY( pc_rqatcod)
		c_RqAtty=fixquote(pc_rqatcod)
		pl_GetAt = .F.
		DO gfatinfo WITH c_RqAtty, "M"
		szAtName = pc_AtyName
		mnameinv = pc_AtySign
		mratadd1 = pc_Aty1Ad
		mratadd2 = pc_Aty2Ad
		mratcsz = pc_Atycsz
		mphone = pc_AtyPhn
	ENDIF

	STORE "" TO szPlAtty, mnameinvP, mratadd1P, mratadd2P, mratcszP, mphoneP, mCrtDesc
	IF NOT EMPTY( pc_platcod)
		c_plAtty =fixquote(pc_platcod)
		pl_GetAt = .F.
		DO gfatinfo WITH c_plAtty, "M"
		szPlAtty =pc_AtyName
		mnameinvP = pc_AtySign
		mratadd1P = pc_Aty1Ad
		mratadd2P = pc_Aty2Ad
		mratcszP = pc_Atycsz
		mphoneP = pc_AtyPhn

	ENDIF


SELECT Master

DO PrintGroup WITH mv, IIF( TxNotFed, "TXSubpoena", "SubpoenaOther")
*   IIF( pl_OfcHous AND TxNotFed, "TXSubpoena", "SubpoenaOther")
DO PrintField WITH mv, "RT", pc_lrsno + "." + ALLT(STR(ntag))
llProvider = .F.

DO PrintField WITH mv, "RequestDate", DTOC( mdate)
&& Add suffix to convert date to an ordinal number (first, second, etc.)
IF TxNotFed
   *IF pl_OfcHous AND TxNotFed
   mdate= CTOD(LEFT(DTOC(mdate),10))
   DO PrintField WITH mv, "StrAdd", gfOrdNum(mdate)
ENDIF
DO PrintField WITH mv, "Loc", pc_offcode
*   IIF(pl_OfcMD OR pl_OfcPgh, "P", pc_offcode)

IF TYPE( "ldDueDate") = "D"
   IF NOT EMPTY( ldDueDate)
      dep_date = ldDueDate
   ENDIF
ENDIF

DO PrintField WITH mv, "DepDate", DTOC( dep_date)

*IF USED( "SPEC_INS")
  * SELECT Spec_Ins
*ELSE
  * USE( f_spec_ins) in 0
  * SELECT Spec_Ins
*ENDIF
*SET ORDER TO cltag
*IF SEEK ( pc_clcode + "*" + ALLT( STR( ntag)))
   *SCAN WHILE cl_code = pc_clcode AND tag = ntag
     * szrequest = ""
     * szEdtReq = ""
     * sztxndate = Spec_Ins.Txn_date
      *szrequest = Spec_Ins.Spec_Inst
     * SET MEMOWIDTH TO 68
     * szEdtReq = gfAddCR( Spec_Ins.Spec_Inst)
     * creqtype = UPPER( ALLT( Spec_Ins.type))
     * LOOP
  * ENDSCAN
*endif
oMed =CREATEOBJECT('medgeneric')
	WAIT WINDOW "Getting Special Instruction" NOWAIT NOCLEAR 
	**10/01/18 SL #109598
	*+ " tag, TYPE, spec_inst, dept, mailid_no from tblspec_ins   WITH (INDEX (IX_TBLSPEC_INS_1)) " 
	l_SpecIns=oMed.sqlexecute("select id_tblSpec_ins, id_tblTimesheet, Txn_date, cl_code, " ;
		+ " tag, TYPE, spec_inst, dept, mailid_no from tblspec_ins " ;
		+ " WHERE cl_code = '" + fixquote(pc_clcode) + "' and tag ='" ;
		+ STR(timesheet.TAG) + "' ORDER BY txn_date", "Spec_ins")

	SELECT spec_ins
	LOCATE FOR id_tbltimesheet =timesheet.id_tbltimesheet
	IF  FOUND()

		szrequest = ""
		szEdtReq = ""
		sztxndate = spec_ins.txn_date
		szrequest = spec_ins.Spec_Inst
		SET MEMOWIDTH TO 68

		szEdtReq = gfAddCR( spec_ins.Spec_Inst)
		creqtype = UPPER( ALLT( spec_ins.TYPE))
	ENDIF

	


DO PrintField WITH mv, "InfoText", szEdtReq

DO PrintGroup WITH mv, "Case"
DO PrintField WITH mv, "Plaintiff", szPltName
DO PrintField WITH mv, "Defendant", mdefendant
DO PrintField WITH mv, "AttyType", IIF( pl_plisrq, "P", "D")
DO PrintField WITH mv, "AttyName", szAtName
DO PrintField WITH mv, "Docket", mRDocket

IF ALLTRIM( UPPER( pc_Court1)) = 'FEDERAL'
   *IF pl_OfcHous AND ALLTRIM( UPPER( pc_Court1)) = 'FEDERAL'
   *IF used('TXcourt')
      *select TXcourt
   *else
     * use(f_txcourt) in 0
     * select TXCourt
  * endif
  DO IfNoTxCourt IN pwrquest
  DO gfTXCour                                   

  SELECT txcourt
   set order to Crt_id
   seek alltrim(pc_Court2)

   DO PrintField WITH mv, "Court", Alltrim(mcourt) + ;
      " (United States District Court " + ;
      proper( alltrim( TxCourt.District)) + " District " + ;
      Proper(ALLTRIM( TXCourt.Division)) + " Division)"
   select Tamaster
ELSE
   mcourt = pc_Court1
   mcourt2 = pc_Court2
   DO PrintField WITH mv, "Court", mcourt
ENDIF

DO PrintField WITH mv, "Court2", IIF( creqtype = "S", pc_Court2, mcourt2)
DO PrintField WITH mv, "County", IIF( creqtype = "S", pc_plcnty, mcounty)
DO PrintField WITH mv, "Term", mTerm


DO PrintField WITH mv, "Dist", IIF( pc_Court1 = "CCL", ;
   "County Civil Court at Law No." + ALLT( pc_cclnum), ;
   ALLT( pc_distrct) + " District Court")


mCrtDesc = ALLT( pc_area)

DO PrintField WITH mv, "Area", mCrtDesc
IF TYPE('pd_pldob')<>"C"
pd_pldob= DTOC( pd_pldob)
endif
DO PrintField WITH mv, "BirthDate",  pd_pldob
DO PrintField WITH mv, "SSN", pc_plssn
IF TXNotFed
   *IF pl_OfcHous AND TXNotFed
   DO PrintField WITH mv, "Extra", TRIM( pc_maiden1)
ENDIF
IF NOT USED("pc_depofile")
		WAIT WINDOW "Getting Deponent's information" NOWAIT NOCLEAR 

		l_mail=oMed.sqlexecute("exec dbo.GetDepInfoByMailIdDept '" ;
			+ timesheet.MailID_No +"','" ;
			+ ALLTRIM(spec_ins.dept) + "' ", "pc_DepoFile")
		=CURSORSETPROP("KeyFieldList", "Code, id_tbldeponents", "pc_DepoFile")

	ENDIF

* 06/16/03 DMA Add no-phone flag parameter to routine call
DO pDepInfo IN Subp_PA ;
   WITH timesheet.mailid_no, PROPER(timesheet.descript), .F.

IF TXNotFed
   DO PrintGroup WITH mv, "Atty"
   DO PrintField WITH mv, "Name_inv", mnameinv
   DO PrintField WITH mv, "Ata1", mratadd1
   DO PrintField WITH mv, "Ata2", mratadd2
   DO PrintField WITH mv, "Atacsz", mratcsz
   DO PrintField WITH mv, "Phone", ;
      SUBSTR(mphone,1,3) + "-" + SUBSTR(mphone,4,3) + ;
      "-" + SUBSTR(mphone,7,4)
ENDIF

** ---  01/29/2021 MD #222170 
IF TXNotFed
	LOCAL inDefendantName
	STORE "" TO inDefendantName	
	oMED.closealias("viewDefName")
	SELECT 0
	oMED.sqlexecute("exec dbo.AttyDefInfo '" + fixquote(pc_clcode)+ "', "+ALLTRIM(STR(timesheet.tag))+", '"+Iif( pl_plisrq, "P", "D")+"'", "viewDefName")
	IF USED("viewDefName")			
	   	GO TOP 		   
	   	inDefendantName=ALLTRIM(DefendantName) 		   
	Endif	
	oMED.closealias("viewDefName")
	Do PrintField With mv, "DefendantName", inDefendantName	
ENDIF 
** ---  01/29/2021 MD #222170 

mclass = "TXReprint"
DO prtenqa WITH mv, mclass, "1", ""
WAIT CLEAR 
RETURN
