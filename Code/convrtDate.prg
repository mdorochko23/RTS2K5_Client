*****************************************************************************
* PROCEDURE: convrtDate
*
*-- Abstract: Check for null, 01/01/1900 and Convert date to date type 
*****************************************************************************
FUNCTION convrtDate
LPARAMETERS ldDate
ldDate=NVL(ldDate,{})
IF TYPE('ldDate')!='D'
   IF TYPE('ldDate')='T'
      ldDate=TTOD(ldDate)
   ELSE    
     ldDate=CTOD(LEFT(ALLTRIM(ldDate),10))
   ENDIF    
ENDIF 
IF ldDate={01/01/1900}
   ldDate={}
ENDIF    
RETURN ldDate