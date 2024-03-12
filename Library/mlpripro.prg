*:****************************************************************************
*:
*: PROCEDURE - MLPRIPRO
*:
*: Description: Reads/Writes Private Profile strings.
*:
*: Parameters : p_cAct - <expC> MUST be "R" or "W" to Read/Write
*:              p_cINI - <expC> Private INI file to use
*:              p_cSec - <expC> INI file section
*:              p_cKey - <expC> INI file key
*:              p_cDef - <expC> Key default (for "R") OR Key Value (for "W")
*:              p_cTrm - <expC> Terminator for a Read INI string
*:
*: Return Val : Returns INI file setting for a Read
*:              Returns .T./.F. for a Write
*:
*: Example    : *--Get Data Path--*
*:              l_cData = MLPriPro("R","cc.ini","App","DataPath","DATA\","\")
*:
*:****************************************************************************
PARAMETERS p_cAct,p_cINI,p_cSec,p_cKey,p_cDef,p_cTrm
PRIVATE    ALL LIKE v_*
#INCLUDE APP.h

*--Parameter Checking/Prepping--*
v_cErr = ""
v_vRet = ""
v_cAct = IIF(EMPTY(p_cAct),"",ALLT(UPPER(p_cAct)))
v_cINI = IIF(EMPTY(p_cINI),"",ALLT(p_cINI))
v_cINI = IIF("\"$v_cINI,v_cINI,SYS(5)+CURDIR()+v_cINI)
v_cSec = IIF(EMPTY(p_cSec),"",ALLT(p_cSec))
v_cKey = IIF(EMPTY(p_cKey),"",ALLT(p_cKey))
v_cDef = IIF(EMPTY(p_cDef),"",ALLT(p_cDef))
v_cTrm = IIF(EMPTY(p_cTrm),"",ALLT(p_cTrm))

*--Which are we doing?--*
DO CASE
  CASE (v_cAct=="R")
    *--DECLARE DLL--*
    DECLARE INTEGER GetPrivateProfileString IN Win32API AS GetPrivStr ;
                    String cSec, ;
                    String cKey, ;
                    String cDef, ;
                    String @cBuf, ;
                    Integer nBufSize, ;
                    String cINIFile
    v_vRet = SPACE(500)
    v_nLen=GetPrivStr(v_cSec,v_cKey,v_cDef,@v_vRet,500,v_cINI)
    v_vRet = LEFT(v_vRet,v_nLen)

    *--Check Termination of String--*
    IF !EMPTY(v_cTrm)
      IF (RIGHT(v_vRet,LEN(v_cTrm))!=v_cTrm)
        v_vRet = v_vRet+v_cTrm
      ENDIF
    ENDIF

  CASE (v_cAct=="W")
    *--DECLARE DLL--*
    DECLARE INTEGER WritePrivateProfileString IN Win32API AS WritePrivStr ;
                    String cSec, ;
                    String cKey, ;
                    String cVal, ;
                    String cINIFile
    v_vRet=(WritePrivStr(v_cSec,v_cKey,v_cDef,v_cINI) != 0)
  OTHE
    v_cErr = "Invalid Parameters!"
ENDCASE


*--Display Error?--*
IF !EMPTY(v_cErr)
  =gfmessage(v_cErr)
*--  =MESSAGEBOX(v_cErr, MB_ICONSTOP, "Error in Profile String!")
ENDIF

RETURN v_vRet

**EOF**
