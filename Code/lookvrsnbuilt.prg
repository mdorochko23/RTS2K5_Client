PROCEDURE lookVrsnBuilt
LPARAMETERS lcWhat, lcTest
LOCAL lc_curarea, lc_copyRTS, llItDept
llItDept=.F. 
IF ALLTRIM( UPPER( goApp.CurrentUser.oRec.pc_userdpt))=="IT"
   llItDept=.T.
ENDIF    
lc_curarea=SELECT()
lc_copyRTS=MLPriPro("R", "RTS.INI", "Data","copyRTS", "\")
SELECT 0
lc_copyRTS=ALLTRIM(lc_copyRTS)+"copyRTS.dbf" 
USE &lc_copyRTS ALIAS copyrts SHARED 
retval=""
IF ALLTRIM(UPPER(lcWhat))="BUILT"
   IF ALLTRIM(UPPER(lcTest))=="TEST"
      retval=chkBuilt("tstBldDate","RTSTest.EXE",llItDept)
   ELSE 
      retval=chkBuilt("build_date","RecordTrak.EXE",llItDept)
   ENDIF 
ENDIF
IF ALLTRIM(UPPER(lcWhat))="VERSION"
   IF ALLTRIM(UPPER(lcTest))=="TEST"   
      retval=chkVersion("testversn","RTSTest.EXE",llItDept)
   ELSE 
      retval=chkVersion("version","RecordTrak.EXE",llItDept)
   ENDIF 
ENDIF
SELECT copyrts
USE
SELECT (lc_curarea)
RETURN retval
*------------------------------------------------------------------------
PROCEDURE chkBuilt
LPARAMETERS lcField, lcEXE, llItDept

retval=DTOC(&lcField) 
IF !FILE(lcEXE)
   IF llItDept=.T.         
      DIMENSION laVer(3)
      laVer[3]=&lcField
   ELSE 
       gfmessage(ALLTRIM(UPPER(lcEXE))+" doesn't exist.  Contact IT Dept."  )  
       QUIT 
   ENDIF 
ELSE      
   ADIR(laVer,lcEXE) 
ENDIF 
IF laVer[3]!=CTOD(retval)
   IF llItDept=.F.
      gfmessage("You are running wrong version from - "+DTOC(laVer[3])+CHR(13)+;
      "The correct version should be built on - "+retval)
      QUIT      
   ELSE 
      retval=DTOC(laVer[3])
   ENDIF      
ENDIF  
RELEASE laVer 
RETURN retVal 
*-----------------------------------------------------------------------------
PROCEDURE chkVersion
LPARAMETERS lcField, lcEXE,llItDept
retval=&lcField
IF !FILE(lcEXE)
   IF llItDept=.T.         
      DIMENSION laVer(4)
      laVer[4]=retval
   ELSE 
       gfmessage(ALLTRIM(UPPER(lcEXE))+" doesn't exist.  Contact IT Dept."  )  
       QUIT 
   ENDIF 
ELSE      
      AGETFILEVERSION(laVer,lcEXE)   
ENDIF 
IF ALLTRIM(UPPER(laVer[4]))!=ALLTRIM(UPPER(retval))
   IF llItDept=.F.
      gfmessage("You are running wrong version - "+laVer[4]+CHR(13)+;
      "The correct version should be - "+ALLTRIM(retval) )     
      QUIT            
   ELSE 
       retval=laVer[4]   
   ENDIF    
ENDIF  
RETURN retVal   