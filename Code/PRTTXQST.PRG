PROCEDURE PrtTXQst
* Prints individual Texas question pages, usually to accompany a Notice
* of Intention to take deposition by written questions
** EF 3/8/06   Added to the VFP project.
**************************************************************************
** DMA 06/28/04 Use long plaintiff name; global variables
**              Eliminate unneeded calling parameter
**              Move external loop (in all calling routines) into this module
** DMA 06/09/04 Make pWrQuest into separate standalone routine
** EF 10/31/01 Print Texas Questions pages
* Formerly PROCEDURE pPrtQuest
*  Called from Subp_PA, PrtTXNot, TxCrtLtr, GenUtils
*  gfGetCas has already been called by upper-level routine
*  Calls gfTXCour, PrintGroup, PrintField, gfEntryN, gfLkUp, gfMailN
**************************************************************************
PARAMETERS mDep, mid, c_rqquest, ntag
*PARAMETERS tamaster, mDep, mid, mQuest, mForm, ntag
PRIVATE i, nrec, c_roloname, c_Quest, c_Form, n_Quest, n_Howmany, ;
	n_count1, n_count2, c_ThisQues
_SCREEN.MOUSEPOINTER=11
c_Quest = ALLT( c_rqquest)
c_Form = ALLT( LEFT( c_rqquest, 1))
n_Quest = LEN( ALLT( c_rqquest))
c_Quest = RIGHT( c_Quest, n_Quest-1)
n_Howmany = LEN( c_Quest) / 2
n_count1 = 0
n_count2 = 0
*USE ( f_States) IN 0
*SELECT States
*SET ORDER TO Code
* 06/28/04 DMA Perform the loop once for each individual set of questions
*              that will be sent to the deponent.
DO WHILE n_count2 <> n_Howmany
	n_count2 = n_count2 + 1
	c_ThisQues = SUBSTR( c_Quest, n_count1+1, 2)
	n_count1 = n_count1 + 2

	*c_RoloName = gfMailN( mid)
	DO PrintGroup WITH mv, "TXQst" + c_Form + ALLTRIM( UPPER( c_ThisQues))
	DO PrintField WITH mv, "RT", pc_lrsno + "." + ALLTRIM( STR( ntag))
	l_ST=oMed.sqlexecute("SELECT dbo.gfState('" + IIF(EMPTY(pc_depofile.state),"PA",pc_depofile.state) + "')", "DepSt")
	lcState=IIF(l_ST,DepSt.EXP, "")
	*lcState = gflkup( c_RoloName, "State", "MAILID_NO", mid)

	lcPrtState = ""
	*SELECT States
	IF !EMPTY (lcState)
		lcPrtState = ALLTRIM(UPPER( lcState))
	ENDIF
	DO PrintField WITH mv, "DepState", lcPrtState

	IF NOT USED ("TABills")

		l_Tabill=gettabill(pc_clcode)
		IF NOT l_Tabill
			gfmessage("Cannot get TAbills file")
			RETURN

		ENDIF
	ENDIF
	SELECT TABILLS
	** get court data
	DO gfTXCour                                  && IN gftxcour WITH ALLTRIM(TAMaster.court)

	* IF pl_autofax
	*lcEnt = pc_entryn

	*SELECT (lcEnt)
	*ELSE
	SELECT  timesheet
	*ENDIF

	DO PrintGroup WITH mv, "Case"
	DO PrintField WITH mv, "Plaintiff", ALLTRIM( pc_plcaptn)
	DO PrintField WITH mv, "Defendant", ALLTRIM( pc_dfcaptn)
	DO PrintField WITH mv, "Docket", pc_docket


	DO PrintGroup WITH mv, "PlCaption"
	DO PrintField WITH mv, "FirstName", pc_plnam
	DO PrintField WITH mv, "MidInitial", " "
	DO PrintField WITH mv, "LastName", " "

	DO PrintGroup WITH mv, "Deponent"
	DO PrintField WITH mv, "Name", mDep
	DO PrintField WITH mv, "Addr", ALLTRIM(pc_depofile.add1 + ' ' + pc_depofile.add2)
	DO PrintField WITH mv, "City", ALLTRIM(pc_depofile.City)
	DO PrintField WITH mv, "State", pc_depofile.state
	DO PrintField WITH mv, "Zip", pc_depofile.Zip
ENDDO
*SELECT States
*USE
_SCREEN.MOUSEPOINTER=0
RETURN
