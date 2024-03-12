**PROCEDURE click2dial

PARAMETERS lcInputPhoneNumber
LOCAL lcLine
lbContinue = .T.
lcPhoneNumber = STRTRAN(lcInputPhoneNumber,'(','')
lcPhoneNumber = STRTRAN(lcPhoneNumber,')','')
lcPhoneNumber = STRTRAN(lcPhoneNumber,'-','')
lcPhoneNumber = ALLTRIM(lcPhoneNumber)
lnPhoneNumberLen = LEN(lcPhoneNumber)
IF (lnPhoneNumberLen < 10)
  RETURN
ENDIF  
TRY
  lnTemp = VAL(lcPhoneNumber)
CATCH
  lbContinue = .F.
ENDTRY
IF (!lbContinue)
  RETURN
ENDIF  

LOCAL lcOS, lcPlatform
lcOS = OS(1)
DO CASE
CASE "6.02" $ lcOS AND OS(11) = "1"
	lcPlatform = "WIN8" && win10 and win8 return the same code 
CASE "6.01" $ lcOS AND OS(11) = "1"
	lcPlatform = "WIN7"
OTHERWISE 
	lcPlatform = "WINXP"
ENDCASE 

IF lcPlatform = "WINXP"
	DECLARE INTEGER ShellExecute IN shell32.DLL ;
	INTEGER hndWin, ;
	STRING cAction, ;
	STRING cFileName, ;
	STRING cParams, ;
	STRING cDir, ;
	INTEGER nShowWin
	cAction = "open"
	cfilename="tt:"+lcPhoneNumber+"?Dial"
	cparams=""
	ShellExecute(0,cAction,cFileName,cParams,"",0)
ELSE 
&&pl_Is64bit
	IF FILE("C:\Program Files (x86)\Go Integrator\phoneHelper.exe")
		lcLine="RUN /n C:\Program Files (x86)\Go Integrator\phoneHelper.exe dial("+ALLTRIM(lcPhoneNumber)+")"
		&lcLine
	ENDIF 
ENDIF 	

return