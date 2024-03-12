
*************************************************************************************
**EF 01/23/08- allows a user to supress the printing of a First Request
*************************************************************************************
PARAMETERS c_clcode, c_tag

PRIVATE l_ok,l_DoWePrint AS Boolean, c_Extra as String, C_MSG as String
loRequest=CREATEOBJECT("medmaster")
STORE "" TO c_Extra, C_MSG
l_ok = loRequest.Sqlexecute("select dbo.IfPrintRequest ('" +  fixquote(c_clcode) + "', '" + c_tag + "')","AllowToStop")
IF l_ok
	l_DoWePrint =AllowToStop.EXP

ELSE
	l_DoWePrint =.F.
ENDIF
pl_StopPrtIss =l_DoWePrint
** YS 05/29/18 RPS No Print Job Logging [#88327]	
IF pl_StopPrtIss
	lcSQLLine=" exec [dbo].[AddTrackStopPrint]   '" + convertToChar(pc_lrsno,1) + "','" + convertToChar(fixquote(c_clcode),1) + "','" + convertToChar(c_tag,1) + "','";
			+ convertToChar(pc_isstype,1) + "','" + convertToChar(fixquote(PC_USERID),1) + "','ifprt1req.prg(1)',''"	
	*lcSQLLine=" exec [dbo].[AddTrackStopPrint]   '" + ALLTRIM(pc_lrsno) + "','" + ALLTRIM(c_clcode) + "','" + ALLTRIM(c_tag) + "','";
		+ pc_isstype  + "','" + ALLTRIM(PC_USERID) + "','ifprt1req.prg(1)',''"
	loRequest.Sqlexecute(lcSQLLine,'')
ENDIF

IF  NOT l_DoWePrint
*****05/25/12- CONFIRM A SUPRESS WHEN EITHER HAND DELIVERY OR ORIF SUBP IS REQUESTED
	C_MSG=HandOrig(.f.)
	IF !EMPTY(C_MSG)
		c_Extra =" A request needs a special handling information are you sure you want to suppress it?" 
	ENDIF
	*******
	
	l_Confirm=gfmessage("Do you want to suppress a printing of this Request?" + c_Extra,.t.)

	IF l_Confirm
	
	
		pl_StopPrtIss = .T.
		** YS 05/29/18 RPS No Print Job Logging [#88327]	
		lcSQLLine=" exec [dbo].[AddTrackStopPrint]   '" + convertToChar(pc_lrsno,1) + "','" + convertToChar(fixquote(c_clcode),1) + "','" + convertToChar(c_tag,1) + "','";
			+ convertToChar(pc_isstype,1) + "','" + convertToChar(fixquote(PC_USERID),1) + "','ifprt1req.prg(2)',''"	
		*lcSQLLine=" exec [dbo].[AddTrackStopPrint]   '" + ALLTRIM(pc_lrsno) + "','" + ALLTRIM(c_clcode) + "','" + ALLTRIM(c_tag) + "','";
			+ pc_isstype  + "','" + ALLTRIM(PC_USERID) + "','ifprt1req.prg(2)',''"
		loRequest.Sqlexecute(lcSQLLine,'')
	ENDIF
ENDIF
RELEASE loRequest

