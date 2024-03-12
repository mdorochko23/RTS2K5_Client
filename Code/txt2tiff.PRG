*---------------------------------------------------------
*-- Convert a text file to tiff file
*---------------------------------------------------------

PARAMETERS lcTxt,lcTiff
** lcFont = 12bc, 18bc (examples)
IF PCOUNT()<2
	RETURN .F.
ENDIF

DECLARE INTEGER ShellExecute IN shell32.DLL ;
	INTEGER hndWin, ;
	STRING cAction, ;
	STRING cFileName, ;
	STRING cParams, ;
	STRING cDir, ;
	INTEGER nShowWin

IF PCOUNT() < 3
	lcFont = "12bc"     && Default
ENDIF

LOCAL cp,nr,lResult
lResult = .F.
cp = '"'+lcTxt+'"' + ' ' + '"'+lcTiff+'"'

IF pl_Is64bit
	nr=ShellExecute(0,"open","c:\program files (X86)\rts\ConvertTxt2Tiff.exe",cp,"",0)
ELSE
	nr=ShellExecute(0,"open","c:\program files\rts\ConvertTxt2Tiff.exe",cp,"",0)
ENDIF
*--nr=ShellExecute(0,"open","c:\program files\rts\ConvertTxt2Tiff.exe",cp,"",0)

DO WHILE isrunning("ConvertTxt2Tiff.exe")
	LOOP
ENDDO

IF FILE(lcTiff)
	lResult = .T.
ENDIF
CLEAR DLLS ShellExecute

RETURN (lResult)

*---------------------------------------------------------
FUNCTION isrunning
PARAMETERS tcName, lTerminate

IF PCOUNT() < 2
	lTerminate = .F.
ENDIF

LOCAL loLocator, loWMI, loProcesses, loProcess, llIsRunning
loLocator 	= CREATEOBJECT('WBEMScripting.SWBEMLocator')
loWMI		= loLocator.ConnectServer()
loWMI.Security_.ImpersonationLevel = 3  		&& Impersonate

loProcesses	= loWMI.ExecQuery([SELECT * FROM Win32_Process WHERE Name = '] + tcName + ['])
llIsRunning = .F.
IF TYPE("loProcesses") = "O" THEN
	IF loProcesses.COUNT > 0
		FOR EACH oProcess IN loProcesses
			sOwner = ""
			TRY
				IF TYPE("oProcess")<> "O"
					LOOP
				ENDIF
				oProcess.GetOwner(@sOwner)
				IF UPPER(ALLTRIM(GETENV("USERNAME"))) == UPPER(ALLTRIM(NVL(sOwner,'')))
					llIsRunning = .T.
					IF lTerminate
						oProcess.TERMINATE(0)
					ENDIF
				ENDIF
			CATCH
			ENDTRY
		ENDFOR
	ENDIF
ENDIF

RETURN llIsRunning
