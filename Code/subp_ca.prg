******************************************************************************
*03/22/2012 - Use new USDC form (share with KOP office) as march 2012
*05/25/2011 - new or old BB set (a new signature for the BEBE 3C)
*08/24/2010 - Oakland's office move
*04/21/2010 - Get a correct dept' info on the Notice to Consumer page
*10/28/2009 - Edited to work with Reprints from PDF.
*08/10/2009 - added getcaSigner/GetCADeliv
*08/03/2009 - split CA POS into two pages
*07/15/2009 - Added pl_NonGBB
*06/29/2009-07/14/2009 -MERGE JOBS QUEUE FOR THE PDF FILES
*04/23/2008 -Switch Pasadena office work to Oakland
*5/21/2007  -added two new boxes to the proof page
*02/28/1006 -added to the VFP project
******************************************************************************
* Subp_ca.prg - Contains California office subpoena procedures.
*   Each procedure generates one or more copies of a specific document.
*   Procedures are called from Subp_PA [S], CANotice [N], CACivilN [V], and
*      HIPAASet [H] and also internally from routines in this package [C]
*   Procedures are dependent on variables introduced in SUBP_PA.
*   Procedures assume that gfGetCas has been called.
*
*   Contains the following routines:
*      CADepSub  -- CA Deposition Subpoena [S, N, V]
*      CAPosNot  -- CA Proof of Service of Notice [S, N, V]
*      CADecAff  -- CA Declaration-Affidavit (Civil Duces Tecum) [S, V]
*      CAConNtc  -- CA Notice to Consumer [S, N, V, H]
*      CAConPOS  -- CA Proof of Service of Notice to Consumer [S, N, V, H]
*      CAUSOthr  -- CA US District Court Subpoena for non-CA court [S, N]
*      CAUSSubp  -- CA US District Court Subpoena for CA court [S, N, V]
*      CAUSPoS   -- CA US District Court Authorization Proof of Service [S, N]
*      CAUSList  -- CA US District Court Service List [N, C]
*      SubWCAB   -- CA WCAB Subpoena [S, N]
*      PrintAty  -- Print attorney information on form  [C]
*      PrtCases  -- Print case-caption information on form [C]
*      PrtCourt  -- Print court-specific information on form [C]
*      PrintDep  -- Print deponent information on form [C]
*                -- (also called by external routine ReAttch)
*
*   Uses the following RPS documents:
*      CAAttch4
*      CABBDepSubpoena
*      CABBNotice
*      CACivilDecl
*      CACivilSubpDT
*      CACivilSubpoena
*      CAConsProof
*      CAConsProofHS
*      CAConsumerNotice
*      CADepSubpoena
*      CADepPersSubpoena
*      CADSPersonal
*      CAPosNotice
*      CAPosNoticeCivil
*      CAPosNoticeDepPers
*      CAUSDCSubp
*      CAUSDCMail
*      CAUSDCSrv
*      SubpoenaXXXX (where XXXX is the USDC Court ID)
*      SubWCAB
*
*  The following routines are no longer contained in this module:
*
*      CACovLtr    -- CA Request Cover Letter for Subpoenas [S]
*                     Moved into Subp_pa, which is its only user.
*      CAAuthCov   -- CA Request Cover Letter for Authorizations [S]
*                     Moved into Subp_pa, which is its only user.
*      CABrkDwnForm - CA Rad-Path breakdown forms [S]
*                     Moved into Subp_Pa, which is its only user.
*      pGetDTxt    -- Get text for WCAB civil subpoena [S]
*                     Code added to appropriate point in subp_pa
*      CAAffidavit -- CA Affidavit (Record Certification) [S]
*                     Moved into Subp_pa, which is its only user.
*      CAAffInst   -- CA Affidavit Instructions [S]
*                     Moved into Subp_PA (only user) and then
*                     further merged into CAAffidavit within Subp_PA
*      CAUSDCPg2   -- CA US District Court Subpoena Proof of Service [S]
*                     Moved into Subp_PA (only user)
*      CAPosSub    -- CA Proof of Service of Subpoena [S]
*                     Moved into Subp_PA (only user)
*      pGetServName - Get Server's name from pick list [S, C]
*                     Replaced with external routine gfServer
*      pGetMailSign - Get Signer's name from pick list [S, C]
*                     Replaced with external routine gfSigner
*
*    Uses: gfSigner, gfServer, PrintField (in TA_Lib), PrintGroup (in TA_Lib),
*          gfUse_RO, gfMailN, gfUnUse, gfEntryF, gfLkUp
*
* History :
* Date        Name  Comment
* ---------------------------------------------------------------------------
* 05/23/05    EF    End of the 5/19/05 work
* 05/19/05    EF	Fix a bug for autpfax of 2nd req with (llrepeat =.t.) cases.
* 03/01/05    EF    Fix a bug ( assign l_faxallow when 'E-Print Notice' used)
* 02/14/05    EF    Fix a bug in the "Fax Second Requests" option
* 10/21/04    EF    Fix a bug in the CAPosNot.
* 10/01/04    EF    Fix a bug in the CAUSDCSub
* 07/07/04    DMA   Fix CAUSPoS to work with PrtCases
* 05/25/04    DMA   Switch to long plaintiff names on all documents
* 05/13/04    DMA   Use global vbls in PrtCourt, PrtCases
* 03/24/04    DMA   Correct typo in printing attorney initial (Proc. CADepSub)
* 09/16/03    DMA   Correct typo in printing of AtaFN (Proc. CADepSub)
* 07/29/03    EF    Add a atty fax number to subs and notices, add "GW" related changes
* 07/18/03    kdl   Added branch office text for pasadena's LACSC-CCW court
* 06/17/03    DMA   Pre-process all phone numbers with TRANSFORM function
* 06/16/03    DMA   Move CAUSDCPg2, CAPosSub into Subp_PA
* 06/11/03    DMA   Improved printing of court data in PrtCourt
* 05/29/03    DMA   Move CAAuthCov, CACovLtr into Subp_pa
*                   Move CA Breakdown form routine into Subp_pa
*                   Replace pGetMailSign, pGetServName, lfGetDepAt
*                        with external routine
* 05/27/03    DMA   Use gfAddCR to format memo fields for printing
* 05/14/03    DMA   Convert noticing variables to standard naming
* 05/12/03    EF    Add B & B signed subp and notice to consumer
* 04/14/03    EF    Add Breakdown Rad/Path forms.
* 11/20/02    EF    Remove PROPER when print a deponent address on a cover letter
* 11/05/02    kdl   Modif CAPosSub to look for first 11 transaction to get issue date
* 05/15/02    kdl   make sure MDEP is initiated in procedure ca_declara
* 09/12/01    EF    3-char. litigation code
* 04/12/01    EF    Notice to Consumer page changes (Oakland vs. Pasadena)
* 09/26/00    DMA   Remove old GLY2K references
* 09/18/00    EF    Add a WCAB Subp.
* 08/28/00    EF    Add a deposition personal subpoena
* 08/01/00    EF    Add a civil subpoena
* 07/20/00    EF    Replaced a default subp by new one.
* 07/12/00    EF    Print carier's signatures on all proofs of notices.
* 04/26/00    EF    Civil & Deposition subs.
* 12/17/99    EF    Notice to Consumer & Proof of Notice to Consumer
* 9/14/99     EF    AKA for CA Request Cover page
* 4/23/99     Riz   Correction for identifying plaintiff atty as requesting
* 3/1/99      Riz   Initial release
*****************************************************************************
*-------------------------------------------------------------------------------
c_today = DTOC(DATE())

******************************************************************************
* Generate a CA Deposition Subpoena (any type)
PROCEDURE CADepSub
** Called from CANotice, CACivilN, Subp_PA
* 07/07/04 DMA Use case-level globals
PARAMETERS szEdtReq, mDep, mid, d_Request, d_Depositn, lnTag
* szEdtReq      Request text ("blurb") specifying items(s) that are requested
* mDep          Deponent's name
* mid           Deponent's Mail ID code for rolodex lookup
* d_Request     Date on which the request was made
* d_Depositn    Date on which the deposition is due
* lnTag         Tag number of the request (within the current case)

* RPS Documents used:
*      CABBDepSubpoena
*      CADepSubpoena
*      CACivilSubpDT
*      CACivilSubpoena
*      CADepPersSubpoena
*      CADSPersonal
*      CAAttch4
PRIVATE dbInit, dbTAAtty, szPhone, llDefault
PRIVATE l_BBCivil, l_oldbbset
*-- 02/02/2022 MD #246793
LOCAL printAD 
printAD =.F. 

l_oldbbset=.F.
dbInit = SELECT()
oMed = CREATEOBJECT("generic.medgeneric")

&&-------------------------------------------------------------------------
*--- 12/09/2020 MD #186387	
		oMed.closealias('TagDesc')
		lcSQLLine="select dbo.GetdepName ('" +mid+ "')"
		oMed.sqlexecute(lcSQLLine,"TagDesc")
		IF USED('TagDesc')
			mDep=UPPER(ALLTRIM(NVL(TagDesc.EXP,"")))		
		ENDIF
		oMed.closealias('TagDesc')
&&-------------------------------------------------------------------------	
* Get names of courier and signer on the date the request was issued

**8/10/09 added getcaSigner/GetCADeliv
IF EMPTY( pc_MailNam)
	pc_MailNam=getcaSigner(d_Request,pc_offcode)
ENDIF
IF EMPTY( pc_ServNam)
	pc_ServNam=GetCADeliv(pc_offcode,d_Request,pc_clcode)
ENDIF

l_BBCivil = ( pc_litcode == "C  " AND pl_BBCase)
lFormExt = .F.
IF NOT USED ('SUBPOENA')
	USE (F_SUBPOENA) IN 0
ENDIF
SELECT Subpoena
SET ORDER TO CLTAG

dbSubp = ALIAS()
*--- 01/26/2021 MD that llDefault it set properly
*!*	IF SEEK( pc_clcode + STR( lnTag))
*!*		llDefault = .F.
*!*		lFormExt = Subpoena.Extra
*!*		SCATTER MEMO MEMVAR
*!*	ELSE
*!*		llDefault = .T.
*!*	ENDIF
llDefault = .T. 
IF SEEK( pc_clcode + STR( lnTag))
	*-- 01/26/2021 MD added to make sure the record was found
	SELECT Subpoena
	IF !EOF()
		IF ALLTRIM(UPPER(Subpoena.cl_code))==ALLTRIM(UPPER(pc_clcode)) AND subpoena.tag==lnTag			
			llDefault = .F.
			lFormExt = Subpoena.Extra
			SCATTER MEMO MEMVAR
		ENDIF 
	ENDIF 
ENDIF
*--------------------------------------------------------------------------
_SCREEN.MOUSEPOINTER=0

* **05/25/2011 - new or old BB set
**06/05/2015- added 3rd BB set

LOCAL ln_bbset AS INTEGER, c_rpsdoc AS STRING
oMed.closealias("BBsign")
c_sql="Select dbo.GetBBSignatureSet  ('" + DTOC(d_Request) + "')"
oMed.sqlexecute(c_sql,"BBsign")
LOCAL ln_bbset AS INTEGER, c_rpsdoc AS STRING
ln_bbset=3 && default is a new (latest set)
*-- 11/02/2023 md #335297
* c_rpsdoc="CA3BBDepSubpoena" 
c_rpsdoc="CA4BBDepSubpoena" 
IF USED("BBsign")
	ln_bbset =NVL(BBsign.EXP,3)
ENDIF

DO CASE
CASE ln_bbset =1
	c_rpsdoc ="CABBDepSubpoena"
CASE  ln_bbset =2
	c_rpsdoc ="CA2BBDepSubpoena"
OTHERWISE
	*-- 11/02/2023 md #335297
	*--c_rpsdoc ="CA3BBDepSubpoena"
	c_rpsdoc ="CA4BBDepSubpoena"
ENDCASE
**06/05/2015- added 3rd BB set  -end



* EF  05/12/03 Add option for B & B signed subpoena
* DMA 07/16/04 arGroup[ gn_Subpoena] is always "CADepSubpoena"
IF llDefault
	WAIT WINDOW "Printing " + IIF( pl_BBCase, "Berry & Berry", "Standard") + ;
		" Deposition Subpoena" NOWAIT NOCLEAR

**07/20/17: added a new CA dep subp form #66153
	*-- 03/31/2021 MD #224406 added check for WCAB
	IF LEFT(ALLTRIM(UPPER(pc_court1)), 4) = "WCAB" and pl_ofcoaK 
		DO PrintGroup WITH mv, "SubWCAB"
	ELSE 
		*-- 02/02/2022 MD #246793
		*-- DO PrintGroup WITH mv, ;
		*-- IIF( pl_BBCase, c_rpsdoc ,  IIF(pl_CivBle, "DepSubpoena","CADepSubpoena"))
		DO PrintGroup WITH mv, ;
		IIF( pl_BBCase, c_rpsdoc ,  IIF(pl_CivBle, "DepSubpoena","CADepSubpoenaAD"))
		*-- 11/02/2023 md #335297
		*IF pl_BBCase=.F. and pl_CivBle=.F.
		*	printAD=.T.
		*endif
		IF pl_CivBle=.F.
			printAD=.T.
		endif
	ENDIF 
	
***12/06/06 - added bb extra text-start
	IF pl_BBAsb
*!*			c_extrabb="Motions relating to this subpoena are to be filed and served " ;
*!*				+ "electronically pursuant to Amended General Order 158. See Attachment 3 for additional information."
		*-----------------------------------------------------------------------------------------------------------------------
		*-- 04/17/2020 MD #167744
		c_extrabb="Motions relating to this subpoena are to be filed and served " +;
		 "electronically pursuant to San Francisco Local Rule 20. See Attachment 3 for additional information. "
		*-----------------------------------------------------------------------------------------------------------------------
		*-- 04/17/2020 MD #167744						
		DO PrintField WITH mv, "ExtraBB", IIF( pc_Court1="SFSC", c_extrabb, " ")
	ENDIF
	
**07/20/17: #66153
	IF pl_CivBle
		DO PrintField WITH mv, "AttyExtra" ,  PROPER(IIF( pl_plisrq, pc_plcaptn, pc_dfcaptn))
		lc_BarNum=NVL(pc_BarNo,"")
**07/20/17 #66153
		DO PrintField WITH mv, "AttyBar" ,  lc_BarNum
	ELSE
	** -- 08/11/2020 MD #186945
		oMed.closealias("AtBarNo")
		oMed.sqlexecute("SELECT dbo.fn_AttyBarNum('" + pc_rqatcod+ "')", "AtBarNo")
		SELECT AtBarNo
		GO top
		*-- lc_BarNum=ALLTRIM(AtBarNo.exp) && 12/07/2020 MD #186387  added SBN CA: 
		lc_BarNum=IIF(!EMPTY(ALLTRIM(NVL(AtBarNo.exp,""))),"SBN CA: "+ALLTRIM(NVL(AtBarNo.exp,"")),"")	
		DO PrintField WITH mv, "BarNo" ,  lc_BarNum		
		oMed.closealias("AtBarNo")
		**--  12/07/2020 MD #186387 added attyEmail
		c_rqat=  Nvl(pc_rqatcod,'')
	    lc_EmailAdd= TxRqemail(0,c_rqat)
		Do PrintField With mv, "AttyEmail",lc_EmailAdd				
	ENDIF
ELSE
	DO CASE
* Civil Subpoena
	CASE Subpoena.TYPE = "C"

		WAIT WINDOW "Printing Civil Subpoena" NOWAIT NOCLEAR
		DO PrintGroup WITH mv, ;
			IIF( Subpoena.Extra, "CACivilSubpDT", "CACivilSubpoena")
		DO PrintField WITH mv, "Time", Subpoena.TIME + " " + ;
			ALLTRIM( Subpoena.Ampm)
		DO PrintField WITH mv, "C2", ;
			IIF( NOT EMPTY( Subpoena.Dept), "X", " ")
		DO PrintField WITH mv, "Dept", ALLTRIM( Subpoena.Dept)
		DO PrintField WITH mv, "C3", ;
			IIF( NOT EMPTY( Subpoena.Div), "X", " ")
		DO PrintField WITH mv, "Div", ALLTRIM( Subpoena.Div)
		DO PrintField WITH mv, "C4", ;
			IIF( NOT EMPTY( Subpoena.Room), "X", " ")
		DO PrintField WITH mv, "Room", ALLTRIM( Subpoena.Room)
		DO PrintField WITH mv, "C5", ;
			IIF( Subpoena.Appear, "X", " ")
		DO PrintField WITH mv, "C6", ;
			IIF( Subpoena.Produce, "X", " ")
		DO PrintField WITH mv, "DepoDate", DTOC( d_Depositn)

		c_RqAtty=fixquote(pc_rqatcod)
		_SCREEN.MOUSEPOINTER=11
		pl_GetAt = .F.
		DO gfatinfo WITH c_RqAtty, "M"
		_SCREEN.MOUSEPOINTER=0

		IF Subpoena.Extra
			DO PrintField WITH mv, "AtaFN", pc_AtyName
			DO PrintField WITH mv, "AtaLN",""
		ENDIF

		DO PrintGroup WITH mv, "Atty"
		DO PrintAty WITH pc_rqatcod

		DO PrintGroup WITH mv, "Case"
		DO PrtCases WITH pc_rqatcod


		SELECT MASTER

		DO PrintGroup WITH mv, "Control"
		DO PrintField WITH mv, "Date", DTOC(d_Request)
		lnCurArea=SELECT()
		IF LEFT( ALLT(mid), 1)=="D"
			c_drname=gfdrformat(mDep)
			c_dep = IIF(NOT "DR."$c_drname,"DR. "+ALLTRIM(c_drname),c_drname)
		ELSE
			c_dep = ALLTRIM(mDep)

		ENDIF
		SELECT (lnCurArea)

		DO PrintDep WITH mid, c_dep

		DO PrtCourt WITH  IIF(pl_CivBle, .T.,.F.)

	CASE Subpoena.TYPE = "P"
** Personal Appearance Subpoenas
		IF Subpoena.Extra
			DO PrintGroup WITH mv, "CADepPersSubpoena"
		ELSE
			DO PrintGroup WITH mv, "CADSPersonal"
			DO PrintField WITH mv, "InfoText", ;
				ALLTRIM( gfAddCR( Subpoena.Text2))
		ENDIF
		WAIT WINDOW "Printing Personal Appearance Deposition Subpoena" NOWAIT NOCLEAR
		DO PrintField WITH mv, "C1", ;
			IIF( Subpoena.Extra, "X", " ")
		DO PrintField WITH mv, "C2", ;
			IIF( NOT EMPTY( Subpoena.Deponent), "X", " ")
		DO PrintField WITH mv, "C3", ;
			IIF( NOT EMPTY( Subpoena.Produce), "X", " ")
		DO PrintField WITH mv, "C4", ;
			IIF( NOT EMPTY( Subpoena.Steno), "X", " ")
		DO PrintField WITH mv, "C5", ;
			IIF( Subpoena.Audio, "X", " ")
		DO PrintField WITH mv, "C6", ;
			IIF( Subpoena.Video, "X", " ")
		DO PrintField WITH mv, "C7", ;
			IIF( Subpoena.Trial, "X", " ")
		DO PrintField WITH mv, "C8", ;
			IIF( Subpoena.Attend, "X", " ")
		DO PrintField WITH mv, "C9", ;
			IIF( Subpoena.Original, "X", " ")
		DO PrintField WITH mv, "C10", ;
			IIF( Subpoena.Described, "X", " ")
		DO PrintField WITH mv, "C11", ;
			IIF( Subpoena.Continued, "X", " ")
		DO PrintField WITH mv, "Time", ;
			ALLTRIM( Subpoena.TIME) + " " + ALLTRIM( Subpoena.Ampm)
		DO PrintField WITH mv, "Add1", ALLTRIM( Subpoena.Add1)
		DO PrintField WITH mv, "Add2", ALLTRIM( Subpoena.Add2)
		DO PrintField WITH mv, "InfoText", ;
			STRTRAN( STRTRAN( szEdtReq, CHR(13), " "), CHR(10), "")
		DO PrintField WITH mv, "DepoDate", DTOC( d_Depositn)
* 05/25/04 DMA Switch to long plaintiff name
		DO PrintField WITH mv, "PertainsTo", ALLT( pc_plnam)


		DO PrintGroup WITH mv, "Atty"
		DO PrintAty WITH pc_rqatcod

		DO PrintGroup WITH mv, "Case"
		DO PrintField WITH mv, "Case", " "
		DO PrtCases WITH pc_rqatcod

		SELECT MASTER

		DO PrintGroup WITH mv, "Control"
		DO PrintField WITH mv, "Date",  DTOC(d_Request)

		DO PrintField WITH mv, "LrsNo", pc_lrsno
		DO PrintField WITH mv, "Tag", ALLTRIM( STR( lnTag))
		DO PrintGroup WITH mv, "Plaintiff"
		IF TYPE('pd_pldob')<>"C"
			pd_pldob=DTOC(pd_pldob)
		ENDIF
		DO PrintField WITH mv, "BirthDate", LEFT(pd_pldob,10)
		DO PrintField WITH mv, "SSN", pc_plssn
		lnCurArea=SELECT()
		IF LEFT( ALLT(mid), 1)=="D"
			c_drname=gfdrformat(mDep)
			c_dep = IIF(NOT "DR."$c_drname,"DR. "+ALLTRIM(c_drname),c_drname)
		ELSE
			c_dep = ALLTRIM(mDep)
			SELECT (lnCurArea)
		ENDIF
		DO PrintDep WITH mid, c_dep

		DO PrtCourt WITH  IIF(pl_CivBle, .T.,.F.)

	ENDCASE
ENDIF

IF llDefault
** Default subpoena -- no record found in Subpoena.dbf with special
** conditions, data, etc. for this request
	_SCREEN.MOUSEPOINTER=11
	SELECT 0
	l_GotDefName=oMed.sqlexecute("SELECT dbo.fn_GetDef_Name('" + fixquote(pc_rqatcod) + "')", "DefName")
	IF NOT l_GotDefName
		gfmessage(" Cannot get a defendant. Contact IT.")
	ELSE

		c_defend=ALLTRIM(DefName.EXP)

	ENDIF


	IF EMPTY(ALLTRIM(szEdtReq))
		szEdtReq= GetSpecInsForTag(lnTag)
	ENDIF

	_SCREEN.MOUSEPOINTER=0
	DO PrintField WITH mv, "InfoText", ;
		STRTRAN( STRTRAN( szEdtReq, CHR(13), " "), CHR(10), "")
	DO PrintField WITH mv, "DepoDate", DTOC( d_Depositn)

	DO PrintField WITH mv, "PertainsTo", ALLT( pc_plnam)

	DO PrintGroup WITH mv, "Atty"
	DO PrintAty WITH pc_rqatcod

	DO PrintGroup WITH mv, "Case"
	DO PrintField WITH mv, "Case", " "
	DO CASE
	CASE pl_ofcOak
		DO PrintField WITH mv, "Def_name", ;
			IIF( pl_BBCase AND pc_litcode = "C  ", "", ALLTRIM( pc_dfcaptn))

	OTHERWISE
		DO PrintField WITH mv, "Def_name", ;
			IIF( pl_PSGWC, ", " + c_defend, "")
	ENDCASE

	DO PrtCases WITH pc_rqatcod

	SELECT MASTER

	DO PrintGroup WITH mv, "Control"
	DO PrintField WITH mv, "Date",  DTOC(d_Request)
	DO PrintField WITH mv, "LrsNo", pc_lrsno
	DO PrintField WITH mv, "Tag", ALLTRIM( STR( lnTag))

	IF llDefault
		DO PrintField WITH mv, "Loc", pc_offcode + IIF( pl_BBAsb, "A", "")
	ENDIF
	lnCurArea=SELECT()
	IF LEFT( ALLT(mid), 1)=="D"
		c_drname=gfdrformat(mDep)
		c_dep = IIF(NOT "DR."$c_drname,"DR. "+ALLTRIM(c_drname),c_drname)
	ELSE
		c_dep = ALLTRIM(mDep)

	ENDIF
	SELECT(lnCurArea)
	DO PrintDep WITH mid, c_dep

	DO PrtCourt WITH  IIF(pl_CivBle, .T.,.F.)
	IF TYPE('pd_pldob')<>"C"
		pd_pldob=DTOC(pd_pldob)
	ENDIF
	DO PrintGroup WITH mv, "Plaintiff"
	DO PrintField WITH mv, "BirthDate",  LEFT(pd_pldob,10)
	&& 12/07/2020 MD #186387
	lnDigitCnt=0
	IF !EMPTY(ALLTRIM(NVL(pc_plssn,"")))
		FOR lnHHH=1 TO LEN(ALLTRIM(pc_plssn))
		    IF ISDIGIT(SUBSTR(ALLTRIM(pc_plssn),lnHHH,1))=.T.
		       lnDigitCnt=lnDigitCnt+1
		    ENDIF 
		NEXT
	ENDIF 
	
	*-- DO PrintField WITH mv, "SSN", pc_plssn
    DO PrintField WITH mv, "SSN", IIF(!EMPTY(ALLTRIM(NVL(pc_plssn,""))) AND lnDigitCnt>0,lnDigitCnt,"")
    * -------------------------------------------------------
    && 08/20/2019 MD #141352
	LOCAL ldefendantName
	ldefendantName=""		
	oMed.closealias("viewDefName")
	SELECT 0
	oMed.sqlexecute("exec dbo.AttyDefName '" + fixquote(pc_clcode)+ "', '"+Iif( pl_plisrq, "P", "D")+"'", "viewDefName")
	IF USED("viewDefName")
		 ldefendantName=ALLTRIM(viewDefName.defendantName)		 	
	ENDIF
		 			
	Do PrintField With mv, "DefendantName", ldefendantName   
	
*--------------------------------------------------------------
ELSE
** Non-default subpoena -- Subpoena.dbf has a record for the
** case/tag being processed, with data on special details for the document
	IF Subpoena.Continued AND Subpoena.Extra
* Print attachment 4
		WAIT WINDOW "Printing Attachment to Subpoena" NOWAIT NOCLEAR
		DO PrintGroup WITH mv, "CAAttch4"
		DO PrintField WITH mv, "InfoText", gfAddCR( Subpoena.Text2)
		lnCurArea=SELECT()
		IF LEFT( ALLT(mid), 1)=="D"
			c_drname=gfdrformat(mDep)
			c_dep = IIF(NOT "DR."$c_drname,"DR. "+ALLTRIM(c_drname),c_drname)
		ELSE
			c_dep = ALLTRIM(mDep)

		ENDIF
		SELECT (lnCurArea)
		DO PrintDep WITH mid, c_dep

		DO PrintGroup WITH mv, "Plaintiff"
* 05/25/04 DMA Switch to long plaintiff name
		DO PrintField WITH mv, "FirstName", ALLTRIM( pc_plnam)
		DO PrintField WITH mv, "MidInitial", ""
		DO PrintField WITH mv, "LastName", ""
		IF TYPE('pd_pldob')<>"C"
			pd_pldob=DTOC(pd_pldob)
		ENDIF
		DO PrintField WITH mv, "BirthDate",  LEFT(pd_pldob,10)
		DO PrintField WITH mv, "SSN", pc_plssn

		DO PrintGroup WITH mv, "Case"
		DO PrintField WITH mv, "Case", " "


		DO CASE
		CASE pl_ofcOak
			IF (pc_litcode = "C  " AND pc_rqatcod = "BEBE  3C" )
				DO PrintField WITH mv, "Def_name", ""
			ELSE
				DO PrintField WITH mv, "Def_name", ALLTRIM( pc_dfcaptn)
			ENDIF
		OTHERWISE
			DO PrintField WITH mv, "Def_name", ;
				IIF( pl_PSGWC, ", " + c_defend, "")
		ENDCASE


		DO PrtCases WITH pc_rqatcod

		SELECT MASTER

		DO PrintGroup WITH mv, "Control"
		DO PrintField WITH mv, "Date",  DTOC(d_Request)
		DO PrintField WITH mv, "LrsNo", pc_lrsno
		DO PrintField WITH mv, "Tag", ALLTRIM( STR( lnTag))


	ENDIF
ENDIF
* -------------------------------------------------------
IF printAD=.T.
   *-- 02/02/2022 MD #246793 added AmendedDepDate
	LOCAL ldAmendedDepDate
	ldAmendedDepDate=""		
	oMed.closealias("viewAmendedDepDate")
	SELECT 0
	oMed.sqlexecute("exec dbo.AmendedDepDate '" + fixquote(pc_clcode)+ "', "+ALLTRIM(STR(lnTag)), "viewAmendedDepDate")
	IF USED("viewAmendedDepDate")
		 ldAmendedDepDate=ALLTRIM(viewAmendedDepDate.AmendedDepDate)		 	
	ENDIF
	oMed.closealias("viewAmendedDepDate")	 			
	Do PrintField With mv, "AmendedDepDate", ldAmendedDepDate
ENDIF 
*--------------------------------------------------------------

SELECT (dbInit)
WAIT CLEAR

RETURN

*-------------------------------------------------------------------------------

PROCEDURE CAPosNot
** Print Proof of service of notice
** Called from CANotice, CACivilN, Subp_PA
** Also calls itself recursively in special situations

PARAMETERS nTag, llHS, llNotice, llDefOnly, ldControl
* nTag: Tag number of deponent being noticed
* llHS: .T. for hand-serve; .F. for US Mail
* llNotice: .T. if "LOCATION: <deponent>" field is to be printed
* llDefOnly: .T. if notices go only to defense attorneys
* ldControl: Date to be printed on notice
PRIVATE dbInit, dbTAAtty, mPhone, dbTABills, nCount, nLoop, ;
	lcAt_Code, arAtty, lcString1, lcString2, lnDefCnt, llRepeat
PRIVATE c_detail1, c_detail2, c_detail3, c_NotcType, c_defend, c_Atty, lnCurArea,lc_AttyNoticeEmail,lc_AttyNoticeFax
PRIVATE oMedPOS AS OBJECT
c_Atty=""
dbInit = SELECT()
oMedPOS= CREATEOBJECT("generic.medgeneric")
WAIT WINDOW "Printing Proof of Service of Notice" NOWAIT NOCLEAR
_SCREEN.MOUSEPOINTER=11
IF NOT TYPE( "ldControl") = "D"
	*gfmessage("Problem...")
	ldControl=convertToDate(ldControl)

ENDIF
*-- 02/10/2021 MD #224406 added check for WCAB
IF LEFT(ALLTRIM(UPPER(pc_court1)), 4) = "WCAB" and pl_ofcoaK 
	DO WCABProof WITH nTag, llHS, llNotice, llDefOnly, ldControl
	RETURN
ENDIF 
	
llRepeat = .F.

IF NOT llDefOnly
	IF llHS
** If llHS was .T., then determine if a recursive call will
** be needed after this document is generated.
** Note that llHS will be .F. if this already is a recursive call.
** This prevents going beyond one level of recursion.
		llRepeat = ( gfDefCnt( .F.) > 0)

	ENDIF
ENDIF

c_defend = ""

SELECT 0
l_GotDefName=oMedPOS.sqlexecute("SELECT dbo.fn_GetDef_Name('" + fixquote(pc_rqatcod) + "')", "DefName")
IF NOT l_GotDefName
	gfmessage(" Cannot get a defendant. Contact IT.")
ELSE
	c_defend=ALLTRIM(DefName.EXP)
ENDIF

IF NOT USED( "Subpoena")
	SELECT 0
	USE (f_subpoena) ORDER CLTAG
ENDIF

SELECT Subpoena

llDefault = .T.
lFormExt = .F.
c_NotcType = " "
IF SEEK( pc_clcode + STR( nTag))
	llDefault = .F.
	lFormExt = Subpoena.Extra
	c_NotcType = Subpoena.TYPE

ENDIF

_SCREEN.MOUSEPOINTER=0
IF llDefault
**07/25/2017 : #66153 - proof  by mail
	IF pl_CivBle
		DO PrintGroup WITH mv, "PosNotice"
	ELSE

		*DO PrintGroup WITH mv, "CAPosNotice"		
			DO PrintGroup WITH mv, "CAPosNotice"		
			 * -------------------------------------------------------
	    	&& 11/25/2019 MD #186387  
			LOCAL ldefendantName
			ldefendantName=""		
			oMedPos.closealias("viewDefName")
			SELECT 0
			oMedPos.sqlexecute("exec dbo.AttyDefName '" + fixquote(pc_clcode)+ "', '"+Iif( pl_plisrq, "P", "D")+"'", "viewDefName")
			IF USED("viewDefName")
				 ldefendantName=ALLTRIM(viewDefName.defendantName)		 	
			ENDIF
			 			
			Do PrintField With mv, "DefendantName", ldefendantName  
			&& 11/25/2019 MD #186387 		
	ENDIF

ELSE
	DO CASE
	CASE c_NotcType = "P"
		DO PrintGroup WITH mv, "CAPosNoticeDepPers"
		DO PrintField WITH mv, "FormExtra", ;
			IIF( lFormExt, "(and production of Documents and Things)", "")
		DO PrintField WITH mv, "FormExtra2", ;
			IIF( lFormExt, ;
			"including Notice to Consumer pursuant to CCP 1985.3/" + ;
			"Notice to Employee pursuant to 1985.6 (if applicable)", "")

	CASE c_NotcType = "C"
		DO PrintGroup WITH mv, "CAPosNoticeCivil"
		DO PrintField WITH mv, "FormExtra", ;
			IIF( lFormExt, ;
			"(Duces Tecum and supporting affidavit if applicable), " + ;
			"including Notice to Consumer pursuant to CCP 1985.3/" + ;
			"Notice to Employee pursuant to 1985.6 (if applicable)", "")

	ENDCASE
ENDIF
	
DO PrintField WITH mv, "Loc", pc_offcode
DO PrintField WITH mv, "How", IIF( llHS, "H", "N")
DO PrintField WITH mv, "ByMail", IIF( llHS, " ", "BY MAIL ")

IF pl_CivBle
	DO PrintField WITH mv, "AttyExtra" ,  PROPER(IIF( pl_plisrq, pc_plcaptn, pc_dfcaptn))
	lc_BarNum=NVL(pc_BarNo,"")
**07/25/17 #66153
	DO PrintField WITH mv, "AttyBar" ,  lc_BarNum
ELSE
	** -- 08/11/2020 MD #186945
		oMedPos.closealias("AtBarNo")
		oMedPos.sqlexecute("SELECT dbo.fn_AttyBarNum('" + pc_rqatcod+ "')", "AtBarNo")
		SELECT AtBarNo
		GO top
		* -- lc_BarNum=NVL(pc_BarNo,"") && 12/07/2020 MD #186387  Added SBN CA:	
		lc_BarNum=IIF(!EMPTY(ALLTRIM(NVL(AtBarNo.exp,""))),"SBN CA: "+ALLTRIM(NVL(AtBarNo.exp,"")),"")	
		DO PrintField WITH mv, "BarNo" ,  lc_BarNum
		oMedPos.closealias("AtBarNo")				
ENDIF




lcPara = ""
IF NOT llHS
*!*		IF pl_OfcPas THEN
*!*			c_detail1 = "Walnut Professional Building, 711 E Walnut St, Suite 201"
*!*			c_detail2 = "Pasadena CA  91101"
*!*			c_detail3 = "Pasadena"
*!*		ELSE
		c_detail1 = "130 Webster Street, Suite 100"
		c_detail2 = "Oakland, CA  94607"
		c_detail3 = "Oakland"
*!*		ENDIF
	lcPara = "and, following ordinary business practice at " + c_detail1 + ", " + ;
		c_detail2 + " for collection and processing of correspondence for mailing " + ;
		"with the United States Postal Service, caused said documents to be mailed the same day" + ;
		" in the United States Post Office at " + c_detail3 + ", California." + CHR(13)
ENDIF
DO PrintField WITH mv, "Para", lcPara

**8/10/09 added getcaSigner/GetCADeliv
IF EMPTY( pc_MailNam)
	pc_MailNam=getcaSigner(ldControl,pc_offcode)
ENDIF
IF EMPTY( pc_ServNam)
	pc_ServNam=GetCADeliv(pc_offcode,ldControl,pc_clcode)
ENDIF
**8/10/09

DO PrintField WITH mv, "MailPers", IIF( llHS, pc_ServNam, pc_MailNam)

DO PrintGroup WITH mv, "Deponent"

IF TYPE("pc_MailID")!='C'
	pc_MailID=""
ENDIF
IF TYPE("mdep")!='C'
	mDep=CANOTICE.DESCRIPT
ENDIF

IF LEFT( ALLT(pc_MailID), 1)=="D" AND !EMPTY(ALLTRIM(pc_MailID))
	c_drname=gfdrformat(mDep)
	c_dep = IIF(NOT "DR."$c_drname,"DR. "+ALLTRIM(c_drname),c_drname)
ELSE

	c_dep = ALLTRIM(mDep)

ENDIF

DO PrintField WITH mv, "Name", IIF( llNotice, " ", "LOCATION: " + c_dep)

DO PrintGroup WITH mv, "Control"
DO PrintField WITH mv, "Date", DTOC( ldControl)

DO PrintGroup WITH mv, "Atty"
DO PrintAty WITH pc_rqatcod

l_Tabill=gettabill(pc_clcode)
IF NOT l_Tabill
	gfmessage("Cannot get TAbills file")
	RETURN
ENDIF

SELECT tabills


nCount = 0
IF llDefOnly
* Build array of participating defense attorneys
	SELECT CODE, At_Code FROM tabills  INTO ARRAY arAtty ;
		WHERE tabills.cl_Code = pc_clcode ;
		AND tabills.At_Code <> pc_rqatcod ;
		AND tabills.CODE = "D" ;
		AND INLIST( tabills.Response, "T", "S") ;
		AND NOT tabills.NoNotice
ELSE
* Build array of all participating attorneys
* (only plaintiff att'ys if this is a recursive call [llRepeat = .T.])
	SELECT CODE, At_Code FROM tabills  INTO ARRAY arAtty ;
		WHERE tabills.cl_Code = pc_clcode ;
		AND tabills.At_Code <> pc_rqatcod ;
		AND IIF( llRepeat, tabills.CODE = "P", .T.) ;
		AND INLIST( tabills.Response, "T", "S") ;
		AND NOT tabills.NoNotice
ENDIF
gnCount = _TALLY

_SCREEN.MOUSEPOINTER=0


IF gnCount =0
	= gfmsg( "No Participating Attys..  Make a note.")
ENDIF
IF gnCount > 0
	= ASORT( arAtty, 1, -1, 1)

	nCount = ALEN( arAtty) / 2
	FOR nLoop = 1 TO ROUND( nCount/2, 0)
		DO PrintGroup WITH mv, "Item"
		lcString1 = " "
		lcString2 = " "

		lcAt_Code = arAtty[ nLoop*2-1, 2]
		**---------------------------------------
		&& 12/09/2020 MD #186387
		lnCurArea=SELECT()
		lc_AttyNoticeEmail=""
		oMedPos.closealias("viewAttyNoticeEmail")
		oMedPos.sqlexecute("exec  [dbo].[getAttyNoticeEmail] '" + lcAt_Code+ "'", "viewAttyNoticeEmail")
		SELECT viewAttyNoticeEmail
		GO top		
		lc_AttyNoticeEmail=ALLTRIM(LOWER(NVL(viewAttyNoticeEmail.email,"")))	
		lc_AttyNoticeFax=ALLTRIM(LOWER(NVL(viewAttyNoticeEmail.fax,"")))	
		oMedPos.closealias("viewAttyNoticeEmail")	
		SELECT (lnCurArea)
		**---------------------------------------
		lcString1=getstring1(lcAt_Code)+;
		IIF(!EMPTY(ALLTRIM(lc_AttyNoticeEmail)),ALLTRIM(lc_AttyNoticeEmail)+CHR(13),"")+;
		IIF(!EMPTY(ALLTRIM(lc_AttyNoticeFax)),ALLTRIM(lc_AttyNoticeFax)+CHR(13),"")
		


*     Prepare column 2 data, if any
		IF (nLoop < ROUND( nCount/2, 0)) OR MOD( nCount, 2) = 0
			lcAt_Code = arAtty[ nLoop*2, 2]
			**---------------------------------------
			&& 12/09/2020 MD #186387
			lnCurArea=SELECT()
			lc_AttyNoticeEmail=""
			oMedPos.closealias("viewAttyNoticeEmail")
			oMedPos.sqlexecute("exec  [dbo].[getAttyNoticeEmail] '" + lcAt_Code+ "'", "viewAttyNoticeEmail")
			SELECT viewAttyNoticeEmail
			GO top		
			lc_AttyNoticeEmail=ALLTRIM(LOWER(NVL(viewAttyNoticeEmail.email,"")))	
			lc_AttyNoticeFax=ALLTRIM(LOWER(NVL(viewAttyNoticeEmail.fax,"")))		
			oMedPos.closealias("viewAttyNoticeEmail")	
			SELECT (lnCurArea)
		**---------------------------------------
			lcString2=getstring2(lcAt_Code)+;
			IIF(!EMPTY(ALLTRIM(lc_AttyNoticeEmail)),ALLTRIM(lc_AttyNoticeEmail)+CHR(13),"")+;
			IIF(!EMPTY(ALLTRIM(lc_AttyNoticeFax)),ALLTRIM(lc_AttyNoticeFax)+CHR(13),"")

		ENDIF

		DO PrintField WITH mv, "Col1", lcString1
		DO PrintField WITH mv, "Col2", lcString2
	ENDFOR

ENDIF


DO PrtCourt WITH .T.
**EF 10/21/2004 - reordered fields in the "Case" Group to fix a bug
DO PrintGroup WITH mv, "Case"
DO PrintField WITH mv, "Def_name", ;
	IIF( pl_PSGWC, ", " + ALLTRIM(DefName.EXP), "")
DO PrtCases WITH pc_rqatcod
** If this was a Hand Served notice (llHS = .T.), it listed only the plaintiff's
** attorney(s). Now, if there are defense attorneys in the case, generate
** another copy of this proof of service which lists the defense attorneys.
** For this copy, llHS is set .F. and llDefOnly is set .T.
IF TYPE ( "l_FaxAllow")= "U"
	IF TYPE ( "l_Fax1Req")= "U" OR TYPE ( "l_PrtFax")= "U"
		l_Fax1Req=.F.
		l_PrtFax =.F.
	ENDIF
	l_FaxAllow = (pl_1st_Req AND (l_Fax1Req OR l_PrtFax))
	l_Fax2Req=.F.

ENDIF
IF llRepeat
**keep calling an old one as it is still used for other types
	DO CAPosNot WITH nTag, .F., llNotice, .T., ldControl
*DO CAPOSPage WITH NTAG, .F., llNotice, .T., ldControl, "P"
ENDIF
**EF 02/14/05 - fax sec requests
IF pc_offcode="C"

	IF l_FaxAllow AND  NOT l_Fax2Req
		c_fax = STRTRAN( szfaxnum, " ", "")
		c_temp = STRTRAN( c_fax, "-", "")
		c_temp2 = STRTRAN( c_temp, "(", "")
		szfaxnum = STRTRAN( c_temp2, ")", "")
	ENDIF
ELSE
	l_Fax2Req=.F.
ENDIF

RELEASE oMedPOS
SELECT (dbInit)

WAIT CLEAR

RETURN

*EF-------------------------------------------------------------------------------

PROCEDURE CADecAff
** Print Declaration-Affidavit (Civil Duces Tecum)
** Used only for Civil subpoenas involving a declaration or affidavit
* Called by Subp_pa, CACivilN
* 07/19/04 DMA Use case-level globals; eliminate TAMaster references
PARAMETERS nTag, dTxnDate
PRIVATE dbInit, lcAttfor, lcOther
STORE "" TO lcAttfor, lcOther
dbInit = SELECT()

SELECT DECL
SET ORDER TO CLTAG


SEEK( pc_clcode + STR(nTag))
IF FOUND()
	SCATTER MEMO MEMVAR
	lcAttfor = DECL.c9
	lcOther = DECL.c10
	SELECT 0

	WAIT WINDOW "Getting special instruction blurb.. Please wait." NOWAIT NOCLEAR
	_SCREEN.MOUSEPOINTER=11

	l_GetSpIns=oMed.sqlexecute( " exec [dbo].[GetSpecInsByClCodeTag] '" + fixquote(pc_clcode) + "','" + STR(nTag) + "'", "Spec_ins")
	IF NOT l_GetSpIns
		gfmessage("Cannot get Special Instruction Table. Contact IT dept.")
		RETURN
	ENDIF
	dbSpec_Ins = ALIAS()

	szrequest = spec_ins.spec_inst
	szEdtReq = ""
	mid = spec_ins.MailID_No
	IF INLIST( TYPE( "mdep"), "U", "L") OR ALLT(mDep) == ""

		IF LEFT( ALLT(mid), 1)=="D"
			c_drname=gfdrformat(spec_ins.DESCRIPT)
			mDep = IIF(NOT "DR."$c_drname,"DR. "+ALLTRIM(c_drname),c_drname)
		ELSE
			mDep = ALLTRIM(spec_ins.DESCRIPT)
		ENDIF

	ENDIF

	szEdtReq = gfAddCR( szrequest)

	_SCREEN.MOUSEPOINTER=11
	dbInit = SELECT()

	WAIT WINDOW "Printing Declaration." NOWAIT NOCLEAR

	DO PrintGroup WITH mv, "CACivilDecl"

	DO PrintField WITH mv, "Date", DTOC( dTxnDate)
	DO PrintField WITH mv, "Text4", DECL.Text4
	DO PrintField WITH mv, "Text2", szEdtReq
	DO PrintField WITH mv, "Text3", DECL.Text3

	DO PrintField WITH mv, "C1", IIF(DECL.C1, "X", " ")
	DO PrintField WITH mv, "C2", IIF(DECL.C2, "X", " ")
	DO PrintField WITH mv, "C3", IIF(DECL.C3, "X", " ")
	DO PrintField WITH mv, "C4", IIF(DECL.C4, "X", " ")
	DO PrintField WITH mv, "C5", IIF(DECL.C5, "X", " ")
	DO PrintField WITH mv, "C6", IIF(DECL.C6, "X", " ")
	DO PrintField WITH mv, "C7", IIF(DECL.C7, "X", " ")
	DO PrintField WITH mv, "C8", IIF(DECL.C8, "X", " ")
	DO PrintField WITH mv, "C9", ALLTRIM( lcAttfor)
	DO PrintField WITH mv, "C10", ALLTRIM( lcOther)
	mDOB =  pd_pldob
	mDOB2 = SUBSTR(mDOB,5,2) + '-' + SUBSTR(mDOB,7,2) + '-' + SUBSTR(mDOB,1,4)

&&pc_offcode, pl_CaVer
	c_plname=pc_plnam
**12/07/06 -  print plaintiff cap for plaintiffs with dod-start
	IF !EMPTY(convrtDate(pd_pldod)) AND pl_ofcOak
		pc_plnam=pc_plcaptn
	ENDIF
**12/07/2006 - print plaintiff cap for plaintiffs with dod-end
	DO PrintField WITH mv, "PertainsTo", 	ALLTRIM( pc_plnam) + " " + "DOB: " + ;
		mDOB2 + " " + "SSN :" + pc_plssn

	pc_plnam=c_plname
	DO PrintGroup WITH mv, "Atty"
	DO PrintAty WITH pc_rqatcod

	DO PrintGroup WITH mv, "Case"
	DO PrintField WITH mv, "Plcap", ALLTRIM(pc_plcaptn)
	DO PrintField WITH mv, "Defcap", ALLTRIM(pc_dfcaptn)
	DO PrintField WITH mv, "Case", " "
	DO PrintField WITH mv, "Docket", ALLTRIM(pc_docket)

&&EF attachment 2 added to a civil subp. 8/8/01
	DO PrintGroup WITH mv, "Control"
	DO PrintField WITH mv, "LrsNo", pc_lrsno
	DO PrintField WITH mv, "Tag", ALLTRIM(STR(nTag))
	IF TYPE("pc_MailID")!='C'
		pc_MailID=""
	ENDIF
	IF LEFT( ALLT(pc_MailID), 1)=="D" AND !EMPTY(ALLTRIM(pc_MailID))
		c_drname=gfdrformat(mDep)
		c_dep = IIF(NOT "DR."$c_drname,"DR. "+ALLTRIM(c_drname),c_drname)
	ELSE
		c_dep = ALLTRIM(mDep)

	ENDIF

	DO PrintDep WITH mid, c_dep

	DO PrintGroup WITH mv, "Plaintiff"
* 05/25/04 DMA Switch to long plaintiff name
	DO PrintField WITH mv, "FirstName", ALLTRIM( pc_plnam)
	DO PrintField WITH mv, "MidInitial", ""
	DO PrintField WITH mv, "LastName", ""
	IF TYPE('pd_pldob')<>"C"
		pd_pldob=DTOC(pd_pldob)
	ENDIF
	DO PrintField WITH mv, "BirthDate",  LEFT(pd_pldob,10)
	DO PrintField WITH mv, "SSN", pc_plssn
	SELECT (dbInit)
	WAIT CLEAR

ENDIF

RETURN
*-------------------------------------------------------------------------------
PROCEDURE CAConNtc
** Notice to Consumer
* Called from CANotice, CACivilN, Subp_PA, HIPAASet
* 07/19/04 DMA Update to use case-level globals, eliminate TAMaster references

PARAMETERS ldControl, llHS, ldDepDate, mDep, mid
PRIVATE lcDepAdd, lcDepAdd2, ilenth, lcCity, dbInit, dbTAAtty, c_roloname, c_sql , l_oldbbset
*-- 02/10/2021 MD #224406 added check for WCAB
IF LEFT(ALLTRIM(UPPER(pc_court1)), 4) = "WCAB" and pl_ofcoaK 
	RETURN
ENDIF 
*-- 02/10/2021 ------------------------------
PRIVATE oMedNtc AS OBJECT
oMedNtc= CREATEOBJECT("generic.medgeneric")
l_oldbbset=.F.
dbInit = SELECT()
&&-------------------------------------------------------------------------
*--- 12/09/2020 MD #186387	
		oMedNtc.closealias('TagDesc')
		lcSQLLine="select dbo.GetdepName ('" +mid+ "')"
		oMedNtc.sqlexecute(lcSQLLine,"TagDesc")
		IF USED('TagDesc')
			mDep=UPPER(ALLTRIM(NVL(TagDesc.EXP,"")))		
		ENDIF
		oMedNtc.closealias('TagDesc')	
&&-------------------------------------------------------------------------	
*-- 11/23/2020 MD #186387  
LOCAL noticeAtty , noticeTag
IF !USED("CANotice")	
	IF !USED("RECORD")
		NoticeTag=1
	ELSE
 		SELECT RECORD
		noticeTag=RECORD.tag
	ENDIF 
ELSE
	noticeTag=CANotice.tag
ENDIF 	
IF TYPE("noticeTag")<>"N"
	noticeTag=VAL(noticeTag)
ENDIF 	

oMedNtc.closealias("viewNoticeAttyList")
c_sql="exec  dbo.CANoticeConsumerList '"+ALLTRIM(UPPER(pc_clcode))+"',"+ALLTRIM(str(noticeTag))+",1"
oMedNtc.sqlexecute(c_sql,"viewNoticeAttyList")
SELECT viewNoticeAttyList
SCAN 		
	noticeAtty=NVL(viewNoticeAttyList.at_code,"")
	IF EMPTY(ALLTRIM(noticeAtty))
	   LOOP
	ENDIF 
	WAIT WINDOW "Printing Notice to Consumer  - "+ALLTRIM(noticeAtty) NOWAIT NOCLEAR
	
	**06/05/2015- added 3rd BB set
	**05/25/2011 - new or old BB set
	oMedNtc.closealias("BBsign")
	*c_sql="Select dbo.NewBBSignature ('" + DTOC(ldControl) + "')"
	c_sql="Select dbo.GetBBSignatureSet  ('" + DTOC(ldControl) + "')"
	oMedNtc.sqlexecute(c_sql,"BBsign")
	LOCAL ln_bbset AS INTEGER, c_rpsdoc AS STRING
	ln_bbset=3 && default is a new (latest set)
	IF USED("BBsign")
		ln_bbset =NVL(BBsign.EXP,3)
	ENDIF
	**05/25/2011 - new or old BB set

	DO CASE

	CASE ln_bbset =1
		c_rpsdoc ="CABBNotice"
	CASE  ln_bbset =2
		c_rpsdoc ="CA2BBNotice"
	OTHERWISE
		*-- 11/02/2023 md #335297
		*c_rpsdoc ="CA3BBNotice"
		c_rpsdoc ="CA4BBNotice"
	ENDCASE

	**06/05/2015- added 3rd BB set  -end

	* 07/25/2017: added pl_CivBle  #66153
	
	*-- 02/15/2022 MD #246793
	*-- DO PrintGroup WITH mv, IIF( pl_BBCase, c_rpsdoc ,  IIF(pl_CivBle,"ConsumerNotice","CAConsumerNotice"))
	DO PrintGroup WITH mv, IIF( pl_BBCase, c_rpsdoc ,  IIF(pl_CivBle,"ConsumerNotice","CAConsumerNoticeAD"))
	
	*-- DO PrintField WITH mv, "How", IIF( llHS, "PERSONALLY DELIVERED", "MAILED") &&&11/23/2020 MD #186387  
	DO PrintField WITH mv, "How", NVL(viewNoticeAttyList.deliverytype,"MAILED")
	DO PrintField WITH mv,"RequestDate", DTOC( ldControl)
	DO PrintField WITH mv, "DepDate", DTOC( ldDepDate)
	
	
	* -------------------------------------------------------
	* IF pl_BBCase=.F. and pl_CivBle=.F.
	* 11/02/2023 Include BB cases 
	IF pl_CivBle=.F.
	   *-- 02/15/2022 MD #246793 added AmendedDepDate
		LOCAL ldAmendedDepDate
		ldAmendedDepDate=""		
		oMedNtc.closealias("viewAmendedDepDate")
		SELECT 0
		oMedNtc.sqlexecute("exec dbo.AmendedDepDate '" + fixquote(pc_clcode)+ "', "+ALLTRIM(str(noticeTag)), "viewAmendedDepDate")
		IF USED("viewAmendedDepDate")
			 ldAmendedDepDate=ALLTRIM(viewAmendedDepDate.AmendedDepDate)		 	
		ENDIF
		oMedNtc.closealias("viewAmendedDepDate")	 			
		Do PrintField With mv, "AmendedDepDate", ldAmendedDepDate
	ENDIF 
	*--------------------------------------------------------------

	**07/25/17: #66153
	IF pl_CivBle
		DO PrintField WITH mv, "AttyExtra" ,  PROPER(IIF( pl_plisrq, pc_plcaptn, pc_dfcaptn))
		*---  lc_BarNum=NVL(pc_BarNo,"") &&& 11/23/2020 MD #186387 
		lc_BarNum=NVL(viewNoticeAttyList.barNo,"")		
		DO PrintField WITH mv, "AttyBar" ,  lc_BarNum
	**IF rq atty is defense THEN plcap AND vs.
		DO PrintField WITH mv, "AttyNotName" ,  IIF( pl_plisrq, pc_plcaptn, pc_dfcaptn)
	ELSE
	 	** -- 08/11/2020 MD #186945
			oMedNtc.closealias("AtBarNo")
			oMedNtc.sqlexecute("SELECT dbo.fn_AttyBarNum('" + pc_rqatcod+ "')", "AtBarNo")  	
			SELECT AtBarNo
			GO top
			*-- lc_BarNum=ALLTRIM(AtBarNo.exp) && 12/07/2020 MD #186387  added SBN CA: 			
			lc_BarNum=IIF(!EMPTY(ALLTRIM(NVL(AtBarNo.exp,""))),"SBN CA: "+ALLTRIM(NVL(AtBarNo.exp,"")),"")	
			DO PrintField WITH mv, "BarNo" ,  lc_BarNum
			oMedNtc.closealias("AtBarNo")
			**--  12/07/2020 MD #186387 added attyEmail
			c_rqat=  Nvl(pc_rqatcod,'')
	    	lc_EmailAdd= TxRqemail(0,c_rqat)
			Do PrintField With mv, "AttyEmail",lc_EmailAdd	
	ENDIF

	IF pl_CivBle
		DO PrintDep WITH mid, mDep

	ELSE  && OLD DOCS AS 07/25/17
		DO PrintGroup WITH mv, "Deponent"
		STORE "" TO lcDepAdd, lcDepAdd2, lcComma


		*--IF TYPE('pc_Descrpt')<>"C" 10/27/2021 MD #255107 always refresh deponent info
	**5/4/2010 (in case pc_Descrpt is nor defined)
			pl_GotDepo = .F.
			cl_CL_code=pc_clcode
			*nl_TAG =lnTag	&& 11/02/2021 MD lnTag is not always defined use noticeTag instead		
			*DO gfGetDep WITH cl_CL_code, nl_TAG
			DO gfGetDep WITH cl_CL_code, noticeTag
		*--ENDIF

		IF NOT USED("pc_DepoFile") OR pl_CANotc

			WAIT WINDOW "Getting Deponent's information." NOWAIT NOCLEAR
			_SCREEN.MOUSEPOINTER=11
			c_deptype="Z"

			c_deptype=deptbydesc(pc_Descrpt)
			l_mail=oMedNtc.sqlexecute("exec dbo.GetDepInfoByMailIdDept '" + mid+"','" + c_deptype + "' ", "pc_DepoFile")
			=CURSORSETPROP("KeyFieldList", "Code, id_tbldeponents", "pc_DepoFile")
		ELSE
			IF ALLTRIM(pc_DepoFile.MailID_No)<>ALLTRIM(mid)
				WAIT WINDOW "Getting Deponent's information" NOWAIT NOCLEAR
				_SCREEN.MOUSEPOINTER=11
				c_deptype="Z"
				c_deptype=deptbydesc(pc_Descrpt)
				l_mail=oMedNtc.sqlexecute("exec dbo.GetDepInfoByMailIdDept '" + mid+"','" + c_deptype + "' ", "pc_DepoFile")
				=CURSORSETPROP("KeyFieldList", "Code, id_tbldeponents", "pc_DepoFile")
			ENDIF

		ENDIF


	**3/26/09- Fix the lost pc_mailid_no value
	**11/04/08- If no public mail_id defined- takes the one from above file
		IF TYPE("pc_MailID")!='C' OR pc_MailID<> mid
			SELECT pc_DepoFile
			IF _TALLY=0
				pc_MailID=""
			ELSE
				pc_MailID=pc_DepoFile.MailID_No
			ENDIF
		ENDIF
	**11/04/08-end
		IF LEFT( ALLT(pc_MailID), 1)=="D" AND !EMPTY(ALLTRIM(pc_MailID))
			c_drname=gfdrformat(mDep)
			c_dep = IIF(NOT "DR."$c_drname,"DR. "+ALLTRIM(c_drname),c_drname)
		ELSE
			c_dep = ALLTRIM(mDep)

		ENDIF

		lcCity=ALLTRIM(pc_DepoFile.city)
		lcDepAdd= c_dep + " " + ALLTRIM(pc_DepoFile.Add1)

		ilenth = LEN( lcDepAdd) + LEN( lcCity)

		lcDepAdd = ALLTRIM(lcDepAdd) + " " +ALLTRIM(pc_DepoFile.Add2) + ", "
		DO CASE

		CASE BETWEEN( ilenth, 1, 55)

			lcDepAdd = ALLTRIM(lcDepAdd) + ALLTRIM( lcCity) + ;
				", " + ALLTRIM(pc_DepoFile.state) + ;
				"  " + ALLTRIM(pc_DepoFile.zip)

		CASE BETWEEN( ilenth, 55, 75)

			lcDepAdd2 = ALLTRIM( lcCity) + ;
				", " + ALLTRIM(pc_DepoFile.state)+ ;
				"  " + ALLTRIM(pc_DepoFile.zip)

		OTHERWISE
			lcComma =  ", "
			lcDepAdd = ALLTRIM( c_dep) + ", " +ALLTRIM(pc_DepoFile.Add1)
			lcDepAdd2 = ALLTRIM(pc_DepoFile.Add2) ;
				+ ALLTRIM( pc_DepoFile.city)+ ;
				", " + ALLTRIM(pc_DepoFile.state)+ ;
				"  " + ALLTRIM(pc_DepoFile.zip)

		ENDCASE
		_SCREEN.MOUSEPOINTER=0

		DO PrintField WITH mv, "comma", lcComma
		DO PrintField WITH mv, "Name", ALLTRIM(lcDepAdd)
		DO PrintField WITH mv, "State", ALLTRIM(lcDepAdd2)
	ENDIF  && pl_civble
	**** Print a case caption vs. plaintiff's name for Oakland/Pasadena offices.

	c_plname=pc_plnam
	**12/06/2006 - print plaintiff cap for plaintiffs with dod-start
	IF !EMPTY(convrtDate(pd_pldod)) AND pl_ofcOak
		pc_plnam=pc_plcaptn
	ENDIF
	**12/06/2006 - print plaintiff cap for plaintiffs with dod-end

	DO PrintField WITH mv, "NotcName", ;
		IIF( pl_OfcPas, ALLT( pc_plcaptn), pc_plnam)


	c_defend=""
	pc_plnam=c_plname
	IF pl_PSGWC
		SELECT 0
		l_GotDefName=oMedNtc.sqlexecute("SELECT dbo.fn_GetDef_Name('" + fixquote(pc_rqatcod) + "')", "DefName")
		IF NOT l_GotDefName
			gfmessage(" Cannot get a defendant. Contact IT.")

		ELSE
			c_defend=ALLTRIM(DefName.EXP)
		ENDIF
	ENDIF
	DO PrintGroup WITH mv, "Case"
	DO PrintField WITH mv, "Def_name", IIF( pl_PSGWC, ", " + c_defend, "")

	DO PrtCases WITH pc_rqatcod  
	
	DO PrintGroup WITH mv, "Atty"
	DO PrintAty WITH pc_rqatcod 
	DO PrtCourt WITH  IIF(pl_CivBle, .T.,.F.)

	&& -- 10/08/2019 MD
	LOCAL ldefendantName
	ldefendantName=""		
	oMedNtc.closealias("viewDefName")
	SELECT 0
	oMedNtc.sqlexecute("exec dbo.AttyDefName '" + fixquote(pc_clcode)+ "', '"+Iif( pl_plisrq, "P", "D")+"'", "viewDefName")
	IF USED("viewDefName")
		 ldefendantName=ALLTRIM(viewDefName.defendantName)		 	
	ENDIF
	DO PrintField WITH mv, "DefendantName",ldefendantName
	*----------------------------
	SELECT  viewNoticeAttyList
ENDSCAN 

RELEASE oMedNtc
SELECT (dbInit)
WAIT CLEAR
RETURN
*-------------------------------------------------------------------------
PROCEDURE CAConPOS
** Proof of Notice to Consumer
* Called by CANotice, CACivilN, Subp_PA, HIPAASet
* 07/19/04 DMA Use case-level globals; eliminate TAMaster references
* 05/14/03 DMA Eliminate unneeded variable szPers
PARAMETERS ldControl, llHS, ldDepoDate
PRIVATE dbInit, dbTAAtty, c_Atty
*-- 02/10/2021 MD #224406 added check for WCAB
IF LEFT(ALLTRIM(UPPER(pc_court1)), 4) = "WCAB" and pl_ofcoaK 
	RETURN
ENDIF 
*-- 02/10/2021 MD #224406 --------------------
dbInit = SELECT()
*-- 11/23/2020 MD #186387  
PRIVATE oMedNtc AS OBJECT
oMedNtc= CREATEOBJECT("generic.medgeneric")
LOCAL noticeAtty , noticeTag, noticeEmail
IF !USED("CANotice")	
	IF !USED("RECORD")
		NoticeTag=1
	ELSE
 		SELECT RECORD
		noticeTag=RECORD.tag
	ENDIF 
ELSE
	noticeTag=CANotice.tag
ENDIF 	
IF TYPE("noticeTag")<>"N"
	noticeTag=VAL(noticeTag)
ENDIF 	 
oMedNtc.closealias("viewNoticeAttyList")
c_sql="exec  dbo.CANoticeConsumerList '"+ALLTRIM(UPPER(pc_clcode))+"',"+ALLTRIM(str(noticeTag))+",2"
oMedNtc.sqlexecute(c_sql,"viewNoticeAttyList")
SELECT viewNoticeAttyList
SCAN 		
	noticeAtty=NVL(viewNoticeAttyList.at_code,"")	
	IF EMPTY(ALLTRIM(noticeAtty))
	   LOOP
	ENDIF 
	noticeEmail=NVL(viewNoticeAttyList.email,"")	

	WAIT WINDOW "Printing Proof of Notice to Consumer. - "+ALLTRIM(UPPER(noticeAtty)) NOWAIT NOCLEAR
	c_Atty=""	

	WAIT WINDOW "Gathering attorney's data.. Please wait." NOWAIT NOCLEAR
	_SCREEN.MOUSEPOINTER=11
	c_Atty=fixquote(noticeAtty)
	pl_GetAt = .F.
	DO gfatinfo WITH c_Atty, "M"


	_SCREEN.MOUSEPOINTER=0
	IF pl_CivBle
		DO PrintGroup WITH mv, "ConsProof" + IIF( llHS, "HS", "")
	ELSE
		*-- 11/23/2020 MD #186387  
		* --DO PrintGroup WITH mv, "CAConsProof" + IIF( llHS, "HS", "")				
		DO PrintGroup WITH mv,IIF(ALLTRIM(UPPER(NVL(viewNoticeAttyList.deliverytype,"M")))="P","CAConsProofHS",;
		IIF(ALLTRIM(UPPER(NVL(viewNoticeAttyList.deliverytype,"M")))="E","CAConsProofEM","CAConsProof"))
	ENDIF

	**EF : add two new boxes to the proof page 5/21/2007
	*-- IF llHS &&&-- 11/23/2020 MD #186387 
	IF ALLTRIM(UPPER(NVL(viewNoticeAttyList.deliverytype,"M")))="P"
		IF pl_BBCase
			DO PrintField WITH mv, "Agent", "AUTHORIZED AGENT"
			DO PrintField WITH mv, "BottomLine", "ORIGINAL PROOF OF SERVICE ON FILE AT RECORDTRAK"
		ELSE
			DO PrintField WITH mv, "Agent", ""
			DO PrintField WITH mv, "BottomLine",""
		ENDIF
	ENDIF
	*-- 11/25/2020 MD #186387  
	LOCAL ldefendantName
	ldefendantName=""		
	oMedNtc.closealias("viewDefName")
	SELECT 0
	oMedNtc.sqlexecute("exec dbo.AttyDefName '" + fixquote(pc_clcode)+ "', '"+Iif( pl_plisrq, "P", "D")+"'", "viewDefName")
	IF USED("viewDefName")
		 ldefendantName=ALLTRIM(viewDefName.defendantName)		 	
	ENDIF
	DO PrintField WITH mv, "DefendantName",ldefendantName
	*-- 11/23/2020 MD #186387  
	 *--  12/08/2020 MD #186387  added attyEmail 
    DO PrintField WITH mv, "AttyEmail",noticeEmail
	*----------------------------
         
	**EF : add two new boxes to the proof page 5/21/2007
	DO PrintField WITH mv, "RequestDate", DTOC( ldControl)
	DO PrintField WITH mv, "Loc", ;
		IIF( pc_litcode == "C  " AND pl_OfcKoP, "R", pc_offcode)
	DO PrintField WITH mv, "DepDate", DTOC( ldDepoDate)
	DO PrintField WITH mv, "RT", pc_lrsno

	**8/10/09 added getcaSigner/GetCADeliv
	IF EMPTY( pc_MailNam)
		pc_MailNam=getcaSigner(ldControl,pc_offcode)
	ENDIF
	IF EMPTY( pc_ServNam)
		pc_ServNam=GetCADeliv(pc_offcode,ldControl,pc_clcode)
	ENDIF
	**8/10/09


	*-- DO PrintField WITH mv, "ServName",IIF( llHS, ALLTRIM( pc_ServNam), ALLT( pc_MailNam)) &&&-- 11/23/2020 MD #186387 
	DO PrintField WITH mv, "ServName",IIF(ALLTRIM(UPPER(NVL(viewNoticeAttyList.deliverytype,"M")))="P", ALLTRIM( pc_ServNam), ALLT( pc_MailNam))
		
	DO PrintGroup WITH mv, "Case"
	DO PrintField WITH mv, "Defcap", IIF( pl_PSGWC, "", ALLTRIM( pc_dfcaptn))
	DO PrintField WITH mv, "Plcap", IIF( pl_PSGWC, "IN RE: ", "" ) + ;
		ALLTRIM( pc_plcaptn)
	DO PrintField WITH mv, "Docket", ALLTRIM( pc_docket)

	DO PrintGroup WITH mv, "Atty"
	*DO PrintAty WITH pc_platcod
	* --DO PrintAtyMix WITH pc_platcod , pl_CivBle &&&-- 11/23/2020 MD #186387 
	DO PrintAtyMix WITH noticeAtty , pl_CivBle
	**07/25/17: #66153

	IF pl_CivBle
		DO PrintField WITH mv, "AttyExtra" ,   PROPER(IIF( pl_plisrq,  pc_dfcaptn,pc_plcaptn))
		DO PrintField WITH mv, "AttyNotName" ,  IIF(EMPTY(pc_AtySIGN), pc_AtyName, pc_AtySIGN)
	ENDIF
	SELECT  viewNoticeAttyList
ENDSCAN 
SELECT (dbInit)
WAIT CLEAR
RETURN

*NOTE: Use new USDC form (share with KOP office) as march 2012
*-------------------------------------------------------------------------------

PROCEDURE CAUSPoS
* Generates Proof of Service for US District courts
* Called by CANotice, Subp_PA
* 07/19/04 DMA Use case-level globals; eliminate TAMaster references
* 07/07/04 DMA Fix call to PrtCases for service-list situation
PARAMETERS lddate

PRIVATE dnInit, lcAtty, llList, l_Defends, c_Atty, lcEmailAdd
dbInit = SELECT()
lcAtty = ""
WAIT WINDOW "Printing USDC Notice Proof." NOWAIT NOCLEAR

l_Defends = (gfDefCnt( .F.) > 0)
IF l_Defends
	lcAtty = "SEE ATTACHED SERVICE LIST"
	llList = .T.
ELSE

	c_Atty=fixquote(pc_platcod)
	_SCREEN.MOUSEPOINTER=11
	pl_GetAt = .F.
	DO gfatinfo WITH c_Atty, "M"

	lcAtty = ALLTRIM(pc_AtyFirm) + CHR(13) +;
		IIF( NOT EMPTY(pc_AtyName), "ATTN: " + ALLTRIM( pc_AtyName) + CHR(13), "") + ;
		IIF( NOT EMPTY(pc_Aty1Ad), ALLTRIM( pc_Aty1Ad) + CHR(13), "") + ;
		IIF (NOT EMPTY(pc_Aty2Ad), ALLTRIM( pc_Aty2Ad) + CHR(13), "") + pc_Atycsz

&& 2/1/2024, ZD #347226, JH
	IF NOT EMPTY(pc_AtyFax)
       lcAtty = lcAtty+chr(13)+"FAX: "+pc_AtyFax
    ENDIF

    lcEmailAdd= TxRqemail(0,c_Atty)
	IF NOT EMPTY(lcEmailAdd)
       lcAtty = lcAtty+chr(13)+"E-MAIL: "+lcEmailAdd
    ENDIF
&& 2/1

	llList = .F.
ENDIF

**1/27/2011 - added CA_USDCMail/issuedate

*DO PrintGroup WITH mv, "CA_USDCMail"		&& 2/1/2024, ZD #347226, JH
DO PrintGroup WITH mv, "CA_USDCMail2"

DO PrintField WITH mv, "Service", lcAtty


IF EMPTY( pc_MailNam)
	lddate2=lddate
	pc_MailNam=getcaSigner(lddate2,pc_offcode)
ENDIF


*DO PrintField WITH mv, "ServName", pc_MailNam	&& 2/1/2024, ZD #347226, JH

DO PrintField WITH mv, "IssueDate",  lddate
DO PrintGroup WITH mv, "Case"
DO PrintField WITH mv, "District", ALLTRIM( pc_distrct)
DO PrtCases WITH IIF( l_Defends, pc_platcod, " ")

DO PrintGroup WITH mv, "Control"
DO PrintField WITH mv, "Date",  lddate

_SCREEN.MOUSEPOINTER=0
IF llList
	DO CAUSList
ENDIF

SELECT (dbInit)
WAIT CLEAR
RETURN
*-------------------------------------------------------------------------------

PROCEDURE CAUSList
* 07/19/04 DMA Use case-level globals; eliminate TAMaster references
* Called from CANotice, Subp_Ca
PARAMETERS lcCl_Code
PRIVATE dnInit, dbTABills, dbTAAtty, lcAt_Code, arAtty, ;
	nCount, nLoop, n_Round, n_Mod, l_Extra
dbInit = SELECT()

WAIT WINDOW "Printing USDC Service List." NOWAIT NOCLEAR

DO PrintGroup WITH mv, "CAUSDCSrv"

SELECT 0
_SCREEN.MOUSEPOINTER=11
l_Tabill=gettabill(pc_clcode)
_SCREEN.MOUSEPOINTER=0
IF NOT l_Tabill
	gfmessage("Cannot get TAbills file.")
	RETURN
ENDIF

SELECT tabills
nCount = 0
SELECT CODE, At_Code FROM tabills INTO ARRAY arAtty ;
	WHERE tabills.cl_Code = pc_clcode ;
	AND INLIST( tabills.Response, "T", "S") ;
	AND NOT tabills.NoNotice ;
	AND tabills.At_Code <> pc_rqatcod ;
	ORDER BY tabills.CODE
SELECT tabills
USE

nCount = ALEN( arAtty) / 2
n_Round = ROUND( nCount/2, 0)
n_Mod = MOD( nCount, 2)
FOR nLoop = 1 TO n_Round
	DO PrintGroup WITH mv, "Item"
	lcString1 = " "
	lcString2 = " "
	lcAt_Code = arAtty[ nLoop*2-1, 2]

	lcString1=getstring1(lcAt_Code)


	IF (nLoop < n_Round) OR n_Mod = 0
		lcAt_Code = arAtty[nLoop*2,2]

		lcString2=getstring2(lcAt_Code)

	ENDIF
	DO PrintField WITH mv, "Col1", lcString1
	DO PrintField WITH mv, "Col2", lcString2
ENDFOR


SELECT (dbInit)
WAIT CLEAR
RETURN
***********************************************************************************
***3/1/06 get string functions
FUNCTION getstring1
PARAMETERS lcAt_Code
PRIVATE c_Atty AS STRING, lcString  AS STRING, lcEMAdd as string
lcString=""
_SCREEN.MOUSEPOINTER=11
c_Atty=fixquote(lcAt_Code)
pl_GetAt = .F.
DO gfatinfo WITH c_Atty, "M"


lcString = ALLTRIM(pc_AtyFirm) + CHR(13) + ;
	IIF( NOT EMPTY( pc_AtySIGN), "ATTN: " + pc_AtySIGN + CHR(13), "") +  ;
	IIF( NOT EMPTY( pc_Aty1Ad), ALLTRIM( pc_Aty1Ad) + CHR(13), "") + ;
	IIF( NOT EMPTY( pc_Aty2Ad), ALLTRIM( pc_Aty2Ad) + CHR(13), "") + ;
	pc_Atycsz  + CHR(13)

&& 2/1/2024, ZD #347226, JH
	IF NOT EMPTY(pc_AtyFax)
       lcString = lcString+"FAX: "+pc_AtyFax+CHR(13)
    ENDIF

    lcEMAdd= TxRqemail(0,c_Atty)
	IF NOT EMPTY(lcEMAdd)
       lcString = lcString+"E-MAIL: "+lcEMAdd+CHR(13)
    ENDIF
&& 2/1


_SCREEN.MOUSEPOINTER=0
RETURN     lcString
************************************************************************************
FUNCTION getstring2
PARAMETERS lcAt_Code

PRIVATE c_Atty AS STRING, lcString2  AS STRING, lcEMAdd as string
lcString=""
_SCREEN.MOUSEPOINTER=11
c_Atty=fixquote(lcAt_Code)
pl_GetAt = .F.
DO gfatinfo WITH c_Atty, "M"
lcString = ALLTRIM(pc_AtyFirm) + CHR(13) + ;
	IIF(NOT EMPTY(pc_AtySIGN), "ATTN: " + pc_AtySIGN  + CHR(13),"")  +;
	IIF(NOT EMPTY(pc_Aty1Ad), ALLTRIM(pc_Aty1Ad) + CHR(13), "") + ;
	IIF(NOT EMPTY(pc_Aty2Ad), ALLTRIM(pc_Aty2Ad) + CHR(13), "") + ;
	pc_Atycsz  + CHR(13)

&& 2/1/2024, ZD #347226, JH
	IF NOT EMPTY(pc_AtyFax)
       lcString = lcString+"FAX: "+pc_AtyFax+CHR(13)
    ENDIF

    lcEMAdd= TxRqemail(0,c_Atty)
	IF NOT EMPTY(lcEMAdd)
       lcString = lcString+"E-MAIL: "+lcEMAdd+CHR(13)
    ENDIF
&& 2/1

_SCREEN.MOUSEPOINTER=0
RETURN lcString

********************************************************************************************
**---------------------------------------------------------
**EF 9/18/00
**--------------------------------------------------------
PROCEDURE SubWCAB
** Called from CANotice, Subp_PA to generate WCAB Subpoenas
** pl_CANotc will be .T. on entry if performing end-of-day CA noticing
* 07/19/04 DMA Use case-level global variables; eliminate TAMaster use
* 04/29/04 DMA Change lCANot to pl_CANotc

* Uses RPS Document SUBWcab

PARAMETERS n_pageno, szEdtReq, ldDepo, lnTag, ldControl
* n_pageno: page number of subpoena (1 or 2)
* szEdtReq: Request blurb
* ldDepo: Deposition date
* lnTag: Tag # of deponent
* ldControl: Issue date

IF n_pageno = "1"
	* DO PrintGroup WITH mv, "SubWCAB" --09/11/2023 MD
	DO PrintGroup WITH mv, "SubWCABNew"
ELSE
	DO PrintGroup WITH mv, "SubWCABP2"
ENDIF 	
DO PrintField WITH mv, "RequestDate", DTOC( ldControl)
DO PrintField WITH mv, "Loc", pc_offcode
DO PrintField WITH mv, "InfoText", ;
	STRTRAN(STRTRAN( szEdtReq, CHR(13), " "), CHR(10), "")
* 05/25/04 DMA Switch to long plaintiff name
 * 09/11/2023 MD 	removed DOB dob SS#
*DO PrintField WITH mv, "PertainsTo", ;  
*	ALLTRIM( pc_plnam) + " DOB: " +  pd_pldob ;
*	+ " SSN: " + ALLTRIM( pc_plssn)
DO PrintField WITH mv, "PertainsTo", ALLTRIM( pc_plnam) 

*-- 02/10/2021 MD #224406		
DO PrintField WITH mv, "CourtCounty", ALLTRIM( UPPER( pc_c1Cnty))
DO PrintField WITH mv,"RequestDate", DTOC( ldControl)
DO PrintField WITH mv,"RequestDate", DTOC( ldControl)  &&09/11/2023 MD
	
*-- 03/17/2021 MD  #224406	Added different second page	
*!*	ELSE
*!*		DO PrintGroup WITH mv, "WCABPage2"
*!*		DO PrintField WITH mv, "DepoDate1", DTOC( ldControl)
*!*	ENDIF
*-- 03/17/2021 MD  #224406
		
*-- 02/10/2021 MD #224406		
*DO PrintField WITH mv, "DepoDate", DTOC( ldDepo)
DO PrintField WITH mv, "Depodatedaymonth", day( ldDepo)
DO PrintField WITH mv, "depodatemonth", cMonth( ldDepo)
DO PrintField WITH mv, "depodateyear", Year( ldDepo)
DO PrintField WITH mv, "RTTag", ALLTRIM(STR(pn_lrsno))+"."+ALLTRIM(STR(lnTag))
DO PrintGroup WITH mv, "Atty"
DO PrintAty WITH pc_rqatcod
*-- 02/10/2021 MD #224406	
*-- 03/17/2021 MD  #224406	Added different second page	
*!*	IF n_pageno = "2"

*!*		DO PrintField WITH mv, "CaseDist", ALLTRIM( pc_distrct)

*!*		SELECT DECL
*!*		dbDecl = ALIAS()
*!*		DO PrintField WITH mv, "Text", ALLTRIM( DECL.Text2)

*!*	ENDIF


*!*	IF n_pageno = "2"
*!*		DO PrintGroup WITH mv, "Atty"
*!*		DO PrintAty WITH pc_rqatcod
*!*		DO PrintField WITH mv, "CourtName", ALLTRIM(PC_aTYcity)

*!*	ENDIF
*-- 03/17/2021 MD  #224406	Added different second page	
DO PrintGroup WITH mv, "Case"
DO PrintField WITH mv, "Case", " "
DO PrtCases WITH pc_rqatcod

*-- 01/12/2021 MD #224406 added Record and wcabDescript
LOCAL wcabDescript
wcabDescript=""
*-- 12/20/2021 MD removed
*!*	IF NOT USED('Timesheet')
*!*	    IF !USED("Record")
*!*			gfmessage("Can't access timesheet")
*!*			RETURN
*!*		ELSE
*!*			 wcabDescript=Record.DESCRIPT
*!*		ENDIF 
*!*	ELSE 
*!*	  wcabDescript=timesheet.DESCRIPT
*!*	ENDIF
*!*	SELECT timesheet

*!*	mid = MailID_No
*-- 12/20/2021 MD removed

*-- 12/20/2021 MD #259076 Added following code 
PRIVATE oMedWCAB AS OBJECT
LOCAL lcSQLLine
oMedWCAB= CREATEOBJECT("generic.medgeneric")
oMedWCAB.closealias("viewDepDescript")
	SELECT 0
	lcSQLLine="exec dbo.TagDescription " + ALLTRIM(STR(pn_lrsno))+","+ALLTRIM(STR(lnTag))
	oMedWCAB.sqlexecute(lcSQLLine, "viewDepDescript")
	IF USED("viewDepDescript")
		 wcabDescript=NVL(ALLTRIM(viewDepDescript.descript),"")		
		 mid=NVL(ALLTRIM(viewDepDescript.mailid_no),"")				
	ENDIF
	oMedWCAB.closealias("viewDepDescript")
*-- 12/20/2021 MD #259076 

IF  LEFT( ALLT(mid),1)="D"
	c_drname=gfdrformat(wcabDescript)
	c_dep = IIF(NOT "DR."$c_drname,"DR. "+ALLTRIM(c_drname),c_drname)
ELSE
	c_dep = ALLTRIM(wcabDescript)
ENDIF
*-- 01/12/2021 MD #224406


* Close timesheet file if performing end-of-day noticing for CA offices
IF pl_CANotc
	IF USED('Timesheet') && 12/21/2021 MD #259076
		SELECT timesheet  && 12/21/2021 MD #259076
		USE
	ENDIF 
ENDIF
DO PrintDep WITH mid, c_dep

DO PrintGroup WITH mv, "Control"
DO PrintField WITH mv, "LrsNo", pc_lrsno
DO PrintField WITH mv, "Tag", STR( lnTag)


RETURN
*************************************************************************************
PROCEDURE PrtCases
PARAMETER c_AtCode
* Prints case-caption data
DO PrintField WITH mv, "Defcap", ALLTRIM( pc_dfcaptn)
DO PrintField WITH mv, "Plcap", IIF( pl_PSGWC, "IN RE: " , "") + ;
	ALLTRIM( pc_plcaptn)
DO PrintField WITH mv, "Docket", ALLTRIM( pc_docket)
IF pl_CivBle
**D(R)- Respondent/ P(E)-  Petitioner
	DO PrintField WITH mv, "AttyType", 	 IIF( pl_plisrq, "E", "R")
ELSE
	DO PrintField WITH mv, "AttyType", ;
		IIF( c_AtCode == "BEBE  3C" AND NOT pl_NonGBB, "C", IIF( pl_plisrq, "P", "D"))
ENDIF



RETURN
***************************************************************************************
PROCEDURE PrintDep
* 05/22/03 DMA Eliminate use of gflkup to cut down on file access
*              Move PrintGroup statement into subroutine
* Called internal to Subp_Ca, and also by external routine ReAttch
PARAMETERS c_mid, c_dep
* c_mid: Mail ID of deponent
* c_dep: Name of deponent
PRIVATE szPhone, c_roloname, l_RoloUsed, c_RoloType
DO PrintGroup WITH mv, "Deponent"
DO PrintField WITH mv, "Name", c_dep
IF NOT USED("pc_DepoFile") && 01/26/2011 MAKE SURE TEH FILE IS OPEN

	WAIT WINDOW "Getting Deponent's information." NOWAIT NOCLEAR
	_SCREEN.MOUSEPOINTER=11
	c_deptype="Z"
	c_deptype=deptbydesc(c_dep)
	l_mail=oMed.sqlexecute("exec dbo.GetDepInfoByMailIdDept '" + c_mid+"','" + c_deptype + "' ", "pc_DepoFile")
	=CURSORSETPROP("KeyFieldList", "Code, id_tbldeponents", "pc_DepoFile")
ENDIF

SELECT pc_DepoFile

DO PrintField WITH mv, "Addr", ALLTRIM( ALLTRIM( Add1) + " " + ALLTRIM( Add2))
DO PrintField WITH mv, "City", ALLTRIM(city)
DO PrintField WITH mv, "State", ALLTRIM(state)
DO PrintField WITH mv, "Zip", ALLTRIM(zip)
DO PrintField WITH mv, "Extra", TRANSFORM( Phone, pc_fmtphon)

RETURN
*******************************************************************************************
PROCEDURE PrtCourt
* 05/13/04 DMA Use global variables for all work in this routine
* 06/11/03 DMA Revised to include file open/close activity
*   and eliminate unneeded parameters
*   New parameter tells routine if County name should be printed
PARAMETER l_County

DO PrintGroup WITH mv, "Court"
* 05/13/04 DMA Use global variables for all work in this routine
IF l_County
	DO PrintField WITH mv, "County", ALLTRIM( UPPER( pc_c1Cnty))
ENDIF
* -- 03/01/2019 MD #125666 
*DO PrintField WITH mv, "Name", ALLTRIM( pc_c1Desc)
DO PrintField WITH mv, "Name", ALLTRIM(  pc_c1Cnty)
*---
DO PrintField WITH mv, "Add1", ALLTRIM( pc_c1Addr1)
IF EMPTY( pc_c1Addr2)
	DO PrintField WITH mv, "Add2", ;
		IIF( NOT EMPTY( pc_c1Addr3), ALLTRIM( pc_c1Addr3), "")
ELSE
	DO PrintField WITH mv, "Add2", ALLTRIM( pc_c1Addr2) + ;
		IIF( NOT EMPTY( pc_c1Addr3), ;
		CHR(13) + ALLTRIM( pc_c1Addr3),"")
ENDIF
DO PrintField WITH mv, "CSZ", ALLTRIM( UPPER( pc_c1City)) + ;
	", " + pc_c1state + "  " + ALLTRIM( pc_c1zip)

DO PrintField WITH mv, "Branch", ;
	IIF( pc_Court1 = "SFSC", "UNLIMITED JURISDICTION", ;
	IIF( ALLTRIM( pc_Court1) == "LACSC-CCW", "CENTRAL CIVIL WEST", "" ))
RETURN

*---------------------------------------------------------------------------
*07/29/03 print atty's data
*---------------------------------------------------------------------------
PROCEDURE PrintAty
PARAMETERS lc_atty
LOCAL oatty AS OBJECT, d_issdate AS DATE
oatty= CREATEOBJECT("generic.medgeneric")
_SCREEN.MOUSEPOINTER=11
c_Atty=fixquote(lc_atty)
pl_GetAt = .F.
DO gfatinfo WITH c_Atty, "M"

*-- 08/06/2020 MD remove upper case
*DO PrintField WITH mv, "Name_inv", IIF(EMPTY(pc_AtySIGN),UPPER( pc_AtyName),UPPER( pc_AtySIGN))
DO PrintField WITH mv, "Name_inv", IIF(EMPTY(pc_AtySIGN),alltrim( pc_AtyName),alltrim( pc_AtySIGN))

DO PrintField WITH mv, "Ata1", pc_AtyFirm
DO PrintField WITH mv, "Ata2", pc_Aty1Ad
DO PrintField WITH mv, "Ata3", pc_Aty2Ad
DO PrintField WITH mv, "Atacsz", pc_Atycsz
DO PrintField WITH mv, "Phone", pc_AtyPhn
DO PrintField WITH mv, "FaxNo", pc_AtyFax
_SCREEN.MOUSEPOINTER=0
RELEASE oatty
RETURN
**************************************************************************
*---------------------------------------------------------------------------
*07/25/2017 print atty's data in mixed case letters
*---------------------------------------------------------------------------
PROCEDURE PrintAtyMix
PARAMETERS lc_atty, l_mix
LOCAL oatty AS OBJECT, d_issdate AS DATE
oatty= CREATEOBJECT("generic.medgeneric")
_SCREEN.MOUSEPOINTER=11
c_Atty=fixquote(lc_atty)
pl_GetAt = .F.
IF l_mix
	DO AtyMixed WITH  c_Atty, "M", .T.
ELSE
	DO gfatinfo WITH c_Atty, "M"
ENDIF

*-- 08/06/2020 MD remove upper case
*DO PrintField WITH mv, "Name_inv", IIF(EMPTY(pc_AtySIGN),UPPER( pc_AtyName),UPPER( pc_AtySIGN))
DO PrintField WITH mv, "Name_inv", IIF(EMPTY(pc_AtySIGN),alltrim( pc_AtyName),alltrim( pc_AtySIGN))

DO PrintField WITH mv, "Ata1", pc_AtyFirm
DO PrintField WITH mv, "Ata2", pc_Aty1Ad
DO PrintField WITH mv, "Ata3", pc_Aty2Ad
DO PrintField WITH mv, "Atacsz", pc_Atycsz
DO PrintField WITH mv, "Phone", pc_AtyPhn
DO PrintField WITH mv, "FaxNo", pc_AtyFax
_SCREEN.MOUSEPOINTER=0
RELEASE oatty
RETURN
**************************************************************************


FUNCTION FmtAtty
* 05/22/03 DMA Added to eliminate replicated code
* Assumes that TAAtty (possibly aliased) is open and positioned
* Returns a string containing the current attorney's name and address
* in a multi-line format.
PRIVATE c_fmtatty
c_fmtatty = ALLTRIM( Firm) + CHR(13) + ;
	IIF( NOT EMPTY( NewLast), "ATTN: " + ;
	ALLTRIM( NewFirst) + " " + ;
	IIF( NOT EMPTY( NewInit), NewInit + ". ", "") + ;
	ALLTRIM( NewLast) + ;
	IIF( NOT EMPTY( TITLE), ", " + TITLE, "") + CHR(13), "") + ;
	IIF( NOT EMPTY( NewAdd1), ALLTRIM( NewAdd1) + CHR(13), "") + ;
	IIF( NOT EMPTY( NewAdd2), ALLTRIM( NewAdd2) + CHR(13), "") + ;
	IIF( NOT EMPTY( NewCity), ALLTRIM( NewCity) + ", ", "") + ;
	ALLTRIM( NewState) + " " + ALLTRIM( NewZip) + CHR(13)
RETURN c_fmtatty
**************************************************************************************
FUNCTION GetSpecInsForTag
PARAMETERS n_tag
WAIT WINDOW "Getting special instruction blurb.. Please wait" NOWAIT NOCLEAR
_SCREEN.MOUSEPOINTER=11
c_alias = ALIAS()
oMedTMP = CREATEOBJECT("generic.medgeneric")
c_EdtReq = ""
l_GetSpIns=oMedTMP.sqlexecute( " exec [dbo].[GetSpecInsByClCodeTag] '" + fixquote(pc_clcode) + "','" + STR(n_tag) + "'", "Spec_ins")
IF NOT l_GetSpIns
	gfmessage("Cannot get Special Instruction Table. Contact IT dept.")
	RETURN
ENDIF
crequest = ALLTRIM(spec_ins.spec_inst)
c_EdtReq = gfAddCR( crequest)
RELEASE oMedTMP
RETURN c_EdtReq


*****************************************************************************************
PROCEDURE WCABProof
PARAMETERS nTag, llHS, llNotice, llDefOnly, ldControl
* nTag: Tag number of deponent being noticed
* llHS: .T. for hand-serve; .F. for US Mail
* llNotice: .T. if "LOCATION: <deponent>" field is to be printed
* llDefOnly: .T. if notices go only to defense attorneys
* ldControl: Date to be printed on notice
PRIVATE dbInit, dbTAAtty, mPhone, dbTABills, nCount, nLoop, ;
	lcAt_Code, arAtty, lcString1, lcString2, lnDefCnt, llRepeat
PRIVATE c_detail1, c_detail2, c_detail3, c_NotcType, c_defend, c_Atty, lnCurArea,lc_AttyNoticeEmail,lc_AttyNoticeFax
PRIVATE oMedPOS AS OBJECT
c_Atty=""
dbInit = SELECT()
oMedPOS= CREATEOBJECT("generic.medgeneric")
WAIT WINDOW "Printing Proof of Service of Notice" NOWAIT NOCLEAR
_SCREEN.MOUSEPOINTER=11
IF NOT TYPE( "ldControl") = "D"
	*gfmessage("Problem...")
	ldControl=convertToDate(ldControl)
ENDIF
llRepeat = .F.
IF NOT llDefOnly
	IF llHS
** If llHS was .T., then determine if a recursive call will
** be needed after this document is generated.
** Note that llHS will be .F. if this already is a recursive call.
** This prevents going beyond one level of recursion.
		llRepeat = ( gfDefCnt( .F.) > 0)
	ENDIF
ENDIF

*-- 02/10/2021 MD #224406 added check for WCAB
IF LEFT(ALLTRIM(UPPER(pc_court1)), 4) = "WCAB" and pl_ofcoaK 
*-- to make sure we are in the right place
ELSE 
	RETURN
ENDIF 

omedPos.closealias("viewNoticeAttyList")
c_sql="exec  dbo.CANoticeConsumerList '"+ALLTRIM(UPPER(pc_clcode))+"',"+ALLTRIM(str(nTag))+",2"
omedPos.sqlexecute(c_sql,"viewNoticeAttyList")
SELECT viewNoticeAttyList
DO PrintGroup WITH mv,IIF(ALLTRIM(UPPER(NVL(viewNoticeAttyList.deliverytype,"M")))="P","WCABProofHS","WCABProof")
*--DO PrintGroup WITH mv,"WCABProofHS" for test thesecond form
DO PrintGroup WITH mv, "Case"
DO PrtCases WITH pc_rqatcod
DO PrintField WITH mv, "RequestDate", DTOC( ldControl)
DO PrintField WITH mv, "SignDate", DTOC( ldControl)
l_Tabill=gettabill(pc_clcode)
IF NOT l_Tabill
	gfmessage("Cannot get TAbills file")
	RETURN
ENDIF

SELECT tabills

nCount = 0
IF llDefOnly
* Build array of participating defense attorneys
	SELECT CODE, At_Code FROM tabills  INTO ARRAY arAtty ;
		WHERE tabills.cl_Code = pc_clcode ;
		AND tabills.At_Code <> pc_rqatcod ;
		AND tabills.CODE = "D" ;
		AND INLIST( tabills.Response, "T", "S") ;
		AND NOT tabills.NoNotice
ELSE
* Build array of all participating attorneys
* (only plaintiff att'ys if this is a recursive call [llRepeat = .T.])
	SELECT CODE, At_Code FROM tabills  INTO ARRAY arAtty ;
		WHERE tabills.cl_Code = pc_clcode ;
		AND tabills.At_Code <> pc_rqatcod ;
		AND IIF( llRepeat, tabills.CODE = "P", .T.) ;
		AND INLIST( tabills.Response, "T", "S") ;
		AND NOT tabills.NoNotice
ENDIF

gnCount = _TALLY

_SCREEN.MOUSEPOINTER=0

DO PrintGroup WITH mv, "Control"
DO PrintGroup WITH mv, "Atty"
DO PrintAty WITH pc_rqatcod

IF gnCount =0
	= gfmsg( "No Participating Attys..  Make a note.")
ENDIF
IF gnCount > 0
	= ASORT( arAtty, 1, -1, 1)

	nCount = ALEN( arAtty) / 2
	FOR nLoop = 1 TO ROUND( nCount/2, 0)
		DO PrintGroup WITH mv, "Item"
		lcString1 = " "
		lcString2 = " "

		lcAt_Code = arAtty[ nLoop*2-1, 2]
		**---------------------------------------
		&& 12/09/2020 MD #186387
		lnCurArea=SELECT()
		lc_AttyNoticeEmail=""
		oMedPos.closealias("viewAttyNoticeEmail")
		oMedPos.sqlexecute("exec  [dbo].[getAttyNoticeEmail] '" + lcAt_Code+ "'", "viewAttyNoticeEmail")
		SELECT viewAttyNoticeEmail
		GO top		
		lc_AttyNoticeEmail=ALLTRIM(LOWER(NVL(viewAttyNoticeEmail.email,"")))	
		lc_AttyNoticeFax=ALLTRIM(LOWER(NVL(viewAttyNoticeEmail.fax,"")))	
		oMedPos.closealias("viewAttyNoticeEmail")	
		SELECT (lnCurArea)
		**---------------------------------------
		lcString1=getstring1(lcAt_Code)+;
		IIF(!EMPTY(ALLTRIM(lc_AttyNoticeEmail)),ALLTRIM(lc_AttyNoticeEmail)+CHR(13),"")+;
		IIF(!EMPTY(ALLTRIM(lc_AttyNoticeFax)),ALLTRIM(lc_AttyNoticeFax)+CHR(13),"")
		


*     Prepare column 2 data, if any
		IF (nLoop < ROUND( nCount/2, 0)) OR MOD( nCount, 2) = 0
			lcAt_Code = arAtty[ nLoop*2, 2]
			**---------------------------------------
			&& 12/09/2020 MD #186387
			lnCurArea=SELECT()
			lc_AttyNoticeEmail=""
			oMedPos.closealias("viewAttyNoticeEmail")
			oMedPos.sqlexecute("exec  [dbo].[getAttyNoticeEmail] '" + lcAt_Code+ "'", "viewAttyNoticeEmail")
			SELECT viewAttyNoticeEmail
			GO top		
			lc_AttyNoticeEmail=ALLTRIM(LOWER(NVL(viewAttyNoticeEmail.email,"")))	
			lc_AttyNoticeFax=ALLTRIM(LOWER(NVL(viewAttyNoticeEmail.fax,"")))		
			oMedPos.closealias("viewAttyNoticeEmail")	
			SELECT (lnCurArea)
		**---------------------------------------
			lcString2=getstring2(lcAt_Code)+;
			IIF(!EMPTY(ALLTRIM(lc_AttyNoticeEmail)),ALLTRIM(lc_AttyNoticeEmail)+CHR(13),"")+;
			IIF(!EMPTY(ALLTRIM(lc_AttyNoticeFax)),ALLTRIM(lc_AttyNoticeFax)+CHR(13),"")

		ENDIF

		DO PrintField WITH mv, "Col1", lcString1
		DO PrintField WITH mv, "Col2", lcString2
	ENDFOR

ENDIF
RELEASE oMedPOS
SELECT (dbInit)

WAIT CLEAR

RETURN
