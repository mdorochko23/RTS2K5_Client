**PROCEDURE  AutoCall

PARAMETERS lcInputPhoneNumber
LOCAL lContinue  as Boolean, lnTemp as Integer
lContinue = .T.
lcPhoneNumber = STRTRAN(lcInputPhoneNumber,'(','')
lcPhoneNumber = STRTRAN(lcPhoneNumber,')','')
lcPhoneNumber = STRTRAN(lcPhoneNumber,'-','')
lcPhoneNumber = ALLTRIM(lcPhoneNumber)
lnPhoneNumberLen = LEN(lcPhoneNumber)
IF (lnPhoneNumberLen < 10)
  RETURN  
ENDIF  
TRY
  lnTemp = VAL(lcPhoneNumber)
CATCH
  lContinue = .F.
ENDTRY
IF (!lContinue)
  RETURN  
ENDIF  


If FILE("C:\Program Files (x86)\Go Integrator\phoneHelper.exe")
lcLine="RUN /n C:\Program Files (x86)\Go Integrator\phoneHelper.exe dial("+ALLTRIM(lcPhoneNumber)+")"
&lcLine
ELSE
GFMESSAGE( 'Missing the phoneHelper.exe. Contact helpdesk. Thank you.' )
 
ENDIF

return
