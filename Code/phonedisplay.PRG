FUNCTION phonedisplay(tsPhone)
* format various phone numbers for display (North American phone number standards)
#INCLUDE app.h

IF nempty(tsPhone) OR TYPE("tsPhone")<>T_CHARACTER
  RETURN ""
ENDIF

tsPhone = ALLTRIM(tsPhone)

DO CASE
CASE "-" $ tsPhone OR "." $ tsPhone OR "(" $ tsPhone OR "/" $ tsPhone OR " " $ LEFT(tsPhone,4)
  RETURN tsPhone
CASE LEN(tsPhone)=10
  RETURN TRANSFORM(tsPhone, "@R 999-999-9999")
CASE LEN(tsPhone)=7
  RETURN TRANSFORM(tsPhone, "@R 999-9999")
CASE LEN(tsPhone)=11 AND tsPhone="1"
  RETURN TRANSFORM(tsPhone, "@R 9-999-999-9999")


OTHERWISE
  RETURN tsPhone
ENDCASE
* end of FUNCTION phonedisplay()