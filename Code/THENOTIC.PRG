PROCEDURE TheNotic
** EF  04/23/2012 - Added KOP WCAB NOTICE FOR SUBP ISSUES
** EF  03/21/2012 - Added OMRPAge
** EF  02/29/2012 - All KOP litigation use the same USDC form
** EF  07/07/2011 _ Added NJ notices
** EF  03/03/2011 - Added Risperdal/pccp
** EF  09/27/2010 - Added Asb/Cambria Email Notice option
** EF  05/21/2010 - SKIP NOT WAVED TAGS WHEN NEEDED (COURTSET docs)
** EF  03/10/2010 - Removed web address from avandia1 notices
** EF  09/17/2009 - Print Notices to all paticipation attys who is ot inhibited and not reruesting
**					- in civil lit cases.
** md  05/04/2009 - Added check for civveroFaxNotice
** EF  04/14/2009 - Do not list Objected tags on the Notices with a court set
** EF  11/21/2008 - NY Notices-email
** EF  11/07/2008 - USDC notices
** EF  04/14/2008 - Added AM Fax Number form civil lit cases only
** EF  06/14/2007 - Print Notices for subps with no rps forms.
** EF  06/05/2007 - start faxing the notices again
** EF  12/01/2006 - Synch with the latest FoxPro.
** EF  10/26/2006 - Synch with the latest FoxPro (ver 7.38.00)
** EF  01/18/2006 -SWITCHED TO SQL
***************************************************************************************
*  Called by Plaintif, Reprint, CourtSet
*  Calls Subp_PA (main entry), Subp_PA (MDProof entry), gfGetDep, gfPrtGrp
*  Assumes that gfGetCas has already been called
*  11/15/2005  EF   Fixed a bug for printing notices for mixes ("A"/"S") issues.
*  09/12/2005  EF   Added [WebAddress] to the "NoticeAuthor" page.
*  08/24/2005  EF   Skip defense atty's for "A" lit Florida/NC areas cases
*  07/14/2005  EF   Added pl_CivilNY : skip requesting and ordering attys
*  04/01/2005  EF   Added notices for a new lit ("ENE")
*  02/10/2005  EF   Email "Zicam" notices
*  11/18/2004  EF   Print notices for not ordering "D" attys for HRT-Morgan
*  10/18/2004  EF   Edited the due date for HRT/Morgan notices ( txn11+23 calendar days)
*  10/15/2004  EF   Added Plaintiff Notices to HRT/Morgan
*  10/15/2004  EF   Print notices for plaintiff and requesting atty in the HRT/Morgan
*  10/13/2004  EF   Print only plaintiff notices for HRT-Keeley auth cases
*  09/21/2004  kdl  Restored msoc_sec parameter because it is reset by calling
*                    programs. Public variable can not be used. Replaced the use of
*                    the public variable pc_SSNLst4 with variable msoc_sec
*  09/17/2004  EF   Added Plaintiff Notices to the Serzone "A" issues
*  07/07/2004  DMA  Eliminate parameter msoc_sec; replace with pc_SSNLst4
*  06/28/2004  DMA  Replace bNot with pl_Noticng
*  06/21/2004  EF   Fixed a bug for printing 'Court Certificates'
*  06/08/2004  EF   Fixed a bug for printing notices with issues
*  05/21/2004  EF   Added one more parameter dIssDate to print Court Filing sets.
*  04/21/2004  EF   Attach a subpoena to both hold and nohold requests
*  03/24/2004  EF   Add a parameter for printing notices with KOP Court Sets
*  03/23/2004  EF   Edited 'NoticeAuthor' for pl_RezNY
*  03/18/2004  EF   Print a Tag's issue date on notices
*  02/12/2004  EF   Print 'Notice of Intent to Server a Subp..' for Hipaa 'No hold' issues
*  01/26/2004  EF   Use Atty Signature on notices
*  01/07/2004  EF   Do not print notice for req atty in PPA cases
*  12/23/2003  DMA  Use lookup table for special MD notice list
*                   Use more logicals to speed up processing
*  12/12/2003  kdl  Added new attorney code A24604P to special md notice list
*  12/11/2003  kdl  Added new attorney code to speacial md notice list
*  11/18/2003  EF   Do not print MD certif for some req.atty.
*  11/12/2003  DMA  Clear deponent-level global variables on exit
*  10/22/2003  IZ   If recipient is Plaintiff Atty and he/she inhibited notices,
*                      make it not print afterwards (outside the loop)
*  10/15/2003  IZ   For Maryland Asb Autho cases we need requesting attorney only
*  10/07/2003  EF   Asb Maryland Autorizations print notice for "D" atty only
*  09/18/2003  EF   Add MDL-hold notices
*  09/11/2003  EF   Add MLD lit notices and treat KOP Maryland notices as real MD ones
*  08/29/2003  EF   Modified MD Asb notices
*  08/20/2003  EF   Add a new notice for MD Asb Atty :"A1333P"
*  08/05/2003  EF   Add Rezulin-MDL notices
*  06/20/2003  EF   Add baycol notices to auth issues
*  03/26/2003  kdl  Update tag variables before call to subp_pa
*  12/23/2002  EF   Attach a subpoena to autofaxed notices
*  12/19/2002  kdl  Adjust notice for request type
*  12/11/2002  EF   Autofax Notices
*  11/12/2002  EF   Do not print  MI notice for Lead and Req attys.
*  11/12/2002  EF   Check for "C" atty status
*  10/18/2002  EF   Add a new-style Notice page for MI and NJ subpoena works.
*  10/10/02 IZ removed 3rd parameter from subp_pa call
*  08/28/2002  DMA  Improve group/case handling w/gfPrtGrp
*  08/21/2002  EF   Print notices for a requestor for Rezulin-Montgomery :
*                   and print only for a plaintiff if Ohio-Asb cases
*  05/28/2002  dma  block all notices for NY/NYC Asbestos per Kim Parsons
*  05/21/2002  kdl  Print notices only for plaintiff and Rq. Atty
*                   in PPA-state/federal cases
*  05/20/2002  kdl  Print notices for Rq. Atty in PPA cases
*  05/10/2002  kdl  Do not exclude PPA requesting defense attnys per jd
*  05/03/2002  DMA  Block notices for defense counsel only
*                   in litigations 51, 52
*  05/02/2002  kdl  Block notices for PA Propulsid cases' declining attnys
*  04/23/2002  DMA  Print notices for Rq, Atty in PA Propulsid cases
*                   Improve group-case handling
*  04/03/2002  DMA  Add in three new diet-drug litigations (E1, E2, E3)
*  03/18/2002  KDL  Start: modified so the text file used for notice letter
*                    for list of "from rev" deponents file will be used when
*                    records.fromrev is .T.
*  01/17/2002  EF   Print notices for Rq. Atty - Civil Lit. cases only.
*  01/02/2002  EF   Latex Glove Autho inhibit per Megan
*  12/03/2001  DMA  Use global variables for TAMaster items
*  09/12/2001  EF   3-char. litigation code
*  05/19/2001  DMA  Add call to gfGetDep to fill in public vbls.
*  03/05/1999  HN   Skip notices for Diet Drug defense attorneys
******************************************************************
*--kdl out 9/21/04: PARAMETER llReprint, dthisdate, lCourtSet, dIssDate
PARAMETER llReprint, msoc_sec, dthisdate, lCourtSet, dIssDate

PRIVATE csuborauth, bcourtd, x, bcourt, platp, contname, contphone
PRIVATE llCourt, llTabills, llLit, llPsNotice, llRecord, c_FaxCode, ;
	ll_FaxNotice, lc_SendType, llCovrCtl, nrec, nbal,  n_psrec, ;
	l_Plaint, l_Defend, l_Request, l_Lead, c_TrimArea, l_Subp, l_Autho, ;
	lcSearch, lcConfirm, lcScanNot, lcNotDate, ll_EmailNot, ;
	c_sql, l_3Angelos, l_ENYNotice, l_Wcabkop , l_ILCook, l_BaltCase,  l_getattys


PRIVATE  l_HasForm AS Boolean
PUBLIC mv
STORE "" TO mv, lc_SendType, lcSearch, lcConfirm, lcScanNot, lcNotDate,c_sql, pc_BatchRq, contphone
STORE .F. TO ll_FaxNotice, ll_EmailNot, l_2Angelos, pl_UpdHoldReqst, l_ENYNotice, l_BaltCase, l_getattys


WAIT WINDOW "Printing Notices. Please wait." NOWAIT NOCLEAR
_SCREEN.MOUSEPOINTER=11
SET PROCEDURE TO ta_lib ADDITIVE

c_TrimArea = UPPER( ALLTRIM( pc_area))

*** UserCtrl/Acct manager data ***************************
contname = pc_amgr_id
omed = CREATEOBJECT("generic.medgeneric")
IF NOT USED('UserCtrl')
	c_sql=" EXEC DBO.[GetUserByLogin] '" +pc_amgr_id + "'"
	omed.sqlexecute(c_sql, "UserCtrl ")
ENDIF
contname= UserCtrl.FULLNAME &&pc_UserNam
contphone= UserCtrl.DirectDial&& pc_UserPhn


IF EMPTY(ALLTRIM(contphone))  OR  LEN (ALLTRIM(contphone))<10
	contphone = "(800) 355-7400"                 && Direct dial phone number
ENDIF

*** Court data ****************************
x = pc_Court1
IF NOT USED("court")
	omed.sqlexecute("exec dbo.GetAllCourt", "court")
ENDIF
SELECT COURT
SELECT DISTINCT COURT.DESC ;
	FROM COURT INTO ARRAY bcourtd ;
	WHERE ALLTRIM(UPPER(COURT.COURT))==ALLTRIM(UPPER(x))
bcourt = ALLT( IIF( _TALLY > 0 AND NOT EMPTY( bcourtd[1]), ;
	bcourtd[1], MASTER.COURT))


*** Get Notices data ****************************
platp = .F.                                     && Keep track of plaintiff attorney's notice being printed
csuborauth = "S"                                && Defaults, to be set later correctly
nbal = 0
*** RPS class data ****************************
*!*	IF pl_RepNotc
*!*		mclass = "RepNot"
*!*	ELSE
*!*		DO CASE
*!*		CASE  lc_SendType="F" AND pl_NoFaxNotice=.F.
*!*			mclass="FaxNotice"
*!*		CASE  lc_SendType="E" OR pl_ElitNotice

*!*			DO CASE
*!*			CASE pl_CambAsb
*!*				mclass='AsbCambNot'
*!*			CASE  pl_RisPccP  AND NVL(PSNOTICE.TYPE,'A')='A'
*!*				mclass='RispNot'
*!*			OTHERWISE &&pl_zicam
*!*				mclass="ENotice" && defaul email notice class
*!*			ENDCASE
*!*		OTHERWISE
*!*			IF  pl_MDLead AND l_BaltCase  && 6/10/15-email md lead subp notices
*!*				mclass='ENotMDLead'
*!*			ELSE
*!*				mclass="Notice"
*!*			ENDIF
*!*		ENDCASE
*!*	ENDIF
*!*	mgroup = "1"




******************************************************************************************************
l_PsNotFile=GETPSNOTIC ( PC_CLCODE)

******************************************************************************************************

IF NOT l_PsNotFile
	gfmessage('Cannot open the PsNotice File.')
	RETURN
ENDIF

SELECT PSNOTICE
IF llReprint
	SET ORDER TO reprint
ELSE
	SET ORDER TO toprint
ENDIF

IF pl_CAVer OR lCourtSet
	SET ORDER TO cl_code
ENDIF
IF EMPTY(msoc_sec)
	msoc_sec='0'
ENDIF
IF SEEK( IIF( pl_CAVer OR lCourtSet, PC_CLCODE, ALLT( msoc_sec) + ALLT( PC_CLCODE)))

	n_psrec = RECNO()
	IF lCourtSet  &&05/21/04 EF: print court set
		lcSearch= "(CTOD(due_date)<>dIssDate) AND (cl_code == pc_clcode) ;
       			 			 AND NOT EOF()"
		lcConfirm = "(cl_code == pc_clcode) AND (CTOD(due_date) = dIssDate) "
	ELSE
		lcSearch = "(CTOD(txn_date)<>dThisdate) AND (cl_code == pc_clcode) ;
       					  AND NOT EOF()"
		lcConfirm = "(cl_code == pc_clcode) AND (CTOD(txn_date) = dThisDate)"
	ENDIF

	DO WHILE &lcSearch
		SKIP
	ENDDO
	IF &lcConfirm
		n_psrec = RECNO()
	ELSE
		GO  n_psrec
	ENDIF

&&11/7/16 #52171 - get a tag's type for reprint
	IF llReprint =.T. AND TYPE('pc_TgNotice')="C"

		csuborauth  =IIF(!EMPTY(pc_TgNotice), pc_TgNotice,PSNOTICE.TYPE)
		IF lCourtSet
			csuborauth ="S"
		ENDIF

	ELSE
		csuborauth = PSNOTICE.TYPE
	ENDIF

	l_Subp = (csuborauth = "S")
	l_Autho = (csuborauth = "A")
	l_3Angelos =IIF (pl_CRTAngl OR pl_DPVAngl OR pl_OSCAngl,.T.,.F.)
******************12/116- relocate here as need "S"/"A" for the RPS class defenition
	IF pl_RepNotc
		mclass = "RepNot"
	ELSE
		DO CASE
		CASE  lc_SendType="F" AND pl_NoFaxNotice=.F.
			mclass="FaxNotice"
		CASE  lc_SendType="E" OR pl_ElitNotice

			DO CASE
			CASE pl_CambAsb
				mclass='AsbCambNot'
			CASE  pl_RisPccP  AND NVL(PSNOTICE.TYPE,'A')='A'
				mclass='RispNot'
			OTHERWISE &&pl_zicam
				mclass="ENotice" && defaul email notice class
			ENDCASE
		OTHERWISE
			IF  pl_MDLead AND l_BaltCase  && 6/10/15-email md lead subp notices
				mclass='ENotMDLead'
			ELSE
				mclass="Notice"
			ENDIF
		ENDCASE
	ENDIF
	mgroup = "1"
******************12/116- relocate here as need "S"/"A" for the RPS class defenition



	STORE .F.  TO l_Wcabkop, l_ILCook, l_BaltCase
	l_ILCook =IIF(pl_ILCook  AND l_Subp, .T.,.F.)
	l_Wcabkop =IIF(pl_Wcabkop  AND l_Subp, .T.,.F.)
**4/08/15:  added MD notices
	l_BaltCase =  IIF(pc_c1Name = "MD-BaltimoCity"  AND l_Subp, .T.,.F.)
**4/08/15:  added MD notices


*** Get TABills Data : attys in a case****************************
	IF NOT USED ("Tabills") OR Tabills.cl_code<>PC_CLCODE
		l_Tabill=gettabill(PC_CLCODE)
		IF NOT l_Tabill
			gfmessage("Cannot get TAbills file to print Notices.")
			RETURN
		ENDIF
	ENDIF

	SELECT Tabills
	IF SEEK( ALLTRIM( PC_CLCODE))

*************************************************************
*!!!!!!
*!!!!!!  REMEMBER TO ADD RECORD TO NONOTICE.DBF FOR NEW LITIGATION
*!!!!!!  IF AUTHORIZATION NOTICES MUST BE GENERATED!!!
*!!!!!!
*************************************************************

		SCAN WHILE ALLTRIM( Tabills.cl_code) == ALLTRIM( PC_CLCODE)

** DMA 12/23/03 Use logicals for faster loop processing
			l_Plaint = (Tabills.CODE = "P")
			l_Defend = (Tabills.CODE = "D")
			l_Request = (Tabills.CODE = "R")
			l_Lead = (Tabills.CODE = "L")
			IF ALLTRIM( Tabills.at_code) == ALLTRIM( PSNOTICE.rq_at_code) AND pl_MargCiv
&&04/23/12- print wcab notices for all atty's -even requesting
&&EF : print notices for the req atty even if they inhibit for the pl_MargCiv 1/19/07
			ELSE
				IF Tabills.NoNotice
** 10/22/03 IZ If Plaintiff Atty has Inhibited notices,
**           make it not print afterwards (outside the loop)
					IF l_Plaint
						platp = .T.
					ENDIF
					LOOP

				ENDIF
			ENDIF
**11/21/08- NY EMAIL NOTICE CONDITION
			l_ENYNotice=.F.
			l_ENYNotice=IIF((pl_NYCAsb AND INLIST(at_code ,"A039428P", "A036300P", "A15187P","A10960P")), .T.,.F.)
**11/21/08- NY EMAIL NOTICE CONDITION
**01/11/2011 skip requesting asb/cambria
**03/03/2011 -skip pl_RisPccp rq attys
			IF ALLTRIM( Tabills.at_code) == ALLTRIM( PSNOTICE.rq_at_code) AND pl_CambAsb AND pl_RisPccP AND pl_ILCook
				LOOP
			ENDIF
			IF pl_CambAsb	AND INLIST( Tabills.Response, "T", "C")
*--skip T and C per Julie- asb/cambria
				LOOP
			ENDIF
**01/11/2011 skip requesting asb/cambria

**3/11/08 -EF- EXCLUDE REQUESDTING ATTY
**06/09/2015- added MD balt to the order verification rule
			DO CASE
			CASE  l_BaltCase
				l_getattys=.T.
			CASE  pc_litcode='C  '
				l_getattys=.T.
			OTHERWISE
				l_getattys=.F.
			ENDCASE


			IF l_getattys AND Tabills.CODE='D'  AND Tabills.at_code<>pc_rqatcod
				c_alias=ALIAS()

				IF FILE ('c:\temp\Tmpnot.DBF') AND USED('Tmpnot')
					SELECT  tmpnot
				ELSE
					IF FILE ('c:\temp\Tmpnot.DBF')
						DELETE FILE ('c:\temp\Tmpnot.DBF')
					ENDIF
					CREATE TABLE c:\temp\tmpnot.DBF ( at_code c(10))
					SELECT  tmpnot
				ENDIF
				IF  Tabills.NoNotice=.F.
					INSERT INTO tmpnot ;
						( at_code) ;
						VALUES ;
						(  Tabills.at_code)
				ENDIF

				IF NOT EMPTY( c_alias)
					SELECT (c_alias)

				ENDIF

			ENDIF


**2/8/08 print order verification for req atty even if we do not send notices



** Block ALL notices for NYC/New York asbestos cases
** per Kim Parsons. DMA 5/28/02
			IF pc_litcode = "A  " AND INLIST( c_TrimArea, "NEWYORK", "NYC") AND NOT l_ENYNotice
				LOOP
			ENDIF

			szrqcode = ALLTRIM( Tabills.at_code)

&& EF 01/17/2002 Print notice for Rq. Atty - only in Civil Litigation
&& DMA 04/23/2002 Add same handling for PA Propulsid cases
&& kdl 5/20/02 Same handling for PPA cases
&& EF 08/21/2002 The same for Rezulin-Montgomery
&& IZ 10/15/2003 The same for Asbestos-MD/Summarized
&& EF  11/14/03 do not print notices for civil lit issues

			IF l_Plaint AND  l_3Angelos
				LOOP
			ENDIF
			IF l_Plaint AND pl_HTSMotl
				LOOP
			ENDIF
			IF l_Plaint AND pl_WFSBart
				platp = .T.
				LOOP
			ENDIF

* - Lead/Motley
			IF l_Plaint AND pl_LeadMot  AND Tabills.Response = "T"
				platp = .T.
				LOOP
			ENDIF

**- welding fumes/Motley
			IF l_Plaint AND pl_WelfMot  AND Tabills.Response = "T"
				platp = .T.
				LOOP
			ENDIF

			IF l_Plaint AND pl_HTSPltf AND Tabills.Response="T"
				platp=.T.
				LOOP
			ENDIF


**04/23/12- print notice for rq atty with subps in the kop wcab issues
			IF (pc_litcode == "3  " AND c_TrimArea == "PENNSYLVANIA") OR;
					INLIST( pc_litcode, "51 ", "52 ")  OR ;
					(pc_litcode == "2  " AND c_TrimArea == "MONTGOMERY") OR ;
					pc_litcode == "A  " AND INLIST( c_TrimArea, "MARYLAND", "MD/SUMMARIZED")
&& removed on 4/30/12 OR l_Wcabkop
			ELSE
**EF 02/10/05 Exclude Notices for 'Zicam' lit
				IF (szrqcode == ALLTRIM( PSNOTICE.rq_at_code) ;
						AND szrqcode <> "A10920P")  AND NOT pl_HrtMorg  ;
						AND NOT pl_zicam AND NOT pl_CivilNY AND NOT pl_HTSMotl ;
						AND NOT pl_CRTAngl AND NOT pl_DPVAngl AND NOT pl_OSCAngl ;
						AND NOT pl_MargCiv

					LOOP
				ENDIF
			ENDIF

*--5/2/02 kdl start: block notices for PA Propulsid cases' declining attnys
			IF pc_litcode == "3  " AND c_TrimArea == "PENNSYLVANIA";
					AND INLIST( Tabills.Response, "F", "C")
*--make sure it's not the requesting or plaintiff att'y
				IF NOT (szrqcode == ALLTRIM( PSNOTICE.rq_at_code) OR l_Plaint)
					LOOP
				ENDIF
			ENDIF
*--5/2/02 kdl end:
**07/16/04 EF -Print Rezulin Notices only for "S" and "T" planitiff attys
			IF pc_litcode = "2  " AND l_Plaint AND Tabills.Response = "F"
				platp = .T.
				LOOP
			ENDIF
**EF 03/31/06 - skip all but defense"F" attys for civil/goldenberg
			IF NOT l_Defend AND ;
					(l_Autho AND  pl_GoldenCiv)
				LOOP
			ENDIF
**3/31/06

			IF pc_litcode == "A  " AND NOT l_ENYNotice
*------EF 08/21/2002 Skip notices for special Asbestos-related conditions
				IF ( c_TrimArea == "NYC" ) OR ;
						( c_TrimArea == "OHIO" AND NOT l_Plaint)
					LOOP
				ENDIF


** For asbestos HIPAA cases, print only plaintiff attorney notices
				IF pl_AsbHipaa AND NOT l_Plaint
					LOOP
				ENDIF

** 10/15/03 IZ  for Maryland Asb Autho cases we need requesting attorney only
** 10/07/03 EF  Asb Maryland Authorization print for defense atty
*--12/11/03 kdl start: add attorney code "A1691P" to list
*--12/12/03 kdl start: add attorney code "A24604P" to list
*            IF (csuborauth = "A" AND INLIST( UPPER( ALLTRIM( pc_area)), "MARYLAND", "MD/SUMMARIZED"))  ;
*                  OR INLIST (TABILLS.at_code, "A1333P", "A23580P", "A1691P", "A24604P")
*               IF NOT Tabills.Code == "D"
*                  SELECT Tabills
*                  LOOP
*               ENDIF
*            ENDIF
				IF NOT l_Defend AND ;
						(l_Autho AND INLIST( c_TrimArea, "MARYLAND", "MD/SUMMARIZED"))
					LOOP
				ENDIF

** DMA 12/23/03 Make attorney-code check table-driven
* Check lookup table for MD "CourtLink" attorneys

**check the CovrCtrl
				IF USED("covrCtrl")
					USE IN covrCtrl
				ENDIF

				lcSQLLine=""
				lcSQLLine="exec  [dbo].[GetAtCovrCtrlRecord] '" +fixquote(ALLTRIM(Tabills.at_code))+"'"
				SELECT 0
				omed.sqlexecute(lcSQLLine, "covrCtrl")
				SELECT covrCtrl
				IF RECCOUNT()>0
					IF covrCtrl.Area = "COURTLINK" AND covrCtrl.MD_Asb
						IF NOT l_Defend
							SELECT Tabills
							LOOP
						ENDIF
					ENDIF
				ENDIF
			ENDIF
			SELECT Tabills

**10/13/04 EF -only plaintiff atty get noticed for the Keeley-HRT cases
			IF pc_litcode = "HRT" AND ALLTRIM( pc_area) = "Keeley" ;
					AND NOT l_Plaint
				LOOP
			ENDIF
**10/13/04 -end

**EF 02/10/05 -start
**9/17/09 -AND NOT pc_litcode ="C"
			IF  NOT  l_BaltCase	AND NOT  pl_zicam AND NOT pl_HTSMotl ;
					AND NOT pl_CRTAngl AND NOT pl_DPVAngl AND NOT pl_OSCAngl AND NOT pl_RisPccP
				IF (l_Lead AND pl_HrtMorg)  OR ;
						(l_Defend AND szrqcode<>ALLTRIM(pc_rqatcod) AND Response="T" ) ;
						AND NOT pc_litcode ="C"


					LOOP
				ENDIF
			ENDIF &&zicam
**EF 02/10/05-end
**10/15/04 -end
**11/18/04 EF  -end
**09/17/04 EF Serzone Notice-print only for plaintiff's attys
			IF pl_SRZNot AND NOT l_Plaint
				LOOP
			ENDIF
**EF 04/01/05 -Environmental Exp. lit and Powell Law Grp area

			IF pl_ENEPwl AND l_Plaint
				IF pl_plisrq &&  req atty is not a defendant
					LOOP
				ENDIF
			ENDIF
*------08/21/2002
***7/14/05 Civil/NY -skip requesting and ordering attys
			IF pl_CivilNY
				IF  szrqcode=ALLTRIM(pc_rqatcod) OR Response="T"
					LOOP
				ENDIF
			ENDIF



**07/14/05 -civil/ny cases
*   Tests for special defense attorneys that don't get notices
			IF l_Defend
* 07/16/04 EF Skip Rezulin Defense attys
* 12/23/03 DMA Remove references to deleted litigations E1, E2, E3
* Don't print notices for diet drug defense attorneys
				IF INLIST( pc_litcode, "D  ", "E  ","DDV", "MLD", "2  ") ;
						OR pl_MdlHold OR pl_RezNY OR pl_PncFed
					LOOP
				ENDIF

* Don't print notices for PPA - State and PPA - Federal
* defense attorneys. Added 5/3/02 DMA
*--5/10/02 kdl start: do not exclude PPA requesting defense attnys per jd's direction
*--5/21/02 kdl start: per jen - ONLY print requesting and plaintiff attnys
**04/23/12 -WCAB NOTICES PRINT FOR ALL ATTYS IN A CASE PER ALEC -removed on 4/30/12
				IF INLIST( pc_litcode, "51 ", "52 ", "C  ") AND ;
						szrqcode == ALLTRIM( PSNOTICE.rq_at_code) &&AND NOT  l_Wcabkop
					LOOP
				ENDIF

* Don't print notices for Breast Implant 4 defense attys
* EF 12/28/01 -- No authos for Latex Glove defense attys
				IF INLIST(pc_litcode, "M  ", "O  ") AND l_Autho
					LOOP
				ENDIF

**EF 08/24/05- added Florida/NC areas
* Don't print notices for NYC Asbestos defense atty's

				IF pc_litcode == "A  " AND INLIST( c_TrimArea, "NYC", "Florida","North Corolina")  AND NOT l_ENYNotice
					LOOP
				ENDIF
**4/23/09 -if no email address -do not print a reqular one either



				IF l_ENYNotice

					l_gotemail=.F.
					l_gotemail=omed.sqlexecute("select dbo.GetNoticeAttyEmail ('" + Tabills.at_code + "'," + IIF(l_ENYNotice, STR(1),STR(0)) + " )","EmailAddr")
					IF l_gotemail
						pc_EmailAdd=IIF(ISNULL(ALLTRIM(EmailAddr.EXP)),"",ALLTRIM(EmailAddr.EXP))
					ENDIF
					IF EMPTY(pc_EmailAdd)
						LOOP
					ENDIF
				ENDIF

**4/23/09

			ENDIF

*--01/07/04 ef : do not print notices for req atty per Yvonne's request

			IF INLIST( pc_litcode, "51 ", "52 ") AND ;
					szrqcode == ALLTRIM( PSNOTICE.rq_at_code)
				LOOP
			ENDIF

**EF 11/12/02 do not print notice for MI for LEAD and REQUESTING attys

** 10/15/03 IZ changed the "()" location, otherwise it'll pick up non Michigan cases
			IF pl_MichCrt AND ( l_Lead OR ;
					ALLTRIM( Tabills.at_code) == ALLTRIM( pc_rqatcod))
				LOOP
			ENDIF
**EF 11/12/02

** EF 06/20/03 print baycol notices only for plaintiffs
			IF pc_litcode == "8  " AND c_TrimArea == "PHILADELPHIA" ;
					AND NOT l_Plaint
				LOOP
			ENDIF
** EF 06/20/03  end
**EF 04/01/05 - "ENE" lit /"Powell Law Grp" area : print for not orderinf defense

			IF pl_ENEPwl AND (l_Defend AND Tabills.Response="T")
				LOOP
			ENDIF
**EF 04/01/05 -end
**3/31/06
			IF pl_GoldenCiv AND (l_Defend AND Tabills.Response="T")
				LOOP
			ENDIF
**3/31/06
***EF 06/02/2006

			IF pl_HTSMotl AND (l_Defend AND Tabills.Response="F")
				LOOP
			ENDIF
**EF 06/02/2006
***EF 06/05/2006
**skip defense 'T'
			IF pl_CRTAngl OR pl_DPVAngl OR pl_OSCAngl ;
					AND (l_Defend AND Tabills.Response="T")
				LOOP
			ENDIF
**EF 06/05/2006

***EF 10/26/2006-start

			IF pl_LeadMot AND (l_Defend AND Tabills.Response="T")
				LOOP
			ENDIF

			IF  pl_WFSBart AND (l_Defend AND Tabills.Response="T")
				LOOP
			ENDIF


			IF pl_WelfMot AND (l_Defend AND Tabills.Response="T")
				LOOP
			ENDIF
**10/26/06	-end
**12/1/06 -start
			IF  pl_HTSPltf AND (l_Defend AND Tabills.Response="T")
				LOOP
			ENDIF
**12/1/06 -end

&& Got a good attorney to print!!
**find atty's preferred method for receiving notices
**10/04/2012 - if emails is set but atty does not have it- use atty's level setting
			DO CASE
			CASE  l_ENYNotice OR pl_ElitNotice AND !EMPTY(pc_EmailAdd)&&pl_CambAsb
				lc_SendType ="E"
			OTHERWISE

				lc_SendType = ALLTRIM( Tabills.hownotice)
			ENDCASE

**
**  PRINT ONLY if it's subpoena and has no form
**6/14/07 -use to print subp with no rpsform
**6/5/07- remove the below per Liz's email: start faxing the notices again

			c_sql="select dbo.getrpsform ('"  +  ALLTRIM(pc_Court1) + "' ) "
			l_gotrps=omed.sqlexecute(c_sql , "RpsForm")

			IF EOF() OR NOT l_gotrps
				l_HasForm=.F.
			ELSE
				l_HasForm=RpsForm.EXP
			ENDIF
			IF l_Subp=.T.  AND pc_offcode='P' AND  NOT l_HasForm
				*lc_SendType='P'			
				IF ALLTRIM(UPPER(pc_court1))==ALLTRIM(UPPER("PA-Philadelphi"))
			    	* 08/29/2018 MD #103895 allow PA-Philadelphi go to email/fax
			    	* 09/12/2018 MD removed for the production release 
			    	* 09/25/2015 MD uncommented
			    ELSE 
					lc_SendType='P'
				ENDIF 
			ENDIF

			IF pl_RepNotc
				mclass = "RepNot"
			ELSE
				IF TYPE('MCLASS')<>"C" OR EMPTY(mclass)
					DO CASE
					CASE  lc_SendType="F" AND pl_NoFaxNotice=.F.
						mclass="FaxNotice"
					CASE  lc_SendType="E"
						DO CASE
						CASE pl_CambAsb
							mclass='AsbCambNot'
						CASE  pl_RisPccP AND  NVL(PSNOTICE.TYPE,'A')='A'
							mclass='RispNot'
						OTHERWISE &&pl_zicam
							mclass="ENotice" && defaul email notice class
						ENDCASE

					OTHERWISE
						IF  pl_MDLead AND l_BaltCase  && 6/10/15-email md lead subp notices
							mclass='ENotMDLead'
						ELSE

							mclass="Notice"
						ENDIF
					ENDCASE

				ENDIF

			ENDIF

			IF szrqcode == ALLTRIM( pc_platcod)
				platp = .T.
			ENDIF

			pl_noticng = .T.
**PLAINTIFF'S COPY
			DO donotice WITH ALLTRIM( Tabills.at_code)
			pl_noticng = .F.
			SELECT PSNOTICE
			GOTO RECORD n_psrec
			SELECT Tabills
		ENDSCAN
	ENDIF
	_SCREEN.MOUSEPOINTER=0
&& Check if Plt Atty is the Requesting Atty!!
	IF NOT pl_plisrq AND ;
			(NOT platp) AND (NOT EMPTY( pc_platcod)) AND ;
			NOT INLIST( pc_platcod, "A14604P", "A14622P", "A14637P", ;
			"A14638P", "A14753P", "A16078P", "A16124P", "A16486P", "A16946P")
&& Print only if PltAtty is not the ReqAtty!!
&& and when the plaintiff attorney has not already been printed
**find atty's preferred method for receiving notices
**12/03/08 -EMAIL IS NOT SET ON THE 3.1.SCREEN YET
		DO CASE
		CASE l_ENYNotice OR pl_ElitNotice &&pl_CambAsb
			lc_SendType ="E"
		OTHERWISE

			lc_SendType = ALLTRIM( Tabills.hownotice)
		ENDCASE

**  PRINT ONLY if it's subpoena
**6/5/07- remove the below per Liz's email: start faxing the notices again
**6/14/07 -restored with additional conditions


		c_sql="select dbo.getrpsform ('"  +  ALLTRIM(pc_Court1) + "' ) "

		l_gotrps=omed.sqlexecute(c_sql , "RpsForm")

		IF EOF() OR NOT l_gotrps
			l_HasForm=.F.
		ELSE
			l_HasForm=RpsForm.EXP
		ENDIF

		IF l_Subp=.T.  AND pc_offcode='P' AND  NOT l_HasForm
			*lc_SendType='P'	
			IF ALLTRIM(UPPER(pc_court1))==ALLTRIM(UPPER("PA-Philadelphi"))
			    * 08/29/20158 MD #103895 allow PA-Philadelphi got to email/fax
			    * 09/12/2018 MD removed for the production release 
			    * 09/25/2015 MD uncommented
			ELSE 
				lc_SendType='P'
			ENDIF 
		ENDIF


		SELECT PSNOTICE
		GOTO RECORD n_psrec
		pl_noticng = .T.
**SECOND COPY
		DO donotice WITH ALLTRIM( pc_platcod)
		pl_noticng = .F.
	ENDIF

&&update psnotice was here
	SELECT Tabills
	WAIT CLEAR
	DO gfClrDep
**11/29/07 PRINT OrderVerification for Civil Lit cases
	IF NOT lCourtSet


		IF l_Wcabkop  OR l_ILCook  OR l_BaltCase  &&/WCAB does  print it for ALL litigation wcab subp isseus
&&2/22/13 -Added a new set- court set for cook county subps

** 10/10/14- check if a rq atty inhibited the notices then he does not need a civ order set
			LOCAL l_SendDoc AS Boolean
			l_SendDoc=.T.
			omed.closealias('NStatus')
			c_sql="select dbo.GetCaseRqAttyNoticeStatus ('"  +  ALLTRIM(PC_CLCODE) + "','"+  pc_rqatcod + "' ) "
			omed.sqlexecute(c_sql , "NStatus")
** 10/10/14
			IF USED("NStatus") AND !EOF()
				l_SendDoc=IIF(NVL(NStatus.EXP,.F.)=.T., .F.,.T.) && NONOTICE - MEANS DO NOT SEND DOCS
			ENDIF

			IF  l_SendDoc
				DO CivVerification WITH dthisdate
			ENDIF
			** --- 08/03/2020 MD #173172 -----------------------------------
			** -- per Alec's request/Bred email do not create this set
*!*				IF l_ILCook
*!*					DO CookCrtSet WITH dthisdate
*!*				ENDIF
			** --- 08/03/2020 MD #173172 -----------------------------------

			pl_noticng = .F. && fix a bug 8/09/2010
		ENDIF
**10/16/15- remove a check for  tmpnot : may need an orderverification page  with no listings per Liz -Zendesk15128
**04/08/15: do not print that set for l_BaltCase
**03/04/09- DO NOT GENERATE A SET FOR "A" TYPE OF ISSUE
		IF pc_litcode='C  '  AND NOT l_Autho &&AND FILE ('c:\temp\Tmpnot.dbf')
			IF NOT pl_Njsub AND NOT pl_Wcabkop AND  NOT pl_ILCook  AND NOT l_BaltCase&& 7/7/2011-04/23/12/ NJ does not print that set


** 10/10/14- check if a rq atty inhibited the notices then he does not need a civ order set
				LOCAL l_SendDoc AS Boolean
				l_SendDoc=.T.
				omed.closealias('NStatus')
				c_sql="select dbo.GetCaseRqAttyNoticeStatus ('"  +  ALLTRIM(PC_CLCODE) + "','"+  pc_rqatcod + "' ) "
				omed.sqlexecute(c_sql , "NStatus")
** 10/10/14
				IF USED("NStatus")
					l_SendDoc=IIF(NVL(NStatus.EXP,.F.)=.T., .F.,.T.) && NONOTICE - MEANS DO NOT SEND DOCS
				ENDIF


				IF l_SendDoc
					DO CivVerification WITH dthisdate
				ENDIF
				pl_noticng = .F. && fix a bug 8/09/2010
			ENDIF
		ENDIF
	ENDIF
**11/29/07 PRINT OrderVerification for Civil Lit cases

	IF NOT llReprint
&& Goto first record to print from!!
		SELECT PSNOTICE
		GOTO RECORD n_psrec
		DO WHILE ALLTRIM( msoc_sec) == ALLTRIM( PSNOTICE.User_code) AND ;
				ALLTRIM( PC_CLCODE) == ALLTRIM( PSNOTICE.cl_code) && ADD IF APPOVED 8/19/2011 AND CTOD(txn_date)=dthisdate
			DO WHILE NOT RLOCK()
			ENDDO
			REPLACE Printed WITH .T.
			UNLOCK
			L_OK= omed.sqlexecute("EXEC dbo.UpdateKopNoticeToPrinted '" + PC_CLCODE + "','" +  ALLTRIM(STR(PSNOTICE.TAG))+ "','" + IIF(pl_BatchNot, "BatchNot", "KopNot") +"'", "")

			IF NOT L_OK
				gfmessage("Cannot Update Notice. ")
			ENDIF

			SKIP
		ENDDO
	ENDIF
ENDIF

*-----------------------------------------------------------------------
*-- 09/23/2020 MD#181270
SELECT PSNOTICE
IF TYPE("n_psrec")="N" &&-- 08/10/2023 MD #325414
	GOTO RECORD n_psrec
	DO WHILE ALLTRIM( msoc_sec) == ALLTRIM( PSNOTICE.User_code) AND ALLTRIM( PC_CLCODE) == ALLTRIM( PSNOTICE.cl_code)
		IF NVL(draft,0)=1	
			omed.sqlexecute("exec dbo.addDraftMemo '" + ALLTRIM(PC_CLCODE) + "'," +  ALLTRIM(STR(PSNOTICE.TAG))+",'"+ALLTRIM(UPPER(goApp.CurrentUser.ntlogin))+"'" )
	    ENDIF 
	    IF  !EOF()			
			SKIP
		ENDIF 
	ENDDO
ENDIF 
*-- 09/23/2020 MD#181270		
*-----------------------------------------------------------------------
**04/25/16 #39616 - Delete temp files at the end of the process
IF FILE ('c:\temp\Tmpnot.DBF')
	IF USED ('Tmpnot')
		SELECT tmpnot
		USE
	ENDIF
	DELETE FILE ('c:\temp\Tmpnot.DBF')
ENDIF
**04/25/16 #39616 - Delete temp files at the end of the process
RETURN

**************************************************************************
**************************************************************************
PROCEDURE donotice
PARAMETER mratcode,  lcopyone, skipAttachments
* 01/31/2019 MD #126302 added third parameter ------ 
IF PCOUNT()<2
   lcopyone=.F.
ENDIF 
IF PCOUNT()<3
   skipAttachments=.F.
ENDIF  
&& For MD cases, first print Proof Of Service page
LOCAL l_NoMdProof AS Boolean, l_AMFaxCode AS Boolean

PRIVATE lc_NameInv, lc_Ratadd1, lc_Ratadd2, lc_Ratadd3, lc_RAtFax, ;
	lc_RqAtType, mLrs, mrpltcap, mrdefcap, mrdocket, mrterm, szSpcIns, ;
	lcTagName, lcNotice, lc_NoObjmde, lc_Waive, lc_Intrgtion, ;
	ld_Deposit, lcInit,  lc_RetEmail, l_gotremail, c_Addr

&& 08/13/2020 -IN Subpoena MD #170629	
LOCAL INNotP1_mv, INNot_tag, InNotP2_mv
STORE "" TO INNotP1_mv, INNotP2_mv
INNot_tag=1	

l_gotremail=.F.
omed = CREATEOBJECT("generic.medgeneric")

c_alias=ALIAS()

&&2/22/13- make a list of attys for CookCourtLetter
IF l_ILCook
	IF pc_litcode='C  ' AND Tabills.NoNotice=.F.  AND Tabills.at_code<>pc_rqatcod

		IF  USED('CookLtr')
			SELECT  CookLtr
		ELSE
			CREATE CURSOR CookLtr ( at_code c(10))
			SELECT CookLtr
		ENDIF


		INSERT INTO CookLtr ( at_code) ;
			VALUES 	( mratcode)


	ENDIF


ENDIF
&&2/22/13- make a list of attys for CookCourtLetter

***11/30/07 start-keep track of all defenses' for civil notices
IF NOT  lCourtSet
	IF NOT  lcopyone
**3/11/08 -EF- EXCLUDE REQUESDTING ATTY
		IF pc_litcode='C  ' AND Tabills.CODE='D'  AND Tabills.at_code<>pc_rqatcod

			IF FILE ('c:\temp\Tmpnot.DBF') AND USED('Tmpnot')
				SELECT  tmpnot
			ELSE
				CREATE TABLE c:\temp\tmpnot.DBF ( at_code c(10))
				SELECT  tmpnot
			ENDIF
**03/05/2009 DO NOT INCLUDE THE ATTYS WHO HAS INHIBIT THE NOTICES
			IF  Tabills.NoNotice=.F.
&& 4/21/09 do not list 'True' Defense atty
&& 08/26/09 DO LIST oRDERING DEFENSE PER LIZ'S REQUEST


				INSERT INTO tmpnot ( at_code) ;
					VALUES 	( mratcode)
			ENDIF

		ENDIF

		IF NOT EMPTY( c_alias)
			SELECT (c_alias)
		ENDIF
	ENDIF  && NOT  lCopyONE
ENDIF
********************11/30/07-end
IF NOT l_BaltCase
	l_NoMdCert=omed.sqlexecute("SELECT dbo.fn_NoMdCert('" + fixquote(pc_rqatcod) + "')", "NoMdCert")
	l_NoMdProof=IIF(l_NoMdCert,NoMdCert.EXP, .F.)

	IF (pl_ofcMD OR pl_MDasb) AND NOT l_Autho AND NOT l_NoMdProof
		DO MDProof IN subp_pa WITH PSNOTICE.TAG, Tabills.at_code
	ENDIF
ENDIF

STORE "" TO lc_NoObjmde, lc_Waive, lc_Intrgtion, lc_NameInv, lc_Ratadd1, ;
	lc_Ratadd2, lc_Ratadd3, lc_RAtCSZ, lc_RAtFax, lc_RqAtType, ;
	lcInit, pc_EmailAdd, lc_RetEmail, c_Addr

llHoldFlag = .F.

IF NOT l_Autho

	l_gothold=omed.sqlexecute("EXEC dbo.HoldRulesbyCourt  '" + PC_CLCODE + "','" +  pc_Court1 + "'", "IfHold")

	IF IfHold.EXP>0
		llHoldFlag = .T.
	ENDIF
ENDIF

mrpltcap=ALLTRIM( pc_plcaptn) &&07/23/12- always print a plcap in the caption
mrdefcap  = ALLTRIM( pc_dfcaptn)
mrdocket  = ALLTRIM( pc_docket)
**07/22/2013 - court set (waivers especialy) can be with a different due-date
IF lCourtSet
	mrduedate=pd_startNot
ELSE



	DO CASE
	CASE pl_HrtMorg
		mrduedate = 		DTOC( gfChkDat( CTOD(PSNOTICE.txn_date)+23, .F., .F.))
	CASE  l_BaltCase
		LOCAL d_fkedate
		d_fkedate=DTOC( gfChkDat( CTOD(PSNOTICE.txn_date)+1, .F., .F.))
		mrduedate = 		DTOC( gfChkDat( CTOD(d_fkedate)+30, .F., .F.))
	OTHERWISE
		IF TYPE ("PSNOTICE.due_date")="C"
			mrduedate = PSNOTICE.due_date
		ELSE
			mrduedate = DTOC( PSNOTICE.due_date)
		ENDIF
	ENDCASE


ENDIF

mrddtword = pd_request
*mrterm =LEFT(ALLT(DTOC(convrtDate(pd_term))),10)
&&08/29/13 - use month year per Liz
mrterm=termdate(pd_term)


mLrs   = pc_lrsno
**EF 08/29/03 MD asb due date
IF  ( pl_MDasb  AND NOT l_Autho)
	ld_Deposit = gfChkDat( CTOD(PSNOTICE.txn_date )+ 30, .F., .F.)
ENDIF
IF l_BaltCase
	ld_Deposit=mrduedate
ENDIF
&& Get Attorney!!

**EF 02/10/05  "Zicam"   Notices     -start
IF pl_zicam AND mratcode=ALLTRIM(pc_rqatcod)
	IF pl_plisrq
		c_AtNot = 'A27147P'
	ELSE
		c_AtNot = pc_platcod
	ENDIF
ELSE
	c_AtNot = mratcode
ENDIF
***EF 02/10/05     -end

****************************
c_Atty=fixquote(c_AtNot)
pl_GetAt = .F.
DO gfatinfo WITH c_Atty, "M"
szAtName = pc_AtyName
&&4/20/15- Use Atty's name for MD Balt per Liz.

&&01/26/04 EF Use Atty Signature
lc_NameInv = IIF(l_BaltCase,ALLTRIM( szAtName),pc_AtySign)&&ALLTRIM(Name_inv)
lc_Ratadd1 = pc_AtyFirm &&ALLTRIM( firm)
lc_Ratadd2 = pc_Aty1Ad &&ALLTRIM( NewAdd1)
lc_Ratadd3 =pc_Aty2Ad &&ALLTRIM( NewAdd2)
lc_RAtCSZ = pc_Atycsz &&ALLTRIM( NewCity + " " + NewState + "  " + NewZip)
lc_RAtFax = IIF(l_BaltCase , "",pc_AtyFax)

c_fax = STRTRAN( lc_RAtFax, " ", "")
c_temp = STRTRAN( c_fax, "-", "")
c_temp2 = STRTRAN( c_temp, "(", "")

lc_FaxNum = "1"+ STRTRAN( c_temp2, ")", "")

IF  LEN(lc_FaxNum )<10
	lc_FaxNum=""
ENDIF

**VALIDATE FAX# TILL GET A SPEC FOR A FULL VALIDATION
IF LEN(ALLTRIM(lc_FaxNum))=11 AND  INLIST(ALLTRIM(STRTRAN( c_temp2, ")", "")),'1111111111','2222222222','3333333333','4444444444','5555555555','6666666666','7777777777','8888888888','9999999999','0000000000')
	lc_FaxNum =""
ENDIF
**VALIDATE

IF EMPTY(pc_EmailAdd)
**10/15/2012- Fax is next after Email
	ll_FaxNotice = (NOT EMPTY( lc_FaxNum))
ELSE

	ll_FaxNotice = (NOT EMPTY( lc_FaxNum) AND lc_SendType == "F")
ENDIF
** 03/16/2017 #59566 : Added "KOPGeneric" /NJ courts/WCAB to the rule below


IF l_Subp
	LOCAL  l_c1Form AS Boolean
	l_c1Form =pl_c1Form
	l_c1Form= Rule1 () &&#59566 :

	IF l_BaltCase
		ll_FaxNotice=.F. && 4/20/15 -PRINT PER Liz
	ELSE
		ll_FaxNotice= IIF(l_c1Form =.T., ll_FaxNotice, .F.)
	ENDIF

ENDIF
**EF: 10/10/08-end

**see what is needed here for NY notices

IF l_ENYNotice OR pl_ElitNotice&&pl_CambAsb

	l_gotemail=.F.
*l_gotemail=oMed.sqlexecute("select dbo.NoticeAttyEmail ('" + mratcode + "')", "EmailAddr")
	c_sql=" EXEC dbo.GetNoticeAttyEmailList '" + mratcode + "'," + IIF(l_ENYNotice, STR(1),STR(0))

	l_gotemail=omed.sqlexecute( c_sql,"EmailAddr")
	IF l_gotemail
		pc_EmailAdd=IIF(ISNULL(ALLTRIM(EmailAddr.EXP)),"",ALLTRIM(EmailAddr.EXP))
		IF NOT EMPTY(pc_EmailAdd)
			ll_EmailNot=.T.
			ll_FaxNotice=.F. && WHEN EMAIL THEN NO FAX
			DO CASE

			CASE pl_CambAsb
				mclass='AsbCambNot'
			CASE  pl_RisPccP AND  NVL(PSNOTICE.TYPE,'A')='A'
				mclass='RispNot'
			OTHERWISE
				mclass="ENotice" && defaul email notice class
			ENDCASE
			lc_SendType ="E"

		ENDIF
	ELSE
		pc_EmailAdd=""
		gfmessage('No email address was found.')
	ENDIF



ELSE
	ll_EmailNot=.F. && removed as the 'old' way of emailing will be replaced by above method when the spec is ready .

ENDIF && not l_ENYNotice

&& Get Requesting Attorney Info!!
*******************
c_Atty=fixquote(pc_rqatcod)
pl_GetAt = .F.
DO gfatinfo WITH c_Atty, "M"
mrrqatname = ""
*********************

lcInit= pc_AtyName


IF pl_CAVer
	mrrqatname = ALLTRIM(pc_AtyFirm )
ELSE

&&01/26/04 EF Use Aty Signature
	mrrqatname = ALLTRIM(pc_AtySign)
ENDIF



&& Get Requesting Attorney Type!!
*lc_RqAtType = IIF( pl_plisrq, "Plaintiff", "Defendant")
**12/07/2016 -#54099 - D and L then lc_RqAtType = "Defendant"  otherwise Plaintiff
lc_RqAtType=""
IF NOT EMPTY(pc_rqatcod)
	omed.closealias("attyrole")
	omed.sqlexecute("select dbo.qc_GetRqAttyRole ('" + fixquote(PC_CLCODE) + "','" + pc_rqatcod + "')","attyrole")
	IF USED('attyrole')
		lc_RqAtType= IIF(NVL(attyrole.EXP,'')="P" , "Plaintiff","Defendant" )
	ENDIF
ENDIF
**12/07/2016 -#54099 - D and L then lc_RqAtType = "Defendant"  otherwise Plaintiff

lcNotice = ""

SELECT REQUEST
LOCATE FOR cl_code =PC_CLCODE AND TAG =PSNOTICE.TAG
*IF SEEK( psnotice.cl_code + "*" + str(psnotice.tag))
pl_GotDepo = .F.
DO gfGetDep WITH PC_CLCODE, PSNOTICE.TAG
*--3/18/02 KDL Start: switched the files so that the "from rev" file will
*--  be used when fromrev is .T.
*--12/19/02 kdl start: adjust notice for request type
*EF 11/15/05 -start: make sure we find the issue type for a selected tag, not
* the very first tag issued on a day
IF lCourtSet
	IF NOT USED('HoldReq')
		l_holdreq=omed.sqlexecute("Exec dbo.GetHoldRequests '" + fixquote(PC_CLCODE) + "','" + STR(timesheet.TAG) + "'","HoldReq")
		IF NOT l_holdreq
			gfmessage( 'Cannot get HoldReq data to print notices. Contact IT dept.')
		ENDIF
	ENDIF
	l_Autho =(holdreq.req_type='A')
ENDIF


IF NOT l_Autho
	lcNotice = IIF( pl_FromRev, pc_ltsfnot, pc_litsnot)
ELSE
	lcNotice = IIF( pl_FromRev, pc_litfnot, pc_litnotc)
ENDIF


IF  INLIST(pc_litcode,"ZOL" , "EFF") AND ALLTRIM(NVL(PSNOTICE.TYPE,'A'))='A'&& 04/30/14 - Zoloft's Notices + EFF as 8/14/14
	lcNotice="NoticeZOL"
ENDIF
IF pl_Wcabkop AND ALLTRIM(NVL(PSNOTICE.TYPE,'A'))='S'&& 04/23/12 -WCAB notice FOR KOP SUBP ISSUES
	lcNotice="WCABNotice"
ENDIF
** 04/08/15 MD/baltimore notices + 4/16/15 added MdMailPage
IF l_BaltCase
	IF  Tabills.CODE="P" AND NOT pl_OrdVerSet
		DO MdMailPage
	ENDIF
	lcNotice=IIF(pl_MDLead,"MDNotice2","MDNotice")
ENDIF
** 04/08/15 MD/baltimore notices
**03/03/2011 added Risperdal/PCCP  + 11/29/16 - use the "RispNotice" for "A" only

IF pl_RisPccP  AND  NVL(PSNOTICE.TYPE,'A')='A'
	lcNotice="RispNotice"
ENDIF
**07/07/2010 - split old Zicam and new Zicam casess

IF pl_zicam
	lcNotice="ZCMNotice"
ENDIF
**07/07/2010 - split old Zicam and new Zicam casess

IF pl_MDasb AND NOT l_Autho
	lcNotice = "NotDuces"
ENDIF
IF pl_MdlHold
	lcNotice = "HoldRezNot"
ENDIF
IF pl_RezNY
	lcNotice = "NoticeAuthor"
ENDIF
*** 11/21/2008- NY notice - emal-start

IF l_ENYNotice  AND NOT EMPTY(pc_EmailAdd)
	lcNotice = "ENoticeAth"

ENDIF
** Cambria County/Asbests - email notice

IF pl_CambAsb
	lcNotice = "AsbENotice"
ENDIF

*** 11/21/2008- NY notice - emal-end

**START 11/11/08--USDC NOTICE
***02/29/12 All KOP litigation use the same USDC form && removed AND pc_Litcode='C  '
**09/17/09 - USDC like courts follow the same rule
IF (LEFT( ALLTRIM(pc_Court1), 4) = "USDC"  AND NOT pl_CAVer  ) AND NOT l_Autho
	lcNotice= "USDCNotice"
ENDIF

IF pl_ILCook AND ALLTRIM(NVL(PSNOTICE.TYPE,'A'))='S'&& 04/23/12 -WCAB notice FOR KOP SUBP ISSUES
	lcNotice="NewNoticeSubp"
ENDIF

IF plCourtIN AND ALLTRIM(NVL(PSNOTICE.TYPE,'A'))='S'&& 08/13/2020 -IN Subpoena MD #170629
	lcNotice="SubpINNotP1"
ENDIF

**4/14/08 -added AM Fax Number form civil lit cases only -start
IF pl_KOPVer
	c_FaxCode="P"
	IF ALLTRIM(pc_litcode) ="C"
		l_AMFaxCode= GetAMFaxCode (pc_amgr_id)
		IF l_AMFaxCode
			c_FaxCode=IIF(ISNULL(AMFax.RpsAMFaxCode) OR EMPTY(AMFax.RpsAMFaxCode), 'P', AMFax.RpsAMFaxCode)
		ELSE
			c_FaxCode= "P"
		ENDIF
	ELSE
		c_FaxCode=pc_offcode
	ENDIF
**4/14/08 -added AM Fax Number form civil lit cases only-end
ELSE
	c_FaxCode=""
ENDIF
IF NOT l_Autho
	llHoldFlag = .F.
	l_gothold=omed.sqlexecute("exec dbo.HoldRulesbyCourt  '" + PC_CLCODE + "',' " +  pc_Court1 + "'", "IfHold")
	IF IfHold.EXP>0 &&gfHold( pc_clcode) > 0
		llHoldFlag = .T.
	ENDIF
&&EF 10/17/02 Michigan subpoenas print with a new-style notice
	IF NOT pl_Njsub

		IF pl_MichCrt
			DO PrintGroup WITH mv, "NoticeMISubpoena"
**EF MI notices need an additional line
			lc_Intrgtion = IIF (pl_MichCrt, ;
				" THERE WILL NOT BE NO INTERROGATION OF THE DEPONENT(S) " + ;
				"BY THE REQUESTING ATTORNEY" ,"")
			DO PrintField WITH mv, "Intrgtion",  lc_Intrgtion
		ELSE
			IF pl_ofcMD AND ALLTRIM( pc_litcode) = "C"
				DO PrintGroup WITH mv, ;
					IIF( NOT EMPTY( lcNotice), ALLT(lcNotice), "NoticeSubpoena2")

			ELSE
				DO PrintGroup WITH mv, IIF( NOT EMPTY( lcNotice), ALLT(lcNotice),;
					IIF( llHoldFlag OR PL_HIPAA, "NoticeSubpoena", "NoticeSubpoena2") )
			ENDIF
		ENDIF
	ELSE

		DO PrintGroup WITH mv, "NewNoticeSubp"
		lc_Waive =  IIF( pl_Njsub, "10", "14")
		lc_NoObjmde = IIF( pl_Njsub, "", ;
			"If no objection is made, the subpoena(s) will be served.")
		DO PrintField WITH mv, "WaiveDate", lc_Waive
		DO PrintField WITH mv, "IfNoObjection", lc_NoObjmde
		DO PrintField WITH mv, "Intrgtion",  ""
	ENDIF


***11/30/07 new field on the subpoena's notices
	IF csuborauth ="S"
		dthisdate2=dthisdate
		DO PrintField WITH mv, "CopyTitle", IIF(lcopyone, 'C O P Y', '')
		IF lcopyone
			IF l_BaltCase
				IF TYPE ("dthisdate")="D" OR TYPE ("dthisdate")="T"
					IF  TYPE ("dthisdate")="T"
						dthisdate=TTOD(dthisdate)
					ENDIF
				ELSE
					dthisdate=DATE()
				ENDIF
				dthisdate2 = gfChkDat( dthisdate+ 1, .F., .F.) &&5/20/15 ADDED A DAY PER LIZ

			ENDIF



			DO PrintField WITH mv, "RequestDate", DTOC( dthisdate2)
		ENDIF
	ENDIF
***11/30/07 new field on the subpoena's notices

	DO PrintField WITH mv, "Loc", ;
		IIF( pl_ofcPgh OR pl_ofcMD, "P", pc_offcode)

	DO PrintField WITH mv, "DepDate", mrduedate

	DO PrintField WITH mv, "FaxLoc", ;
		IIF( pl_ofcPgh OR pl_ofcMD, "P", c_FaxCode)

ELSE
	DO PrintGroup WITH mv, IIF( NOT EMPTY( lcNotice), ALLT( lcNotice), ;
		"NoticeAuthor")
	DO PrintField WITH mv, "Loc", ;
		IIF( pl_ofcPgh OR pl_ofcMD, "P", pc_offcode)

	DO PrintField WITH mv, "FaxLoc", ;
		IIF( pl_ofcPgh OR pl_ofcMD, "P", c_FaxCode)
**09/12/05 start- intergel/florida changes to a notice page

*!*		DO PrintField WITH mv, "WebAddress", ;
*!*			IIF( pl_IRGFl , "", " OR REPLY THROUGH OUR WEB SITE AT Recordtrak.com")
**10/22/15: use a new/edited reqaunot.doc per Zendesk#18980
	DO PrintField WITH mv, "WebAddress", ;
		IIF( pl_IRGFl , "", " or reply through our web site at RecordTrak.com")
&& 09/24/2010 - Cambria County Asbestos Notice have the special settings per Julie's request.


	IF pl_CambAsb
		l_gotrec=.F.
		omed.sqlexecute(" exec dbo.GetEmailNoticeRecord '" + pc_litcode + "' ,'" +pc_area + "','" +pc_offcode +"'", "EmailNot")
		SELECT EmailNot
		IF NOT EOF()
			l_gotrec=.T.
			IF l_gotrec
				contname=	ALLTRIM(EmailNot.NoticeContact	)
				contphone=UserCtrl.DirectDial
				DO PrintField WITH mv, "EmailAddress",  UPPER(ALLTRIM(EmailNot.NoticeEmail))
			ENDIF
		ENDIF
	ENDIF
&& 09/24/2010 - Cambria County Asbestos Notice have the special settings per Julie's request.
ENDIF
**03/03/2011 added Risperdal/pccp+ 11/29/16 - use the "RispNotice" for "A" only

IF pl_RisPccP  AND  ALLTRIM(NVL(PSNOTICE.TYPE,'A'))='A'
	DO PrintField WITH mv, "NotcDate", DTOC( dthisdate)
	DO PrintField WITH mv, "AttyEmail", NVL(pc_EmailAdd,'')
	DO PrintField WITH mv, "RequestDateby",  DTOC(SkipBusd(pd_reqmail,1))
	DO PrintField WITH mv, "RequestDateaf",  DTOC(SkipBusd(pd_reqmail,1))

** added PL Firm names
	lc_list=""
	lc_list =getplfirms()
	DO PrintField WITH mv, "AttyList", IIF(EMPTY(ALLTRIM(lc_list)),"Sheller P.C.",ALLTRIM(lc_list))


ENDIF

**CHECK DUE DATE


DO PrintField WITH mv, "DueDate", mrduedate

*-- 01/26/2021 MD #
*-- 04/16/2021 MD #234373
*-- IF (LEFT( ALLTRIM(pc_Court1), 4) = "USDC"  AND NOT pl_CAVer  ) AND NOT l_Autho AND lcNotice= "USDCNotice"
IF ALLTRIM(UPPER(lcNotice))= ALLTRIM(UPPER("USDCNotice"))
	addedText1="____ Yes, I would like to purchase a copy of all of the records listed above."
	addedText2="____ Yes, I would like to purchase the specific records I have indicated above."
	addedText3="SIGNATURE: _______________________________________   Date: ______________"
	addedText4="FIRM: __________________________________________________________________"
	addedText5="EMAIL:  ________________________________________________________________"	
	omed.closealias("viewUSDCNotice")
	omed.sqlexecute(" exec dbo.checkUSDCNotice '" + pc_lrsno +"'", "viewUSDCNotice")
	SELECT viewUSDCNotice
	IF RECCOUNT()>0  
		IF viewUSDCNotice.dontPrint=.T.
			STORE "" TO addedText1,addedText2,addedText3,addedText4, addedText5
		ENDIF 
	ENDIF 
	omed.closealias("viewUSDCNotice")
	DO PrintField WITH mv, "Text1", addedText1
	DO PrintField WITH mv, "Text2", addedText2
	DO PrintField WITH mv, "Text3", addedText3
	DO PrintField WITH mv, "Text4", addedText4
	DO PrintField WITH mv, "Text5", addedText5
ENDIF
*------------------------------------------------------------------

IF pl_MDasb AND NOT l_Autho
	DO PrintField WITH mv, "Deposit", DTOC( ld_Deposit)
ENDIF
**06/20/03 baycol special data
IF pl_Baycol AND NOT l_Autho
	DO PrintField WITH mv, "ReqAtty", mrrqatname
	DO PrintField WITH mv, "NoticeDif", IIF( pl_FromRev, ;
		"as 10 day notice that, in the absence of any objection within 10 day period, RecordTrak will be", ;
		"to notify you that RecordTrak is" )
	DO PrintField WITH mv, "Listed", IIF( pl_FromRev, "NOT", "")
ENDIF
**06/20/03


**11/21/08-ny notice-start
IF l_ENYNotice  AND NOT EMPTY(pc_EmailAdd)
	l_gotremail=.F.
	l_gotremail=omed.sqlexecute("select dbo.NoticeEmail('" +pc_litcode + "', '" + pc_area + "','" + ALLTRIM(pc_amgr_id)+ "','" + pc_offcode +"')", "REmailAddr")
	IF l_gotremail AND NOT EOF()
		lc_RetEmail=IIF(ISNULL(ALLTRIM(REmailAddr.EXP)),"",ALLTRIM(REmailAddr.EXP))
	ELSE
		gfmessage('No return email address was found.')
	ENDIF

	DO PrintField WITH mv, "RetEmail", lc_RetEmail
ENDIF
**11/21/08-ny notice -end


DO PrintGroup WITH mv, "Case"

DO PrintField WITH mv, "LRS", mLrs
DO PrintField WITH mv, "Name", pc_plnam
DO PrintField WITH mv, "Plaintiff", mrpltcap
DO PrintField WITH mv, "Defendant", mrdefcap
DO PrintField WITH mv, "AttyName", mrrqatname

IF NOT pl_CAVer
	DO PrintField WITH mv, "AttyType", IIF( lc_RqAtType = "Defendant", "D", "P")
ENDIF
**06/10/2013 use court's description for KOP hold subps per Liz/Alec
**02/29/12 All KOP litigation use the same USDC form && removed AND pc_Litcode='C  '
**08/08/2011 use pc_c1Desc as court's description


IF (LEFT( ALLTRIM(pc_Court1), 4) = "USDC"  AND NOT pl_CAVer  ) AND NOT l_Autho
	DO PrintField WITH mv, "Court", ALLTRIM(pc_c1Desc) &&PROPER(ALLT(  pc_distrct)) + " District of " + getstatename(pc_c1State)
ELSE
	DO PrintField WITH mv, "Court", IIF(llHoldFlag, ALLTRIM(pc_c1Desc),PROPER( pc_c1Desc))
ENDIF
DO PrintField WITH mv, "Term", mrterm
DO PrintField WITH mv, "Docket", mrdocket

NOTE ³ Following array logic included by Mark Rizzo on 11/12/97
NOTE ³ to correct the passing of attorney rolodex fields.
DO PrintGroup WITH mv, "Atty"
	laRTS = ""
	lcRPS = ""
	DIMENSION laRTS[5]
	DIMENSION laRPS[5]
	laRTS[1] = "lc_NameInv"
	laRTS[2] = "lc_RAtAdd1"
	laRTS[3] = "lc_RAtAdd2"
	laRTS[4] = "lc_RAtAdd3"
	laRTS[5] = "lc_RAtCSZ"
	laRPS[1] = "Name_inv"
	laRPS[2] = "Ata1"
	laRPS[3] = "Ata2"
	laRPS[4] = "Ata3"
	laRPS[5] = "Atacsz"
	lnRTS = 0
	FOR nLoop = 1 TO 5
		lnRTS = lnRTS + 1
		DO WHILE lnRTS < 6
			IF EMPTY(ALLTRIM(&laRTS[lnRTS].))
				lnRTS = lnRTS + 1
			ELSE
				EXIT
			ENDIF
		ENDDO
		IF lnRTS < 6
			DO PrintField WITH mv, laRPS[nLoop], &laRTS[lnRTS].
		ELSE
			DO PrintField WITH mv, laRPS[nLoop], " "
		ENDIF
	NEXT nLoop
	DO PrintField WITH mv, "FaxNo", lc_RAtFax

DO PrintGroup WITH mv, "Contact"
DO PrintField WITH mv, "Name", contname
DO PrintField WITH mv, "Phone", contphone

***EF 02/10/05 Zicam CC Atty printing
IF pl_zicam
*******************
	c_Atty=fixquote(pc_rqatcod)
	pl_GetAt = .F.
	DO gfatinfo WITH c_Atty, "M"

	DO PrintGroup WITH mv, "CcAtty"
	DO PrintField WITH mv, "Name_inv", UPPER( pc_AtyName)
	DO PrintField WITH mv, "Ata1", pc_AtyFirm
	DO PrintField WITH mv, "Ata2", pc_Aty1Ad
	DO PrintField WITH mv, "Ata3", pc_Aty2Ad
	DO PrintField WITH mv, "Atacsz", pc_Atycsz
	DO PrintField WITH mv, "Phone", pc_AtyPhn
	DO PrintField WITH mv, "FaxNo", pc_AtyFax
ENDIF


IF  l_BaltCase
	l_gotrec=.F.
	omed.sqlexecute(" exec dbo.GetEmailNoticeRecord '" + pc_litcode + "' ,'" +pc_area + "','" +pc_offcode +"'", "EmailNot")
	SELECT EmailNot
	IF NOT EOF()
		l_gotrec=.T.
		IF l_gotrec
			contname=	ALLTRIM(EmailNot.NoticeContact	)
			contphone=UserCtrl.DirectDial
			DO PrintField WITH mv, "EmailAddress",  UPPER(ALLTRIM(EmailNot.NoticeEmail))
		ENDIF
	ELSE&& did not find email on alit/area use acctmgr's one
		DO PrintField WITH mv, "EmailAddress",  ALLTRIM(NVL(pc_amgr_ml, ""))
	ENDIF
ENDIF


**EF 02/10/05 -end
*------------------------------------------------------------------------
*EF  caseinfo
* 08/28/02 DMA Use public vbls for group/case information
*------------------------------------------------------------------------

IF pl_ofcKOP OR pl_ofcMD OR pl_ofcPgh OR  pl_ofcHous
	pl_KOPVer=.T.
ENDIF
IF pl_KOPVer  AND NOT pl_zicam
	DO gfPrtGrp
ENDIF
*------------------------------------------------------------------------


**** This is for the list of record custodians

CREATE CURSOR AutoSubp (DepTag N(3))

x = 0
SET MEMOWIDTH TO 75
_PLENGTH = 57


&& Print List of Notices!!
SELECT PSNOTICE
IF pl_KOPVer AND NOT lCourtSet
	SEEK ALLTRIM( msoc_sec) + ALLTRIM( PC_CLCODE)
ELSE
**06/02/2011 - REMOVE ALL THE TAG NOT ISSUED ON A GIVEN DATES TO AVOID A SITUATION WHEN TAGS HAVE BEEN ISSUED UNSEQUENTIALLY

	DELETE ALL FOR  CTOD(due_date)<CTOD(mrduedate)
	DELETE ALL FOR  CTOD(due_date)>CTOD(mrduedate)
	GO TOP
**06/02/2011 -
	SET ORDER TO cl_code
	SEEK ALLTRIM(cl_code)
ENDIF


&& Locate proper date!!
DO WHILE NOT EOF() AND IIF( pl_CAVer OR lCourtSet, cl_code==PC_CLCODE, ;
		ALLTRIM( msoc_sec) == ALLTRIM(User_code) AND ;
		ALLTRIM( PC_CLCODE) == ALLTRIM(PSNOTICE.cl_code))

	IF (CTOD(PSNOTICE.txn_date) == dthisdate) OR lCourtSet

&&EF 03/18/04 print correct issue date on notices
		IF l_BaltCase  &&4/16/15- add one date to MD Balt cases per Liz/Alec
*dthisdate2 =dthisdate
*dthisdate2 = gfChkDat( CTOD(PSNOTICE.txn_date )+ 1, .F., .F.)
*DO PrintField WITH mv, "RequestDate",  DTOC( dthisdate2)
			IF TYPE ('d_fkedate')="D"
				DO PrintField WITH mv, "RequestDate",  DTOC( d_fkedate)
			ELSE
				DO PrintField WITH mv, "RequestDate",   d_fkedate
			ENDIF

		ELSE


**11/29/16 - use the "RispNotice" with its rules for "A" only
			DO PrintField WITH mv, "RequestDate", ;
				IIF( lCourtSet , DTOC( dthisdate),  IIF(pl_RisPccP AND ALLTRIM(NVL(PSNOTICE.TYPE,'A'))='A' ,DTOC(SkipBusd(pd_reqmail,1)),PSNOTICE.txn_date))
		ENDIF
		EXIT
	ENDIF
	SKIP
ENDDO


&&EF 05/21/04
IF lCourtSet
	lcScanNot = "cl_code==pc_clcode AND CTOD(due_date)=CTOD(mrduedate)"
	lcNotDate = "CTOD(PSNotice.due_date) == CTOD(mrduedate)"

ELSE
	lcScanNot = "cl_code==pc_clcode AND CTOD(txn_date)=dThisDate"
	lcNotDate = "CTOD(PSNotice.Txn_date) == dThisDate"

ENDIF
&& 08/13/2020 -IN Subpoena MD #170629
STORE "" TO INNotP1_mv, InNotP2_mv

SELECT PSNOTICE
GOTO n_psrec

IF  NOT pl_CambAsb
**7/24/13
	SCAN FOR IIF( pl_CAVer OR lCourtSet, ;
			&lcScanNot, ;
			ALLTRIM( msoc_sec) == ALLTRIM( User_code) AND ;
			ALLTRIM( PC_CLCODE) == ALLTRIM( PSNOTICE.cl_code))



		IF &lcNotDate                               &&06/21/04  EF : fixed a bug

**11/7/16 #52171 check if a tag's type agrees with a set -and skip if it does not
			IF ALLTRIM(UPPER(csuborauth))<>ALLTRIM(UPPER(PSNOTICE.TYPE))
				LOOP
			ENDIF
**11/7/16 #52171 check if a tag's type agrees with a set -and skip if it does not

			IF lCourtSet &&4/13/09- do not list objected tags + 5/19/2010 - SKIP NOT WAVED TAGS WHEN NEEDED
				c_sql=""
				l_inclide=.T.
				l_inclide=getcourtdates(PC_CLCODE,PSNOTICE.TAG)
				IF l_inclide
					c_sql="Exec [dbo].[CourtSetNotices]'" + fixquote(PC_CLCODE) + "', '" + ALLTRIM(STR(PSNOTICE.TAG) )+"'"
				ELSE
					LOOP
				ENDIF
			ELSE

				c_sql=" exec  dbo.GetTxn11Line '" + fixquote(PC_CLCODE) + "','" + ALLTRIM(STR(PSNOTICE.TAG) )+ "' "

			ENDIF &&4/13/09- do not list objected tags

			omed.sqlexecute(c_sql,'Timesheet')


***4/30/14 - USE DEPONENTS NAME INSTEAD OF THE TXN 11 LINE DESCRIPTION -PER LIZ
			LOCAL C_DEPT2 AS STRING, C_ADDITION AS STRING
			STORE "" TO C_DEP2,C_ADDITION
			IF  csuborauth ="S" AND ("PA" $ pc_Court1 OR ALLTRIM(pc_Court1) ="PCCP" )
				omed.closealias("Dept")
				c_sql="select dbo.GetDeptCode2('" +fixquote(PC_CLCODE) +"',"+ALLTRIM(STR(PSNOTICE.TAG))+") as deptcode"
				IF TYPE('OMED') <>"O"
					omed= CREATEOBJECT("generic.medgeneric")
				ENDIF
				pc_MailID=ALLT(PSNOTICE.Mailid_no)
				pc_deptype=""
				omed.sqlexecute(c_sql, "Dept")
				C_ADDITION= GETDESCRIPT(NVL(DEPT.DEPTCODE,'Z'))
				omed.closealias('TagDesc')
				lcSQLLine="select dbo.GetdepName ( '" + PSNOTICE.Mailid_no+ "')"
				omed.sqlexecute(lcSQLLine,"TagDesc")
				IF USED('TagDesc')
					C_DEP2=DEPTOPRINT(ALLTRIM(NVL(TagDesc.EXP,"")))
				ELSE
					C_DEP2= ALLTRIM( timesheet.DESCRIPT)
				ENDIF



			ELSE
				C_DEP2= ALLTRIM( timesheet.DESCRIPT)
			ENDIF

***4/30/14 - USE DEPONENTS NAME INSTEAD OF THE TXN 11 LINE DESCRIPTION -PER LIZ

			SELECT timesheet
			IF NOT EOF()

&&4/17/14 - do not show the blurbs with the subp notices
				DO CASE 
				CASE pl_zicam
				**IF pl_zicam
					DO GetObjct WITH PC_CLCODE, PSNOTICE.TAG, .T.
					DO PrintGroup WITH mv, "Item"
					DO PrintField WITH mv, "Col1", ALLTRIM( STR( PSNOTICE.TAG))
					DO PrintField WITH mv, "Col2",  ALLTRIM( timesheet.DESCRIPT)
					DO PrintField WITH mv, "Col3", STR(pn_objday)
					DO PrintField WITH mv, "Col4", IIF (pn_objday=0, PSNOTICE.due_date ,DTOC(pd_issdte))
				*-- CASE plCourtIn  --08/26/2021 MD #248878
				CASE plCourtIn AND ALLTRIM(NVL(PSNOTICE.TYPE,'A'))='S'
				** ---------------------------------
					&& 08/13/2020 -IN Subpoena MD #170629					
					*---LOCAL lcSQLLine 08/10/2022 MD #283265 commented out this line
					omed.closealias("INDInfo")													
					omed.sqlexecute("exec dbo.INNotcDepInfo '" +fixquote(PC_CLCODE) +"',"+ALLTRIM(STR(PSNOTICE.TAG)), "INDInfo")												
					DO PrintGroup WITH INNotP1_mv, "Item"					
					DO PrintField WITH INNotP1_mv, "Tbl1Col",ALLTRIM(NVL(INDInfo.name,""))+IIF(LEN(ALLTRIM(NVL(INDInfo.certtype,"")))>0," - "+ALLTRIM(NVL(INDInfo.certtype,"")),"")					
					DO PrintGroup WITH INNotP1_mv, "Item"				
					DO PrintField WITH INNotP1_mv, "Tbl1Col",ALLTRIM(NVL(INDInfo.address,""))		
					DO PrintGroup WITH INNotP1_mv, "Item"			
					DO PrintField WITH INNotP1_mv,"Tbl1Col",ALLTRIM(NVL(INDInfo.citystate,""))	
					DO PrintGroup WITH INNotP1_mv, "Item"				
					DO PrintField WITH INNotP1_mv, "Tbl1Col",ALLTRIM(NVL(INDInfo.phone,""))
					
					DO PrintGroup WITH INNotP2_mv, "Item"
					DO PrintField WITH INNotP2_mv, "Col1","_____"
					DO PrintField WITH INNotP2_mv, "Col2",ALLTRIM(STR(PSNOTICE.TAG))+" "+ALLTRIM(NVL(INDInfo.name,""))
					INNot_tag=PSNOTICE.TAG
					omed.closealias("INDInfo")	
					** ---------------------------------
				OTHERWISE 			
				**ELSE
					DO PrintGroup WITH mv, "Item"
					DO PrintField WITH mv, "Tag", ALLTRIM( STR( PSNOTICE.TAG))
					DO PrintField WITH mv, "Name", "____ " + C_DEP2+ C_ADDITION

&&7/1/14- PRINT BLURB ON ALL BUT KOP SUB NOTICES
					IF !l_BaltCase
						&& 08/13/2020 -IN Subpoena MD #170629
						IF NOT pl_ofcMD AND NOT plCourtIn
*--3/14/18: kdl fix for court that is not "PA" but has "PA" in its name [81846]
							DO PrintField WITH mv, "InfoText", 	IIF(PSNOTICE.TYPE ="S" AND ("PA-" $ pc_Court1 OR ALLTRIM(pc_Court1) ="PCCP"  OR  pc_Court1="PHILA MUNICIP" OR pl_MichCrt) ,"",STRTRAN( STRTRAN( PSNOTICE.spec_inst, CHR(13), " "), CHR(10), ""))
							*--DO PrintField WITH mv, "InfoText", 	IIF(PSNOTICE.TYPE ="S" AND ("PA" $ pc_Court1 OR ALLTRIM(pc_Court1) ="PCCP"  OR  pc_Court1="PHILA MUNICIP" OR pl_MichCrt),"",STRTRAN( STRTRAN( PSNOTICE.spec_inst, CHR(13), " "), CHR(10), ""))
						ENDIF
					ENDIF
*DO PrintField WITH mv, "InfoText", 	STRTRAN( STRTRAN( PSNOTICE.spec_inst, CHR(13), " "), CHR(10), "")

				**ENDIF &&Zicam
				ENDCASE 
				INSERT INTO AutoSubp ;
					(DepTag) ;
					VALUES ;
					(timesheet.TAG)

&&7/8/14- do not check to court's rule for Auth issues
				pl_CrtFlng = IIF(PSNOTICE.TYPE="A",.F., pl_CrtFlng)

			ENDIF
		ENDIF
&&OBJECTED TAG
		SELECT PSNOTICE
	ENDSCAN &&7/24/13
*SKIP
*ENDDO



ENDIF  && cambria asbestos notice
IF NOT llReprint
	mgroup = "3"
ENDIF

IF TYPE( "llHoldFlag")="U"
	llHoldFlag=.F.
ENDIF

*********************************** &&06/10/2015 - PRINT ONLY A COVER FOR THE REST OF PL ATTYS ON THE ORDER VERIFICATION
IF  pn_SetNum>1   AND pl_OrdVerSet  AND  l_BaltCase

	RETURN

ENDIF
***********************************&&06/10/2015 - PRINT ONLY A COVER FOR THE REST OF PL ATTYS ON THE ORDER VERIFICATION
* 01/31/2019 MD #126302 don't print subpoena attachments for the verification copy set ------    
IF skipAttachments=.T.
   RETURN
ENDIF   
*--- 09/27/2021  #251656 added to make sure the program at the right record 
SELECT PSNOTICE
GOTO n_psrec
*---------------------------------------------------------------
* --  08/14/2020 IN Subpoena MD #170629 page 2 and 3
* -- 08/31/2020 MD removed "proper" from firmname 
LOCAL IndCourtDist
IndCourtDist=""		
*-- IF plCourtIn=.T.  --8/26/2021 MD #248878
IF plCourtIn=.T. AND ALLTRIM(NVL(PSNOTICE.TYPE,'A'))='S' && 09/03/2021 REMOVED &&-- 09/27/2021 #251656 Restore with additional logic above
	*---- 09/17/2020 MD #191480
	*--LOCAL lcSQLLine 08/10/2022 MD #283265 commented out this line
	omed.closealias("viewINDCourtDist")													
	omed.sqlexecute("exec dbo.INNotcCourtDist '" +fixquote(PC_CLCODE)+"'", "viewINDCourtDist")	
	SELECT viewINDCourtDist
	IF RECCOUNT()>0
		GO top
		IndCourtDist=ALLTRIM(NVL(district,"" ))
		IndCourtCounty=ALLTRIM(NVL(caseCounty,Upper(pc_c1cnty) ))
	ENDIF 
	IF ALLTRIM(NVL(IndCourtDist,""))==""
		IndCourtDist="SUPERIOR COURT"
	ENDIF 
	omed.closealias("viewINDCourtDist")		
	*---- 09/17/2020 MD #191480	
	DO PrintGroup WITH mv,"SubpINNotP2"
	DO PrintGroup WITH mv, "Case"

	DO PrintField WITH mv, "LRS", mLrs
	DO PrintField WITH mv, "Name", pc_plnam
	DO PrintField WITH mv, "Plaintiff", mrpltcap
	DO PrintField WITH mv, "Defendant", mrdefcap
	DO PrintField WITH mv, "AttyName", mrrqatname

	DO PrintField WITH mv, "AttyType", IIF( lc_RqAtType = "Defendant", "D", "P")
	DO PrintField WITH mv, "Court", IIF(llHoldFlag, ALLTRIM(pc_c1Desc),PROPER( pc_c1Desc))
	DO PrintField WITH mv, "Term", mrterm
	DO PrintField WITH mv, "Docket", mrdocket
	* -- Do PrintField With mv, "County", Upper(pc_c1cnty)	10/29/2020 MD #202001
	Do PrintField With mv, "County", ALLTRIM(IndCourtCounty)						
 	Do PrintField With MV, "District", ALLTRIM(IndCourtDist) 	 		 	
 	holddays=0
 	oMed.closealias("viewHoldDays")
	oMed.sqlexecute("exec dbo.getHolDays '"+ALLTRIM(pc_clcode)+"', '"+ALLTRIM(fixquote(pc_Court1))+"' ","viewHoldDays")
	SELECT viewHoldDays
	IF RECCOUNT()>0
   		holddays = viewHoldDays.exp
	ENDIF  
	oMed.closealias("viewHoldDays")
	Do PrintField With MV, "holddays", ALLTRIM(STR(holddays )) 	
	DO PrintGroup WITH mv, "Atty"
	LOCAL leadfirmName, leadFileNo,leadDefendantName, leadRole,leadAtty,leadBarNo,leadNameInv,;
	leadAdd1,leadAdd2,leadAddcsz,leadPhone,leadFax, leadIssueDate, ;
	opRole,opBarNo,opName_Inv,opAdd1,opAdd2,opAddcsz,opPhone, opFirmName
	STORE "" TO leadfirmName, leadFileNo,leadDefendantName, leadRole,leadAtty,leadBarNo,leadNameInv,;
	leadAdd1,leadAdd2,leadAddcsz,leadAddcsz,leadPhone,leadFax, contactEmail, leadrequestDate,leadIssueDate,;
	opRole,opBarNo,opName_Inv,opAdd1,opAdd2,opAddcsz,opPhone, opFirmName
	
	oMED.closealias("viewDefName")
	SELECT 0
	oMED.sqlexecute("exec dbo.AttyDefInfo '" + fixquote(pc_clcode)+ "', "+ALLTRIM(STR(INNot_tag))+", '"+Iif( pl_plisrq, "P", "D")+"', '"+ALLTRIM(mratcode)+"'", "viewDefName")
	IF USED("viewDefName")			
	 	GO TOP 
		leadfirmName=ALLTRIM(AttyFirm)
		leadFileNo=ALLTRIM(fileno)
		leadDefendantName=ALLTRIM(DefendantName) 
		leadRole=ALLTRIM(attyrole) 
		leadAtty=ALLTRIM(rqAttyCode)
		leadBarNo=ALLTRIM(BarNo)
		leadNameInv=ALLTRIM(NameInv)
		leadAdd1=ALLTRIM(add1)
		leadAdd2=ALLTRIM(add2)
		leadAddcsz=ALLTRIM(Addcsz)
		leadPhone=ALLTRIM(Phone)
		leadFax=ALLTRIM(Fax)
		contactEmail=ALLTRIM(contactEmail)
		leadrequestDate=ALLTRIM(sendDate)
		leadIssueDate=ALLTRIM(reqDate)
		
		opfirmName=ALLTRIM(opFirmName)
		opRole=ALLTRIM(oprole) 		
		opBarNo=ALLTRIM(opBarNo)
		opName_Inv=ALLTRIM(opName_Inv)
		opAdd1=ALLTRIM(opadd1)
		opAdd2=ALLTRIM(opadd2)
		opAddcsz=ALLTRIM(opAddcsz)
		opPhone=ALLTRIM(opPhone)
	Endif			
	Do PrintField With mv, "Name_inv", leadNameInv
	Do PrintField With mv, "Ata1", leadAdd1
	Do PrintField With mv, "Ata2", leadAdd2
	Do PrintField With mv, "Atacsz", leadAddcsz
	Do PrintField With mv, "Phone", leadPhone
	Do PrintField With mv, "FaxNo", leadFax
	
	Do PrintField With mv, "FirmName", leadfirmName
	Do PrintField With mv, "subDefName", leadDefendantName
	Do PrintField With mv, "BarNo", leadBarNo
	Do PrintField With mv, "litEmail", contactEmail
	DO PrintField WITH mv, "FaxLoc", IIF( pl_ofcPgh OR pl_ofcMD, "P", c_FaxCode)
	Do PrintField With mv, "RequestDate", leadIssueDate
	
	mv=ALLTRIM(mv)+ALLTRIM(INNotP1_mv)
    
    *--------------------------------------------------------------
    *-- Indiana waver page
    DO PrintGroup WITH mv,"SubpINNotP3"
	DO PrintGroup WITH mv, "Case"

	DO PrintField WITH mv, "LRS", mLrs
	DO PrintField WITH mv, "Name", pc_plnam
	DO PrintField WITH mv, "Plaintiff", mrpltcap
	DO PrintField WITH mv, "Defendant", mrdefcap
	DO PrintField WITH mv, "AttyName", mrrqatname

	DO PrintField WITH mv, "AttyType", IIF( lc_RqAtType = "Defendant", "D", "P")
	DO PrintField WITH mv, "Court", IIF(llHoldFlag, ALLTRIM(pc_c1Desc),PROPER( pc_c1Desc))
	DO PrintField WITH mv, "Term", mrterm
	DO PrintField WITH mv, "Docket", mrdocket
	*--Do PrintField With mv, "County", Upper(pc_c1cnty)
	Do PrintField With mv, "County", ALLTRIM(IndCourtCounty)
 	Do PrintField With MV, "District", ALLTRIM(IndCourtDist) 	 		 
    Do PrintField With mv, "FirmName", leadfirmName
    mv=ALLTRIM(mv)+ALLTRIM(INNotP2_mv)
       	
	DO PrintField WITH mv, "opName_inv", alltrim(opName_inv)
	DO PrintField WITH mv, "opFirmName",ALLTRIM(opFirmName)
	DO PrintField WITH mv, "opAdd1", LTRIM(RTRIM(opAdd1))+IIF(LEN(ALLTRIM(NVL(opAdd2,'')))>0,' '+LTRIM(RTRIM(opAdd2)),"")
	DO PrintField WITH mv, "opAddcsz", opAddcsz
	DO PrintField WITH mv, "opPhone", opPhone
	DO PrintField WITH mv, "opBarNo", opBarNo
	DO PrintField WITH mv, "opRole", opRole
	
	DO PrintGroup WITH mv, "Contact"
	DO PrintField WITH mv, "Phone", contphone
	DO PrintField WITH mv, "Loc", IIF( pl_ofcPgh OR pl_ofcMD, "P", pc_offcode)
	DO PrintField WITH mv, "FaxLoc", IIF( pl_ofcPgh OR pl_ofcMD, "P", c_FaxCode)
	Do PrintField With mv, "litEmail", contactEmail
ENDIF 	
*---------------------------------------------------------------
 
IF USED( "AutoSubp")

	IF USED ('REQUEST')
		SELECT REQUEST
		USE
	ENDIF
	l_done=omed.sqlexecute(" exec dbo.GetRequestRecordbyClcode '" + fixquote(PC_CLCODE) + "'", 'Request')

	IF l_done THEN
		=CURSORSETPROP("KeyFieldList", "ID_tblRequests,Cl_code, Tag", "Request")
		INDEX ON cl_code + '*'+STR(TAG) TAG CLtag ADDITIVE
		SET ORDER TO CLtag
	ENDIF

	SELECT AutoSubp
	GO TOP
	SCAN
		SELECT REQUEST

		IF SEEK( PC_CLCODE + "*" + STR( AutoSubp.DepTag))
** Changed 5/26/98 to print Subpoenas for "Attached" Notice form
*--3/26/03 kdl start: update tag variables before call to subp_pa
			pl_GotDepo = .F.
			DO gfGetDep WITH PC_CLCODE, AutoSubp.DepTag


			IF (REQUEST.TYPE <> "A") AND NOT lCourtSet
*--3/26/03 kdl end:
**EF 02/10/05 -do not fax subps if original is requested
				LOCAL  l_c1Form AS Boolean
				l_c1Form =pl_c1Form
				l_c1Form= Rule1 () &&#59566 :

				pl_FaxSubp = IIF(l_c1Form, ll_FaxNotice,.F.)

				IF pl_FaxSubp
					szfaxnum =IIF (LEN(ALLTRIM(lc_FaxNum))<10,'',lc_FaxNum)
				ENDIF

				omed.sqlexecute("exec dbo.GetSpec_Insbyclcode '"+fixquote(PC_CLCODE)+"'", "Spec_Ins")


				DO subp_pa WITH .T., 2, AutoSubp.DepTag, .T., .F., lCourtSet,.T.
				pl_FaxSubp = .F.
			ENDIF
		ENDIF
		SELECT AutoSubp
	ENDSCAN



&&04/08/2015 MD NOTICES  need Statutory Page  4-306, 4-307 and Md service:
	IF l_BaltCase
		LOCAL C_clcode AS STRING
		C_clcode=""
		C_clcode=PC_CLCODE

		IF  l_Plaint   &&4/20/15- REMOVE THE Statutory notice from defense notice set
			mv =mv + mdPlNot(dthisdate, 	  C_clcode, IIF(l_Plaint, 'P', 'D'))
		ENDIF

		mv =mv + mdservice(	dthisdate,2)
	ENDIF

**1/31/08  print order verification separately
	IF NOT EMPTY(mv) AND NOT lCourtSet  AND  NOT  lcopyone
**EF 02/10/05 -Email Zicam Notice

		DO CASE

		CASE ll_FaxNotice AND pl_NoFaxNotice=.F.
			mclass="FaxNotice"
			pc_EmailAdd=""
			c_Addr=IIF (LEN(ALLTRIM(lc_FaxNum))<10,"",lc_FaxNum)
			c_fax = STRTRAN( c_Addr, " ", "")
			c_temp = STRTRAN( c_fax, "-", "")
			c_temp2 = STRTRAN( c_temp, "(", "")
			c_Addr = STRTRAN( c_temp2, ")", "")

&&09/30/14- do not fax to below numebr per Alec/James as new fax server cannot handel it- print instead
			IF ALLTRIM(c_Addr)='16109921405'
				c_Addr=""
				pl_NoFaxNotice=.T.

				IF  pl_MDLead AND l_BaltCase  && 6/10/15-email md lead subp notices
					mclass='ENotMDLead'
				ELSE

					mclass='Notice'
				ENDIF
			ENDIF




		CASE (ll_EmailNot OR pl_zicam ) AND NOT EMPTY(ALLTRIM(pc_EmailAdd))
			DO CASE

			CASE pl_CambAsb
				mclass='AsbCambNot'
			CASE  pl_RisPccP    AND  NVL(PSNOTICE.TYPE,'A')='A' && 11/29/16 - use the "RispNotice" for "A" only #53497
				mclass='RispNot'
			OTHERWISE &&pl_zicam
				mclass="ENotice" && defaul email notice class
			ENDCASE


**09/27/2010 EMAIL/FAX NOTICE
			c_Addr_e=pc_EmailAdd
			IF !EMPTY(NVL(pc_AtyFax,''))
				c_Addr=IIF (LEN(ALLTRIM(lc_FaxNum))<10,"",lc_FaxNum)
				c_fax = STRTRAN( c_Addr, " ", "")
				c_temp = STRTRAN( c_fax, "-", "")
				c_temp2 = STRTRAN( c_temp, "(", "")
				c_Addr = STRTRAN( c_temp2, ")", "")
			ENDIF
		OTHERWISE
			IF  pl_MDLead AND l_BaltCase  && 6/10/15-email md lead subp notices
				mclass='ENotMDLead'
				pc_EmailAdd=""
				c_Addr=""
			ELSE


				mclass='Notice' &&mclass
				pc_EmailAdd=""
				c_Addr=""
			ENDIF
		ENDCASE


		mclass = IIF(  pl_RepNotc, "RepNot" , mclass)

		pl_SkipBatchPRT=.T.
		pc_BatchRq=""

&&03/23/2016 removed  OMRPage #36180
*!*			IF pl_RepNotc OR pl_NoFaxNotice OR EMPTY(ALLTRIM(pc_EmailAdd))
*!*			&&03/08/2012 added OMRPage	- only "A" request use it
*!*				IF REQUEST.TYPE = "A"
*!*					DO OmrPage
*!*				ENDIF
*!*			ENDIF
&&03/23/2016 removed  OMRPage #36180
		IF  NOT pl_OrdVerSet && 10/22/12- SKIP IT HERE AS ORDER VERIF HAS ITS OWN ASSIGMENT TO A CLASS
**it is ok to fax again #57382 as	2/1/17
**09/29/15- PRINT NOTICES FOR PA-PHILADELPHI TILL LIZ SAYS OTHERWISE
**03/15/2017 #59568 - email pdf as an original notices for non prog till a new set is ready per Liz D.


			IF (pl_c1Form=.F. AND UPPER(pc_RpsForm)="NONPROG"  ) 	AND NOT pl_RepNotc
				mclass='FakeNot'
				c_Addr=''
			ENDIF
			
			* 02/01/2019 MD #126302 email notices
			* 02/04/2019 The area was changed from Torrey to InfectDisease
			IF ALLTRIM(UPPER(pc_litcode))=="C" AND ALLTRIM(UPPER(pc_area))==UPPER("InfectDisease")
				mclass="CTorNot"
			ENDIF  
			
			DO PrtEnQa IN ta_lib WITH mv, mclass, 	"2", c_Addr
		ENDIF


	ENDIF
	IF NOT lCourtSet
		SELECT AutoSubp
		USE
	ENDIF

ENDIF

pl_PrtNotc=.F. && EF 10/07/2010 reset back to false

RETURN
***********************************************************************************
FUNCTION getcourtdates
PARAMETERS lccl, lntg
LOCAL lcAlias AS STRING, lok AS Boolean, n_rec AS INTEGER, C_ORDER AS STRING
C_ORDER=""
lcAlias =SELECT()
lok=.T.
IF TYPE('pd_dateCourtset')<>"U"
	SELECT holdreq
	C_ORDER=ORDER()
	SET INDEX TO
	n_rec = RECNO()
	LOCATE FOR cl_code =lccl AND TAG =lntg
	IF FOUND()
		IF TTOD(Issue_Date)=pd_dateCourtset OR TTOD(waivr_date)=pd_dateCourtset
			lok=.T.
		ELSE
			lok=.F.
		ENDIF
	ELSE
		lok=.F.
	ENDIF
ENDIF
SELECT holdreq
IF !EMPTY(C_ORDER)
	SET ORDER TO (C_ORDER)
ENDIF
GO n_rec
SELECT (lcAlias)


RETURN lok

***********************************************
FUNCTION getplfirms

LOCAL cFirms AS STRING, cAlias AS STRING
STORE "" TO cFirms
cAlias=ALIAS()
omed.closealias('PlFirms')

omed.sqlexecute("exec dbo.GetPlFirms '" + fixquote(PC_CLCODE) + "'", "PlFirms")
IF USED('PlFirms')
	SELECT PlFirms
	SCAN
		cFirms=cFirms + CHR(13) +  ALLTRIM(PlFirms.PlFirmName)

		SELECT PlFirms
	ENDSCAN

ENDIF

IF NOT EMPTY(cAlias)
	SELECT (cAlias)
ENDIF


RETURN cFirms


********************************************************************************
PROCEDURE  MdMailPage      && MD notices -certified mail cover

********************************************************************************
PRIVATE  C_SAVE AS STRING
C_SAVE = SELECT()
DO PrintGroup WITH mv, "MDMailCov"
SELECT (C_SAVE)
RETURN
********************************************************************************
FUNCTION Rule1 && 03/16/2017  : #59566  -Rule#1: check for subpoena form: RT (Word)
** was considered the only one: added more to it  CASE-ENDCASE
********************************************************************************
LOCAL l_form AS Boolean
l_form=pl_c1Form
IF !pl_c1Form
	DO CASE
	CASE pl_Wcabkop
*pl_c1Form=.T.
		l_form=.T.
	CASE pl_Njsub
*pl_c1Form=.T.
		l_form=.T.
	CASE pc_RpsForm="KOPGeneric"
*pl_c1Form=.T.
		l_form=.T.	
	CASE ALLTRIM(UPPER(pc_court1))==ALLTRIM(UPPER("PA-Philadelphi"))
		* 09/12/2018 MD #103895 allow PA-Philadelphi go to email/fax
		* 09/12/2018 MD removed for the production release 
	    * 09/25/2015 MD uncommented
		l_form=.T.
	ENDCASE
ENDIF

RETURN l_form=.T.




RETURN


