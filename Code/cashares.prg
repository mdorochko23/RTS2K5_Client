PROCEDURE CASHARES
	* 05/03/06 EF Added to the project.
	*************************************************************************
	* Called by Plaintif
	* 03/21/05  DMA  Add "Date_Out >= A.Date_In to current-participant
	*                select statment to cover situations where client
	*                comes in and out of case repeatedly
	* 07/29/04  DMA  Change inner select for current participants to
	*                be round-specific (BB_Combo + Round_ID, rather than
	*                just BB_Combo) for accuracy
	* 02/16/04  DMA  Display combined results for docket and ASB #
	* 02/11/04  KDL  Added push key clear to ensure that ESC key is available
	* 01/09/04  DMA  Remove filtering; file now pre-cleaned
	* 11/20/03  DMA  Filter out inappropriate Newshares entries
	* 10/14/03  DMA  Automated re-opening of closed cases.
	*                Use new Share file for participant information
	* 02/07/03  DMA  Add summary-list option
	* 01/14/02  DMA  Change F3 search to use firm name, not attorney name
	* 10/02/01  DMA  Ensure release of window definition
	* 09/18/01  DMA  3-char litigation codes
	* 10/05/99  DMA  Y2K update
	*
	PARAMETERS n_ViewMode, c_KeyValue
	PRIVATE szWait, c_deleted, n_viewtype, omedca as Object

	omedca =CREATEOBJECT("medmaster")
	omedca .getitem(c_KeyValue)

	pl_GotCase = .F.
	DO gfgetcas WITH .T.
	
	DO CASE

			* Display all participants
		CASE n_ViewMode = 1			

			l_Cancel=goapp.OpenForm("generic.frmcashare", "M", .T.,.T.)

		CASE n_ViewMode= 2			

			l_Cancel=goapp.OpenForm("generic.frmcashare", "M", .F.,.F.)

	ENDCASE
	IF l_Cancel
	   RETURN
	endif
RELEASE omedca 
	RETURN

	*!*****************************************************************************

PROCEDURE brv
	PARAMETERS p_rec, p_window
	IF UPPER(WONTOP())==UPPER(p_window) AND LASTKEY()<>27
		p_rec=0
	ENDIF
	RETURN .T.

	*!*****************************************************************************

PROCEDURE brw
	cur_rec=RECNO()
	RETURN


	*!*****************************************************************************

PROCEDURE PrintLst
	n_record = RECNO()
	SET PRINTER ON
	SET CONSOLE OFF
	*SET PRINTER TO LPT1:
	? ""
	? " Active Participating Attorneys for RT # " + pc_lrsno ;
		+ " [" + ALLT(pc_plbbASB) + " / " + ALLT( pc_BBDock) + "]"
	?
	? "Attorney" AT 5
	?? "Firm" AT 30
	?? "Defendant" AT 80
	? "-----------------------------------------------------------------------------------------------------------------------------------------"
	?
	GO TOP
	SCAN
		? SUBS( at_code, 1, 10) + SPACE(15) + SUBS( Firmname, 1, 38) + "  " + SUBS( Def_name, 1, 25) AT 5
	ENDSCAN
	EJECT
	SET CONSOLE ON
	SET PRINTER OFF
	SET PRINTER TO
	GO n_record
	RETURN
