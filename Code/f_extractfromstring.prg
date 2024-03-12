*____________________________________________________________________
*____________________________________________________________________
*
*	Function		:	F_ExtractFromString
*
*	NOTES	:
*
* Description: Method parses out an extract from a string based
*              left and right delimiters passed.
*
* Parameters : tsResultVariableReference   - <expC> - Required - No default                        
*                         - Where to store value PASSED BY REFERENCE!
*              tsString  - <expC> - Required - No default 
*                         - String to parse
*              tsLeftDelimiter    - <expC> - Optional - Default = ""
*                         - Left Delimiter to look for
*              tsRightDelimiter    - <expC> - Optional - Default = ""
*                         - Right Delimiter to look for
*              tiOccurence   - <expN> - Optional - Default = 1
*                         - Which occurrence to snatch
*
* Return Val : Position in the string immediately after the first
*              delimiter.  "0" if not found.
*
* Example    : *--Pull out option string value
*              l_cOptions = "X=[14]Y=[15]Z=[456]"
*              l_cYVal    = .ExtractFromString(l_cOptions,"Y=[","]")
*              ? l_cYVal && 15
*
*____________________________________________________________________
LPARAMETERS tsResultVariableReference,tsString,tsLeftDelimiter,tsRightDelimiter,tiOccurence
LOCAL       lsString,liPointer,liPosition

*----------------------------------------------
*--Test Parameters
*----------------------------------------------
IF (TYPE("tsString") != "C")
  ?? CHR(7)
  WAIT "Invalid Paramters Passed TO F_ExtractFromString!" WIND TIME 1
  RETURN 0
ENDIF  


*----------------------------------------------
*--Initialize
*----------------------------------------------
tsLeftDelimiter   = IIF(TYPE("tsLeftDelimiter")="C",tsLeftDelimiter,"")
tsRightDelimiter   = IIF(TYPE("tsRightDelimiter")="C",tsRightDelimiter,"")
lsString = IIF(EMPTY(tsString),"",tsString)
tsResultVariableReference  = ""
tiOccurence  = IIF(EMPTY(tiOccurence),1,tiOccurence)
liPosition    = 0


*----------------------------------------------
*--Parse Left Side
*----------------------------------------------
IF (LEN(tsLeftDelimiter) > 0)
	liPointer = ATC(tsLeftDelimiter,lsString,tiOccurence)
	IF (liPointer > 0)
		liPosition = (liPointer+1)
		lsString = SUBSTR(lsString,liPointer+LEN(tsLeftDelimiter))
	ELSE
		lsString = ""
	ENDIF
ENDIF


*----------------------------------------------
*--Parse Right Side
*----------------------------------------------
IF (LEN(tsRightDelimiter) > 0)
	liPointer = ATC(tsRightDelimiter,lsString)
	IF (liPointer > 0)
		lsString = LEFT(lsString,liPointer-1)
	ELSE
		liPosition = 0
		lsString = ""
	ENDIF
ENDIF


*----------------------------------------------
*--Stuff in addressed parameter
*----------------------------------------------
tsResultVariableReference = lsString

RETURN liPosition

**EOM**
