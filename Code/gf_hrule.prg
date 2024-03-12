FUNCTION gf_HRule
** Calculates the number of days a request must be held in-house before it
** can be mailed to the deponent, unless a waiver is received.
** Calls: gfDtSkip, gfChkdat,
** Called from: subp_pa, waivrcvd
***************************************************************************************
** 08/09/05 EF - Add to the new RTS
** 02/10/05 EF - Add "Zicam" litigation's rules
** 04/06/04 IZ - replaced pl_litcode Public variable with local variable lc_litcode
** 03/23/04 EF - "A"-lit cases have separate rules for "Auth" and "Subp" issues
**
***************************************************************************************
PARAMETERS ldDay1, lcIsstype
** ldDay1 -- a day we start our calculation ( txn 11)
** lcIssType -- "A" for authorization; "S" for subpoena
PRIVATE lcAlias, llNoHold, ldMailDay

lcAlias = ALIAS()

pl_GotCase=.F.
DO gfgetcas

llNoHold = .F.
ldMailDay = ldDay1

llNoHold = pl_nohold
IF llNoHold
	ldMailDay = ldMailDay
ELSE
	lnHoldDays = pn_HoldSub                      &&gflookup("court", "hold", "court", tamaster.court)
	ldMailDay = GetHold( lnHoldDays)

ENDIF

IF NOT EMPTY( lcAlias)
	SELECT ( lcAlias)
ENDIF

RETURN ldMailDay
**********************************************************************
FUNCTION GetHold
PARAMETERS lnHoldDays
PRIVATE c_alias, n_days, l_Busndays, d_maildate, l_Continue, lc_litcode, lcCentury
c_alias = ALIAS()
l_Busndays = .F.
l_Continue = .F.
d_maildate = IIF (lnHoldDays=0, ldMailDay,d_today)
lc_litcode = pc_litcode
lcCentury = SET("CENTURY")
IF lcCentury <> "ON"
	SET CENTURY ON
ENDIF
SELECT HoldRulz
**#51529 - removed litigation rules for "S" when calculating a hold and comply
IF lcIsstype = "A"
	SET ORDER TO TYPEA
ENDIF
IF pc_offcode="T"
	lc_litcode="*"
ENDIF

SEEK ( pc_offcode + ALLTRIM( lc_litcode))
IF FOUND()
	DO CASE
**EF 2/10/05 'Zicam' lit -start
	CASE ALLTRIM( lc_litcode) = "ZCM"
		DO WHILE  ALLTRIM( lc_litcode) = "ZCM" AND NOT EOF()
			IF  FROMREV = pl_fromrev AND pc_AreaID = ALLTRIM( HoldRulz.areacode)
				l_Continue = .T.
			ENDIF
			SKIP
		ENDDO
**EF 2/10/05 'Zicam' lit-end
	CASE ALLTRIM( lc_litcode) = "2"
		IF pc_AreaID = ALLTRIM( HoldRulz.areacode)
			l_Continue = .T.
		ENDIF
	CASE ALLTRIM( lc_litcode) = "3"
		IF INLIST(pc_AreaID, "0145","0165")
			l_Continue = .T.
		ENDIF
	CASE ALLTRIM( lc_litcode) = "8" AND pl_fromrev
		IF pc_AreaID = ALLTRIM( HoldRulz.areacode)
			l_Continue = .T.
		ENDIF
	CASE ALLTRIM( lc_litcode)= "C"
		l_Continue = .T.
	CASE ALLTRIM( lc_litcode) = "D"
		l_Continue = .T.

	CASE ALLTRIM( lc_litcode) = "E"
		IF pl_fromrev
			l_Continue = .T.
		ENDIF
	CASE pl_ofchous AND lcIsstype="S"
		l_Continue = .T.
	CASE  ALLTRIM( lc_litcode)= "A"  AND lcIsstype="A"
&&03/23/04 we have two entries : "S" and "A" type
*!*	      do case
*!*	        case lcIsstype="A"
		l_Continue =IIF(ALLTRIM(pc_court1)=ALLTRIM(HoldRulz.court),.T.,.F.)
*!*	        otherwise

*!*	            l_Continue = IIF ("MD-" $ pc_Court1 , .F., .T.)
*!*	      ENDCASE
**7/15/16 Ripedal PCCP only gets a hold
	CASE ALLTRIM( lc_litcode)= "RPD"
		IF pc_AreaID = ALLTRIM( HoldRulz.areacode)
			l_Continue = .T.
		ENDIF
	ENDCASE
ENDIF
**Check other conditions:

IF l_Continue
	l_Busndays = HoldRulz.BusDays
	IF l_Busndays
		n_days = gfDtSkip( ldDay1, HoldRulz.Days)
	ELSE
		n_days = ldDay1 + Days
	ENDIF
	d_maildate = gfchkdat(n_days, .F., .F.)

ENDIF

********11/15/16 EDIT FOR "A" ISSUES
IF lcIsstype<>"A"
	n_days = ldDay1 +lnHoldDays
	d_maildate =gfchkdat(n_days,.F.,.F.)
ELSE
	d_maildate = IIF (l_Continue, n_days,ldDay1)
ENDIF

**EF 02/10/05 'Zicam' -start
IF pl_Zicam AND l_Continue
	pd_IssDte = gfchkdat(d_today+pn_ObjDay, .F., .F.)
	pd_MailDte = d_today
	pd_DueDte = gfchkdat(d_today+pn_ObjDay + 10, .F., .F.)
	pd_ObjDte = pd_IssDte
	d_maildate = pd_IssDte
ENDIF
**EF 02/10/05 'Zicam' -end
IF NOT EMPTY(c_alias)
	SELECT (c_alias)
ENDIF
IF NOT EMPTY(lcCentury)
	SET CENTURY &lcCentury
ENDIF

RETURN d_maildate
