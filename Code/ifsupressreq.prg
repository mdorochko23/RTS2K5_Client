
*************************************************************************************
**04/3/08- allows a user to supress the issuing of a First Request
*************************************************************************************
PARAMETERS c_clcode
PRIVATE l_ok,l_DoWeSuppress AS Boolean

loRequest=CREATEOBJECT("medmaster")
l_ok=loRequest.Sqlexecute("select  dbo.Ifsupressrequest('"+fixquote(c_clcode)+"')","AllowToStop")
IF l_ok
	l_DoWeSuppress=AllowToStop.EXP
ELSE
	l_DoWeSuppress=.F.
ENDIF
IF  l_DoWeSuppress AND (EMPTY(PC_SPECHAND) AND NOT pl_StopPrtIss) &&04/23/12- DO NOT ASK THE SAME QUESTION TWICE
	l_DoWeSuppress=gfmessage("Do you want to suppress the issuing of this Request?",.t.)
ENDIF
RELEASE loRequest

RETURN (l_DoWeSuppress)

