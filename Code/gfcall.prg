*** gfCall.prg - Returns the type of outgoing call
***    1-LD, 2-Local, 0-can't tell, must ask user
**************************************************************************
** PCL 04/29/2005 Re-write, migrated to SQL Server.  Parameters lcArea
**		and lcLit are no longer utilized, but are included for legacy.
** EF  09/12/2001 3-char. litigation code
** DMA 10/06/2000 Expand number of "local" area codes in Office.dbf to 10
** DMA 10/05/2000 Add complete list of US toll-free area codes.
** HN 02/04/98
**************************************************************************
** Called by Confirm, PhoneTxn, SubP_PA

parameters lcAreacode, lcOffice, lcArea, lcLit
private llLocalac
private lncalltype, laEnv, llOffice
PRIVATE lsSQL
Dimension laEnv[1,3]

*DO setclasslibs
*goapp = CREATEOBJECT("appcusapp")
o = CREATE("medgeneric")

lsSQL = "select dbo.gfCall('" + lcAreaCode + "', '" + lcOffice + "', '" + lcArea + "', '" + lcLit + "')"

o.sqlexecute(lsSQL, "gfCall")

RETURN gfCall.exp

*!*	lcAreaCode = alltrim(lcAreaCode)
*!*	if len(lcAreaCode)<> 3 or empty(lcOffice)
*!*		return 0
*!*	endif

*!*	if INLIST(lcAreaCode, "800", "822", "833", "844", "855", "866", "877", "888")
*!*	return 2
*!*	endif

*!*	lncalltype = 0

*!*	=gfPush(@laEnv)
*!*	* Look up office code in Office.dbf.
*!*	* Then see if the area code is in the list of "local" codes for the office.
*!*	llOffice = gfUse("Office")
*!*	SET ORDER TO CODE
*!*	IF SEEK( lcOffice)
*!*	   if lcAreaCode==Office.AreaCode1 or ;
*!*	         lcAreaCode==Office.AreaCode2 or ;
*!*	         lcAreaCode==Office.AreaCode3 or ;
*!*	         lcAreaCode==Office.AreaCode4 or ;
*!*	         lcAreaCode==Office.AreaCode5 or ;
*!*	         lcAreaCode==Office.AreaCode6 or ;
*!*	         lcAreaCode==Office.AreaCode7 or ;
*!*	         lcAreaCode==Office.AreaCode8 or ;
*!*	         lcAreaCode==Office.AreaCode9 or ;
*!*	         lcAreaCode==Office.AreaCod10
*!*	      lncalltype = 2                            && local
*!*	   else
*!*	      lncalltype = 1                            && LDC
*!*	   endif
*!*	endif
*!*	=gfunuse("Office", llOffice)

*!*	* For non-local calls only, check office/litigation/area in LocalAC.dbf.
*!*	* This file lists "local" area codes that are only valid within
*!*	* a specific office/litigation/area combination. These reflect special
*!*	* definitions of "local" processing made in unusual situations.
*!*	* (For instance, calls made to the Cincinnati area are treated as local
*!*	* if we are dealing with Ohio-area Asbestos cases from the Philly office.)

*!*	if lnCalltype < 2
*!*	   llLocalAC = gfuse("localAC")
*!*	   lnCallType = 1
*!*	   SCAN FOR LocalAC.Office = lcOffice AND ;
*!*	         LocalAC.Area == lcArea AND ;
*!*	         LocalAC.Litigation == lcLit AND ;
*!*	         LocalAC.AreaCode == lcAreaCode
*!*	      ** Match found implies a local area code for this set of parameters.
*!*	      lnCallType = 2
*!*	   ENDSCAN
*!*	   =gfunuse("localAC", llLocalAC)
*!*	endif
*!*	=gfPop(@laEnv)
*!*	return lncalltype
