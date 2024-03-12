**PROCEDURE  FaxMemo
**EF    05/01/17: replaced the AddPhntx
*****************************************************************************
** Remove txn 66 and 2/8 for txn44  #61920 / #61921
*****************************************************************************
PARAMETERS nRequest, n_Tag
*nRequest=1 - fax original issues
*nRequest=2 - fax second requests
*nRequest=3 - fax/print original issues
LOCAL c_memo AS STRING, l_done AS Boolean, c_alias AS STRING, o_med5 as Object
l_done=.F.
c_alias=ALIAS()

_SCREEN.MOUSEPOINTER=11

o_med5=CREATEOBJECT("medMaster")
	
c_memo =ALLTRIM(NVL(pc_FaxMemo,''))

IF USED('REQUEST')
	c_descript = REQUEST.DESCRIPT
ELSE
	s_clcode=pc_clcode
	DO getRequestbyRTtag IN cadissue WITH  s_clcode, n_Tag
	c_descript=REQUEST.DESCRIPT
ENDIF
IF pc_deptype == "D"
	c_drname=gfdrformat(c_descript)
	c_descript = IIF(NOT "DR."$c_drname,"DR. "+ALLTRIM(c_drname),c_drname)
ELSE
	c_descript = ALLTRIM(c_descript)
ENDIF

ccl_code=FIXQUOTE(pc_clcode)

c_str= ""

c_str= "Exec dbo.Add2ndFaxIssue '" +  ccl_code + "','"  + ALLTRIM(STR(n_Tag)) + "','" ;
	+ LEFT(FIXQUOTE(c_descript) ,50)  + "',"  + STR(nRequest) + ",'" + ;
	+ ALLTRIM(pc_UserID) + "','"  + FIXQUOTE(c_memo) + "'"

l_done=o_med5.sqlexecute(c_str)
IF !l_done
	gfmessage("Transactions have failed. Contact helpdesk@recordtrak.com")
ELSE

ENDIF

RELEASE o_med5
_SCREEN.MOUSEPOINTER=0
IF !EMPTY(c_alias)
	SELECT (c_alias)
ENDIF

RETURN
