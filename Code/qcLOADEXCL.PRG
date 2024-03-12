*FUNCTION QCLoadExcl
************************************************************************
PARAMETERS cBatchNum, lcFile

STORE "" TO lcDefault,  c_dir, lcCurr, lc_sql , c_location, lc_loc
LOCAL omedExc AS OBJECT
STORE .F. TO l_ok
lnCurArea=SELECT()
lcCurr=SYS(5) +SYS(2003)
omedExc=CREATEOBJECT("medgeneric")
lcDefault=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","QCExcel", "\")))

SET DEFAULT TO &lcDefault
STORE "" TO lcFileName, PC_TODOFILE

IF NOT EMPTY(ALLTRIM(LCFILE))
	n_div=0
	c_dir =""
	n_div =RAT("\",lcfile,1)
	c_dir =LEFT(lcfile, n_div)
	lcFile="'"+ALLTRIM(lcFile)+"'"
	SET DEFAULT TO &lcCurr
	IF step1excl(&lcFile, c_dir, cBatchNum)=.F.	
	
		IF NOT EMPTY(lnCurArea)
			SELECT (lnCurArea)
		ENDIF
		RETURN ""
	ELSE
		lcFileName=PC_TODOFILE
	ENDIF


ENDIF 
IF NOT EMPTY(lnCurArea)
	SELECT (lnCurArea)
ENDIF

RELEASE omedExc
RETURN (lcFileName)




