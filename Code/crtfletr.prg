PROCEDURE CrtFLetr
	** EF 05/15/06 - added to the project.
	*****************************************************************************
	** Court filing Letter for Receipt of Records
	** 06/10/04 DMA Use public set of laser-printer codes
	** 05/10/04 DMA Use global variables when available
	** 01/25/02 HN  Created for Texas Reprints	*
	*   Called by GenUtils
	*   Assumes that gfGetCas has already been called
	******************************************************************************
	SET NEAR ON
	PRIVATE lcCrtType, c_clerk, c_lastline
 	PUBLIC lc_Item1,lc_Item2,lc_Item3,lc_Item4,lc_Item5,lc_Item6,lc_Item7,lc_Item8, ;
 	lc_Item9,lc_Item10,lc_Item11,lc_Item12,lcCause, LcDocket, c_today, lcRT
 	STORE "" TO lc_Item1,lc_Item2,lc_Item3,lc_Item4,lc_Item5,lc_Item6,lc_Item7,lc_Item8, ;
 	lc_Item9,lc_Item10,lc_Item11,lc_Item12,lcCause, LcDocket, c_today, lcRT
	WAIT WINDOW "Printing Court Filing Letter for Receipt of Records." NOWAIT NOCLEAR 
	C_ALIAS=ALIAS()
	SET PRINTER TO LPT1
	SET PRINTER ON
	SET CONSOLE OFF
	c_clerk = ""
	c_lastline = ""
	mRDist = UPPER( ALLTRIM( pc_distrct))
	szLine1 = ""
	szLine2 = ""
	szLine3 = ""
	szLine4 = ""
	szLine5 = ""
	szLine6 = ""
	c_lastline = ALLT( pc_c1City) + ", " + pc_c1State + " " + pc_c1Zip
	DO CASE

		CASE pc_TxCtTyp = "FED"
			c_clerk = "FEDERAL CLERK"
			szLine1 = pc_TxCtLn1
			szLine2 = pc_TxCtLn2
			IF ALLTRIM( pc_Court2) == "US-DOL"
				szLine3 = pc_c1Addr1
				IF NOT EMPTY( pc_c1Addr2)
					szLine4 = pc_c1Addr2
					szLine5 = c_lastline
				ELSE
					szLine4 = c_lastline
				ENDIF
			ELSE
				szLine3 = pc_TxCtLn3
				szLine4 = pc_c1Addr1
				IF NOT EMPTY( pc_c1Addr2)
					szLine5 = pc_c1Addr2
					szLine6 = c_lastlint
				ELSE
					szLine5 = c_lastline
				ENDIF
			ENDIF

		CASE pc_TxCtTyp = "CCL"
			c_clerk = "COUNTY CLERK"
			szLine1 = ALLT( pc_plCnty) + " County Courthouse"
			szLine2 = pc_c1Addr1
			IF NOT EMPTY( pc_c1Addr2)
				szLine3 = pc_c1Addr2
				szLine4 = c_lastline
			ELSE
				szLine3 = c_lastline
			ENDIF

		CASE pc_TxCtTyp = "DIS"
			c_clerk = "DISTRICT CLERK"
			szLine1 = ALLT( pc_plCnty) + " County Courthouse"
			szLine2 = pc_c1Addr1
			IF NOT EMPTY( pc_c1Addr2)
				szLine3 = pc_c1Addr2
				szLine4 = c_lastline
			ELSE
				szLine3 = c_lastline
			ENDIF
	ENDCASE

	c_today =DTOC(DATE())
	IF NOT EMPTY(szLine1)
		lc_Item1= szLine1
	ENDIF
	IF NOT EMPTY(szLine2)
		lc_Item2= szLine2
	ENDIF
	IF NOT EMPTY(szLine3)
		lc_Item3= szLine3
	ENDIF
	IF NOT EMPTY(szLine4)
		lc_Item4= szLine4
	ENDIF
	IF NOT EMPTY(szLine5)
		lc_Item5= szLine5
	ENDIF
	IF NOT EMPTY(szLine6)
		lc_Item6= szLine6
	ENDIF
	lcRT =pc_lrsno + "." + ALLTRIM(STR(timesheet.TAG))
	lc_Item7= "ATTN: " + c_clerk
	lcCause = "Recordtrak #: " + lcRT
	lcdocket ="Case No: " + pc_docket

	lc_Item10= "Records Pertaining To: " + pc_plnam
	lc_Item8= "Dear Sirs or Madams:"
	lc_Item9= "Please file the attached Officer's Certification and Answers to " ;
		+ " Written Deposition in reference to the above styled case."
	lc_Item11= "Deposition Of: " + ALLTRIM(timesheet.DESCRIPT)

	lc_Item12= "Thank you for your assistance.  If there are any questions," ;
		+ " please contact RECORDTRAK at (713) 655-1800."
	SET PRINTER ON
	lcprinter=GETPRINTER()
	IF !EMPTY(lcprinter)
		SET PRINTER TO NAME (lcprinter)
	ENDIF

	REPORT FORM txofcert &&RANGE 1 , 1

	SET CONSOLE ON
	SELECT (C_ALIAS)
	WAIT CLEAR
