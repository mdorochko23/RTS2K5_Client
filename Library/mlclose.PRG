*************************************************************************************
* PROGRAM - MCLOSE
*           Performs CLOSING command initializations
*
* PARAMS  - p_quit   <Logical> : Quit or just Cancel?
*         - p_prog   <char   > : Routine to run to reset specific params
*
*************************************************************************************
PARAMETERS p_quit,p_prog

*--Tell 'em--*
WAIT "Clearing..." WIND NOWA

*--All Platform CLEAR initilizations--*
CLEAR
*!*	CLEAR MACROS
*!*	CLEAR PROGRAM
*!*	CLEAR READ ALL
*!*	CLEAR DLLS
*!*	CLOSE ALL
POP KEY ALL
RELEASE WINDOWS calculator,puzzle,help

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
SET AUTOSAVE             ON
SET BELL                 ON
SET BLINK                ON
SET BLOCKSIZE TO         33
SET BORDER               TO
SET BRSTATUS             OFF
SET CARRY                OFF
*--SET CENTURY              ON
SET CLEAR                OFF
SET COLLATE TO           "MACHINE"             
SET COMPATIBLE           OFF
SET CONFIRM              OFF
SET CONSOLE              ON
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
SET ESCAPE               ON
SET EXACT                OFF
SET EXCLUSIVE            OFF
SET FIELDS               OFF
SET FIXED                OFF
SET FORMAT               TO
SET FULLPATH             ON
SET HEADING              ON
SET HOURS TO             12
SET INTENSITY            ON
SET KEYCOMP TO           WINDOWS             
SET LIBRARY              TO
SET LOCK                 OFF
SET LOGERRORS            OFF
SET MACKEY TO            && Note, when set to F10, results in disabled the shortcut menu key.
SET MARGIN TO            0
SET MARK                 TO
SET MEMOWIDTH TO         50
SET MESSAGE TO           ""
SET MOUSE                ON
SET MOUSE TO             5
SET MULTILOCKS           ON
SET NEAR                 ON
SET NOTIFY               ON
SET NULLDISPLAY 				 TO
SET ODOMETER TO          100
SET OPTIMIZE             ON
SET PALETTE              ON
SET POINT                TO
SET PRINTER              TO
SET PROCEDURE            TO
SET READBORDER           ON
SET REFRESH TO           0,5
SET REPROCESS TO         1
SET RESOURCE             ON
SET SAFETY               OFF
SET SCOREBOARD           OFF
SET SEPARATOR            TO
SET SHADOWS              ON
SET SPACE                ON
SET STATUS TIMEOUT       TO              
SET STATUS BAR           ON
SET STICKY               ON
SET SYSMENU TO           DEFAULT
SET TEXTMERGE            OFF
SET TEXTMERGE DELIMITERS 
SET TRBETWEEN            ON
SET TYPEAHEAD TO         20
SET UDFPARMS TO          VALUE
SET UNIQUE               OFF
SET CLOCK                STATUS
CAPSLOCK(.f.)

*--Runtime Specific Commands--*
SET HELP ON
*--SUSP
CLOSE ALL
WAIT CLEAR
CLEAR ALL
*CANCEL
*!*	CLEAR ALL
CLEAR PROGRAM

*!*	CLEAR READ ALL
*!*	CLEAR DLLS
*!*	CLEAR

RETURN
