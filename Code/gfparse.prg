**************************************************
* PRG: GFPARSE
* Programmer: Hume/kdl (originally in VFP lfparse)
* Date: 07/01/03
* Abstract: ** Inputs a string of numbers separated with commas,
*  converts to array of numbers. Also takes a range of numbers separated
*  by '-' (e.g. 5-23)
**************************************************
PARAMETERS lcString, laBuffer

lcBuffer = ""
lnPages = 0
PRIVATE i, j
*--PUBLIC laPages
**set step on

FOR i = 1 TO LEN(lcString)
   IF SUBSTR( lcString, i, 1) = ","
      IF NOT EMPTY( lcBuffer)
         IF NOT "-" $ lcBuffer
            lnPages = lnPages + 1
            DIMENSION laBuffer(lnPages)
            laBuffer[lnPages] = INT( VAL( lcBuffer))
         ELSE
            lnStart = INT( VAL( LEFT( lcBuffer, AT( "-", lcBuffer) - 1)))
            lnEnd   = INT( VAL( SUBSTR( lcBuffer, AT( "-", lcBuffer) + 1)))
            FOR j = lnStart TO lnEnd
               lnPages = lnPages + 1
               DIMENSION laBuffer(lnPages)
               laBuffer[lnPages] = INT( VAL( j))
            ENDFOR
         ENDIF
         lcBuffer = ""
      ENDIF
   ELSE
      lcBuffer = lcBuffer + SUBSTR( lcString, i, 1)
   ENDIF
ENDFOR

IF NOT EMPTY( lcBuffer)
   IF NOT "-" $ lcBuffer
      lnPages = lnPages + 1
      DIMENSION laBuffer(lnPages)
      laBuffer[lnPages] = INT( VAL( lcBuffer))
   ELSE
      lnStart = INT( VAL( LEFT( lcBuffer, AT( "-", lcBuffer) - 1)))
      lnEnd   = INT( VAL( SUBSTR( lcBuffer, AT( "-", lcBuffer) + 1)))
      FOR j = lnStart TO lnEnd
         lnPages = lnPages + 1
         DIMENSION laBuffer(lnPages)
         laBuffer[lnPages] = j
      ENDFOR
   ENDIF
ENDIF
RETURN
