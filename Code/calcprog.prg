PROCEDURE CALCPROG
*  Called by DefCalc.prg
*** Calcprog.prg - Make calculator and Calendar available

parameters what

** what = C-Calculator , L-Calendar

push key
on key label "ESC" ;
   do setback in calcprog.prg
on key label "CTRL+W" ;
   do setback in calcprog.prg
on key label "CTRL+ENTER" ;
   do setback in calcprog.prg

if what = "L"
   activate window CALENDAR
else
   activate window calculator
endif

**************************************************************
procedure setback

pop key
do defcalc
release window CALENDAR
release window CALCULATOR
