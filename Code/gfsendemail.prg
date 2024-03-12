FUNCTION gfSendEmail
PARAMETERS sendTo, copyTo, fromName, fromEmail,subject, lcMess, subjectFrom
*--check if users copy of email.exe needs to be updated
LOCAL  lcMail, c_file, n_file, c_String, lsOriginalErrorHandler, llRetVal
llRetVal=.T.
lcMail=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","EMAIL", "\")))+"email.exe"
IF !FILE("c:\email.exe")
   COPY FILE &lcMail TO c:\email.exe
ENDIF 

c_File = "c:\" + SYS(3) +".txt"
n_File = FCREATE(c_File)
IF n_File > 0
   = FPUT(n_File, ALLTRIM(subjectFrom))
   = FPUT(n_File, ALLTRIM(sendTo ))
   = FPUT(n_File, ALLTRIM(copyTo))
   = FPUT(n_File, ALLTRIM(fromName))
   = FPUT(n_File, ALLTRIM(fromEmail))
   = FPUT(n_File, ALLTRIM(subject))
   = FPUT(n_File, lcMess)
   = FPUT(n_File, '')
   = FCLOSE(n_File)
ENDIF
*--call the VFP email generator
c_String = '"' + c_File + '"'
lsOriginalErrorHandler = ON("ERROR")   	
ON ERROR llRetVal=.F.
RUN /N c:\email.exe &c_file
ON ERROR &lsOriginalErrorHandler	
*c_email=c_sendto
RETURN llRetVal