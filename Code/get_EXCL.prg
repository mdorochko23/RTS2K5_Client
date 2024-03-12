************************************************************************
**7/7/09 get an excel for AIP process
*FUNCTION get_EXCL
************************************************************************
lnCurArea=SELECT()
lcCURR=SYS(5) +SYS(2003)
lcDefault=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","AUTOMATEDISSUE", "\")))
gfMessage("Please make sure the file matches a TEMPLATE file for this litigation.")
IF USED("OrigList")
SELECT OrigList
USE
ENDIF
SET DEFAULT TO &lcDefault
lcFile=GETFILE("XLS","Load Excel List")
IF NOT EMPTY(ALLTRIM(LCFILE))
lcFile="'"+ALLTRIM(lcFile)+"'" 
SET SAFETY off
IMPORT FROM &lcFile xl5
lcFileName=DBF()
USE
SET SAFETY on
lcFileName="'"+ALLTRIM(lcFileName)+"'"
pc_ToDoFile=lcFileName
USE &lcFileName ALIAS OrigList EXCLUSIVE
GO TOP 
DELETE NEXT 1
USE
ENDIF && EMPTY file
IF NOT EMPTY(lnCurArea)
SELECT (lnCurArea)  
endif 
SET DEFAULT TO &lcCURR 
RETURN (lcFileName)
