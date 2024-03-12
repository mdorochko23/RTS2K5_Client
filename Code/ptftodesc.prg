*FUNCTION PTFTODESC
PARAMETERS lchkNYCAsb, cName
LOCAL cNewName as String
cNewName=ALLTRIM(cName)

IF lchkNYCAsb=1 AND NOT EMPTY(cNewName)

	IF  NOT '[PTF]'$ cName
	cNewName=ALLTRIM(cName) + " [PTF]"
	ENDIF
ELSE  
	cNewName= STRTRAN( ALLTRIM(cName),"[PTF]", "", 1,1)
	
ENDIF

RETURN cNewName