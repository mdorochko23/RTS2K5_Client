FUNCTION CHKYY
	*  Used by the following Screens in VALID clauses:
	*     CaseInfo, cacasein
	*** Checks the year of the date for validity
	*
	* 02/01/00  DMA  Remove gly2k references
	* 10/04/99  DMA  Y2K
	PARAMETERS chrdate
	PRIVATE chrcvt, MDY

	n_datelen = 4

	** Accepts a field name or variable name containing a string
	** of date type data.
	IF TYPE(chrdate) = "C"
		chrcvt = &chrdate
		IF chrcvt = "  /  /  " OR EMPTY(chrcvt)
			RETURN .T.
		ELSE
			IF LEN(ALLTRIM(chrcvt))<10
				RETURN .F.
			ENDIF
			MDY = CTOD("01/01/" + SUBSTR(chrcvt, 7, 4) )
			IF EMPTY(MDY)
				RETURN .F.
			ELSE
				IF NOT BETWEEN( VAL( SUBS( chrcvt, 7, 4)), 1850, 2050)
					RETURN .F.
				ENDIF
			ENDIF
		ENDIF
	ELSE
		RETURN .T.
	ENDIF
