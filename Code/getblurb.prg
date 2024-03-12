PROCEDURE GetBlurb
	* GetBlurb.prg - Pick blurbs (detailed specifications of the required
	*                records) from a list of pre-designed request texts
	*                pre-selected based upon appropriateness for the
	*                office, area, litigation, and type of deponent.
	***************************************************************************
	** 07/09/04  DMA    Replace gsCertType with pc_CertTyp, lsCertType w/c_certtype
	** 06/02/03  DMA    Use logicals to identify RTS version
	** 02/04/03  IZ     Removes CertOrdr out of cycle, fixes CertOrdr
	** 07/23/02  DMA    Add error message and handler for situation w/no blurbs
	** 06/25/02  EF     Get order for certs
	** 01/10/02  DMA    Add pre-selection by area and office codes
	** 09/12/01  EF     3-char. litigation code
	** 10/16/00  DMA/EF Updated to handle cert types
	***************************************************************************
	**  Called by Subp_PA
	**  Calls gfShowF2, gfUse, gfUnUse
	**  Uses screen GetBlurb
	**  Internal routines lpVBlurb, lpWBlurb are called from GetBlurb screen
	**
	LOCAL llSpec1, lnMemoW, c_CertType, n_blurb, n_picked, c_count, ;
		c_nextline, n_blurbs, n_blurb, n_line

	DIMENSION laBlurb[1, 3]
	*
	*   laBlurb[n, 1]  -> Summary line describing blurb, incl. certification
	*   laBlurb[n, 2]  -> Record number of blurb in Spec1 file
	*   laBlurb[n, 3]  -> .T. if blurb is selected for use
	*
	llSpec1 = gfuse( "Spec1")
	lnMemoW = SET( "MEMOWIDTH")

	* When assembling requests, assume maximum display/print line length of
	* 68 characters. For non-CA requests, first four chars are request
	* number or matching indentation.

	* 06/02/03 DMA Switch to logical vbl.
	SET MEMOWIDTH TO IIF( pl_CAVer, 68, 64)
	SELECT 0
	n_picked = 0
	n_blurbs = 0

	* Build display array of blurbs that are appropriate to the case's
	* litigation, area, office, and deponent type.

	SELECT Spec1
	SET ORDER TO ReqScrLine
	GO TOP
	SCAN
		IF NOT Spec1.All_Rolos
			IF AT( pc_deptype, Spec1.RoloType) = 0
				LOOP
			ENDIF
		ENDIF
		IF NOT Spec1.All_Office
			IF AT( pc_offcode, Spec1.Offices) = 0
				LOOP
			ENDIF
		ENDIF
		IF NOT Spec1.All_Lits
			IF AT( pc_litcode, Spec1.Litigation) = 0
				LOOP
			ENDIF
		ENDIF
		IF NOT Spec1.All_Areas
			IF AT( pc_AreaID, Spec1.Areas) = 0
				LOOP
			ENDIF
		ENDIF
		n_blurbs = n_blurbs + 1
		DIMENSION laBlurb[n_blurbs, 3]
		laBlurb[n_blurbs, 1] = CHR( n_blurbs + IIF( n_blurbs <= 26, 64, 70)) + ;
			" - " + Spec1.ReqScrLine + " -"  + Spec1.CertType
		laBlurb[n_blurbs, 2] = RECNO()
		laBlurb[n_blurbs, 3] = .F.
	ENDSCAN

	m.blurbch = 1
	m.GetBlurb = 1
	STORE "" TO blrbtext, SELTEXT, szrequest, c_CertType
	* 07/23/02 DMA handler for no-blurb situation
	IF n_blurbs = 0
		gfmessage( "There are no blurbs available for this combination" + ;
			CHR( 13) + "of litigation, area, rolodex, and issuing office." + ;
			CHR( 13) + "Contact supervisor or IT Dept. for assistance.")
		l_cancel = .T.
		=gfunuse( "Spec1", llSpec1)
		SET MEMOWIDTH TO lnMemoW
		RETURN
	ENDIF
	ON KEY LABEL "SPACEBAR" ;
		DO lpVBlurb
	ON KEY LABEL "F3" ;
		DO gfshowf2
*!*		DO GetBlurb.spr
	ON KEY LABEL "SPACEBAR"
	ON KEY LABEL "F3"
	IF m.GetBlurb = 2
		l_cancel = .T.
		szrequest = ""
	ELSE
		c_CertType = ""
		pc_CertTyp = ""
		l_cancel = .F.

		* Build the full text of the selected blurbs into a single string
		* for storage as the request's special instructions.

		FOR n_blurb = 1 TO n_blurbs
			IF laBlurb[n_blurb, 3]
				GOTO laBlurb[n_blurb, 2]
				n_picked = n_picked + 1
				FOR n_line = 1 TO MEMLINES( Spec1.ReqText)

					*  For non-California cases, each line of request text is
					*  preceeded by request number or matching indentation

					IF NOT pl_CAVer
						c_count = ALLT( STR( n_picked))
						szrequest = szrequest ;
							+ IIF( n_line = 1, c_count + ". ", ;
							SPACE( LEN( c_count) + 2))
					ENDIF

					* Append next line of currently-selected request, plus cr/lf

					szrequest = szrequest + ;
						ALLT( MLINE( Spec1.ReqText, n_line)) + pc_eol
				ENDFOR

				* Note certification type for selected request

				c_CertType = c_CertType + Spec1.CertType
				pc_CertTyp = c_CertType
			ENDIF
		ENDFOR
	ENDIF
	n_certs = LEN( pc_CertTyp)
	icnt = 1

	*
	*  Remove any duplicate certification types from cert. list
	DO WHILE .T.
		IF icnt > n_certs
			EXIT
		ENDIF
		lsDbl = SUBSTR( pc_CertTyp, icnt, 1)
		lsDbl2 = STRTRAN( pc_CertTyp, lsDbl, "", 2, 1)
		lsCert = SUBSTR( lsDbl2, icnt, 1)
		pc_CertTyp = lsDbl2

		icnt = icnt + 1
	ENDDO
	** 02/04/03 IZ moves cert. type order (CertOrdr function) out of cycle,
	** because string is already supressed

&&EF 6/25/02 get order for certs
	*   pc_CertTyp = CertOrdr(pc_CertTyp)
&&--
	= gfunuse( "Spec1", llSpec1)
	szrequest = ALLTRIM( szrequest)
	SET MEMOWIDTH TO lnMemoW
	RETURN
	*****************************************
PROCEDURE lpWBlurb
	* Display full text of a single blurb in window
	SELECT Spec1
	GOTO laBlurb[m.blurbch, 2]
	blrbtext = Spec1.ReqText
	SHOW GETS
	RETURN
	*****************************************
PROCEDURE lpVBlurb
	*  Invert selection status of current blurb, then build
	*  and display the combined text of all currently-selected blurbs
	LOCAL i
	SELECT Spec1
	laBlurb[m.blurbch, 3] = NOT laBlurb[m.blurbch, 3]
	SELTEXT = ""
	FOR i = 1 TO n_blurbs
		IF laBlurb[i, 3]
			SELTEXT = SELTEXT + laBlurb[i, 1] + pc_eol
			GOTO laBlurb[i, 2]
		ENDIF
	ENDFOR
	SHOW GETS
	RETURN
	***************************************************************
PROCEDURE CertOrdr
	PARAMETERS lcCerttype
	* Place "R" certificate, if any, at front of certificate list
	LOCAL lcstr1, lcstr2, lcResult, lnat
	STORE "" TO lcstr1, lcstr2, lcResult

	****** IZ 02/04/03 removed old code
	*lncnt = LEN( lcCerttype)
	*FOR i = 0 TO lncnt-1
	*   lcstr1 = ""
	*   lcstr1 = SUBSTR( lcCerttype, i+1, 1)
	*   IF lcstr1 = "R"
	*      lcstr1 = STRTRAN( lcCerttype, 'R', '', 1, 2)
	*      lcstr2 = "R" + lcstr1
	*      lcResult = ""
	*      EXIT
	*   ELSE
	*      lcstr2 = lcstr1
	*   ENDIF
	*NEXT

	** IZ 02/04/03 writes new code

	lnat = AT("R",lcCerttype)

	IF lnat <> 0
		lcstr1 = LEFT(lcCerttype, lnat-1)
		lcstr2 = SUBSTR(lcCerttype, lnat+1)
		lcResult = "R" + lcstr1 + lcstr2
	ELSE
		lcResult = lcCerttype
	ENDIF

	RETURN lcResult
	**********************************
