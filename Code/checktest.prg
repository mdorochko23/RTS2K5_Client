LPARAMETERS lcProcess
LOCAL retval, lcTestList, lnCurArea
lnCurArea=SELECT()
retval=.T.
SET EXCLUSIVE OFF

IF USED( "testList")
 SELECT  testList
 USE
ENDIF

lcTestList=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","GLOBAL", "\")))+"testlist.dbf"
SELECT 0
IF NOT USED("testList")
USE &lcTestList ALIAS testList IN 0 SHARED AGAIN
ENDIF

SELECT testList
SET ORDER to PROCESS   && ALLTRIM(UPPER(PROCESS))
SEEK ALLTRIM(UPPER(lcProcess))
IF !FOUND()		&& the program was released into production
   USE IN testList
   SELECT (lnCurArea) 
   RETURN .F.
ENDIF   

* new version is still in test mode 
* check if the user has rights to access test version

DO WHILE !EOF() AND ALLTRIM(UPPER(process))==ALLTRIM(UPPER(lcProcess))
   IF ALLTRIM(UPPER(login))==ALLTRIM(UPPER(goApp.CurrentUser.ntlogin))
     retval=.F.
     EXIT 
   ENDIF 
   IF !EOF()
     SKIP
   ENDIF 
ENDDO 
USE IN testList
SELECT (lnCurArea)
RETURN retval   