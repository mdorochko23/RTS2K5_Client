PROCEDURE MastUpd
** MastUpd.prg - Update the Global TAMaster file from the local copy
** Called by NewDepo, CaseClos, CaseInfo, NewTag, Plaintif, UpdArea, gfReOpen
** Calls gfPush, gfPop
PARAMETERS lcClient

*!*	Program no longer needed so just return
return

*!*	PRIVATE laEnv, llMaster, llAddNew

*!*	DIMENSION laEnv[1,3]
*!*	= gfPush( @laEnv)

*!*	IF USED( "TAMaster")
*!*	   IF ALLTRIM( Tamaster.cl_code) == ALLTRIM( lcClient)
*!*	      WAIT WINDOW "Updating global case file. Please wait." NOWAIT
*!*	      SCATTER MEMVAR
*!*	      llAddNew = .T.
*!*	      SELECT 0
*!*	      USE ( f_GMaster) ALIAS GlobTam
*!*	      SET ORDER TO cl_code

*!*	      IF SEEK( lcClient)
*!*	         IF ALLTRIM( GlobTam.cl_code) == ALLTRIM( lcClient)
*!*	            SELECT GlobTam
*!*	            GATHER memvar
*!*	            llAddNew = .F.
*!*	         ENDIF
*!*	      ENDIF
*!*	      IF llAddNew
*!*	         INSERT INTO GlobTam FROM MEMVAR
*!*	      ENDIF

*!*	      SELECT GlobTam
*!*	      USE

*!*	      WAIT CLEAR
*!*	   ENDIF
*!*	ENDIF

*!*	= gfPop( @laEnv)
*!*	RETURN
