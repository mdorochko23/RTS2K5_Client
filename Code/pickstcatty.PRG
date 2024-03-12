** EF 9/30/05- Switched to SQL
**Assumes the TABILLS was selected
**Called from  medrequest.pickattorney() of request.vcx.

LOCAL  lcAlias AS STRING, llPicked AS Boolean, llDone AS Boolean

lcAlias=ALIAS()
llPicked=.F.

SELECT at_code, name_last, name_first, ;
	response, CODE, .F. AS Chosen, file_no ;
	FROM tabills  ;
	INTO Cursor PickAtty READWRITE ;
	ORDER BY CODE DESC
	
WAIT CLEAR


*DEFINE WINDOW w_attykeys AT 14,25  SIZE 5,71 COLOR SCHEME 10 
DEFINE WINDOW w_attykeys AT 14,25  SIZE 31,71 COLOR SCHEME 10 ;
	TITLE " Attorney Selection Hot Keys "
	ACTIVATE WINDOW w_attykeys
@ 1,1 SAY "      <F5> Select All Attorneys      " + ;
	"<F6> Select Plaintiff's Attorney" ;
	COLOR GR+/B
@ 2,1 SAY "      <F8> Deselect All Attorneys    " + ;
	"<F7> Select Requesting Attorney " ;
	COLOR GR+/B
@ 3,1 SAY "      <Ctrl+W> Confirm and exit      " + ;
	"                                " ;
	COLOR GR+/B

DEFINE WINDOW w_pickatty FROM 5,1 TO 19,63 COLOR SCHEME 10 ;
	TITLE " Select recipient(s) of status letter " ;
	in window w_attykeys
ACTIVATE WINDOW w_pickatty

PUSH KEY
SET ESCAPE OFF
ON KEY LABEL F5 DO lfSelAll WITH .T., llDone
ON KEY LABEL F6 DO lfSelOne WITH llDone, "P"
ON KEY LABEL F7 DO lfSelOne WITH llDone, "R"
ON KEY LABEL F8 DO lfSelAll WITH .F., llDone
llDone = .F.

DO WHILE NOT llDone
	
	BROWSE FREEZE Chosen FIELDS ;
		Chosen    :9    :H="Chosen?" :P="L", ;
		name_last   :15   :H="Last Name", ;
		name_first  :15  :H="First Name", ;
		at_code   :12   :H="Atty Code", ;
		response  :8    :H="Resp", ;
		xcode = IIF( CODE = "P", "Plaintiff", ;
		IIF( CODE = "L", "Lead", "Defense")) :11 :H="  Role", ;
		is_req = IIF( at_code = pc_rqatcod, .T., .F.) ;
		:5 :H="Req" :P="Y" ;
		FONT 'Arial' , 10 ;
		IN WINDOW w_pickatty
	llDone = .T.	
ENDDO
DEACTIVATE WINDOW w_pickatty
RELEASE WINDOW w_pickatty
DEACTIVATE WINDOW w_attykeys
RELEASE WINDOW w_attykeys
@ 14,0 CLEAR
llPicked = IIF( LASTKEY() = 27, .F. , llDone)
IF NOT llPicked 
	=gfmessage("No Attorney was selected. The operation has been canceled.")
*--wait window "No Attorney was selected. The operation has been canceled." nowait
endif
SELECT (lcAlias)
POP KEY
SET ESCAPE ON
RETURN llPicked
******************************************************************
PROCEDURE lfSelAll
PARAMETER llSelect, llDone

REPLACE ALL Chosen WITH llSelect
GOTO TOP
llDone = .F.
KEYBOARD "{CTRL+W}" PLAIN CLEAR
RETURN
* --------------------------------------------------------------------------
* Select/Deselect Individual attorney in the case
* --------------------------------------------------------------------------
PROCEDURE lfSelOne
PARAMETER llDone, c_attytype
PRIVATE lcAtty
lcAtty = IIF( c_attytype = "P", pc_platcod, pc_rqatcod)
IF EMPTY(lcAtty)
	=gfmessage("No " + IIF( c_attytype = "P", "plaintiff's", "requesting") + ;
      " attorney has been specified in this case.")
*--  =MESSAGEBOX("No " + IIF( c_attytype = "P", "plaintiff's", "requesting") + ;
      " attorney has been specified in this case.",64,"Print STC Letters")
ELSE
   LOCATE FOR at_code = lcAtty
   IF FOUND()
      REPLACE Chosen WITH NOT Chosen
      LOCATE FOR at_code = lcAtty
   ELSE
      =gfmessage( "Attorney " + lcAtty + " is not in the case.")
*--      =MESSAGEBOX( "Attorney " + lcAtty + " is not in the case.",64,"Print STC Letters")
   ENDIF
ENDIF
llDone = .F.
KEYBOARD "{CTRL+W}" PLAIN CLEAR
RETURN
