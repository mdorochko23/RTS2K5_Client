*****************************************************************************
* gfIssued.PRG - Return if a deponent has been issued
*
* History :
* Date      Name  Comment
* ---------------------------------------------------------------------------
* 08/05/98  Hume  Initial release
*****************************************************************************
Parameter lcClient, lnTag
Private lcAlias, llIssued
*!*	Private llIssued, lcAlias, lcEntry, lcOrder

*!*	llIssued = .F.

lcAlias = Alias()

IF TYPE('lntag') = 'N'

	lntag = ALLTRIM(STR(lntag))

ENDIF


SELECT 0
o = CREATE("medgeneric")
o.sqlexecute("select dbo.gfIssued('" + lcClient + "','" + lnTag + "')", "gfIssued")
llIssued = gfIssued.exp
USE IN gfIssued
* call a mediator that to query timesheet for 2 parameters
*lcEntry = gfEntryN(lcClient)
*Select (lcEntry)
*lcOrder = Order()
*Set Order To Status
*If Seek(lcClient+"*"+Str(lnTag))
*   llIssued = .T.
*Endif
* --- restore entry file active index ---
*If ! Empty(lcOrder)
*   Set Order To Tag (lcOrder)
*Else
*   Set Order To
*Endif

If ! Empty(lcAlias)
   Select (lcAlias)
Endif

Return llIssued 

