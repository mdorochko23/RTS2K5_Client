
**03/20/2009- district list for the USDC court cases
PRIVATE llexit  AS Boolean
PUBLIC c_dist AS STRING
c_dist=""
llexit=.F.

DO WHILE  llexit=.F.

	DO district.mpr
	IF TYPE("c_dist")!="C" OR ISNULL(c_dist)=.T. OR EMPTY(ALLTRIM(C_DIST))
		lc_message = "Please, pick a DISTRICT for a case."
		o_message = CREATEOBJECT('rts_message',lc_message)
		o_message.SHOW
		DO district.mpr
		IF TYPE("c_dist")="C" AND NOT EMPTY(ALLTRIM(c_dist))
			llexit=.T.
			EXIT
		ENDIF
	ELSE
		llexit=.T.
	ENDIF
ENDDO


RETURN c_dist
