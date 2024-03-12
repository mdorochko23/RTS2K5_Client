**09/13/2010 -addapted from the PROCEDURE getRogsPath
LPARAMETERS lnLrsNo
LOCAL lnCurArea, lcPath, lcRTRogsPath, lcRetPath
LOCAL lcSQLLine
LOCAL oGen AS medGeneric OF generic
oGen=CREATEOBJECT("medGeneric")
lnCurArea=SELECT()
lcRetPath=""
SELECT 0
IF used("viewRogsPath")
   USE IN viewRogsPath
ENDIF    
lcSQLline="exec  [dbo].[getimagepath] 'ROG'"
oGen.sqlexecute(lcSQLLine, "viewRogsPath")
SELECT viewRogsPath
SCAN 
    lcPath=ALLTRIM(viewRogsPath.sPath)
    lcRTRogsPath=ALLTRIM(lcPath)+PADL(ALLTRIM(STR(lnLrsNo)),8,"0")
    IF !DIRECTORY(lcRTRogsPath) 
      IF !DIRECTORY(lcPath) 
          * this directory always there, so assuming the server itself is down
          * put some delay for server recovery
          WAIT WINDOW "Waiting for RTRogs Server response " TIMEOUT 20
      ENDIF 
    ENDIF 
    IF DIRECTORY(lcRTRogsPath)
       lcRetPath=lcPath
       EXIT 
    ENDIF     
ENDSCAN 
USE IN viewRogsPath
RELEASE oGen 
SELECT (lnCurArea)
RETURN  lcRetPath


