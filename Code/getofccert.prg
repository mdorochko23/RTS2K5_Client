PARAMETERS ntag
**EF 05/15/06 -added to the project. Called from the txofcer.prg/frmtxrepwvr (option #9)
PRIVATE c_tag, l_retval
l_retval=.T.
omed=CREATEOBJECT('medgeneric')
IF USED('Ofcrcert')
	SELECT ofcrcert
	USE
ENDIF
SELECT 0
c_tag =STR(ntag)
s_str= "Select * FROM tblOfcrcert " ; 
+ " Where Cl_Code ='" + fixquote(pc_Clcode) +  "' And tag ='" + ALLTRIM(c_tag) + "'"
l_retval=omed.sqlexecute (s_str, "Ofcrcert")

SELECT Ofcrcert
IF NOT EOF() THEN
	SELECT ofcrcert
	l_retval=.t.
	*=CURSORSETPROP("TABLES", "cl_code", "Ofcrcert")
	*=CURSORSETPROP("KeyFieldList", "Cl_code, Tag", "Ofcrcert")
	*INDEX ON CL_CODE +"*"+ STR(TAG) TAG ClTag ADDITIVE
ELSE
	l_retval=.F.
	=gfmessage("Cannot open Ofcrcert table")
**	=MESSAGEBOX ("Cannot open Ofcrcert table",16, "Load Table")
ENDIF

RETURN l_retval
