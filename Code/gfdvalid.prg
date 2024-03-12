FUNCTION gfDValid
* Date Validation Routine
*   Tests to confirm that a date is within a specific range
*   Can be used in conjunction with gfChkDat to also review
*   whether or not a date falls on a holiday.
*
*   Called by: PhotEdad, Taattvue, TABills, DepStat, CasePick,
*              CaseInfo, Invoice, XRayEdAd, GetPlt,
*              ChkDetl.spr, EditComm.spr, ACWitFee.spr, AttCharg.spr,
*              DupCase2.spr, Add6Txn.spr, BBCovLet.spr, WitFee.spr,
*              CaseInst.spr, Receive.spr, Caseinfo.spr, WitFee2.spr,
*              CaseFlt2.spr, DueDate.spr, NewCover.spr,
*              CovLet.spr, NoRecv.spr, Incompl.spr, CloseReq.spr,
*              CourFee.spr, ExpReq.spr, Confirm.spr, Add30Txn.spr,
*              Add51Txn.spr, Add27Txn.spr, PhoneTxn.spr, CaSubpQu.spr,
*              EditEnt.spr, Paraleg.spr, MemoTxn.spr, OrigSubp.spr,
*              ACPkDate.spr, NoLocTxn.spr, ODate.spr, DDate.spr,
*              NoRecv_C.spr, NoResp.spr, CaCivil0.spr, CASer.spr,
*              SameAs.spr, MemoCase.spr, MemoTag.spr, NRSCat.spr,
*
PARAMETERS l_chardate, d_testme, c_chardate, d_lower, d_upper
LOCAL n_Parms
n_Parms = PCOUNT()
*
* PARAMETERS
*
*  l_chardate -- .T. if date to be examined is in character format
*                .F. if date to be examined is in date format
*
*  d_testme   -- Date to be examined, in date format
*
*  c_chardate -- OPTIONAL unless l_chardate = .T.
*                Date to be examined, in character-string format
*
*  d_lower    -- OPTIONAL
*                Lowest possible value for the date being tested.
*                If omitted, defaults to the date the company was founded.
*
*  d_upper    -- OPTIONAL
*                Highest possible value for the date being tested.
*                If omitted, defaults to January 1, 2010
*

*--1/2/18: remove hard-coded "upper" date. use current date as default if no upper date provided. [76538]
IF n_Parms < 5
	d_upper = DATE()
*--	d_upper = CTOD('01/01/2018')
ENDIF
IF TYPE ('d_upper')="D"
	IF DTOC(d_upper)= "  /  /  "
		d_upper = DATE()
*--		d_upper = CTOD('01/01/2018')
	ENDIF
ENDIF

IF n_Parms < 4
	IF TYPE('d_founded')="U"
		d_lower = DATE(1975, 01, 01)
	ELSE
		d_lower = d_founded
	ENDIF

ENDIF
IF n_Parms < 3 AND l_chardate
	RETURN .F.
ENDIF
IF n_Parms < 2
	RETURN .F.
ENDIF
*
*  If the date is in character-string format, check that it has a
*  four-digit year and properly formatted. Then, convert it to a
*  date and proceed with other checks. Note that if we get an
*  empty result on conversion, the date was invalid.
*
IF l_chardate
	IF EMPTY( c_chardate) OR c_chardate = "  /  /  "
		RETURN .T.
	ENDIF
	IF LEN( ALLT( c_chardate)) < 10 OR ;
			SUBS(c_chardate, 3, 1) <> "/" OR ;
			SUBS(c_chardate, 6, 1) <> "/"
		o_message = CREATEOBJECT('rts_message',"This date must be in the format mm/dd/yyyy.")
		o_message.SHOW
		RELEASE o_message
		RETURN .F.
	ENDIF
	d_testme = CTOD( c_chardate)
	IF EMPTY( d_testme)
		o_message = CREATEOBJECT('rts_message',c_chardate + " is not a valid date.")
		o_message.SHOW
		RELEASE o_message

		RETURN
	ENDIF
ENDIF

IF EMPTY(d_testme)
	RETURN .T.
ENDIF


IF d_testme < d_lower
	o_message = CREATEOBJECT('rts_message',"This date must be on or after " + DTOC(d_lower) + ".")
	o_message.SHOW
	RELEASE o_message
*--   =MESSAGEBOX("This date must be on or after " + DTOC(d_lower) + ".",0+16)
	RETURN .F.
ENDIF
IF d_testme > d_upper
	o_message = CREATEOBJECT('rts_message',"This date must be on or before " + DTOC(d_upper) + ".")
	o_message.SHOW
	RELEASE o_message
*--   =MESSAGEBOX("This date must be on or before " + DTOC(d_upper) + ".",0+16)
	RETURN .F.
ENDIF
RETURN .T.
