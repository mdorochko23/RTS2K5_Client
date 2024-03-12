*************************************************************************************
* PROGRAM - MLAPPDIR
*           Returns the executing application directory
*************************************************************************************
LOCAL l_cStr
l_cStr = SYS(16,0)
RETURN LEFT(l_cStr,RAT("\",l_cStr))
