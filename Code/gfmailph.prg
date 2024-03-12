**EF 12/21/05 -Added to the project
**********************************************************************************
*** gfMailph.prg - Returns the Area code or State abbreviation for a MailId
** DMA 02/18/2002 Add check on echocardiogram dept. for hospitals
** DMA 10/05/2000 Update list of toll-free area codes
**                Create internal subroutine for efficiency
** HN 02/03/98

** Called by Confirm, PhoneTxn, Subp_CA, Subp_CA, Prt2RQ

parameters lcMid, lcWhich
** lcMid: MailID of deponent being checked
** lcWhich = "A" - Check by Area code, "S" - Check by State
PRIVATE lsSQL

if empty(lcMid) or NOT INLIST( lcWhich, "A", "S")
	RETURN space(3)
endif

*DO setclasslibs
*goapp = CREATEOBJECT("appcusapp")
o = CREATE("medgeneric")
lsSQL = "select dbo.gfMailPh('" + lcMid + "', '" + lcWhich + "')"
o.sqlexecute(lsSQL, "gfMailPh")

RETURN gfMailPh.exp

** Legacy code...
*!*	private lcMailf, lcAreaCode, laEnv, lcState, llhave800, llhaveAC, ;
*!*	   c_temp1, c_temp2, c_phonestr
*!*	Dimension laEnv[1,3]

*!*	lcAreaCode = ""
*!*	lcState = ""

*!*	if empty(lcMid) or NOT INLIST( lcWhich, "A", "S")
*!*		return space(3)
*!*	endif

*!*	= gfPush(@laEnv)


*!*	lcMailf = gfMailn( lcMid)
*!*	llMailf = gfUse( lcMailf)

*!*	set order to mailid_no

*!*	if seek( lcMid)
*!*	   if lcWhich = "A"
*!*	      if lcMailf <> "MAILH"
*!*	         c_phonestr = ALLT(STR( phone))
*!*	         if len(c_phonestr)= 10
*!*	            lcAreaCode = SUBS(c_phonestr, 1, 3)
*!*	         endif
*!*	      else
*!*	         llhave800 = .f.
*!*	         llhaveac  = .f.
*!*	         *        Check for toll-free general info number at hospital
*!*	         DO AC_Test WITH Phone, llhave800, llhaveAC, lcAreaCode

*!*	         *        Check for toll-free radiology number at hospital
*!*	         if NOT llhaveAC
*!*	            DO AC_Test WITH rphone, llhave800, llhaveAC, lcAreaCode
*!*	         endif

*!*	         *        Check for toll-free pathology number at hospital
*!*	         if NOT llhaveac
*!*	            DO AC_Test WITH pphone, llhave800, llhaveAC, lcAreaCode
*!*	         endif

*!*	         *        Check for toll-free echocardiogram number at hospital
*!*	         if NOT llhaveac
*!*	            DO AC_Test WITH ephone, llhave800, llhaveAC, lcAreaCode
*!*	         endif

*!*	         *        Check for toll-free business office number at hospital
*!*	         if NOT llhaveac
*!*	            DO AC_Test WITH bphone, llhave800, llhaveAC, lcAreaCode
*!*	         endif

*!*	         if NOT llHaveAC and llHave800
*!*	            lcAreaCode = "800"
*!*	         endif
*!*	      endif
*!*	   else
*!*	      lcState = State
*!*	   endif
*!*	endif

*!*	=gfunuse(lcMailf, llMailf)

*!*	=gfPop(@laEnv)

*!*	RETURN IIF( lcWhich = "A", lcAreaCode, lcState)

*!*	PROCEDURE AC_TEST
*!*	PARAMETERS n_phone, l_have800, l_haveac, c_AreaCode
*!*	** n_phone: Numeric phone number from rolodex
*!*	** l_have800: .F. on entry; .T. on return if this is a toll-free number
*!*	** l_haveac: .F. on entry; .T. on return if this is not a toll-free number
*!*	** c_areacode: On return, contains area code if not a toll-free number
*!*	PRIVATE c_phone

*!*	c_phone = ALLT(STR(n_phone))

*!*	if len(c_phone) = 10
*!*	   if INLIST( SUBS(c_phone, 1, 3) + space(3), ;
*!*	         "800", "822", "833", "844", "855", "866", "877", "888")
*!*	      l_have800 = .T.
*!*	   else
*!*	      l_haveAC = .T.
*!*	      c_AreaCode = SUBS(c_phone, 1, 3)
*!*	   endif
*!*	endif

*!*	RETURN

*!*	RETURN 