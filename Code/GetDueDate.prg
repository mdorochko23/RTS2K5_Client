************************************************************************************************
**8/25/09 : Calculates a request's due date based on the business rules, assumes the gfgetcas
** was called and all teh public vars are set
***********************************************************************************************
FUNCTION GetDueDate
PARAMETERS d_Maildate,  d_today ,c_IssType, d_BusOnly, n_Comply, n_Hold, l_reprint, l_1streq
LOCAL ld_Duedate AS DATE, ldBusOnly AS DATE, ld_mail AS DATE , l_CookSub as Boolean
**3/3/11 added pl_Rispccp
** 09/21/2016 -added IL-Cook  to a busness days group
DO CASE
CASE  TYPE("d_Maildate") ="C"
	ld_mail=CTOD(d_Maildate)
CASE TYPE("d_Maildate") ="T"
	ld_mail=TTOD(d_Maildate)
OTHERWISE
	ld_mail=d_Maildate
ENDCASE

IF (c_IssType="A"  AND n_Hold<>0) OR (c_IssType="A" )
	n_Comply=10
ENDIF
l_CookSub=.f.
l_CookSub=IIF((c_IssType="S" and PL_ILCOOK), .t.,.f.)

DO CASE
CASE l_1streq
	ld_Duedate = IIF( pl_MichCrt OR pl_NJSub OR pl_CambAsb OR pl_Rispccp , d_BusOnly,  d_today)  + IIF(n_Comply=0,10,n_Comply)

CASE l_reprint
	ld_Duedate = IIF( pl_MichCrt OR pl_NJSub OR pl_CambAsb OR pl_Rispccp  ,d_BusOnly,  ld_mail)  + IIF(n_Comply=0,10,IIF(n_Hold=0,10,n_Hold))

OTHERWISE && SECOND REQUEST

	ld_Duedate = IIF( pl_MichCrt OR pl_NJSub OR pl_CambAsb OR pl_Rispccp   ,d_BusOnly,  ld_mail)  + n_Comply

ENDCASE


DO CASE
CASE  l_1streq

	IF c_IssType = "A" AND (pl_PropNJ OR pl_PropPA OR pl_Rispccp  )
		ld_Duedate = gfChkDat( ld_Duedate, .F., .F.)
	ENDIF
	IF ( pl_MichCrt OR pl_NJSub OR pl_CambAsb )
		ld_Duedate=	d_BusOnly
	ENDIF
	IF pl_zicam
		IF TYPE('pd_Duedte')<>"U"
			ld_Duedate  = pd_Duedte
		ENDIF
	ENDIF

CASE l_reprint
	DO CASE
	
	 
	CASE pl_baycol AND pl_FromRev
		ld_Duedate = ld_mail + 10
	CASE pl_MdlHold
		ld_Duedate = ld_mail + 10
	CASE pl_zicam
		IF timesheet.Txn_code=11
**  Zicam reprint -start
			ld_Duedate = pd_Duedte
		ELSE
&& Reprint of the sec. request
			ld_Duedate = ld_mail + IIF( llFromRev,;
				IIF( gnFRDays>0, gnFRDays, 10 ), ;
				IIF( gnIssDays>0, gnIssDays, 10))
		ENDIF

	OTHERWISE
		IF n_Hold<>0
			ld_Duedate = ld_mail  + n_Hold
		ENDIF
	ENDCASE

	IF (pl_PropPA OR pl_PropNJ)
		IF  c_IssType <> "S"          && 1/10 Propulsid subpoenas issues vs.auth.

			ldBusOnly = ld_mail
			FOR i = 0 TO 13
				ldBusOnly = ldBusOnly + 1
				ldBusOnly = gfChkDat( ldBusOnly, .F., .F.)
			NEXT
			dduedate = ldBusOnly
			duedate = dduedate + 10
		ENDIF
	ENDIF


ENDCASE

ld_Duedate = gfChkDat( ld_Duedate, .F., .F.)

RETURN ld_Duedate
