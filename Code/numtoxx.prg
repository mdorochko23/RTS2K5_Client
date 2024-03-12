**************************************************************************************************************************************************
**4/17/14- replace numbers with XXX  (for the blurbs on the KOP subp riders)
**************************************************************************************************************************************************
LPARAMETER lcString
LOCAL lnanyNum as Integer, lcReplace as String
lcReplace="X"
lnanyNum =1
 
  
DO WHILE lnanyNum<>0
	LOCAL lnAt, lcSource, lnReplaceSize , ln
	FOR ln=0 TO 9
		lcSource=ALLTRIM(STR(ln))
		lnAt =0
		lnReplaceSize = LEN(lcSource)

		lnItemCount =OCCURS(lcSource, lcString)
		IF lnItemCount<>0
				*DIMENSION laResult[lnItemCount]
		*lnLastPos=1
		FOR icnt=1 TO lnItemCount
			lnAt = AT(lcSource,lcString, 1)	
			***
			
			IF  ( SUBSTR(lcString,lnAt, 2)= "1."  OR SUBSTR(ALLTRIM(lcString),lnAt, 2)= "2."  OR SUBSTR(ALLTRIM(lcString),lnAt, 2)= "3."     OR SUBSTR(ALLTRIM(lcString),lnAt, 2)= "4."  OR SUBSTR(ALLTRIM(lcString),lnAt, 2)= "5."   OR  SUBSTR(ALLTRIM(lcString),lnAt, 2)= "6."  OR SUBSTR(ALLTRIM(lcString),lnAt, 2)= "7."   OR SUBSTR(ALLTRIM(lcString),lnAt, 2)= "8."  )
					icnt=icnt+1	 
					lnAt = AT(lcSource,lcString, icnt)
					IF lnAt=0 AND lnanyNum=0
						RETURN lcString
					endif
			ENDIF
			***
				IF icnt<= lnItemCount				
					lcString = STUFF(lcString,lnAt,lnReplaceSize,lcReplace)			
				ENDIF
			
			*lnLastPos =  LEN( lcString)
		ENDFOR
		endif

	ENDFOR


	IF ('1'$lcString OR  '2'$lcString   OR '3'$lcString  OR '4'$lcString  OR '5'$lcString  OR '6'$lcString OR '7'$lcString  OR '8'$lcString  OR '9'$lcString  OR '0'$lcString ) AND ln<=9

		lnanyNum=1
	
	ELSE
		lnanyNum=0
	ENDIF

ENDDO

RETURN lcString

