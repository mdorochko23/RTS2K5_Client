*FUNCTION validssn
PARAMETERS  c_socsec


LOCAL l_ok as Boolean
lok =.f. &&assume that all number in teh ssn are the same
LOCAL lnall as Integer, cssn as String, cssn2 as String
cssn=STRTRAN(c_socsec,'-','',1)

lnall=LEN(ALLTRIM(cssn))
FOR ln=1 TO lnall
cssn2=''
cssn2= SUBSTR(cssn,ln,1)
IF  ln>1
IF cssnx<>cssn2	
	lok=.t.
	EXIT
ENDIF

ENDIF
	cssnx=	cssn2	
next


RETURN lok