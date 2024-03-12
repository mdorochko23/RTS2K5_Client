*************************************************************************************
* PROGRAM - MLINIT
*           Performs SETUP command initializations
*
* PARAMS  - p_test   <Logical> : Are we live or is this memorex?
*************************************************************************************
PARAMETERS p_test
LOCAL nBackbuffer,nForebuffer
*--Tell 'em--*
WAIT "Initializing..." WIND NOWA

*--Setup Main Window--*
*MODIFY WINDOW SCREEN

*--All Platform CLEAR initilizations--*
CLEAR
CLEAR MACROS
CLEAR PROGRAM
CLEAR EVENTS
CLEAR READ ALL
CLEAR DLLS
CLOSE ALL
POP KEY ALL
ON KEY LABEL F1  *
ON KEY LABEL F8  *
ON KEY LABEL F10 *
RELEASE WINDOWS calculator,puzzle,help

*--Set memory buffer limits
*!*	nForebuffer=val(ALLTRIM(MLPriPro("R", "RTS.INI", "Data","Foregroundbuffersize", "\")))
*!*	nBackbuffer=val(ALLTRIM(MLPriPro("R", "RTS.INI", "Data","Backgroundbuffersize", "\")))
*!*	= SYS(3050, 1, VAL(SYS(3050, 1, 0)) / IIF(NVL(nForebuffer,3)>0,nForebuffer,3))
*!*	= SYS(3050, 2, VAL(SYS(3050, 2, 0)) / IIF(NVL(nBackbuffer,3)>0,nBackbuffer,3))

*--All Platform ON initilizations--*
ON ERROR
ON ESCAPE
ON KEY
ON PAGE
ON READERROR
ON SHUTDOWN

*--All Platform SET initilizations--*
SET TALK                 OFF
SET ALTERNATE            OFF
SET ANSI                 OFF
SET ASSERTS              ON
SET AUTOSAVE             ON
SET BELL                 ON
SET BLINK                ON
SET BLOCKSIZE TO         33
SET BORDER               TO
SET BRSTATUS             OFF
SET CARRY                OFF
SET CENTURY              ON
SET CLASSLIB             TO
SET CLEAR                OFF
SET COLLATE TO           "MACHINE"             
SET COMPATIBLE           OFF
SET CONFIRM              OFF
SET CONSOLE              OFF
SET CPDIALOG             OFF
SET CURRENCY             TO
SET CURRENCY             LEFT
SET CURSOR               ON
SET DATE                 AMERICAN
SET DEBUG                ON
SET DECIMALS TO          2
SET DELETED              ON
SET DELIMITERS           OFF
SET DEVELOPMENT          ON
SET DEVICE TO            SCREEN
SET DOHISTORY            OFF
SET ECHO                 OFF
SET ESCAPE               OFF
SET EXACT                OFF
SET EXCLUSIVE            OFF
SET FIELDS               OFF
SET FIXED                OFF
SET FORMAT               TO
SET FULLPATH             ON
SET HEADING              ON
SET HELP                 ON
SET HOURS TO             12
SET INTENSITY            ON
SET KEYCOMP TO           WINDOWS             
SET LIBRARY              TO
SET LOCK                 OFF
SET LOGERRORS            OFF
SET MACKEY               TO
SET MARGIN TO            0
SET MARK                 TO
SET MEMOWIDTH TO         80
SET MESSAGE TO           ""
SET MOUSE                ON
SET MOUSE TO             5
SET MULTILOCKS           ON
SET NEAR                 ON
SET NOTIFY               OFF
SET ODOMETER TO          100
SET OPTIMIZE             ON
SET PALETTE              OFF
SET POINT                TO
SET PRINTER              TO
SET PROCEDURE            TO
SET READBORDER           OFF
SET REFRESH TO           0,5
SET REPROCESS TO         1
SET RESOURCE             OFF
SET SAFETY               OFF
SET SCOREBOARD           OFF
SET SECONDS              OFF
SET SEPARATOR            TO
SET SHADOWS              OFF
SET SPACE                ON
SET STATUS TIMEOUT       TO              
SET STATUS               OFF
SET STATUS BAR           OFF
SET STICKY               ON
SET STRICTDATE TO				 0
SET SYSMENU              OFF
SET TEXTMERGE            OFF
SET TEXTMERGE DELIMITERS 
SET TRBETWEEN            OFF
SET TYPEAHEAD TO         20
SET UDFPARMS TO          VALUE
SET UNIQUE               OFF
SET CLOCK                STATUS
 
*--Runtime Specific SET initializations--*
IF (p_test)
* SET ESCAPE             ON
* SET MACKEY TO          SHIFT+F10
ELSE
* SET ESCAPE             OFF
* SET MACKEY             TO
ENDIF

*--Wipe out everything--*
CLEAR ALL
WAIT CLEAR

RETURN

**EOF**
