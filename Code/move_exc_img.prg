PARAMETERS c_file, c_folder
******************************************************************************
*** MOVES AN EXCEL WITH IMAGES TO A NEWLY CRETAED FOLDER
_SCREEN.MOUSEPOINTER=11
 &&store an image file 
LOCAL lcpath AS String, lcNewpath as String, lcname as String
LOCAL fso_exc AS Object
STORE "" TO lcpath, lcNewpath, lcname
lcpath=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","QCExcel", "\")))
lcNewpath=lcpath +c_folder
n_div=0
n_all=0
n_all =LEN(c_file)
n_div =RAT("\",c_file,1)
lcname =RIGHT(c_file,n_all-n_div)
	
DO closeexcel WITH "Excel.EXE"

fso_exc = CREATEOBJECT("Scripting.FileSystemObject")

IF  NOT fso_exc.FolderExists(lcNewpath)
	fldr = fso_exc.CreateFolder(lcNewpath)
ENDIF
IF FILE(c_file) 	
		fso_exc.CopyFile( c_file,lcNewpath +"\"+ lcname )		
endif

*gfmessage("Stored an Images file at "  + lcNewpath ) 
RELEASE fso_exc
_SCREEN.MOUSEPOINTER=0
RETURN
***********************************************************************************************************
FUNCTION closeexcel
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