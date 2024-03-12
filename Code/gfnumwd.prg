**************************************************
* PROGRAM: GFNUMWD
* Date: 7/08/03
* Programmer:
*
* Abstract: Convert numeric amount to words
* Modifications:
*
****************************************************
PARAMETER n_Amt, c_Type
IF PCOUNT() < 2
   c_Type = "DOLLARS"
ENDIF
PRIVATE c_Amt, c_Ones, c_Teen, c_Tens, c_Num
c_Amt=""
STORE "     ONE  TWO  THREEFOUR FIVE SIX  SEVENEIGHTNINE " TO c_Ones
STORE "TEN      ELEVEN   TWELVE   THIRTEEN FOURTEEN FIFTEEN  SIXTEEN  "+;
   "SEVENTEENEIGHTEEN NINETEEN " TO c_Teen
STORE "TWENTY THIRTY FORTY  FIFTY  SIXTY  SEVENTYEIGHTY NINETY" TO c_Tens
c_Num = LEFT(STR(n_Amt,9,2),6)
IF LEFT(c_Num,1)>" "
   c_Amt = RTRIM(SUBSTR(c_Ones,VAL(LEFT(c_Num,1))*5+1,5))+" HUNDRED "
ENDIF
DO CASE
   CASE SUBSTR(c_Num,2,1) > "1"
      c_Amt = c_Amt + RTRIM(SUBSTR(c_Tens,VAL(SUBSTR(c_Num,2,1))*7-13,7))
      IF SUBSTR(c_Num,3,1) > "0"
         c_Amt = c_Amt + "-" + ;
            RTRIM(SUBSTR(c_Ones,VAL(SUBSTR(c_Num,3,1))*5+1,5))
      ENDIF
      c_Amt = c_Amt + " THOUSAND "
   CASE SUBSTR(c_Num,2,1) = "1"
      c_Amt = c_Amt + RTRIM(SUBSTR(c_Teen,VAL(SUBSTR(c_Num,3,1))*9+1,9)) + ;
         " THOUSAND "
   CASE SUBSTR(c_Num,2,2) = "00"
      c_Amt = c_Amt + "THOUSAND "
   CASE SUBSTR(c_Num,3,1) > " "
      c_Amt = c_Amt + RTRIM(SUBSTR(c_Ones,VAL(SUBSTR(c_Num,3,1))*5+1,5)) + ;
         " THOUSAND "
ENDCASE
IF SUBSTR(c_Num,4,1) > "0"
   c_Amt = c_Amt+RTRIM(SUBSTR(c_Ones,VAL(SUBSTR(c_Num,4,1))*5+1,5)) + ;
      " HUNDRED "
ENDIF
DO CASE
   CASE SUBSTR(c_Num,5,1) > "1"
      c_Amt = c_Amt+RTRIM(SUBSTR(c_Tens,VAL(SUBSTR(c_Num,5,1))*7-13,7))
      IF RIGHT(c_Num,1)>"0"
         c_Amt = c_Amt + "-" + ;
            RTRIM(SUBSTR(c_Ones,VAL(RIGHT(c_Num,1))*5+1,5))
      ENDIF
   CASE SUBSTR(c_Num,5,1) = "1"
      c_Amt = c_Amt+RTRIM(SUBSTR(c_Teen,VAL(RIGHT(c_Num,1))*9+1,9))
   CASE RIGHT(c_Num,2) = " 0"
      c_Amt = "ZERO"
   OTHERWISE
      c_Amt = c_Amt+RTRIM(SUBSTR(c_Ones,VAL(RIGHT(c_Num,1))*5+1,5))
ENDCASE

IF c_Type = "DOLLARS"
   cents = RIGHT(STR(n_Amt,9,2),2)
   c_Amt = RTRIM(c_Amt) + " AND "+cents+"/100 DOLLARS"
   STRING = SPACE(62)
   LENGTH = LEN(c_Amt)
ENDIF

RETURN c_Amt
