*____________________________________________________________________
*____________________________________________________________________
*
*	CLASSLIB 	: Base.vcx
*	CLASSNAME	: Mediator
*	METHOD		: StringToArray
*
*	NOTES	:
*
* Description: Method parses a string into an array based on
*              the string delimiter that is passed.  This is
*              useful for popups that depend on an array and
*              other things.
*
* Parameters : taArray   - <@exp> - Required - No default 
*                         - Array to fill with parsed values. Any
*                           variable can be passed. Type will be
*                           changed to an Array.  Variable MUST be
*                           passed by reference.
*              tsString  - <expC> - Required - No default                        
*                         - String to parse
*              tsDelimiter - <expC> - Optional - Default = "|"
*                         - Delimiter to parse the string on
*              tiColumns    - <expN> - Optional - Default = 1
*                         - Number of columns in the array
*
* Return Val : Returns number of rows in the Array
*
* Example    : *--Fill Array with parsed values from string
*              A_array = .F.
*              total   = .StringToArray(@A_array,"hello|goodbye|why ?")
*              FOR counter = 1 TO total
*                ? A_array[counter]                
*              ENDFOR
*
*____________________________________________________________________
PARAMETERS taArray, tsString AS String, tsDelimiter AS String, tiColumns AS Integer
EXTERNAL ARRAY taArray
LOCAL 	liDelimiterLength 	AS Integer, ;
		liOccurrences 		AS Integer, ;
		liRowCount			AS Integer, ;
		liRow				AS Integer, ;
		liPosition			AS Integer


*--Test Parameters
IF (TYPE("tsString") != "C")
  ?? CHR(7)
  WAIT "Invalid Parameters Passed to StringToArray Method!!" WIND
  DIMENSION taArray[1]
  taArray[1] = .F.
  RETURN 0
ENDIF  

*--Initialize--*
tsDelimiter  		= IIF(TYPE("tsDelimiter")!="C" OR LEN(tsDelimiter)=0, "|",tsDelimiter)
liDelimiterLength   = LEN(tsDelimiter)
liRowCount = 0


*--Count Occurrences--*
liOccurrences = OCCURS(tsDelimiter,tsString)

*--Build Array--*
IF (liOccurrences = 0)
  IF (LEN(tsString)>0)
    liRowCount = 1
    DIMENSION taArray[1]
    taArray[1] = tsString
  ELSE
    liRowCount = 0
    DIMENSION taArray[1]
    taArray[1] = .F.
  ENDIF
ELSE
  liRowCount = (liOccurrences +1)
  DIMENSION taArray[liRowCount]
  FOR liRow=1 TO (liRowCount-1)
    liPosition = AT(tsDelimiter,tsString)
    taArray[liRow] = SUBSTR(tsString,1,(liPosition-1))
    tsString = SUBSTR(tsString,(liPosition+liDelimiterLength))
  ENDFOR

  IF (LEN(tsString)=0)
    liRowCount = (liRowCount -1)
    DIMENSION taArray[liRowCount]
  ELSE
    taArray[liRowCount] = tsString
  ENDIF
  
ENDIF

*--Adjust the size?--*
IF TYPE("tiColumns")="N" AND (tiColumns > 1) AND (liRowCount > 0) Then
  liRowCount = CEILING(liRowCount/tiColumns)
  DIMENSION taArray[liRowCount,tiColumns]
ENDIF

RETURN liRowCount

**EOM**
