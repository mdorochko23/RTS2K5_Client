
#DEFINE TH32CS_SNAPHEAPLIST 0x00000001
#DEFINE TH32CS_SNAPPROCESS  0x00000002
#DEFINE TH32CS_SNAPTHREAD   0x00000004
#DEFINE TH32CS_SNAPMODULE   0x00000008
#DEFINE TH32CS_SNAPALL      0x0000000F
#DEFINE TH32CS_INHERIT      0x80000000

#DEFINE MAX_MODULE_NAME32 255
#DEFINE MAX_PATH          260
#DEFINE SIZEOF_PE32 296
#DEFINE SIZEOF_ME32 548

PARAMETERS cExe,caction
IF PCOUNT()<2
 caction="APPCOUNT"
ENDIF  

LOCAL loTest AS 'AppsLister' OF 'appcheck.prg'
loTest = CREATEOBJECT('AppsLister')
loTest.GetModulesRunning('myModules')

lcExeToTest = cExe &&'vfp9.exe'

DO CASE
CASE caction=="APPCOUNT"
*// count number of occurrences of the process
	SELECT COUNT(*) FROM myModules ;
		WHERE ATC(m.lcExeToTest, ModuleName) = 1 ;
		INTO ARRAY arrCnt
	RETURN arrCnt
CASE caction=="ENDPROC"
*// terminate the process

* Get the process handle
	DECLARE INTEGER OpenProcess IN kernel32 INTEGER, INTEGER, INTEGER
	DECLARE LONG GetExitCodeProcess IN kernel32 LONG, LONG @
	DECLARE TerminateProcess IN kernel32 INTEGER, INTEGER
	DECLARE INTEGER CloseHandle IN kernel32 INTEGER

	SELECT myModules
	SCAN FOR ATC(UPPER(m.lcExeToTest), UPPER(ModuleName)) = 1
		lnPH = OpenProcess(2035711, 0, myModules.PROCESSID)
* Get the exit code
		lnExitCode = 0
		=GetExitCodeProcess(lnPH, @lnExitCode)
* Terminate the process
		=TerminateProcess(lnPH, lnExitCode)
* Close the process handle
		=CloseHandle(lnPH)
	ENDSCAN
	CLEAR DLLS "OpenProcess","GetExitCodeProcess","TerminateProcess","CloseHandle"
OTHERWISE
	SELECT COUNT(*) FROM myModules ;
		WHERE ATC(m.lcExeToTest, ModuleName) = 1 ;
		INTO ARRAY arrCnt
	RETURN arrCnt
ENDCASE

*MESSAGEBOX('Instances running:'+LTRIM(STR( arrCnt )), 0, m.lcExeToTest)

*!*	Select * From myModules ;
*!*	  where Atc(m.lcExeToTest, ModuleName) = 1

DEFINE CLASS AppsLister AS LINE
	DIMENSION arrDLLs[1]
	Me32Structure = ''
	Pe32Structure = ''
	ProcListCursor   = SYS(2015)
	ModuleListCursor = SYS(2015)
	AppsListCursor   = SYS(2015)

	PROCEDURE INIT
	LOCAL ARRAY arrDLLs[1]
	ADLLS(arrDLLs) && Save defined DLLs
	ACOPY(arrDLLs,THIS.arrDLLs)
	THIS.InitDLLs() && Declare DLLs
	THIS.Me32Structure = THIS.Int2Str(SIZEOF_ME32) + ;
		REPLICATE(CHR(0), SIZEOF_ME32-4)
	THIS.Pe32Structure = THIS.Int2Str(SIZEOF_PE32) + ;
		REPLICATE(CHR(0), SIZEOF_PE32-4)
	THIS.CreateCursors()
	ENDPROC

	PROCEDURE CreateCursors
	CREATE CURSOR (THIS.ModuleListCursor) ;
		(PROCESSID i, szModule c(254), szExeFile c(254))
	CREATE CURSOR (THIS.ProcListCursor) ;
		(PROCESSID i,;
		cntThreads i,;
		ParentPID i,;
		szExeFile c(254))
	ENDPROC

	PROCEDURE RemoveCursors
	USE IN (THIS.ModuleListCursor)
	USE IN (THIS.ProcListCursor)
	ENDPROC

	PROCEDURE GetModulesRunning
	LPARAMETERS tcCursorName
	tcCursorName = IIF(EMPTY(m.tcCursorName),'Modules',m.tcCursorName)
	THIS.GetProcessList()

	SELECT DISTINCT pl.PROCESSID, pl.cntThreads, pl.ParentPID, ;
		NVL(ml.szModule,pl.szExeFile) AS 'ModuleName', ;
		NVL(ml.szExeFile,'') AS ExeName ;
		FROM (THIS.ProcListCursor) pl ;
		LEFT JOIN (THIS.ModuleListCursor) ml ON pl.PROCESSID = ml.PROCESSID ;
		INTO CURSOR (m.tcCursorName) ;
		nofilter
	ENDPROC

	PROCEDURE InitDLLs && Declare DLLs
	DECLARE INTEGER GetWindowText IN Win32API ;
		INTEGER HWND, STRING @lptstr, INTEGER cbmax
	DECLARE INTEGER GetClassName IN WIN32API ;
		INTEGER HWND, STRING @cClass, INTEGER nMaxBuffer
	DECLARE INTEGER GetWindowThreadProcessId IN win32API ;
		INTEGER HWND, INTEGER @lpdwProcessId
	DECLARE INTEGER CloseHandle IN win32API INTEGER hObject
	DECLARE INTEGER CreateToolhelp32Snapshot IN win32API ;
		INTEGER dwFlags, INTEGER th32ProcessID
	DECLARE INTEGER Process32First IN win32API ;
		INTEGER hSnapshot, STRING @ lppe
	DECLARE INTEGER Process32Next IN win32API ;
		INTEGER hSnapshot, STRING @ lppe
	DECLARE INTEGER Module32First IN win32API ;
		INTEGER hSnapshot, STRING @ lpme
	DECLARE INTEGER Module32Next IN win32API ;
		INTEGER hSnapshot, STRING @ lpme
	DECLARE RtlMoveMemory IN WIN32API ;
		INTEGER @DestNumeric, ;
		STRING @pVoidSource, ;
		INTEGER nLength
	ENDPROC

	PROCEDURE DESTROY
	LOCAL lnDLLs
	LOCAL ARRAY arrDLLs[1]
	lnDLLs = ADLLS(arrDLLs) && Get current DLLs
	FOR ix=1 TO m.lnDLLs
		IF EMPTY(THIS.arrDLLs) OR ;
				ASCAN(THIS.arrDLLs,arrDLLs[m.ix,2],1,-1,2,1+2+4+8) = 0
			CLEAR DLLS &arrDLLs[m.ix,2]
		ENDIF
	ENDFOR
	THIS.RemoveCursors()
	ENDPROC

	PROCEDURE GetProcessModule
	LPARAMETERS tnPID
	LOCAL hModuleSnap, me32
	hModuleSnap = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, m.tnPID)
	IF hModuleSnap < 0
		RETURN .F.
	ENDIF
	me32 = THIS.Me32Structure
	lSuccess = ( Module32First(hModuleSnap, @me32) # 0)
	THIS.MODULEENTRY32_ToCursor(m.me32)
	CloseHandle (hModuleSnap)
	ENDPROC

	FUNCTION GetProcessList
	LOCAL hProcessSnap, pe32, lSuccess
	hProcessSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
	pe32 = THIS.Pe32Structure
*  Walk the snapshot of the processes
*  and for each process, get module info
	lSuccess = ( Process32First(hProcessSnap, @pe32) # 0 )
	DO WHILE m.lSuccess
		m.th32ProcessID = THIS.PROCESSENTRY32_ToCursor(m.pe32)
		THIS.GetProcessModule(m.th32ProcessID)
		lSuccess = ( Process32Next(hProcessSnap, @pe32) # 0)
	ENDDO
	CloseHandle (m.hProcessSnap)
	ENDPROC

	PROCEDURE MODULEENTRY32_ToCursor
	LPARAMETERS tcBuffer
	LOCAL PROCESSID, szModule, szExeFile
	WITH THIS
		m.ProcessID = .Substr2Num(m.tcBuffer,9,4)
		m.tcBuffer  = SUBSTR(m.tcBuffer,33)
		m.szModule  = LEFT(m.tcBuffer,AT(CHR(0),m.tcBuffer)-1)
		m.tcBuffer  = SUBSTR(m.tcBuffer,256+1)
		m.szExeFile = LEFT(m.tcBuffer,AT(CHR(0),m.tcBuffer)-1)

		INSERT INTO (.ModuleListCursor) ;
			(PROCESSID,szModule,szExeFile) VALUES ;
			(m.ProcessID,m.szModule,m.szExeFile)
	ENDWITH
	ENDPROC

	PROCEDURE PROCESSENTRY32_ToCursor
	LPARAMETERS tcBuffer
	LOCAL PROCESSID, cntThreads, ParentPID, szExeFile
	WITH THIS
		m.ProcessID  = .Substr2Num(m.tcBuffer,9,4)
		m.cntThreads = .Substr2Num(m.tcBuffer,21,4)
		m.ParentPID  = .Substr2Num(m.tcBuffer,25,4)
		m.tcBuffer   = SUBSTR(m.tcBuffer,37)
		m.szExeFile  = LEFT(m.tcBuffer,AT(CHR(0),m.tcBuffer)-1)

		INSERT INTO (.ProcListCursor) ;
			(PROCESSID,	cntThreads, ParentPID, szExeFile) ;
			VALUES ;
			(m.ProcessID, m.cntThreads, m.ParentPID, m.szExeFile)
	ENDWITH
	RETURN m.ProcessID
	ENDPROC

	PROCEDURE Substr2Num
	LPARAMETERS tcStr, tnStart, tnSize
	RETURN THIS.Str2Num(SUBSTR(m.tcStr, m.tnStart, m.tnSize), m.tnSize)
	ENDPROC

	PROCEDURE Str2Num
	LPARAMETERS tcStr,tnSize
	LOCAL m.lnValue
	m.lnValue=0
	RtlMoveMemory(@lnValue, m.tcStr, m.tnSize)
	RETURN m.lnValue
	ENDPROC

	PROCEDURE Int2Str
	LPARAMETERS tnValue, tnSize
	LOCAL ix, lcReturn
	m.tnSize = IIF(EMPTY(m.tnSize),4,m.tnSize)
	lcReturn = ''
	FOR ix=1 TO m.tnSize
		m.lcReturn = m.lcReturn + ;
			CHR(BITAND(BITRSHIFT(m.tnValue, (m.ix-1)*8),0xFF))
	ENDFOR
	RETURN m.lcReturn
	ENDPROC

ENDDEFINE

