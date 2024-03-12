***********************************************************************************************************
**FUNCTION closeexcel
LPARAMETERS tcName
LOCAL loLocator, loWMI, loProcesses, loProcess, llIsRunning
loLocator 	= CREATEOBJECT('WBEMScripting.SWBEMLocator')
loWMI		= loLocator.ConnectServer() 
loWMI.Security_.ImpersonationLevel = 3  		&& Impersonate
 
loProcesses	= loWMI.ExecQuery([SELECT * FROM Win32_Process WHERE Name = '] + tcName + ['])
llIsRunning = .F.
IF loProcesses.Count > 0
	FOR EACH loProcess in loProcesses
		llIsRunning = .T.	
		loProcess.Terminate(0)	
	ENDFOR
ENDIF
RETURN llIsRunning