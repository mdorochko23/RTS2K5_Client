
*FUNCTION properssn
PARAMETERS c_Field, c_Value


**VALIDATE SSN AND DATES- 09/05/2012
			LOCAL l_validssn AS Boolean,C1 AS STRING, C2 AS STRING, c_socsec AS STRING, l_ExcVerify as Boolean
			STORE "" TO C1, C2, c_socsec
			STORE .T. TO l_validssn, l_ExcVerify
			DO CASE

			CASE c_Field='D' AND c_Value<>"SS#" &&ssn
				IF NOT EMPTY(ALLTRIM(c_Value))
					IF  NOT "-"$ALLTRIM(c_Value)
						c_socsec=ALLTRIM(c_Value)
						c_ssn1= LEFT(c_socsec,3)
						c_ssn2= SUBSTR(c_socsec,4,2)
						c_ssn3= RIGHT(c_socsec,4)
						c_socsec= ALLTRIM(c_ssn1) +"-" + ALLTRIM(c_ssn2)+"-"+ ALLTRIM(c_ssn3)
						n_lenssn =LEN(ALLTRIM(c_socsec))
						IF  n_lenssn<>11
							l_validssn=.F.
						ENDIF

					ELSE
**ALREADY HAS A DASH IN SSN, CHECK HOW MANY NNN-NN-NNNN
						C1=SUBSTR(ALLTRIM(c_Value), 4 ,1)
						C2=SUBSTR(ALLTRIM(c_Value), 7 ,1)
						IF C1<>'-' OR C2<>'-'
							l_validssn=.F.
						ENDIF

					ENDIF

				ENDIF
				


		
			ENDCASE
l_ExcVerify=l_validssn


RETURN l_ExcVerify