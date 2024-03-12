***Validation for the issue type
*FUNCTION IsIssueType called from the subp_pa
PARAMETERS cAction, nreqby
LOCAL cretval AS STRING
cretval=cAction

IF (cAction = "7" AND nreqby = 2) OR ;
		(cAction = "8" AND nreqby = 1)
	gfmessage(  "The case instructions specify that requests" + ;
		CHR(13) + "should be issued via " + ;
		IIF( nreqby = 1, "subpoena", "authorization") + "." + CHR(13) + ;
		"You have chosen to issue this request via " + ;
		IIF( cAction = "7", "subpoena", "authorization") + "." )	
	lc_message = "Issue request as you specified?"
	o_message = CREATEOBJECT('rts_message_yes_no',lc_message)
	o_message.SHOW
	l_Confirm=IIF(o_message.exit_mode="YES",.T.,.F.)
	o_message.RELEASE
	IF NOT l_Confirm

		lc_message = "Issue request according to case instructions?"
		o_message = CREATEOBJECT('rts_message_yes_no',lc_message)
		o_message.SHOW
		l_Confirm=IIF(o_message.exit_mode="YES",.T.,.F.)
		o_message.RELEASE
		IF NOT l_Confirm
			RETURN ""
		ENDIF

		IF cAction = "7"
			cAction = "8"
		ELSE
			cAction = "7"
		ENDIF
		cretval=cAction
	ENDIF

ENDIF



RETURN cretval
