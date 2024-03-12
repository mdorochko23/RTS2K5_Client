*************************************************************************************
* PROGRAM - MLSYSLCK
*           Checks/Sets/Locks System Access 
*
* PARAMS  - p_action <ExpC> : Do What? Options include "IN", "LOCK", "UNLOCK"
*         - p_dir    <ExpC> : Directory to find the SYSTEM.LCK File
*
* REQURE  - Assumes there is a directory called DATA\ underneath the executing
*           application directory if you don't pass a directory for the Lock file.
*         - Don't issue a CLOSE ALL (CLOSE DATA is okay) in your program unless
*           your quitting because it will close your control file.
*         - Don't issue a CLEAR ALL because it will erase your PUBLIC variables
*************************************************************************************
PARAMETERS p_action,p_dir
PRIVATE    l_file

*--Set Up--*
p_action = IIF(EMPTY(p_action),"",ALLT(UPPER(p_action)))
l_file   = IIF(EMPTY(p_dir),GetLockDir(),p_dir)+"SYSTEM.LCK"
*--Do It--*
DO CASE

  CASE (p_action=="IN")
    PUBLIC __JPR__sys
    IF !FILE(l_file)
      __JPR__sys = FCREATE(l_file)
      IF (__JPR__sys = -1)       
        ?? CHR(7)
        WAIT "MLSYSLCK: Could NOT Create Lock File!" + CHR(13) + ;
             "          Press any key to continue..." WIND
        RETURN .F.
      ELSE
        =FPUTS(__JPR__sys,"System Locking File")
        =FCLOSE(__JPR__sys)
      ENDIF
    ENDIF
    __JPR__sys = FOPEN(l_file,10)
    IF (__JPR__sys = -1)       
      ?? CHR(7)
      WAIT "Sorry, the System is busy...Try again later!" + CHR(13) + ;
           "          Press any key to continue..." WIND
      RETURN .F.
    ELSE
      RETURN .T.
    ENDIF

  CASE (p_action=="LOCK")
    =FCLOSE(__JPR__sys)
    __JPR__sys = FOPEN(l_file,12)
    IF (__JPR__sys = -1)       
      __JPR__sys = FOPEN(l_file,10)
      ?? CHR(7)
      WAIT "Sorry, All other users MUST be out of the System!" +CHR(13)+;
           "                 Press any key to continue..." WIND
      RETURN .F.
    ELSE
      RETURN .T.
    ENDIF

  CASE (p_action=="UNLOCK")
    =FCLOSE(__JPR__sys)
    __JPR__sys = FOPEN(l_file,10)
    RETURN .T.

  OTHE
    ?? CHR(7)
    WAIT "MLSYSLCK: Invalid parameter!"+CHR(13)+;
         "   Press any key to continue..." WIND
    RETURN .F.

ENDCASE

RETURN


*************************************************************************************
PROCEDURE GetLockDir
PRIVATE   l_path
l_path = SYS(16,0)
l_path = LEFT(l_path,RAT("\",l_path))   && +"DATA\"
RETURN l_path
