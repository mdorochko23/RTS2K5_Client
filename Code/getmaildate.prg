*********************************************
FUNCTION GetMailDate
PARAMETERS ld_reqdate, ld_BusOnly, ld_today, ln_Hold, ld_txndate,llFromRev, lc_Type ,l_1st_Req, l_reprint
PRIVATE ld_Maildate AS DATE, d_Maildate AS DATE
IF DTOC(ld_reqdate)="01/01/1900"
	ld_reqdate=ld_today
ENDIF
**3/3/2011-added pl_Rispccp
**01/15/16- Edited count to 4 for the RISPPPCP 
ld_Maildate=NVL(ld_reqdate,ld_today)



DO CASE
CASE l_1st_Req
	pd_IssDte=DATE()


	IF ln_Hold<>0 AND lc_Type="S"
		ld_Maildate = gfChkDat(ld_today + ln_Hold,.F.,.F.)
	ENDIF

	DO CASE
	CASE lc_Type = "A"
		l_BaycolFR = pl_baycol AND pl_FromRev
		l_PropSubp = .F.
		ld_Maildate = ld_today + IIF( llFromRev, gnFRDays, gnIssDays)

		ld_BusOnly = ld_today
		FOR i = 0 TO IIF (pl_Rispccp, 4,13)
			ld_BusOnly = ld_BusOnly + 1
			ld_BusOnly = gfChkDat( ld_BusOnly, .F., .F.)
		NEXT
		DO CASE
		CASE pl_Rispccp
			ld_Maildate = ld_BusOnly

		CASE pl_PropPA OR pl_PropNJ
			ld_Maildate = ld_BusOnly

		CASE pl_DietDrg OR pl_MdlHold
			ld_Maildate= ld_Maildate+ 15

		CASE l_BaycolFR
			ld_Maildate = ld_Maildate+ 10

		ENDCASE
		IF pl_zicam
			ld_Maildate = pd_IssDte
		ENDIF
	ENDCASE
CASE l_reprint

	DO CASE

	CASE pl_baycol AND llFromRev
		LD_MAILDATE = LD_TXNDATE + ( GNFRDAYS + 10)


	CASE PL_MDLHOLD
**EF 01/20/04 Use an original issue dates for reprints
		LD_MAILDATE = LD_TXNDATE +IIF( LLFROMREV, GNFRDAYS, GNISSDAYS)+15

	CASE PL_ZICAM
		IF TIMESHEET.TXN_CODE=11
**EF 02/10/05 Zicam reprint -start
			D_MAILDATE = PD_ISSDTE
			LD_MAILDATE = PD_ISSDTE
		ELSE
&&12/27/05 Reprint of the sec. request
			LD_MAILDATE = LD_TXNDATE + IIF( LLFROMREV, GNFRDAYS, GNISSDAYS)

		ENDIF

	OTHERWISE
		LD_MAILDATE = IIF(LD_TXNDATE<>ld_Maildate,ld_Maildate,LD_TXNDATE) + IIF( LLFROMREV, GNFRDAYS, GNISSDAYS)

	ENDCASE

	IF (PL_PROPPA OR PL_PROPNJ)
		IF  lc_IssType <> "S"          && 1/10 Propulsid subpoenas issues vs.auth.
			d_Maildate = ld_txndate+ IIF( llFromRev, gnFRDays, gnIssDays)
			ld_Maildate = gfChkDat( d_Maildate, .F., .F.)
		ENDIF
	ENDIF
	IF pl_zicam
		ld_Maildate = pd_IssDte
	ENDIF

OTHERWISE
**sec req
	IF pl_zicam
		ld_Maildate = d_today


	ENDIF

ENDCASE





RETURN ld_Maildate
