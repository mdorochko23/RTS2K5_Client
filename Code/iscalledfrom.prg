*IsCalledFrom   determine a caller of a program or process, look at the call stack
*#255675 WY 12/19/2021
PARAMETERS tcFoxFileName
LOCAL i, llResult

llResult = .f.
=ASTACKINFO(gaStackInfo)
FOR i = 1 to ALEN(gaStackInfo,1)
	IF UPPER(ALLTRIM(tcFoxFileName)) $ UPPER(ALLTRIM(gaStackInfo(i, 3)))
		llResult = .t.
		Exit
	ENDIF 
ENDFOR 
RELEASE gaStackInfo
RETURN llResult
