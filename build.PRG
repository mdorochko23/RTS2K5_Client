LPARAMETERS tbRecompile AS Boolean
DECLARE INTEGER GetPrivateProfileString IN Win32API AS GetPrivStr ;
                    String cSec, ;
                    String cKey, ;
                    String cDef, ;
                    String @cBuf, ;
                    Integer nBufSize, ;
                    String cINIFile
    lc_copyRTS = SPACE(500)
    ln_len=GetPrivStr("Data","copyRTS","\",@lc_copyRTS,500,SYS(5)+CURDIR()+"rts.ini")
    lc_copyRTS= LEFT(lc_copyRTS,ln_Len)
llTest=.F.    
lnResponse=MESSAGEBOX("Build Production Version? Yes - Prduction; No - Test Version",35)
IF lnResponse=2   
   RETURN 
ENDIF    
IF lnResponse=6
   lcExe=".\RecordTrak.exe"
ELSE
   llTest=.T.
   lcExe=".\RTSTest.exe"
ENDIF 
   IF tbRecompile then
	  BUILD EXE &lcExe  FROM ".\project\rts.PJX" RECOMPILE
   Else
	  BUILD EXE &lcExe FROM ".\project\rts.PJX" 
   ENDIF 
   
IF MESSAGEBOX("Update Build Date?",36)=6
   IF llTest=.F.
      =AGETFILEVERSION(la_version, ".\RecordTrak.exe")
      lc_copyRTS=ALLTRIM(lc_copyRTS)+"copyrts.dbf"
      USE &lc_copyRTS ALIAS copyrts SHARED
      IF ALLTRIM(version)!=ALLTRIM(la_version[1,4])
         replace version WITH ALLTRIM(la_version[1,4])                  
         replace build_date WITH DATE()
      ENDIF
   ELSE 
      =AGETFILEVERSION(la_version, ".\RTSTest.exe")
      lc_copyRTS=ALLTRIM(lc_copyRTS)+"copyrts.dbf"
      USE &lc_copyRTS ALIAS copyrts SHARED
      IF ALLTRIM(testversn)!=ALLTRIM(la_version[1,4])
         replace testversn WITH ALLTRIM(la_version[1,4])                   
         replace tstblddate WITH DATE()
      ENDIF   
   ENDIF 
ENDIF       
USE
   

