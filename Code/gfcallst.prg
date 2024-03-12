**EF 12/21/05 -switched to sql
************************************************************************
** gfCallst.prg - Returns the type of call 1-LD, 2-Local, 0-Undetermined
**  based on State Abbreviation and Office passed.
** Called by PhoneTxn, Confirm, Subp_PA
** HN 02/04/98

parameters lcState, lcOffice
** PCL: Legacy code; no longer needed.
*!*	private lncalltype, laEnv, llOffice
*!*	Dimension laEnv[1, 3]
PRIVATE lsSQL

*DO setclasslibs
*goapp = CREATEOBJECT("appcusapp")
o = CREATE("medgeneric")

lsSQL = "select dbo.gfCallSt('" + lcState + "', '" + lcOffice + "')"

o.sqlexecute(lsSQL, "gfCallSt")

RETURN gfCallSt.exp

*!*	lcState = alltrim(lcState)
*!*	if len(lcState)<> 2 or empty(lcOffice)
*!*	return 0
*!*	endif

*!*	lncalltype = 0

*!*	=gfPush(@laEnv)
*!*	llOffice = gfUse("Office")
*!*	locate for alltrim(upper(code))==alltrim(upper(lcOffice))
*!*	if found()
*!*	   if office.state <> lcState
*!*	      lnCallType = 1
*!*	   endif
*!*	endif

*!*	=gfunuse("Office",llOffice)
*!*	=gfPop(@laEnv)
*!*	return lncalltype
