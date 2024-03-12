PROCEDURE DEFCALC
* Called by RTS, CalcProg, DepStat, DepOpts, New4Scr
*  Calls CalcProg
on key label "Alt+C" ;
   do calcprog with "C"
on key label "Alt+L" ;
   do calcprog with "L"
RETURN
