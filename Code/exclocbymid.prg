**FUNCTION ExcLocbyMid
PARAMETERS  C_MAILID, C_hdep
LOCAL c_midloc AS STRING
PRIVATE o_midchk AS OBJECT
o_midchk=CREATEOBJECT("generic.medgeneric")


STORE "" TO c_midloc, c_addtodesc
IF EMPTY(C_hdep)
	C_hdep="Z"
ENDIF
IF C_hdep<>"Z"
c_addtodesc=getdescript(C_hdep)
endif
DO GETDEPONENT  IN ISSUEPROCESS WITH C_MAILID, C_hdep

IF !EMPTY(NVL(PC_DEPOFILE.ID_TBLDEPONENTS,""))	
	c_midloc=ALLTRIM(PC_DEPOFILE.NAME)
ENDIF





RELEASE o_midchk

RETURN ALLTRIM(c_midloc) + c_addtodesc

