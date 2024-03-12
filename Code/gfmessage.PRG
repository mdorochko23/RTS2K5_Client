
**************************************************************************
*** PROGRAM: Gfmessage
*** Date: 8/10/06
*** Funtion: Display user designated version of the RTS messagebox
**************************************************************************
LPARAMETERS c_message,l_respond, lNoFocus
LOCAL o_message AS Object, lo_message AS Object
*Set Classlib To App Additive
IF PCOUNT()<1
	c_message="ERROR: No message passed"
ENDIF
IF PCOUNT()<2
	l_respond=.F.
ENDIF
IF PCOUNT()<3
	lNoFocus=.F.
ENDIF
*Set Classlib To App Additive
IF NOT l_respond
	o_message = CREATEOBJECT('app.rts_message',c_message)
	o_message.SHOW
	RELEASE o_message
ELSE
	LOCAL l_answer
	lo_message = CREATEOBJECT('app.rts_message_yes_no',c_message)
	IF lNoFocus=.T.
	   lo_message.cmdNo.SetFocus
	   lo_message.refresh
	ENDIF 
	lo_message.SHOW	
	l_answer=IIF(lo_message.exit_mode="YES",.T.,.F.)
	lo_message.release
	RELEASE lo_message
	RETURN l_answer
ENDIF