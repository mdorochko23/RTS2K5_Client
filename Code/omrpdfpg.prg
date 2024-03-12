*PROCEDURE omrpdfpg
LOCAL lcpath AS STRING, c_Temp AS STRING, c_netprint as String, lcCurDir as String
STORE "" TO lcpath, c_Temp, c_netprint, lcCurDir



lcCurDir=SYS(5)+SYS(2003)

c_netprint=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","cnetprint", "\"))) 
c_Temp=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","cTemp", "\"))) + "omrpage.pdf"
fso2= CREATEOBJECT("Scripting.FileSystemObject")

lc_pages= INPUTBOX("Please enter a number of OMR pages you want to print:","OMR Pages","1")
n_page=VAL(lc_pages)
IF n_page=0
	gfmessage("Invalid number of pages entered. Try again.")
ELSE

FOR icnt =1 TO n_page
IF (FILE(c_Temp))
** found it-use it
	DO netpdfprint WITH "C:\TEMP\omrpage.pdf"
ELSE
**copy to user's pc
	SET DEFAULT TO &c_netprint
	fso2.CopyFile( c_netprint +"omrpage.pdf",c_Temp )	
	
	SET DEFAULT TO &lcCurDir
	DO netpdfprint WITH "C:\TEMP\omrpage.pdf"


ENDIF

NEXT 
gfmessage("Printing complete.")
ENDIF

RELEASE fso2
SET DEFAULT TO &lcCurDir

RETURN
