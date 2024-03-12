PROCEDURE Del_Rcpt
	**EF 05/01/06 -Added to the VFP project.
	*********************************************************************
	* 04/04/06 EF  Added this functionality to the 'Pasadena' office.
	* 10/05/04 IZ  Add wording to every receipt by Mark's request
	* 06/10/04 DMA Use PUBLIC set of laser-printer codes
	* 02/19/04 kdl Add condition when no name is entered for the attorney code
	* 07/25/03 DMA Update PSNotice.Service automatically
	* 02/13/01 DMA Switched to use attyfirm routine for recipient selection
	* 02/05/01 DMA Switched to use desktop printer, not network
	* 01/05/01 DMA Integrated into RTS V6.00 Utilities Menu
	* Taken from Old Oakland TA system for use with RTS 6.x
	*
	* Calls AttyFirm, gfLastAddr, gfEntryN
	*
	PUBLIC lcID, lcA1, lcA2, lcA3, lcA4, lcA5
	PRIVATE dbInit, scrn, szYN, c_exact, c_near, n_ok, lnRT, lnTag, szEntry, ;
		_cFile,  c_clcode, c_clstart, ;
		c_attyordr, c_cityline, lcATCode, n_continue, c_key
	LOCAL lcName, lcCode
	n_continue = 0
	c_cityline = ""
	c_attyordr = ""
	c_key = ""
	dbInit = SELECT()
	c_exact = SET("EXACT")
	c_near = SET("NEAR")
	SET EXACT OFF
	SET NEAR ON


	CREATE CURSOR w_recs (rt N(8), TAG C(3), DESCRIPT C(50), OTHER C(10), lrs_nocode C(1))
	lcATCode = ""

	lcform=CREATEOBJECT("Client.frmClientSearch", "M", "", "")
	lcform.SHOW
	lcName=lcform.SelectedName
	lcATCode=lcform.selectedCode
	RELEASE lcform
	IF NOT EMPTY(lcATCode)

		l_ok=goApp.OpenForm("generic.frmdel_rcpt", "M", lcATCode,lcATCode)

		c_Today = DTOC(d_Today)
		lcID =  c_Today+ TIME()

		IF  NOT l_ok
			RETURN
		ENDIF
		l_ok=.F.

		l_ok =goApp.OpenForm("generic.frmDelRPick", "M", lcATCode,lcATCode)
		ogen=CREATEOBJECT('medgeneric')

		DO AddBump



		SELECT w_recs
		IF RECCOUNT("w_Recs") > 0

			FOR l = 1 TO 2
				REPORT FORM delrcpt TO PRINTER NOCONSOLE
				SELECT w_recs
				GO TOP
				SCAN
					IF l=1
						c_str="Exec dbo.InsertDeliveryRcpt '" ;
							+ STR(w_recs.rt) + "','" ;
							+ w_recs.TAG + "','" ;
							+ lcATCode + "','" ;
							+ w_recs.OTHER + "','" ;
							+ lcID + "','" ;
							+ ALLTRIM(pc_UserID) + "'"
						l_AddRec=ogen.sqlexecute(c_str,"")

						IF NOT   l_AddRec
							gfmessage(" Cannot insert a record into the tblDel_rcpt. Note the RT # and Tag # and contact IT dept.")
						ENDIF

						SELECT w_recs
					ENDIF
				ENDSCAN


			NEXT l
			SET CONSOLE ON
			SET PRINTER OFF
			SET PRINTER TO
		ENDIF
		SELECT w_recs
		USE

	ENDIF
	SET EXACT &c_exact
	SET NEAR &c_near
	RETURN

	******************************
PROCEDURE AddBump
	*
	* "Bumps" up used address lines into empty slots, if any
	DO WHILE EMPTY(lcA1) AND NOT EMPTY(lcA2+lcA3+lcA4+lcA5)
		lcA1 = lcA2
		lcA2 = lcA3
		lcA3 = lcA4
		lcA4 = lcA5
		lcA5 = SPAC(40)
	ENDDO
	DO WHILE EMPTY(lcA2) AND NOT EMPTY(lcA3+lcA4+lcA5)
		lcA2 = lcA3
		lcA3 = lcA4
		lcA4 = lcA5
		lcA5 = SPAC(40)
	ENDDO
	DO WHILE EMPTY(lcA3) AND NOT EMPTY(lcA4+lcA5)
		lcA3 = lcA4
		lcA4 = lcA5
		lcA5 = SPAC(40)
	ENDDO
	IF EMPTY(lcA4) AND NOT EMPTY(lcA5)
		lcA4 = lcA5
		lcA5 = SPAC(40)
	ENDIF
	RETURN
