**PROCEDURE HandOrig
PARAMETERS l_Display
LOCAL c_msg AS STRING
IF pl_OfcOak
RETURN ""
ENDIF
DO CASE
CASE (pl_MailOrig  AND pc_isstype="S") AND  pl_HandDlvr
	c_msg=" hand delivery of an original subpoena."
CASE pl_MailOrig AND pc_isstype="S"
	c_msg=" original subpoena."
CASE pl_HandDlvr &&AND NOT pl_MailOrig AND pc_isstype="A"
	c_msg=" hand delivery."

OTHERWISE
	c_msg=""
ENDCASE


IF NOT EMPTY(c_msg) AND l_Display
	gfmessage("You'll have to add a Special Handling Instructions as a request requires "  + c_msg)
ENDIF

RETURN c_msg
