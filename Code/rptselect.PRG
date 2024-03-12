******************************************************************
*--Selects proper work passed work area.
*--Used by converted RTS system reports to set works areas during
*-- execution to resolve loss of selected work areas caused by 
*-- switching between data environments since reports run in
*-- asynchronous mode.

*-- c_area is the work area (alias) needed

******************************************************************
PARAMETERS c_area

SELECT (c_area)
RETURN .T.