*****************************************************************************
* gfInvName.PRG - Get Attorney Invoice Name
*
* History :
* Date      Name  Comment
* ---------------------------------------------------------------------------
FUNCTION gfInvNam
LPARAMETERS lcAtCode
LOCAL lnCurArea, LCSQLLine, retval, lloGen
lnCurArea=SELECT()
retval=""
IF TYPE("oGen")!="O"
   oGen=CREATEOBJECT("medgeneric")
   lloGen=.T.
ENDIF
lcSQLLine="select dbo.gfInvName('"+ALLTRIM(fixQuote(lcAtCode))+"')"
oGen.sqlexecute(lcSQLLine,"viewInvName")
SELECT viewInvName
IF RECCOUNT()>0
   retval=viewInvName.exp
ENDIF
USE 
IF lloGen=.T.
   release oGen
ENDIF    
SELECT(lnCurArea)  
RETURN retval
************************************************************************************