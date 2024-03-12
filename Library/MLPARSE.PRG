*____________________________________________________________________
*-- MLParse.Prg
*
* Description: Method parses a string into an array based on
*              the string delimiter that is passed.  This is
*              useful for popups that depend on an array and
*              other things.
*
* Parameters : p_aArray   - <@exp> - Required - No default 
*                         - Array to fill with parsed values. Any
*                           variable can be passed. Type will be
*                           changed to an Array.  Variable MUST be
*                           passed by reference.
*              p_cString  - <expC> - Required - No default                        
*                         - String to parse
*              p_cDelimit - <expC> - Optional - Default = "|"
*                         - Delimiter to parse the string on
*              p_nCols    - <expN> - Optional - Default = 1
*                         - Number of columns in the array
*
* Return Val : Returns number of rows in the Array
*
* Example    : *--Fill Array with parsed values from string
*              A_array = .F.
*              total   = .ma_parsearray(@A_array,"hello|goodbye|why ?")
*              FOR counter = 1 TO total
*                ? A_array[counter]                
*              ENDFOR
*
*____________________________________________________________________
PARAMETERS p_aArray,p_cString,p_cDelimit,p_nCols
PRIVATE ALL LIKE v_*

*--Test Parameters
IF (TYPE("p_cString") != "C")
  ?? CHR(7)
  WAIT "MLPARSE: Invalid Parameters!" WIND NOWA
  DIMENSION p_aArray[1]
  p_aArray[1] = .F.
  RETURN 0
ENDIF  

*--Initialize--*
p_cDelimit  = IIF(TYPE("p_cDelimit")!="C" OR LEN(p_cDelimit)=0, ;
                  "|",p_cDelimit)
v_nDelLen   = LEN(p_cDelimit)

*--Count Occurrences--*
v_nTotal = OCCURS(p_cDelimit,p_cString)

*--Build Array--*
IF (v_nTotal = 0)
  IF (LEN(p_cString)>0)
    v_nTotal = 1
    DIMENSION p_aArray[1]
    p_aArray[1] = p_cString
  ELSE
    v_nTotal = 0
    DIMENSION p_aArray[1]
    p_aArray[1] = .F.
  ENDIF
ELSE
  v_nTotal = (v_nTotal+1)
  DIMENSION p_aArray[v_nTotal]
  FOR v_nCnt=1 TO (v_nTotal-1)
    v_nPtr = AT(p_cDelimit,p_cString)
    p_aArray[v_nCnt] = SUBSTR(p_cString,1,(v_nPtr-1))
    p_cString = SUBSTR(p_cString,(v_nPtr+v_nDelLen))
  ENDFOR

  IF (LEN(p_cString)=0)
    v_nTotal = (v_nTotal-1)
    DIMENSION p_aArray[v_nTotal]
  ELSE
    p_aArray[v_nTotal] = p_cString
  ENDIF
  
ENDIF

*--Adjust the size?--*
IF TYPE("p_nCols")="N" AND ;
   (p_nCols > 1) AND ;
   (v_nTotal > 0)
  v_nTotal = CEILING(v_nTotal/p_nCols)
  DIMENSION p_aArray[v_nTotal,p_nCols]
ENDIF

RETURN v_nTotal
