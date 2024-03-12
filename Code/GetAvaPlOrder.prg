
*PROCEDURE GetAvaPlOrder 
c_Save = SELECT()
WAIT WINDOW "Printing  Avandia/Plaintiff Court Order Pages" NOWAIT
DO PrintGroup WITH mv, "AvaPlOrder"
SELECT (c_Save)
WAIT CLEAR
RETURN
