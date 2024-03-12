*:****************************************************************************
*:
*: PROCEDURE - MLMSG
*:
*: Description: MlMsg() provides a wait window with an optional beep.
*:
*: Parameters : msg_val - <expC> - Optional - Default = "Please Wait"
*:                      - Value to Seek
*:              msg_bep - <expL> - Optional - Default=True
*:                      - Flag defines whether or not message beeps
*:
*: Return Val : Returns .T. 
*:
*: Example    : *--Send Message to user and beep at them--*
*:              IF (baderror)
*:                =Mlmsg("You goofed!")
*:              ENDIF
*:
*:****************************************************************************
PARAMETERS msg_val,msg_bep
PRIVATE ALL LIKE msg_*

msg_prm = PCOUNT()

*--Do the beep thing--*
IF (msg_prm < 2 .OR. msg_bep)
  ?? CHR(7)
ENDIF

*--Display Error Message--*
msg_val = IIF(!EMPTY(msg_val),msg_val,"Please Wait...")
CLEAR TYPEAHEAD
WAIT msg_val WINDOW TIMEOUT 2

RETURN


