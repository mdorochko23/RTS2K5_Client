*PROCEDURE txcert
******************************************************************************
*EF 11/28/2017:  Judicial vs. County court  #70136
*EF 11/10/2017: Added a tag level  'p' files 
*EF 08/16/2017: Added Reissue
*EF 08/09/2017: Added pc_Suffix
*EF 06/15/2017: Texas Certificate of Service page
******************************************************************************
PARAMETERS n_Tag, c_mdep, c_mid

PRIVATE c_nameinv, c_nameinvp, c_ratadd1, c_ratadd1p,  c_clcode,  c_cty, ;
	c_ratadd2, c_ratadd2p, c_ratcszP, c_ratcsz, c_date1, c_roloname, c_sign, contname, contphone
LOCAL lcTXAmended

*----------------
*-- 09/02/2022  MD #277503 Do not print TX Certs with new Subpoena/Notice pages
RETURN
*-- 09/02/2022 
*----------------
** 10/19/2017  : #71549 Old TX Reissue and Follow-ups  of Old tags do not use any programmed pages- Use scanned only
	If  SkipTxDocs (PN_LRSNO,N_TAG )
	 Return
	Endif
** 10/19/2017  : #71549 Old TX Reissue and Follow-ups  of Old tags do not use any programmed pages- Use scanned only

*!*	**11/10/2017 - Print tag level scanned certs "P"  for tags issued after 9/22/17
If  TxSFile (n_Tag,"P")
   DO TXPages WITH "P",n_Tag ,  c_mid
   RETURN
ENDIF 

*** print progrqammed page below	
dbInit = ALIAS()
ots = CREATEOBJECT("medtimesheet")
_SCREEN.MOUSEPOINTER=11
SET PROCEDURE TO ta_lib ADDITIVE
c_clcode= fixquote(pc_clcode)

contphone=UserCtrl.DirectDial
IF  USED('Request2')
	SELECT REQUEST2
	USE
ENDIF
ots.sqlexecute(" exec dbo.GetRequestRecordbyClcodeTag '" + c_clcode + "','" + STR(n_Tag) + "' ", "Request2")

SELECT REQUEST2
*06/13/2018 MD #71930 ------------------------------------------
IF USED('viewTXAM')
   USE IN viewTXAM
ENDIF 
lcSQLLine=" exec [dbo].[qc_CheckTXAM]   '" +fixquote(c_clcode) + "'," + convertToChar(n_Tag,1)
ots.sqlexecute(lcSQLLine,'viewTXAM')
lcTXAmended=""
* 07/16/2018 MD replaced to use viewTXAM instead of tblrequest data ------------------------------------------
IF ALLTRIM(UPPER(NVL(viewTXAM.addInfo,"")))=="TXAM" AND ALLTRIM(UPPER(NVL(request2.type,"A")))=="S" AND LEFT(ALLTRIM(UPPER(NVL(pc_Court1,""))),2)="TX"         
   lcTXAmended="amended"
ENDIF 
IF USED('viewTXAM')
   USE IN viewTXAM
ENDIF 
* ------------------------------------------------------------------      
  
**10/31/2017: #70884 Skip Holidays for TX issues : GFCHKDAT 
c_date1=GFCHKDAT (CTOD(LEFT(DTOC(Request2.REQ_Date),10)),.f.,.f.)
c_cty=fixquote(NVL(pc_c1Cnty,''))
*------------------------------------------------------------
*DO PrintGroup WITH mv, "TXCrtSrv" && txcert.doc 
*#255675 01/05/2021 WY 
DO PrintGroup WITH mv, "2_TXCrtSrv" && 2_txcert.doc 
*#255675 WY 12/21/2021 Support TX Header user selection
PRIVATE pcTxHeaderMode
pcTxHeaderMode = GetTxHeaderStyle(PN_LRSNO, N_TAG)


*------------------------------------------------------------
DO PrintField WITH mv, "Loc", "K"
DO PrintField WITH mv, "RequestDate", DTOC(c_date1)
DO PrintField WITH mv, "AttyType", IIF( pl_plisrq, "P", "D")
*11/28/2017:  Judicial vs. County court  #70136
*DO PrintField WITH mv, "County", UPPER(c_cty)
*DO PrintField WITH mv, "Suffix", pc_Suffix
*DO PrintField WITH mv, "CrtType", ALLTRIM(pc_txCrtType)
	mv_cap2=""
	mv_cap2= txcourtcap()

	IF EMPTY(mv_cap2)
		Wait Window 'Error in a court caption.'
		Return
	ENDIF
	mv=mv+mv_cap2

STORE "" TO c_nameinv, c_nameinvp, c_ratadd1p, c_ratadd2p, c_ratcszP, ;
	c_AttyInfo, c_ratadd1, c_ratadd2, c_ratcsz, c_Pltcap, c_AtName, c_EmailAdd, c_AtyFax

IF NOT EMPTY( pc_rqatcod)
	pl_GetAt = .F.
	DO AtyMixed WITH fixquote(pc_rqatcod), "M", .T.
ENDIF

** 2 lines for deponent's address
DO DepTxCert  WITH c_mid, PROPER( c_mdep), .F.

DO PrintGroup WITH mv, "Case"
*DO PrintField WITH mv, "Plaintiff", pc_plcaptn
*255675 WY 01/04/2022
DO PrintField WITH mv, "Plaintiff", PrintFieldIntercept("Plaintiff", pc_plcaptn)
*DO PrintField WITH mv, "Defendant", pc_dfcaptn
*255675 WY 01/04/2022
DO PrintField WITH mv, "Defendant", PrintFieldIntercept("Defendant", pc_dfcaptn)

DO PrintField WITH mv, "Docket", pc_docket
DO PrintField WITH mv, "AttyType", IIF( pl_plisrq, "P", "D")
IF TYPE('pd_pldob')<>"C"
	pd_pldob=DTOC(pd_pldob)
ENDIF

DO PrintField WITH mv, "AttyName", ALLTRIM(c_nameinv)
DO PrintField WITH mv, "BirthDate", pd_pldob
DO PrintField WITH mv, "SSN", pc_plssn
DO PrintField WITH mv, "Term", pd_term
DO PrintField WITH mv, "Dist",  "" &&UPPER(ALLT( pc_distrct))
DO PrintField WITH mv, "Area", "" &&UPPER(c_cty)
** hardcoded to Liz's name 
pc_amgr_nm="Christine Hoffman"   && 01/05/2022 'Liz Donegan'
DO PrintGroup WITH mv, "Contact"
DO PrintField WITH mv, "Name", IIF( NOT EMPTY(pc_amgr_nm), pc_amgr_nm, "RecordTrak Representative")
DO PrintField WITH mv, "Phone", contphone
*06/13/2018 MD #71930
Do PrintField With mv, "Amended",lcTXAmended

*255675 WY 12/21/2021 Support TX Header user selection
CreateTxHeader()

_SCREEN.MOUSEPOINTER=0
SELECT ( dbInit)
RELEASE ots
WAIT CLEAR

RETURN
*************************************************************************
**********************************************************************
PROCEDURE DEPTxCert
**********************************************************************
* Print Deponent Information: use two lines for an address
PARAMETERS MID, MDEP, L_PHONE
PRIVATE C_ROLONAME, L_ROLOUSED, C_OLDFILE, OMEDGEN, L_GOT11LINE
IF PARAMETERS() = 2
	L_PHONE = .F.
ENDIF

C_OLDFILE = SELECT()
WAIT WINDOW "Print Deponent Information" NOWAIT
IF EMPTY(ALLTRIM(MID)) AND !EMPTY(ALLTRIM(PC_MAILID))
	MID=ALLTRIM(PC_MAILID)
ENDIF
OMEDGEN = CREATEOBJECT("generic.medgeneric")
L_GOT11LINE=.F.
OMEDGEN.SQLEXECUTE(" select [dbo].[GetTxn11Description] ('" + FIXQUOTE(PC_CLCODE)+ "','" +STR(PN_TAG ) +"')","Desc11")
IF NOT EMPTY(NVL(DESC11.EXP,''))
	L_GOT11LINE=.T.
ENDIF
IF TYPE('pc_deptype')<>"C"
	IF NOT ISDIGIT( LEFT( ALLT( MID), 1))
		PC_DEPTYPE = LEFT( ALLT( MID), 1)
	ELSE
		PC_DEPTYPE = "D"
	ENDIF
ENDIF

IF (L_GOT11LINE AND PC_DEPTYPE = "H" ) OR PL_CAVER
	C_DEPTYPE=DEPTBYDESC(DESC11.EXP)
ELSE
	C_DEPTYPE="Z"
ENDIF

WAIT WINDOW "Getting Deponent's information" NOWAIT NOCLEAR
_SCREEN.MOUSEPOINTER=11
**08/25/2017: Mixed Cases on the TX docs

L_MAIL=DepoData (MID, C_DEPTYPE,  PL_TXCOURT)

=CURSORSETPROP("KeyFieldList", "Code, id_tbldeponents", "pc_DepoFile")
_SCREEN.MOUSEPOINTER=0


SELECT PC_DEPOFILE
IF EOF()
	WAIT WINDOW " No deponent data is available. Note the case and tag number (" + ALLTRIM(PC_LRSNO) + "." + ALLTRIM(STR(PN_TAG) ) + ") and contact IT Dept. Thank you."
ENDIF
RELEASE OMEDGEN

DO PRINTGROUP WITH MV, "Deponent"

C_ADDITION= GETDESCRIPT(C_DEPTYPE)

C_DEP=DEPTOPRINT (ALLTRIM(NVL(PC_DEPOFILE.NAME,MDEP)))

DO PRINTFIELD WITH MV, "Name",  IIF(PL_TXCOURT, UPPER(C_DEP ), c_dep)+ IIF(PC_DEPTYPE = "H"  ,"",C_ADDITION) &&lc_dname
**05/21/2012- print deponent's name  insted of txn 11 line ( per Alec)

** 09/07/2017 - print without empty lines as one block
LOCAL c_block as String
 c_block =""
 c_block = Addr1Block ()

DO PRINTFIELD WITH MV, "Addr1",  c_block 
DO PRINTFIELD WITH MV, "Addr2", ""
DO PRINTFIELD WITH MV, "City",	""
DO PRINTFIELD WITH MV, "State", ""
DO PRINTFIELD WITH MV, "Zip", ""


IF L_PHONE
	DO PRINTFIELD WITH MV, "Extra", TRANSFORM( PHONE, PC_FMTPHON)
ENDIF

SELECT ( C_OLDFILE)
RETURN
********************************************************************************

** 09/07/2017 - print without empty lines as one block
Function Addr1Block

 _Screen.MousePointer=11
LOCAL    c_Address as String
STORE "" to   c_Address


   c_Address = ALLTRIM(PC_DEPOFILE.ADD1)+ CHR(13)
   
   c_Address = c_Address + IIF( NOT EMPTY( ALLTRIM(PC_DEPOFILE.ADD2)), ;
     ALLTRIM(PC_DEPOFILE.ADD2)+ CHR(13), "")
   c_Address = c_Address + IIF( NOT EMPTY( ALLTRIM(PC_DEPOFILE.CITY)), ;
    ALLTRIM(PC_DEPOFILE.CITY)+ ", " , "") + ALLTRIM(PC_DEPOFILE.STATE) + " " + IIF(ALLTRIM(PC_DEPOFILE.ZIP)='00000','', ALLTRIM(PC_DEPOFILE.ZIP))
 

 _Screen.MousePointer=0




RETURN  c_Address

*255675 WY 12/21/2021 Support TX Header user selection
PROCEDURE CreateTxHeader() 
	Do PrintField With mv, "UnderCasePlaintiff", PrintFieldIntercept("UnderCasePlaintiff")   		
	IF pcTxHeaderMode = 3
		Do PrintField With mv, "Ver", PrintFieldIntercept("Ver", pc_plcaptn)   		
	ELSE
		Do PrintField With mv, "Ver", PrintFieldIntercept("Ver")   		
	ENDIF 
	Do PrintField With mv, "UnderCaseDef", PrintFieldIntercept("UnderCaseDef")   	
ENDPROC 