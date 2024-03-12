*--identifies if current operation system is 64 bit
*-- windows 64 bit operation systems use Wow64Process to run 32 bit programs
DECLARE Long GetModuleHandle IN WIN32API STRING lpModuleName
DECLARE Long GetProcAddress IN WIN32API Long hModule, String lpProcName
llIsWow64ProcessExists = (GetProcAddress(GetModuleHandle("kernel32"),"IsWow64Process") <> 0)
 
llIs64BitOS = .F.
IF llIsWow64ProcessExists 
	DECLARE Long GetCurrentProcess IN WIN32API 
	DECLARE Long IsWow64Process IN WIN32API Long hProcess, Long @ Wow64Process
	lnIsWow64Process = 0
	* IsWow64Process function return value is nonzero if it succeeds 
	* The second output parameter value will be nonzero if VFP application is running under 64-bit OS 
	IF IsWow64Process( GetCurrentProcess(), @lnIsWow64Process) <> 0
		llIs64BitOS = (lnIsWow64Process <> 0)
	ENDIF	
ENDIF	
return llIs64BitOS 