PROCEDURE ReAttch
**04/14//2017- Re-sized a blurb when priting to the rps  # 60943 (width =97 instead of a 68 -default)
**06/01/2016- Added "R" -scanned rider  #40514
** 03/21/12  EF CA USDC use its own attachment form.
** 03/05/10  EF - Print canned blurb with the BB non generic
** 12/09/09  EF - added full plaintiff's SSN
** 10/01/09  EF - added new bb bill/med blurbs
** 09/15/06  EF -synch with the Foxpro: added B & B special text per Melissa
**3/2/06 EF -ADDED TO THE PROJECT
*****************************************************************************************
***  DMA 05/25/04 Use long plaintiff name
***  EF  07/29/03 Add spec handling for GWC lit cases and restored parameters
****              for printing attach with notices
***  DMA 06/17/03 Add exact location for call to PrintDep in Subp_CA
***               Use global variables for TAMaster fields instead of parms
***  DMA 05/27/03 Use gfAddCR to format memo field
***  EF  08/10/01 Attachment page prints with reprint affidavits option.
***  Called from Subp_pa, CANotice
***  Assumes that gfGetCas has been previously called
***  Assumes that calling program will call PrtEnqA at some point after return
***  Calls PrintDep (in Subp_CA), PrintGroup, PrintField
***  Uses RPS Document ReCAAttch
*************************************************************************************************
PARAMETERS ntag, mdep, mid
PRIVATE c_depname AS STRING, c_code250 AS STRING, c_canned AS STRING, dstartdate AS DATE, 	l_oldAttch AS Boolean, lc_dept AS STRING, C_RIDERPCX as String
STORE "" TO c_depname, c_code250, c_canned, lc_dept, C_RIDERPCX
SET MEMOWIDTH TO 68
dbInit = SELECT()
&&1/26/11 skip attachment page for usdc issues
&&03/20/12 - Use new USDC form (has its own attacment)
IF pl_Canotc AND LEFT( ALLTRIM(pc_court1), 4) = "USDC"
	RETURN
ENDIF
*-- 02/19/2021   MD #226818 To make the scanned docs are checked in the correct folder
IF RIGHT(ALLTRIM(UPPER(pc_clcode)),1)=="C"
	PL_OFCOAK=.T.
ENDIF 	
*--

WAIT WINDOW "Printing attachment page(s)." NOWAIT NOCLEAR
oMedTmp = CREATEOBJECT("generic.medgeneric")

&&-------------------------------------------------------------------------
*--- 01/14/2021 MD #218844 	
		oMedTmp.closealias('TagDesc')
		lcSQLLine="select dbo.GetdepName ('" +mid+ "')"
		oMedTmp.sqlexecute(lcSQLLine,"TagDesc")
		IF USED('TagDesc')
			mDep=UPPER(ALLTRIM(NVL(TagDesc.EXP,"")))		
		ENDIF
		oMedTmp.closealias('TagDesc')
&&-------------------------------------------------------------------------	
**06/06/2016- Added "R" -scanned rider  #40514
C_RIDERPCX=SUBRIDERPCX	(ntag,"R",1 )
IF !EMPTY(ALLTRIM(C_RIDERPCX))
		DO pspecdoc IN subp_pa WITH 'R'
ELSE


	lc_dept="Z"	
	SELECT Spec_Ins
	lc_dept =ALLTRIM(Spec_Ins.dept)
	IF EMPTY(Spec_Ins.Spec_Inst)

		l_GetSpIns=oMedTmp.sqlexecute( " exec [dbo].[GetSpecInsByClCodeTag] '" + fixquote(pc_clcode) + "','" + STR(ntag) + "'", "Spec_ins")
		IF NOT l_GetSpIns
			gfmessage("Cannot get Special Instruction Table. Contact IT dept.")
			RETURN
		ENDIF
		c_TimesheetID=''
		l_got11=oMedTmp.sqlexecute("SELECT id_tblTimesheet from tblTimesheet with (nolock)" + ;
			"  where  cl_code='" + fixquote(pc_clcode) + "' AND TAG='" + STR(ntag) + "' and txn_code=11 and deleted is null", "Exist11")
		IF NOT l_got11 OR EOF()
			gfmessage("Cannot get Entry Table. Contact IT dept.")
			RETURN
		ENDIF
		c_TimesheetID=NVL(EXIST11.id_tblTimesheet,'')
		SELECT Spec_Ins
		IF RECCOUNT()>0
			LOCATE FOR id_tblTimesheet =c_TimesheetID
			lc_dept =Spec_Ins.dept
		ENDIF
	ENDIF

	dstartdate=DATE()
	STORE .F. TO l_oldAttch

***03/05/2010 -added pl_NonGBB to the process
	IF INLIST(lc_dept , "B","M") AND pl_NonGBB
		lcSave=SELECT()
		IF !USED("StartDate")
			lcsql ="select dbo.NewBB_BlurbStartDate(" + STR(IIF(pl_NonGBB=.T.,1,0)) + ")"
			oMedTmp.sqlexecute(lcsql,"StartDate")
		ENDIF
		IF TYPE( "StartDate.exp") ="C"
			dstartdate =CTOD(StartDate.EXP)
		ELSE
			dstartdate=CTOD(LEFT(DTOC(StartDate.EXP),10))
		ENDIF
		IF NOT EMPTY(lcSave)
			SELECT (lcSave)
		ENDIF

		IF Spec_Ins.txn_date <dstartdate
			l_oldAttch =.T.
		ENDIF
	ENDIF
	*-- 03/09/2021 MD #224406 added WCAB
	IF LEFT( ALLTRIM(UPPER(pc_court1)), 4)=="WCAB"
	  	DO PrintGroup WITH mv, "WCABAttch"
	ELSE	
		DO PrintGroup WITH mv, "ReCAAttch"
	ENDIF 
**10/01/2009 new bill/med blurbs- start
*IF NOT l_oldAttch
	IF INLIST(ALLTRIM(Spec_Ins.dept), "B","M") AND ALLTRIM(Spec_Ins.TYPE) ="S" AND NOT l_oldAttch
		c_code250="As used  in this subpoena, DOCUMENTS means a writing, as defined in California  " ;
			+ "Evidence CodeSection 250, and includes the original or a copy without limitation of " ;
			+ "every kind of written, printed, typed, recorded, or graphic matter, however produced  " ;
			+ "or reproduced, including but not limited to notes, forms, claims, memoranda, briefs, " ;
			+ "summaries, charts, medical records, transcripts and correspondence concerning or relating " ;
			+ "to the individual referenced above."
	ELSE
		c_code250=""
	ENDIF


&&add pl_NonGBB 03/05/2010
	DO PrintField WITH mv, "BBEviCode", IIF( pl_BBAsb OR pl_NonGBB, c_code250, " ")

&& ---08/14/2019 MD moved this line here to fill fields in the same order as they presented on the word doc
* 05/28/03 DMA Use new utility routine
	DO PrintField WITH mv, "InfoText", ALLTRIM( gfAddCR( Spec_Ins.Spec_Inst,83))
&& ---
	
	IF INLIST(ALLTRIM(Spec_Ins.dept), "B","M") AND ALLTRIM(Spec_Ins.TYPE) ="S" AND NOT l_oldAttch
		c_canned= bbextra(Spec_Ins.dept,.F.)
	ELSE
		c_canned=""
	ENDIF
	DO PrintField WITH mv, "CannBlb", IIF( pl_BBAsb OR pl_NonGBB, c_canned, " ")
*ENDIF && l_oldAttch
**10/01/2009 new bill/med blurbs- end

&& ---08/14/2019 MD moved this line in front of CannedBlurb to fill fields in the same order as they presented on the word doc
*!*	* 05/28/03 DMA Use new utility routine
*!*		DO PrintField WITH mv, "InfoText", ALLTRIM( gfAddCR( Spec_Ins.Spec_Inst,83))
&& ---

**07/29/03 EF  Groundwater Contamination change
	DO PrintField WITH mv, "vs", IIF( pl_PSGWC, "", " vs. ")

*!*	***9/15/06 starts
*!*	&&02/17/16 removed B & B
*!*		c_extrabb="Motions relating to this subpoena are to be filed and served " ;
*!*			+ "electronically pursuant to Amended General Order 158. For a copy of Amended " ;
*!*			+ "General Order 158, please contact LexisNexis at <http://www.lexisnexis.com/fileandserve/> " ;
*!*			+ "or Spanos | Przetak at 510-250-0200 or at its website www.spanos-przetak.com<http://www.spanos-przetak.com/>. " ;
*!*			+ "Important legal rights could be prejudiced should you fail to follow the provisions contained within " ;
*!*			+ "Amended General Order 158."
*!*		DO PrintField WITH mv, "ExtraBB", IIF( pl_BBAsb AND pc_court1="SFSC", c_extrabb, " ")
*!*	***9/15/06 extra text
*-----------------------------------------------------------------------------------------------------------------------
*-- 04/17/2020 MD #167744
c_extrabb="Motions relating to this subpoena are to be filed and served " +;
		 "electronically pursuant to San Francisco Local Rule 20.  "+;
		 "For a copy of San Francisco Local Rule 20, please contact LexisNexis at http://www.lexisnexis.com/fileandserve/ "+;
		 "or Spanos | Przetak at 510-250-0200 or its website at www.spanos-przetak.com<http://www.spanos-przetak.com/>."+;
		 "Important legal rights could be prejudiced should you fail to follow the provisions contained within "+;
		 "San Francisco Local Rule 20."
DO PrintField WITH mv, "ExtraBB", IIF( pl_BBAsb AND pc_court1="SFSC", c_extrabb, " ")
*-----------------------------------------------------------------------------------------------------------------------
*-- 04/17/2020 MD #167744

	DO PrintGroup WITH mv, "Deponent"
* 06/17/03 DMA Add precise location of PrintDep routine
	IF LEFT( ALLT(  Spec_Ins.mailid_no), 1)="D"
		c_drname=gfdrformat(mdep)
		c_depname = IIF(NOT "DR."$c_drname,"DR. "+ALLTRIM(c_drname),c_drname)
	ELSE
		c_depname = ALLTRIM(mdep)

	ENDIF

	DO PrintDep IN Subp_CA WITH mid, c_depname

	DO PrintGroup WITH mv, "Plaintiff"
	DO PrintField WITH mv, "FirstName", pc_plnam
	DO PrintField WITH mv, "MidInitial", ""
	DO PrintField WITH mv, "LastName", ""
	*-- DO PrintField WITH mv, "BirthDate",pd_pldob && 12/07/2020 MD #186387	
	DO PrintField WITH mv, "BirthDate",IIF(!EMPTY(ALLTRIM(convertToChar(pd_pldob,0))),"DOB: "+ALLTRIM(convertToChar(pd_pldob,0)),"")
	&& 12/07/2020 MD #186387
	*-- DO PrintField WITH mv, "SSN",  ALLTRIM(pc_plssn) &&show only last 4 digits #48102 ALLTRIM( pc_fullssn)
	lnDigitCnt=0
	IF !EMPTY(ALLTRIM(NVL(pc_plssn,"")))
		FOR lnHHH=1 TO LEN(ALLTRIM(pc_plssn))
		    IF ISDIGIT(SUBSTR(ALLTRIM(pc_plssn),lnHHH,1))=.T.
		       lnDigitCnt=lnDigitCnt+1
		    ENDIF 
		NEXT
	ENDIF 
	DO PrintField WITH mv, "SSN",  IIF(!EMPTY(ALLTRIM(NVL(pc_plssn,""))) AND lnDigitCnt>0,"SS#: "+ALLTRIM(NVL(pc_plssn,"")),"") &&show only last 4 digits #48102 ALLTRIM( pc_fullssn)
	*-- 09/18/2019 MD #143595 
	&& 12/07/2020 MD #186387
	*-- DO PrintField WITH mv, "AKA",ALLTRIM(NVL(pc_maiden1,''))
	DO PrintField WITH mv, "AKA",IIF(!EMPTY(ALLTRIM(NVL(pc_maiden1,''))),"AKA: "+ALLTRIM(NVL(pc_maiden1,'')),"")
	
	DO PrintGroup WITH mv, "Case"
	DO PrintField WITH mv, "Plcap", ALLTRIM( pc_plcaptn)
	DO PrintField WITH mv, "Defcap", IIF( pl_PSGWC, "", ALLTRIM( pc_dfcaptn))
	DO PrintField WITH mv, "Docket", ALLTRIM( pc_docket)

	DO PrintGroup WITH mv, "Control"
	DO PrintField WITH mv, "Date", DTOC( pd_Depsitn)
	DO PrintField WITH mv, "LrsNo", pc_lrsno
	DO PrintField WITH mv, "Tag", ALLTRIM( STR( ntag))

ENDIF && 06/01/2016- Added "R" -scanned rider  #40514
RELEASE oMedTmp
WAIT CLEAR
RETURN
